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
// Author: Tan, Zhiyuan
// Description: Lsu missing status holding registers

`timescale 1ns/1ns
`include "define.v"

module mshr_backup (
  input                                             clk                       ,
  input                                             rst_n                     ,

  //from mshr
  input                                             from_addr_valid_i         ,
  output                                            from_addr_ready_o         ,
  input   [`DEPTH_WARP-1:0]                         from_addr_warp_id_i       ,
  input                                             from_addr_wfd_i           ,
  input                                             from_addr_wxd_i           ,
  //input                                             from_addr_isvec_i         ,
  input   [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]         from_addr_reg_idxw_i      ,
  input   [`NUM_THREAD-1:0]                         from_addr_mask_i          ,
  input                                             from_addr_unsigned_i      ,
  input   [`BYTESOFWORD*`NUM_THREAD-1:0]            from_addr_wordoffset1h_i  ,
  input                                             from_addr_iswrite_i       ,

  //send idx_entry to addr
  output  [$clog2(`LSU_NMSHRENTRY)-1:0]             idx_entry_o               ,

  //from dcache/shared
  input                                             from_dcache_valid_i       ,
  output                                            from_dcache_ready_o       ,
  input   [$clog2(`LSU_NMSHRENTRY)-1:0]             from_dcache_instrid_i     ,
  input   [`XLEN*`NUM_THREAD-1:0]                   from_dcache_data_i        ,
  input   [`NUM_THREAD-1:0]                         from_dcache_activemask_i  ,

  //to pipe
  output                                            to_pipe_valid_o           ,
  input                                             to_pipe_ready_i           ,
  output  [`DEPTH_WARP-1:0]                         to_pipe_warp_id_o         ,
  output                                            to_pipe_wfd_o             ,
  output                                            to_pipe_wxd_o             ,
  //output                                            to_pipe_isvec_o           ,
  output  [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]         to_pipe_reg_idxw_o        ,
  output  [`NUM_THREAD-1:0]                         to_pipe_mask_o            ,
  //output                                            to_pipe_unsigned_o        ,
  //output  [`BYTESOFWORD*`NUM_THREAD-1:0]            to_pipe_wordoffset1h_o    ,
  output                                            to_pipe_iswrite_o         ,
  output  [`XLEN*`NUM_THREAD-1:0]                   to_pipe_data_o            
);

  wire to_pipe_unsigned;
  wire [`BYTESOFWORD*`NUM_THREAD-1:0] to_pipe_wordoffset1h;
  //mshr entry size: LSU_NMSHRENTRY
  reg  [`XLEN*`NUM_THREAD*`LSU_NMSHRENTRY-1:0]             data            ;
  reg  [`DEPTH_WARP*`LSU_NMSHRENTRY-1:0]                   tag_warp_id     ;
  reg  [`LSU_NMSHRENTRY-1:0]                               tag_wfd         ;
  reg  [`LSU_NMSHRENTRY-1:0]                               tag_wxd         ;
  //reg  [`LSU_NMSHRENTRY-1:0]                               tag_isvec       ;
  reg  [(`REGIDX_WIDTH+`REGEXT_WIDTH)*`LSU_NMSHRENTRY-1:0] tag_reg_idxw    ;
  reg  [`NUM_THREAD*`LSU_NMSHRENTRY-1:0]                   tag_mask        ;
  reg  [`LSU_NMSHRENTRY-1:0]                               tag_unsigned    ;
  reg  [`BYTESOFWORD*`NUM_THREAD*`LSU_NMSHRENTRY-1:0]      tag_wordoffset1h;
  reg  [`LSU_NMSHRENTRY-1:0]                               tag_iswrite     ;

  //current mask and used information
  reg  [`NUM_THREAD*`LSU_NMSHRENTRY-1:0]                   current_mask    ;
  reg  [`LSU_NMSHRENTRY-1:0]                               used            ;

  //reg_req
  //reg  [`DEPTH_WARP-1:0]                 reg_req_warp_id     ;
  //reg                                    reg_req_wfd         ;
  //reg                                    reg_req_wxd         ;
  //reg                                    reg_req_isvec       ;
  //reg  [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] reg_req_reg_idxw    ;
  reg  [`NUM_THREAD-1:0]                 reg_req_mask        ;
  //reg                                    reg_req_unsigned    ;
  //reg  [`BYTESOFWORD*`NUM_THREAD-1:0]    reg_req_wordoffset1h;
  //reg                                    reg_req_iswrite     ;

  //inv_activemask
  wire [`NUM_THREAD-1:0]             inv_activemask     ;
  
  assign inv_activemask = ~from_dcache_activemask_i;
  
  //PriorityEncoder: complete, ~used
  wire [`LSU_NMSHRENTRY-1:0]         complete           ;
  wire [`LSU_NMSHRENTRY-1:0]         pri_complete_oh    ;
  wire [$clog2(`LSU_NMSHRENTRY)-1:0] pri_complete_bin   ;
  wire [`LSU_NMSHRENTRY-1:0]         pri_nused_oh       ;
  wire [$clog2(`LSU_NMSHRENTRY)-1:0] pri_nused_bin      ;

  genvar n;
  generate for(n=0;n<`LSU_NMSHRENTRY;n=n+1) begin: COMPLETE //assign complete
    assign complete[n] = (current_mask[`NUM_THREAD*(n+1)-1:`NUM_THREAD*n]=='d0) && used[n] ;
  end
  endgenerate
  
  fixed_pri_arb #(
    .ARB_WIDTH  (`LSU_NMSHRENTRY) 
  )
  complete_oh(
    .req    (complete       ) ,
    .grant  (pri_complete_oh)   
  );

  one2bin #(
    .ONE_WIDTH  (`LSU_NMSHRENTRY        ) ,
    .BIN_WIDTH  ($clog2(`LSU_NMSHRENTRY)) 
  )
  complete_bin(
    .oh    (pri_complete_oh ) ,
    .bin   (pri_complete_bin) 
  );
  
  fixed_pri_arb #(
    .ARB_WIDTH  (`LSU_NMSHRENTRY) 
  )
  nused_oh(
    .req    (~used          ) ,
    .grant  (pri_nused_oh   )   
  );

  one2bin #(
    .ONE_WIDTH  (`LSU_NMSHRENTRY        ) ,
    .BIN_WIDTH  ($clog2(`LSU_NMSHRENTRY)) 
  )
  nused_bin(
    .oh    (pri_nused_oh    ) ,
    .bin   (pri_nused_bin   ) 
  );

  //output entry and valid entry
  wire [$clog2(`LSU_NMSHRENTRY)-1:0] output_entry       ;
  wire [$clog2(`LSU_NMSHRENTRY)-1:0] valid_entry        ;
  assign output_entry = (|complete) ? pri_complete_bin : 'd0           ;
  assign valid_entry  = (&used)     ? 'd0              : pri_nused_bin ;

  //fsm defines
  localparam S_IDLE = 2'b00,
             S_ADD  = 2'b01,
             S_OUT  = 2'b10;

  reg [1:0] c_state ;
  reg [1:0] n_state ;

  //output ready signals and idx_entry
  assign from_dcache_ready_o = c_state == S_IDLE             ;
  assign from_addr_ready_o   = (c_state==S_IDLE) && !(&used) ;
  assign idx_entry_o         = (from_addr_valid_i&&from_addr_ready_o) ? valid_entry : 'd0 ;

  //bitset: for used and complete
  wire [`LSU_NMSHRENTRY-1:0] valid_entry_true   ;
  wire [`LSU_NMSHRENTRY-1:0] valid_entry_false  ;
  wire [`LSU_NMSHRENTRY-1:0] output_entry_true  ;
  wire [`LSU_NMSHRENTRY-1:0] output_entry_false ;

  bin2one #(
    .ONE_WIDTH  (`LSU_NMSHRENTRY        ) ,
    .BIN_WIDTH  ($clog2(`LSU_NMSHRENTRY))
  )
  valid_entry_oh(
    .bin    (valid_entry      ) ,
    .oh     (valid_entry_true )   
  );

  bin2one #(
    .ONE_WIDTH  (`LSU_NMSHRENTRY        ) ,
    .BIN_WIDTH  ($clog2(`LSU_NMSHRENTRY))
  )
  output_entry_oh(
    .bin    (output_entry     ) ,
    .oh     (output_entry_true)   
  );

  assign valid_entry_false  = ~valid_entry_true  ;
  assign output_entry_false = ~output_entry_true ;

  //fsm state transfer
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      c_state <= 2'b00;
    end
    else begin
      c_state <= n_state;
    end
  end

  always@(*) begin
    case(c_state)
      S_IDLE  :begin
        if(from_dcache_ready_o && from_dcache_valid_i) begin
          if(from_addr_ready_o && from_addr_valid_i) begin
            n_state = S_ADD;
          end
          else if(to_pipe_ready_i && (current_mask[`NUM_THREAD*(from_dcache_instrid_i+1)-1 -:`NUM_THREAD]==from_dcache_activemask_i)) begin
            n_state = S_OUT;
          end
          else begin
            n_state = S_IDLE;
          end
        end
        else if((|complete) && to_pipe_ready_i) begin
          n_state = S_OUT;
        end
        else begin
          n_state = S_IDLE;
        end
      end
      S_OUT   :begin
        if(to_pipe_ready_i && (|(complete&valid_entry_false))) begin
          n_state = S_OUT;
        end
        else begin
          n_state = S_IDLE;
        end
      end
      S_ADD   :begin
        if(to_pipe_ready_i && (|complete)) begin
          n_state = S_OUT;
        end
        else begin
          n_state = S_IDLE;
        end
      end
      default :begin
        n_state = S_IDLE;
      end
    endcase
  end

  //data for write: with activemask
  wire [`XLEN*`NUM_THREAD-1:0] data_with_mask;
  
  genvar i;
  generate for(i=0;i<`NUM_THREAD;i=i+1) begin: DATA_WRITE
    assign data_with_mask[`XLEN*(i+1)-1:`XLEN*i] = from_dcache_activemask_i[i] ? from_dcache_data_i[`XLEN*(i+1)-1:`XLEN*i] : 'd0 ;
  end
  endgenerate

  //fsm operation: data_write, tag_write, used, current_mask, reg_req
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      data                 <= 'd0;
      tag_warp_id          <= 'd0;
      tag_wfd              <= 'd0;
      tag_wxd              <= 'd0;
      //tag_isvec            <= 'd0;
      tag_reg_idxw         <= 'd0;
      tag_mask             <= 'd0;
      tag_unsigned         <= 'd0;
      tag_wordoffset1h     <= 'd0;
      tag_iswrite          <= 'd0;
      current_mask         <= 'd0;
      used                 <= 'd0;
      //reg_req_warp_id      <= 'd0;
      //reg_req_wfd          <= 'd0;
      //reg_req_wxd          <= 'd0;
      //reg_req_isvec        <= 'd0;
      //reg_req_reg_idxw     <= 'd0;
      reg_req_mask         <= 'd0;
      //reg_req_unsigned     <= 'd0;
      //reg_req_wordoffset1h <= 'd0;
      //reg_req_iswrite      <= 'd0;
    end
    else begin
      case(c_state)
        S_IDLE  :begin
          if(from_dcache_ready_o && from_dcache_valid_i) begin //write data
            data[`XLEN*`NUM_THREAD*(from_dcache_instrid_i+1)-1 -:`XLEN*`NUM_THREAD] <= data_with_mask | data[`XLEN*`NUM_THREAD*(from_dcache_instrid_i+1)-1 -:`XLEN*`NUM_THREAD];
            current_mask[`NUM_THREAD*(from_dcache_instrid_i+1)-1 -:`NUM_THREAD]     <= current_mask[`NUM_THREAD*(from_dcache_instrid_i+1)-1 -:`NUM_THREAD] & inv_activemask;
            if(from_addr_ready_o && from_addr_valid_i) begin   //dcache and addr send require in one cycle: reg from_addr
              //reg_req_warp_id      <= from_addr_warp_id_i     ;
              //reg_req_wfd          <= from_addr_wfd_i         ;
              //reg_req_wxd          <= from_addr_wxd_i         ;
              //reg_req_isvec        <= from_addr_isvec_i       ;
              //reg_req_reg_idxw     <= from_addr_reg_idxw_i    ;
              reg_req_mask         <= from_addr_mask_i        ;
              //reg_req_unsigned     <= from_addr_unsigned_i    ;
              //reg_req_wordoffset1h <= from_addr_wordoffset1h_i;
              //reg_req_iswrite      <= from_addr_iswrite_i     ;
            end
            else begin
              //reg_req_warp_id      <= reg_req_warp_id         ;
              //reg_req_wfd          <= reg_req_wfd             ;
              //reg_req_wxd          <= reg_req_wxd             ;
              //reg_req_isvec        <= reg_req_isvec           ;
              //reg_req_reg_idxw     <= reg_req_reg_idxw        ;
              reg_req_mask         <= reg_req_mask            ;
              //reg_req_unsigned     <= reg_req_unsigned        ;
              //reg_req_wordoffset1h <= reg_req_wordoffset1h    ;
              //reg_req_iswrite      <= reg_req_iswrite         ;
            end
          end
          else if(from_addr_ready_o && from_addr_valid_i) begin //accept tag, empty data
            used                                                                                          <= used | valid_entry_true ;
            tag_warp_id[`DEPTH_WARP*(valid_entry+1)-1 -:`DEPTH_WARP]                                      <= from_addr_warp_id_i     ;
            tag_wfd[valid_entry]                                                                          <= from_addr_wfd_i         ;
            tag_wxd[valid_entry]                                                                          <= from_addr_wxd_i         ;
            //tag_isvec[valid_entry]                                                                        <= from_addr_isvec_i       ;
            tag_reg_idxw[(`REGIDX_WIDTH+`REGEXT_WIDTH)*(valid_entry+1)-1 -:(`REGIDX_WIDTH+`REGEXT_WIDTH)] <= from_addr_reg_idxw_i    ;
            tag_mask[`NUM_THREAD*(valid_entry+1)-1 -:`NUM_THREAD]                                         <= from_addr_mask_i        ;
            tag_unsigned[valid_entry]                                                                     <= from_addr_unsigned_i    ;
            tag_wordoffset1h[`NUM_THREAD*`BYTESOFWORD*(valid_entry+1)-1 -:`NUM_THREAD*`BYTESOFWORD]       <= from_addr_wordoffset1h_i;
            tag_iswrite[valid_entry]                                                                      <= from_addr_iswrite_i     ;
            data[`XLEN*`NUM_THREAD*(valid_entry+1)-1 -:`XLEN*`NUM_THREAD]                                 <= 'd0                     ;
            current_mask[`NUM_THREAD*(valid_entry+1)-1 -:`NUM_THREAD]                                     <= from_addr_mask_i        ;
          end
          else begin //no operation
            used                 <= used                ;
            //reg_req_warp_id      <= reg_req_warp_id     ;
            //reg_req_wfd          <= reg_req_wfd         ;
            //reg_req_wxd          <= reg_req_wxd         ;
            //reg_req_isvec        <= reg_req_isvec       ;
            //reg_req_reg_idxw     <= reg_req_reg_idxw    ;
            reg_req_mask         <= reg_req_mask        ;
            //reg_req_unsigned     <= reg_req_unsigned    ;
            //reg_req_wordoffset1h <= reg_req_wordoffset1h;
            //reg_req_iswrite      <= reg_req_iswrite     ;
          end
        end
        S_ADD:   begin //update tag information
          used                                                                                          <= used | valid_entry_true ;
          tag_warp_id[`DEPTH_WARP*(valid_entry+1)-1 -:`DEPTH_WARP]                                      <= from_addr_warp_id_i     ;
          tag_wfd[valid_entry]                                                                          <= from_addr_wfd_i         ;
          tag_wxd[valid_entry]                                                                          <= from_addr_wxd_i         ;
          //tag_isvec[valid_entry]                                                                        <= from_addr_isvec_i       ;
          tag_reg_idxw[(`REGIDX_WIDTH+`REGEXT_WIDTH)*(valid_entry+1)-1 -:(`REGIDX_WIDTH+`REGEXT_WIDTH)] <= from_addr_reg_idxw_i    ;
          tag_mask[`NUM_THREAD*(valid_entry+1)-1 -:`NUM_THREAD]                                         <= from_addr_mask_i        ;
          tag_unsigned[valid_entry]                                                                     <= from_addr_unsigned_i    ;
          tag_wordoffset1h[`NUM_THREAD*`BYTESOFWORD*(valid_entry+1)-1 -:`NUM_THREAD*`BYTESOFWORD]       <= from_addr_wordoffset1h_i;
          tag_iswrite[valid_entry]                                                                      <= from_addr_iswrite_i     ;
          data[`XLEN*`NUM_THREAD*(valid_entry+1)-1 -:`XLEN*`NUM_THREAD]                                 <= 'd0                     ;
          current_mask[`NUM_THREAD*(valid_entry+1)-1 -:`NUM_THREAD]                                     <= reg_req_mask            ;
        end
        S_OUT:   begin //update used information
          if(to_pipe_valid_o && to_pipe_ready_i) begin
            used <= used & output_entry_false;
          end
          else begin
            used <= used;
          end
        end
        default: begin //no operation
          used                 <= used                ;
          //reg_req_warp_id      <= reg_req_warp_id     ;
          //reg_req_wfd          <= reg_req_wfd         ;
          //reg_req_wxd          <= reg_req_wxd         ;
          //reg_req_isvec        <= reg_req_isvec       ;
          //reg_req_reg_idxw     <= reg_req_reg_idxw    ;
          reg_req_mask         <= reg_req_mask        ;
          //reg_req_unsigned     <= reg_req_unsigned    ;
          //reg_req_wordoffset1h <= reg_req_wordoffset1h;
          //reg_req_iswrite      <= reg_req_iswrite     ;
        end
      endcase
    end
  end

  //output to pipe: tag
  wire [`XLEN*`NUM_THREAD-1:0]           raw_data            ;
  wire [`XLEN*`NUM_THREAD-1:0]           extract_data        ;
  wire [`XLEN*`NUM_THREAD-1:0]           output_data         ;
  //wire [`DEPTH_WARP-1:0]                 to_pipe_warp_id     ;
  //wire                                   to_pipe_wfd         ;
  //wire                                   to_pipe_wxd         ;
  //wire                                   to_pipe_isvec       ;
  //wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] to_pipe_reg_idxw    ;
  //wire [`NUM_THREAD-1:0]                 to_pipe_mask        ;
  //wire                                   to_pipe_unsigned    ;
  //wire [`BYTESOFWORD*`NUM_THREAD-1:0]    to_pipe_wordoffset1h;
  //wire                                   to_pipe_iswrite     ;

  /*
  genvar m;
  generate for(m=0;m<`NUM_THREAD;m=m+1) begin: OUTPUT_TAG
    always@(*) begin
      if(output_entry == m) begin
        to_pipe_warp_id      = tag_warp_id[`DEPTH_WARP*(m+1)-1:`DEPTH_WARP*m]                                     ;
        to_pipe_wfd          = tag_wfd[m]                                                                         ;
        to_pipe_wxd          = tag_wxd[m]                                                                         ;
        to_pipe_isvec        = tag_isvec[m]                                                                       ;
        to_pipe_reg_idxw     = tag_reg_idxw[(`REGIDX_WIDTH+`REGEXT_WIDTH)*(m+1)-1:(`REGIDX_WIDTH+`REGEXT_WIDTH)*m];
        to_pipe_mask         = tag_mask[`NUM_THREAD*(m+1)-1:`NUM_THREAD*m]                                        ;
        to_pipe_unsigned     = tag_unsigned[m]                                                                    ;
        to_pipe_wordoffset1h = tag_wordoffset1h[`NUM_THREAD*`BYTESOFWORD*(m+1)-1:`NUM_THREAD*`BYTESOFWORD*m]      ;
        to_pipe_iswrite      = tag_iswrite[m]                                                                     ;
        raw_data             = data[`XLEN*`NUM_THREAD*(m+1)-1:`XLEN*`NUM_THREAD*m]                                ;
      end
    end
  end
  endgenerate
  */

  assign raw_data = data[`XLEN*`NUM_THREAD*(output_entry+1)-1 -:`XLEN*`NUM_THREAD];

  genvar j;
  generate for(j=0;j<`NUM_THREAD;j=j+1) begin: OUTPUT_DATA
    byte_extract raw(
      .is_uint    (to_pipe_unsigned                                         ),
      .sel        (to_pipe_wordoffset1h[`BYTESOFWORD*(j+1)-1:`BYTESOFWORD*j]),
      .in         (raw_data[`XLEN*(j+1)-1:`XLEN*j]                          ),
      .result     (extract_data[`XLEN*(j+1)-1:`XLEN*j]                      )
    );

    assign output_data[`XLEN*(j+1)-1:`XLEN*j] = extract_data[`XLEN*(j+1)-1:`XLEN*j] ;
  end
  endgenerate
 
  assign to_pipe_valid_o      = (|complete) && (c_state==S_OUT)                                                               ;
  assign to_pipe_warp_id_o    = tag_warp_id[`DEPTH_WARP*(output_entry+1)-1 -:`DEPTH_WARP]                                     ;
  assign to_pipe_wfd_o        = tag_wfd[output_entry]                                                                         ;
  assign to_pipe_wxd_o        = tag_wxd[output_entry]                                                                         ;
  //assign to_pipe_isvec_o      = tag_isvec[output_entry]                                                                       ;
  assign to_pipe_reg_idxw_o   = tag_reg_idxw[(`REGIDX_WIDTH+`REGEXT_WIDTH)*(output_entry+1)-1 -:(`REGIDX_WIDTH+`REGEXT_WIDTH)];
  assign to_pipe_mask_o       = tag_mask[`NUM_THREAD*(output_entry+1)-1 -:`NUM_THREAD]                                        ;
  assign to_pipe_unsigned     = tag_unsigned[output_entry]                                                                    ;
  assign to_pipe_wordoffset1h = tag_wordoffset1h[`NUM_THREAD*`BYTESOFWORD*(output_entry+1)-1 -:`NUM_THREAD*`BYTESOFWORD]      ;
  assign to_pipe_iswrite_o    = tag_iswrite[output_entry]                                                                     ;
  assign to_pipe_data_o       = output_data                                                                                   ;

endmodule
