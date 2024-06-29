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
// Description:vector alu(soft_thread==hard_thread)
`timescale 1ns/1ns
`include "define.v"
//`include "IDecode_define.v"

module  valu #(
  parameter SOFT_THREAD = `NUM_THREAD,
  parameter HARD_THREAD = `NUM_THREAD
  )(
  input                                     clk              ,
  input                                     rst_n            ,

  input                                     in_valid_i       ,
  input                                     out_ready_i      ,
  input                                     out2simt_ready_i ,

  input   [SOFT_THREAD*`XLEN-1:0]           in1_i            ,
  input   [SOFT_THREAD*`XLEN-1:0]           in2_i            ,
  //input   [SOFT_THREAD*`XLEN-1:0]           in3_i            ,
  input   [SOFT_THREAD-1:0]                 mask_i           ,
  input   [5:0]                             ctrl_alu_fn_i    ,
  input                                     ctrl_reverse_i   ,
  //input                                     ctrl_writemask_i ,
  //input                                     ctrl_readmask_i  ,
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

  //result输入数据
  wire   [SOFT_THREAD*`XLEN+SOFT_THREAD+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP-1:0] result_data_in     ;
  wire   [SOFT_THREAD*`XLEN+SOFT_THREAD+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP-1:0] result_data_out    ;
  wire                                                                                 result_in_valid    ;
  wire                                                                                 result_in_ready    ;
  wire                                                                                 result_out_valid   ;
  wire                                                                                 result_out_ready   ;

  //result_simt输入数据
  wire   [`DEPTH_WARP+SOFT_THREAD-1:0]  result_simt_data_in  ;
  wire   [`DEPTH_WARP+SOFT_THREAD-1:0]  result_simt_data_out ;
  wire                                  result_simt_in_valid ;
  wire                                  result_simt_in_ready ;
  wire                                  result_simt_out_valid;
  wire                                  result_simt_out_ready;

  //alu
  reg    [`XLEN*HARD_THREAD-1:0]        alu_in1                  ;
  reg    [`XLEN*HARD_THREAD-1:0]        alu_in2                  ;
  //reg    [`XLEN*HARD_THREAD-1:0]        alu_in3                  ;
  reg    [5*HARD_THREAD-1:0]            alu_op                   ;
  wire   [`XLEN-1:0]                    alu_out [0:HARD_THREAD-1];
  wire                                  alu_cmp [0:HARD_THREAD-1];
  
  wire   [HARD_THREAD-1:0]              if_mask                  ;
  wire   [SOFT_THREAD*`XLEN-1:0]        wb_wvd_rd_comb           ;
  //reg    [`XLEN-1:0]                    wb_wvd_rd [0:HARD_THREAD-1];
  reg    [`XLEN*HARD_THREAD-1:0]        wb_wvd_rd                ;
  reg    [HARD_THREAD-1:0]              wvd_mask                 ;
  reg    [`XLEN-1:0]                    temp;

  genvar i;
  generate
    for(i=0;i<HARD_THREAD;i=i+1) begin:alu
      alu #(.OPCODE_WIDTH(5)) U_alu_i(
        //.clk  (clk                          ),
        //.rst_n(rst_n                        ),
        .op_i (alu_op[(i+1)*5-1-:5]        ),
        .in1_i(alu_in1[(i+1)*`XLEN-1-:`XLEN]),
        .in2_i(alu_in2[(i+1)*`XLEN-1-:`XLEN]),
        //.in3_i(alu_in3[(i+1)*`XLEN-1-:`XLEN]),
        .out_o(alu_out[i]                   ),
        .cmp_o(alu_cmp[i]                   )
      );

      assign wb_wvd_rd_comb[(i+1)*`XLEN-1-:`XLEN] = wb_wvd_rd[(i+1)*`XLEN-1-:`XLEN];
      assign if_mask[i] = ~alu_cmp[i];

      always@(*) begin
        if(ctrl_reverse_i == 1'b1) begin
          alu_op[(i+1)*5-1-:5]            = ctrl_alu_fn_i[4:0];
          alu_in1[(i+1)*`XLEN-1-:`XLEN]   = in2_i[(i+1)*`XLEN-1-:`XLEN];
          alu_in2[(i+1)*`XLEN-1-:`XLEN]   = in1_i[(i+1)*`XLEN-1-:`XLEN];
          //alu_in3[(i+1)*`XLEN-1-:`XLEN]   = in3_i[(i+1)*`XLEN-1-:`XLEN];
          wb_wvd_rd[(i+1)*`XLEN-1-:`XLEN] = alu_out[i];
          wvd_mask[i]                     = mask_i[i];
        end

        else if((ctrl_alu_fn_i == `FN_VMANDNOT) | (ctrl_alu_fn_i == `FN_VMORNOT) | (ctrl_alu_fn_i == `FN_VMNAND) |
                (ctrl_alu_fn_i == `FN_VMNOR) | (ctrl_alu_fn_i == `FN_VMXNOR)) begin
          if((ctrl_alu_fn_i == `FN_VMANDNOT) | (ctrl_alu_fn_i == `FN_VMORNOT)) begin
            alu_op[(i+1)*5-1-:5]            = {4'd3,ctrl_alu_fn_i[0]};
            alu_in1[(i+1)*`XLEN-1-:`XLEN]   = ~in1_i[(i+1)*`XLEN-1-:`XLEN];
            alu_in2[(i+1)*`XLEN-1-:`XLEN]   = in2_i[(i+1)*`XLEN-1-:`XLEN];
            //alu_in3[(i+1)*`XLEN-1-:`XLEN]   = in3_i[(i+1)*`XLEN-1-:`XLEN];
            wb_wvd_rd[(i+1)*`XLEN-1-:`XLEN] = alu_out[i];
            wvd_mask[i]                     = mask_i[i];
          end
          else begin
            if(ctrl_alu_fn_i == `FN_VMXNOR) begin
              alu_op[(i+1)*5-1-:5]            = `FN_XOR;
              alu_in1[(i+1)*`XLEN-1-:`XLEN]   = in1_i[(i+1)*`XLEN-1-:`XLEN];
              alu_in2[(i+1)*`XLEN-1-:`XLEN]   = in2_i[(i+1)*`XLEN-1-:`XLEN];
              //alu_in3[(i+1)*`XLEN-1-:`XLEN]   = in3_i[(i+1)*`XLEN-1-:`XLEN];
              wb_wvd_rd[(i+1)*`XLEN-1-:`XLEN] = ~alu_out[i];
              wvd_mask[i]                     = mask_i[i];
            end
            else begin
              alu_op[(i+1)*5-1-:5]            = {4'd3,ctrl_alu_fn_i[0]};
              alu_in1[(i+1)*`XLEN-1-:`XLEN]   = in1_i[(i+1)*`XLEN-1-:`XLEN];
              alu_in2[(i+1)*`XLEN-1-:`XLEN]   = in2_i[(i+1)*`XLEN-1-:`XLEN];
              //alu_in3[(i+1)*`XLEN-1-:`XLEN]   = in3_i[(i+1)*`XLEN-1-:`XLEN];
              wb_wvd_rd[(i+1)*`XLEN-1-:`XLEN] = ~alu_out[i];
              wvd_mask[i]                     = mask_i[i];
            end
          end
        end
        
        else if(ctrl_alu_fn_i == `FN_VID) begin
          alu_op[(i+1)*5-1-:5]            = ctrl_alu_fn_i[4:0];
          alu_in1[(i+1)*`XLEN-1-:`XLEN]   = in1_i[(i+1)*`XLEN-1-:`XLEN];
          alu_in2[(i+1)*`XLEN-1-:`XLEN]   = in2_i[(i+1)*`XLEN-1-:`XLEN];
          //alu_in3[(i+1)*`XLEN-1-:`XLEN]   = in3_i[(i+1)*`XLEN-1-:`XLEN];
          wb_wvd_rd[(i+1)*`XLEN-1-:`XLEN] = i;
          wvd_mask[i]                     = mask_i[i];
        end

        else if(ctrl_alu_fn_i == `FN_VMERGE) begin
          alu_op[(i+1)*5-1-:5]            = ctrl_alu_fn_i[4:0];
          alu_in1[(i+1)*`XLEN-1-:`XLEN]   = in1_i[(i+1)*`XLEN-1-:`XLEN];
          alu_in2[(i+1)*`XLEN-1-:`XLEN]   = in2_i[(i+1)*`XLEN-1-:`XLEN];
          //alu_in3[(i+1)*`XLEN-1-:`XLEN]   = in3_i[(i+1)*`XLEN-1-:`XLEN];
          wb_wvd_rd[(i+1)*`XLEN-1-:`XLEN] = mask_i[i] ? in1_i[(i+1)*`XLEN-1-:`XLEN] : in2_i[(i+1)*`XLEN-1-:`XLEN];
          wvd_mask[i]                     = 1'b1;
        end

        else begin
          alu_op[(i+1)*5-1-:5]            = ctrl_alu_fn_i[4:0];
          alu_in1[(i+1)*`XLEN-1-:`XLEN]   = in1_i[(i+1)*`XLEN-1-:`XLEN];
          alu_in2[(i+1)*`XLEN-1-:`XLEN]   = in2_i[(i+1)*`XLEN-1-:`XLEN];
          //alu_in3[(i+1)*`XLEN-1-:`XLEN]   = in3_i[(i+1)*`XLEN-1-:`XLEN];
          wb_wvd_rd[(i+1)*`XLEN-1-:`XLEN] = alu_out[i];
          wvd_mask[i]                     = mask_i[i];
        end
      end
    end
  endgenerate

  //writemask恒为0，不需要考虑
  /*genvar j;
  generate
    for(j=0;j<HARD_THREAD;j=j+1) begin
      always@(*) begin
        if(ctrl_writemask_i) begin
          wb_wvd_rd[0] = ctrl_readmask_i ? alu_out[0] : temp;
          temp[j]      = mask_i[j] ? alu_out[j][0] : 1'b0;
          wvd_mask[0]  = 1'b1;
          if(ctrl_alu_fn_i == `FN_VMNAND | ctrl_alu_fn_i == `FN_VMXNOR | ctrl_alu_fn_i == `FN_VMXNOR) begin
            wb_wvd_rd[0][j] = mask_i[j] ? !alu_out[j][0] : 1'b0;
            wvd_mask[j] = mask_i[j];
          end
          else begin
            wb_wvd_rd[j] = alu_out[j];
            wvd_mask[j] = mask_i[j];
          end
        end
        else begin
          wb_wvd_rd[j] = alu_out[j];
          wvd_mask[j] = mask_i[j];
        end
      end
    end
  endgenerate*/
  
  stream_fifo_pipe_true #(.DATA_WIDTH(SOFT_THREAD*`XLEN+SOFT_THREAD+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP),
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

  stream_fifo_pipe_true #(.DATA_WIDTH(`DEPTH_WARP+SOFT_THREAD),
                          .FIFO_DEPTH(1)
    ) U_result_simt(
              .clk        (clk                  ),
              .rst_n      (rst_n                ),
              .w_valid_i  (result_simt_in_valid ),
              .w_data_i   (result_simt_data_in  ),
              .r_ready_i  (result_simt_out_ready),

              .w_ready_o  (result_simt_in_ready ),
              .r_data_o   (result_simt_data_out ),
              .r_valid_o  (result_simt_out_valid)
            );
  //result端口赋值
  assign  result_data_in   = {ctrl_wid_i,wb_wvd_rd_comb,ctrl_reg_idxw_i,ctrl_wvd_i,wvd_mask};
  assign  result_in_valid  = in_valid_i & ctrl_wvd_i & (!ctrl_simt_stack_i)                 ;
  //assign  result_in_valid  = in_valid_i & (ctrl_wvd_i || ctrl_alu_fn_i=='d8) & (!ctrl_simt_stack_i);
  assign  result_out_ready = out_ready_i                                                    ;

  //result2simt端口赋值
  assign  result_simt_data_in   = {ctrl_wid_i,if_mask}          ;
  assign  result_simt_in_valid  = in_valid_i & ctrl_simt_stack_i;
  assign  result_simt_out_ready = out2simt_ready_i              ;

  //result输出拆分
  assign  warp_id_o  = result_data_out[SOFT_THREAD*`XLEN+SOFT_THREAD+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP-1-:`DEPTH_WARP];
  assign  wb_wvd_rd_o= result_data_out[SOFT_THREAD*`XLEN+SOFT_THREAD+`REGIDX_WIDTH+`REGEXT_WIDTH-:SOFT_THREAD*`XLEN]          ;
  assign  reg_idxw_o = result_data_out[SOFT_THREAD+`REGIDX_WIDTH+`REGEXT_WIDTH-:`REGIDX_WIDTH+`REGEXT_WIDTH]                  ;
  assign  wvd_o      = result_data_out[SOFT_THREAD]                                                                           ;
  assign  wvd_mask_o = result_data_out[SOFT_THREAD-1:0]                                                                       ;
  assign  out_valid_o= result_out_valid                                                                                       ;
  
  /*genvar k;
  generate 
    for(k=0;k<HARD_THREAD;k=k+1) begin
      wb_wvd_rd_o[k] = result_data_out[(k+1)*`XLEN+SOFT_THREAD+`REGIDX_WIDTH+`REGEXT_WIDTH:k*`XLEN+SOFT_THREAD+`REGIDX_WIDTH+`REGEXT_WIDTH+1];
    end
  endgenerate*/

  //result_simt输出拆分
  assign  wid_o      = result_simt_data_out[`DEPTH_WARP+SOFT_THREAD-1:SOFT_THREAD];
  assign  if_mask_o  = result_simt_data_out[SOFT_THREAD-1:0]                      ;
  assign  out2simt_valid_o = result_simt_out_valid                                ;

  assign  in_ready_o = ctrl_simt_stack_i ? result_simt_in_ready : result_in_ready ;

endmodule


