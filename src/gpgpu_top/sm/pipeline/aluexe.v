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
// Description:alu to wb/branch
`timescale 1ns/1ns
//`include "IDecode_define.v"
`include "define.v"

module  aluexe(
  input                                     clk            ,
  input                                     rst_n          ,

  input                                     in_valid_i     ,
  input                                     out_ready_i    ,
  input                                     out2br_ready_i ,

  input   [`XLEN-1:0]                       in1_i          ,
  input   [`XLEN-1:0]                       in2_i          ,
  input   [`XLEN-1:0]                       in3_i          ,
  input   [`DEPTH_WARP-1:0]                 ctrl_wid_i     ,
  input   [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] ctrl_reg_idxw_i,
  input                                     ctrl_wxd_i     ,
  input   [5:0]                             ctrl_alu_fn_i  ,
  input   [1:0]                             ctrl_branch_i  ,

  output                                    in_ready_o     ,
  output                                    out_valid_o    ,
  output                                    out2br_valid_o ,

  output  [`XLEN-1:0]                       wb_wxd_rd_o    ,
  output                                    wxd_o          ,
  output  [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] reg_idxw_o     ,
  output  [`DEPTH_WARP-1:0]                 warp_id_o      ,

  output  [`DEPTH_WARP-1:0]                 br_wid_o       ,
  output                                    br_jump_o      ,
  output  [31:0]                            br_new_pc_o  
  );
  
  reg                                                          jump_temp          ;

  //result输入数据
  wire   [`XLEN+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP-1:0] result_data_in     ;
  wire   [`XLEN+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP-1:0] result_data_out    ;
  wire                                                         result_in_valid    ;
  wire                                                         result_in_ready    ;
  wire                                                         result_out_valid   ;
  wire                                                         result_out_ready   ;

  //result_br输入数据
  wire   [`DEPTH_WARP+32+1-1:0]                                result_br_data_in  ;
  wire   [`DEPTH_WARP+32+1-1:0]                                result_br_data_out ;
  wire                                                         result_br_in_valid ;
  wire                                                         result_br_in_ready ;
  wire                                                         result_br_out_valid;
  wire                                                         result_br_out_ready;

  //alu输出
  wire   [`XLEN-1:0]                                           alu_out            ;
  wire                                                         alu_cmp            ;

  alu #(.OPCODE_WIDTH(5)) U_alu(
    //.clk  (clk               ),
    //.rst_n(rst_n             ),
    .op_i (ctrl_alu_fn_i[4:0]),
    .in1_i(in1_i             ),
    .in2_i(in2_i             ),
    //.in3_i(in3_i             ),
    .out_o(alu_out           ),
    .cmp_o(alu_cmp           )
    );

  stream_fifo_pipe_true #(.DATA_WIDTH(`XLEN+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP),
                          .FIFO_DEPTH(1)
    ) U_result(
              .clk        (clk             ),
              .rst_n      (rst_n           ),
              .w_valid_i  (result_in_valid ),
              .w_data_i   (result_data_in  ),
              .r_ready_i  (result_out_ready),

              .w_ready_o  (result_in_ready ),
              .r_data_o   (result_data_out ),
              .r_valid_o  (result_out_valid)
            );

  stream_fifo_pipe_true #(.DATA_WIDTH(`DEPTH_WARP+32+1),
                          .FIFO_DEPTH(2)
    ) U_result_br(
              .clk        (clk                ),
              .rst_n      (rst_n              ),
              .w_valid_i  (result_br_in_valid ),
              .w_data_i   (result_br_data_in  ),
              .r_ready_i  (result_br_out_ready),

              .w_ready_o  (result_br_in_ready ),
              .r_data_o   (result_br_data_out ),
              .r_valid_o  (result_br_out_valid)
            );

  always@(*) begin
    case(ctrl_branch_i) 
     `B_B    : jump_temp = alu_cmp;
     `B_J    : jump_temp = 1'b1   ;
     `B_R    : jump_temp = 1'b1   ;
     default : jump_temp = 1'b0   ;
    endcase
  end

  assign  result_data_in   = {ctrl_wid_i,alu_out,ctrl_reg_idxw_i,ctrl_wxd_i};
  assign  result_in_valid  = in_valid_i & ctrl_wxd_i                        ;
  assign  result_out_ready = out_ready_i                                    ;

  assign  result_br_data_in   = {ctrl_wid_i,in3_i,jump_temp}                ;
  assign  result_br_in_valid  = in_valid_i & (ctrl_branch_i != `B_N)        ;
  assign  result_br_out_ready = out2br_ready_i                              ;

  assign  warp_id_o   = result_data_out[`XLEN+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP-1:`XLEN+1+`REGIDX_WIDTH+`REGEXT_WIDTH];
  assign  wb_wxd_rd_o = result_data_out[`XLEN+`REGIDX_WIDTH+`REGEXT_WIDTH:`REGIDX_WIDTH+`REGEXT_WIDTH+1]                      ;
  assign  reg_idxw_o  = result_data_out[`REGIDX_WIDTH+`REGEXT_WIDTH:1]                                                        ;
  assign  wxd_o       = result_data_out[0]                                                                                    ;
  assign  out_valid_o = result_out_valid                                                                                      ;

  assign  br_wid_o       = result_br_data_out[`DEPTH_WARP+32+1-1:33]                                                          ;
  assign  br_new_pc_o    = result_br_data_out[32:1]                                                                           ;
  assign  br_jump_o      = result_br_data_out[0]                                                                              ;
  assign  out2br_valid_o = result_br_out_valid                                                                                ;

  assign  in_ready_o = (ctrl_branch_i == `B_B) ? result_br_in_ready : 
                       ((ctrl_branch_i == `B_N) ? result_in_ready : result_br_in_ready & result_in_ready);

endmodule

  
