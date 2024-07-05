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
// Description:浮点数转整数
`define CTRLGEN
module fp_to_int #(
  parameter EXPWIDTH    = 8,
  parameter PRECISION   = 24,
  parameter SOFT_THREAD = 4
)(
  input                                     clk            ,
  input                                     rst_n          ,

  input   [2:0]                             op_i           ,
  input   [63:0]                            a_i            ,
  input   [2:0]                             rm_i           ,
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

  output  [63:0]                            result_o       ,
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

  wire                         is_single    ;
  wire    [1:0]                core_op      ;
  //s1_reg
  reg                          is_single_reg1    ;
  reg     [1:0]                core_op_reg       ;
  reg     [63:0]               src               ;
  reg     [2:0]                rm_reg            ;
`ifdef CTRLGEN
  reg     [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] ctrl_regindex_reg1;
  reg     [`DEPTH_WARP-1:0]                 ctrl_warpid_reg1  ;
  reg     [SOFT_THREAD-1:0]                 ctrl_vecmask_reg1 ;
  reg                                       ctrl_wvd_reg1     ;
  reg                                       ctrl_wxd_reg1     ;  
`endif 
  //core input
  wire    [EXPWIDTH+PRECISION-1:0]      core_a     ;
  //core output
  wire    [63:0]                        core_result;
  wire    [4:0]                         core_fflags;
  //s2_reg
  reg                          is_single_reg2    ;
  reg     [63:0]               core_result_reg   ;
  reg     [4:0]                core_fflags_reg   ;
`ifdef CTRLGEN
  reg     [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] ctrl_regindex_reg2;
  reg     [`DEPTH_WARP-1:0]                 ctrl_warpid_reg2  ;
  reg     [SOFT_THREAD-1:0]                 ctrl_vecmask_reg2 ;
  reg                                       ctrl_wvd_reg2     ;
  reg                                       ctrl_wxd_reg2     ;
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

  //将输入寄存一拍
  assign is_single = !op_i[2];
  assign core_op   = op_i[1:0] ;
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      is_single_reg1       <= 'd0;
      core_op_reg          <= 'd0;
      src                  <= 'd0;
      rm_reg               <= 'd0;
      `ifdef CTRLGEN
      ctrl_regindex_reg1   <= 'd0;   
      ctrl_warpid_reg1     <= 'd0;
      ctrl_vecmask_reg1    <= 'd0;
      ctrl_wvd_reg1        <= 'd0;
      ctrl_wxd_reg1        <= 'd0;
      `endif
    end
    else if(reg_en1) begin
      is_single_reg1       <= is_single      ;
      core_op_reg          <= core_op        ;
      src                  <= a_i            ;
      rm_reg               <= rm_i           ;
      `ifdef CTRLGEN
      ctrl_regindex_reg1   <= ctrl_regindex_i;   
      ctrl_warpid_reg1     <= ctrl_warpid_i  ;
      ctrl_vecmask_reg1    <= ctrl_vecmask_i ;
      ctrl_wvd_reg1        <= ctrl_wvd_i     ;
      ctrl_wxd_reg1        <= ctrl_wxd_i     ;
      `endif
    end
    else begin
      is_single_reg1       <= is_single_reg1    ;
      core_op_reg          <= core_op_reg       ;
      src                  <= src               ;
      rm_reg               <= rm_reg            ;
      `ifdef CTRLGEN
      ctrl_regindex_reg1   <= ctrl_regindex_reg1;   
      ctrl_warpid_reg1     <= ctrl_warpid_reg1  ;
      ctrl_vecmask_reg1    <= ctrl_vecmask_reg1 ;
      ctrl_wvd_reg1        <= ctrl_wvd_reg1     ;
      ctrl_wxd_reg1        <= ctrl_wxd_reg1     ;
      `endif
    end
  end

  //例化fp_to_int_core
  assign core_a = is_single_reg1 ? src[31:0] : 32'd0;

  fp_to_int_core #(
    .EXPWIDTH (EXPWIDTH ),
    .PRECISION(PRECISION)
  )
  U_fp_to_int_core (
    .a_i     (core_a     ),
    .rm_i    (rm_reg     ),
    .op_i    (core_op_reg),
    .result_o(core_result),
    .fflags_o(core_fflags)
    );

  //将输出寄存一拍
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      `ifdef CTRLGEN
      ctrl_regindex_reg2 <= 'd0; 
      ctrl_warpid_reg2   <= 'd0;
      ctrl_vecmask_reg2  <= 'd0;
      ctrl_wvd_reg2      <= 'd0;
      ctrl_wxd_reg2      <= 'd0;
      `endif
      core_result_reg    <= 'd0;
      core_fflags_reg    <= 'd0;
      is_single_reg2     <= 'd0;
    end
    else if(reg_en2) begin
      `ifdef CTRLGEN
      ctrl_regindex_reg2 <= ctrl_regindex_reg1  ;  
      ctrl_warpid_reg2   <= ctrl_warpid_reg1    ;
      ctrl_vecmask_reg2  <= ctrl_vecmask_reg1   ;
      ctrl_wvd_reg2      <= ctrl_wvd_reg1       ;
      ctrl_wxd_reg2      <= ctrl_wxd_reg1       ;
      `endif
      core_result_reg    <= core_result         ;
      core_fflags_reg    <= core_fflags         ;
      is_single_reg2     <= is_single_reg1      ;
    end
    else begin
      `ifdef CTRLGEN
      ctrl_regindex_reg2 <= ctrl_regindex_reg2;
      ctrl_warpid_reg2   <= ctrl_warpid_reg2  ;
      ctrl_vecmask_reg2  <= ctrl_vecmask_reg2 ;
      ctrl_wvd_reg2      <= ctrl_wvd_reg2     ;
      ctrl_wxd_reg2      <= ctrl_wxd_reg2     ;
      `endif
      core_result_reg    <= core_result_reg   ;
      core_fflags_reg    <= core_fflags_reg   ;
      is_single_reg2     <= is_single_reg2    ;
    end
  end
`ifdef CTRLGEN
  assign ctrl_regindex_o = ctrl_regindex_reg2;
  assign ctrl_warpid_o   = ctrl_warpid_reg2  ;
  assign ctrl_vecmask_o  = ctrl_vecmask_reg2 ;
  assign ctrl_wvd_o      = ctrl_wvd_reg2     ;
  assign ctrl_wxd_o      = ctrl_wxd_reg2     ;
`endif
  assign fflags_o        = is_single_reg2 ? core_fflags_reg : 5'd0;
  assign result_o        = is_single_reg2 ? core_result_reg : 64'd0;

endmodule
