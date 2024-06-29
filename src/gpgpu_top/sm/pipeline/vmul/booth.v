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
// Description:booth
`timescale 1ns/1ns
module Booth #(parameter WORDLEN=32) (
	/* from LSB to MSB */
	input [2:0] S,
	input [WORDLEN-1:0] A,
	output wire [WORDLEN:0] Result,
	output wire Sign
);

	reg valency_2;
	reg valency_1;

	assign Sign = S[2];
	assign Result = ({(WORDLEN+1){S[2]}} ^ (valency_2 ? {A, 1'b0} : (valency_1 ? {1'b0, A} : {9'b0})));

	always@(S, A) begin
		valency_1 = S[0] ^ S[1];
		valency_2 = ~((S[1] ~^ S[2]) | valency_1);
	end

endmodule
