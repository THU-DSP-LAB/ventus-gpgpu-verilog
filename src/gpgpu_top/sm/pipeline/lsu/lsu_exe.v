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
// Description: Lsu main module

`timescale 1ns/1ns

//`define DEBUG

`include "define.v"
//`include "IDecode_define.v"

module lsu_exe (
  input                                             clk                       ,
  input                                             rst_n                     ,

  //lsu req(vExeData)
  input                                             lsu_req_valid_i           ,
  output                                            lsu_req_ready_o           ,
  input   [`XLEN*`NUM_THREAD-1:0]                   lsu_req_in1_i             ,
  input   [`XLEN*`NUM_THREAD-1:0]                   lsu_req_in2_i             ,
  input   [`XLEN*`NUM_THREAD-1:0]                   lsu_req_in3_i             ,
  input   [`NUM_THREAD-1:0]                         lsu_req_mask_i            ,
  input   [`DEPTH_WARP-1:0]                         lsu_req_wid_i             ,
  input                                             lsu_req_isvec_i           ,
  input   [1:0]                                     lsu_req_mem_whb_i         ,
  input                                             lsu_req_mem_unsigned_i    ,
  input   [5:0]                                     lsu_req_alu_fn_i          ,
  input                                             lsu_req_is_vls12_i        ,
  input                                             lsu_req_disable_mask_i    ,
  input   [1:0]                                     lsu_req_mem_cmd_i         ,
  input   [1:0]                                     lsu_req_mop_i             ,
  input   [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]         lsu_req_reg_idxw_i        ,
  input                                             lsu_req_wvd_i             ,
  input                                             lsu_req_fence_i           ,
  input                                             lsu_req_wxd_i             ,
  input                                             lsu_req_atomic_i          ,
  input                                             lsu_req_aq_i              ,
  input                                             lsu_req_rl_i              ,

  //lsu rsp(rsp to pipe)
  output                                            lsu_rsp_valid_o           ,
  input                                             lsu_rsp_ready_i           ,
  output  [`DEPTH_WARP-1:0]                         lsu_rsp_warp_id_o         ,
  output                                            lsu_rsp_wfd_o             ,
  output                                            lsu_rsp_wxd_o             ,
  //output                                            lsu_rsp_isvec_o           ,
  output  [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]         lsu_rsp_reg_idxw_o        ,
  output  [`NUM_THREAD-1:0]                         lsu_rsp_mask_o            ,
  //output                                            lsu_rsp_unsigned_o        ,
  //output  [`BYTESOFWORD*`NUM_THREAD-1:0]            lsu_rsp_wordoffset1h_o    ,
  output                                            lsu_rsp_iswrite_o         ,
  output  [`XLEN*`NUM_THREAD-1:0]                   lsu_rsp_data_o            ,

  //dcache req
  output                                            dcache_req_valid_o        ,
  input                                             dcache_req_ready_i        ,
  output  [$clog2(`LSU_NMSHRENTRY)-1:0]             dcache_req_instrid_o      ,
  output  [`DCACHE_SETIDXBITS-1:0]                  dcache_req_setidx_o       ,
  output  [`DCACHE_TAGBITS-1:0]                     dcache_req_tag_o          ,
  output  [`NUM_THREAD-1:0]                         dcache_req_activemask_o   ,
  output  [`NUM_THREAD*`DCACHE_BLOCKOFFSETBITS-1:0] dcache_req_blockoffset_o  ,
  output  [`NUM_THREAD*`BYTESOFWORD-1:0]            dcache_req_wordoffset1h_o ,
  output  [`NUM_THREAD*`XLEN-1:0]                   dcache_req_data_o         ,
  output  [2:0]                                     dcache_req_opcode_o       ,
  output  [3:0]                                     dcache_req_param_o        ,

  //dcache rsp
  input                                             dcache_rsp_valid_i        ,
  output                                            dcache_rsp_ready_o        ,
  input   [$clog2(`LSU_NMSHRENTRY)-1:0]             dcache_rsp_instrid_i      ,
  input   [`XLEN*`NUM_THREAD-1:0]                   dcache_rsp_data_i         ,
  input   [`NUM_THREAD-1:0]                         dcache_rsp_activemask_i   ,

  //shared req
  output                                            shared_req_valid_o        ,
  input                                             shared_req_ready_i        ,
  output  [$clog2(`LSU_NMSHRENTRY)-1:0]             shared_req_instrid_o      ,
  output                                            shared_req_iswrite_o      ,
  output  [`DCACHE_TAGBITS-1:0]                     shared_req_tag_o          ,
  output  [`DCACHE_SETIDXBITS-1:0]                  shared_req_setidx_o       ,
  output  [`NUM_THREAD-1:0]                         shared_req_activemask_o   ,
  output  [`NUM_THREAD*`DCACHE_BLOCKOFFSETBITS-1:0] shared_req_blockoffset_o  ,
  output  [`NUM_THREAD*`BYTESOFWORD-1:0]            shared_req_wordoffset1h_o ,
  output  [`NUM_THREAD*`XLEN-1:0]                   shared_req_data_o         ,

  //shared rsp
  input                                             shared_rsp_valid_i        ,
  output                                            shared_rsp_ready_o        ,
  input   [$clog2(`LSU_NMSHRENTRY)-1:0]             shared_rsp_instrid_i      ,
  input   [`XLEN*`NUM_THREAD-1:0]                   shared_rsp_data_i         ,
  input   [`NUM_THREAD-1:0]                         shared_rsp_activemask_i   ,

  //fence_end
  output  [`NUM_WARP-1:0]                           fence_end_o               ,

  //connect csr
  input   [`XLEN-1:0]                               csr_pds_i                 ,
  input   [`XLEN-1:0]                               csr_numw_i                ,
  input   [`XLEN-1:0]                               csr_tid_i                 ,
  output  [`DEPTH_WARP-1:0]                         csr_wid_o                 
);

  localparam SHARED_ADDR_MAX = `SHAREMEM_SIZE;

  //connect input_fifo and addrcalculate
  wire                                   infifo_addr_valid        ;
  wire                                   infifo_addr_ready        ;
  wire [`XLEN*`NUM_THREAD-1:0]           infifo_addr_in1          ;
  wire [`XLEN*`NUM_THREAD-1:0]           infifo_addr_in2          ;
  wire [`XLEN*`NUM_THREAD-1:0]           infifo_addr_in3          ;
  wire [`NUM_THREAD-1:0]                 infifo_addr_mask         ;
  wire [`DEPTH_WARP-1:0]                 infifo_addr_wid          ;
  wire                                   infifo_addr_isvec        ;
  wire [1:0]                             infifo_addr_mem_whb      ;
  wire                                   infifo_addr_mem_unsigned ;
  wire [5:0]                             infifo_addr_alu_fn       ;
  wire                                   infifo_addr_is_vls12     ;
  wire                                   infifo_addr_disable_mask ;
  wire [1:0]                             infifo_addr_mem_cmd      ;
  wire [1:0]                             infifo_addr_mop          ;
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] infifo_addr_reg_idxw     ;
  wire                                   infifo_addr_wvd          ;
  wire                                   infifo_addr_fence        ;
  wire                                   infifo_addr_wxd          ;
  wire                                   infifo_addr_atomic       ;
  wire                                   infifo_addr_aq           ;
  wire                                   infifo_addr_rl           ;

  //enq.valid and enq.ready for input_fifo
  wire                                   input_fifo_enq_valid     ;
  wire                                   input_fifo_enq_ready     ;

  input_fifo infifo(
    .clk                (clk                     ),
    .rst_n              (rst_n                   ),
    .enq_valid_i        (input_fifo_enq_valid    ),
    .enq_ready_o        (input_fifo_enq_ready    ),
    .enq_in1_i          (lsu_req_in1_i           ),
    .enq_in2_i          (lsu_req_in2_i           ),
    .enq_in3_i          (lsu_req_in3_i           ),
    .enq_mask_i         (lsu_req_mask_i          ),
    .enq_wid_i          (lsu_req_wid_i           ),
    .enq_isvec_i        (lsu_req_isvec_i         ),
    .enq_mem_whb_i      (lsu_req_mem_whb_i       ),
    .enq_mem_unsigned_i (lsu_req_mem_unsigned_i  ),
    .enq_alu_fn_i       (lsu_req_alu_fn_i        ),
    .enq_is_vls12_i     (lsu_req_is_vls12_i      ),
    .enq_disable_mask_i (lsu_req_disable_mask_i  ),
    .enq_mem_cmd_i      (lsu_req_mem_cmd_i       ),
    .enq_mop_i          (lsu_req_mop_i           ),
    .enq_reg_idxw_i     (lsu_req_reg_idxw_i      ),
    .enq_wvd_i          (lsu_req_wvd_i           ),
    .enq_fence_i        (lsu_req_fence_i         ),
    .enq_wxd_i          (lsu_req_wxd_i           ),
    .enq_atomic_i       (lsu_req_atomic_i        ),
    .enq_aq_i           (lsu_req_aq_i            ),
    .enq_rl_i           (lsu_req_rl_i            ),
    .deq_valid_o        (infifo_addr_valid       ),
    .deq_ready_i        (infifo_addr_ready       ),
    .deq_in1_o          (infifo_addr_in1         ),
    .deq_in2_o          (infifo_addr_in2         ),
    .deq_in3_o          (infifo_addr_in3         ),
    .deq_mask_o         (infifo_addr_mask        ),
    .deq_wid_o          (infifo_addr_wid         ),
    .deq_isvec_o        (infifo_addr_isvec       ),
    .deq_mem_whb_o      (infifo_addr_mem_whb     ),
    .deq_mem_unsigned_o (infifo_addr_mem_unsigned),
    .deq_alu_fn_o       (infifo_addr_alu_fn      ),
    .deq_is_vls12_o     (infifo_addr_is_vls12    ),
    .deq_disable_mask_o (infifo_addr_disable_mask),
    .deq_mem_cmd_o      (infifo_addr_mem_cmd     ),
    .deq_mop_o          (infifo_addr_mop         ),
    .deq_reg_idxw_o     (infifo_addr_reg_idxw    ),
    .deq_wvd_o          (infifo_addr_wvd         ),
    .deq_fence_o        (infifo_addr_fence       ),
    .deq_wxd_o          (infifo_addr_wxd         ),
    .deq_atomic_o       (infifo_addr_atomic      ),
    .deq_aq_o           (infifo_addr_aq          ),
    .deq_rl_o           (infifo_addr_rl          )
  );

  //connect addrcalculate and mshr
  wire                                   addr_mshr_valid        ;
  wire                                   addr_mshr_ready        ;
  wire [`DEPTH_WARP-1:0]                 addr_mshr_warp_id      ;
  wire                                   addr_mshr_wfd          ;
  wire                                   addr_mshr_wxd          ;
  //wire                                   addr_mshr_isvec        ;
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] addr_mshr_reg_idxw     ;
  wire [`NUM_THREAD-1:0]                 addr_mshr_mask         ;
  //wire                                   addr_mshr_unsigned     ;
  wire [`BYTESOFWORD*`NUM_THREAD-1:0]    addr_mshr_wordoffset1h ;
  wire                                   addr_mshr_iswrite      ;
  wire [$clog2(`LSU_NMSHRENTRY)-1:0]     mshr_addr_idx_entry    ;

  addrcalculate #(
    .SHARED_ADDR_MAX (SHARED_ADDR_MAX)
  )
  addrcalc (
    .clk                      (clk                      ),
    .rst_n                    (rst_n                    ),
    .from_fifo_valid_i        (infifo_addr_valid        ),
    .from_fifo_ready_o        (infifo_addr_ready        ),
    .from_fifo_in1_i          (infifo_addr_in1          ),
    .from_fifo_in2_i          (infifo_addr_in2          ),
    .from_fifo_in3_i          (infifo_addr_in3          ),
    .from_fifo_mask_i         (infifo_addr_mask         ),
    .from_fifo_wid_i          (infifo_addr_wid          ),
    .from_fifo_isvec_i        (infifo_addr_isvec        ),
    .from_fifo_mem_whb_i      (infifo_addr_mem_whb      ),
    .from_fifo_mem_unsigned_i (infifo_addr_mem_unsigned ),
    .from_fifo_alu_fn_i       (infifo_addr_alu_fn       ),
    .from_fifo_is_vls12_i     (infifo_addr_is_vls12     ),
    .from_fifo_disable_mask_i (infifo_addr_disable_mask ),
    .from_fifo_mem_cmd_i      (infifo_addr_mem_cmd      ),
    .from_fifo_mop_i          (infifo_addr_mop          ),
    .from_fifo_reg_idxw_i     (infifo_addr_reg_idxw     ),
    .from_fifo_wvd_i          (infifo_addr_wvd          ),
    .from_fifo_fence_i        (infifo_addr_fence        ),
    .from_fifo_wxd_i          (infifo_addr_wxd          ),
    .from_fifo_atomic_i       (infifo_addr_atomic       ),
    .from_fifo_aq_i           (infifo_addr_aq           ),
    .from_fifo_rl_i           (infifo_addr_rl           ),
    .csr_pds_i                (csr_pds_i                ),
    .csr_numw_i               (csr_numw_i               ),
    .csr_tid_i                (csr_tid_i                ),
    .csr_wid_o                (csr_wid_o                ),
    .idx_entry_i              (mshr_addr_idx_entry      ),
    .to_mshr_valid_o          (addr_mshr_valid          ),
    .to_mshr_ready_i          (addr_mshr_ready          ),
    .to_mshr_warp_id_o        (addr_mshr_warp_id        ),
    .to_mshr_wfd_o            (addr_mshr_wfd            ),
    .to_mshr_wxd_o            (addr_mshr_wxd            ),
    //.to_mshr_isvec_o          (addr_mshr_isvec          ),
    .to_mshr_reg_idxw_o       (addr_mshr_reg_idxw       ),
    .to_mshr_mask_o           (addr_mshr_mask           ),
    .to_mshr_unsigned_o       (addr_mshr_unsigned       ),
    .to_mshr_wordoffset1h_o   (addr_mshr_wordoffset1h   ),
    .to_mshr_iswrite_o        (addr_mshr_iswrite        ),
    .to_shared_valid_o        (shared_req_valid_o       ),
    .to_shared_ready_i        (shared_req_ready_i       ),
    .to_shared_instrid_o      (shared_req_instrid_o     ),
    .to_shared_iswrite_o      (shared_req_iswrite_o     ),
    .to_shared_setidx_o       (shared_req_setidx_o      ),
    .to_shared_tag_o          (shared_req_tag_o         ),
    .to_shared_activemask_o   (shared_req_activemask_o  ),
    .to_shared_blockoffset_o  (shared_req_blockoffset_o ),
    .to_shared_wordoffset1h_o (shared_req_wordoffset1h_o),
    .to_shared_data_o         (shared_req_data_o        ),
    .to_dcache_valid_o        (dcache_req_valid_o       ),
    .to_dcache_ready_i        (dcache_req_ready_i       ),
    .to_dcache_instrid_o      (dcache_req_instrid_o     ),
    .to_dcache_setidx_o       (dcache_req_setidx_o      ),
    .to_dcache_tag_o          (dcache_req_tag_o         ),
    .to_dcache_activemask_o   (dcache_req_activemask_o  ),
    .to_dcache_blockoffset_o  (dcache_req_blockoffset_o ),
    .to_dcache_wordoffset1h_o (dcache_req_wordoffset1h_o),
    .to_dcache_data_o         (dcache_req_data_o        ),
    .to_dcache_opcode_o       (dcache_req_opcode_o      ),
    .to_dcache_param_o        (dcache_req_param_o       )
  );

  //connect rsp_arb and mshr
  wire                               arb_mshr_valid      ;
  wire                               arb_mshr_ready      ;
  wire [$clog2(`LSU_NMSHRENTRY)-1:0] arb_mshr_instrid    ;
  wire [`XLEN*`NUM_THREAD-1:0]       arb_mshr_data       ;
  wire [`NUM_THREAD-1:0]             arb_mshr_activemask ;

  rsp_arb rsparbiter(
    .in0_valid_i      (dcache_rsp_valid_i     ),
    .in0_ready_o      (dcache_rsp_ready_o     ),
    .in0_instrid_i    (dcache_rsp_instrid_i   ),
    .in0_data_i       (dcache_rsp_data_i      ),
    .in0_activemask_i (dcache_rsp_activemask_i),
    .in1_valid_i      (shared_rsp_valid_i     ),
    .in1_ready_o      (shared_rsp_ready_o     ),
    .in1_instrid_i    (shared_rsp_instrid_i   ),
    .in1_data_i       (shared_rsp_data_i      ),
    .in1_activemask_i (shared_rsp_activemask_i),
    .out_valid_o      (arb_mshr_valid         ),
    .out_ready_i      (arb_mshr_ready         ),
    .out_instrid_o    (arb_mshr_instrid       ),
    .out_data_o       (arb_mshr_data          ),
    .out_activemask_o (arb_mshr_activemask    )
  );

  mshr coalscer(
  //mshr_backup coalscer(
    .clk                      (clk                    ),
    .rst_n                    (rst_n                  ),
    .from_addr_valid_i        (addr_mshr_valid        ),
    .from_addr_ready_o        (addr_mshr_ready        ),
    .from_addr_warp_id_i      (addr_mshr_warp_id      ),
    .from_addr_wfd_i          (addr_mshr_wfd          ),
    .from_addr_wxd_i          (addr_mshr_wxd          ),
    //.from_addr_isvec_i        (addr_mshr_isvec        ),
    .from_addr_reg_idxw_i     (addr_mshr_reg_idxw     ),
    .from_addr_mask_i         (addr_mshr_mask         ),
    .from_addr_unsigned_i     (addr_mshr_unsigned     ),
    .from_addr_wordoffset1h_i (addr_mshr_wordoffset1h ),
    .from_addr_iswrite_i      (addr_mshr_iswrite      ),
    .idx_entry_o              (mshr_addr_idx_entry    ),
    .from_dcache_valid_i      (arb_mshr_valid         ),
    .from_dcache_ready_o      (arb_mshr_ready         ),
    .from_dcache_instrid_i    (arb_mshr_instrid       ),
    .from_dcache_data_i       (arb_mshr_data          ),
    .from_dcache_activemask_i (arb_mshr_activemask    ),
    .to_pipe_valid_o          (lsu_rsp_valid_o        ),
    .to_pipe_ready_i          (lsu_rsp_ready_i        ),
    .to_pipe_warp_id_o        (lsu_rsp_warp_id_o      ),
    .to_pipe_wfd_o            (lsu_rsp_wfd_o          ),
    .to_pipe_wxd_o            (lsu_rsp_wxd_o          ),
    //.to_pipe_isvec_o          (lsu_rsp_isvec_o        ),
    .to_pipe_reg_idxw_o       (lsu_rsp_reg_idxw_o     ),
    .to_pipe_mask_o           (lsu_rsp_mask_o         ),
    //.to_pipe_unsigned_o       (lsu_rsp_unsigned_o     ),
    //.to_pipe_wordoffset1h_o   (lsu_rsp_wordoffset1h_o ),
    .to_pipe_iswrite_o        (lsu_rsp_iswrite_o      ),
    .to_pipe_data_o           (lsu_rsp_data_o         )
  );

  //shiftboard: for fence
  wire [`NUM_WARP-1:0] left_move  ;
  wire [`NUM_WARP-1:0] right_move ;
  wire [`NUM_WARP-1:0] full       ;
  wire [`NUM_WARP-1:0] empty      ;
  
  genvar i;
  generate for(i=0;i<`NUM_WARP;i=i+1) begin: SHIFTBOARD
    assign left_move[i]  = lsu_req_valid_i && lsu_req_ready_o && (lsu_req_wid_i==i)    ;
    assign right_move[i] = lsu_rsp_valid_o && lsu_rsp_ready_i && (lsu_rsp_warp_id_o==i);
    assign fence_end_o[i]= empty[i];    //for fence_end

    shiftboard #(
      .DEPTH (`LSU_NUM_ENTRY_EACH_WARP)
    )
    board (
      .clk   (clk          ),
      .rst_n (rst_n        ),
      .left  (left_move[i] ),
      .right (right_move[i]),
      .full  (full[i]      ),
      .empty (empty[i]     )
    ); 
  end
  endgenerate

  //input_fifo_enq_valid, lsu_req_ready_o
  assign input_fifo_enq_valid = full[lsu_req_wid_i] ? 'd0 : lsu_req_valid_i     ;
  assign lsu_req_ready_o      = full[lsu_req_wid_i] ? 'd0 : input_fifo_enq_ready;

/*
`ifdef DEBUG
  reg [`XLEN*`NUM_THREAD] in1_reg;
  reg [`XLEN*`NUM_THREAD] in2_reg;
  reg [`XLEN*`NUM_THREAD] in3_reg;
  reg lsu_req_valid_reg;
  reg lsu_req_ready_reg;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      in1_reg <= 'd0;
      in2_reg <= 'd0;
      in3_reg <= 'd0;
      lsu_req_valid_reg <= 'd0;
      lsu_req_ready_reg <= 'd0;
    end
    else begin
      in1_reg <= lsu_req_in1_i;
      in2_reg <= lsu_req_in2_i;
      in3_reg <= lsu_req_in3_i;
      lsu_req_valid_reg <= lsu_req_valid_i;
      lsu_req_ready_reg <= lsu_req_ready_o;
      if(lsu_req_valid_reg && !lsu_req_ready_reg && lsu_req_valid_i) begin
        if((in1_reg!=lsu_req_in1_i) || (in2_reg!=lsu_req_in2_i) || (in3_reg!=lsu_req_in3_i)) begin
          $error("Lose a request!");
        end
      end
    end
  end
`endif
*/
 

endmodule
