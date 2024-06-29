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
// Author:Tangyao 
// Description:Accept info from L1cache

`timescale  1ns/1ns
`include "define.v"
//`include "L2cache_define.v"

module sinkA(
  input                               clk                    ,
  input                               rst_n                  ,
  // Decoupled FullRequest
  input                               sinkA_req_ready_i      ,
  output                              sinkA_req_valid_o      ,
  //sinkA req part handshake signals
  output  [`SET_BITS-1:0]             sinkA_req_set_o        ,
  //output  [`L2C_BITS-1:0]             sinkA_req_l2cidx_o     ,
  output  [`OP_BITS-1:0]              sinkA_req_opcode_o     ,
  output  [`SIZE_BITS-1:0]            sinkA_req_size_o       ,
  output  [`SOURCE_BITS-1:0]          sinkA_req_source_o     ,
  output  [`TAG_BITS-1:0]             sinkA_req_tag_o        ,
  output  [`OFFSET_BITS-1:0]          sinkA_req_offset_o     ,
  output  [`PUT_BITS-1:0]             sinkA_req_put_o        ,
  output  [`DATA_BITS-1:0]            sinkA_req_data_o       ,
  output  [`MASK_BITS-1:0]            sinkA_req_mask_o       ,
  output  [`PARAM_BITS-1:0]           sinkA_req_param_o      ,
  
  //Flipped(Decoupled -TLBundleA_lite）
  output                              sinkA_a_ready_o        ,
  input                               sinkA_a_valid_i        ,
  //sinkA a part handshake signals
  input   [`OP_BITS-1:0]              sinkA_a_opcode_i       ,
  input   [`SIZE_BITS-1:0]            sinkA_a_size_i         ,
  input   [`SOURCE_BITS-1:0]          sinkA_a_source_i       ,
  input   [`ADDRESS_BITS-1:0]         sinkA_a_address_i      ,
  input   [`MASK_BITS-1:0]            sinkA_a_mask_i         ,
  input   [`DATA_BITS-1:0]            sinkA_a_data_i         ,
  input   [`PARAM_BITS-1:0]           sinkA_a_param_i        ,
  
  //invalid/flush 
  input                               invalidate_ready_i     ,
  input                               flush_ready_i          ,   
  //Flipped(Decoupled -PutBufferPop）
  output                              sinkA_pb_pop_ready_o   ,
  input                               sinkA_pb_pop_valid_i   ,
  //sinkA pb_pop part handshake signals
  input [`PUT_BITS-1:0]               sinkA_pb_pop_index_i   ,
  
  //sinkA_pb_beat part signals 
  output   [`DATA_BITS-1:0]           sinkA_pb_beat_data_o   ,
  output   [`MASK_BITS-1:0]           sinkA_pb_beat_mask_o   ,
  //sinkA empty part signals 
  output                              sinkA_empty_o          
  
  );
  wire                        a_sinkA_a_ready         ;
  wire                        a_sinkA_a_valid         ;
  //sinkA a part handshake signals
  wire   [`OP_BITS-1:0]       a_sinkA_a_opcode        ;
  wire   [`SIZE_BITS-1:0]     a_sinkA_a_size          ;
  wire   [`SOURCE_BITS-1:0]   a_sinkA_a_source        ;
  wire   [`ADDRESS_BITS-1:0]  a_sinkA_a_address       ;
  wire   [`MASK_BITS-1:0]     a_sinkA_a_mask          ;
  wire   [`DATA_BITS-1:0]     a_sinkA_a_data          ;
  wire   [`PARAM_BITS-1:0]    a_sinkA_a_param         ;
  
  assign  sinkA_a_ready_o   = a_sinkA_a_ready  ;
  assign  a_sinkA_a_valid   = sinkA_a_valid_i  ;
  assign  a_sinkA_a_opcode  = sinkA_a_opcode_i ;
  assign  a_sinkA_a_size    = sinkA_a_size_i   ;
  assign  a_sinkA_a_source  = sinkA_a_source_i ;
  assign  a_sinkA_a_address = sinkA_a_address_i;
  assign  a_sinkA_a_mask    = sinkA_a_mask_i   ;
  assign  a_sinkA_a_data    = sinkA_a_data_i   ;
  assign  a_sinkA_a_param   = sinkA_a_param_i  ;
  
  // val putbuffer, in fact it is listbuffer
  wire                              putbuffer_push_ready_o           ;
  wire                              putbuffer_push_valid_i           ;
  wire [`PUT_BITS-1:0]              putbuffer_push_index_i           ;
  wire [`DATA_BITS-1:0]             putbuffer_push_data_data_i       ;
  wire [`MASK_BITS-1:0]             putbuffer_push_data_mask_i       ;
  //wire [`PUT_BITS-1:0]              putbuffer_push_data_put_i        ;
  //wire [`OP_BITS-1:0]               putbuffer_push_data_opcode_i     ;
  //wire [`SOURCE_BITS-1:0]           putbuffer_push_data_source_i     ;
  wire [`PUTLISTS-1:0]              putbuffer_valid_o                ;
  wire                              putbuffer_pop_valid_i            ;
  wire [`PUT_BITS-1:0]              putbuffer_pop_data_i             ;
  wire [`DATA_BITS-1:0]             putbuffer_data_data_o            ;
  wire [`MASK_BITS-1:0]             putbuffer_data_mask_o            ;
  wire [`PUT_BITS-1:0]              putbuffer_data_put_o             ;
  wire [`OP_BITS-1:0]               putbuffer_data_opcode_o          ;
  wire [`SOURCE_BITS-1:0]           putbuffer_data_source_o          ;
  
  
  Listbuffer_no_push_opc_put_source Listbuffer_dut(
  .clk                           (clk                         ) ,
  .rst_n                         (rst_n                       ) ,
  .List_buffer_push_ready_o      (putbuffer_push_ready_o      ) ,//data out
  .List_buffer_push_valid_i      (putbuffer_push_valid_i      ) ,//data in
  .List_buffer_push_index_i      (putbuffer_push_index_i      ) ,//data in
  .List_buffer_push_data_data_i  (putbuffer_push_data_data_i  ) ,//data in;
  .List_buffer_push_data_mask_i  (putbuffer_push_data_mask_i  ) ,//data in;
  //.List_buffer_push_data_put_i   (putbuffer_push_data_put_i   ) ,
  //.List_buffer_push_data_opcode_i(putbuffer_push_data_opcode_i) ,
  //.List_buffer_push_data_source_i(putbuffer_push_data_source_i) ,
  .List_buffer_valid_o           (putbuffer_valid_o           ) ,//data out
  .List_buffer_pop_valid_i       (putbuffer_pop_valid_i       ) ,//data in
  .List_buffer_pop_data_i        (putbuffer_pop_data_i        ) ,//data in
  .List_buffer_data_data_o       (putbuffer_data_data_o       ),//data out
  .List_buffer_data_mask_o       (putbuffer_data_mask_o       )//data out
  //.List_buffer_data_put_o        (putbuffer_data_put_o        ),
  //.List_buffer_data_opcode_o     (putbuffer_data_opcode_o     ),
  //.List_buffer_data_source_o     (putbuffer_data_source_o     )
  );
  
  
  //above is putbuffer signals (listbuffer)
  
  wire [`PUT_BITS-1:0] freeIdx  ;
  reg  [`PUTLISTS-1:0] lists    ;//init 0 //PUT_BITS = 2
  wire [`PUTLISTS-1:0] lists_set;//init 0
  wire [`PUTLISTS-1:0] lists_clr;//init 0
  wire free                     ;
  wire [`PUTLISTS-1:0] freeOH   ;
  
  assign free = !(&lists);
  assign freeOH = (~((((~lists)|((~lists)<<1)) | (((~lists)|((~lists)<<1))<<2)) <<1)) & (~lists);
  one2bin #(
  .ONE_WIDTH(`PUTLISTS),
  .BIN_WIDTH(`PUT_BITS)
  )
  U2_one2bin(
  .oh (freeOH),
  .bin(freeIdx)
  );
  //one hot to uint  freeOH -> freeidx
  wire hasData;
  assign hasData = (sinkA_a_opcode_i == 3'b1 )||(sinkA_a_opcode_i == 3'b0 );
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      lists <= 0;
    end
    else begin
      lists <= (lists | lists_set ) & (~lists_clr);
    end
  end  
  
  wire req_block;
  assign req_block = !sinkA_req_ready_i;
  
  wire buf_block;
  assign buf_block = hasData && !putbuffer_push_ready_o;
  
  wire set_block;
  assign set_block = hasData && !free;
  
  assign a_sinkA_a_ready = (a_sinkA_a_opcode == 3'd5) ? (!req_block && !buf_block && !set_block && invalidate_ready_i) : (!req_block && !buf_block && !set_block);
  assign sinkA_req_valid_o = (a_sinkA_a_opcode != 3'd5) ? (a_sinkA_a_valid && !buf_block && !set_block) : ((a_sinkA_a_param == 'd1) ? (a_sinkA_a_valid && !buf_block && !set_block && invalidate_ready_i) : (a_sinkA_a_valid && !buf_block && !set_block && flush_ready_i));
  assign putbuffer_push_valid_i = a_sinkA_a_valid && hasData && !req_block && !set_block;
  assign lists_set = (a_sinkA_a_valid && hasData && !req_block && !buf_block) ? freeOH:'b0;
  
  wire [`TAG_BITS-1:0] tag      ;
  //wire [`L2C_BITS-1:0] l2cidx;
  wire [`SET_BITS-1:0] set      ;
  wire [`OFFSET_BITS-1:0] offset;
  assign tag = a_sinkA_a_address[`ADDRESS_BITS-1-:`TAG_BITS];
  //assign l2cidx = a_sinkA_a_address [`ADDRESS_BITS-`TAG_BITS-1-:`L2C_BITS]; //now `L2C_BITS > 1
  //assign l2cidx = (`L2C_BITS !=0) ? ((set >> `SET_BITS) [`L2C_BITS-1:0]) :0; //if `L2C_BITS > 0
  //assign l2cidx = 'b0;//only if l2cbits == 0;
  assign set = a_sinkA_a_address[`OFFSET_BITS+:`SET_BITS]   ;
  assign offset = a_sinkA_a_address[`OFFSET_BITS-1:0]       ; 
  wire [`PUT_BITS-1:0] put;
  assign put = freeIdx;
  assign sinkA_req_opcode_o = a_sinkA_a_opcode;
  assign sinkA_req_size_o   = a_sinkA_a_size  ;
  assign sinkA_req_source_o = a_sinkA_a_source;
  assign sinkA_req_offset_o = offset          ;
  assign sinkA_req_set_o    = set             ;
  assign sinkA_req_tag_o    = tag             ;
  //assign sinkA_req_l2cidx_o = l2cidx        ;
  assign sinkA_req_put_o    = put             ;
  assign sinkA_req_mask_o   = a_sinkA_a_mask  ;
  assign sinkA_req_data_o   = a_sinkA_a_data  ;
  assign sinkA_req_param_o  = a_sinkA_a_param ;
  
  assign putbuffer_push_index_i     = put                                         ;  
  assign putbuffer_push_data_data_i = a_sinkA_a_data                              ;
  assign putbuffer_push_data_mask_i = a_sinkA_a_mask                              ;
  assign putbuffer_pop_data_i       =  sinkA_pb_pop_index_i                       ;
  assign putbuffer_pop_valid_i      = sinkA_pb_pop_valid_i && sinkA_pb_pop_ready_o;

  assign sinkA_pb_pop_ready_o       = putbuffer_valid_o [sinkA_pb_pop_index_i];
  assign sinkA_pb_beat_data_o       = putbuffer_data_data_o                   ;
  assign sinkA_pb_beat_mask_o       = putbuffer_data_mask_o                   ;
  assign sinkA_empty_o              = ~(|((lists | lists_set) & (~lists_clr)));

  assign lists_clr                  = (sinkA_pb_pop_ready_o && sinkA_pb_pop_valid_i ) ?  ( (sinkA_pb_pop_index_i == 'b0) ? 'b1 : (1'b1<< sinkA_pb_pop_index_i)  ): 'b0;
  //onehot -> uint lists_clr
  //assign used_clr = (putbuffer_pop_valid ) ? (1<< pop_head[$clog2(`PUTBEATS) -1])[`PUTBEATS-1:0] : used_clr;
endmodule
