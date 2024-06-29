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
// Description:

`timescale 1ns/1ns

//`include "fpu_ops.v"
`include "define.v"

//`define CTRLGEN

module fma_no_ctrl #(
  parameter EXPWIDTH  = 8 ,
  parameter PRECISION = 24,
  parameter SOFTTHREAD= 4 ,
  parameter HARDTHREAD= 4 
)
(
  input                                clk                       ,
  input                                rst_n                     ,
  input                                in_valid_i                ,
  output                               in_ready_o                ,
  input  [2:0]                         in_op_i                   ,
  input  [EXPWIDTH+PRECISION-1:0]      in_a_i                    ,
  input  [EXPWIDTH+PRECISION-1:0]      in_b_i                    ,
  input  [EXPWIDTH+PRECISION-1:0]      in_c_i                    ,
  input  [2:0]                         in_rm_i                   ,
/*`ifdef CTRLGEN
  input  [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] in_reg_index_i        ,
  input  [`DEPTH_WARP-1:0]                 in_warp_id_i          ,
  input  [SOFTTHREAD-1:0]                  in_vec_mask_i         ,
  input                                    in_wvd_i              ,
  input                                    in_wxd_i              ,
  output [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] out_reg_index_o       ,
  output [`DEPTH_WARP-1:0]                 out_warp_id_o         ,
  output [SOFTTHREAD-1:0]                  out_vec_mask_o        ,
  output                                   out_wvd_o             ,
  output                                   out_wxd_o             ,
`endif*/
  output                               out_valid_o               ,
  input                                out_ready_i               ,
  output [EXPWIDTH+PRECISION-1:0]      out_result_o              ,
  output [4:0]                         out_fflags_o               
);

  parameter LEN = EXPWIDTH + PRECISION;

  //mul_pipe
  wire is_fma            ;
  wire is_fmul           ;
  wire is_addsub         ;
  wire mul_pipe_in_valid ;

  assign is_fma            = in_op_i[2] == 1'b1               ;
  assign is_fmul           = in_op_i == 3'b010                ;
  assign is_addsub         = in_op_i[2:1] == 2'b00            ;
  assign mul_pipe_in_valid = in_valid_i && (is_fma || is_fmul);

  wire                                   mul_in_ready           ;
/*`ifdef CTRLGEN
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] mul_out_reg_index      ;
  wire [`DEPTH_WARP-1:0]                 mul_out_warp_id        ;
  wire [SOFTTHREAD-1:0]                  mul_out_vec_mask       ;
  wire                                   mul_out_wvd            ;
  wire                                   mul_out_wxd            ;
`endif*/
  wire                                   mul_out_valid          ;
  wire                                   mul_out_ready          ;
  wire [EXPWIDTH+PRECISION-1:0]          mul_out_result         ;
  wire [4:0]                             mul_out_fflags         ;
  wire                                   mul_toadd_fp_prod_sign ;
  wire [EXPWIDTH-1:0]                    mul_toadd_fp_prod_exp  ;
  wire [2*PRECISION-2:0]                 mul_toadd_fp_prod_sig  ;
  wire                                   mul_toadd_is_nan       ;
  wire                                   mul_toadd_is_inf       ;
  wire                                   mul_toadd_is_inv       ;
  wire                                   mul_toadd_overflow     ;
  wire [EXPWIDTH+PRECISION-1:0]          mul_toadd_add_another  ;
  wire [2:0]                             mul_toadd_op           ;

  fmul_pipe_no_ctrl #(
    .EXPWIDTH   (EXPWIDTH  ),
    .PRECISION  (PRECISION ),
    .SOFTTHREAD (SOFTTHREAD),
    .HARDTHREAD (HARDTHREAD)
  )
  mul_pipe (
    .clk                       (clk                   ),
    .rst_n                     (rst_n                 ),
    .in_valid_i                (mul_pipe_in_valid     ),
    .in_ready_o                (mul_in_ready          ),
    .in_op_i                   (in_op_i               ),
    .in_a_i                    (in_a_i                ),
    .in_b_i                    (in_b_i                ),
    .in_c_i                    (in_c_i                ),
    .in_rm_i                   (in_rm_i               ),
/*`ifdef CTRLGEN
    .in_reg_index_i            (in_reg_index_i        ),
    .in_warp_id_i              (in_warp_id_i          ),
    .in_vec_mask_i             (in_vec_mask_i         ),
    .in_wvd_i                  (in_wvd_i              ),
    .in_wxd_i                  (in_wxd_i              ),
    .out_reg_index_o           (mul_out_reg_index     ),
    .out_warp_id_o             (mul_out_warp_id       ),
    .out_vec_mask_o            (mul_out_vec_mask      ),
    .out_wvd_o                 (mul_out_wvd           ),
    .out_wxd_o                 (mul_out_wxd           ),
`endif*/
    .out_valid_o               (mul_out_valid         ),
    .out_ready_i               (mul_out_ready         ),
    .out_result_o              (mul_out_result        ),
    .out_fflags_o              (mul_out_fflags        ),
    .mul_output_fp_prod_sign_o (mul_toadd_fp_prod_sign),
    .mul_output_fp_prod_exp_o  (mul_toadd_fp_prod_exp ),
    .mul_output_fp_prod_sig_o  (mul_toadd_fp_prod_sig ),
    .mul_output_is_nan_o       (mul_toadd_is_nan      ),
    .mul_output_is_inf_o       (mul_toadd_is_inf      ),
    .mul_output_is_inv_o       (mul_toadd_is_inv      ),
    .mul_output_overflow_o     (mul_toadd_overflow    ),
    .add_another_o             (mul_toadd_add_another ),
    .op_o                      (mul_toadd_op          )
  );

  //toadd arb: include fifo(0) and fifo(1)
  wire       toaddarb_fifo_0_enq_ready ;
  wire       toaddarb_fifo_0_deq_valid ;
  wire       toaddarb_fifo_0_deq_ready ;
  wire [2:0] toaddarb_fifo_0_deq_op    ;
/*`ifdef CTRLGEN
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP+SOFTTHREAD+1:0] toaddarb_fifo_0_enq_ctrl;
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP+SOFTTHREAD+1:0] toaddarb_fifo_0_deq_ctrl;
  
  assign toaddarb_fifo_0_enq_ctrl = {mul_out_reg_index,mul_out_warp_id,mul_out_vec_mask,mul_out_wvd,mul_out_wxd};
`endif*/
  
  wire       toaddarb_fifo_1_enq_valid ;
  wire       toaddarb_fifo_1_enq_ready ;
  wire       toaddarb_fifo_1_deq_valid ;
  wire       toaddarb_fifo_1_deq_ready ;
  wire [2:0] toaddarb_fifo_1_deq_op    ;
/*`ifdef CTRLGEN
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP+SOFTTHREAD+1:0] toaddarb_fifo_1_enq_ctrl;
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP+SOFTTHREAD+1:0] toaddarb_fifo_1_deq_ctrl;
  
  assign toaddarb_fifo_1_enq_ctrl = {in_reg_index_i,in_warp_id_i,in_vec_mask_i,in_wvd_i,in_wxd_i};
`endif*/

  wire   mul_toadd_isfma;

  assign mul_toadd_isfma = mul_toadd_op[2] == 1'b1;

  //fifo(0): for mul-arb-add
  stream_fifo_pipe_true #(
    .DATA_WIDTH (3),
    .FIFO_DEPTH (1)
  )
  to_add_arb_fifo_0_op (
    .clk       (clk                             ),
    .rst_n     (rst_n                           ),
    .w_ready_o (toaddarb_fifo_0_enq_ready       ),    
    .w_valid_i (mul_out_valid && mul_toadd_isfma),
    .w_data_i  (mul_toadd_op                    ),
    .r_valid_o (toaddarb_fifo_0_deq_valid       ),
    .r_ready_i (toaddarb_fifo_0_deq_ready       ),
    .r_data_o  (toaddarb_fifo_0_deq_op          )
  );

/*`ifdef CTRLGEN
  stream_fifo_pipe_true #(
    .DATA_WIDTH (`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP+SOFTTHREAD+2),
    .FIFO_DEPTH (1                                                    )
  )
  to_add_arb_fifo_0_ctrl (
    .clk       (clk                             ),
    .rst_n     (rst_n                           ),
    .w_ready_o (                                ),    
    .w_valid_i (mul_out_valid && mul_toadd_isfma),
    .w_data_i  (toaddarb_fifo_0_enq_ctrl        ),
    .r_valid_o (                                ),
    .r_ready_i (toaddarb_fifo_0_deq_ready       ),
    .r_data_o  (toaddarb_fifo_0_deq_ctrl        )
  );
`endif*/

  //fifo(1): for input-arb-add
  stream_fifo_pipe_true #(
    .DATA_WIDTH (3),
    .FIFO_DEPTH (1)
  )
  to_add_arb_fifo_1_op (
    .clk       (clk                      ),
    .rst_n     (rst_n                    ),
    .w_ready_o (toaddarb_fifo_1_enq_ready),    
    .w_valid_i (in_valid_i && is_addsub  ),
    .w_data_i  (in_op_i                  ),
    .r_valid_o (toaddarb_fifo_1_deq_valid),
    .r_ready_i (toaddarb_fifo_1_deq_ready),
    .r_data_o  (toaddarb_fifo_1_deq_op   )
  );

/*`ifdef CTRLGEN
  stream_fifo_pipe_true #(
    .DATA_WIDTH (`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP+SOFTTHREAD+2),
    .FIFO_DEPTH (1                                                    )
  )
  to_add_arb_fifo_1_ctrl (
    .clk       (clk                      ),
    .rst_n     (rst_n                    ),
    .w_ready_o (                         ),    
    .w_valid_i (in_valid_i && is_addsub  ),
    .w_data_i  (toaddarb_fifo_1_enq_ctrl ),
    .r_valid_o (                         ),
    .r_ready_i (toaddarb_fifo_1_deq_ready),
    .r_data_o  (toaddarb_fifo_1_deq_ctrl )
  );
`endif*/

  //arbiter: mul has a higher priority
  wire       toaddarb_out_valid;
  wire       toaddarb_out_ready;
  wire [2:0] toaddarb_out_op   ;

  assign toaddarb_out_valid        = toaddarb_fifo_0_deq_valid || toaddarb_fifo_1_deq_valid                     ;
  assign toaddarb_fifo_0_deq_ready = toaddarb_out_ready                                                         ;
  assign toaddarb_fifo_1_deq_ready = !toaddarb_fifo_0_deq_valid && toaddarb_out_ready                           ;
  assign toaddarb_out_op           = toaddarb_fifo_0_deq_valid ? toaddarb_fifo_0_deq_op : toaddarb_fifo_1_deq_op;
/*`ifdef CTRLGEN
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP+SOFTTHREAD+1:0] toaddarb_out_ctrl;

  assign toaddarb_out_ctrl = toaddarb_fifo_0_deq_valid ? toaddarb_fifo_0_deq_ctrl : toaddarb_fifo_1_deq_ctrl    ;
`endif*/
  
  //in to add fifo
  wire             intoadd_enq_ready;
  wire             intoadd_deq_valid;
  wire [LEN*3+5:0] intoadd_enq_bits ;
  wire [LEN*3+5:0] intoadd_deq_bits ;

  assign intoadd_enq_bits = {in_op_i,in_a_i,in_b_i,in_c_i,in_rm_i};
  
  stream_fifo_pipe_true #(
    .DATA_WIDTH (LEN*3+6),
    .FIFO_DEPTH (1      )
  )
  intoadd_fifo_bits (
    .clk       (clk                      ),
    .rst_n     (rst_n                    ),
    .w_ready_o (intoadd_enq_ready        ),    
    .w_valid_i (in_valid_i && is_addsub  ),
    .w_data_i  (intoadd_enq_bits         ),
    .r_valid_o (intoadd_deq_valid        ),
    .r_ready_i (toaddarb_fifo_1_deq_ready),
    .r_data_o  (intoadd_deq_bits         )
  );

/*`ifdef CTRLGEN
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP+SOFTTHREAD+1:0] intoadd_deq_ctrl;

  stream_fifo_pipe_true #(
    .DATA_WIDTH (`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP+SOFTTHREAD+2),
    .FIFO_DEPTH (1                                                    )
  )
  intoadd_fifo_ctrl (
    .clk       (clk                      ),
    .rst_n     (rst_n                    ),
    .w_ready_o (                         ),    
    .w_valid_i (in_valid_i && is_addsub  ),
    .w_data_i  (toaddarb_fifo_1_enq_ctrl ),
    .r_valid_o (                         ),
    .r_ready_i (toaddarb_fifo_1_deq_ready),
    .r_data_o  (intoadd_deq_ctrl         )
  );
`endif*/

  //mul to add fifo
  wire                       multoadd_enq_valid;
  wire                       multoadd_enq_ready;
  wire                       multoadd_deq_valid;
  wire                       multoadd_deq_ready;
  wire [LEN*2+PRECISION+6:0] multoadd_enq_bits ;
  wire [LEN*2+PRECISION+6:0] multoadd_deq_bits ;

  assign multoadd_enq_valid = toaddarb_fifo_0_enq_ready && (mul_out_valid && mul_toadd_isfma);
  assign multoadd_deq_ready = toaddarb_fifo_0_deq_ready && toaddarb_fifo_0_deq_valid         ;
  assign multoadd_enq_bits  = {mul_toadd_fp_prod_sign,
                               mul_toadd_fp_prod_exp ,
                               mul_toadd_fp_prod_sig ,
                               mul_toadd_is_nan      ,
                               mul_toadd_is_inf      ,
                               mul_toadd_is_inv      ,
                               mul_toadd_overflow    ,
                               mul_toadd_add_another ,
                               mul_toadd_op          };

  stream_fifo_pipe_true #(
    .DATA_WIDTH (LEN*2+PRECISION+7),
    .FIFO_DEPTH (1                )
  )
  multoadd_fifo_bits (
    .clk       (clk               ),
    .rst_n     (rst_n             ),
    .w_ready_o (multoadd_enq_ready),    
    .w_valid_i (multoadd_enq_valid),
    .w_data_i  (multoadd_enq_bits ),
    .r_valid_o (multoadd_deq_valid),
    .r_ready_i (multoadd_deq_ready),
    .r_data_o  (multoadd_deq_bits )
  );

  wire                          from_mul_fp_prod_sign;
  wire [EXPWIDTH-1:0]           from_mul_fp_prod_exp ;
  wire [2*PRECISION-2:0]        from_mul_fp_prod_sig ;
  wire                          from_mul_is_nan      ;
  wire                          from_mul_is_inf      ;
  wire                          from_mul_is_inv      ;
  wire                          from_mul_overflow    ;
  wire [EXPWIDTH+PRECISION-1:0] from_mul_add_another ;
  //wire [2:0]                    from_mul_op          ;           

  assign from_mul_fp_prod_sign = multoadd_deq_bits[LEN*2+PRECISION+6]                  ;
  assign from_mul_fp_prod_exp  = multoadd_deq_bits[LEN*2+PRECISION+5:LEN+PRECISION*2+6];
  assign from_mul_fp_prod_sig  = multoadd_deq_bits[LEN+PRECISION*2+5:LEN+7]            ;
  assign from_mul_is_nan       = multoadd_deq_bits[LEN+6]                              ;
  assign from_mul_is_inf       = multoadd_deq_bits[LEN+5]                              ;
  assign from_mul_is_inv       = multoadd_deq_bits[LEN+4]                              ;
  assign from_mul_overflow     = multoadd_deq_bits[LEN+3]                              ;
  assign from_mul_add_another  = multoadd_deq_bits[LEN+2:3]                            ;
  //assign from_mul_op           = multoadd_deq_bits[2:0]                                ;

  //add pipe
  wire                                   add_in_valid     ;
  wire                                   add_in_ready     ;
  wire [2:0]                             add_in_op        ;
  wire [EXPWIDTH+PRECISION-1:0]          add_in_a         ;
  wire [EXPWIDTH+PRECISION-1:0]          add_in_b         ;
  //wire [EXPWIDTH+PRECISION-1:0]          add_in_c         ;
  wire [2:0]                             add_in_rm        ;
/*`ifdef CTRLGEN
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] add_in_reg_index ;
  wire [`DEPTH_WARP-1:0]                 add_in_warp_id   ;
  wire [SOFTTHREAD-1:0]                  add_in_vec_mask  ;
  wire                                   add_in_wvd       ;
  wire                                   add_in_wxd       ;
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] add_out_reg_index;
  wire [`DEPTH_WARP-1:0]                 add_out_warp_id  ;
  wire [SOFTTHREAD-1:0]                  add_out_vec_mask ;
  wire                                   add_out_wvd      ;
  wire                                   add_out_wxd      ;
`endif*/
  wire                                   add_out_valid    ;
  wire                                   add_out_ready    ;
  wire [EXPWIDTH+PRECISION-1:0]          add_out_result   ;
  wire [4:0]                             add_out_fflags   ;

  assign toaddarb_out_ready = add_in_ready      ;
  assign add_in_valid       = toaddarb_out_valid;

  assign add_in_a  = intoadd_deq_bits[LEN*3+2:LEN*2+3];
  assign add_in_b  = intoadd_deq_bits[LEN*2+2:LEN+3]  ;
  //assign add_in_c  = intoadd_deq_bits[LEN+2:3]        ;
  assign add_in_rm = intoadd_deq_bits[2:0]            ;
  assign add_in_op = toaddarb_out_op                  ;
 

/*`ifdef CTRLGEN
  assign add_in_reg_index = toaddarb_out_ctrl[`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP+SOFTTHREAD+1:`DEPTH_WARP+SOFTTHREAD+2];
  assign add_in_warp_id   = toaddarb_out_ctrl[`DEPTH_WARP+SOFTTHREAD+1:SOFTTHREAD+2]                                        ;
  assign add_in_vec_mask  = toaddarb_out_ctrl[SOFTTHREAD+1:2]                                                               ;
  assign add_in_wvd       = toaddarb_out_ctrl[1]                                                                            ;
  assign add_in_wxd       = toaddarb_out_ctrl[0]                                                                            ;
`endif*/

  fadd_pipe_no_ctrl #(
    .EXPWIDTH   (EXPWIDTH  ),
    .PRECISION  (PRECISION ),
    .SOFTTHREAD (SOFTTHREAD),
    .HARDTHREAD (HARDTHREAD)
  )
  add_pipe (
    .clk                     (clk                  ),
    .rst_n                   (rst_n                ),
    .in_valid_i              (add_in_valid         ),
    .in_ready_o              (add_in_ready         ),
    .in_op_i                 (add_in_op            ),
    .in_a_i                  (add_in_a             ),
    .in_b_i                  (add_in_b             ),
    //.in_c_i                  (add_in_c             ),
    .in_rm_i                 (add_in_rm            ),
    .from_mul_fp_prod_sign_i (from_mul_fp_prod_sign),
    .from_mul_fp_prod_exp_i  (from_mul_fp_prod_exp ),
    .from_mul_fp_prod_sig_i  (from_mul_fp_prod_sig ),
    .from_mul_is_nan_i       (from_mul_is_nan      ),
    .from_mul_is_inf_i       (from_mul_is_inf      ),
    .from_mul_is_inv_i       (from_mul_is_inv      ),
    .from_mul_overflow_i     (from_mul_overflow    ),
    .from_mul_add_another_i  (from_mul_add_another ),
    //.from_mul_op_i           (from_mul_op          ),
/*`ifdef CTRLGEN
    .in_reg_index_i          (add_in_reg_index     ),
    .in_warp_id_i            (add_in_warp_id       ),
    .in_vec_mask_i           (add_in_vec_mask      ),
    .in_wvd_i                (add_in_wvd           ),
    .in_wxd_i                (add_in_wxd           ),
    .out_reg_index_o         (add_out_reg_index    ),
    .out_warp_id_o           (add_out_warp_id      ),
    .out_vec_mask_o          (add_out_vec_mask     ),
    .out_wvd_o               (add_out_wvd          ),
    .out_wxd_o               (add_out_wxd          ),
`endif*/
    .out_valid_o             (add_out_valid        ),
    .out_ready_i             (add_out_ready        ),
    .out_result_o            (add_out_result       ),
    .out_fflags_o            (add_out_fflags       )
  );

  //output in_ready_o
  assign in_ready_o = is_addsub ? toaddarb_fifo_1_enq_ready : mul_in_ready;

  //mul fifo(for output)
  wire           mul_fifo_enq_valid;
  wire           mul_fifo_enq_ready;
  wire           mul_fifo_deq_valid;
  wire           mul_fifo_deq_ready;
  wire [LEN+4:0] mul_fifo_enq_bits;
  wire [LEN+4:0] mul_fifo_deq_bits;

  assign mul_fifo_enq_valid = mul_out_valid && (mul_toadd_op[2:0]==3'b010);
  assign mul_fifo_enq_bits  = {mul_out_result,mul_out_fflags}             ;
    
  stream_fifo_pipe_true #(
    .DATA_WIDTH (LEN+5),
    .FIFO_DEPTH (1    )
  )
  mul_fifo_bits (
    .clk       (clk               ),
    .rst_n     (rst_n             ),
    .w_ready_o (mul_fifo_enq_ready),    
    .w_valid_i (mul_fifo_enq_valid),
    .w_data_i  (mul_fifo_enq_bits ),
    .r_valid_o (mul_fifo_deq_valid),
    .r_ready_i (mul_fifo_deq_ready),
    .r_data_o  (mul_fifo_deq_bits )
  );

/*`ifdef CTRLGEN
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP+SOFTTHREAD+1:0] mul_fifo_deq_ctrl;
  
  stream_fifo_pipe_true #(
    .DATA_WIDTH (`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP+SOFTTHREAD+2),
    .FIFO_DEPTH (1                                                   )
  )
  mul_fifo_ctrl (
    .clk       (clk                     ),
    .rst_n     (rst_n                   ),
    .w_ready_o (                        ),    
    .w_valid_i (mul_fifo_enq_valid      ),
    .w_data_i  (toaddarb_fifo_0_enq_ctrl),
    .r_valid_o (                        ),
    .r_ready_i (mul_fifo_deq_ready      ),
    .r_data_o  (mul_fifo_deq_ctrl       )
  );
`endif*/

  //add fifo(for output)
  wire           add_fifo_enq_valid;
  wire           add_fifo_enq_ready;
  wire           add_fifo_deq_valid;
  wire           add_fifo_deq_ready;
  wire [LEN+4:0] add_fifo_enq_bits;
  wire [LEN+4:0] add_fifo_deq_bits;

  assign add_fifo_enq_valid = add_out_valid                  ;
  assign add_out_ready      = add_fifo_deq_ready             ;
  assign add_fifo_enq_bits  = {add_out_result,add_out_fflags};
    
  stream_fifo_pipe_true #(
    .DATA_WIDTH (LEN+5),
    .FIFO_DEPTH (1    )
  )
  add_fifo_bits (
    .clk       (clk               ),
    .rst_n     (rst_n             ),
    .w_ready_o (add_fifo_enq_ready),    
    .w_valid_i (add_fifo_enq_valid),
    .w_data_i  (add_fifo_enq_bits ),
    .r_valid_o (add_fifo_deq_valid),
    .r_ready_i (add_fifo_deq_ready),
    .r_data_o  (add_fifo_deq_bits )
  );

  assign mul_out_ready = (toaddarb_fifo_0_enq_ready && (mul_toadd_op[2]==1'b1)) || (mul_fifo_enq_ready && (mul_toadd_op[2:0]==3'b010));

/*`ifdef CTRLGEN
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP+SOFTTHREAD+1:0] add_fifo_enq_ctrl;
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP+SOFTTHREAD+1:0] add_fifo_deq_ctrl;

  assign add_fifo_enq_ctrl = {add_out_reg_index,
                              add_out_warp_id  ,
                              add_out_vec_mask ,
                              add_out_wvd      ,
                              add_out_wxd      };

  stream_fifo_pipe_true #(
    .DATA_WIDTH (`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP+SOFTTHREAD+2),
    .FIFO_DEPTH (1                                                   )
  )
  add_fifo_ctrl (
    .clk       (clk               ),
    .rst_n     (rst_n             ),
    .w_ready_o (                  ),    
    .w_valid_i (add_fifo_enq_valid),
    .w_data_i  (add_fifo_enq_ctrl),
    .r_valid_o (                  ),
    .r_ready_i (add_fifo_deq_ready),
    .r_data_o  (add_fifo_deq_ctrl )
  );
`endif*/

  //output arbiter: mul_fifo has a higher priority
  wire [LEN-1:0] mul_fifo_result;
  wire [4:0]     mul_fifo_fflags;
  wire [LEN-1:0] add_fifo_result;
  wire [4:0]     add_fifo_fflags;

  assign mul_fifo_deq_ready = out_ready_i                       ;
  assign add_fifo_deq_ready = !mul_fifo_enq_valid && out_ready_i;
  assign mul_fifo_result    = mul_fifo_deq_bits[LEN+4:5]        ;
  assign mul_fifo_fflags    = mul_fifo_deq_bits[4:0]            ;
  assign add_fifo_result    = add_fifo_deq_bits[LEN+4:5]        ;
  assign add_fifo_fflags    = add_fifo_deq_bits[4:0]            ;
  
  assign out_result_o = mul_fifo_deq_valid ? mul_fifo_result : add_fifo_result;
  assign out_fflags_o = mul_fifo_deq_valid ? mul_fifo_fflags : add_fifo_fflags;
  assign out_valid_o  = mul_fifo_deq_valid || add_fifo_deq_valid              ;

/*`ifdef CTRLGEN
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] add_fifo_reg_index;
  wire [`DEPTH_WARP-1:0]                 add_fifo_warp_id  ;
  wire [SOFTTHREAD-1:0]                  add_fifo_vec_mask ;
  wire                                   add_fifo_wvd      ;
  wire                                   add_fifo_wxd      ;
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] mul_fifo_reg_index;
  wire [`DEPTH_WARP-1:0]                 mul_fifo_warp_id  ;
  wire [SOFTTHREAD-1:0]                  mul_fifo_vec_mask ;
  wire                                   mul_fifo_wvd      ;
  wire                                   mul_fifo_wxd      ;

  assign add_fifo_reg_index = add_fifo_deq_ctrl[`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP+SOFTTHREAD+1:`DEPTH_WARP+SOFTTHREAD+2];
  assign add_fifo_warp_id   = add_fifo_deq_ctrl[`DEPTH_WARP+SOFTTHREAD+1:SOFTTHREAD+2]                                        ;
  assign add_fifo_vec_mask  = add_fifo_deq_ctrl[SOFTTHREAD+1:2]                                                               ;
  assign add_fifo_wvd       = add_fifo_deq_ctrl[1]                                                                            ;
  assign add_fifo_wxd       = add_fifo_deq_ctrl[0]                                                                            ;
  assign mul_fifo_reg_index = mul_fifo_deq_ctrl[`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP+SOFTTHREAD+1:`DEPTH_WARP+SOFTTHREAD+2];
  assign mul_fifo_warp_id   = mul_fifo_deq_ctrl[`DEPTH_WARP+SOFTTHREAD+1:SOFTTHREAD+2]                                        ;
  assign mul_fifo_vec_mask  = mul_fifo_deq_ctrl[SOFTTHREAD+1:2]                                                               ;
  assign mul_fifo_wvd       = mul_fifo_deq_ctrl[1]                                                                            ;
  assign mul_fifo_wxd       = mul_fifo_deq_ctrl[0]                                                                            ;

  assign out_reg_index_o = mul_fifo_deq_valid ? mul_fifo_reg_index : add_fifo_reg_index;
  assign out_warp_id_o   = mul_fifo_deq_valid ? mul_fifo_warp_id   : add_fifo_warp_id  ;
  assign out_vec_mask_o  = mul_fifo_deq_valid ? mul_fifo_vec_mask  : add_fifo_vec_mask ;
  assign out_wvd_o       = mul_fifo_deq_valid ? mul_fifo_wvd       : add_fifo_wvd      ;
  assign out_wxd_o       = mul_fifo_deq_valid ? mul_fifo_wxd       : add_fifo_wxd      ;
`endif*/

endmodule

//`undef CTRLGEN
