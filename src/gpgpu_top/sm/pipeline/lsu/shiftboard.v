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
// Author: Tan, Zhiyuan
// Description: For fence

`timescale 1ns/1ns

module shiftboard #(parameter DEPTH = 4)(
  input  clk   ,
  input  rst_n ,
  input  left  ,
  input  right ,
  output full  ,
  output empty
);

  reg [DEPTH-1:0] taps;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      taps <= 'd0;
    end
    else begin
      if(left && right) begin //req and rsp in a same cycle, don't move
        taps <= taps;
      end
      else if(left) begin //req, shift left
        taps <= {taps[DEPTH-2:0],1'b1};
      end
      else if(right) begin //rsp, shift right
        taps <= {1'b0,taps[DEPTH-1:1]};
      end
      else begin //no operation, don't move
        taps <= taps;
      end
    end
  end

  assign full  = taps[DEPTH-1];
  assign empty = !taps[0]     ;

endmodule

