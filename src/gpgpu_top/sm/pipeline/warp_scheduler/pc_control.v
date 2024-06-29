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
// Author: Zhang, Qi
// Description:pc control module
`timescale 1ns/1ns

`include "define.v"

module pc_control (
  input                       clk        ,
  input                       rst_n      ,
  input      [31:0]           new_pc_i   , 
  input      [1:0]            pc_src_i   , //1(branch);2(pipe);3(pc replay)
  input      [`NUM_FETCH-1:0] mask_i     ,
  output reg [31:0]           pc_next_o  , //fetch pc
  output reg [`NUM_FETCH-1:0] mask_o       //if both instructions are valid mask_o=11
  );
  
  wire [31:0] pc_tmp;
  wire [`NUM_FETCH-1:0] mask_tmp;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      pc_next_o <= 'h0;
      mask_o <= 'h0;
    end
    else begin
      case(pc_src_i)
        2'h1    : begin
                    pc_next_o <= pc_tmp;
                    mask_o <= mask_tmp;
                  end
        2'h2    : begin 
                    pc_next_o <= pc_next_o + (`NUM_FETCH << 2); //e.g. num_fetch=2, pc_next_o=pc+8
                    mask_o <= 2'h3;
                  end
        2'h3    : begin 
                    pc_next_o <= new_pc_i;
                    mask_o <= mask_i; 
                  end
        default : begin
                    pc_next_o <= pc_next_o;
                    mask_o <= mask_o;
                  end
      endcase
    end
  end

  pc_align align(            //used to align jump addresses
    .pc_i        (new_pc_i),
    .pc_aligned_o(pc_tmp  ),
    .pc_mask_o   (mask_tmp)
    );

endmodule

