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
// Description:cta scheduler 2 warp scheduer
`timescale 1ns/1ns

`include "define.v"

module cta2warp (
  input                    clk                                  ,
  input                    rst_n                                ,
    
  output                   cta_req_ready_o                      ,
  input                    cta_req_valid_i                      ,
  input  [`TAG_WIDTH-1:0]  cta_req_dispatch2cu_wf_tag_dispatch_i,

  input                    cta_rsp_ready_i                      ,
  output                   cta_rsp_valid_o                      ,
  output [`TAG_WIDTH-1:0]  cta_rsp_cu2dispatch_wf_tag_done_o    ,

  output                   warpReq_valid_o                      ,
  output [`DEPTH_WARP-1:0] warpReq_wid_o                        ,

  output                   warpRsp_ready_o                      ,
  input                    warpRsp_valid_i                      , 
  input  [`DEPTH_WARP-1:0] warpRsp_wid_i                        , //the id of the warp that have ended execution
           
  input  [`DEPTH_WARP-1:0] wg_id_lookup_i                       , //wid
  output [`TAG_WIDTH-1:0]  wg_id_tag_o                            //workgroup's tag
  );

  wire cta_req_fire,warpRsp_fire;
  reg [`NUM_WARP-1:0] idx_using;
  wire [`NUM_WARP-1:0] idx_using_alloc,idx_using_dealloc;
  wire [`DEPTH_WARP-1:0] idx_next_allocate;
  wire [`NUM_WARP-1:0] idx_next_allocate_one;
  reg [`NUM_WARP*`TAG_WIDTH-1:0] data;

  assign cta_req_fire = cta_req_valid_i && cta_req_ready_o;
  assign warpRsp_fire = warpRsp_valid_i && warpRsp_ready_o;

  assign cta_req_ready_o = ~(&idx_using);

  assign wg_id_tag_o = data[(`TAG_WIDTH*(wg_id_lookup_i+1)-1)-:`TAG_WIDTH]; 

  assign idx_using_alloc = idx_using | ((1'h1<<idx_next_allocate) & {`NUM_WARP{cta_req_fire}}); 
  assign idx_using_dealloc = (1'h1<<warpRsp_wid_i) & {`NUM_WARP{warpRsp_fire}}; 

  assign warpReq_valid_o = cta_req_fire;
  assign warpReq_wid_o = idx_next_allocate;
  assign warpRsp_ready_o = cta_rsp_ready_i;
  assign cta_rsp_valid_o = warpRsp_valid_i;
  assign cta_rsp_cu2dispatch_wf_tag_done_o = data[(`TAG_WIDTH*(warpRsp_wid_i+1)-1)-:`TAG_WIDTH]; 

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      idx_using <= 'h0;
    end 
    else begin
      idx_using <= idx_using_alloc & (~idx_using_dealloc); 
    end  
  end 

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      data <= 'h0;
    end
    else if(cta_req_fire) begin
      data[`TAG_WIDTH*(idx_next_allocate+1)-1-:`TAG_WIDTH] <= cta_req_dispatch2cu_wf_tag_dispatch_i;
    end 
    else begin
      data <= data;
    end 
  end 

  fixed_pri_arb #(
    .ARB_WIDTH(`NUM_WARP)
    ) priority_encoder(
    .req  (~idx_using           ),
    .grant(idx_next_allocate_one)
    );

  one2bin #(
    .ONE_WIDTH(`NUM_WARP  ),
    .BIN_WIDTH(`DEPTH_WARP)
    ) idx_one2bin(
    .oh (idx_next_allocate_one),
    .bin(idx_next_allocate    )
    );

endmodule
