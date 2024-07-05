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
`define MUL_NOT_FOLD 

module vmul_top #(
  parameter SOFT_THREAD = 4,
  parameter HARD_THREAD = 4,
  parameter MAX_ITER    = 1
  )
  (
  input                                     clk              ,
  input                                     rst_n            ,

  input                                     in_valid_i       ,
  input                                     outx_ready_i     ,
  input                                     outv_ready_i     ,

  input   [SOFT_THREAD*`XLEN-1:0]           in1_i            ,
  input   [SOFT_THREAD*`XLEN-1:0]           in2_i            ,
  input   [SOFT_THREAD*`XLEN-1:0]           in3_i            ,
  input   [SOFT_THREAD-1:0]                 mask_i           ,
  input   [5:0]                             ctrl_alu_fn_i    ,
  input                                     ctrl_reverse_i   ,
  input   [`DEPTH_WARP-1:0]                 ctrl_wid_i       ,
  input   [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] ctrl_reg_idxw_i  ,
  input                                     ctrl_wvd_i       ,
  input                                     ctrl_wxd_i       ,

  output                                    in_ready_o       ,
  output                                    outx_valid_o     ,
  output                                    outv_valid_o     ,
  
  //scalar output
  output  [`XLEN-1:0]                       outx_wb_wxd_rd_o ,
  output                                    outx_wxd_o       ,
  output  [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] outx_reg_idwx_o  ,
  output  [`DEPTH_WARP-1:0]                 outx_warp_id_o   ,

  //vector output
  output  [SOFT_THREAD*`XLEN-1:0]           outv_wb_wxd_rd_o ,
  output  [SOFT_THREAD-1:0]                 outv_wvd_mask_o  ,
  output                                    outv_wvd_o       ,
  output  [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] outv_reg_idxw_o  ,
  output  [`DEPTH_WARP-1:0]                 outv_warp_id_o   
  );

  `ifdef MUL_NOT_FOLD
  vmul #(
    .SOFT_THREAD(SOFT_THREAD),
    .HARD_THREAD(HARD_THREAD)
    ) vmul(
    .clk             (clk            ),
    .rst_n           (rst_n          ),
                                     
    .in_valid_i      (in_valid_i     ),
    .outx_ready_i    (outx_ready_i   ),
    .outv_ready_i    (outv_ready_i   ),
                                     
    .in1_i           (in1_i          ),
    .in2_i           (in2_i          ),
    .in3_i           (in3_i          ),
    .mask_i          (mask_i         ),
    .ctrl_alu_fn_i   (ctrl_alu_fn_i  ),
    .ctrl_reverse_i  (ctrl_reverse_i ),
    .ctrl_wid_i      (ctrl_wid_i     ),
    .ctrl_reg_idxw_i (ctrl_reg_idxw_i),
    .ctrl_wvd_i      (ctrl_wvd_i     ),
    .ctrl_wxd_i      (ctrl_wxd_i     ),

    .in_ready_o      (in_ready_o      ),
    .outx_valid_o    (outx_valid_o    ),
    .outv_valid_o    (outv_valid_o    ),
                                     
    .outx_wb_wxd_rd_o(outx_wb_wxd_rd_o),
    .outx_wxd_o      (outx_wxd_o      ),
    .outx_reg_idwx_o (outx_reg_idwx_o ),
    .outx_warp_id_o  (outx_warp_id_o  ),
                                     
    .outv_wb_wxd_rd_o(outv_wb_wxd_rd_o),
    .outv_wvd_mask_o (outv_wvd_mask_o ),
    .outv_wvd_o      (outv_wvd_o      ),
    .outv_reg_idxw_o (outv_reg_idxw_o ),
    .outv_warp_id_o  (outv_warp_id_o  )
    );
`else
  vmul_v2 #(
    .SOFT_THREAD(SOFT_THREAD),
    .HARD_THREAD(HARD_THREAD),
    .MAX_ITER   (1          )
    ) vmul_v2(
    .clk             (clk              ),
    .rst_n           (rst_n            ),
                                       
    .in_valid_i      (in_valid_i       ),
    .outx_ready_i    (outx_ready_i     ),
    .outv_ready_i    (outv_ready_i     ),
                                       
    .in1_i           (in1_i            ),
    .in2_i           (in2_i            ),
    .in3_i           (in3_i            ),
    .mask_i          (mask_i           ),
    .ctrl_alu_fn_i   (ctrl_alu_fn_i    ),
    .ctrl_reverse_i  (ctrl_reverse_i   ),
    .ctrl_wid_i      (ctrl_wid_i       ),
    .ctrl_reg_idxw_i (ctrl_reg_idxw_i  ),
    .ctrl_wvd_i      (ctrl_wvd_i       ),
    .ctrl_wxd_i      (ctrl_wxd_i       ),

    .in_ready_o      (in_ready_o       ),
    .outx_valid_o    (outx_valid_o     ),
    .outv_valid_o    (outv_valid_o     ),
                                        
    .outx_wb_wxd_rd_o(outx_wb_wxd_rd_o ),
    .outx_wxd_o      (outx_wxd_o       ),
    .outx_reg_idwx_o (outx_reg_idwx_o  ),
    .outx_warp_id_o  (outx_warp_id_o   ),
                                        
    .outv_wb_wxd_rd_o(outv_wb_wxd_rd_o ),
    .outv_wvd_mask_o (outv_wvd_mask_o  ),
    .outv_wvd_o      (outv_wvd_o       ),
    .outv_reg_idxw_o (outv_reg_idxw_o  ),
    .outv_warp_id_o  (outv_warp_id_o   )
    );
`endif
endmodule
