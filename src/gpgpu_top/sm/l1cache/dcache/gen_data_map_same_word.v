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

module gen_data_map_same_word(
  input       [1*`DCACHE_NLANES-1:0]                          perLaneAddr_activeMask_i              ,
  input       [`DCACHE_BLOCKOFFSETBITS*`DCACHE_NLANES-1:0]    perLaneAddr_blockOffset_i             ,
  input       [`BYTESOFWORD*`DCACHE_NLANES-1:0]               perLaneAddr_wordOffset1H_i            ,
  input       [`WORDLENGTH*`DCACHE_NLANES-1:0]                data_i                                ,
  output      [1*`DCACHE_NLANES-1:0]                          perLaneAddrRemap_activeMask_o         , // no use
  output      [`DCACHE_BLOCKOFFSETBITS*`DCACHE_NLANES-1:0]    perLaneAddrRemap_blockOffset_o        , // no use
  output      [`BYTESOFWORD*`DCACHE_NLANES-1:0]               perLaneAddrRemap_wordOffset1H_o       ,
  output      [`WORDLENGTH*`DCACHE_NLANES-1:0]                data_o                                 
);

  reg  [`DCACHE_NLANES*`DCACHE_NLANES-1:0]                    blockOffsetMatch          ;
  wire [`DCACHE_NLANES*`DCACHE_NLANES*`BYTESOFWORD-1:0]       wordOffsetRemap           ;
  wire [`DCACHE_NLANES*`DCACHE_NLANES*`WORDLENGTH-1:0]        dataRemap                 ;
  //wire [`DCACHE_NLANES*`BYTESOFWORD-1:0]                      wordOffsetRemap_reduce    ;
  //wire [`DCACHE_NLANES*`WORDLENGTH-1:0]                       dataRemap_reduce          ;
  wire [`DCACHE_NLANES*(`DCACHE_NLANES-1)*`BYTESOFWORD-1:0]   wordOffsetRemap_tmp       ;
  wire [`DCACHE_NLANES*(`DCACHE_NLANES-1)*`WORDLENGTH-1:0]    dataRemap_tmp             ;

  genvar i,j;
  generate
    for (i=0; i<`DCACHE_NLANES; i=i+1) begin:row_loop_1
      for (j=0; j<`DCACHE_NLANES; j=j+1) begin:column_loop_1
        always@(*) begin
          if(perLaneAddr_activeMask_i[i] && perLaneAddr_activeMask_i[j]) begin
            blockOffsetMatch[`DCACHE_NLANES*i+j]  = perLaneAddr_blockOffset_i[`DCACHE_BLOCKOFFSETBITS*(i+1)-1-:`DCACHE_BLOCKOFFSETBITS]==perLaneAddr_blockOffset_i[`DCACHE_BLOCKOFFSETBITS*(j+1)-1-:`DCACHE_BLOCKOFFSETBITS];
          end else begin
            blockOffsetMatch[`DCACHE_NLANES*i+j]  = 1'b0;
          end
        end
      end
    end
  endgenerate

  genvar n,m;
  generate
    for (n=0; n<`DCACHE_NLANES; n=n+1) begin:row_loop_2
      assign  perLaneAddrRemap_activeMask_o   [n]                                                        = perLaneAddr_activeMask_i   [n]                                                                             ;
      assign  perLaneAddrRemap_blockOffset_o  [`DCACHE_BLOCKOFFSETBITS*(n+1)-1-:`DCACHE_BLOCKOFFSETBITS] = perLaneAddr_blockOffset_i  [`DCACHE_BLOCKOFFSETBITS*(n+1)-1-:`DCACHE_BLOCKOFFSETBITS]                      ;
      assign  perLaneAddrRemap_wordOffset1H_o [`BYTESOFWORD*(n+1)-1-:`BYTESOFWORD]                       = wordOffsetRemap_tmp     [(`DCACHE_NLANES-1)*`BYTESOFWORD*n+(`DCACHE_NLANES-1)*`BYTESOFWORD-1-:`BYTESOFWORD];
      assign  data_o                          [`WORDLENGTH*(n+1)-1-:`WORDLENGTH]                         = dataRemap_tmp           [(`DCACHE_NLANES-1)*`WORDLENGTH*n+(`DCACHE_NLANES-1)*`WORDLENGTH-1-:`WORDLENGTH]   ;
      for (m=0; m<`DCACHE_NLANES; m=m+1) begin:column_loop_2
        assign  wordOffsetRemap[`DCACHE_NLANES*`BYTESOFWORD*n+`BYTESOFWORD*(m+1)-1-:`BYTESOFWORD] = blockOffsetMatch[`DCACHE_NLANES*n+m] ? perLaneAddr_wordOffset1H_i[`BYTESOFWORD*(m+1)-1-:`BYTESOFWORD] : 'b0       ;
        assign  dataRemap[`DCACHE_NLANES*`WORDLENGTH*n+`WORDLENGTH*(m+1)-1-:`WORDLENGTH]          = blockOffsetMatch[`DCACHE_NLANES*n+m] ? data_i[`WORDLENGTH*(m+1)-1-:`WORDLENGTH] : 'b0                             ;
      end
    end
  endgenerate

  genvar k,l;
  generate
    for (k=0; k<`DCACHE_NLANES; k=k+1) begin:row_loop_3
      assign  wordOffsetRemap_tmp [(`DCACHE_NLANES-1)*`BYTESOFWORD*k+`BYTESOFWORD*(0+1)-1-:`BYTESOFWORD]  = wordOffsetRemap [`DCACHE_NLANES*`BYTESOFWORD*k+`BYTESOFWORD*(1+1)-1-:`BYTESOFWORD]  | wordOffsetRemap [`DCACHE_NLANES*`BYTESOFWORD*k+`BYTESOFWORD*(0+1)-1-:`BYTESOFWORD]  ;
      assign  dataRemap_tmp       [(`DCACHE_NLANES-1)*`WORDLENGTH*k+`WORDLENGTH*(0+1)-1-:`WORDLENGTH]     = dataRemap       [`DCACHE_NLANES*`WORDLENGTH*k+`WORDLENGTH*(1+1)-1-:`WORDLENGTH]     | dataRemap       [`DCACHE_NLANES*`WORDLENGTH*k+`WORDLENGTH*(0+1)-1-:`WORDLENGTH]     ;
      for (l=0; l<`DCACHE_NLANES-2; l=l+1) begin:column_loop_3
        assign  wordOffsetRemap_tmp[(`DCACHE_NLANES-1)*`BYTESOFWORD*k+`BYTESOFWORD*(l+1+1)-1-:`BYTESOFWORD] = wordOffsetRemap[`DCACHE_NLANES*`BYTESOFWORD*k+`BYTESOFWORD*(l+2+1)-1-:`BYTESOFWORD] | wordOffsetRemap_tmp [(`DCACHE_NLANES-1)*`BYTESOFWORD*k+`BYTESOFWORD*(l+1)-1-:`BYTESOFWORD]  ;
        assign  dataRemap_tmp      [(`DCACHE_NLANES-1)*`WORDLENGTH*k+`WORDLENGTH*(l+1+1)-1-:`WORDLENGTH]    = dataRemap      [`DCACHE_NLANES*`WORDLENGTH*k+`WORDLENGTH*(l+2+1)-1-:`WORDLENGTH]    | dataRemap_tmp       [(`DCACHE_NLANES-1)*`WORDLENGTH*k+`WORDLENGTH*(l+1)-1-:`WORDLENGTH]     ;
      end
    end
  endgenerate



endmodule
