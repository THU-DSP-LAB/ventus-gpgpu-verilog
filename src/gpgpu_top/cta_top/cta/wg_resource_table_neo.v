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

module wg_resource_table_neo #(
  parameter NUMBER_CU   = 2,
  parameter CU_ID_WIDTH = 1
  )(
  input                                 clk                 ,
  input                                 rst_n               ,

  input   [CU_ID_WIDTH-1:0]             cu_id_i             ,
  input                                 alloc_en_i          ,
  input                                 dealloc_en_i        ,
  input   [`WF_COUNT_WIDTH_PER_WG-1:0]  wf_count_i          ,
  input   [`WG_SLOT_ID_WIDTH-1:0]       alloc_wg_slot_id_i  ,
  input   [`WG_SLOT_ID_WIDTH-1:0]       dealloc_wg_slot_id_i,
  output  [`WF_COUNT_WIDTH-1:0]         wf_count_o            
  );
  
  localparam  SLOT_ID_NUM = 1 << `WG_SLOT_ID_WIDTH;
  
  reg   [NUMBER_CU*`WF_COUNT_WIDTH-1:0]                     wf_count_out_reg    ;
  reg   [NUMBER_CU*SLOT_ID_NUM*`WF_COUNT_WIDTH_PER_WG-1:0]  wf_count_per_wg_slot;
  reg   [CU_ID_WIDTH-1:0]                                   cu_id_delay         ;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      wf_count_out_reg     <= {NUMBER_CU{`WF_COUNT_MAX}};
      wf_count_per_wg_slot <= 'd0                       ;
    end
    else if(alloc_en_i) begin
      wf_count_out_reg[(cu_id_i+1)*`WF_COUNT_WIDTH-1-:`WF_COUNT_WIDTH]                                                  <= wf_count_out_reg[(cu_id_i+1)*`WF_COUNT_WIDTH-1-:`WF_COUNT_WIDTH] - wf_count_i;
      wf_count_per_wg_slot[(cu_id_i*SLOT_ID_NUM+alloc_wg_slot_id_i+1)*`WF_COUNT_WIDTH_PER_WG-1-:`WF_COUNT_WIDTH_PER_WG] <= wf_count_i                                                                   ;
    end
    else if(dealloc_en_i) begin
      wf_count_out_reg[(cu_id_i+1)*`WF_COUNT_WIDTH-1-:`WF_COUNT_WIDTH] <= wf_count_out_reg[(cu_id_i+1)*`WF_COUNT_WIDTH-1-:`WF_COUNT_WIDTH] + wf_count_per_wg_slot[(cu_id_i*SLOT_ID_NUM+dealloc_wg_slot_id_i+1)*`WF_COUNT_WIDTH_PER_WG-1-:`WF_COUNT_WIDTH_PER_WG];
    end
    else begin
      wf_count_out_reg     <= wf_count_out_reg    ;
      wf_count_per_wg_slot <= wf_count_per_wg_slot;
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      cu_id_delay <= 'd0;
    end
    else begin
      cu_id_delay <= cu_id_i;
    end
  end

  assign wf_count_o = wf_count_out_reg[(cu_id_delay+1)*`WF_COUNT_WIDTH-1-:`WF_COUNT_WIDTH];

endmodule



