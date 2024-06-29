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
// Author: TangYao
// Description:Simplifed Listbuffer module, 

`timescale  1ns/1ns
`include "define.v"
  module Listbuffer_no_push_opc_put_source(
  input                                         clk                         ,
  input                                         rst_n                       ,
  // val putbuffer, in fact it is listbuffer class
  output                                        List_buffer_push_ready_o    ,//data out
  input                                         List_buffer_push_valid_i    ,//data in
  input [`PUT_BITS-1:0]                         List_buffer_push_index_i    ,//data in
  input [`DATA_BITS-1:0]                        List_buffer_push_data_data_i,//data in;
  input [`MASK_BITS-1:0]                        List_buffer_push_data_mask_i,//data in;
  output [`PUTLISTS-1:0]                        List_buffer_valid_o         ,//data out
  input                                         List_buffer_pop_valid_i     ,//data in
  input [`PUT_BITS-1:0]                         List_buffer_pop_data_i      ,//data in
  output [`DATA_BITS-1:0]                       List_buffer_data_data_o     ,//data out
  output [`MASK_BITS-1:0]                       List_buffer_data_mask_o             //data out
  );
//above is the putbuffe IO ports, and there is no other index, pop2 and data2 port is because singleport is true.
//and below is the putbuffer inner logic
  reg [`PUTLISTS-1:0]                           valid                       ;
  reg [$clog2(`PUTBEATS)*`PUTLISTS-1:0]         head                        ;         
  reg [$clog2(`PUTBEATS)*`PUTLISTS-1:0]         tail                        ;         
  reg [`PUTBEATS-1:0]                           used                        ; //init 0
  reg [$clog2(`PUTBEATS)*`PUTBEATS-1:0]         next                        ;  
  reg [`DATA_BITS*`PUTBEATS-1:0]                data_data                   ;        
  reg [`MASK_BITS*`PUTBEATS-1:0]                data_mask                   ;        
  reg [`SOURCE_BITS*`PUTBEATS-1:0]              data_source                 ;
  reg [`PUT_BITS*`PUTBEATS-1:0]                 data_put                    ;        
  reg [`OP_BITS*`PUTBEATS-1:0]                  data_opcode                 ;
  wire [`PUTBEATS-1:0]                          freeOH                      ;
  wire [$clog2(`PUTBEATS)-1:0]                  freeIdx                     ;
  assign freeOH = (~((((~used)|((~used)<<1)) | (((~used)|((~used)<<1))<<2))<<1)) & (~used);//only if `PUTBEATS == 4
  one2bin #(
  .ONE_WIDTH(`PUTBEATS),
  .BIN_WIDTH($clog2(`PUTBEATS))
  )
  U_one2bin(
  .oh (freeOH),
  .bin(freeIdx)
  );
  wire [`PUTLISTS-1:0]                          valid_set                   ;
  wire [`PUTLISTS-1:0]                          valid_clr                   ;
  wire [`PUTBEATS-1:0]                          used_set                    ;
  wire [`PUTBEATS-1:0]                          used_clr                    ;
  wire [`PUTLISTS-1:0]                          valid_clr_2                 ;
  wire [`PUTBEATS-1:0]                          used_clr_2                  ;
  wire [$clog2(`PUTBEATS)-1:0]                  push_tail                   ;
  wire                                          push_valid                  ;
  wire [$clog2(`PUTBEATS)-1:0]                  pop_head                    ;
  assign pop_head = head [List_buffer_pop_data_i*$clog2(`PUTBEATS)+:$clog2(`PUTBEATS)];
  wire [$clog2 (`PUTBEATS)-1:0] head_write_pop_data;
  assign head_write_pop_data = (List_buffer_push_valid_i && List_buffer_push_ready_o && push_valid && (push_tail == pop_head)) ? freeIdx : next[pop_head*$clog2 (`PUTBEATS)+:$clog2 (`PUTBEATS)];
  assign push_tail  = tail[List_buffer_push_index_i*$clog2(`PUTBEATS)+:$clog2(`PUTBEATS)];
  assign push_valid = valid[List_buffer_push_index_i]                                    ;
  assign List_buffer_push_ready_o  = !(&used);
  assign valid_set = (List_buffer_push_ready_o & List_buffer_push_valid_i) ?  ( (List_buffer_push_index_i == 'b0) ? 'b1 : (1'b1<< List_buffer_push_index_i)  ): 'b0;
  assign used_set  = (List_buffer_push_ready_o & List_buffer_push_valid_i) ? (freeOH) :'b0;
  //是mem的  valid- head- tail - used -next - data_data - data_mask
  always @(posedge clk or negedge rst_n)
    begin
      if(!rst_n)
        begin
          head <= 0;
          tail <= 0;
          data_data <= 0;
          data_mask <= 0;
          next <= 0;
        end
      else if(List_buffer_push_ready_o & List_buffer_push_valid_i)
        begin
          data_data[freeIdx*`DATA_BITS+:`DATA_BITS] <= List_buffer_push_data_data_i;
          data_mask[freeIdx*`MASK_BITS+:`MASK_BITS] <= List_buffer_push_data_mask_i;
          tail[List_buffer_push_index_i*$clog2(`PUTBEATS)+:$clog2(`PUTBEATS)] <= freeIdx;
         if(push_valid)
          begin
            next[push_tail*$clog2(`PUTBEATS)+:$clog2(`PUTBEATS)] <= freeIdx;
          end
          else if(!push_valid)
            begin
              head[List_buffer_push_index_i*$clog2(`PUTBEATS)+:$clog2(`PUTBEATS)] <= freeIdx;
            end
        end
        else if(List_buffer_pop_valid_i )
          begin
            head[List_buffer_pop_data_i*$clog2(`PUTBEATS)+:$clog2(`PUTBEATS)] <= head_write_pop_data;
          end
          else
            begin
              next       <= next     ;
              head       <= head     ;
              tail       <= tail     ;
              data_data  <= data_data;
              data_mask  <= data_mask;
            end
    end
  
  wire pop_valid;
  assign pop_valid = valid[List_buffer_pop_data_i];
  
  assign List_buffer_data_data_o  = data_data [pop_head*`DATA_BITS+:`DATA_BITS];//only if bypass is false
  assign List_buffer_data_mask_o  = data_mask [pop_head*`MASK_BITS+:`MASK_BITS];//only if bypass is false
  assign List_buffer_valid_o = valid;
  
  assign used_clr  = (List_buffer_pop_valid_i) ?  ( (pop_head == 'b0) ? 'b1 : (1'b1<< pop_head)  ): 'b0;
  assign valid_clr = (List_buffer_pop_valid_i && (pop_head == tail[List_buffer_pop_data_i*$clog2(`PUTBEATS)+:$clog2(`PUTBEATS)])) ?  ( (List_buffer_pop_data_i == 'b0) ? 'b1 : (1'b1<< List_buffer_pop_data_i)  ): 'b0;
  always@(posedge clk or negedge rst_n)
  begin
    if(!rst_n)
      begin
        used  <= 0;
        valid <= 0;
      end
      else if( ! List_buffer_pop_valid_i || pop_valid ) // bypass is false now ,and no pop_valid2 bacause singleport is true
  begin
      used  <= used  & (~used_clr)   | used_set  ;
      valid <= valid & (~valid_clr)  | valid_set ;
  end
  end
  
  endmodule
