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
// Description:32bit*32bit multiplier
`timescale 1ns/1ns
module mult_32 #(parameter WORDLEN=32) (
    input               clk,
    input               rst_n,
	input [WORDLEN:0] Asign,
	input [WORDLEN:0] Bsign,
	output [2*WORDLEN-1:0] Result
);
    wire  [WORDLEN-1:0] A;
    wire  [WORDLEN-1:0] B;
    wire  [2*WORDLEN-1:0] Result_abs;
	wire  [WORDLEN:0] B_res_1;
	wire  [WORDLEN:0] B_res_2;
	wire  [WORDLEN:0] B_res_3;
	wire  [WORDLEN:0] B_res_4;
	wire  [WORDLEN:0] B_res_5;
	wire  [WORDLEN:0] B_res_6;
	wire  [WORDLEN:0] B_res_7;
	wire  [WORDLEN:0] B_res_8;
	wire  [WORDLEN:0] B_res_9;
	wire  [WORDLEN:0] B_res_10;
	wire  [WORDLEN:0] B_res_11;
	wire  [WORDLEN:0] B_res_12;
	wire  [WORDLEN:0] B_res_13;
	wire  [WORDLEN:0] B_res_14;
	wire  [WORDLEN:0] B_res_15;
	wire  [WORDLEN:0] B_res_16;
	wire  [WORDLEN:0] B_res_17;
  
    //reg  [WORDLEN:0] Asign_reg  ;
    //reg  [WORDLEN:0] Bsign_reg  ;
    //reg  [WORDLEN:0] B_res_1_reg;
	//reg  [WORDLEN:0] B_res_2_reg;
	//reg  [WORDLEN:0] B_res_3_reg;
	//reg  [WORDLEN:0] B_res_4_reg;
	//reg  [WORDLEN:0] B_res_5_reg;
	//reg  [WORDLEN:0] B_res_6_reg;
	//reg  [WORDLEN:0] B_res_7_reg;
	//reg  [WORDLEN:0] B_res_8_reg;
	//reg  [WORDLEN:0] B_res_9_reg;
	//reg  [WORDLEN:0] B_res_10_reg;
	//reg  [WORDLEN:0] B_res_11_reg;
	//reg  [WORDLEN:0] B_res_12_reg;
	//reg  [WORDLEN:0] B_res_13_reg;
	//reg  [WORDLEN:0] B_res_14_reg;
	//reg  [WORDLEN:0] B_res_15_reg;
	//reg  [WORDLEN:0] B_res_16_reg;
	//reg  [WORDLEN:0] B_res_17_reg;

	wire  B_carry_1;
	wire  B_carry_2;
	wire  B_carry_3;
	wire  B_carry_4;
	wire  B_carry_5;
	wire  B_carry_6;
	wire  B_carry_7;
	wire  B_carry_8;
	wire  B_carry_9;
	wire  B_carry_10;
	wire  B_carry_11;
	wire  B_carry_12;
	wire  B_carry_13;
	wire  B_carry_14;
	wire  B_carry_15;
	wire  B_carry_16;
	wire  B_carry_17;

    //reg  B_carry_1_reg;
	//reg  B_carry_2_reg;
	//reg  B_carry_3_reg;
	//reg  B_carry_4_reg;
	//reg  B_carry_5_reg;
	//reg  B_carry_6_reg;
	//reg  B_carry_7_reg;
	//reg  B_carry_8_reg;
	//reg  B_carry_9_reg;
	//reg  B_carry_10_reg;
	//reg  B_carry_11_reg;
	//reg  B_carry_12_reg;
	//reg  B_carry_13_reg;
	//reg  B_carry_14_reg;
	//reg  B_carry_15_reg;
	//reg  B_carry_16_reg;
	//reg  B_carry_17_reg;

    assign  A = Asign[WORDLEN] ? ~(Asign[WORDLEN-1:0])+1 : Asign[WORDLEN-1:0];
    assign  B = Bsign[WORDLEN] ? ~(Bsign[WORDLEN-1:0])+1 : Bsign[WORDLEN-1:0];

	// 32 bit numbers require 16+1 Booths
	Booth B1({A[1:0], 1'b0}, B, B_res_1, B_carry_1);
	Booth B2(A[3:1], B, B_res_2, B_carry_2);
	Booth B3(A[5:3], B, B_res_3, B_carry_3);
	Booth B4(A[7:5], B, B_res_4, B_carry_4);
	Booth B5(A[9:7], B, B_res_5, B_carry_5);
	Booth B6(A[11:9], B, B_res_6, B_carry_6);
	Booth B7(A[13:11], B, B_res_7, B_carry_7);
	Booth B8(A[15:13], B, B_res_8, B_carry_8);
	Booth B9(A[17:15], B, B_res_9, B_carry_9);
	Booth B10(A[19:17], B, B_res_10, B_carry_10);
	Booth B11(A[21:19], B, B_res_11, B_carry_11);
	Booth B12(A[23:21], B, B_res_12, B_carry_12);
	Booth B13(A[25:23], B, B_res_13, B_carry_13);
	Booth B14(A[27:25], B, B_res_14, B_carry_14);
	Booth B15(A[29:27], B, B_res_15, B_carry_15);
	Booth B16(A[31:29], B, B_res_16, B_carry_16);
	Booth B17({2'b0, A[31]}, B, B_res_17, B_carry_17);

  /*always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
     B_res_1_reg <='d0; 
     B_res_2_reg <='d0;
     B_res_3_reg <='d0;
     B_res_4_reg <='d0;
     B_res_5_reg <='d0;
     B_res_6_reg <='d0;
     B_res_7_reg <='d0;
     B_res_8_reg <='d0;
     B_res_9_reg <='d0;
     B_res_10_reg<='d0; 
     B_res_11_reg<='d0; 
     B_res_12_reg<='d0; 
     B_res_13_reg<='d0; 
     B_res_14_reg<='d0; 
     B_res_15_reg<='d0; 
     B_res_16_reg<='d0; 
     B_res_17_reg<='d0;
     B_carry_1_reg <='d0;
     B_carry_2_reg <='d0;
     B_carry_3_reg <='d0;
     B_carry_4_reg <='d0;
     B_carry_5_reg <='d0;
     B_carry_6_reg <='d0;
     B_carry_7_reg <='d0;
     B_carry_8_reg <='d0;
     B_carry_9_reg <='d0;
     B_carry_10_reg<='d0; 
     B_carry_11_reg<='d0; 
     B_carry_12_reg<='d0; 
     B_carry_13_reg<='d0; 
     B_carry_14_reg<='d0; 
     B_carry_15_reg<='d0; 
     B_carry_16_reg<='d0; 
     B_carry_17_reg<='d0;
   end
   else begin
     B_res_1_reg <= B_res_1 ;
     B_res_2_reg <= B_res_2 ;
     B_res_3_reg <= B_res_3 ;
     B_res_4_reg <= B_res_4 ;
     B_res_5_reg <= B_res_5 ;
     B_res_6_reg <= B_res_6 ;
     B_res_7_reg <= B_res_7 ;
     B_res_8_reg <= B_res_8 ;
     B_res_9_reg <= B_res_9 ;
     B_res_10_reg<= B_res_10;
     B_res_11_reg<= B_res_11;
     B_res_12_reg<= B_res_12;
     B_res_13_reg<= B_res_13;
     B_res_14_reg<= B_res_14;
     B_res_15_reg<= B_res_15;
     B_res_16_reg<= B_res_16;
     B_res_17_reg<= B_res_17; 
     B_carry_1_reg <=B_carry_1 ; 
     B_carry_2_reg <=B_carry_2 ;
     B_carry_3_reg <=B_carry_3 ;
     B_carry_4_reg <=B_carry_4 ;
     B_carry_5_reg <=B_carry_5 ;
     B_carry_6_reg <=B_carry_6 ;
     B_carry_7_reg <=B_carry_7 ;
     B_carry_8_reg <=B_carry_8 ;
     B_carry_9_reg <=B_carry_9 ;
     B_carry_10_reg<=B_carry_10; 
     B_carry_11_reg<=B_carry_11; 
     B_carry_12_reg<=B_carry_12; 
     B_carry_13_reg<=B_carry_13; 
     B_carry_14_reg<=B_carry_14; 
     B_carry_15_reg<=B_carry_15; 
     B_carry_16_reg<=B_carry_16; 
     B_carry_17_reg<=B_carry_17;
   end
 end*/

 /*always@(posedge clk or negedge rst_n) begin
  if(!rst_n) begin
    Asign_reg <= 'd0;
    Bsign_reg <= 'd0;
  end
  else begin
    Asign_reg <= Asign;
    Bsign_reg <= Bsign;
  end
 end*/

	/*Wallace_adder_18 #(64) wallace_adder (
		// with modified sign extension
        .clk  (clk)  ,
        .rst_n(rst_n),
		.in_1({{31{B_carry_1_reg}}, B_res_1_reg}),
		.in_2({{29{B_carry_2_reg}}, B_res_2_reg, 1'b0, B_carry_1_reg}),
		.in_3({{27{B_carry_3_reg}}, B_res_3_reg, 1'b0, B_carry_2_reg, 2'b0}),
		.in_4({{25{B_carry_4_reg}}, B_res_4_reg, 1'b0, B_carry_3_reg, 4'b0}),
		.in_5({{23{B_carry_5_reg}}, B_res_5_reg, 1'b0, B_carry_4_reg, 6'b0}),
		.in_6({{21{B_carry_6_reg}}, B_res_6_reg, 1'b0, B_carry_5_reg, 8'b0}),
		.in_7({{19{B_carry_7_reg}}, B_res_7_reg, 1'b0, B_carry_6_reg, 10'b0}),
		.in_8({{17{B_carry_8_reg}}, B_res_8_reg, 1'b0, B_carry_7_reg, 12'b0}),
		.in_9({{15{B_carry_9_reg}}, B_res_9_reg, 1'b0, B_carry_8_reg, 14'b0}),
		.in_10({{13{B_carry_10_reg}}, B_res_10_reg, 1'b0, B_carry_9_reg, 16'b0}),
		.in_11({{11{B_carry_11_reg}}, B_res_11_reg, 1'b0, B_carry_10_reg, 18'b0}),
		.in_12({{9{B_carry_12_reg}}, B_res_12_reg, 1'b0, B_carry_11_reg, 20'b0}),
		.in_13({{7{B_carry_13_reg}}, B_res_13_reg, 1'b0, B_carry_12_reg, 22'b0}),
		.in_14({{5{B_carry_14_reg}}, B_res_14_reg, 1'b0, B_carry_13_reg, 24'b0}),
		.in_15({{3{B_carry_15_reg}}, B_res_15_reg, 1'b0, B_carry_14_reg, 26'b0}),
		.in_16({B_carry_16_reg, B_res_16_reg, 1'b0, B_carry_15_reg, 28'b0}),
		.in_17({B_res_17_reg[31:0], 1'b0, B_carry_16_reg, 30'b0}),
		.in_18({31'b0, B_carry_17_reg, 32'b0}),
		.out(Result_abs)
	);*/

    Wallace_adder_18 #(64) wallace_adder (
		// with modified sign extension
        .clk (clk),
        .rst_n(rst_n),
		.in_1({{31{B_carry_1}}, B_res_1}),
		.in_2({{29{B_carry_2}}, B_res_2, 1'b0, B_carry_1}),
		.in_3({{27{B_carry_3}}, B_res_3, 1'b0, B_carry_2, 2'b0}),
		.in_4({{25{B_carry_4}}, B_res_4, 1'b0, B_carry_3, 4'b0}),
		.in_5({{23{B_carry_5}}, B_res_5, 1'b0, B_carry_4, 6'b0}),
		.in_6({{21{B_carry_6}}, B_res_6, 1'b0, B_carry_5, 8'b0}),
		.in_7({{19{B_carry_7}}, B_res_7, 1'b0, B_carry_6, 10'b0}),
		.in_8({{17{B_carry_8}}, B_res_8, 1'b0, B_carry_7, 12'b0}),
		.in_9({{15{B_carry_9}}, B_res_9, 1'b0, B_carry_8, 14'b0}),
		.in_10({{13{B_carry_10}}, B_res_10, 1'b0, B_carry_9, 16'b0}),
		.in_11({{11{B_carry_11}}, B_res_11, 1'b0, B_carry_10, 18'b0}),
		.in_12({{9{B_carry_12}}, B_res_12, 1'b0, B_carry_11, 20'b0}),
		.in_13({{7{B_carry_13}}, B_res_13, 1'b0, B_carry_12, 22'b0}),
		.in_14({{5{B_carry_14}}, B_res_14, 1'b0, B_carry_13, 24'b0}),
		.in_15({{3{B_carry_15}}, B_res_15, 1'b0, B_carry_14, 26'b0}),
		.in_16({B_carry_16, B_res_16, 1'b0, B_carry_15, 28'b0}),
		.in_17({B_res_17[31:0], 1'b0, B_carry_16, 30'b0}),
		.in_18({31'b0, B_carry_17, 32'b0}),
		.out(Result_abs)
	);

  assign Result = (/*Asign_reg*/Asign[WORDLEN] ^ /*Bsign_reg*/Bsign[WORDLEN]) ? ~Result_abs+1 : Result_abs;

	`ifdef FORMAL
		assert property(A * B == Result);
	`endif
endmodule

