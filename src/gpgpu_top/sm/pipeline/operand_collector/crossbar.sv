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
// Author: Chen, Qixiang
// Description:
`include "define.v"

`timescale 1ns/1ps

module crossbar(
  //input                                             clk                     ,
  //input                                             rst_n                   ,

  // input interface
  input   [$clog2(4*`NUM_COLLECTORUNIT)-1:0]        chosen_scalar_i         [`NUM_BANK-1:0]           , 
  input   [$clog2(4*`NUM_COLLECTORUNIT)-1:0]        chosen_vector_i         [`NUM_BANK-1:0]           ,
  input                                             valid_arbiter_scalar_i  [`NUM_BANK-1:0]           ,
  input                                             valid_arbiter_vector_i  [`NUM_BANK-1:0]           ,
  input   [`XLEN-1:0]                               data_scalar_rs_i        [`NUM_BANK-1:0]           ,
  input   [`XLEN*`NUM_THREAD-1:0]                   data_vector_rs_i        [`NUM_BANK-1:0]           ,
  input   [`XLEN*`NUM_THREAD-1:0]                   data_vector_v0_i        [`NUM_BANK-1:0]           ,

  // output interface
  output  [4-1:0]                                   out_valid_o      [`NUM_COLLECTORUNIT-1:0]         ,
  output  [2*4-1:0]                                 out_regOrder_o   [`NUM_COLLECTORUNIT-1:0]         ,
  output  [`XLEN*`NUM_THREAD*4-1:0]                 out_data_o       [`NUM_COLLECTORUNIT-1:0]         ,
  output  [`XLEN*`NUM_THREAD*4-1:0]                 out_v0_o         [`NUM_COLLECTORUNIT-1:0]        
);

  parameter DEPTH_4_COLLECTORUNIT = $clog2(4*`NUM_COLLECTORUNIT);  

  wire [`DEPTH_COLLECTORUNIT*`NUM_BANK-1:0]  cu_id_scalar      ;
  wire [`DEPTH_COLLECTORUNIT*`NUM_BANK-1:0]  cu_id_vector      ;
  wire [2*`NUM_BANK-1:0]                     regOrder_scalar   ;
  wire [2*`NUM_BANK-1:0]                     regOrder_vector   ;

  reg [4-1:0]                               out_valid_0       ;
  reg [2*4-1:0]                             out_regOrder_0    ;
  reg [`XLEN*`NUM_THREAD*4-1:0]             out_data_0        ;
  reg [`XLEN*`NUM_THREAD*4-1:0]             out_v0_0          ;

  reg [4-1:0]                               out_valid_1       ;
  reg [2*4-1:0]                             out_regOrder_1    ;
  reg [`XLEN*`NUM_THREAD*4-1:0]             out_data_1        ;
  reg [`XLEN*`NUM_THREAD*4-1:0]             out_v0_1          ;

  reg [4-1:0]                               out_valid_2       ;
  reg [2*4-1:0]                             out_regOrder_2    ;
  reg [`XLEN*`NUM_THREAD*4-1:0]             out_data_2        ;
  reg [`XLEN*`NUM_THREAD*4-1:0]             out_v0_2          ;

  reg [4-1:0]                               out_valid_3       ;
  reg [2*4-1:0]                             out_regOrder_3    ;
  reg [`XLEN*`NUM_THREAD*4-1:0]             out_data_3        ;
  reg [`XLEN*`NUM_THREAD*4-1:0]             out_v0_3          ;

  reg [4-1:0]                               out_valid_4       ;
  reg [2*4-1:0]                             out_regOrder_4    ;
  reg [`XLEN*`NUM_THREAD*4-1:0]             out_data_4        ;
  reg [`XLEN*`NUM_THREAD*4-1:0]             out_v0_4          ;

  reg [4-1:0]                               out_valid_5       ;
  reg [2*4-1:0]                             out_regOrder_5    ;
  reg [`XLEN*`NUM_THREAD*4-1:0]             out_data_5        ;
  reg [`XLEN*`NUM_THREAD*4-1:0]             out_v0_5          ;

  reg [4-1:0]                               out_valid_6       ;
  reg [2*4-1:0]                             out_regOrder_6    ;
  reg [`XLEN*`NUM_THREAD*4-1:0]             out_data_6        ;
  reg [`XLEN*`NUM_THREAD*4-1:0]             out_v0_6          ;

  reg [4-1:0]                               out_valid_7       ;
  reg [2*4-1:0]                             out_regOrder_7    ;
  reg [`XLEN*`NUM_THREAD*4-1:0]             out_data_7        ;
  reg [`XLEN*`NUM_THREAD*4-1:0]             out_v0_7          ;
  
 
  genvar n;
  generate
    for (n=0; n<`NUM_BANK; n=n+1) begin:cuId_and_regOrder
      assign  regOrder_scalar[2*(n+1)-1-:2] = chosen_scalar_i[n][1:0];
      assign  regOrder_vector[2*(n+1)-1-:2] = chosen_vector_i[n][1:0];
      assign  cu_id_scalar[`DEPTH_COLLECTORUNIT*(n+1)-1-:`DEPTH_COLLECTORUNIT] = {2'b0,chosen_scalar_i[n][DEPTH_4_COLLECTORUNIT-1:2]} ;
      assign  cu_id_vector[`DEPTH_COLLECTORUNIT*(n+1)-1-:`DEPTH_COLLECTORUNIT] = {2'b0,chosen_vector_i[n][DEPTH_4_COLLECTORUNIT-1:2]} ;
    end
  endgenerate

  always @(*) begin

    out_valid_0         =  'b0;
    out_regOrder_0      =  'b0;
    out_data_0          =  'b0;
    out_v0_0            =  'b0;
    out_valid_1         =  'b0;
    out_regOrder_1      =  'b0;
    out_data_1          =  'b0;
    out_v0_1            =  'b0;
    out_valid_2         =  'b0;
    out_regOrder_2      =  'b0;
    out_data_2          =  'b0;
    out_v0_2            =  'b0;
    out_valid_3         =  'b0;
    out_regOrder_3      =  'b0;
    out_data_3          =  'b0;
    out_v0_3            =  'b0;
    out_valid_4         =  'b0;
    out_regOrder_4      =  'b0;
    out_data_4          =  'b0;
    out_v0_4            =  'b0;
    out_valid_5         =  'b0;
    out_regOrder_5      =  'b0;
    out_data_5          =  'b0;
    out_v0_5            =  'b0;
    out_valid_6         =  'b0;
    out_regOrder_6      =  'b0;
    out_data_6          =  'b0;
    out_v0_6            =  'b0;
    out_valid_7         =  'b0;
    out_regOrder_7      =  'b0;
    out_data_7          =  'b0;
    out_v0_7            =  'b0;

    if(valid_arbiter_scalar_i[0] || valid_arbiter_vector_i[0]) begin
      if(valid_arbiter_scalar_i[0]) begin
        case(cu_id_scalar[`DEPTH_COLLECTORUNIT*(0+1)-1-:`DEPTH_COLLECTORUNIT])
          3'd0: begin   out_valid_0     [regOrder_scalar[1:0]]                                               =  1'b1                               ;
                        out_regOrder_0  [2*(regOrder_scalar[1:0]+1)-1-:2]                                    =  regOrder_scalar[1:0]               ;
                        out_data_0      [`XLEN*`NUM_THREAD*(regOrder_scalar[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[0]}} ;
                        out_v0_0        [`XLEN*`NUM_THREAD*(regOrder_scalar[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          3'd1: begin   out_valid_1     [regOrder_scalar[1:0]]                                               =  1'b1                               ;
                        out_regOrder_1  [2*(regOrder_scalar[1:0]+1)-1-:2]                                    =  regOrder_scalar[1:0]               ;
                        out_data_1      [`XLEN*`NUM_THREAD*(regOrder_scalar[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[0]}} ;
                        out_v0_1        [`XLEN*`NUM_THREAD*(regOrder_scalar[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          3'd2: begin   out_valid_2     [regOrder_scalar[1:0]]                                               =  1'b1                               ;
                        out_regOrder_2  [2*(regOrder_scalar[1:0]+1)-1-:2]                                    =  regOrder_scalar[1:0]               ;
                        out_data_2      [`XLEN*`NUM_THREAD*(regOrder_scalar[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[0]}} ;
                        out_v0_2        [`XLEN*`NUM_THREAD*(regOrder_scalar[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          3'd3: begin   out_valid_3     [regOrder_scalar[1:0]]                                               =  1'b1                               ;
                        out_regOrder_3  [2*(regOrder_scalar[1:0]+1)-1-:2]                                    =  regOrder_scalar[1:0]               ;
                        out_data_3      [`XLEN*`NUM_THREAD*(regOrder_scalar[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[0]}} ;
                        out_v0_3        [`XLEN*`NUM_THREAD*(regOrder_scalar[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          3'd4: begin   out_valid_4     [regOrder_scalar[1:0]]                                               =  1'b1                               ;
                        out_regOrder_4  [2*(regOrder_scalar[1:0]+1)-1-:2]                                    =  regOrder_scalar[1:0]               ;
                        out_data_4      [`XLEN*`NUM_THREAD*(regOrder_scalar[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[0]}} ;
                        out_v0_4        [`XLEN*`NUM_THREAD*(regOrder_scalar[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          3'd5: begin   out_valid_5     [regOrder_scalar[1:0]]                                               =  1'b1                               ;
                        out_regOrder_5  [2*(regOrder_scalar[1:0]+1)-1-:2]                                    =  regOrder_scalar[1:0]               ;
                        out_data_5      [`XLEN*`NUM_THREAD*(regOrder_scalar[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[0]}} ;
                        out_v0_5        [`XLEN*`NUM_THREAD*(regOrder_scalar[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          3'd6: begin   out_valid_6     [regOrder_scalar[1:0]]                                               =  1'b1                               ;
                        out_regOrder_6  [2*(regOrder_scalar[1:0]+1)-1-:2]                                    =  regOrder_scalar[1:0]               ;
                        out_data_6      [`XLEN*`NUM_THREAD*(regOrder_scalar[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[0]}} ;
                        out_v0_6        [`XLEN*`NUM_THREAD*(regOrder_scalar[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          3'd7: begin   out_valid_7     [regOrder_scalar[1:0]]                                               =  1'b1                               ;
                        out_regOrder_7  [2*(regOrder_scalar[1:0]+1)-1-:2]                                    =  regOrder_scalar[1:0]               ;
                        out_data_7      [`XLEN*`NUM_THREAD*(regOrder_scalar[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[0]}} ;
                        out_v0_7        [`XLEN*`NUM_THREAD*(regOrder_scalar[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          default: ;
        endcase
      end else begin
        case(cu_id_vector[`DEPTH_COLLECTORUNIT*(0+1)-1-:`DEPTH_COLLECTORUNIT])
          3'd0: begin   out_valid_0     [regOrder_vector[1:0]]                                               =  1'b1                          ;
                        out_regOrder_0  [2*(regOrder_vector[1:0]+1)-1-:2]                                    =  regOrder_vector[1:0] ;
                        out_data_0      [`XLEN*`NUM_THREAD*(regOrder_vector[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[0]           ;
                        out_v0_0        [`XLEN*`NUM_THREAD*(regOrder_vector[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[0]           ;
                 end
          3'd1: begin   out_valid_1     [regOrder_vector[1:0]]                                               =  1'b1                          ;
                        out_regOrder_1  [2*(regOrder_vector[1:0]+1)-1-:2]                                    =  regOrder_vector[1:0] ;
                        out_data_1      [`XLEN*`NUM_THREAD*(regOrder_vector[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[0]           ;
                        out_v0_1        [`XLEN*`NUM_THREAD*(regOrder_vector[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[0]           ;
                 end
          3'd2: begin   out_valid_2     [regOrder_vector[1:0]]                                               =  1'b1                          ;
                        out_regOrder_2  [2*(regOrder_vector[1:0]+1)-1-:2]                                    =  regOrder_vector[1:0] ;
                        out_data_2      [`XLEN*`NUM_THREAD*(regOrder_vector[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[0]           ;
                        out_v0_2        [`XLEN*`NUM_THREAD*(regOrder_vector[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[0]           ;
                 end
          3'd3: begin   out_valid_3     [regOrder_vector[1:0]]                                               =  1'b1                          ;
                        out_regOrder_3  [2*(regOrder_vector[1:0]+1)-1-:2]                                    =  regOrder_vector[1:0] ;
                        out_data_3      [`XLEN*`NUM_THREAD*(regOrder_vector[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[0]           ;
                        out_v0_3        [`XLEN*`NUM_THREAD*(regOrder_vector[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[0]           ;
                 end
          3'd4: begin   out_valid_4     [regOrder_vector[1:0]]                                               =  1'b1                          ;
                        out_regOrder_4  [2*(regOrder_vector[1:0]+1)-1-:2]                                    =  regOrder_vector[1:0] ;
                        out_data_4      [`XLEN*`NUM_THREAD*(regOrder_vector[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[0]           ;
                        out_v0_4        [`XLEN*`NUM_THREAD*(regOrder_vector[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[0]           ;
                 end
          3'd5: begin   out_valid_5     [regOrder_vector[1:0]]                                               =  1'b1                          ;
                        out_regOrder_5  [2*(regOrder_vector[1:0]+1)-1-:2]                                    =  regOrder_vector[1:0] ;
                        out_data_5      [`XLEN*`NUM_THREAD*(regOrder_vector[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[0]           ;
                        out_v0_5        [`XLEN*`NUM_THREAD*(regOrder_vector[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[0]           ;
                 end
          3'd6: begin   out_valid_6     [regOrder_vector[1:0]]                                               =  1'b1                          ;
                        out_regOrder_6  [2*(regOrder_vector[1:0]+1)-1-:2]                                    =  regOrder_vector[1:0] ;
                        out_data_6      [`XLEN*`NUM_THREAD*(regOrder_vector[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[0]           ;
                        out_v0_6        [`XLEN*`NUM_THREAD*(regOrder_vector[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[0]           ;
                 end
          3'd7: begin   out_valid_7     [regOrder_vector[1:0]]                                               =  1'b1                          ;
                        out_regOrder_7  [2*(regOrder_vector[1:0]+1)-1-:2]                                    =  regOrder_vector[1:0] ;
                        out_data_7      [`XLEN*`NUM_THREAD*(regOrder_vector[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[0]           ;
                        out_v0_7        [`XLEN*`NUM_THREAD*(regOrder_vector[1:0]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[0]           ;
                 end
          default: ;
        endcase
      end
    end else if(valid_arbiter_scalar_i[1] || valid_arbiter_vector_i[1]) begin
      if(valid_arbiter_scalar_i[1]) begin
        case(cu_id_scalar[`DEPTH_COLLECTORUNIT*(1+1)-1-:`DEPTH_COLLECTORUNIT])
          3'd0: begin   out_valid_0     [regOrder_scalar[3:2]]                                               =  1'b1                               ;
                        out_regOrder_0  [2*(regOrder_scalar[3:2]+1)-1-:2]                                    =  regOrder_scalar[3:2]               ;
                        out_data_0      [`XLEN*`NUM_THREAD*(regOrder_scalar[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[1]}} ;
                        out_v0_0        [`XLEN*`NUM_THREAD*(regOrder_scalar[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          3'd1: begin   out_valid_1     [regOrder_scalar[3:2]]                                               =  1'b1                               ;
                        out_regOrder_1  [2*(regOrder_scalar[3:2]+1)-1-:2]                                    =  regOrder_scalar[3:2]               ;
                        out_data_1      [`XLEN*`NUM_THREAD*(regOrder_scalar[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[1]}} ;
                        out_v0_1        [`XLEN*`NUM_THREAD*(regOrder_scalar[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          3'd2: begin   out_valid_2     [regOrder_scalar[3:2]]                                               =  1'b1                               ;
                        out_regOrder_2  [2*(regOrder_scalar[3:2]+1)-1-:2]                                    =  regOrder_scalar[3:2]               ;
                        out_data_2      [`XLEN*`NUM_THREAD*(regOrder_scalar[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[1]}} ;
                        out_v0_2        [`XLEN*`NUM_THREAD*(regOrder_scalar[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          3'd3: begin   out_valid_3     [regOrder_scalar[3:2]]                                               =  1'b1                               ;
                        out_regOrder_3  [2*(regOrder_scalar[3:2]+1)-1-:2]                                    =  regOrder_scalar[3:2]               ;
                        out_data_3      [`XLEN*`NUM_THREAD*(regOrder_scalar[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[1]}} ;
                        out_v0_3        [`XLEN*`NUM_THREAD*(regOrder_scalar[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          3'd4: begin   out_valid_4     [regOrder_scalar[3:2]]                                               =  1'b1                               ;
                        out_regOrder_4  [2*(regOrder_scalar[3:2]+1)-1-:2]                                    =  regOrder_scalar[3:2]               ;
                        out_data_4      [`XLEN*`NUM_THREAD*(regOrder_scalar[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[1]}} ;
                        out_v0_4        [`XLEN*`NUM_THREAD*(regOrder_scalar[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          3'd5: begin   out_valid_5     [regOrder_scalar[3:2]]                                               =  1'b1                               ;
                        out_regOrder_5  [2*(regOrder_scalar[3:2]+1)-1-:2]                                    =  regOrder_scalar[3:2]               ;
                        out_data_5      [`XLEN*`NUM_THREAD*(regOrder_scalar[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[1]}} ;
                        out_v0_5        [`XLEN*`NUM_THREAD*(regOrder_scalar[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          3'd6: begin   out_valid_6     [regOrder_scalar[3:2]]                                               =  1'b1                               ;
                        out_regOrder_6  [2*(regOrder_scalar[3:2]+1)-1-:2]                                    =  regOrder_scalar[3:2]               ;
                        out_data_6      [`XLEN*`NUM_THREAD*(regOrder_scalar[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[1]}} ;
                        out_v0_6        [`XLEN*`NUM_THREAD*(regOrder_scalar[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          3'd7: begin   out_valid_7     [regOrder_scalar[3:2]]                                               =  1'b1                               ;
                        out_regOrder_7  [2*(regOrder_scalar[3:2]+1)-1-:2]                                    =  regOrder_scalar[3:2]               ;
                        out_data_7      [`XLEN*`NUM_THREAD*(regOrder_scalar[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[1]}} ;
                        out_v0_7        [`XLEN*`NUM_THREAD*(regOrder_scalar[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          default: ;
        endcase
      end else begin
        case(cu_id_vector[`DEPTH_COLLECTORUNIT*(1+1)-1-:`DEPTH_COLLECTORUNIT])
          3'd0: begin   out_valid_0     [regOrder_vector[3:2]]                                               =  1'b1                          ;
                        out_regOrder_0  [2*(regOrder_vector[3:2]+1)-1-:2]                                    =  regOrder_vector[3:2] ;
                        out_data_0      [`XLEN*`NUM_THREAD*(regOrder_vector[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[1]           ;
                        out_v0_0        [`XLEN*`NUM_THREAD*(regOrder_vector[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[1]           ;
                 end
          3'd1: begin   out_valid_1     [regOrder_vector[3:2]]                                               =  1'b1                          ;
                        out_regOrder_1  [2*(regOrder_vector[3:2]+1)-1-:2]                                    =  regOrder_vector[3:2] ;
                        out_data_1      [`XLEN*`NUM_THREAD*(regOrder_vector[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[1]           ;
                        out_v0_1        [`XLEN*`NUM_THREAD*(regOrder_vector[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[1]           ;
                 end
          3'd2: begin   out_valid_2     [regOrder_vector[3:2]]                                               =  1'b1                          ;
                        out_regOrder_2  [2*(regOrder_vector[3:2]+1)-1-:2]                                    =  regOrder_vector[3:2] ;
                        out_data_2      [`XLEN*`NUM_THREAD*(regOrder_vector[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[1]           ;
                        out_v0_2        [`XLEN*`NUM_THREAD*(regOrder_vector[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[1]           ;
                 end
          3'd3: begin   out_valid_3     [regOrder_vector[3:2]]                                               =  1'b1                          ;
                        out_regOrder_3  [2*(regOrder_vector[3:2]+1)-1-:2]                                    =  regOrder_vector[3:2] ;
                        out_data_3      [`XLEN*`NUM_THREAD*(regOrder_vector[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[1]           ;
                        out_v0_3        [`XLEN*`NUM_THREAD*(regOrder_vector[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[1]           ;
                 end
          3'd4: begin   out_valid_4     [regOrder_vector[3:2]]                                               =  1'b1                          ;
                        out_regOrder_4  [2*(regOrder_vector[3:2]+1)-1-:2]                                    =  regOrder_vector[3:2] ;
                        out_data_4      [`XLEN*`NUM_THREAD*(regOrder_vector[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[1]           ;
                        out_v0_4        [`XLEN*`NUM_THREAD*(regOrder_vector[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[1]           ;
                 end
          3'd5: begin   out_valid_5     [regOrder_vector[3:2]]                                               =  1'b1                          ;
                        out_regOrder_5  [2*(regOrder_vector[3:2]+1)-1-:2]                                    =  regOrder_vector[3:2] ;
                        out_data_5      [`XLEN*`NUM_THREAD*(regOrder_vector[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[1]           ;
                        out_v0_5        [`XLEN*`NUM_THREAD*(regOrder_vector[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[1]           ;
                 end
          3'd6: begin   out_valid_6     [regOrder_vector[3:2]]                                               =  1'b1                          ;
                        out_regOrder_6  [2*(regOrder_vector[3:2]+1)-1-:2]                                    =  regOrder_vector[3:2] ;
                        out_data_6      [`XLEN*`NUM_THREAD*(regOrder_vector[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[1]           ;
                        out_v0_6        [`XLEN*`NUM_THREAD*(regOrder_vector[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[1]           ;
                 end
          3'd7: begin   out_valid_7     [regOrder_vector[3:2]]                                               =  1'b1                          ;
                        out_regOrder_7  [2*(regOrder_vector[3:2]+1)-1-:2]                                    =  regOrder_vector[3:2] ;
                        out_data_7      [`XLEN*`NUM_THREAD*(regOrder_vector[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[1]           ;
                        out_v0_7        [`XLEN*`NUM_THREAD*(regOrder_vector[3:2]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[1]           ;
                 end
          default: ;
        endcase
      end
    end else if(valid_arbiter_scalar_i[2] || valid_arbiter_vector_i[2]) begin
      if(valid_arbiter_scalar_i[2]) begin
        case(cu_id_scalar[`DEPTH_COLLECTORUNIT*(2+1)-1-:`DEPTH_COLLECTORUNIT])
          3'd0: begin   out_valid_0     [regOrder_scalar[5:4]]                                               =  1'b1                               ;
                        out_regOrder_0  [2*(regOrder_scalar[5:4]+1)-1-:2]                                    =  regOrder_scalar[5:4]               ;
                        out_data_0      [`XLEN*`NUM_THREAD*(regOrder_scalar[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[2]}} ;
                        out_v0_0        [`XLEN*`NUM_THREAD*(regOrder_scalar[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          3'd1: begin   out_valid_1     [regOrder_scalar[5:4]]                                               =  1'b1                               ;
                        out_regOrder_1  [2*(regOrder_scalar[5:4]+1)-1-:2]                                    =  regOrder_scalar[5:4]               ;
                        out_data_1      [`XLEN*`NUM_THREAD*(regOrder_scalar[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[2]}} ;
                        out_v0_1        [`XLEN*`NUM_THREAD*(regOrder_scalar[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          3'd2: begin   out_valid_2     [regOrder_scalar[5:4]]                                               =  1'b1                               ;
                        out_regOrder_2  [2*(regOrder_scalar[5:4]+1)-1-:2]                                    =  regOrder_scalar[5:4]               ;
                        out_data_2      [`XLEN*`NUM_THREAD*(regOrder_scalar[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[2]}} ;
                        out_v0_2        [`XLEN*`NUM_THREAD*(regOrder_scalar[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          3'd3: begin   out_valid_3     [regOrder_scalar[5:4]]                                               =  1'b1                               ;
                        out_regOrder_3  [2*(regOrder_scalar[5:4]+1)-1-:2]                                    =  regOrder_scalar[5:4]               ;
                        out_data_3      [`XLEN*`NUM_THREAD*(regOrder_scalar[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[2]}} ;
                        out_v0_3        [`XLEN*`NUM_THREAD*(regOrder_scalar[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          3'd4: begin   out_valid_4     [regOrder_scalar[5:4]]                                               =  1'b1                               ;
                        out_regOrder_4  [2*(regOrder_scalar[5:4]+1)-1-:2]                                    =  regOrder_scalar[5:4]               ;
                        out_data_4      [`XLEN*`NUM_THREAD*(regOrder_scalar[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[2]}} ;
                        out_v0_4        [`XLEN*`NUM_THREAD*(regOrder_scalar[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          3'd5: begin   out_valid_5     [regOrder_scalar[5:4]]                                               =  1'b1                               ;
                        out_regOrder_5  [2*(regOrder_scalar[5:4]+1)-1-:2]                                    =  regOrder_scalar[5:4]               ;
                        out_data_5      [`XLEN*`NUM_THREAD*(regOrder_scalar[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[2]}} ;
                        out_v0_5        [`XLEN*`NUM_THREAD*(regOrder_scalar[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          3'd6: begin   out_valid_6     [regOrder_scalar[5:4]]                                               =  1'b1                               ;
                        out_regOrder_6  [2*(regOrder_scalar[5:4]+1)-1-:2]                                    =  regOrder_scalar[5:4]               ;
                        out_data_6      [`XLEN*`NUM_THREAD*(regOrder_scalar[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[2]}} ;
                        out_v0_6        [`XLEN*`NUM_THREAD*(regOrder_scalar[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          3'd7: begin   out_valid_7     [regOrder_scalar[5:4]]                                               =  1'b1                               ;
                        out_regOrder_7  [2*(regOrder_scalar[5:4]+1)-1-:2]                                    =  regOrder_scalar[5:4]               ;
                        out_data_7      [`XLEN*`NUM_THREAD*(regOrder_scalar[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[2]}} ;
                        out_v0_7        [`XLEN*`NUM_THREAD*(regOrder_scalar[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          default: ;
        endcase
      end else begin
        case(cu_id_vector[`DEPTH_COLLECTORUNIT*(2+1)-1-:`DEPTH_COLLECTORUNIT])
          3'd0: begin   out_valid_0     [regOrder_vector[5:4]]                                               =  1'b1                          ;
                        out_regOrder_0  [2*(regOrder_vector[5:4]+1)-1-:2]                                    =  regOrder_vector[5:4] ;
                        out_data_0      [`XLEN*`NUM_THREAD*(regOrder_vector[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[2]           ;
                        out_v0_0        [`XLEN*`NUM_THREAD*(regOrder_vector[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[2]           ;
                 end
          3'd1: begin   out_valid_1     [regOrder_vector[5:4]]                                               =  1'b1                          ;
                        out_regOrder_1  [2*(regOrder_vector[5:4]+1)-1-:2]                                    =  regOrder_vector[5:4] ;
                        out_data_1      [`XLEN*`NUM_THREAD*(regOrder_vector[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[2]           ;
                        out_v0_1        [`XLEN*`NUM_THREAD*(regOrder_vector[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[2]           ;
                 end
          3'd2: begin   out_valid_2     [regOrder_vector[5:4]]                                               =  1'b1                          ;
                        out_regOrder_2  [2*(regOrder_vector[5:4]+1)-1-:2]                                    =  regOrder_vector[5:4] ;
                        out_data_2      [`XLEN*`NUM_THREAD*(regOrder_vector[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[2]           ;
                        out_v0_2        [`XLEN*`NUM_THREAD*(regOrder_vector[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[2]           ;
                 end
          3'd3: begin   out_valid_3     [regOrder_vector[5:4]]                                               =  1'b1                          ;
                        out_regOrder_3  [2*(regOrder_vector[5:4]+1)-1-:2]                                    =  regOrder_vector[5:4] ;
                        out_data_3      [`XLEN*`NUM_THREAD*(regOrder_vector[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[2]           ;
                        out_v0_3        [`XLEN*`NUM_THREAD*(regOrder_vector[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[2]           ;
                 end
          3'd4: begin   out_valid_4     [regOrder_vector[5:4]]                                               =  1'b1                          ;
                        out_regOrder_4  [2*(regOrder_vector[5:4]+1)-1-:2]                                    =  regOrder_vector[5:4] ;
                        out_data_4      [`XLEN*`NUM_THREAD*(regOrder_vector[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[2]           ;
                        out_v0_4        [`XLEN*`NUM_THREAD*(regOrder_vector[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[2]           ;
                 end
          3'd5: begin   out_valid_5     [regOrder_vector[5:4]]                                               =  1'b1                          ;
                        out_regOrder_5  [2*(regOrder_vector[5:4]+1)-1-:2]                                    =  regOrder_vector[5:4] ;
                        out_data_5      [`XLEN*`NUM_THREAD*(regOrder_vector[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[2]           ;
                        out_v0_5        [`XLEN*`NUM_THREAD*(regOrder_vector[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[2]           ;
                 end
          3'd6: begin   out_valid_6     [regOrder_vector[5:4]]                                               =  1'b1                          ;
                        out_regOrder_6  [2*(regOrder_vector[5:4]+1)-1-:2]                                    =  regOrder_vector[5:4] ;
                        out_data_6      [`XLEN*`NUM_THREAD*(regOrder_vector[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[2]           ;
                        out_v0_6        [`XLEN*`NUM_THREAD*(regOrder_vector[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[2]           ;
                 end
          3'd7: begin   out_valid_7     [regOrder_vector[5:4]]                                               =  1'b1                          ;
                        out_regOrder_7  [2*(regOrder_vector[5:4]+1)-1-:2]                                    =  regOrder_vector[5:4] ;
                        out_data_7      [`XLEN*`NUM_THREAD*(regOrder_vector[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[2]           ;
                        out_v0_7        [`XLEN*`NUM_THREAD*(regOrder_vector[5:4]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[2]           ;
                 end
          default: ;
        endcase
      end
    end else if(valid_arbiter_scalar_i[3] || valid_arbiter_vector_i[3]) begin
      if(valid_arbiter_scalar_i[3]) begin
        case(cu_id_scalar[`DEPTH_COLLECTORUNIT*(3+1)-1-:`DEPTH_COLLECTORUNIT])
          3'd0: begin   out_valid_0     [regOrder_scalar[7:6]]                                               =  1'b1                               ;
                        out_regOrder_0  [2*(regOrder_scalar[7:6]+1)-1-:2]                                    =  regOrder_scalar[7:6]               ;
                        out_data_0      [`XLEN*`NUM_THREAD*(regOrder_scalar[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[3]}} ;
                        out_v0_0        [`XLEN*`NUM_THREAD*(regOrder_scalar[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          3'd1: begin   out_valid_1     [regOrder_scalar[7:6]]                                               =  1'b1                               ;
                        out_regOrder_1  [2*(regOrder_scalar[7:6]+1)-1-:2]                                    =  regOrder_scalar[7:6]               ;
                        out_data_1      [`XLEN*`NUM_THREAD*(regOrder_scalar[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[3]}} ;
                        out_v0_1        [`XLEN*`NUM_THREAD*(regOrder_scalar[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          3'd2: begin   out_valid_2     [regOrder_scalar[7:6]]                                               =  1'b1                               ;
                        out_regOrder_2  [2*(regOrder_scalar[7:6]+1)-1-:2]                                    =  regOrder_scalar[7:6]               ;
                        out_data_2      [`XLEN*`NUM_THREAD*(regOrder_scalar[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[3]}} ;
                        out_v0_2        [`XLEN*`NUM_THREAD*(regOrder_scalar[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          3'd3: begin   out_valid_3     [regOrder_scalar[7:6]]                                               =  1'b1                               ;
                        out_regOrder_3  [2*(regOrder_scalar[7:6]+1)-1-:2]                                    =  regOrder_scalar[7:6]               ;
                        out_data_3      [`XLEN*`NUM_THREAD*(regOrder_scalar[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[3]}} ;
                        out_v0_3        [`XLEN*`NUM_THREAD*(regOrder_scalar[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          3'd4: begin   out_valid_4     [regOrder_scalar[7:6]]                                               =  1'b1                               ;
                        out_regOrder_4  [2*(regOrder_scalar[7:6]+1)-1-:2]                                    =  regOrder_scalar[7:6]               ;
                        out_data_4      [`XLEN*`NUM_THREAD*(regOrder_scalar[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[3]}} ;
                        out_v0_4        [`XLEN*`NUM_THREAD*(regOrder_scalar[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          3'd5: begin   out_valid_5     [regOrder_scalar[7:6]]                                               =  1'b1                               ;
                        out_regOrder_5  [2*(regOrder_scalar[7:6]+1)-1-:2]                                    =  regOrder_scalar[7:6]               ;
                        out_data_5      [`XLEN*`NUM_THREAD*(regOrder_scalar[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[3]}} ;
                        out_v0_5        [`XLEN*`NUM_THREAD*(regOrder_scalar[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          3'd6: begin   out_valid_6     [regOrder_scalar[7:6]]                                               =  1'b1                               ;
                        out_regOrder_6  [2*(regOrder_scalar[7:6]+1)-1-:2]                                    =  regOrder_scalar[7:6]               ;
                        out_data_6      [`XLEN*`NUM_THREAD*(regOrder_scalar[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[3]}} ;
                        out_v0_6        [`XLEN*`NUM_THREAD*(regOrder_scalar[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          3'd7: begin   out_valid_7     [regOrder_scalar[7:6]]                                               =  1'b1                               ;
                        out_regOrder_7  [2*(regOrder_scalar[7:6]+1)-1-:2]                                    =  regOrder_scalar[7:6]               ;
                        out_data_7      [`XLEN*`NUM_THREAD*(regOrder_scalar[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  {`NUM_THREAD{data_scalar_rs_i[3]}} ;
                        out_v0_7        [`XLEN*`NUM_THREAD*(regOrder_scalar[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  'b0                                ;
                 end
          default: ;
        endcase
      end else begin
        case(cu_id_vector[`DEPTH_COLLECTORUNIT*(3+1)-1-:`DEPTH_COLLECTORUNIT])
          3'd0: begin   out_valid_0     [regOrder_vector[7:6]]                                               =  1'b1                          ;
                        out_regOrder_0  [2*(regOrder_vector[7:6]+1)-1-:2]                                    =  regOrder_vector[7:6] ;
                        out_data_0      [`XLEN*`NUM_THREAD*(regOrder_vector[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[3]           ;
                        out_v0_0        [`XLEN*`NUM_THREAD*(regOrder_vector[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[3]           ;
                 end
          3'd1: begin   out_valid_1     [regOrder_vector[7:6]]                                               =  1'b1                          ;
                        out_regOrder_1  [2*(regOrder_vector[7:6]+1)-1-:2]                                    =  regOrder_vector[7:6] ;
                        out_data_1      [`XLEN*`NUM_THREAD*(regOrder_vector[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[3]           ;
                        out_v0_1        [`XLEN*`NUM_THREAD*(regOrder_vector[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[3]           ;
                 end
          3'd2: begin   out_valid_2     [regOrder_vector[7:6]]                                               =  1'b1                          ;
                        out_regOrder_2  [2*(regOrder_vector[7:6]+1)-1-:2]                                    =  regOrder_vector[7:6] ;
                        out_data_2      [`XLEN*`NUM_THREAD*(regOrder_vector[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[3]           ;
                        out_v0_2        [`XLEN*`NUM_THREAD*(regOrder_vector[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[3]           ;
                 end
          3'd3: begin   out_valid_3     [regOrder_vector[7:6]]                                               =  1'b1                          ;
                        out_regOrder_3  [2*(regOrder_vector[7:6]+1)-1-:2]                                    =  regOrder_vector[7:6] ;
                        out_data_3      [`XLEN*`NUM_THREAD*(regOrder_vector[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[3]           ;
                        out_v0_3        [`XLEN*`NUM_THREAD*(regOrder_vector[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[3]           ;
                 end
          3'd4: begin   out_valid_4     [regOrder_vector[7:6]]                                               =  1'b1                          ;
                        out_regOrder_4  [2*(regOrder_vector[7:6]+1)-1-:2]                                    =  regOrder_vector[7:6] ;
                        out_data_4      [`XLEN*`NUM_THREAD*(regOrder_vector[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[3]           ;
                        out_v0_4        [`XLEN*`NUM_THREAD*(regOrder_vector[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[3]           ;
                 end
          3'd5: begin   out_valid_5     [regOrder_vector[7:6]]                                               =  1'b1                          ;
                        out_regOrder_5  [2*(regOrder_vector[7:6]+1)-1-:2]                                    =  regOrder_vector[7:6] ;
                        out_data_5      [`XLEN*`NUM_THREAD*(regOrder_vector[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[3]           ;
                        out_v0_5        [`XLEN*`NUM_THREAD*(regOrder_vector[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[3]           ;
                 end
          3'd6: begin   out_valid_6     [regOrder_vector[7:6]]                                               =  1'b1                          ;
                        out_regOrder_6  [2*(regOrder_vector[7:6]+1)-1-:2]                                    =  regOrder_vector[7:6] ;
                        out_data_6      [`XLEN*`NUM_THREAD*(regOrder_vector[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[3]           ;
                        out_v0_6        [`XLEN*`NUM_THREAD*(regOrder_vector[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[3]           ;
                 end
          3'd7: begin   out_valid_7     [regOrder_vector[7:6]]                                               =  1'b1                          ;
                        out_regOrder_7  [2*(regOrder_vector[7:6]+1)-1-:2]                                    =  regOrder_vector[7:6] ;
                        out_data_7      [`XLEN*`NUM_THREAD*(regOrder_vector[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_rs_i[3]           ;
                        out_v0_7        [`XLEN*`NUM_THREAD*(regOrder_vector[7:6]+1)-1-:`XLEN*`NUM_THREAD]    =  data_vector_v0_i[3]           ;
                 end
          default: ;
        endcase
      end
    end else begin
      out_valid_0         =  'b0;
      out_regOrder_0      =  'b0;
      out_data_0          =  'b0;
      out_v0_0            =  'b0;
      out_valid_1         =  'b0;
      out_regOrder_1      =  'b0;
      out_data_1          =  'b0;
      out_v0_1            =  'b0;
      out_valid_2         =  'b0;
      out_regOrder_2      =  'b0;
      out_data_2          =  'b0;
      out_v0_2            =  'b0;
      out_valid_3         =  'b0;
      out_regOrder_3      =  'b0;
      out_data_3          =  'b0;
      out_v0_3            =  'b0;
      out_valid_4         =  'b0;
      out_regOrder_4      =  'b0;
      out_data_4          =  'b0;
      out_v0_4            =  'b0;
      out_valid_5         =  'b0;
      out_regOrder_5      =  'b0;
      out_data_5          =  'b0;
      out_v0_5            =  'b0;
      out_valid_6         =  'b0;
      out_regOrder_6      =  'b0;
      out_data_6          =  'b0;
      out_v0_6            =  'b0;
      out_valid_7         =  'b0;
      out_regOrder_7      =  'b0;
      out_data_7          =  'b0;
      out_v0_7            =  'b0;
    end
  end

  assign  out_valid_o     [0]   = out_valid_0     ;       
  assign  out_regOrder_o  [0]   = out_regOrder_0  ;       
  assign  out_data_o      [0]   = out_data_0      ;       
  assign  out_v0_o        [0]   = out_v0_0        ;       
  assign  out_valid_o     [1]   = out_valid_1     ;
  assign  out_regOrder_o  [1]   = out_regOrder_1  ;
  assign  out_data_o      [1]   = out_data_1      ;
  assign  out_v0_o        [1]   = out_v0_1        ;
  assign  out_valid_o     [2]   = out_valid_2     ;
  assign  out_regOrder_o  [2]   = out_regOrder_2  ;
  assign  out_data_o      [2]   = out_data_2      ;
  assign  out_v0_o        [2]   = out_v0_2        ;
  assign  out_valid_o     [3]   = out_valid_3     ;
  assign  out_regOrder_o  [3]   = out_regOrder_3  ;
  assign  out_data_o      [3]   = out_data_3      ;
  assign  out_v0_o        [3]   = out_v0_3        ;
  assign  out_valid_o     [4]   = out_valid_4     ;
  assign  out_regOrder_o  [4]   = out_regOrder_4  ;
  assign  out_data_o      [4]   = out_data_4      ;
  assign  out_v0_o        [4]   = out_v0_4        ;
  assign  out_valid_o     [5]   = out_valid_5     ;
  assign  out_regOrder_o  [5]   = out_regOrder_5  ;
  assign  out_data_o      [5]   = out_data_5      ;
  assign  out_v0_o        [5]   = out_v0_5        ;
  assign  out_valid_o     [6]   = out_valid_6     ;
  assign  out_regOrder_o  [6]   = out_regOrder_6  ;
  assign  out_data_o      [6]   = out_data_6      ;
  assign  out_v0_o        [6]   = out_v0_6        ;
  assign  out_valid_o     [7]   = out_valid_7     ;
  assign  out_regOrder_o  [7]   = out_regOrder_7  ;
  assign  out_data_o      [7]   = out_data_7      ;
  assign  out_v0_o        [7]   = out_v0_7        ;

endmodule
