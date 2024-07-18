/*
 * Copyright (c) 2023-2024 C*Core Technology Co.,Ltd,Suzhou.
 * Ventus-RTL is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
 * EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
 * MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details. */
// Author:TangYao 
// Description:Store the input tag info here, and judge req_tag is hit or not, and output dirty info to sourceD.

`timescale  1ns/1ns
`include "define.v"
//`include "L2cache_define.v"

module directory_test#(
  parameter NUM_WAY = 2**`WAY_BITS,
  parameter NUM_SET = 2**`SET_BITS
  )(
  input                                             clk                                                                       ,
  input                                             rst_n                                                                     ,
  //write port
  input                                             dir_write_valid_i                                                         ,
  output                                            dir_write_ready_o                                                         ,
  input [`WAY_BITS-1:0]                             dir_write_way_i                                                           ,
  //tag is the write data
  input [`TAG_BITS-1:0]                             dir_write_tag_i                                                           ,
  input [`SET_BITS-1:0]                             dir_write_set_i                                                           ,
  //read port
  input                                             dir_read_valid_i                                                          ,
  output                                            dir_read_ready_o                                                          ,
  input [`SET_BITS-1:0]                             dir_read_set_i                                                            ,
  //input [`L2C_BITS-1:0]                             dir_read_l2cidx_i                                                         ,
  input [`OP_BITS-1:0]                              dir_read_opcode_i                                                         ,
  input [`SIZE_BITS-1:0]                            dir_read_size_i                                                           ,
  input [`SOURCE_BITS-1:0]                          dir_read_source_i                                                         ,
  input [`TAG_BITS-1:0]                             dir_read_tag_i                                                            ,
  input [`OFFSET_BITS-1:0]                          dir_read_offset_i                                                         ,
  input [`PUT_BITS-1:0]                             dir_read_put_i                                                            ,
  input [`DATA_BITS-1:0]                            dir_read_data_i                                                           ,
  input [`MASK_BITS-1:0]                            dir_read_mask_i                                                           ,
  input [2:0]                                       dir_read_param_i                                                          ,
  //result port
  output                                            dir_result_valid_o                                                        ,
  input                                             dir_result_ready_i                                                        ,
  output [`TAG_BITS-1:0]                            dir_result_victim_tag_o                                                   ,
  output [`WAY_BITS-1:0]                            dir_result_way_o                                                          ,
  output                                            dir_result_hit_o                                                          ,
  output                                            dir_result_dirty_o                                                        ,
  output                                            dir_result_flush_o                                                        ,
  output                                            dir_result_last_flush_o                                                   ,
  output [`SET_BITS-1:0]                            dir_result_set_o                                                          ,
  //output [`L2C_BITS-1:0]                            dir_result_l2cidx_o                                                       ,
  output [`OP_BITS-1:0]                             dir_result_opcode_o                                                       ,
  output [`SIZE_BITS-1:0]                           dir_result_size_o                                                         ,
  output [`SOURCE_BITS-1:0]                         dir_result_source_o                                                       ,
  output [`TAG_BITS-1:0]                            dir_result_tag_o                                                          ,
  output [`OFFSET_BITS-1:0]                         dir_result_offset_o                                                       ,
  output [`PUT_BITS-1:0]                            dir_result_put_o                                                          ,
  output [`DATA_BITS-1:0]                           dir_result_data_o                                                         ,
  output [`MASK_BITS-1:0]                           dir_result_mask_o                                                         ,
  output [2:0]                                      dir_result_param_o                                                        ,
  //ready port
  output                                            dir_ready_o                                                               ,
  //flush port
  input                                             dir_flush_i                                                               ,
  //invalidate port
  input                                             dir_invalidate_i                                                          ,
  //tagmatch port
  input                                             dir_tag_match_i                                                           
  );
  //reg  [(NUM_WAY)*(NUM_SET)*`TAG_BITS-1:0] cc_dir;
  wire cc_dir_w_valid                              ; //wen of this sram
  wire [NUM_WAY*`TAG_BITS-1:0] cc_dir_w_data       ; //wdata of this sram
  wire [`WAY_BITS-1:0] cc_dir_w_way_addr           ; //way waddr of this sram
  wire [`SET_BITS-1:0] cc_dir_w_set_addr           ; //set waddr of this sram
  wire cc_dir_r_valid                              ;  
  //reg [`TAG_BITS-1:0] cc_dir_r_data[NUM_WAY-1:0] ; //rdata of this sram
  wire [(NUM_WAY)*`TAG_BITS-1:0] cc_dir_r_data     ;
  //wire [`TAG_BITS-1:0] regout [NUM_WAY-1:0];
  wire [(NUM_WAY)*`TAG_BITS-1:0] regout       ;
  
  reg  [`SET_BITS:0] wipeCount;
  reg  wipeoff                ; //regnext(next,init) - >(false,true)
  wire wipeDone,wipeSet       ;
  
  reg  flush_issue_reg                        ; //init 0
  wire flush_issue                            ;
  reg  is_invalidate_reg                      ; //init 0
  wire is_invalidate                          ;
  reg  [`SET_BITS + `WAY_BITS-1:0] flushCount ; //init 0
  wire flushDone                              ;
  wire cc_dir_r_set_addr                      ; //set raddr of this sram
  
  wire ren ;
  reg  ren1;
  
  reg [`TAG_BITS-1:0] tag; //init 0 ;
  reg [`SET_BITS-1:0] set; //init 0 ;
  
  wire wen_new    ;
  wire wen        ;
  reg  wen1       ;
  wire not_replace;
  //reg [NUM_WAY-1:0] status_reg_valid [NUM_SET-1:0]; //init 0
  //reg [NUM_WAY-1:0] status_reg_dirty [NUM_SET-1:0]; //init 0
  reg [NUM_WAY*(NUM_SET)-1:0] status_reg_valid; //init 0
  reg [NUM_WAY*(NUM_SET)-1:0] status_reg_dirty; //init 0
  /*
  reg [15:0] lfsr;
  wire lfsr_xor;
  wire [15:0] victim_LFSR ;
  */
  wire [`WAY_BITS-1:0] victimWay;
  
  wire setQuash_1;
  reg  setQuash  ;
  wire tagmatch_1;
  reg  tagmatch  ;
  //reg [`WAY_BITS-1:0] writeWay1; //init 0 
  
  //wire [`TAG_BITS-1:0] ways [NUM_WAY-1:0];
  wire [(NUM_WAY)*`TAG_BITS-1:0] ways        ;
  //wire [NUM_WAY-1:0]status_dirty;
  wire [NUM_WAY-1:0]             status_valid;
  //reg  [`SET_BITS-1:0] writeSet1;
  wire [NUM_WAY-1:0]             hits        ;
  wire [`WAY_BITS-1:0]           hitway      ;
  wire                           hit         ;
  wire [`SET_BITS-1:0]           flush_set   ;
  wire [`WAY_BITS-1:0]           flush_way   ;
  wire [`TAG_BITS-1:0]           flush_tag   ;
  reg                            valid_reg   ; //init 0
  
  wire valid_signal;
  //read_bits_reg init 0
  reg [`SET_BITS-1:0]                            read_bits_reg_set      ;
  //reg [`L2C_BITS-1:0]                            read_bits_reg_l2cidx   ;
  reg [`OP_BITS-1:0]                             read_bits_reg_opcode   ;
  reg [`SIZE_BITS-1:0]                           read_bits_reg_size     ;
  reg [`SOURCE_BITS-1:0]                         read_bits_reg_source   ;
  reg [`TAG_BITS-1:0]                            read_bits_reg_tag      ;
  reg [`OFFSET_BITS-1:0]                         read_bits_reg_offset   ;
  reg [`PUT_BITS-1:0]                            read_bits_reg_put      ;
  reg [`DATA_BITS-1:0]                           read_bits_reg_data     ;
  reg [`MASK_BITS-1:0]                           read_bits_reg_mask     ;
  reg [2:0]                                      read_bits_reg_param    ;
  reg flush_issue_reg_1; //init 0
  //reg [NUM_WAY-1:0] status_reg_dirty_reg_1 [NUM_SET-1:0]; //init 0  reg [`WAY_BITS-1:0] status_reg_dirty [`SET_BITS-1:0]; 
  reg [NUM_WAY*(NUM_SET)-1:0] status_reg_dirty_reg_1 ; //init 0  reg [`WAY_BITS-1:0] status_reg_dirty [`SET_BITS-1:0]; 
  reg [`SET_BITS-1:0] flush_set_reg_1; //init 0
  reg [`WAY_BITS-1:0] flush_way_reg_1; //init 0
  reg [`TAG_BITS-1:0] flush_tag_reg_1; //init 0
  reg flushDone_reg_1; //init 0
  //reg [`TAG_BITS-1:0] dir_read_tag_i_reg_1;
  reg [`SET_BITS-1:0] dir_read_set_i_reg_1;
  reg [`WAY_BITS-1:0] dir_write_way_i_reg_1;
  wire about_replace;
  wire timely_hit;
  
  reg  [`TAG_BITS-1:0] dir_read_tag_r ;
  wire [NUM_WAY-1:0]   w_req_waymask_i;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      dir_read_tag_r <= 'h0;
      dir_read_set_i_reg_1 <= 'h0;
    end 
    else if(dir_read_valid_i) begin
      dir_read_tag_r <= dir_read_tag_i;
      dir_read_set_i_reg_1 <= dir_read_set_i;
    end   
    else begin
      dir_read_tag_r <= dir_read_tag_r;
      dir_read_set_i_reg_1 <= dir_read_set_i_reg_1;
    end
  end 
  
  assign regout = cc_dir_r_data;
  
  assign ren               = (dir_read_valid_i & dir_read_ready_o ) || flush_issue;
  assign cc_dir_r_set_addr = flush_issue ? flush_set : dir_read_set_i             ;
  
  assign cc_dir_r_valid    = ren & (!(setQuash_1 && tagmatch_1))                  ;
  
  assign cc_dir_w_valid    = wen_new                                              ;
  assign cc_dir_w_data     = wipeDone ? {NUM_WAY{dir_write_tag_i }}:0             ;//Mux(wipeDone, io.write.bits.data.asUInt, 0.U),
  assign cc_dir_w_set_addr = wipeDone ? dir_write_set_i :wipeSet                  ;//Mux(wipeDone, io.write.bits.set, 0.U),
  assign cc_dir_w_way_addr = dir_write_way_i                                      ;//wipedone has been processed in the previous loop.
  assign w_req_waymask_i   = (!wipeDone) ? {NUM_WAY{1'b1}} : ({{(NUM_WAY-1){1'b0}},1'b1} << cc_dir_w_way_addr);    
    
  assign wipeDone          = wipeCount [`SET_BITS]   ;
  assign wipeSet           = wipeCount[`SET_BITS-1:0];
  sram_template  #(     
  .GEN_WIDTH      (`TAG_BITS        ),
  .NUM_SET        (NUM_SET          ),
  .NUM_WAY        (NUM_WAY          ),
  .SET_DEPTH      (`SET_BITS        ),
  .WAY_DEPTH      (`WAY_BITS        ))
  //.DATA_WIDTH     (`TAG_BITS        ))
  sram_template   (
  .clk            (clk              ),
  .rst_n          (rst_n            ),
  .r_req_valid_i  (cc_dir_r_valid   ),
  .r_req_setid_i  (cc_dir_r_set_addr),
  .r_resp_data_o  (cc_dir_r_data    ),
  .w_req_valid_i  (cc_dir_w_valid   ),
  .w_req_setid_i  (cc_dir_w_set_addr),
  .w_req_waymask_i(w_req_waymask_i  ),
  .w_req_data_i   (cc_dir_w_data    )); 
  
  always @(posedge clk or negedge rst_n) 
    begin
      if(!rst_n)
        begin
          wipeoff <= 1'b1;
          wipeCount <= 0;
        end
      else 
        begin
          wipeoff <= 1'b0;
          if(!wipeDone & !wipeoff)
            begin
              wipeCount <= wipeCount + 1;
            end
        end
  end
  
  
  assign flushDone = flushCount == NUM_SET * NUM_WAY -1;
  
  assign flush_issue = (dir_flush_i || dir_invalidate_i) ? 1'b1 : flush_issue_reg ;
  assign is_invalidate = dir_invalidate_i ?  dir_invalidate_i : is_invalidate_reg ;
  
  always @(posedge clk or negedge rst_n) 
    begin
      if(!rst_n)
        begin
          flush_issue_reg   <= 1'b0;
          is_invalidate_reg <= 1'b0;
        end
      else if(dir_flush_i || dir_invalidate_i)
        begin
          flush_issue_reg <= 1'b1;
          is_invalidate_reg <= dir_invalidate_i;
        end
      else if(flushDone)
        begin
          flush_issue_reg <= 1'b0;
          is_invalidate_reg <= 1'b0;
        end
  end
  
  always @(posedge clk or negedge rst_n) 
    begin
      if(!rst_n)
        begin
          flushCount <= 0;
        end
      else if(flushDone)
        flushCount <= 0; 
      else if(dir_flush_i || dir_invalidate_i || flush_issue_reg)
        begin
          flushCount <= flushCount + 1;
        end
  end
  
  
  assign wen_new = (!wipeDone  && !wipeoff) || (dir_write_valid_i && dir_write_ready_o) ;
  
  assign wen = dir_write_valid_i && dir_write_ready_o ;
  
  assign not_replace = ((dir_result_opcode_o == `PUTFULLDATA || dir_result_opcode_o == `PUTPARTIALDATA) && !dir_result_hit_o) || dir_tag_match_i ;
    //not replace victim when write miss or when multi mergeable miss
  
  
  always @(posedge clk or negedge rst_n) 
    begin
      if(!rst_n)
        begin
          wen1 <= 1'b0;
          ren1 <= 1'b0;
          tagmatch <= 1'b0;
          setQuash <= 1'b0;
        end
      else
        begin
          wen1 <= wen;
          ren1 <= ren;
          tagmatch <= tagmatch_1;
          setQuash <= setQuash_1;
          dir_write_way_i_reg_1 <= dir_write_way_i;
        end
  end
  
  
  always @(posedge clk or negedge rst_n) 
    begin
      if(!rst_n)
        begin
          status_reg_valid <= 0;
          status_reg_dirty <= 0;
        end
      else 
        begin
          if(!wipeDone)
            begin
              status_reg_valid    <= 'b0;
              status_reg_dirty    <= 'b0;
            end
          else if(flush_issue)
            begin
              if(is_invalidate)
                begin
                  status_reg_valid [flushCount] <= 1'b0;
                end
              status_reg_dirty [flushCount] <= 1'b0;
            end
          else if(dir_result_valid_o && dir_result_hit_o && ((dir_result_opcode_o == `PUTPARTIALDATA) || dir_result_opcode_o == `PUTFULLDATA) )
            begin
              status_reg_dirty[(dir_result_set_o)*(NUM_WAY) +  dir_result_way_o ] <= 1'b1;
            end
          else if( dir_result_valid_o && !dir_result_hit_o  && !not_replace)
            begin
              status_reg_dirty[(dir_result_set_o)*(NUM_WAY) +  dir_result_way_o ] <= 1'b0;
              status_reg_valid[(dir_result_set_o)*(NUM_WAY) +  dir_result_way_o ] <= 1'b0;
            end
          else if(dir_write_valid_i )
            begin
              status_reg_valid[(dir_write_set_i)*(NUM_WAY) +  dir_write_way_i ] <= 1'b1;
              status_reg_dirty[(dir_write_set_i)*(NUM_WAY) +  dir_write_way_i ] <= 1'b0;
            end
        end
    end
  
  
  always @(posedge clk or negedge rst_n) 
    begin
      if(!rst_n)
        begin
          tag <= 0;
          set <= 0;
        end
      else if(ren)
        begin
          tag <= dir_read_tag_i;
          set <= dir_read_set_i;
        end     
    end
  /*
  // reg replacer_array; //not used in this module
  assign lfsr_xor =  lfsr[0] ^ lfsr[1] ^ lfsr[3] ^ lfsr[4];
  always @(posedge clk or negedge rst_n) 
  begin
      if(!rst_n)
         begin        
          lfsr <= 16'h0000;
         end
      else if(dir_result_valid_o && dir_result_ready_i)
         begin
          lfsr <= (lfsr == 16'd0) ? 16'd1 : {lfsr[14:0],lfsr_xor};
         end
      else 
         lfsr <= lfsr;
  end
  assign victim_LFSR = lfsr;
  */
  wire [`WAY_BITS-1:0] temp_way;
  assign temp_way = hit ? hitway :( (dir_result_valid_o & dir_result_ready_i) ? dir_result_way_o : (dir_write_valid_i ?  dir_write_way_i : 'b0));
  wire [`WAY_BITS*(`SET_BITS+1)-1:0] lru_way_o;
  //assign victimWay = victim_LFSR[`WAY_BITS-1:0];
  genvar q;
  generate
    for(q=0;q<`SET_BITS+1;q=q+1)
       begin:lru_for_every_set
         lru_matrix #(
         .NUM_WAY  (NUM_WAY),// number way of one set    
         .WAY_DEPTH(NUM_SET))
         U_lru_matrix(
         .clk            (clk                                                                                                 )   ,
         .rst_n          (rst_n                                                                                               )   ,
         .update_entry_i (((dir_result_valid_o && dir_result_ready_i )||(hit)||(dir_write_valid_i)) && (dir_result_set_o == q))   , // input update condition
         .update_index_i (temp_way                                                                                            )   , // input update wayId
         .lru_index_o    (lru_way_o[q*`WAY_BITS+:`WAY_BITS]                                                                   )     // output replacement wayId
         );
  
       end
  endgenerate

  assign victimWay = lru_way_o[dir_result_set_o *`WAY_BITS+:`WAY_BITS] ;
  
  assign setQuash_1 = wen && dir_write_set_i == dir_read_set_i_reg_1/*dir_read_set_i*/;
  //assign setQuash = wen && dir_write_set_i == set ;
  assign tagmatch_1 =  (dir_read_tag_i == dir_write_tag_i) && (dir_result_tag_o == dir_write_tag_i);
  //assign tagmatch_1 =  (dir_read_valid_i) ? (dir_read_tag_i == dir_write_tag_i) : (dir_read_tag_r == dir_write_tag_i);
  
  //assign tagmatch  = dir_write_tag_i == tag ;
  /*
  always @(posedge clk or negedge rst_n) 
  begin
      if(!rst_n)
         begin
          writeWay1 <= 0;
         end
         else 
           begin
             writeWay1 <= dir_write_way_i;
           end
  end
  */  
  //wire [`TAG_BITS-1:0] regout [NUM_WAY-1:0];
  
  assign ways = regout;
  assign status_valid = status_reg_valid[(NUM_WAY)*set +:NUM_WAY];
  genvar p;
  generate
    for(p=0;p<NUM_WAY;p=p+1)
      begin:gen_hits
  //      assign hits[p] = ways[(p+1)*`TAG_BITS-1-:`TAG_BITS] == tag && (!setQuash) && status_valid[p];
        assign hits[p] = ways[(p+1)*`TAG_BITS-1-:`TAG_BITS] == tag &&  status_valid[p];
  //      if(hits[p])
  //        assign hitway = p;
      end
  endgenerate
  
  one2bin #(
  .ONE_WIDTH(NUM_WAY),
  .BIN_WIDTH(`WAY_BITS)
  )U_one2bin(
  .oh(hits),
  .bin(hitway)
  );
  
  assign hit = |hits;
  
  assign flush_set         = flushCount / NUM_WAY                      ;
  assign flush_way         = flushCount % NUM_WAY                      ;
  assign flush_tag         = ways[flush_way_reg_1*`TAG_BITS+:`TAG_BITS];
  assign dir_ready_o       = wipeDone && !flush_issue_reg              ;
  assign dir_write_ready_o = wipeDone && !flush_issue_reg              ;
  
  
  always @(posedge clk or negedge rst_n) 
    begin
      if(!rst_n)
        begin
          valid_reg <= 0;
        end
      else if(ren1 && !dir_result_ready_i)
        begin
          valid_reg <= 1'b1;
        end
      else if(dir_result_ready_i && dir_result_valid_o)
        begin
          valid_reg <= 1'b0;
        end
    end
  
  
  assign valid_signal = ren1 ? ren1 : valid_reg;
  
  
  always @(posedge clk or negedge rst_n) 
    begin
      if(!rst_n)
        begin
          read_bits_reg_set      <= 0 ;
  //        read_bits_reg_l2cidx   <= 0 ;
          read_bits_reg_opcode   <= 0 ;
          read_bits_reg_size     <= 0 ;
          read_bits_reg_source   <= 0 ;
          read_bits_reg_tag      <= 0 ;
          read_bits_reg_offset   <= 0 ;
          read_bits_reg_put      <= 0 ;
          read_bits_reg_data     <= 0 ;
          read_bits_reg_mask     <= 0 ;
          read_bits_reg_param    <= 0 ;
        end
      else if (dir_read_ready_o && dir_read_valid_i)
        begin
          read_bits_reg_set      <= dir_read_set_i    ;
  //        read_bits_reg_l2cidx   <= dir_read_l2cidx_i ;
          read_bits_reg_opcode   <= dir_read_opcode_i ;
          read_bits_reg_size     <= dir_read_size_i   ;
          read_bits_reg_source   <= dir_read_source_i ;
          read_bits_reg_tag      <= dir_read_tag_i    ;
          read_bits_reg_offset   <= dir_read_offset_i ;
          read_bits_reg_put      <= dir_read_put_i    ;
          read_bits_reg_data     <= dir_read_data_i   ;
          read_bits_reg_mask     <= dir_read_mask_i   ;
          read_bits_reg_param    <= dir_read_param_i  ;
        end
      else if (dir_invalidate_i)
        begin
          read_bits_reg_set      <= read_bits_reg_set    ;
  //        read_bits_reg_l2cidx   <= dir_read_l2cidx_i ;
          read_bits_reg_opcode   <= read_bits_reg_opcode ;
          read_bits_reg_size     <= read_bits_reg_size   ;
          read_bits_reg_source   <= dir_read_source_i    ;
          read_bits_reg_tag      <= read_bits_reg_tag    ;
          read_bits_reg_offset   <= read_bits_reg_offset ;
          read_bits_reg_put      <= read_bits_reg_put    ;
          read_bits_reg_data     <= read_bits_reg_data   ;
          read_bits_reg_mask     <= read_bits_reg_mask   ;
          read_bits_reg_param    <= read_bits_reg_param  ;
        end
      /*else if (dir_invalidate_i)   
        begin
          read_bits_reg_set      <=  read_bits_reg_set     ; 
  //        read_bits_reg_l2cidx <=    read_bits_reg_l2cidx;
          read_bits_reg_opcode   <=  read_bits_reg_opcode  ;
          read_bits_reg_size     <=  read_bits_reg_size    ;
          
          read_bits_reg_source   <=  dir_read_source_i     ;
          
          read_bits_reg_tag      <=  read_bits_reg_tag     ;
          read_bits_reg_offset   <=  read_bits_reg_offset  ;
          read_bits_reg_put      <=  read_bits_reg_put     ;
          read_bits_reg_data     <=  read_bits_reg_data    ;
          read_bits_reg_mask     <=  read_bits_reg_mask    ;
          read_bits_reg_param    <=  read_bits_reg_param   ; 
        end */
    end
  always @(posedge clk or negedge rst_n) 
    begin
      if(!rst_n)
        begin
          flush_issue_reg_1      <= 0;
          flush_set_reg_1        <= 0;
          flush_way_reg_1        <= 0;
          flush_tag_reg_1        <= 0;
          flushDone_reg_1        <= 0;
          status_reg_dirty_reg_1 <= 0;
        end
      else 
        begin
          flush_issue_reg_1      <= flush_issue     ;
          flush_set_reg_1        <= flush_set       ;
          flush_way_reg_1        <= flush_way       ;
          flush_tag_reg_1        <= flush_tag       ;
          flushDone_reg_1        <= flushDone       ;
          status_reg_dirty_reg_1 <= status_reg_dirty;
        end
    end

    
  assign about_replace           = (dir_write_set_i == dir_result_set_o) && (dir_write_way_i == dir_result_way_o)  &&  dir_write_valid_i && dir_write_ready_o; 
  assign timely_hit              = (dir_read_tag_r/*dir_read_tag_i_reg_1*/ == dir_write_tag_i )&& dir_write_valid_i && dir_write_ready_o && (dir_read_set_i_reg_1 == dir_write_set_i);
  assign dir_read_ready_o        = ((wipeDone  && !(dir_write_valid_i && dir_write_ready_o)) || (setQuash_1 && tagmatch_1)) && !flush_issue_reg && dir_result_ready_i;   //also fire when bypass , write and read can not happen at the same time
  assign dir_result_valid_o      = flush_issue_reg_1 ? /*status_reg_dirty_reg_1[(NUM_WAY)*(flush_set_reg_1) +  flush_way_reg_1 ]&& flush_issue_reg_1*/1'b1 : valid_signal ;
  assign dir_result_hit_o        = flush_issue_reg_1 ? 1'b1 :((status_reg_valid[(dir_result_set_o)*(NUM_WAY) + dir_result_way_o] == 1'b1) ? 1'b0: ((hit || (setQuash && tagmatch && dir_result_set_o == dir_write_set_i) || timely_hit) && (!about_replace)));
  assign dir_result_way_o        = flush_issue_reg_1 ? flush_way_reg_1 : (hit? hitway: ((setQuash && tagmatch)?  dir_write_way_i_reg_1: (timely_hit ? dir_write_way_i :victimWay)  )) ;
  assign dir_result_put_o        = flush_issue_reg_1 ? 1'b0 : read_bits_reg_put ;
  assign dir_result_data_o       = flush_issue_reg_1 ? 0 : read_bits_reg_data ;
  assign dir_result_offset_o     = flush_issue_reg_1 ? 0 : read_bits_reg_offset ;
  assign dir_result_size_o       = flush_issue_reg_1 ? $clog2(`L2CACHE_BEATBYTES) : read_bits_reg_size ;
  assign dir_result_set_o        = flush_issue_reg_1 ? flush_set_reg_1 : read_bits_reg_set ;
  assign dir_result_source_o     = read_bits_reg_source ;
  //assign dir_result_source_o   = flush_issue_reg_1 ? {1'b1, : read_bits_reg_source ;
  assign dir_result_tag_o        = flush_issue_reg_1 ? flush_tag : read_bits_reg_tag ;
  assign dir_result_opcode_o     = flush_issue_reg_1 ? `HINT: read_bits_reg_opcode ;
  assign dir_result_mask_o       = flush_issue_reg_1 ? {`MASK_BITS{1'b1}} : read_bits_reg_mask ;
  assign dir_result_dirty_o      = flush_issue_reg_1 ? status_reg_dirty_reg_1[(flush_set_reg_1)*(NUM_WAY) + flush_way_reg_1 ] : (not_replace ? 0: status_reg_dirty[(set)*(NUM_WAY) + dir_result_way_o ] ) ;    
  assign dir_result_last_flush_o = flush_issue_reg_1 ? flushDone_reg_1 : 1'b0 ;
  assign dir_result_flush_o      = flush_issue_reg_1 ;
  assign dir_result_victim_tag_o = ways[dir_result_way_o*`TAG_BITS+:`TAG_BITS];//ways[flush_way*`TAG_BITS+:`TAG_BITS];
  //assign dir_result_l2cidx_o   = flush_issue_reg_1 ? 0 : read_bits_reg_l2cidx ;
  assign dir_result_param_o      = flush_issue_reg_1 ? 0 : read_bits_reg_param ;

endmodule

