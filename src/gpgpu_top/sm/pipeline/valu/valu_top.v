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
// Author: Zhang, Qi
// Description:
`timescale 1ns/1ns

`include "define.v"
//`include "IDecode_define.v"
`define ALU_NOT_FOLD 

module valu_top #(
  parameter SOFT_THREAD = 4,
  parameter HARD_THREAD = 4,
  parameter MAX_ITER    = 1 //soft / hard
  )(

  input                                     clk              ,
  input                                     rst_n            ,

  input                                     in_valid_i       ,
  input                                     out_ready_i      ,
  input                                     out2simt_ready_i ,

  input   [SOFT_THREAD*`XLEN-1:0]           in1_i            ,
  input   [SOFT_THREAD*`XLEN-1:0]           in2_i            ,
  input   [SOFT_THREAD*`XLEN-1:0]           in3_i            ,
  input   [SOFT_THREAD-1:0]                 mask_i           ,
  input   [5:0]                             ctrl_alu_fn_i    ,
  input                                     ctrl_reverse_i   ,
  input                                     ctrl_simt_stack_i,
  input   [`DEPTH_WARP-1:0]                 ctrl_wid_i       ,
  input   [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] ctrl_reg_idxw_i  ,
  input                                     ctrl_wvd_i       ,

  output                                    in_ready_o       ,
  output                                    out_valid_o      ,
  output                                    out2simt_valid_o ,

  output  [SOFT_THREAD*`XLEN-1:0]           wb_wvd_rd_o      ,
  output  [SOFT_THREAD-1:0]                 wvd_mask_o       ,
  output                                    wvd_o            ,
  output  [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] reg_idxw_o       ,
  output  [`DEPTH_WARP-1:0]                 warp_id_o        ,

  output  [SOFT_THREAD-1:0]                 if_mask_o        ,
  output  [`DEPTH_WARP-1:0]                 wid_o             
  );

  `ifdef ALU_NOT_FOLD
  valu #(
    .SOFT_THREAD(SOFT_THREAD),
    .HARD_THREAD(HARD_THREAD)
    ) valu(
    .clk              (clk              ),
    .rst_n            (rst_n            ),
                                        
    .in_valid_i       (in_valid_i       ),
    .out_ready_i      (out_ready_i      ),
    .out2simt_ready_i (out2simt_ready_i ),
                                        
    .in1_i            (in1_i            ),
    .in2_i            (in2_i            ),
    //.in3_i            (in3_i            ),
    .mask_i           (mask_i           ),
    .ctrl_alu_fn_i    (ctrl_alu_fn_i    ),
    .ctrl_reverse_i   (ctrl_reverse_i   ),
    .ctrl_simt_stack_i(ctrl_simt_stack_i),
    .ctrl_wid_i       (ctrl_wid_i       ),
    .ctrl_reg_idxw_i  (ctrl_reg_idxw_i  ),
    .ctrl_wvd_i       (ctrl_wvd_i       ),

    .in_ready_o       (in_ready_o       ),
    .out_valid_o      (out_valid_o      ),
    .out2simt_valid_o (out2simt_valid_o ),
                                        
    .wb_wvd_rd_o      (wb_wvd_rd_o      ),
    .wvd_mask_o       (wvd_mask_o       ),
    .wvd_o            (wvd_o            ),
    .reg_idxw_o       (reg_idxw_o       ),
    .warp_id_o        (warp_id_o        ),
                                        
    .if_mask_o        (if_mask_o        ),
    .wid_o            (wid_o            )
    );
`else
  valu_v2 #(
    .SOFT_THREAD(SOFT_THREAD),
    .HARD_THREAD(HARD_THREAD),
    .MAX_ITER   (MAX_ITER   )
    ) valu_v2(
    .clk              (clk              ),
    .rst_n            (rst_n            ),
                                        
    .in_valid_i       (in_valid_i       ),
    .out_ready_i      (out_ready_i      ),
    .out2simt_ready_i (out2simt_ready_i ),
                                        
    .in1_i            (in1_i            ),
    .in2_i            (in2_i            ),
    .in3_i            (in3_i            ),
    .mask_i           (mask_i           ),
    .ctrl_alu_fn_i    (ctrl_alu_fn_i    ),
    .ctrl_reverse_i   (ctrl_reverse_i   ),
    .ctrl_simt_stack_i(ctrl_simt_stack_i),
    .ctrl_wid_i       (ctrl_wid_i       ),
    .ctrl_reg_idxw_i  (ctrl_reg_idxw_i  ),
    .ctrl_wvd_i       (ctrl_wvd_i       ),

    .in_ready_o       (in_ready_o       ),
    .out_valid_o      (out_valid_o      ),
    .out2simt_valid_o (out2simt_valid_o ),
                                         
    .wb_wvd_rd_o      (wb_wvd_rd_o      ),
    .wvd_mask_o       (wvd_mask_o       ),
    .wvd_o            (wvd_o            ),
    .reg_idxw_o       (reg_idxw_o       ),
    .warp_id_o        (warp_id_o        ),
                                         
    .if_mask_o        (if_mask_o        ),
    .wid_o            (wid_o            )
    );
`endif

endmodule
