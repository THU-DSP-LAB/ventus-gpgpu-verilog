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
// Author: Gu, Zihan
// Description:张量计算单元
`timescale 1ns/1ns
`include "define.v"

module tensor_core_fp32 #(
  parameter VL        = `NUM_THREAD,
  parameter DIM_M     = 2,
  parameter DIM_N     = 2,
  parameter DIM_K     = 2,
  parameter EXPWIDTH  = 8,
  parameter PRECISION = 24
)(
  input                                   clk            ,
  input                                   rst_n          ,
  
  //input   [2:0]                           op_i           ,
  input   [VL*(EXPWIDTH+PRECISION)-1:0]   a_i            ,
  input   [VL*(EXPWIDTH+PRECISION)-1:0]   b_i            ,
  input   [VL*(EXPWIDTH+PRECISION)-1:0]   c_i            ,
  input   [VL*3-1:0]                      rm_i           ,
  input   [7:0]                           ctrl_reg_idxw_i,
  input   [`DEPTH_WARP-1:0]               ctrl_warpid_i  ,

  input                                   in_valid_i     ,
  input                                   out_ready_i    ,

  output                                  in_ready_o     ,
  output                                  out_valid_o    ,

  output  [VL*(EXPWIDTH+PRECISION)-1:0]   result_o       ,
  output  [VL*5-1:0]                      fflags_o       ,
  output  [7:0]                           ctrl_reg_idxw_o,
  output  [`DEPTH_WARP-1:0]               ctrl_warpid_o  
);
  
  wire                                    tc_array_in_ready     [0:VL-1];
  wire                                    tc_array_out_valid    [0:VL-1];
  wire    [7:0]                           tc_array_ctrl_reg_idxw[0:VL-1];
  wire    [`DEPTH_WARP-1:0]               tc_array_ctrl_warpid  [0:VL-1];

  //例化DIM_M*DIM_K次tc_dot_product
  genvar i,j;
  generate
  for(i=0;i<DIM_M;i=i+1) begin : A1
    for(j=0;j<DIM_K;j=j+1) begin : A2
      tc_dot_product #(
        .DIM_N    (DIM_N    ),
        .EXPWIDTH (EXPWIDTH ),
        .PRECISION(PRECISION)
      )
      U_tc_array (
        .clk            (clk                                                                            ),                                                                  
        .rst_n          (rst_n                                                                          ),          
      
        .a_i            (a_i[(i+1)*DIM_N*(EXPWIDTH+PRECISION)-1:i*DIM_N*(EXPWIDTH+PRECISION)]           ),                
        .b_i            (b_i[(j+1)*DIM_N*(EXPWIDTH+PRECISION)-1:j*DIM_N*(EXPWIDTH+PRECISION)]           ),          
        .c_i            (c_i[(i*DIM_K+j+1)*(EXPWIDTH+PRECISION)-1:(i*DIM_K+j)*(EXPWIDTH+PRECISION)]     ),              
        .rm_i           (rm_i[2:0]                                                                      ),                  
        .ctrl_reg_idxw_i(ctrl_reg_idxw_i                                                                ),        
        .ctrl_warpid_i  (ctrl_warpid_i                                                                  ),            
                      
        .in_valid_i     (in_valid_i                                                                     ),                       
        .out_ready_i    (out_ready_i                                                                    ),                  
      
        .in_ready_o     (tc_array_in_ready[i*DIM_K+j]                                                   ),                
        .out_valid_o    (tc_array_out_valid[i*DIM_K+j]                                                  ),                
      
        .result_o       (result_o[(i*DIM_K+j+1)*(EXPWIDTH+PRECISION)-1:(i*DIM_K+j)*(EXPWIDTH+PRECISION)]),        
        .fflags_o       (fflags_o[(i*DIM_K+j+1)*5-1:(i*DIM_K+j)*5]                                      ),      
        .ctrl_reg_idxw_o(tc_array_ctrl_reg_idxw[i*DIM_K+j]                                              ),  
        .ctrl_warpid_o  (tc_array_ctrl_warpid[i*DIM_K+j]                                                )            
      );
    end
  end
  endgenerate
  
  assign ctrl_reg_idxw_o = tc_array_ctrl_reg_idxw[0];
  assign ctrl_warpid_o   = tc_array_ctrl_warpid[0];

  assign in_ready_o  = tc_array_in_ready[0];
  assign out_valid_o = tc_array_out_valid[0];

endmodule
