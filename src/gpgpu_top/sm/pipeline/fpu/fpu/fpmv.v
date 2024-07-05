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
// Description:浮点数比较模块
`timescale 1ns/1ns
`include "define.v"
//`include "fpu_ops.v"
`define CTRLGEN
module fpmv #(
  parameter EXPWIDTH    = 8,
  parameter PRECISION   = 24,
  parameter SOFT_THREAD = 4
)(
  input                                     clk            ,
  input                                     rst_n          ,

  input   [2:0]                             op_i           ,
  input   [EXPWIDTH+PRECISION-1:0]          a_i            ,
  input   [EXPWIDTH+PRECISION-1:0]          b_i            ,
`ifdef CTRLGEN
  input   [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] ctrl_regindex_i,
  input   [`DEPTH_WARP-1:0]                 ctrl_warpid_i  ,
  input   [SOFT_THREAD-1:0]                 ctrl_vecmask_i ,
  input                                     ctrl_wvd_i     ,
  input                                     ctrl_wxd_i     ,
`endif

  input                                     in_valid_i     ,
  input                                     out_ready_i    ,

  output                                    in_ready_o     ,
  output                                    out_valid_o    ,

  output  [EXPWIDTH+PRECISION-1:0]          result_o       ,
  output  [4:0]                             fflags_o       
`ifdef CTRLGEN
                                                           ,
  output  [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] ctrl_regindex_o,
  output  [`DEPTH_WARP-1:0]                 ctrl_warpid_o  ,
  output  [SOFT_THREAD-1:0]                 ctrl_vecmask_o ,
  output                                    ctrl_wvd_o     ,
  output                                    ctrl_wxd_o     
`endif
  );

  //for pipeline reg valid: latency = 2
  reg                          in_valid_reg1;
  reg                          in_valid_reg2;
  wire                         reg_en1      ;
  wire                         reg_en2      ;

  reg                                       res_sign            ;
  wire    [EXPWIDTH+PRECISION-1:0]          a_temp              ;

  //s1_reg
  reg     [EXPWIDTH+PRECISION-1:0]          a_reg               ;
  reg     [2:0]                             op_reg              ;
`ifdef CTRLGEN
  reg     [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] ctrl_regindex_reg1  ;
  reg     [`DEPTH_WARP-1:0]                 ctrl_warpid_reg1    ;
  reg     [SOFT_THREAD-1:0]                 ctrl_vecmask_reg1   ;
  reg                                       ctrl_wvd_reg1       ;
  reg                                       ctrl_wxd_reg1       ;  
`endif

  //classify
  wire                                        a_sign              ;
  wire    [EXPWIDTH+PRECISION-2:PRECISION-1]  a_exp               ;
  wire    [PRECISION-2:0]                     a_sig               ;
  wire                                        a_exp_not_zero      ;
  wire                                        a_exp_is_ones       ;
  wire                                        a_sig_not_zero      ;
  wire                                        a_is_subnormal      ;
  wire                                        a_is_inf            ;
  wire                                        a_is_zero           ;
  wire                                        a_is_nan            ;
  wire                                        a_is_snan           ;
  wire                                        a_is_qnan           ;
  wire                                        a_is_normal         ;
  wire    [9:0]                               classify_out        ;

  wire    [EXPWIDTH+PRECISION-1:0]            result_temp         ;

  //s2_reg
  reg     [EXPWIDTH+PRECISION-1:0]          result_reg          ;
`ifdef CTRLGEN
  reg     [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] ctrl_regindex_reg2  ;
  reg     [`DEPTH_WARP-1:0]                 ctrl_warpid_reg2    ;
  reg     [SOFT_THREAD-1:0]                 ctrl_vecmask_reg2   ;
  reg                                       ctrl_wvd_reg2       ;
  reg                                       ctrl_wxd_reg2       ;
`endif

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      in_valid_reg1 <= 'd0 ;
      in_valid_reg2 <= 'd0 ;
    end
    else begin
      if(!(!out_ready_i && in_valid_reg1 && in_valid_reg2)) begin
        in_valid_reg1 <= in_valid_i   ;
      end
      else begin
        in_valid_reg1 <= in_valid_reg1;
      end
      if(!(!out_ready_i && in_valid_reg2)) begin        
        in_valid_reg2 <= in_valid_reg1;
      end
      else begin
        in_valid_reg2 <= in_valid_reg2;
      end
    end
  end

  assign reg_en1 = in_valid_i && !(in_valid_reg1 && in_valid_reg2 && !out_ready_i) ;
  assign reg_en2 = in_valid_reg1 && !(in_valid_reg2 && !out_ready_i)               ;

  //for valid and ready
  assign in_ready_o  = !(!out_ready_i && in_valid_reg1 && in_valid_reg2) ;
  assign out_valid_o = in_valid_reg2                                     ;

  always@(*) begin
    case({3'b010,op_i})
      `FN_FSGNJ  : res_sign = b_i[EXPWIDTH+PRECISION-1];
      `FN_FSGNJN : res_sign = !b_i[EXPWIDTH+PRECISION-1];
      `FN_FSGNJX : res_sign = a_i[EXPWIDTH+PRECISION-1] ^ b_i[EXPWIDTH+PRECISION-1];
      default    : res_sign = a_i[EXPWIDTH+PRECISION-1];
    endcase
  end

  assign a_temp = ({3'b010,op_i} == `FN_FCLASS) ? a_i : {res_sign,a_i[EXPWIDTH+PRECISION-2:0]};

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      op_reg               <= 'd0;
      a_reg                <= 'd0;
      `ifdef CTRLGEN
      ctrl_regindex_reg1   <= 'd0;   
      ctrl_warpid_reg1     <= 'd0;
      ctrl_vecmask_reg1    <= 'd0;
      ctrl_wvd_reg1        <= 'd0;
      ctrl_wxd_reg1        <= 'd0;
      `endif
    end
    else if(reg_en1) begin
      op_reg               <= op_i            ;
      a_reg                <= a_temp          ;
      `ifdef CTRLGEN
      ctrl_regindex_reg1   <= ctrl_regindex_i ;   
      ctrl_warpid_reg1     <= ctrl_warpid_i   ;
      ctrl_vecmask_reg1    <= ctrl_vecmask_i  ;
      ctrl_wvd_reg1        <= ctrl_wvd_i      ;
      ctrl_wxd_reg1        <= ctrl_wxd_i      ;
      `endif
    end
    else begin
      op_reg               <= op_reg              ;
      a_reg                <= a_reg               ;
      `ifdef CTRLGEN
      ctrl_regindex_reg1   <= ctrl_regindex_reg1  ;
      ctrl_warpid_reg1     <= ctrl_warpid_reg1    ;
      ctrl_vecmask_reg1    <= ctrl_vecmask_reg1   ;
      ctrl_wvd_reg1        <= ctrl_wvd_reg1       ;
      ctrl_wxd_reg1        <= ctrl_wxd_reg1       ;
      `endif
    end
  end

  //classify
  assign a_sign = a_reg[EXPWIDTH+PRECISION-1];
  assign a_exp  = a_reg[EXPWIDTH+PRECISION-2:PRECISION-1];
  assign a_sig  = a_reg[PRECISION-2:0];
  assign a_exp_not_zero = |a_exp;
  assign a_exp_is_ones  = &a_exp;
  assign a_sig_not_zero = |a_sig;
  assign a_is_subnormal = !a_exp_not_zero && a_sig_not_zero;
  assign a_is_inf       = a_exp_is_ones && !a_sig_not_zero;
  assign a_is_zero      = !a_exp_not_zero && !a_sig_not_zero;
  assign a_is_nan       = a_exp_is_ones && a_sig_not_zero;
  assign a_is_snan      = a_is_nan && !a_sig[PRECISION-2];
  assign a_is_qnan      = a_is_nan && a_sig[PRECISION-2];
  assign a_is_normal    = !a_exp_is_ones && a_exp_not_zero;
  assign classify_out   = {a_is_qnan,
                           a_is_snan,
                           a_is_inf&&!a_sign,
                           a_is_normal&&!a_sign,
                           a_is_subnormal&&!a_sign,
                           a_is_zero&&!a_sign,
                           a_is_zero&&a_sign,
                           a_is_subnormal&&a_sign,
                           a_is_normal&&a_sign,
                           a_is_inf&&a_sign};

  assign result_temp = ({3'b010,op_reg} == `FN_FCLASS) ? classify_out : a_reg;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      `ifdef CTRLGEN
      ctrl_regindex_reg2 <= 'd0; 
      ctrl_warpid_reg2   <= 'd0;
      ctrl_vecmask_reg2  <= 'd0;
      ctrl_wvd_reg2      <= 'd0;
      ctrl_wxd_reg2      <= 'd0;
      `endif
      result_reg         <= 'd0;
    end
    else if(reg_en2) begin
      `ifdef CTRLGEN
      ctrl_regindex_reg2 <= ctrl_regindex_reg1  ;  
      ctrl_warpid_reg2   <= ctrl_warpid_reg1    ;
      ctrl_vecmask_reg2  <= ctrl_vecmask_reg1   ;
      ctrl_wvd_reg2      <= ctrl_wvd_reg1       ;
      ctrl_wxd_reg2      <= ctrl_wxd_reg1       ;
      `endif
      result_reg         <= result_temp         ;
    end
    else begin
      `ifdef CTRLGEN
      ctrl_regindex_reg2 <= ctrl_regindex_reg2;
      ctrl_warpid_reg2   <= ctrl_warpid_reg2  ;
      ctrl_vecmask_reg2  <= ctrl_vecmask_reg2 ;
      ctrl_wvd_reg2      <= ctrl_wvd_reg2     ;
      ctrl_wxd_reg2      <= ctrl_wxd_reg2     ;
      `endif
      result_reg         <= result_reg        ;
    end
  end

  assign result_o = result_reg;
  assign fflags_o = 'd0;
  `ifdef CTRLGEN
  assign ctrl_regindex_o = ctrl_regindex_reg2;
  assign ctrl_warpid_o   = ctrl_warpid_reg2;
  assign ctrl_vecmask_o  = ctrl_vecmask_reg2;
  assign ctrl_wvd_o      = ctrl_wvd_reg2;
  assign ctrl_wxd_o      = ctrl_wxd_reg2;
  `endif 

endmodule
  


