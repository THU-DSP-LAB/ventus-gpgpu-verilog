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
// Author: Tangyao
// Description: To decide the order of control_signals in every ibuffer who will going to
// output.
`include "define.v"
//`include "decode_df_para.v"
module slowdown
#(
 parameter    NUM_FETCH   = 2,
 parameter    BUFFER_WIDTH =155 
)
(
  input                                                                   clk                                                    ,
  input                                                                   rst_n                                                  ,
  input [NUM_FETCH-1:0]                                                   slowdown_in_control_mask_i                             ,
  //以下是译码得来的控制信号
  input [BUFFER_WIDTH*NUM_FETCH-1:0]                                      slowdown_in_control_signals_i                          ,
  input                                                                   flush_i                                                ,
  output [BUFFER_WIDTH-1:0]                                               slowdown_out_control_signals_o                         ,
  input                                                                   slowdown_in_control_valid_i                            ,
  output                                                                  slowdown_in_control_ready_o                            ,
  output                                                                  slowdown_out_control_valid_o                           ,
  input                                                                   slowdown_out_control_ready_i                           ,
  input                                                                   slowdown_out_grant_i                                
  );
  //wire                                                                    slowdown_in_control_ready_o ;
  //wire                                                                    slowdown_out_control_valid_o;
  wire                                                                    slowdown_out_fire           ;
  reg  [BUFFER_WIDTH*NUM_FETCH-1:0]                                       control_reg                 ;
  reg  [NUM_FETCH-1:0]                                                    mask_reg                    ;
  wire [NUM_FETCH-1:0]                                                    mask_next                   ;
  wire [$clog2(NUM_FETCH)-1:0] ptr                                                                    ; 
  wire [NUM_FETCH-1:0] mask_reg_oh                                                                    ;
  assign slowdown_out_fire =  slowdown_out_control_valid_o & slowdown_out_control_ready_i;
  assign slowdown_in_fire  =  slowdown_in_control_valid_i  & slowdown_in_control_ready_o ;
  assign slowdown_in_control_ready_o = (mask_reg == 'b0) && slowdown_out_control_ready_i;
  assign slowdown_out_control_valid_o= (mask_reg != 'b0);
  
  fixed_pri_arb #(
  .ARB_WIDTH(NUM_FETCH)
  )U_fixed_pri_arb(
  .req  (mask_reg),
  .grant(mask_reg_oh))
  ;
  one2bin # (
  .ONE_WIDTH(NUM_FETCH),
  .BIN_WIDTH($clog2(NUM_FETCH))
  )
  U_one2bin(
  .oh  (mask_reg_oh),
  .bin (ptr)
  );
  assign mask_next = mask_reg & (~(({NUM_FETCH{1'b0}} + 1'b1 ) << ptr )) ;
  always @(posedge clk or negedge rst_n)
    begin
      if(!rst_n)
        begin
          control_reg <= 0;
          mask_reg    <= 0;
        end
      else if(flush_i)
        begin
          control_reg <= 0;
          mask_reg    <= 0;
        end
      else if(slowdown_in_fire)
        begin
          mask_reg    <= slowdown_in_control_mask_i;  
          control_reg <= slowdown_in_control_signals_i;
        end
      else if(slowdown_out_fire && slowdown_out_grant_i)  
        mask_reg <= mask_next;
    end

  assign slowdown_out_control_signals_o = control_reg [BUFFER_WIDTH * (ptr)+:BUFFER_WIDTH];

endmodule
