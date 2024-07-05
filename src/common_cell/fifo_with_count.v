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
// Description:

`timescale 1ns/1ns

module fifo_with_count #(
  parameter DATA_WIDTH = 32,
  parameter FIFO_DEPTH = 4 ,//can't be zero
  parameter CNT_WIDTH  = 2
  )
  (
  input                   clk     ,
  input                   rst_n   ,
  input                   w_en_i  ,
  input                   r_en_i  ,
  input  [DATA_WIDTH-1:0] w_data_i,
  output [DATA_WIDTH-1:0] r_data_o,
  output                  full_o  ,
  output                  empty_o ,
  output [CNT_WIDTH-1:0]  count_o 
  );

  localparam ADDR_WIDTH = (FIFO_DEPTH == 1) ? 1 : $clog2(FIFO_DEPTH);
  
  //reg [DATA_WIDTH-1:0] dual_port_ram [0:FIFO_DEPTH-1];
  reg [FIFO_DEPTH*DATA_WIDTH-1:0] dual_port_ram;
  reg [ADDR_WIDTH:0]   w_ptr,r_ptr;
  wire [ADDR_WIDTH-1:0] w_addr,r_addr;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      w_ptr <= 'd0;
    end
    else if(w_en_i) begin
      w_ptr <= (FIFO_DEPTH == 1) ? (w_ptr + 2) : (w_ptr + 1);
    end
    else begin
      w_ptr <= w_ptr;
    end
  end
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      r_ptr <= 'd0;
    end
    else if(r_en_i) begin
      r_ptr <= (FIFO_DEPTH == 1) ? (r_ptr + 2) : (r_ptr + 1);
    end
    else begin
      r_ptr <= r_ptr;
    end
  end
  
  assign w_addr = w_ptr[ADDR_WIDTH-1:0];
  assign r_addr = r_ptr[ADDR_WIDTH-1:0];

  /*
  genvar i; 
  generate for(i=0;i<FIFO_DEPTH;i=i+1) begin:B1 
    always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        dual_port_ram[i] <= 'd0;
      end
      else if(w_en_i) begin
        dual_port_ram[w_addr] <= w_data_i;
      end
      else begin
        dual_port_ram[w_addr] <= dual_port_ram[w_addr];
      end
    end
  end  
  endgenerate
  */
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      dual_port_ram <= 'h0;
    end 
    else if(w_en_i && !full_o) begin
      dual_port_ram[(DATA_WIDTH*(w_addr+1)-1)-:DATA_WIDTH] <= w_data_i;
    end 
    else begin
      dual_port_ram <= dual_port_ram;
    end 
  end
  
  assign r_data_o = dual_port_ram[(DATA_WIDTH*(r_addr+1)-1)-:DATA_WIDTH];

  assign full_o = (r_ptr == {~w_ptr[ADDR_WIDTH],w_ptr[ADDR_WIDTH-1:0]});
  assign empty_o = (r_ptr == w_ptr);

  assign count_o = (FIFO_DEPTH == 1) ? (w_ptr[ADDR_WIDTH] ^ r_ptr[ADDR_WIDTH]) : (w_ptr - r_ptr);

endmodule

