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
// Description:FN_MUL -> (zeroext, zeroext),
//             FN_MULH-> (signext, signext),
//             FN_MULHSU -> (signext, zeroext),
//             FN_MULHU -> (zeroext, zeroext),
//             乘加中都是无符号数乘法

`timescale 1ns/1ns
`include "define.v"
//`include "IDecode_define.v"

module array_multiplier #(
  parameter LATENCY = 2
  )(
  input                                       clk            ,
  input                                       rst_n          ,

  input   [`NUM_THREAD-1:0]                   mask_i         ,
  input   [`XLEN-1:0]                         a_i            ,
  input   [`XLEN-1:0]                         b_i            ,
  input   [`XLEN-1:0]                         c_i            ,
  input   [5:0]                               ctrl_alu_fn_i  ,
  input   [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]   ctrl_reg_idxw_i,
  input   [`DEPTH_WARP-1:0]                   ctrl_wid_i     ,
  input                                       ctrl_wvd_i     ,
  input                                       ctrl_wxd_i     ,

  input                                       in_valid_i     ,
  input                                       out_ready_i    ,

  output                                      in_ready_o     ,
  output                                      out_valid_o    ,

  output     [`NUM_THREAD-1:0]                mask_o         ,
  output     [5:0]                            ctrl_alu_fn_o  ,
  output     [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]ctrl_reg_idxw_o,
  output     [`DEPTH_WARP-1:0]                ctrl_wid_o     ,
  output                                      ctrl_wvd_o     ,
  output                                      ctrl_wxd_o     ,
  output reg [`XLEN-1:0]                      result_o     
  );

  wire    [`XLEN-1:0]                         mul_in1        ;
  wire    [`XLEN-1:0]                         mul_in2        ;
  wire    [`XLEN-1:0]                         mul_in3        ;
  wire    [`XLEN:0]                           signext_mul_in1;//符号位扩展1位后的输入
  wire    [`XLEN:0]                           signext_mul_in2;
  wire    [`XLEN:0]                           zeroext_mul_in1;
  wire    [`XLEN:0]                           zeroext_mul_in2;
  wire    [`XLEN:0]                           ai             ;//booth乘法单元输入
  wire    [`XLEN:0]                           bi             ;
  wire    [2*`XLEN-1:0]                       mul_result     ;

  //pipelinereg:latency=2
  reg                                         in_valid_reg1  ;
  reg                                         in_valid_reg2  ;
  wire                                        reg_en1        ;
  wire                                        reg_en2        ;

  reg     [5:0]                               ctrlvec_alu_fn    ;
  reg     [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]   ctrlvec_reg_idwx  ;
  reg     [`DEPTH_WARP-1:0]                   ctrlvec_wid       ;
  reg                                         ctrlvec_wvd       ;
  reg                                         ctrlvec_wxd       ;
  reg     [`NUM_THREAD-1:0]                   maskvec_mask      ;
  reg     [`XLEN-1:0]                         cvec_mul_in3      ;

  reg     [5:0]                               ctrlvec_alu_fn_reg    ;
  reg     [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]   ctrlvec_reg_idwx_reg  ;
  reg     [`DEPTH_WARP-1:0]                   ctrlvec_wid_reg       ;
  reg                                         ctrlvec_wvd_reg       ;
  reg                                         ctrlvec_wxd_reg       ;
  reg     [`NUM_THREAD-1:0]                   maskvec_mask_reg      ;

  wire    [5:0]                               func              ;
  wire    [2*`XLEN-1:0]                       mac_out           ;
  wire    [`XLEN-1:0]                         res               ;
  wire                                        ismac             ;

  assign mul_in1 = (ctrl_alu_fn_i == `FN_MADD | ctrl_alu_fn_i == `FN_NMSUB) ? c_i : a_i;
  assign mul_in2 = b_i;
  assign mul_in3 = (ctrl_alu_fn_i == `FN_MADD | ctrl_alu_fn_i == `FN_NMSUB) ? a_i : c_i;
  //符号位扩展
  assign signext_mul_in1 = {mul_in1[`XLEN-1],mul_in1};
  assign signext_mul_in2 = {mul_in2[`XLEN-1],mul_in2};
  assign zeroext_mul_in1 = {1'b0,mul_in1};
  assign zeroext_mul_in2 = {1'b0,mul_in2};

  //booth乘法单元输入
  assign ai = (ctrl_alu_fn_i == `FN_MULH | ctrl_alu_fn_i == `FN_MULHSU) ? signext_mul_in1 : zeroext_mul_in1;
  assign bi = ctrl_alu_fn_i == `FN_MULH ? signext_mul_in2 : zeroext_mul_in2;

  //例化booth乘法单元
  mult_32 #(
    .WORDLEN(`XLEN)
  )
  U_mul (
              .clk   (clk       ),
              .rst_n (rst_n     ),
              
              .Asign (ai        ),
              .Bsign (bi        ),
              
              .Result(mul_result)
             );
  //pipeline_reg
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

  //pipeline_reg(1)
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      ctrlvec_alu_fn   <= 'd0;
      ctrlvec_reg_idwx <= 'd0;
      ctrlvec_wid      <= 'd0;
      ctrlvec_wvd      <= 'd0;
      ctrlvec_wxd      <= 'd0;
      maskvec_mask     <= 'd0;
      cvec_mul_in3     <= 'd0;
    end
    else if(reg_en1) begin
      ctrlvec_alu_fn   <= ctrl_alu_fn_i  ;
      ctrlvec_reg_idwx <= ctrl_reg_idxw_i;
      ctrlvec_wid      <= ctrl_wid_i     ;
      ctrlvec_wvd      <= ctrl_wvd_i     ;
      ctrlvec_wxd      <= ctrl_wxd_i     ;
      maskvec_mask     <= mask_i         ;
      cvec_mul_in3     <= mul_in3        ;
    end
    else begin
      ctrlvec_alu_fn   <= ctrlvec_alu_fn  ;
      ctrlvec_reg_idwx <= ctrlvec_reg_idwx;
      ctrlvec_wid      <= ctrlvec_wid     ;
      ctrlvec_wvd      <= ctrlvec_wvd     ;
      ctrlvec_wxd      <= ctrlvec_wxd     ;
      maskvec_mask     <= maskvec_mask    ;
      cvec_mul_in3     <= cvec_mul_in3    ;
    end
  end

  //pipeline_reg(2)
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      ctrlvec_alu_fn_reg   <= 'd0;
      ctrlvec_reg_idwx_reg <= 'd0;
      ctrlvec_wid_reg      <= 'd0;
      ctrlvec_wvd_reg      <= 'd0;
      ctrlvec_wxd_reg      <= 'd0;
      maskvec_mask_reg     <= 'd0;
    end
    else if(reg_en2) begin
      ctrlvec_alu_fn_reg   <= ctrlvec_alu_fn  ;
      ctrlvec_reg_idwx_reg <= ctrlvec_reg_idwx;
      ctrlvec_wid_reg      <= ctrlvec_wid     ;
      ctrlvec_wvd_reg      <= ctrlvec_wvd     ;
      ctrlvec_wxd_reg      <= ctrlvec_wxd     ;
      maskvec_mask_reg     <= maskvec_mask    ;
    end
    else begin
      ctrlvec_alu_fn_reg   <= ctrlvec_alu_fn_reg  ;
      ctrlvec_reg_idwx_reg <= ctrlvec_reg_idwx_reg;
      ctrlvec_wid_reg      <= ctrlvec_wid_reg     ;
      ctrlvec_wvd_reg      <= ctrlvec_wvd_reg     ;
      ctrlvec_wxd_reg      <= ctrlvec_wxd_reg     ;
      maskvec_mask_reg     <= maskvec_mask_reg    ;
    end
  end


  assign func    = ctrlvec_alu_fn;
  assign mac_out = (func == `FN_MACC | func == `FN_MADD) ? (mul_result + {{`XLEN{1'b0}},cvec_mul_in3}) : ({{`XLEN{1'b0}},cvec_mul_in3} - mul_result);
  assign ismac   = func[4:2] == 3'b110; 
  assign res     = ismac ? mac_out[`XLEN-1:0] : ((func == `FN_MULH | func == `FN_MULHU | func == `FN_MULHSU) ? mul_result[2*`XLEN-1:`XLEN] : mul_result[`XLEN-1:0]);

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      result_o <= 'd0;
    end
    else if(reg_en2) begin
      result_o <= res;
    end
    else begin
      result_o <= result_o;
    end
  end

  assign ctrl_alu_fn_o   = ctrlvec_alu_fn_reg  ;
  assign ctrl_reg_idxw_o = ctrlvec_reg_idwx_reg;
  assign ctrl_wid_o      = ctrlvec_wid_reg     ;
  assign ctrl_wvd_o      = ctrlvec_wvd_reg     ;
  assign ctrl_wxd_o      = ctrlvec_wxd_reg     ;
  assign mask_o          = maskvec_mask_reg    ;

endmodule





