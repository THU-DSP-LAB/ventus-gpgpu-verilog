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
// Description: Sharemem main module
`timescale 1ns/1ns

`include "define.v"

module shared_mem (
  input                                                 clk                    ,
  input                                                 rst_n                  ,
  input                                                 core_req_valid_i       ,
  output                                                core_req_ready_o       ,
  input  [`WIDBITS-1:0]                                 core_req_instrid_i     ,
  input                                                 core_req_iswrite_i     ,
  input  [`DCACHE_TAGBITS-1:0]                          core_req_tag_i         ,
  input  [`DCACHE_SETIDXBITS-1:0]                       core_req_setidx_i      ,
  input  [`SHAREMEM_NLANES-1:0]                         core_req_activemask_i  ,
  input  [`SHAREMEM_NLANES*`DCACHE_BLOCKOFFSETBITS-1:0] core_req_blockoffset_i ,
  input  [`SHAREMEM_NLANES*`BYTESOFWORD-1:0]            core_req_wordoffset1h_i,
  input  [`SHAREMEM_NLANES*`XLEN-1:0]                   core_req_data_i        ,
  output                                                core_rsp_valid_o       ,
  input                                                 core_rsp_ready_i       ,
  output                                                core_rsp_iswrite_o     ,
  output [`WIDBITS-1:0]                                 core_rsp_instrid_o     ,
  output [`SHAREMEM_NLANES*`XLEN-1:0]                   core_rsp_data_o        ,
  output [`SHAREMEM_NLANES-1:0]                         core_rsp_activemask_o  
);

  localparam SRAM_SET   = `SHAREDMEM_DEPTH*`SHAREDMEM_NWAYS*`SHAREDMEM_BLOCKWORDS/`SHAREMEM_NBANKS;
  localparam SETIDXBITS = $clog2(SRAM_SET);//`DCACHE_SETIDXBITS+`SHAREDMEM_BLOCKOFFSETBITS-`SHAREMEM_BANKIDXBITS     ;
  localparam BANKOFFSET_ISZERO = `DCACHE_BLOCKOFFSETBITS <= `SHAREMEM_BANKIDXBITS;
  localparam RSP_FIFO_DEPTH    = 4;
  localparam RSP_FIFO_CNT_DEPTH= 3;

  //corereq_st0: input reg
  reg                                                core_req_fire_st0        ;
  reg [`WIDBITS-1:0]                                 core_req_instrid_st0     ;
  reg                                                core_req_iswrite_st0     ;
  reg [`DCACHE_TAGBITS-1:0]                          core_req_tag_st0         ;
  reg [`DCACHE_SETIDXBITS-1:0]                       core_req_setidx_st0      ;
  reg [`SHAREMEM_NLANES-1:0]                         core_req_activemask_st0  ;
  reg [`DCACHE_BLOCKOFFSETBITS*`SHAREMEM_NLANES-1:0] core_req_blockoffset_st0 ;
  reg [`BYTESOFWORD*`SHAREMEM_NLANES-1:0]            core_req_wordoffset1h_st0;
  reg [`XLEN*`SHAREMEM_NLANES-1:0]                   core_req_data_st0        ;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      core_req_fire_st0 <= 'd0;
    end
    else begin
      core_req_fire_st0 <= core_req_valid_i && core_req_ready_o;
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      core_req_instrid_st0      <= 'd0;
      core_req_iswrite_st0      <= 'd0;
      core_req_tag_st0          <= 'd0;
      core_req_setidx_st0       <= 'd0;
      core_req_activemask_st0   <= 'd0;
      core_req_blockoffset_st0  <= 'd0;
      core_req_wordoffset1h_st0 <= 'd0;
      core_req_data_st0         <= 'd0;
    end
    else begin
      if(core_req_valid_i && core_req_ready_o) begin
        core_req_instrid_st0      <= core_req_instrid_i     ;
        core_req_iswrite_st0      <= core_req_iswrite_i     ;
        core_req_tag_st0          <= core_req_tag_i         ;
        core_req_setidx_st0       <= core_req_setidx_i      ;
        core_req_activemask_st0   <= core_req_activemask_i  ;
        core_req_blockoffset_st0  <= core_req_blockoffset_i ;
        core_req_wordoffset1h_st0 <= core_req_wordoffset1h_i;
        core_req_data_st0         <= core_req_data_i        ;
      end
      else begin
        core_req_instrid_st0      <= core_req_instrid_st0     ;
        core_req_iswrite_st0      <= core_req_iswrite_st0     ;
        core_req_tag_st0          <= core_req_tag_st0         ;
        core_req_setidx_st0       <= core_req_setidx_st0      ;
        core_req_activemask_st0   <= core_req_activemask_st0  ;
        core_req_blockoffset_st0  <= core_req_blockoffset_st0 ;
        core_req_wordoffset1h_st0 <= core_req_wordoffset1h_st0;
        core_req_data_st0         <= core_req_data_st0        ;
      end
    end
  end

  //corereq_st1
  reg [`WIDBITS-1:0]                                 core_req_instrid_st1     ;
  reg                                                core_req_iswrite_st1     ;
  reg [`DCACHE_TAGBITS-1:0]                          core_req_tag_st1         ;
  reg [`DCACHE_SETIDXBITS-1:0]                       core_req_setidx_st1      ;
  reg [`SHAREMEM_NLANES-1:0]                         core_req_activemask_st1  ;
  reg [`DCACHE_BLOCKOFFSETBITS*`SHAREMEM_NLANES-1:0] core_req_blockoffset_st1 ;
  reg [`BYTESOFWORD*`SHAREMEM_NLANES-1:0]            core_req_wordoffset1h_st1;
  reg [`XLEN*`SHAREMEM_NLANES-1:0]                   core_req_data_st1        ;

  wire [`XLEN-1:0] core_req_data_st1_wire [0:`SHAREMEM_NLANES-1];

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      core_req_instrid_st1    <= 'd0;
      core_req_iswrite_st1    <= 'd0;
      core_req_tag_st1        <= 'd0;
      core_req_setidx_st1     <= 'd0;
      core_req_activemask_st1 <= 'd0;
    end
    else begin
      if(core_req_fire_st0) begin
        core_req_instrid_st1    <= core_req_instrid_st0   ;
        core_req_iswrite_st1    <= core_req_iswrite_st0   ;
        core_req_tag_st1        <= core_req_tag_st0       ;
        core_req_setidx_st1     <= core_req_setidx_st0    ;
        core_req_activemask_st1 <= core_req_activemask_st0;
      end
      else begin
        core_req_instrid_st1    <= core_req_instrid_st1   ;
        core_req_iswrite_st1    <= core_req_iswrite_st1   ;
        core_req_tag_st1        <= core_req_tag_st1       ;
        core_req_setidx_st1     <= core_req_setidx_st1    ;
        core_req_activemask_st1 <= core_req_activemask_st1;
      end
    end
  end

  genvar i;
  generate for(i=0;i<`SHAREMEM_NLANES;i=i+1) begin: COREREQ
    always@(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        core_req_blockoffset_st1[`DCACHE_BLOCKOFFSETBITS*(i+1)-1:`DCACHE_BLOCKOFFSETBITS*i]  <= 'd0;
        core_req_wordoffset1h_st1[`BYTESOFWORD*(i+1)-1:`BYTESOFWORD*i]                       <= 'd0;
        core_req_data_st1[`XLEN*(i+1)-1:`XLEN*i]                                             <= 'd0;
      end
      else begin
        if(core_req_fire_st0) begin
          core_req_blockoffset_st1[`DCACHE_BLOCKOFFSETBITS*(i+1)-1:`DCACHE_BLOCKOFFSETBITS*i]  <= core_req_blockoffset_st0[`DCACHE_BLOCKOFFSETBITS*(i+1)-1:`DCACHE_BLOCKOFFSETBITS*i]; 
          core_req_wordoffset1h_st1[`BYTESOFWORD*(i+1)-1:`BYTESOFWORD*i] <= core_req_wordoffset1h_st0[`BYTESOFWORD*(i+1)-1:`BYTESOFWORD*i];
          core_req_data_st1[`XLEN*(i+1)-1:`XLEN*i] <= core_req_data_st0[`XLEN*(i+1)-1:`XLEN*i];
        end
        else begin
          core_req_blockoffset_st1[`DCACHE_BLOCKOFFSETBITS*(i+1)-1:`DCACHE_BLOCKOFFSETBITS*i]  <= core_req_blockoffset_st1[`DCACHE_BLOCKOFFSETBITS*(i+1)-1:`DCACHE_BLOCKOFFSETBITS*i] ;
          core_req_wordoffset1h_st1[`BYTESOFWORD*(i+1)-1:`BYTESOFWORD*i] <= core_req_wordoffset1h_st1[`BYTESOFWORD*(i+1)-1:`BYTESOFWORD*i];
          core_req_data_st1[`XLEN*(i+1)-1:`XLEN*i] <= core_req_data_st1[`XLEN*(i+1)-1:`XLEN*i];
        end
      end
    end

    assign core_req_data_st1_wire[i] = core_req_data_st1[`XLEN*(i+1)-1:`XLEN*i];
  end
  endgenerate

  wire                                                bankconf_core_req_arb_is_write       ;
  wire                                                bankconf_core_req_arb_enable         ;
  wire [`SHAREMEM_NLANES-1:0]                         bankconf_core_req_arb_activemask     ;
  wire [`SHAREMEM_NLANES*`DCACHE_BLOCKOFFSETBITS-1:0] bankconf_core_req_arb_blockoffset    ;
  wire [`SHAREMEM_NLANES*`BYTESOFWORD-1:0]            bankconf_core_req_arb_wordoffset1h   ;
  wire [`SHAREMEM_NLANES*`SHAREMEM_NBANKS-1:0]        bankconf_data_crsbar_write_sel1h     ;
  wire [`SHAREMEM_NBANKS*`SHAREMEM_NLANES-1:0]        bankconf_data_crsbar_read_sel1h      ;
  wire [`SHAREMEM_NBANKS*`SHAREMEM_BANKOFFSET-1:0]    bankconf_data_crsbar_out_bankoffset  ;
  wire [`SHAREMEM_NBANKS*`BYTESOFWORD-1:0]            bankconf_data_crsbar_out_wordoffset1h;
  wire [`SHAREMEM_NBANKS-1:0]                         bankconf_data_array_en               ;
  wire [`SHAREMEM_NLANES-1:0]                         bankconf_active_lane                 ;
  wire                                                bankconf_bankconflict                ;
  reg                                                 bankconflict_reg                     ;

  assign bankconf_core_req_arb_is_write     = bankconflict_reg ? core_req_iswrite_st1 : core_req_iswrite_st0;
  assign bankconf_core_req_arb_enable       = core_req_fire_st0                                             ;
  assign bankconf_core_req_arb_activemask   = core_req_activemask_st0                                       ;
  assign bankconf_core_req_arb_blockoffset  = core_req_blockoffset_st0                                      ;
  assign bankconf_core_req_arb_wordoffset1h = core_req_wordoffset1h_st0                                     ;

  bankconflict_arb bankconf (
    .clk                            (clk                                  ),
    .rst_n                          (rst_n                                ),
    .core_req_arb_is_write_i        (bankconf_core_req_arb_is_write       ),
    .core_req_arb_enable_i          (bankconf_core_req_arb_enable         ),
    .core_req_arb_activemask_i      (bankconf_core_req_arb_activemask     ),
    .core_req_arb_blockoffset_i     (bankconf_core_req_arb_blockoffset    ),
    .core_req_arb_wordoffset1h_i    (bankconf_core_req_arb_wordoffset1h   ),
    .data_crsbar_write_sel1h_o      (bankconf_data_crsbar_write_sel1h     ),
    .data_crsbar_read_sel1h_o       (bankconf_data_crsbar_read_sel1h      ),
    .data_crsbar_out_bankoffset_o   (bankconf_data_crsbar_out_bankoffset  ),
    .data_crsbar_out_wordoffset1h_o (bankconf_data_crsbar_out_wordoffset1h),
    .data_array_en_o                (bankconf_data_array_en               ),
    .active_lane_o                  (bankconf_active_lane                 ),
    .bankconflict_o                 (bankconf_bankconflict                )
  );

  //pipeline regs
  reg                                             core_req_isvalid_write_st1               ;
  reg                                             core_req_isvalid_read_st1                ;
  reg                                             core_req_isvalid_write_st2               ;
  reg                                             core_req_isvalid_read_st2                ;
  reg                                             core_req_iswrite_st2                     ;
  reg [`WIDBITS-1:0]                              core_req_instrid_st2                     ;
  reg [`SHAREMEM_NLANES-1:0]                      bankconf_activelane_st1                  ;
  reg [`SHAREMEM_NLANES-1:0]                      bankconf_activelane_st2                  ;
  reg [`SHAREMEM_NBANKS-1:0]                      bankconf_data_array_en_st1               ;
  reg [`SHAREMEM_NLANES*`SHAREMEM_NBANKS-1:0]     data_crsbar_write_sel1h_st1              ;
  reg [`SHAREMEM_NBANKS*`SHAREMEM_NLANES-1:0]     data_crsbar_read_sel1h_st1               ;
  reg [`SHAREMEM_NBANKS*`SHAREMEM_NLANES-1:0]     data_crsbar_read_sel1h_st2               ; 
  reg [`SHAREMEM_NBANKS*`SHAREMEM_BANKOFFSET-1:0] bankconf_data_crsbar_out_bankoffset_st1  ;
  reg [`SHAREMEM_NBANKS*`BYTESOFWORD-1:0]         bankconf_data_crsbar_out_wordoffset1h_st1;

  wire [`SHAREMEM_BANKIDXBITS-1:0]    crsbar_sel_for_read  [0:`SHAREMEM_NLANES-1];
  wire [$clog2(`SHAREMEM_NLANES)-1:0] crsbar_sel_for_write [0:`SHAREMEM_NBANKS-1];


  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      bankconflict_reg            <= 'd0;
      core_req_isvalid_write_st1  <= 'd0;
      core_req_isvalid_read_st1   <= 'd0;
      core_req_isvalid_write_st2  <= 'd0;
      core_req_isvalid_read_st2   <= 'd0;
      core_req_iswrite_st2        <= 'd0;
      core_req_instrid_st2        <= 'd0;
      bankconf_activelane_st1     <= 'd0;
      bankconf_activelane_st2     <= 'd0;
      bankconf_data_array_en_st1  <= 'd0;
      bankconf_data_crsbar_out_bankoffset_st1   <= 'd0;
      bankconf_data_crsbar_out_wordoffset1h_st1 <= 'd0;
    end
    else begin
      bankconflict_reg            <= bankconf_bankconflict           ;
      core_req_isvalid_write_st2  <= core_req_isvalid_write_st1      ;
      core_req_isvalid_read_st2   <= core_req_isvalid_read_st1       ;
      core_req_iswrite_st2        <= core_req_iswrite_st1            ;
      core_req_instrid_st2        <= core_req_instrid_st1            ;
      bankconf_activelane_st1     <= bankconf_active_lane            ;
      bankconf_activelane_st2     <= bankconf_activelane_st1         ;
      bankconf_data_array_en_st1  <= bankconf_data_array_en          ;
      core_req_isvalid_write_st1  <= (core_req_fire_st0 && core_req_iswrite_st0) || (core_req_isvalid_write_st1 && bankconflict_reg);
      core_req_isvalid_read_st1   <= (core_req_fire_st0 && !core_req_iswrite_st0) || (core_req_isvalid_read_st1 && bankconflict_reg);
      bankconf_data_crsbar_out_bankoffset_st1   <= bankconf_data_crsbar_out_bankoffset  ;
      bankconf_data_crsbar_out_wordoffset1h_st1 <= bankconf_data_crsbar_out_wordoffset1h;
    end
  end

  wire [`XLEN-1:0]                  data_for_write     [0:`SHAREMEM_NBANKS-1];
  wire [`XLEN-1:0]                  read_data          [0:`SHAREMEM_NBANKS-1];
  wire [`XLEN*-1:0]                 read_data_st2_wire [0:`SHAREMEM_NBANKS-1];
  reg  [SETIDXBITS-1:0]             write_setidx       [0:`SHAREMEM_NBANKS-1];
  reg  [SETIDXBITS-1:0]             read_setidx        [0:`SHAREMEM_NBANKS-1];
  reg  [`XLEN*`SHAREMEM_NBANKS-1:0] read_data_st2                            ;

  wire read_data_valid;
  assign read_data_valid = (core_req_fire_st0 && !core_req_iswrite_st0) || (core_req_isvalid_read_st1 && bankconflict_reg);

  wire [`BABITS-1:0]    core_req_ba_st0         ;
  wire [`BABITS-1:0]    core_req_ba_st1         ;
  wire [SETIDXBITS-1:0] core_req_setidx_bank_st0;
  wire [SETIDXBITS-1:0] core_req_setidx_bank_st1;

  assign core_req_ba_st0          = {core_req_tag_st0,core_req_setidx_st0};
  assign core_req_ba_st1          = {core_req_tag_st1,core_req_setidx_st1};
  assign core_req_setidx_bank_st0 = core_req_ba_st0[SETIDXBITS-1:0]       ;
  assign core_req_setidx_bank_st1 = core_req_ba_st1[SETIDXBITS-1:0]       ;

  genvar j;
  generate for(j=0;j<`SHAREMEM_NBANKS;j=j+1) begin: SRAM_IN
    assign data_for_write[j] = core_req_data_st1_wire[crsbar_sel_for_write[j]];

    always@(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        data_crsbar_write_sel1h_st1[`SHAREMEM_NLANES*(j+1)-1:`SHAREMEM_NLANES*j] <= 'd0;
      end
      else begin
        data_crsbar_write_sel1h_st1[`SHAREMEM_NLANES*(j+1)-1:`SHAREMEM_NLANES*j] <= bankconf_data_crsbar_write_sel1h[`SHAREMEM_NLANES*(j+1)-1:`SHAREMEM_NLANES*j];
      end
    end

    one2bin #(
      .ONE_WIDTH (`SHAREMEM_NLANES        ),
      .BIN_WIDTH ($clog2(`SHAREMEM_NLANES))
    )
    sel_write (
      .oh  (data_crsbar_write_sel1h_st1[`SHAREMEM_NLANES*(j+1)-1:`SHAREMEM_NLANES*j]),
      .bin (crsbar_sel_for_write[j]                                                 )
    );
    
    always@(*) begin
      if(BANKOFFSET_ISZERO) begin
        write_setidx[j] = core_req_setidx_bank_st1;
        read_setidx[j]  = core_req_setidx_bank_st0;
      end
      else begin
        write_setidx[j] = {core_req_setidx_bank_st1,bankconf_data_crsbar_out_bankoffset_st1[`SHAREMEM_BANKOFFSET*(j+1)-1:`SHAREMEM_BANKOFFSET*j]};
        read_setidx[j]  = {core_req_setidx_bank_st0,bankconf_data_crsbar_out_bankoffset[`SHAREMEM_BANKOFFSET*(j+1)-1:`SHAREMEM_BANKOFFSET*j]}      ;
      end
    end

    sram_template #(
      .GEN_WIDTH (8           ),
      .NUM_SET   (SRAM_SET    ),
      .NUM_WAY   (`BYTESOFWORD),
      .SET_DEPTH (SETIDXBITS  )
    )
    data_access (
      .clk             (clk                                                                           ),
      .rst_n           (rst_n                                                                         ),
      .r_req_valid_i   (read_data_valid                                                               ),
      .r_req_setid_i   (read_setidx[j]                                                                ),
      .r_resp_data_o   (read_data[j]                                                                  ),
      .w_req_valid_i   (core_req_isvalid_write_st1 && bankconf_data_array_en_st1[j]                   ),
      .w_req_setid_i   (write_setidx[j]                                                               ),
      .w_req_waymask_i (bankconf_data_crsbar_out_wordoffset1h_st1[`BYTESOFWORD*(j+1)-1:`BYTESOFWORD*j]),
      .w_req_data_i    (data_for_write[j]                                                             )
    );

    always@(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        read_data_st2[`XLEN*(j+1)-1:`XLEN*j] <= 'd0;
      end
      else begin
        read_data_st2[`XLEN*(j+1)-1:`XLEN*j] <= read_data[j];
      end
    end

    assign read_data_st2_wire[j] = read_data_st2[`XLEN*(j+1)-1:`XLEN*j];
      
  end
  endgenerate

  wire [`XLEN-1:0] data_crsbar_out [0:`SHAREMEM_NLANES-1];

  genvar k;
  generate for(k=0;k<`SHAREMEM_NLANES;k=k+1) begin: SRAM_OUT
    always@(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        data_crsbar_read_sel1h_st1[`SHAREMEM_NBANKS*(k+1)-1:`SHAREMEM_NBANKS*k] <= 'd0;
        data_crsbar_read_sel1h_st2[`SHAREMEM_NBANKS*(k+1)-1:`SHAREMEM_NBANKS*k] <= 'd0;
      end
      else begin
        data_crsbar_read_sel1h_st1[`SHAREMEM_NBANKS*(k+1)-1:`SHAREMEM_NBANKS*k] <= bankconf_data_crsbar_read_sel1h[`SHAREMEM_NBANKS*(k+1)-1:`SHAREMEM_NBANKS*k];
        data_crsbar_read_sel1h_st2[`SHAREMEM_NBANKS*(k+1)-1:`SHAREMEM_NBANKS*k] <= data_crsbar_read_sel1h_st1[`SHAREMEM_NBANKS*(k+1)-1:`SHAREMEM_NBANKS*k]     ;
      end
    end

    one2bin #(
      .ONE_WIDTH (`SHAREMEM_NBANKS     ),
      .BIN_WIDTH (`SHAREMEM_BANKIDXBITS)
    )
    sel_write (
      .oh  (data_crsbar_read_sel1h_st2[`SHAREMEM_NBANKS*(k+1)-1:`SHAREMEM_NBANKS*k]),
      .bin (crsbar_sel_for_read[k]                                                 )
    );

    assign data_crsbar_out[k] = read_data_st2_wire[crsbar_sel_for_read[k]];
  end
  endgenerate

  wire                                                      rsp_q_enq_valid;
  wire                                                      rsp_q_enq_ready;
  wire [`WIDBITS+`SHAREMEM_NLANES+`SHAREMEM_NLANES*`XLEN:0] rsp_q_enq_bits ;
  wire [`WIDBITS+`SHAREMEM_NLANES+`SHAREMEM_NLANES*`XLEN:0] rsp_q_deq_bits ;
  wire [RSP_FIFO_CNT_DEPTH-1:0]                             rsp_q_count    ;
  wire                                                      rsp_q_alm_full ;

  genvar n;
  generate for(n=0;n<`SHAREMEM_NLANES;n=n+1) begin: RSP_DATA
    assign rsp_q_enq_bits[`XLEN*(n+1)-1:`XLEN*n] = data_crsbar_out[n];
  end
  endgenerate

  assign rsp_q_enq_valid = core_req_isvalid_read_st2 || core_req_isvalid_write_st2;
  assign rsp_q_enq_bits[`WIDBITS+`SHAREMEM_NLANES+`SHAREMEM_NLANES*`XLEN:`SHAREMEM_NLANES*`XLEN] = {core_req_iswrite_st2,core_req_instrid_st2,bankconf_activelane_st2};

  stream_fifo_pipe_true_with_count #(
    .DATA_WIDTH (1+`WIDBITS+`SHAREMEM_NLANES+`SHAREMEM_NLANES*`XLEN),
    .FIFO_DEPTH (RSP_FIFO_DEPTH                                    ),
    .CNT_WIDTH  (RSP_FIFO_CNT_DEPTH                                )
  )
  core_rsp_q (
    .clk       (clk             ),
    .rst_n     (rst_n           ),
    .w_ready_o (rsp_q_enq_ready ),
    .w_valid_i (rsp_q_enq_valid ),
    .w_data_i  (rsp_q_enq_bits  ),
    .r_valid_o (core_rsp_valid_o),
    .r_ready_i (core_rsp_ready_i),
    .r_data_o  (rsp_q_deq_bits  ),
    .count_o   (rsp_q_count     )
  );

  assign rsp_q_alm_full        = rsp_q_count == (RSP_FIFO_DEPTH - 3)                                ;
  assign core_req_ready_o      = !bankconflict_reg && !rsp_q_alm_full && !core_req_isvalid_write_st1;
  assign core_rsp_iswrite_o    = rsp_q_deq_bits[`WIDBITS+`SHAREMEM_NLANES+`SHAREMEM_NLANES*`XLEN]   ;
  assign core_rsp_instrid_o    = rsp_q_deq_bits[`WIDBITS+`SHAREMEM_NLANES+`SHAREMEM_NLANES*`XLEN-1:`SHAREMEM_NLANES+`SHAREMEM_NLANES*`XLEN];
  assign core_rsp_activemask_o = rsp_q_deq_bits[`SHAREMEM_NLANES+`SHAREMEM_NLANES*`XLEN-1:`SHAREMEM_NLANES*`XLEN];
  assign core_rsp_data_o       = rsp_q_deq_bits[`SHAREMEM_NLANES*`XLEN-1:0];

endmodule

