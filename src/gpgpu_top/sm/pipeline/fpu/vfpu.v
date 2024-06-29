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
// Description:vector fpu(soft_thread==hard_thread)
`timescale 1ns/1ns
`include "define.v"
//`include "IDecode_define.v"
//`include "fpu_ops.v"

module vfpu #(
  parameter EXPWIDTH    = 8,
  parameter PRECISION   = 24,
  parameter LEN         = EXPWIDTH + PRECISION,
  parameter SOFT_THREAD = 4,
  parameter HARD_THREAD = 4
  )(
  input                                     clk            ,
  input                                     rst_n          ,

  input   [SOFT_THREAD*6-1:0]               op_i           ,
  input   [SOFT_THREAD*3-1:0]               rm_i           ,
  input   [SOFT_THREAD*LEN-1:0]             a_i            ,
  input   [SOFT_THREAD*LEN-1:0]             b_i            ,
  input   [SOFT_THREAD*LEN-1:0]             c_i            ,
  
  input   [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] ctrl_regindex_i,
  input   [`DEPTH_WARP-1:0]                 ctrl_warpid_i  ,
  input   [SOFT_THREAD-1:0]                 ctrl_vecmask_i ,
  input                                     ctrl_wvd_i     ,
  input                                     ctrl_wxd_i     ,

  input                                     in_valid_i     ,
  input                                     out_ready_i    ,

  output                                    in_ready_o     ,
  output                                    out_valid_o    ,

  output  [SOFT_THREAD*64-1:0]              result_o       ,
  output  [SOFT_THREAD*5-1:0]               fflags_o       ,
                                                      
  output  [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] ctrl_regindex_o,
  output  [`DEPTH_WARP-1:0]                 ctrl_warpid_o  ,
  output  [SOFT_THREAD-1:0]                 ctrl_vecmask_o ,
  output                                    ctrl_wvd_o     ,
  output                                    ctrl_wxd_o    
);
  //scalar fpu output
  wire  [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] fpu_ctrl_regindex    [0:HARD_THREAD-1];
  wire  [`DEPTH_WARP-1:0]                 fpu_ctrl_warpid      [0:HARD_THREAD-1];
  wire  [SOFT_THREAD-1:0]                 fpu_ctrl_vecmask     [0:HARD_THREAD-1];
  wire                                    fpu_ctrl_wvd         [0:HARD_THREAD-1];
  wire                                    fpu_ctrl_wxd         [0:HARD_THREAD-1];
  wire                                    fpu_in_ready         [0:HARD_THREAD-1];
  wire                                    fpu_out_valid        [0:HARD_THREAD-1];
  wire  [63:0]                            fpu_result           [0:HARD_THREAD-1];
  wire  [4:0]                             fpu_fflags           [0:HARD_THREAD-1];
  wire  [2:0]                             fpu_select           [0:HARD_THREAD-1];

  //例化第一个scalar_fpu,CTRLGEN open
  scalar_fpu #(
    .EXPWIDTH(EXPWIDTH),
    .PRECISION(PRECISION),
    .SOFT_THREAD(SOFT_THREAD),
    .HARD_THREAD(HARD_THREAD)
  )
  U_scalar_fpu_with_ctrl (
  .clk            (clk                 ),  
  .rst_n          (rst_n               ),
                                       
  .op_i           (op_i[5:0]           ),
  .a_i            (a_i[LEN-1:0]        ),
  .b_i            (b_i[LEN-1:0]        ),
  .c_i            (c_i[LEN-1:0]        ),
  .rm_i           (rm_i[2:0]           ),
                            
  .ctrl_regindex_i(ctrl_regindex_i     ),
  .ctrl_warpid_i  (ctrl_warpid_i       ),
  .ctrl_vecmask_i (ctrl_vecmask_i      ),
  .ctrl_wvd_i     (ctrl_wvd_i          ),
  .ctrl_wxd_i     (ctrl_wxd_i          ),
  .ctrl_regindex_o(fpu_ctrl_regindex[0]), 
  .ctrl_warpid_o  (fpu_ctrl_warpid[0]  ), 
  .ctrl_vecmask_o (fpu_ctrl_vecmask[0] ),
  .ctrl_wvd_o     (fpu_ctrl_wvd[0]     ), 
  .ctrl_wxd_o     (fpu_ctrl_wxd[0]     ), 
                                       
  .in_valid_i     (in_valid_i          ),          
  .out_ready_i    (out_ready_i         ),
                              
  .in_ready_o     (fpu_in_ready[0]     ),
  .out_valid_o    (fpu_out_valid[0]    ),
                              
  .select_o       (fpu_select[0]       ),
  .result_o       (fpu_result[0]       ),
  .fflags_o       (fpu_fflags[0]       )
  );

  assign result_o[63:0] = fpu_result[0];
  assign fflags_o[4:0]  = fpu_fflags[0];

  //例化剩余HARD_THREAD-1个scalar_fpu,CTRLGEN close
  genvar i;
  generate
    for(i=1;i<HARD_THREAD;i=i+1) begin : A1
      scalar_fpu_no_ctrl #(
        .EXPWIDTH(EXPWIDTH),
        .PRECISION(PRECISION),
        .SOFT_THREAD(SOFT_THREAD),
        .HARD_THREAD(HARD_THREAD)
      )
      U_scalar_fpu_without_ctrl (
      .clk            (clk                  ),  
      .rst_n          (rst_n                ),
                                           
      .op_i           (op_i[(i+1)*6-1-:6]   ),
      .a_i            (a_i[(i+1)*LEN-1-:LEN]),
      .b_i            (b_i[(i+1)*LEN-1-:LEN]),
      .c_i            (c_i[(i+1)*LEN-1-:LEN]),
      .rm_i           (rm_i[(i+1)*3-1-:3]   ),
                                            
      .in_valid_i     (in_valid_i           ),          
      .out_ready_i    (out_ready_i          ),
                                  
      .in_ready_o     (fpu_in_ready[i]      ),
      .out_valid_o    (fpu_out_valid[i]     ),
                                  
      .select_o       (fpu_select[i]        ),
      .result_o       (fpu_result[i]        ),
      .fflags_o       (fpu_fflags[i]        )
      );

      assign result_o[(i+1)*64-1-:64] = fpu_result[i];
      assign fflags_o[(i+1)*5-1-:5]   = fpu_fflags[i];
    end
  endgenerate

  assign out_valid_o     = fpu_out_valid[0]    ;
  assign in_ready_o      = fpu_in_ready[0]     ;
  assign ctrl_regindex_o = fpu_ctrl_regindex[0];
  assign ctrl_warpid_o   = fpu_ctrl_warpid[0]  ;
  assign ctrl_vecmask_o  = fpu_ctrl_vecmask[0] ;
  assign ctrl_wvd_o      = fpu_ctrl_wvd[0]     ;
  assign ctrl_wxd_o      = fpu_ctrl_wxd[0]     ;

endmodule
  

