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
// Author: Wu, Chenjie
// Description:

// PORT description
// AB   -> read address
// REB  -> mem read signal
// AA   -> write address
// WEB  -> mem write signal
// BWEB -> bit write enable signal

`define DEBUG

module dualportSRAM #(
  parameter BITWIDTH   = 32,
  parameter DEPTH      = 8 
)
(
  input                 CLK ,
  input                 RSTN,
  input  [BITWIDTH-1:0] D   ,
  output [BITWIDTH-1:0] Q   ,
  input                 REB ,
  input                 WEB ,
  input  [BITWIDTH-1:0] BWEB,
  input  [DEPTH-1:0]    AA  ,
  input  [DEPTH-1:0]    AB   //In the same cycle, AB can't be same as AA
);

  reg  [BITWIDTH-1:0] mem_core [0:2**DEPTH-1];
  
  always@(posedge CLK or negedge RSTN) begin: WRITE_PROC
    integer ii,jj;
    if(!RSTN) begin
      for(jj = 32'sd0; jj < 2**DEPTH; jj = jj + 32'sd1) begin
        mem_core[jj] <= 'd0;
      end
    end
    else if(WEB) begin
      for(ii = 32'sd0; ii < BITWIDTH; ii = ii + 32'sd1) begin
        if(BWEB[ii]) begin
          mem_core[AA][ii] <= D[ii];
        end
      end
    end
  end

  reg [BITWIDTH-1:0] QN;

  always@(posedge CLK or negedge RSTN) begin
    if(!RSTN) begin
      QN <= 'd0;
    end
    else if(REB) begin
      QN <= mem_core[AB];
    end
  end

  assign Q = QN;

//`ifdef DEBUG
//  always@(posedge CLK or negedge RSTN) begin
//    //assert((WEB&&REB&&(AA==AB)),"In the same cycle, AB can't be same as AA");
//    if(WEB&&REB&&(AA==AB)) begin
//      $error("In the same cycle, AB can't be same as AA");
//    end
//  end
//`endif

endmodule
