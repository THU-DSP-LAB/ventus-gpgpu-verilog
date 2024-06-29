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

module mshr (
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
  //sram wires
  wire                               sram_in_data_ren  ;
  wire [$clog2(`LSU_NMSHRENTRY)-1:0] sram_in_data_raddr;
  reg                                sram_in_data_wen  ;
  reg  [$clog2(`LSU_NMSHRENTRY)-1:0] sram_in_data_waddr;
  reg  [`XLEN*`NUM_THREAD-1:0]       sram_in_data_wmask;
  reg  [`XLEN*`NUM_THREAD-1:0]       sram_in_data_bits ;
  wire [`XLEN*`NUM_THREAD-1:0]       sram_out_data_bits;

  wire                                                             sram_in_tag_ren  ;
  wire [$clog2(`LSU_NMSHRENTRY)-1:0]                               sram_in_tag_raddr;
  reg                                                              sram_in_tag_wen  ;
  wire [$clog2(`LSU_NMSHRENTRY)-1:0]                               sram_in_tag_waddr;
  wire [3+`NUM_THREAD*5+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP:0] sram_in_tag_wmask;
  wire [3+`NUM_THREAD*5+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP:0] sram_in_tag_bits ;
  wire [3+`NUM_THREAD*5+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP:0] sram_out_tag_bits;

  wire [`DEPTH_WARP-1:0]                 sram_in_tag_warp_id     ;
  wire                                   sram_in_tag_wfd         ;
  wire                                   sram_in_tag_wxd         ;
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] sram_in_tag_reg_idxw    ;
  wire [`NUM_THREAD-1:0]                 sram_in_tag_mask        ;
  wire                                   sram_in_tag_unsigned    ;
  wire [`BYTESOFWORD*`NUM_THREAD-1:0]    sram_in_tag_wordoffset1h;
  wire                                   sram_in_tag_iswrite     ;

  //current mask and used information
  reg  [`NUM_THREAD*`LSU_NMSHRENTRY-1:0]                   current_mask    ;
  reg  [`LSU_NMSHRENTRY-1:0]                               used            ;

  //reg_req
  reg  [`NUM_THREAD-1:0]             reg_req_mask       ;

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
    assign complete[n]      = (current_mask[`NUM_THREAD*(n+1)-1-:`NUM_THREAD]=='d0) && used[n] ;
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
  localparam S_IDLE  = 2'b00,
             S_ADD   = 2'b01,
             S_OUT_1 = 2'b10,
             S_OUT_2 = 2'b11;

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
          else if(current_mask[`NUM_THREAD*(from_dcache_instrid_i+1)-1 -:`NUM_THREAD]==from_dcache_activemask_i) begin
            n_state = S_OUT_1;
          end
          else begin
            n_state = S_IDLE;
          end
        end
        else if(|complete) begin
          n_state = S_OUT_1;
        end
        else begin
          n_state = S_IDLE;
        end
      end
      S_ADD   :begin
        if(|complete) begin
          n_state = S_OUT_1;
        end
        else begin
          n_state = S_IDLE;
        end
      end
      S_OUT_1 :begin
        if(to_pipe_ready_i) begin
          n_state = S_OUT_2;
        end
        else begin
          n_state = S_OUT_1;
        end
      end
      S_OUT_2 :begin
        if(to_pipe_ready_i) begin
          if(|(complete&output_entry_false)) begin
            n_state = S_OUT_1;
          end
          else begin
            n_state = S_IDLE;
          end
        end
        else begin
          n_state = S_OUT_2;
        end
      end
      default :begin
        n_state = S_IDLE;
      end
    endcase
  end 

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      used         <= 'd0;
      current_mask <= 'd0;
      reg_req_mask <= 'd0;
    end
    else begin
      case(c_state)
        S_IDLE  : begin
          if(from_dcache_valid_i && from_dcache_ready_o) begin
            used <= used;
            current_mask[`NUM_THREAD*(from_dcache_instrid_i+1)-1 -:`NUM_THREAD] <= current_mask[`NUM_THREAD*(from_dcache_instrid_i+1)-1 -:`NUM_THREAD] & inv_activemask;
            if(from_addr_valid_i && from_addr_ready_o) begin
              reg_req_mask <= from_addr_mask_i;
            end
            else begin
              reg_req_mask <= reg_req_mask;
            end
          end
          else if(from_addr_valid_i && from_addr_ready_o) begin
            used <= used | valid_entry_true;
            reg_req_mask <= reg_req_mask;
            current_mask[`NUM_THREAD*(valid_entry+1)-1 -:`NUM_THREAD] <= from_addr_mask_i;
          end
          else begin
            used         <= used        ;
            reg_req_mask <= reg_req_mask;
            current_mask <= current_mask;
          end
        end
        S_ADD   : begin
          used         <= used | valid_entry_true;
          reg_req_mask <= reg_req_mask           ;
          current_mask[`NUM_THREAD*(valid_entry+1)-1 -:`NUM_THREAD] <= reg_req_mask;
        end
        S_OUT_2 : begin
          reg_req_mask <= reg_req_mask;
          current_mask <= current_mask;
          if(to_pipe_valid_o && to_pipe_ready_i) begin
            used <= used & output_entry_false;
          end
          else begin
            used <= used;
          end
        end
        default : begin
          used         <= used        ;
          reg_req_mask <= reg_req_mask;
          current_mask <= current_mask;
        end
      endcase
    end
  end

  assign sram_in_tag_warp_id      = from_addr_warp_id_i     ;
  assign sram_in_tag_wfd          = from_addr_wfd_i         ;
  assign sram_in_tag_wxd          = from_addr_wxd_i         ;
  assign sram_in_tag_reg_idxw     = from_addr_reg_idxw_i    ;
  assign sram_in_tag_mask         = from_addr_mask_i        ;
  assign sram_in_tag_unsigned     = from_addr_unsigned_i    ;
  assign sram_in_tag_wordoffset1h = from_addr_wordoffset1h_i;
  assign sram_in_tag_iswrite      = from_addr_iswrite_i     ;

  assign sram_in_tag_bits = {sram_in_tag_warp_id     ,  
                             sram_in_tag_wfd         ,
                             sram_in_tag_wxd         ,
                             sram_in_tag_reg_idxw    ,
                             sram_in_tag_mask        ,
                             sram_in_tag_unsigned    ,
                             sram_in_tag_wordoffset1h,
                             sram_in_tag_iswrite     };  

  assign sram_in_data_raddr = output_entry;
  
  assign sram_in_tag_raddr = output_entry;
  assign sram_in_tag_waddr = valid_entry ;
  assign sram_in_tag_wmask = {(4+`NUM_THREAD*5+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP){1'b1}};

  //when state is S_OUT_1, read SRAM;
  //when state is S_OUT_2, output SRAM results;
  assign sram_in_tag_ren   = c_state == S_OUT_1;
  assign sram_in_data_ren  = c_state == S_OUT_1;

  wire [`XLEN*`NUM_THREAD-1:0] from_dcache_mask_to_sram;

  always@(*) begin
    case(c_state)
      S_IDLE  :begin
        if(from_dcache_ready_o && from_dcache_valid_i) begin //write data
          sram_in_data_wen   = 1'b1                       ;
          sram_in_data_wmask = from_dcache_mask_to_sram   ;
          sram_in_data_waddr = from_dcache_instrid_i      ;
          sram_in_data_bits  = from_dcache_data_i         ;
          sram_in_tag_wen    = 1'b0                       ;
        end
        else if(from_addr_ready_o && from_addr_valid_i) begin //accept tag, empty data
          sram_in_data_wen   = 1'b1                       ;
          sram_in_data_wmask = {(`NUM_THREAD*`XLEN){1'b1}};
          sram_in_data_waddr = valid_entry                ;
          sram_in_data_bits  = 'd0                        ;
          sram_in_tag_wen    = 1'b1                       ;
        end
        else begin //no operation
          sram_in_data_wen   = 1'b0                       ;
          sram_in_data_wmask = {(`NUM_THREAD*`XLEN){1'b1}};
          sram_in_data_waddr = valid_entry                ;
          sram_in_data_bits  = 'd0                        ;
          sram_in_tag_wen    = 1'b0                       ;
        end
      end
      S_ADD:   begin //update tag information
        sram_in_data_wen   = 1'b1                       ;
        sram_in_data_wmask = {(`NUM_THREAD*`XLEN){1'b1}};
        sram_in_data_waddr = valid_entry                ;
        sram_in_data_bits  = 'd0                        ;
        sram_in_tag_wen    = 1'b1                       ;
      end
      default: begin //no operation
        sram_in_data_wen   = 1'b0                       ;
        sram_in_data_wmask = {(`NUM_THREAD*`XLEN){1'b0}};
        sram_in_data_waddr = valid_entry                ;
        sram_in_data_bits  = 'd0                        ;
        sram_in_tag_wen    = 1'b0                       ;
      end
    endcase
  end

  //output to pipe: tag
  wire [`XLEN*`NUM_THREAD-1:0]           raw_data            ;
  wire [`XLEN*`NUM_THREAD-1:0]           extract_data        ;
  wire [`XLEN*`NUM_THREAD-1:0]           output_data         ;

  assign raw_data = sram_out_data_bits;

  genvar j;
  generate for(j=0;j<`NUM_THREAD;j=j+1) begin: OUTPUT_DATA
    assign from_dcache_mask_to_sram[`XLEN*(j+1)-1-:`XLEN] = from_dcache_activemask_i[j] ? {`XLEN{1'b1}} : {`XLEN{1'b0}}; 

    byte_extract raw(
      .is_uint    (to_pipe_unsigned                                         ),
      .sel        (to_pipe_wordoffset1h[`BYTESOFWORD*(j+1)-1:`BYTESOFWORD*j]),
      .in         (raw_data[`XLEN*(j+1)-1:`XLEN*j]                          ),
      .result     (extract_data[`XLEN*(j+1)-1:`XLEN*j]                      )
    );

    assign output_data[`XLEN*(j+1)-1:`XLEN*j] = extract_data[`XLEN*(j+1)-1:`XLEN*j] ;
  end
  endgenerate

  assign to_pipe_valid_o      = c_state==S_OUT_2 && (|complete)                                                            ;
  assign to_pipe_warp_id_o    = sram_out_tag_bits[3+`NUM_THREAD*5+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP-:`DEPTH_WARP]    ;
  assign to_pipe_wfd_o        = sram_out_tag_bits[3+`NUM_THREAD*5+`REGIDX_WIDTH+`REGEXT_WIDTH]                             ;
  assign to_pipe_wxd_o        = sram_out_tag_bits[2+`NUM_THREAD*5+`REGIDX_WIDTH+`REGEXT_WIDTH]                             ;
  assign to_pipe_reg_idxw_o   = sram_out_tag_bits[1+`NUM_THREAD*5+`REGIDX_WIDTH+`REGEXT_WIDTH-:`REGIDX_WIDTH+`REGEXT_WIDTH];
  assign to_pipe_mask_o       = sram_out_tag_bits[1+`NUM_THREAD*5-:`NUM_THREAD]                                            ;
  assign to_pipe_unsigned     = sram_out_tag_bits[`NUM_THREAD*4]                                                           ;
  assign to_pipe_wordoffset1h = sram_out_tag_bits[`NUM_THREAD*4-:`NUM_THREAD*4]                                            ;
  assign to_pipe_iswrite_o    = sram_out_tag_bits[0]                                                                       ;
  assign to_pipe_data_o       = output_data;

  dualportSRAM #(
    .BITWIDTH   (`XLEN*`NUM_THREAD      ),
    .DEPTH      ($clog2(`LSU_NMSHRENTRY))
  )
  mshr_data (
    .CLK  (clk               ),
    .RSTN (rst_n             ),
    .D    (sram_in_data_bits ),
    .Q    (sram_out_data_bits),
    .REB  (sram_in_data_ren  ),
    .WEB  (sram_in_data_wen  ), 
    .BWEB (sram_in_data_wmask), 
    .AA   (sram_in_data_waddr), 
    .AB   (sram_in_data_raddr) 
  );

  dualportSRAM #(
    .BITWIDTH   (4+`NUM_THREAD*5+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP),
    .DEPTH      ($clog2(`LSU_NMSHRENTRY)                                )
  )
  mshr_tag (
    .CLK  (clk              ),
    .RSTN (rst_n            ),
    .D    (sram_in_tag_bits ),
    .Q    (sram_out_tag_bits),
    .REB  (sram_in_tag_ren  ),
    .WEB  (sram_in_tag_wen  ), 
    .BWEB (sram_in_tag_wmask), 
    .AA   (sram_in_tag_waddr), 
    .AB   (sram_in_tag_raddr) 
  );
    

endmodule
