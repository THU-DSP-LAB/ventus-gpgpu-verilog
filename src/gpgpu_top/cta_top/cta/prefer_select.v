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

module prefer_select #(
  parameter RANGE    = 2,
  parameter ID_WIDTH = 1
  )(
  input   [RANGE-1:0]           signal_i,
  input   [ID_WIDTH-1:0]        prefer_i,
  output                        valid_o ,
  output  [ID_WIDTH-1:0]        id_o    
  );

  wire                          found                    ;
  wire    [ID_WIDTH:0]          found_id                 ;
  wire    [$clog2(RANGE)-1:0]   prefer_pre               ;
  wire    [$clog2(RANGE):0]     prefer_pre_1  [0:RANGE-1];
  wire    [$clog2(RANGE)-1:0]   prefer_pre_2  [0:RANGE-1];
  wire    [RANGE-1:0]           oh                       ;
  wire    [RANGE-1:0]           oh_rev                   ;
  wire    [RANGE-1:0]           grant                    ;
  wire    [RANGE-1:0]           grant_rev                ;

  assign prefer_pre   = prefer_i[$clog2(RANGE)-1:0];

  genvar i;
  generate for(i=0;i<RANGE;i=i+1) begin : A1
    //assign found[i]    = signal_i[(i + prefer_pre)[$clog2(RANGE)-1:0]] ? 1'b1 : 1'b0                              ;
    //assign found_id[i] = signal_i[(i + prefer_pre)[$clog2(RANGE)-1:0]] ? (i + prefer_pre)[$clog2(RANGE)-1:0] : 'd0;
    
    assign prefer_pre_1[i] = prefer_pre + i                    ;
    assign prefer_pre_2[i] = prefer_pre_1[i][$clog2(RANGE)-1:0];
    assign oh[i]                = signal_i[prefer_pre_2[i]]    ;
    assign oh_rev[RANGE-1-i]    = oh[i]                        ;//最高位优先级最高，需要reverse
    assign grant_rev[RANGE-1-i] = grant[i]                     ;//再reverse回来
  end
  endgenerate

  fixed_pri_arb #(
    .ARB_WIDTH(RANGE))
  U_fixed_pri_arb (
    .req  (oh_rev     ),
    .grant(grant      )
    );

  one2bin #(
    .ONE_WIDTH(RANGE   ),
    .BIN_WIDTH(ID_WIDTH+1))
  U_one2bin (
    .oh (grant_rev),
    .bin(found_id )
    );

  assign found   = |oh                   ;
  assign valid_o = found                 ;
  assign id_o    = found_id[ID_WIDTH-1:0];
 
endmodule



  


