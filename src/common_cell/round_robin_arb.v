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
// Description:Round Robin Arbiter

`timescale 1ns/1ps

`include "define.v"

module round_robin_arb #(
  parameter ARB_WIDTH = 4
  ) 
  (
  input                  clk  ,
  input                  rst_n,
  input  [ARB_WIDTH-1:0] req  ,
  output [ARB_WIDTH-1:0] grant
  );

  
  reg [ARB_WIDTH-1:0] pre_req;
  wire [2*ARB_WIDTH-1:0] grant_ext;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin      
      pre_req <= {{(ARB_WIDTH-1){1'b0}},1'b1};
    end else if(|req) begin
      pre_req <= {grant[ARB_WIDTH-2:0],grant[ARB_WIDTH-1]};
    end else begin      
      pre_req <= pre_req;
    end
  end

  assign grant_ext = {req,req} & ~({req,req} - pre_req);
  assign grant = grant_ext[ARB_WIDTH-1:0] | grant_ext[2*ARB_WIDTH-1:ARB_WIDTH];
  

  /*wire  [ARB_WIDTH-1:0] req_masked;
  wire  [ARB_WIDTH-1:0] mask_higher_pri_reqs;
  wire  [ARB_WIDTH-1:0] grant_masked;
  wire  [ARB_WIDTH-1:0] unmask_higher_pri_reqs;
  wire  [ARB_WIDTH-1:0] grant_unmasked;
  wire  no_req_masked;
  reg   [ARB_WIDTH-1:0] pointer_reg;

  assign  req_masked = req & pointer_reg;
  assign  mask_higher_pri_reqs[ARB_WIDTH-1:1] = mask_higher_pri_reqs[ARB_WIDTH-2:0] | req_masked[ARB_WIDTH-2:0];
  assign  mask_higher_pri_reqs[0] = 1'b0;
  assign  grant_masked = req_masked & ~mask_higher_pri_reqs;

  assign  unmask_higher_pri_reqs[ARB_WIDTH-1:1] = unmask_higher_pri_reqs[ARB_WIDTH-2:0] | req[ARB_WIDTH-2:0];
  assign  unmask_higher_pri_reqs[0] = 1'b0;
  assign  grant_unmasked = req & ~unmask_higher_pri_reqs;

  assign  no_req_masked = ~(|req_masked);
  assign  grant = ({ARB_WIDTH{no_req_masked}} & grant_unmasked) | grant_masked;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin      
      pointer_reg <= {ARB_WIDTH{1'b1}};
    end else if(|req_masked) begin
      pointer_reg <= mask_higher_pri_reqs;
    end else if(|req) begin
      pointer_reg <= unmask_higher_pri_reqs;
    end else begin      
      pointer_reg <= pointer_reg;
    end
  end*/


endmodule
