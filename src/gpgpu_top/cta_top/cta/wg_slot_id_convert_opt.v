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

module wg_slot_id_convert_opt #(
  parameter NUMBER_CU   = 2,
  parameter CU_ID_WIDTH = 1
  )(
  input                             clk              ,
  input                             rst_n            ,

  input   [`WG_ID_WIDTH-1:0]        wg_id_i          ,
  input   [CU_ID_WIDTH-1:0]         cu_id_i          ,
  input                             find_and_cancel_i,
  input                             generate_i       ,
  output  [`WG_SLOT_ID_WIDTH-1:0]   wg_slot_id_gen_o ,
  output  [`WG_SLOT_ID_WIDTH-1:0]   wg_slot_id_find_o
  );

  localparam SLOT_ID_NUM = 1 << `WG_SLOT_ID_WIDTH;

  wire  [`WG_SLOT_ID_WIDTH-1:0]                   found_wg_id            ;
  wire  [SLOT_ID_NUM-1:0]                         found_wg_id_valid      ;
  reg   [`WG_SLOT_ID_WIDTH-1:0]                   wg_slot_id_find_reg    ;
  reg   [`WG_SLOT_ID_WIDTH-1:0]                   wg_slot_id_gen_reg     ;
  reg   [NUMBER_CU*SLOT_ID_NUM-1:0]               wg_slot_id_bitmap      ;
  reg   [NUMBER_CU*SLOT_ID_NUM*`WG_ID_WIDTH-1:0]  wg_slot_id_find_ram_cam;

  wire  [`WG_SLOT_ID_WIDTH-1:0]                   first_slot_id          ;
  wire                                            first_slot_id_valid    ;
  wire  [SLOT_ID_NUM-1:0]                         first_slot_id_req      ;   
  wire  [SLOT_ID_NUM-1:0]                         first_slot_id_grant    ;

  reg   [CU_ID_WIDTH-1:0]                         cu_id_cancel           ;
  reg                                             cancel_valid           ;

  assign wg_slot_id_gen_o  = wg_slot_id_gen_reg ;
  assign wg_slot_id_find_o = wg_slot_id_find_reg;

  assign first_slot_id_req   = ~wg_slot_id_bitmap[(cu_id_i+1)*SLOT_ID_NUM-1-:SLOT_ID_NUM];
  assign first_slot_id_valid = |first_slot_id_req                                        ;

  fixed_pri_arb #(
    .ARB_WIDTH(SLOT_ID_NUM))
  U_fixed_pri_arb (
    .req  (first_slot_id_req  ),
    .grant(first_slot_id_grant)
    );

  one2bin #(
    .ONE_WIDTH(SLOT_ID_NUM      ),
    .BIN_WIDTH(`WG_SLOT_ID_WIDTH))
  U_one2bin (
    .oh (first_slot_id_grant),
    .bin(first_slot_id      )
    );

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      wg_slot_id_gen_reg  <= 'd0;
      wg_slot_id_find_reg <= 'd0;
      cu_id_cancel        <= 'd0;
      cancel_valid        <= 'd0;
    end
    else begin
      wg_slot_id_gen_reg  <= first_slot_id    ;
      wg_slot_id_find_reg <= found_wg_id      ;
      cu_id_cancel        <= cu_id_i          ;
      cancel_valid        <= find_and_cancel_i;
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      wg_slot_id_bitmap       <= 'd0;
      wg_slot_id_find_ram_cam <= 'd0;
    end
    else if(generate_i && first_slot_id_valid) begin
      wg_slot_id_bitmap[cu_id_i*SLOT_ID_NUM+first_slot_id]                                        <= 1'b1   ;
      wg_slot_id_find_ram_cam[(cu_id_i*SLOT_ID_NUM+first_slot_id+1)*`WG_ID_WIDTH-1-:`WG_ID_WIDTH] <= wg_id_i;     
    end
    else if(cancel_valid) begin
      wg_slot_id_bitmap[cu_id_cancel*SLOT_ID_NUM+wg_slot_id_find_reg] <= 1'b0;
    end
    else begin
      wg_slot_id_bitmap       <= wg_slot_id_bitmap      ;
      wg_slot_id_find_ram_cam <= wg_slot_id_find_ram_cam;
    end
  end

  //found the wg and cancel
  genvar i;
  generate for(i=0;i<SLOT_ID_NUM;i=i+1) begin : A1
    assign found_wg_id_valid[i] = ((wg_slot_id_find_ram_cam[(cu_id_cancel*SLOT_ID_NUM+i+1)*`WG_ID_WIDTH-1-:`WG_ID_WIDTH] == wg_id_i) && wg_slot_id_bitmap[cu_id_cancel*SLOT_ID_NUM+i]) ? 1 : 'd0;
  end
  endgenerate

  one2bin #(
    .ONE_WIDTH(SLOT_ID_NUM      ),
    .BIN_WIDTH(`WG_SLOT_ID_WIDTH))
  U_one2bin_1 (
    .oh (found_wg_id_valid),
    .bin(found_wg_id      )
    );

endmodule


  



