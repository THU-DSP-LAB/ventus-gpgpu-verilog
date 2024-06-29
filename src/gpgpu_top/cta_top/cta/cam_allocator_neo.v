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
// Description:

`timescale 1ns/1ns
`include "define.v"

module cam_allocator_neo #(
  parameter RES_ID_WIDTH = 10)
  (
  input                                 clk                   ,
  input                                 rst_n                 ,
  input                                 cam_wr_en_i           ,
  input   [`CU_ID_WIDTH-1:0]            cam_wr_addr_i         ,
  input   [RES_ID_WIDTH:0]              cam_wr_data_i         ,
  input   [RES_ID_WIDTH-1:0]            cam_wr_start_i        ,
  input                                 res_search_en_i       ,
  input   [RES_ID_WIDTH:0]              res_search_size_i     ,
  output  [`NUMBER_CU-1:0]              res_search_out_o      ,
  output  [`NUMBER_CU*RES_ID_WIDTH-1:0] res_search_out_start_o
  );

  reg                                       res_search_en_reg  ;
  reg   [RES_ID_WIDTH:0]                    res_search_size_reg;
  reg   [`NUMBER_CU-1:0]                    cam_valid_entry    ;
  reg   [`NUMBER_CU*(RES_ID_WIDTH+1)-1:0]   cam_ram            ;
  reg   [`NUMBER_CU*RES_ID_WIDTH-1:0]       cam_ram_start      ;
  reg   [`NUMBER_CU-1:0]                    decoded_output     ;

  assign res_search_out_start_o = cam_ram_start ; 
  assign res_search_out_o       = decoded_output;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      res_search_en_reg   <= 'd0;
      res_search_size_reg <= 'd0;
    end
    else begin
      res_search_en_reg   <= res_search_en_i  ;
      res_search_size_reg <= res_search_size_i;
    end
  end

  genvar i;
  generate for(i=0;i<`NUMBER_CU;i=i+1) begin : A1
    always@(*) begin
      if(!res_search_en_reg) begin
        decoded_output[i] = 1'b0;
      end
      else begin
        if(!cam_valid_entry[i]) begin
          decoded_output[i] = 1'b1;
        end
        else begin
          if(cam_ram[(i+1)*(RES_ID_WIDTH+1)-1-:(RES_ID_WIDTH+1)] >= res_search_size_reg) begin
            decoded_output[i] = 1'b1;
          end
          else begin
            decoded_output[i] = 1'b0;
          end
        end
      end
    end
  end
  endgenerate

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      cam_valid_entry <= 'd0;
      cam_ram_start   <= 'd0;
      cam_ram         <= 'd0;
    end
    else if(cam_wr_en_i) begin
      cam_ram[(cam_wr_addr_i+1)*(RES_ID_WIDTH+1)-1-:(RES_ID_WIDTH+1)] <= cam_wr_data_i ;
      cam_ram_start[(cam_wr_addr_i+1)*RES_ID_WIDTH-1-:RES_ID_WIDTH]   <= cam_wr_start_i;
      cam_valid_entry[cam_wr_addr_i]                                  <= 1'b1          ;
    end
    else begin
      cam_ram         <= cam_ram        ;
      cam_ram_start   <= cam_ram_start  ;
      cam_valid_entry <= cam_valid_entry;
    end
  end

endmodule
