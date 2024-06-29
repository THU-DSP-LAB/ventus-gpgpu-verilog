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

module throttling_engine #(
  parameter NUMBER_CU   = 2,
  parameter CU_ID_WIDTH = 1
  )(
  input                             clk                   ,
  input                             rst_n                 ,

  input   [CU_ID_WIDTH-1:0]         cu_id_i               ,
  input                             alloc_en_i            ,
  input                             dealloc_en_i          ,
  input   [`WG_SLOT_ID_WIDTH:0]     wg_max_update_i       ,
  input                             wg_max_update_valid_i ,
  input                             wg_max_update_all_cu_i,
  input   [CU_ID_WIDTH-1:0]         wg_max_update_cu_id_i ,
  output  [`WG_SLOT_ID_WIDTH:0]     wg_count_available_o   
  );

  reg   [NUMBER_CU*(`WG_SLOT_ID_WIDTH+1)-1:0] wg_count_max_array    ;
  reg   [NUMBER_CU*(`WG_SLOT_ID_WIDTH+1)-1:0] actual_wg_count_array ;
  reg   [CU_ID_WIDTH-1:0]                     cu_id_reg             ;
  reg                                         alloc_en_reg          ;
  reg                                         dealloc_en_reg        ;
  reg   [`WG_SLOT_ID_WIDTH:0]                 wg_count_available_reg;

  assign wg_count_available_o = wg_count_available_reg;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      wg_count_max_array <= {NUMBER_CU{`INIT_MAX_WG_COUNT}};
    end
    else if(wg_max_update_valid_i) begin
      wg_count_max_array[(wg_max_update_cu_id_i+1)*(`WG_SLOT_ID_WIDTH+1)-1-:(`WG_SLOT_ID_WIDTH+1)] <=wg_max_update_i;
    end
    else if(wg_max_update_all_cu_i) begin
      wg_count_max_array <= {NUMBER_CU{wg_max_update_i}};
    end
    else begin
      wg_count_max_array <= wg_count_max_array;
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      alloc_en_reg   <= 'd0;
      dealloc_en_reg <= 'd0;
    end
    else begin
      alloc_en_reg   <= alloc_en_i  ;
      dealloc_en_reg <= dealloc_en_i;
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      cu_id_reg <= 'd0;
    end
    else if(alloc_en_i || dealloc_en_i) begin
      cu_id_reg <= cu_id_i;
    end
    else begin
      cu_id_reg <= cu_id_reg;
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      wg_count_available_reg <= 'd0;
    end
    else if(wg_count_max_array[(cu_id_i+1)*(`WG_SLOT_ID_WIDTH+1)-1-:(`WG_SLOT_ID_WIDTH+1)] > actual_wg_count_array[(cu_id_i+1)*(`WG_SLOT_ID_WIDTH+1)-1-:(`WG_SLOT_ID_WIDTH+1)]) begin
      wg_count_available_reg <= wg_count_max_array[(cu_id_i+1)*(`WG_SLOT_ID_WIDTH+1)-1-:(`WG_SLOT_ID_WIDTH+1)] - actual_wg_count_array[(cu_id_i+1)*(`WG_SLOT_ID_WIDTH+1)-1-:(`WG_SLOT_ID_WIDTH+1)];
    end
    else begin
      wg_count_available_reg <= 'd0;
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      actual_wg_count_array <= 'd0;
    end
    else if(alloc_en_reg) begin
      actual_wg_count_array[(cu_id_i+1)*(`WG_SLOT_ID_WIDTH+1)-1-:(`WG_SLOT_ID_WIDTH+1)] <= actual_wg_count_array[(cu_id_i+1)*(`WG_SLOT_ID_WIDTH+1)-1-:(`WG_SLOT_ID_WIDTH+1)] + 1;
    end
    else if(dealloc_en_reg) begin
      actual_wg_count_array[(cu_id_i+1)*(`WG_SLOT_ID_WIDTH+1)-1-:(`WG_SLOT_ID_WIDTH+1)] <= actual_wg_count_array[(cu_id_i+1)*(`WG_SLOT_ID_WIDTH+1)-1-:(`WG_SLOT_ID_WIDTH+1)] - 1;
    end
    else begin
      actual_wg_count_array <= actual_wg_count_array;
    end
  end

endmodule



