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
module fcmp #(
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

  //fcmp_core output
  wire                                      fcmp_core_eq    ;
  wire                                      fcmp_core_le    ;
  wire                                      fcmp_core_lt    ;
  wire    [4:0]                             fcmp_core_fflags;

  //s1_reg
  reg                                       fcmp_core_eq_reg    ;
  reg                                       fcmp_core_le_reg    ;
  reg                                       fcmp_core_lt_reg    ;
  reg     [4:0]                             fcmp_core_fflags_reg;
  reg     [2:0]                             op_reg              ;
  reg     [EXPWIDTH+PRECISION-1:0]          a_reg               ;
  reg     [EXPWIDTH+PRECISION-1:0]          b_reg               ;
`ifdef CTRLGEN
  reg     [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] ctrl_regindex_reg1  ;
  reg     [`DEPTH_WARP-1:0]                 ctrl_warpid_reg1    ;
  reg     [SOFT_THREAD-1:0]                 ctrl_vecmask_reg1   ;
  reg                                       ctrl_wvd_reg1       ;
  reg                                       ctrl_wxd_reg1       ;
`endif

  //s2_reg
`ifdef CTRLGEN
  reg     [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] ctrl_regindex_reg2  ;
  reg     [`DEPTH_WARP-1:0]                 ctrl_warpid_reg2    ;
  reg     [SOFT_THREAD-1:0]                 ctrl_vecmask_reg2   ;
  reg                                       ctrl_wvd_reg2       ;
  reg                                       ctrl_wxd_reg2       ;
`endif
  reg     [EXPWIDTH+PRECISION-1:0]          result_reg          ;
  reg     [4:0]                             fflags_reg          ;

  wire    [EXPWIDTH+PRECISION-1:0]          max                 ;
  wire    [EXPWIDTH+PRECISION-1:0]          min                 ;
  wire    [EXPWIDTH+PRECISION-1:0]          result              ;
  reg     [EXPWIDTH+PRECISION-1:0]          result_temp         ;

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

  //例化fcmp_core
  fcmp_core #(
    .EXPWIDTH (EXPWIDTH),
    .PRECISION(PRECISION)
  )
  U_fcmp_core (
    .a_i        (a_i             ), 
    .b_i        (b_i             ),
    .signaling_i(1'b0            ),
    .eq_o       (fcmp_core_eq    ),
    .le_o       (fcmp_core_le    ),
    .lt_o       (fcmp_core_lt    ),
    .fflags_o   (fcmp_core_fflags)
  );

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      fcmp_core_eq_reg     <= 'd0;
      fcmp_core_le_reg     <= 'd0;
      fcmp_core_lt_reg     <= 'd0;
      fcmp_core_fflags_reg <= 'd0;
      op_reg               <= 'd0;
      a_reg                <= 'd0;
      b_reg                <= 'd0;
      `ifdef CTRLGEN 
      ctrl_regindex_reg1   <= 'd0;   
      ctrl_warpid_reg1     <= 'd0;
      ctrl_vecmask_reg1    <= 'd0;
      ctrl_wvd_reg1        <= 'd0;
      ctrl_wxd_reg1        <= 'd0;
      `endif
    end
    else if(reg_en1) begin
      fcmp_core_eq_reg     <= fcmp_core_eq    ;
      fcmp_core_le_reg     <= fcmp_core_le    ;
      fcmp_core_lt_reg     <= fcmp_core_lt    ;
      fcmp_core_fflags_reg <= fcmp_core_fflags;
      op_reg               <= op_i            ;
      a_reg                <= a_i             ;
      b_reg                <= b_i             ;
      `ifdef CTRLGEN
      ctrl_regindex_reg1   <= ctrl_regindex_i ;   
      ctrl_warpid_reg1     <= ctrl_warpid_i   ;
      ctrl_vecmask_reg1    <= ctrl_vecmask_i  ;
      ctrl_wvd_reg1        <= ctrl_wvd_i      ;
      ctrl_wxd_reg1        <= ctrl_wxd_i      ;
      `endif
    end
    else begin
      fcmp_core_eq_reg     <= fcmp_core_eq_reg    ; 
      fcmp_core_le_reg     <= fcmp_core_le_reg    ;
      fcmp_core_lt_reg     <= fcmp_core_lt_reg    ;
      fcmp_core_fflags_reg <= fcmp_core_fflags_reg;
      op_reg               <= op_reg              ;
      a_reg                <= a_reg               ;
      b_reg                <= b_reg               ;
      `ifdef CTRLGEN
      ctrl_regindex_reg1   <= ctrl_regindex_reg1  ;
      ctrl_warpid_reg1     <= ctrl_warpid_reg1    ;
      ctrl_vecmask_reg1    <= ctrl_vecmask_reg1   ;
      ctrl_wvd_reg1        <= ctrl_wvd_reg1       ;
      ctrl_wxd_reg1        <= ctrl_wxd_reg1       ;
      `endif
    end
  end

  assign max = fcmp_core_lt_reg ? b_reg : a_reg   ;
  assign min = fcmp_core_lt_reg ? a_reg : b_reg   ;
  
  always@(*) begin
    case({3'b001,op_reg})
      `FN_FEQ  : result_temp = fcmp_core_eq_reg    ;
      `FN_FNE  : result_temp = !fcmp_core_eq_reg   ;
      `FN_FLE  : result_temp = fcmp_core_le_reg    ;
      `FN_FLT  : result_temp = fcmp_core_lt_reg    ;
      `FN_FMAX : result_temp = max                 ;
      `FN_FMIN : result_temp = min                 ;
      default  : result_temp = 'd0                 ;
    endcase
  end

  assign result = fcmp_core_fflags_reg[4] ? 'd0 : result_temp;

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
      fflags_reg         <= 'd0;
    end
    else if(reg_en2) begin
      `ifdef CTRLGEN
      ctrl_regindex_reg2 <= ctrl_regindex_reg1  ;  
      ctrl_warpid_reg2   <= ctrl_warpid_reg1    ;
      ctrl_vecmask_reg2  <= ctrl_vecmask_reg1   ;
      ctrl_wvd_reg2      <= ctrl_wvd_reg1       ;
      ctrl_wxd_reg2      <= ctrl_wxd_reg1       ;
      `endif
      result_reg         <= result              ;
      fflags_reg         <= fcmp_core_fflags_reg;
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
      fflags_reg         <= fflags_reg        ;
    end
  end

  assign result_o = result_reg;
  assign fflags_o = fflags_reg;
`ifdef CTRLGEN
  assign ctrl_regindex_o = ctrl_regindex_reg2;
  assign ctrl_warpid_o   = ctrl_warpid_reg2;
  assign ctrl_vecmask_o  = ctrl_vecmask_reg2;
  assign ctrl_wvd_o      = ctrl_wvd_reg2;
  assign ctrl_wxd_o      = ctrl_wxd_reg2;
`endif

endmodule
