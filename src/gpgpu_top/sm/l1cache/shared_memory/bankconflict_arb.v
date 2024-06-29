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
// Author: Tan, Zhiyuan
// Description: For dealing with bank conflict: split one require into multiple requre
`timescale 1ns/1ns

`include "define.v"

module bankconflict_arb (
  input                                                 clk                           ,
  input                                                 rst_n                         ,
  input                                                 core_req_arb_is_write_i       ,
  input                                                 core_req_arb_enable_i         ,
  input  [`SHAREMEM_NLANES-1:0]                         core_req_arb_activemask_i     ,
  input  [`SHAREMEM_NLANES*`DCACHE_BLOCKOFFSETBITS-1:0] core_req_arb_blockoffset_i    ,
  input  [`SHAREMEM_NLANES*`BYTESOFWORD-1:0]            core_req_arb_wordoffset1h_i   ,
  output [`SHAREMEM_NBANKS*`SHAREMEM_NLANES-1:0]        data_crsbar_write_sel1h_o     ,
  output [`SHAREMEM_NLANES*`SHAREMEM_NBANKS-1:0]        data_crsbar_read_sel1h_o      ,
  output [`SHAREMEM_NBANKS*`SHAREMEM_BANKOFFSET-1:0]    data_crsbar_out_bankoffset_o  ,
  output [`SHAREMEM_NBANKS*`BYTESOFWORD-1:0]            data_crsbar_out_wordoffset1h_o,
  output [`SHAREMEM_NBANKS-1:0]                         data_array_en_o               ,
  output [`SHAREMEM_NLANES-1:0]                         active_lane_o                 ,
  output                                                bankconflict_o                
);

  localparam BANKOFFSET_ISZERO = `DCACHE_BLOCKOFFSETBITS <= `SHAREMEM_BANKIDXBITS;
  localparam COUNT_WIDTH       = $clog2(`SHAREMEM_NLANES)                        ;

  wire bankconflict             ;
  reg  bankconflict_reg         ;
  reg  conflict_req_is_write_reg;

  wire [`SHAREMEM_NLANES-1:0]      perlane_req_activemask                                  ;
  wire [`SHAREMEM_BANKIDXBITS-1:0] perlane_req_bankidx               [0:`SHAREMEM_NLANES-1];
  wire [`SHAREMEM_BANKOFFSET-1:0]  perlane_req_bankoffset            [0:`SHAREMEM_NLANES-1];
  wire [`BYTESOFWORD-1:0]          perlane_req_wordoffset1h          [0:`SHAREMEM_NLANES-1];
  wire [`SHAREMEM_NLANES-1:0]      perlane_conf_req_activemask                             ;
  wire [`SHAREMEM_BANKIDXBITS-1:0] perlane_conf_req_bankidx          [0:`SHAREMEM_NLANES-1];
  wire [`SHAREMEM_BANKOFFSET-1:0]  perlane_conf_req_bankoffset       [0:`SHAREMEM_NLANES-1];
  wire [`BYTESOFWORD-1:0]          perlane_conf_req_wordoffset1h     [0:`SHAREMEM_NLANES-1];
  reg  [`SHAREMEM_NLANES-1:0]      perlane_conf_req_activemask_reg                         ;
  reg  [`SHAREMEM_BANKIDXBITS*`SHAREMEM_NLANES-1:0] perlane_conf_req_bankidx_reg     ;
  reg  [`SHAREMEM_BANKOFFSET*`SHAREMEM_NLANES-1:0]  perlane_conf_req_bankoffset_reg  ;
  reg  [`BYTESOFWORD*`SHAREMEM_NLANES-1:0]          perlane_conf_req_wordoffset1h_reg;

  genvar i;
  generate for(i=0;i<`SHAREMEM_NLANES;i=i+1) begin: INPUT_GEN
    assign perlane_req_activemask[i]   = core_req_arb_activemask_i[i] ;
    assign perlane_req_bankidx[i]      = core_req_arb_blockoffset_i[i*`DCACHE_BLOCKOFFSETBITS+`SHAREMEM_BANKIDXBITS-1:i*`DCACHE_BLOCKOFFSETBITS];//i*`SHAREDMEM_BLOCKOFFSETBITS];
    //assign perlane_req_bankidx[i]      = {1'b0,core_req_arb_blockoffset_i[i]};
    assign perlane_req_bankoffset[i]   = BANKOFFSET_ISZERO ? 'd0 : core_req_arb_blockoffset_i[(i+1)*`DCACHE_BLOCKOFFSETBITS-1 -: `SHAREMEM_BANKOFFSET];//i*`SHAREDMEM_BLOCKOFFSETBITS+`SHAREMEM_BANKIDXBITS];
    assign perlane_req_wordoffset1h[i] = core_req_arb_wordoffset1h_i[(i+1)*`BYTESOFWORD-1:i*`BYTESOFWORD];
  end
  endgenerate

  wire                             is_write                              ;
  wire [`SHAREMEM_BANKIDXBITS-1:0] bank_idx        [0:`SHAREMEM_NLANES-1];
  wire [`SHAREMEM_NLANES-1:0]      lane_activemask                       ;
  wire [`SHAREMEM_NBANKS-1:0]      bank_idx1h      [0:`SHAREMEM_NLANES-1];
  wire [`SHAREMEM_NBANKS-1:0]      bank_idxmasked  [0:`SHAREMEM_NLANES-1];

  assign is_write = bankconflict_reg ? conflict_req_is_write_reg : core_req_arb_is_write_i;
  
  genvar j;
  generate for(j=0;j<`SHAREMEM_NLANES;j=j+1) begin: BANK_MASK
    assign bank_idx[j]        = perlane_conf_req_bankidx[j]                           ;
    assign lane_activemask[j] = perlane_conf_req_activemask[j]                        ;
    assign bank_idxmasked[j]  = bank_idx1h[j] & {`SHAREMEM_NBANKS{lane_activemask[j]}};

    bin2one #(
      .ONE_WIDTH (`SHAREMEM_NBANKS     ),
      .BIN_WIDTH (`SHAREMEM_BANKIDXBITS)
    )
    bankidx_bin2one (
      .bin (bank_idx[j]  ),
      .oh  (bank_idx1h[j])
    );

  end
  endgenerate

  wire [`SHAREMEM_NLANES-1:0] perbank_req_bin                  [0:`SHAREMEM_NBANKS-1];
  wire [COUNT_WIDTH-1:0]      perbank_req_count                [0:`SHAREMEM_NBANKS-1];
  wire [`SHAREMEM_NBANKS-1:0] perbank_req_conf                                       ;
  wire [`SHAREMEM_NLANES-1:0] perbank_activelane_when_conf1h   [0:`SHAREMEM_NBANKS-1];
  wire [COUNT_WIDTH-1:0]      perbank_activelane_when_conf_bin [0:`SHAREMEM_NBANKS-1];
  wire [`SHAREMEM_NBANKS-1:0] activelane_when_conf             [0:`SHAREMEM_NLANES-1];

  genvar n,m;
  generate for(n=0;n<`SHAREMEM_NBANKS;n=n+1) begin: COUNT
    for(m=0;m<`SHAREMEM_NLANES;m=m+1) begin: CAT
      assign perbank_req_bin[n][m]      = bank_idxmasked[m][n]                ;
      assign activelane_when_conf[m][n] = perbank_activelane_when_conf1h[n][m];
    end
    
    pop_cnt #(
      .DATA_LEN (`SHAREMEM_NLANES),
      .DATA_WID (COUNT_WIDTH     )
    )
    bankreq_count (
      .data_i (perbank_req_bin[n]  ),
      .data_o (perbank_req_count[n])
    );

    fixed_pri_arb #(
      .ARB_WIDTH (`SHAREMEM_NLANES)
    )
    conf1h (
      .req   (perbank_req_bin[n]               ),
      .grant (perbank_activelane_when_conf1h[n])
    );

    one2bin #(
      .ONE_WIDTH (`SHAREMEM_NLANES),
      .BIN_WIDTH (COUNT_WIDTH     )
    )
    conf_bin (
      .oh  (perbank_activelane_when_conf1h[n]  ),
      .bin (perbank_activelane_when_conf_bin[n])
    );

    assign perbank_req_conf[n] = (perbank_req_count[n] > 1);
  end
  endgenerate

  assign bankconflict = (|perbank_req_conf) && (core_req_arb_enable_i || bankconflict_reg);

  wire [`SHAREMEM_NLANES-1:0] activelane_when_conf1h ;
  wire [`SHAREMEM_NLANES-1:0] reservelane_when_conf1h;

  genvar k;
  generate for(k=0;k<`SHAREMEM_NLANES;k=k+1) begin: ACTIVELANE
    assign activelane_when_conf1h[k]  = |activelane_when_conf[k];
  end
  endgenerate

  assign reservelane_when_conf1h = ~activelane_when_conf1h & lane_activemask;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      bankconflict_reg          <= 'd0;
      conflict_req_is_write_reg <= 'd0;
    end
    else begin
      bankconflict_reg          <= bankconflict                                                      ;
      conflict_req_is_write_reg <= bankconflict ? core_req_arb_is_write_i : conflict_req_is_write_reg;
    end
  end

  genvar x;
  generate for(x=0;x<`SHAREMEM_NLANES;x=x+1) begin: PRELANE_REQ_REG
    assign perlane_conf_req_activemask[x]   = bankconflict_reg ? perlane_conf_req_activemask_reg[x]                                                     : perlane_req_activemask[x]  ;
    assign perlane_conf_req_bankidx[x]      = bankconflict_reg ? perlane_conf_req_bankidx_reg[`SHAREMEM_BANKIDXBITS*(x+1)-1:`SHAREMEM_BANKIDXBITS*x]    : perlane_req_bankidx[x]     ;
    assign perlane_conf_req_bankoffset[x]   = bankconflict_reg ? perlane_conf_req_bankoffset_reg[`SHAREMEM_BANKOFFSET*(x+1)-1:`SHAREMEM_BANKOFFSET*x]   : perlane_req_bankoffset[x]  ;
    assign perlane_conf_req_wordoffset1h[x] = bankconflict_reg ? perlane_conf_req_wordoffset1h_reg[`BYTESOFWORD*(x+1)-1:`BYTESOFWORD*x]                 : perlane_req_wordoffset1h[x];
    
    always@(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        perlane_conf_req_activemask_reg[x]                                                   <= 'd0;
        perlane_conf_req_bankidx_reg[`SHAREMEM_BANKIDXBITS*(x+1)-1:`SHAREMEM_BANKIDXBITS*x]  <= 'd0;
        perlane_conf_req_bankoffset_reg[`SHAREMEM_BANKOFFSET*(x+1)-1:`SHAREMEM_BANKOFFSET*x] <= 'd0;
        perlane_conf_req_wordoffset1h_reg[`BYTESOFWORD*(x+1)-1:`BYTESOFWORD*x]               <= 'd0;
      end
      else begin
        if(reservelane_when_conf1h[x]) begin
          perlane_conf_req_activemask_reg[x]                                                   <= reservelane_when_conf1h[x]      ;
          perlane_conf_req_bankidx_reg[`SHAREMEM_BANKIDXBITS*(x+1)-1:`SHAREMEM_BANKIDXBITS*x]  <= perlane_conf_req_bankidx[x]     ;
          perlane_conf_req_bankoffset_reg[`SHAREMEM_BANKOFFSET*(x+1)-1:`SHAREMEM_BANKOFFSET*x] <= perlane_conf_req_bankoffset[x]  ;
          perlane_conf_req_wordoffset1h_reg[`BYTESOFWORD*(x+1)-1:`BYTESOFWORD*x]               <= perlane_conf_req_wordoffset1h[x];
        end
        else begin
          perlane_conf_req_activemask_reg[x]                                                   <= 1'b0;//perlane_conf_req_activemask_reg[x]  ;
          perlane_conf_req_bankidx_reg[`SHAREMEM_BANKIDXBITS*(x+1)-1:`SHAREMEM_BANKIDXBITS*x]  <= perlane_conf_req_bankidx_reg[`SHAREMEM_BANKIDXBITS*(x+1)-1:`SHAREMEM_BANKIDXBITS*x]     ;
          perlane_conf_req_bankoffset_reg[`SHAREMEM_BANKOFFSET*(x+1)-1:`SHAREMEM_BANKOFFSET*x] <= perlane_conf_req_bankoffset_reg[`SHAREMEM_BANKOFFSET*(x+1)-1:`SHAREMEM_BANKOFFSET*x]  ;
          perlane_conf_req_wordoffset1h_reg[`BYTESOFWORD*(x+1)-1:`BYTESOFWORD*x]               <= perlane_conf_req_wordoffset1h_reg[`BYTESOFWORD*(x+1)-1:`BYTESOFWORD*x];
        end
      end
    end
  end
  endgenerate

  assign active_lane_o  = activelane_when_conf1h;
  assign bankconflict_o = bankconflict          ;
  
  genvar y;
  generate for(y=0;y<`SHAREMEM_NBANKS;y=y+1) begin: OUTPUT_WRITE
    assign data_crsbar_write_sel1h_o[`SHAREMEM_NLANES*(y+1)-1:`SHAREMEM_NLANES*y]            = perbank_activelane_when_conf1h[y]                                 ;
    assign data_crsbar_out_bankoffset_o[`SHAREMEM_BANKOFFSET*(y+1)-1:`SHAREMEM_BANKOFFSET*y] = perlane_conf_req_bankoffset[perbank_activelane_when_conf_bin[y]]  ;
    assign data_crsbar_out_wordoffset1h_o[`BYTESOFWORD*(y+1)-1:`BYTESOFWORD*y]               = perlane_conf_req_wordoffset1h[perbank_activelane_when_conf_bin[y]];
    assign data_array_en_o[y]                                                                = |perbank_activelane_when_conf1h[y]                                ;
  end
  endgenerate

  genvar z;
  generate for(z=0;z<`SHAREMEM_NLANES;z=z+1) begin: OUTPUT_READ
    assign data_crsbar_read_sel1h_o[`SHAREMEM_NBANKS*(z+1)-1:`SHAREMEM_NBANKS*z] = bank_idxmasked[z];
  end
  endgenerate

endmodule

