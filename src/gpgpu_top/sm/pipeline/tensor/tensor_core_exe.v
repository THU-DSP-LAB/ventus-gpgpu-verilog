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
// Description:张量计算单元执行部分（输出接入fifo）
`timescale 1ns/1ns
`include "define.v"

module tensor_core_exe #(
  parameter VL         = `NUM_THREAD,
  //parameter DIM_M      = `TC_DIM_M,
  //parameter DIM_N      = `TC_DIM_N,
  //parameter DIM_K      = `TC_DIM_K,
  parameter DIM_M      = 2,
  parameter DIM_N      = 2,
  parameter DIM_K      = 2,
  parameter EXPWIDTH   = 8,
  parameter PRECISION  = 24
)(
  input                                     clk              ,
  input                                     rst_n            ,

  input   [`NUM_THREAD*`XLEN-1:0]           in1_i            ,
  input   [`NUM_THREAD*`XLEN-1:0]           in2_i            ,
  input   [`NUM_THREAD*`XLEN-1:0]           in3_i            ,
  //input   [`NUM_THREAD-1:0]                 mask_i           ,
  input   [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] ctrl_reg_idxw_i  ,
  input   [`DEPTH_WARP-1:0]                 ctrl_wid_i       ,
  input   [2:0]                             rm_i             ,

  input                                     in_valid_i       ,
  input                                     out_ready_i      ,

  output                                    in_ready_o       ,
  output                                    out_valid_o      ,

  output  [`NUM_THREAD*`XLEN-1:0]           wb_wvd_rd_o      ,
  output  [`NUM_THREAD-1:0]                 wvd_mask_o       ,
  output                                    wvd_o            ,
  output  [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] reg_idxw_o       ,
  output  [`DEPTH_WARP-1:0]                 warp_id_o         
);

  //tensor output
  wire    [`NUM_THREAD*`XLEN-1:0]           tensor_result       ;
  wire    [`NUM_THREAD*5-1:0]               tensor_fflags       ;
  wire    [7:0]                             tensor_ctrl_reg_idxw;
  wire    [`DEPTH_WARP-1:0]                 tensor_ctrl_warpid  ;
  wire                                      tensor_in_ready     ;
  wire                                      tensor_out_valid    ;

  //result输入数据
  wire   [`NUM_THREAD*`XLEN+`NUM_THREAD+1+8+`DEPTH_WARP-1:0] result_v_data_in     ;
  wire   [`NUM_THREAD*`XLEN+`NUM_THREAD+1+8+`DEPTH_WARP-1:0] result_v_data_out    ;
  wire                                                       result_v_in_valid    ;
  wire                                                       result_v_in_ready    ;
  wire                                                       result_v_out_valid   ;
  wire                                                       result_v_out_ready   ;

  //例化tensor_core_fp32
  tensor_core_fp32 #(
    .VL       (VL       ),
    .DIM_M    (DIM_M    ),
    .DIM_N    (DIM_N    ),
    .DIM_K    (DIM_K    ),
    .EXPWIDTH (EXPWIDTH ),
    .PRECISION(PRECISION)
  )
  U_tensor (
    .clk            (clk                 ), 
    .rst_n          (rst_n               ),     
    
    //.op_i           ('d0                 ),        
    .a_i            (in1_i               ),        
    .b_i            (in2_i               ),       
    .c_i            (in3_i               ),         
    .rm_i           ({VL{rm_i}}          ),          
    .ctrl_reg_idxw_i(ctrl_reg_idxw_i     ),           
    .ctrl_warpid_i  (ctrl_wid_i          ),           
                    
    .in_valid_i     (in_valid_i          ),             
    .out_ready_i    (result_v_in_ready   ),              
                   
    .in_ready_o     (tensor_in_ready     ),            
    .out_valid_o    (tensor_out_valid    ),            
                   
    .result_o       (tensor_result       ),            
    .fflags_o       (tensor_fflags       ),            
    .ctrl_reg_idxw_o(tensor_ctrl_reg_idxw),           
    .ctrl_warpid_o  (tensor_ctrl_warpid  )
  );

  //例化fifo
  stream_fifo_pipe_true #(.DATA_WIDTH(`NUM_THREAD*`XLEN+`NUM_THREAD+1+8+`DEPTH_WARP),
                          .FIFO_DEPTH(1)
    ) U_result_v(
              .clk        (clk               ),
              .rst_n      (rst_n             ),
              .w_valid_i  (result_v_in_valid ),
              .w_data_i   (result_v_data_in  ),
              .r_ready_i  (result_v_out_ready),

              .w_ready_o  (result_v_in_ready ),
              .r_data_o   (result_v_data_out ),
              .r_valid_o  (result_v_out_valid)
            );

  //result_v input
  assign result_v_data_in   = {tensor_result,tensor_ctrl_warpid,tensor_ctrl_reg_idxw,tensor_out_valid,{`NUM_THREAD{1'b1}}};
  assign result_v_in_valid  = tensor_out_valid;
  assign result_v_out_ready = out_ready_i;

  assign wb_wvd_rd_o = result_v_data_out[`NUM_THREAD*`XLEN+`NUM_THREAD+1+8+`DEPTH_WARP-1-:`NUM_THREAD*`XLEN];
  assign warp_id_o   = result_v_data_out[`NUM_THREAD+8+`DEPTH_WARP-:`DEPTH_WARP];
  assign reg_idxw_o  = result_v_data_out[`NUM_THREAD+8-:8];
  assign wvd_o       = result_v_data_out[`NUM_THREAD];
  assign wvd_mask_o  = result_v_data_out[`NUM_THREAD-1:0];
  assign in_ready_o  = result_v_in_ready;//原为tensor_in_ready
  assign out_valid_o = result_v_out_valid;

endmodule
