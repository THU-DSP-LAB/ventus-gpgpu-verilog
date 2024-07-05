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
// Description:Synchronous fifo, use SyncReadMem

`timescale 1ns/1ns

module stream_fifo_with_incount_useSRAM #(
  parameter DATA_WIDTH = 32,
  parameter FIFO_DEPTH = 4  // >= 2 
  )
  (
  input                   clk      ,
  input                   rst_n    ,

  output                  w_ready_o,
  input                   w_valid_i,
  input  [DATA_WIDTH-1:0] w_data_i ,
  
  output                  r_valid_o,
  input                   r_ready_i,
  output [DATA_WIDTH-1:0] r_data_o ,
  output                  w_count_o
  );

  parameter ADDR_WIDTH = $clog2(FIFO_DEPTH);

  reg push_reg; 
  reg [ADDR_WIDTH-1:0] w_addr,r_addr;
  reg [ADDR_WIDTH-1:0] fifo_cnt_in ;
  reg [ADDR_WIDTH-1:0] fifo_cnt_out;

  wire push,pop;
  wire read_en ;
  wire [ADDR_WIDTH-1:0] r_ptr_next;
  wire [ADDR_WIDTH-1:0] r_ptr     ;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      push_reg <= 'd0;
    end
    else begin
      push_reg <= push;
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      fifo_cnt_in <= 'd0;
    end
    else if(push ^ pop) begin
      if(push) begin
        fifo_cnt_in <= fifo_cnt_in + 1'b1;
      end
      else begin
        fifo_cnt_in <= fifo_cnt_in - 1'b1;
      end
    end
    else begin
      fifo_cnt_in <= fifo_cnt_in;
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      fifo_cnt_out <= 'd0;
    end
    else if(push_reg ^ pop) begin
      if(push_reg) begin
        fifo_cnt_out <= fifo_cnt_in + 1'b1;
      end
      else begin
        fifo_cnt_out <= fifo_cnt_in - 1'b1;
      end
    end
    else begin
        fifo_cnt_out <= fifo_cnt_out;
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      w_addr <= 'd0;
    end
    else if(push) begin
      w_addr <= w_addr + 1;
    end
    else begin
      w_addr <= w_addr;
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      r_addr <= 'd0;
    end
    else if(pop) begin
      r_addr <= r_ptr;
    end
    else begin
      r_addr <= r_addr;
    end
  end
  
  assign push = w_valid_i && w_ready_o;
  assign pop  = r_valid_o && r_ready_i;

  assign r_valid_o = fifo_cnt_out > {DATA_WIDTH{1'b0}}      ;
  assign w_ready_o = (fifo_cnt_in < FIFO_DEPTH);
  //assign w_ready_o = (fifo_cnt_in < FIFO_DEPTH) || r_ready_i;


  assign read_en = !(push && w_addr==r_ptr);

  assign r_ptr_next = (r_addr==(FIFO_DEPTH-1)) ? 'd0 : (r_addr+1);
  assign r_ptr      = pop ? r_ptr_next : r_addr;

  wire [DATA_WIDTH-1:0] read_data;
  
  dualportSRAM #(
    .BITWIDTH (DATA_WIDTH),
    .DEPTH    (ADDR_WIDTH)
  )
  dual_port_ram (
    .CLK  (clk               ),
    .RSTN (rst_n             ),
    .D    (w_data_i          ), 
    .Q    (read_data         ), 
    .REB  (read_en           ), 
    .WEB  (push              ), 
    .BWEB ({DATA_WIDTH{1'b1}}), 
    .AA   (w_addr            ), 
    .AB   (r_ptr             ) 
  );

  reg read_en_reg;
  reg [DATA_WIDTH-1:0] w_data_reg;
  
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      read_en_reg <= 'd0;
      w_data_reg  <= 'd0;
    end
    else begin
      read_en_reg <= read_en;
      w_data_reg  <= w_data_i;
    end
  end  
  
  assign r_data_o  = read_en_reg ? read_data : w_data_reg;
  assign w_count_o = fifo_cnt_in > 0                     ;

endmodule
