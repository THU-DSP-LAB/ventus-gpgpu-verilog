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
// Author: Chen, Qixiang
// Description:
`include "define.v"

`timescale 1ns/1ps

module dcache_wshr #(
  parameter DEPTH = `DCACHE_WSHR_ENTRY          ,
  parameter WIDTH = $clog2(`DCACHE_WSHR_ENTRY)    
)(
  input                                             clk                     ,
  input                                             rst_n                   ,

  // push
  input                                             pushReq_valid_i         ,
  output                                            pushReq_ready_o         ,
  input   [`DCACHE_SETIDXBITS+`DCACHE_TAGBITS-1:0]  pushReq_blockAddr_i     ,
  output                                            conflict_o              ,
  output  [WIDTH-1:0]                               pushedIdx_o             ,

  // for invOrFlu
  output                                            empty_o                 ,
  
  // pop
  input                                             popReq_valid_i          ,
  input   [WIDTH-1:0]                               popReq_bits_i             
);

  reg   [(`DCACHE_SETIDXBITS+`DCACHE_TAGBITS)*DEPTH-1:0]    blockAddrEntries        ;
  reg   [DEPTH-1:0]                                         validEntries            ;
  wire  [DEPTH-1:0]                                         pushMatchMask           ;
  wire  [WIDTH-1:0]                                         nextEntryIdx            ;
  wire                                                      pop_push_in_same_cycle  ;
  wire  [DEPTH-1:0]                                         available_entries_oh    ;
  //wire  [WIDTH-1:0]                                         available_entries_bin   ;


  assign  empty_o = !(|validEntries);
  
  genvar i;
  generate
    for (i=0; i<DEPTH; i=i+1) begin:mask_loop
      assign  pushMatchMask[i] = (blockAddrEntries[(`DCACHE_SETIDXBITS+`DCACHE_TAGBITS)*(i+1)-1-:(`DCACHE_SETIDXBITS+`DCACHE_TAGBITS)]==pushReq_blockAddr_i) && validEntries[i];
      //assign  pushMatchMask[i] = (pushReq_valid_i && pushReq_ready_o) ? (blockAddrEntries[(`DCACHE_SETIDXBITS+`DCACHE_TAGBITS)*(i+1)-1-:(`DCACHE_SETIDXBITS+`DCACHE_TAGBITS)]==pushReq_blockAddr_i) && validEntries[i] : 'd0;// && pushReq_valid_i && pushReq_ready_o;
    end
  endgenerate

  assign  conflict_o      = |pushMatchMask    ;
  assign  pushReq_ready_o = !(&validEntries)  ; // pushReq_ready = !full

  assign  pop_push_in_same_cycle = (pushReq_valid_i && pushReq_ready_o) && popReq_valid_i;
  assign  pushedIdx_o = pop_push_in_same_cycle ? popReq_bits_i : nextEntryIdx;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      blockAddrEntries  <= 'b0;
      validEntries      <= 'b0;
    end else if(pop_push_in_same_cycle) begin
      blockAddrEntries[(`DCACHE_SETIDXBITS+`DCACHE_TAGBITS)*(popReq_bits_i+1)-1-:(`DCACHE_SETIDXBITS+`DCACHE_TAGBITS)]  <= pushReq_blockAddr_i;
      validEntries[popReq_bits_i]         <= 1'b1;
    end else if(pushReq_valid_i && pushReq_ready_o) begin
      blockAddrEntries[(`DCACHE_SETIDXBITS+`DCACHE_TAGBITS)*(nextEntryIdx+1)-1-:(`DCACHE_SETIDXBITS+`DCACHE_TAGBITS)]  <= pushReq_blockAddr_i;
      validEntries[nextEntryIdx]          <= 1'b1;
    end else if(popReq_valid_i) begin
      validEntries[popReq_bits_i]         <= 1'b0;
    end else begin
      blockAddrEntries  <= blockAddrEntries ;
      validEntries      <= validEntries     ;
    end
  end

  fixed_pri_arb #(
    .ARB_WIDTH(DEPTH)
  )
  U_fixed_pri_arb
  (
    .req  (~validEntries            ),
    .grant(available_entries_oh     )
  );

  one2bin #(
    .ONE_WIDTH(DEPTH),
    .BIN_WIDTH(WIDTH)
  )
  U_one2bin
  (
    .oh (available_entries_oh      ),
    .bin(nextEntryIdx              )    
  );

endmodule
