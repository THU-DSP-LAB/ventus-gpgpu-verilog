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
// Description:wallace tree
`timescale 1ns / 1ns

// 18 Input Wallace adder
module Wallace_adder_18 #(parameter WORDLEN=4) (
    input               clk  ,
    input               rst_n,
	input [WORDLEN-1:0] in_1,
	input [WORDLEN-1:0] in_2,
	input [WORDLEN-1:0] in_3,
	input [WORDLEN-1:0] in_4,
	input [WORDLEN-1:0] in_5,
	input [WORDLEN-1:0] in_6,
	input [WORDLEN-1:0] in_7,
	input [WORDLEN-1:0] in_8,
	input [WORDLEN-1:0] in_9,
	input [WORDLEN-1:0] in_10,
	input [WORDLEN-1:0] in_11,
	input [WORDLEN-1:0] in_12,
	input [WORDLEN-1:0] in_13,
	input [WORDLEN-1:0] in_14,
	input [WORDLEN-1:0] in_15,
	input [WORDLEN-1:0] in_16,
	input [WORDLEN-1:0] in_17,
	input [WORDLEN-1:0] in_18,
	output [WORDLEN-1:0] out
);
	wire  [WORDLEN-1:0] s_row_11;
	wire  [WORDLEN-1:0] s_row_12;
	wire  [WORDLEN-1:0] s_row_13;
	wire  [WORDLEN-1:0] s_row_14;
	wire  [WORDLEN-1:0] s_row_15;
	wire  [WORDLEN-1:0] s_row_16;

	wire  [WORDLEN-1:0] s_row_21;
	wire  [WORDLEN-1:0] s_row_22;
	wire  [WORDLEN-1:0] s_row_23;
	wire  [WORDLEN-1:0] s_row_24;

	wire  [WORDLEN-1:0] s_row_31;
	wire  [WORDLEN-1:0] s_row_32;

	wire  [WORDLEN-1:0] s_row_41;
	wire  [WORDLEN-1:0] s_row_42;

	wire  [WORDLEN-1:0] s_row_5;
	wire  [WORDLEN-1:0] s_row_6;


	wire  [WORDLEN-1:0] c_row_11;
	wire  [WORDLEN-1:0] c_row_12;
	wire  [WORDLEN-1:0] c_row_13;
	wire  [WORDLEN-1:0] c_row_14;
	wire  [WORDLEN-1:0] c_row_15;
	wire  [WORDLEN-1:0] c_row_16;

	wire  [WORDLEN-1:0] c_row_21;
	wire  [WORDLEN-1:0] c_row_22;
	wire  [WORDLEN-1:0] c_row_23;
	wire  [WORDLEN-1:0] c_row_24;

	wire  [WORDLEN-1:0] c_row_31;
	wire  [WORDLEN-1:0] c_row_32;

	wire  [WORDLEN-1:0] c_row_41;
	wire  [WORDLEN-1:0] c_row_42;

	wire  [WORDLEN-1:0] c_row_5;
	wire  [WORDLEN-1:0] c_row_6;

    reg   [WORDLEN-1:0] s_row_24_reg;
    reg   [WORDLEN-1:0] c_row_24_reg;
    reg   [WORDLEN-1:0] s_row_31_reg;
	reg   [WORDLEN-1:0] s_row_32_reg;
    reg   [WORDLEN-1:0] c_row_31_reg;
	reg   [WORDLEN-1:0] c_row_32_reg;

    always@(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        s_row_24_reg <= 'd0;
        c_row_24_reg <= 'd0;
        s_row_31_reg <= 'd0;
        s_row_32_reg <= 'd0;
        c_row_31_reg <= 'd0;
        c_row_32_reg <= 'd0;
      end
      else begin
        s_row_24_reg <= s_row_24;
        c_row_24_reg <= c_row_24;
        s_row_31_reg <= s_row_31;
        s_row_32_reg <= s_row_32;
        c_row_31_reg <= c_row_31;
        c_row_32_reg <= c_row_32;
      end
    end

	full_adder FA_Row_11 [WORDLEN-1:0] (in_1, in_2, in_3, s_row_11, c_row_11);
	full_adder FA_Row_12 [WORDLEN-1:0] (in_4, in_5, in_6, s_row_12, c_row_12);
	full_adder FA_Row_13 [WORDLEN-1:0] (in_7, in_8, in_9, s_row_13, c_row_13);
	full_adder FA_Row_14 [WORDLEN-1:0] (in_10, in_11, in_12, s_row_14, c_row_14);
	full_adder FA_Row_15 [WORDLEN-1:0] (in_13, in_14, in_15, s_row_15, c_row_15);
	full_adder FA_Row_16 [WORDLEN-1:0] (in_16, in_17, in_18, s_row_16, c_row_16);


	full_adder FA_Row_21 [WORDLEN-1:0] (s_row_11, {c_row_11[WORDLEN-2:0], 1'b0}, s_row_12, s_row_21, c_row_21);
	full_adder FA_Row_22 [WORDLEN-1:0] ({c_row_12[WORDLEN-2:0], 1'b0}, s_row_13, {c_row_13[WORDLEN-2:0], 1'b0}, s_row_22, c_row_22);
	full_adder FA_Row_23 [WORDLEN-1:0] (s_row_14, {c_row_14[WORDLEN-2:0], 1'b0}, s_row_15, s_row_23, c_row_23);
	full_adder FA_Row_24 [WORDLEN-1:0] ({c_row_15[WORDLEN-2:0], 1'b0}, s_row_16, {c_row_16[WORDLEN-2:0], 1'b0}, s_row_24, c_row_24);

	full_adder FA_Row_31 [WORDLEN-1:0] (s_row_21, {c_row_21[WORDLEN-2:0], 1'b0}, s_row_22, s_row_31, c_row_31);
	full_adder FA_Row_32 [WORDLEN-1:0] ({c_row_22[WORDLEN-2:0], 1'b0}, s_row_23, {c_row_23[WORDLEN-2:0], 1'b0}, s_row_32, c_row_32);

	full_adder FA_Row_41 [WORDLEN-1:0] (s_row_31_reg, {c_row_31_reg[WORDLEN-2:0], 1'b0}, s_row_32_reg, s_row_41, c_row_41);
	full_adder FA_Row_42 [WORDLEN-1:0] ({c_row_32_reg[WORDLEN-2:0], 1'b0}, s_row_24_reg, {c_row_24_reg[WORDLEN-2:0], 1'b0}, s_row_42, c_row_42);

	full_adder FA_Row_5 [WORDLEN-1:0] (s_row_41, {c_row_41[WORDLEN-2:0], 1'b0}, s_row_42, s_row_5, c_row_5);

	full_adder FA_Row_6 [WORDLEN-1:0] (s_row_5, {c_row_5[WORDLEN-2:0], 1'b0}, {c_row_42[WORDLEN-2:0], 1'b0}, s_row_6, c_row_6);

	// CPA
	wire [WORDLEN-1:0] cpa_carry;
	/*full_adder CPA [WORDLEN-1:0] (s_row_6, {c_row_6[WORDLEN-2:0], 1'b0}, {cpa_carry[WORDLEN-2:0], 1'b0}, out, cpa_carry);*/
    assign out = s_row_6 + {c_row_6[WORDLEN-2:0], 1'b0};

	`ifdef FORMAL 
		assert property((in_1 + in_2 + in_3 + in_4 + in_5 + in_6 + in_7 + in_8 + in_9 + in_10 + in_11 + in_12 + in_13 + in_14 + in_15 + in_16 + in_17 + in_18) == out);
	`endif


endmodule
