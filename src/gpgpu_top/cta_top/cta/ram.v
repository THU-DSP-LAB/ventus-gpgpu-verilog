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
// Description:ram

module ram #(parameter WORD_SIZE = 32,
             parameter ADDR_SIZE = 3 ,
             parameter NUM_WORDS = 8 
)(
  input                       clk         ,
  input                       rst_n       ,

  input   [ADDR_SIZE-1:0]     rd_addr_i   ,
  input   [ADDR_SIZE-1:0]     wr_addr_i   ,
  input   [WORD_SIZE-1:0]     wr_word_i   ,
  input                       wr_en_i     ,
  input                       rd_en_i     ,

  output  [WORD_SIZE-1:0]     rd_word_o
  );

  /*reg [WORD_SIZE*NUM_WORDS-1:0] mem        ;
  reg [WORD_SIZE-1:0]           rd_word_reg;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      mem <= 'd0;
    end
    else if(wr_en_i) begin
      mem[(wr_addr_i+1)*WORD_SIZE-1-:WORD_SIZE] <= wr_word_i;
    end
    else begin
      mem <= mem;
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      rd_word_reg <= 'd0;
    end
    else if(rd_en_i) begin
      rd_word_reg <= mem[(rd_addr_i+1)*WORD_SIZE-1-:WORD_SIZE];
    end
    else begin
      rd_word_reg <= rd_word_reg;
    end
  end

  assign rd_word_o = rd_word_reg;*/

  dualportSRAM #(
    .BITWIDTH  (WORD_SIZE),
    .DEPTH     (ADDR_SIZE)
    )
  U_dualportSRAM (
    .CLK (clk              ),
    .RSTN(rst_n            ),
    .D   (wr_word_i        ),
    .Q   (rd_word_o        ),
    .REB (rd_en_i          ),
    .WEB (wr_en_i          ),
    .BWEB({WORD_SIZE{1'b1}}),
    .AA  (wr_addr_i        ),
    .AB  (rd_addr_i        )
    );

endmodule
