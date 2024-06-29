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
// Description:full adder
`timescale 1ns / 1ns

module full_adder(
	input in_a, 
	input in_b, 
	input in_carry, 
	output out, 
	output out_carry
);

	reg s_prime;
	reg carry_1, carry_2;

	always@(in_a, in_b, in_carry) begin
		s_prime = in_a ^ in_b;
		carry_2 = in_a & in_b;
		carry_1 = in_carry & s_prime;
	end

	assign out_carry = carry_1 | carry_2;
	assign out = in_carry ^ s_prime;

/*	`ifdef FORMAL
		assert property ({1'b0, in_a} + {1'b0, in_b} + {1'b0, in_carry} == {out_carry, out});
	`endif
	*/

endmodule
