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
// Description: L1 DCache main module

`timescale 1ns/1ns

`include "define.v"
//`include "l1dcache_define.v"

module l1_dcache (
  input                                                     clk                    ,
  input                                                     rst_n                  ,
  //coreReq
  input                                                     core_req_valid_i       ,
  output                                                    core_req_ready_o       ,
  input  [`WIDBITS-1:0]                                     core_req_instrid_i     ,
  input  [`DCACHE_SETIDXBITS-1:0]                           core_req_setidx_i      ,
  input  [`DCACHE_TAGBITS-1:0]                              core_req_tag_i         ,
  input  [`DCACHE_NLANES-1:0]                               core_req_activemask_i  ,
  input  [`DCACHE_NLANES*`DCACHE_BLOCKOFFSETBITS-1:0]       core_req_blockoffset_i ,
  input  [`DCACHE_NLANES*`BYTESOFWORD-1:0]                  core_req_wordoffset1h_i,
  input  [`DCACHE_NLANES*`XLEN-1:0]                         core_req_data_i        ,
  input  [2:0]                                              core_req_opcode_i      ,
  input  [3:0]                                              core_req_param_i       ,
  //coreRsp
  output                                                    core_rsp_valid_o       ,
  input                                                     core_rsp_ready_i       ,
  output                                                    core_rsp_is_write_o    ,
  output [`WIDBITS-1:0]                                     core_rsp_instrid_o     ,
  output [`DCACHE_NLANES*`XLEN-1:0]                         core_rsp_data_o        ,
  output [`DCACHE_NLANES-1:0]                               core_rsp_activemask_o  ,
  //memRsp
  input                                                     mem_rsp_valid_i        ,
  output                                                    mem_rsp_ready_o        ,
  input  [2:0]                                              mem_rsp_d_opcode_i     ,
  input  [2+$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS:0] mem_rsp_d_source_i     ,
  input  [`XLEN-1:0]                                        mem_rsp_d_addr_i       ,
  input  [`DCACHE_BLOCKWORDS*`XLEN-1:0]                     mem_rsp_d_data_i       ,
  //memReq
  output                                                    mem_req_valid_o        ,
  input                                                     mem_req_ready_i        ,
  output [2:0]                                              mem_req_a_opcode_o     ,
  output [2:0]                                              mem_req_a_param_o      ,
  output [2+$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS:0] mem_req_a_source_o     ,
  output [`XLEN-1:0]                                        mem_req_a_addr_o       ,
  output [`DCACHE_BLOCKWORDS*`XLEN-1:0]                     mem_req_a_data_o       ,
  output [`DCACHE_BLOCKWORDS*`BYTESOFWORD-1:0]              mem_req_a_mask_o       
);

  localparam CORE_RSP_Q_ENTRIES = `DCACHE_NLANES                       ;
  localparam SRAM_NSETS         = `DCACHE_NSETS * `DCACHE_NWAYS        ;
  localparam SRAM_SETIDXBITS    = $clog2(SRAM_NSETS)                   ;
  localparam WM_ENTRY_EQUAL     = `DCACHE_MSHRENTRY==`DCACHE_WSHR_ENTRY;

  //Queue: coreReq_Q
  wire core_req_enq_valid;
  wire core_req_enq_ready;
  wire core_req_deq_valid;
  wire core_req_deq_ready;
  wire [`WIDBITS+`DCACHE_SETIDXBITS+`DCACHE_TAGBITS+`DCACHE_NLANES+`DCACHE_NLANES*`DCACHE_BLOCKOFFSETBITS+`DCACHE_NLANES*`BYTESOFWORD+`DCACHE_NLANES*`XLEN+6:0] core_req_enq_bits;
  wire [`WIDBITS+`DCACHE_SETIDXBITS+`DCACHE_TAGBITS+`DCACHE_NLANES+`DCACHE_NLANES*`DCACHE_BLOCKOFFSETBITS+`DCACHE_NLANES*`BYTESOFWORD+`DCACHE_NLANES*`XLEN+6:0] core_req_deq_bits;

  assign core_req_enq_bits = {core_req_instrid_i     ,
                              core_req_setidx_i      ,
                              core_req_tag_i         ,
                              core_req_activemask_i  ,
                              core_req_blockoffset_i ,
                              core_req_wordoffset1h_i,
                              core_req_data_i        ,
                              core_req_opcode_i      ,
                              core_req_param_i       };

  stream_fifo_pipe_true #(
    .DATA_WIDTH (`WIDBITS+`DCACHE_SETIDXBITS+`DCACHE_TAGBITS+`DCACHE_NLANES+`DCACHE_NLANES*`DCACHE_BLOCKOFFSETBITS+`DCACHE_NLANES*`BYTESOFWORD+`DCACHE_NLANES*`XLEN+7),
    .FIFO_DEPTH (1)
  )
  core_req_q (
    .clk       (clk               ),
    .rst_n     (rst_n             ),
    .w_ready_o (core_req_enq_ready),
    .w_valid_i (core_req_enq_valid),
    .w_data_i  (core_req_enq_bits ),
    .r_valid_o (core_req_deq_valid),
    .r_ready_i (core_req_deq_ready),
    .r_data_o  (core_req_deq_bits )
  );

  //Queue: coreReq_st1
  wire [`WIDBITS-1:0]                               core_req_instrid_st1     ;
  wire [`DCACHE_SETIDXBITS-1:0]                     core_req_setidx_st1      ;
  wire [`DCACHE_TAGBITS-1:0]                        core_req_tag_st1         ;
  wire [`DCACHE_NLANES-1:0]                         core_req_activemask_st1  ;
  wire [`DCACHE_NLANES*`DCACHE_BLOCKOFFSETBITS-1:0] core_req_blockoffset_st1 ;
  wire [`DCACHE_NLANES*`BYTESOFWORD-1:0]            core_req_wordoffset1h_st1;
  wire [`DCACHE_NLANES*`XLEN-1:0]                   core_req_data_st1        ;
  wire [2:0]                                        core_req_opcode_st1      ;
  wire [3:0]                                        core_req_param_st1       ;

  assign core_req_instrid_st1      = core_req_deq_bits[`WIDBITS+`DCACHE_SETIDXBITS+`DCACHE_TAGBITS+`DCACHE_NLANES+`DCACHE_NLANES*`DCACHE_BLOCKOFFSETBITS+`DCACHE_NLANES*`BYTESOFWORD+`DCACHE_NLANES*`XLEN+6:`DCACHE_SETIDXBITS+`DCACHE_TAGBITS+`DCACHE_NLANES+`DCACHE_NLANES*`DCACHE_BLOCKOFFSETBITS+`DCACHE_NLANES*`BYTESOFWORD+`DCACHE_NLANES*`XLEN+7];
  assign core_req_setidx_st1       = core_req_deq_bits[`DCACHE_SETIDXBITS+`DCACHE_TAGBITS+`DCACHE_NLANES+`DCACHE_NLANES*`DCACHE_BLOCKOFFSETBITS+`DCACHE_NLANES*`BYTESOFWORD+`DCACHE_NLANES*`XLEN+6:`DCACHE_TAGBITS+`DCACHE_NLANES+`DCACHE_NLANES*`DCACHE_BLOCKOFFSETBITS+`DCACHE_NLANES*`BYTESOFWORD+`DCACHE_NLANES*`XLEN+7];
  assign core_req_tag_st1          = core_req_deq_bits[`DCACHE_TAGBITS+`DCACHE_NLANES+`DCACHE_NLANES*`DCACHE_BLOCKOFFSETBITS+`DCACHE_NLANES*`BYTESOFWORD+`DCACHE_NLANES*`XLEN+6:`DCACHE_NLANES+`DCACHE_NLANES*`DCACHE_BLOCKOFFSETBITS+`DCACHE_NLANES*`BYTESOFWORD+`DCACHE_NLANES*`XLEN+7];
  assign core_req_activemask_st1   = core_req_deq_bits[`DCACHE_NLANES+`DCACHE_NLANES*`DCACHE_BLOCKOFFSETBITS+`DCACHE_NLANES*`BYTESOFWORD+`DCACHE_NLANES*`XLEN+6:`DCACHE_NLANES*`DCACHE_BLOCKOFFSETBITS+`DCACHE_NLANES*`BYTESOFWORD+`DCACHE_NLANES*`XLEN+7];
  assign core_req_blockoffset_st1  = core_req_deq_bits[`DCACHE_NLANES*`DCACHE_BLOCKOFFSETBITS+`DCACHE_NLANES*`BYTESOFWORD+`DCACHE_NLANES*`XLEN+6:`DCACHE_NLANES*`BYTESOFWORD+`DCACHE_NLANES*`XLEN+7];
  assign core_req_wordoffset1h_st1 = core_req_deq_bits[`DCACHE_NLANES*`BYTESOFWORD+`DCACHE_NLANES*`XLEN+6:`DCACHE_NLANES*`XLEN+7];
  assign core_req_data_st1         = core_req_deq_bits[`DCACHE_NLANES*`XLEN+6:7];
  assign core_req_opcode_st1       = core_req_deq_bits[6:4];
  assign core_req_param_st1        = core_req_deq_bits[3:0];

  //tag access
  wire                                        tag_probeRead_valid               ;
  wire                                        tag_probeRead_ready               ;
  wire [`DCACHE_SETIDXBITS-1:0]               tag_probeRead_setIdx              ;
  wire [`DCACHE_TAGBITS-1:0]                  tag_tagFromCore_st1               ;
  wire                                        tag_probeIsWrite_st1              ;
  wire                                        tag_coreReq_q_deq_fire            ;
  wire                                        tag_hit_st1                       ;
  wire [`DCACHE_NWAYS-1:0]                    tag_waymaskHit_st1                ;
  wire                                        tag_allocateWrite_valid           ;
  wire [`DCACHE_SETIDXBITS-1:0]               tag_allocateWrite_setIdx          ;
  wire [`DCACHE_TAGBITS-1:0]                  tag_allocateWriteData_st1         ;
  wire                                        tag_mem_req_fire                  ;
  wire                                        tag_allocateWriteTagSRAMWValid_st1;
  wire                                        tag_needReplace                   ;
  wire [`DCACHE_NWAYS-1:0]                    tag_waymaskReplacement_st1        ;
  wire [`XLEN-1:0]                            tag_addrReplacement_st1           ;
  wire                                        tag_hasDirty_st0                  ;
  wire [`DCACHE_SETIDXBITS-1:0]               tag_dirtySetIdx_st0               ;
  wire [$clog2(`DCACHE_NWAYS)-1:0]            tag_dirtyWayMask_st0              ;
  wire [`DCACHE_TAGBITS-1:0]                  tag_dirtyTag_st1                  ;
  wire                                        tag_flushChoosen_valid            ;
  wire [`DCACHE_SETIDXBITS+`DCACHE_NWAYS-1:0] tag_flushChoosen                  ;
  wire                                        tag_invalidateAll                 ;
  wire                                        tag_tagready_st1                  ;

  tag_access_top_v2 #(
    .NUM_SET  (`DCACHE_NSETS  ),
    .NUM_WAY  (`DCACHE_NWAYS  ),
    .TAG_BITS (`DCACHE_TAGBITS)
  )
  tagaccess (
    .clk                              (clk                               ),
    .rst_n                            (rst_n                             ),
    .probeRead_valid_i                (tag_probeRead_valid               ),
    .probeRead_ready_o                (tag_probeRead_ready               ),
    .probeRead_setIdx_i               (tag_probeRead_setIdx              ),
    .tagFromCore_st1_i                (tag_tagFromCore_st1               ),
    .probeIsWrite_st1_i               (tag_probeIsWrite_st1              ),
    .coreReq_q_deq_fire_i             (tag_coreReq_q_deq_fire            ),
    .hit_st1_o                        (tag_hit_st1                       ),
    .waymaskHit_st1_o                 (tag_waymaskHit_st1                ),
    .allocateWrite_valid_i            (tag_allocateWrite_valid           ),
    .allocateWrite_setIdx_i           (tag_allocateWrite_setIdx          ),
    .allocateWriteData_st1_i          (tag_allocateWriteData_st1         ),
    .mem_req_fire_i                   (tag_mem_req_fire                  ),
    .allocateWriteTagSRAMWValid_st1_i (tag_allocateWriteTagSRAMWValid_st1),
    .needReplace_o                    (tag_needReplace                   ),
    .waymaskReplacement_st1_o         (tag_waymaskReplacement_st1        ),
    .addrReplacement_st1_o            (tag_addrReplacement_st1           ),
    .hasDirty_st0_o                   (tag_hasDirty_st0                  ),
    .dirtySetIdx_st0_o                (tag_dirtySetIdx_st0               ),
    .dirtyWayMask_st0_o               (tag_dirtyWayMask_st0              ),
    .dirtyTag_st1_o                   (tag_dirtyTag_st1                  ),
    .flushChoosen_valid_i             (tag_flushChoosen_valid            ),
    .flushChoosen_i                   (tag_flushChoosen                  ),
    .invalidateAll_i                  (tag_invalidateAll                 ),
    .tagready_st1_i                   (tag_tagready_st1                  )
  );

  //mshr
  wire                                 mshr_probe_valid           ;
  wire [`BABITS-1:0]                   mshr_probe_blockaddr       ;
  wire                                 mshr_missreq_valid         ;
  wire                                 mshr_missreq_ready         ;
  wire [`BABITS-1:0]                   mshr_missreq_blockaddr     ;
  wire [`TIWIDTH-1:0]                  mshr_missreq_targetinfo    ;
  wire                                 mshr_missrsp_in_valid      ;
  wire                                 mshr_missrsp_in_ready      ;
  wire [$clog2(`DCACHE_MSHRENTRY)-1:0] mshr_missrsp_in_instrid    ;
  wire                                 mshr_missrsp_out_valid     ;
  wire [`BABITS-1:0]                   mshr_missrsp_out_blockaddr ;
  wire [`TIWIDTH-1:0]                  mshr_missrsp_out_targetinfo;
  wire                                 mshr_empty                 ;
  wire                                 mshr_probe_status          ;
  wire [2:0]                           mshr_mshr_status_st0       ;
  wire [2:0]                           mshr_probe_out_mshr_status ;
  wire [$clog2(`DCACHE_MSHRENTRY)-1:0] mshr_probe_out_a_source    ;
  wire                                 mshr_stage1_ready          ;
  wire                                 mshr_stage2_ready          ;

  l1_mshr mshraccess (
    .clk                      (clk                        ),
    .rst_n                    (rst_n                      ),
    .probe_valid_i            (mshr_probe_valid           ),
    .probe_blockaddr_i        (mshr_probe_blockaddr       ),
    .missreq_valid_i          (mshr_missreq_valid         ),
    .missreq_ready_o          (mshr_missreq_ready         ),
    .missreq_blockaddr_i      (mshr_missreq_blockaddr     ),
    .missreq_targetinfo_i     (mshr_missreq_targetinfo    ),
    .missrsp_in_valid_i       (mshr_missrsp_in_valid      ),
    .missrsp_in_ready_o       (mshr_missrsp_in_ready      ),
    .missrsp_in_instrid_i     (mshr_missrsp_in_instrid    ),
    .missrsp_out_valid_o      (mshr_missrsp_out_valid     ),
    .missrsp_out_blockaddr_o  (mshr_missrsp_out_blockaddr ),
    .missrsp_out_targetinfo_o (mshr_missrsp_out_targetinfo),
    .empty_o                  (mshr_empty                 ),
    .probe_status_o           (mshr_probe_status          ),
    .mshr_status_st0_o        (mshr_mshr_status_st0       ),
    .probe_out_mshr_status_o  (mshr_probe_out_mshr_status ),
    .probe_out_a_source_o     (mshr_probe_out_a_source    ),
    .stage1_ready_i           (mshr_stage1_ready          ),
    .stage2_ready_i           (mshr_stage2_ready          )
  );

  //indicate read/write miss/hit
  wire cache_hit_st1 ;
  wire cache_miss_st1;
  wire read_hit_st1  ;
  wire read_miss_st1 ;
  wire write_hit_st1 ;
  wire write_miss_st1;

  //for handshake
  reg  inflight_read_write_miss    ;

  wire readmiss_same_addr          ;
  wire proberead_allocatewrite_conf;
  wire inflight_read_write_miss_w  ;

  //these handshake signals indicate: when the memRsp comes, whether the coreReq is blocked
  wire core_req_st0_ready          ;
  //wire core_req_st0_valid          ;
  reg  core_req_st1_ready          ;
  wire core_req_st1_valid          ;
  

  //coreReq handshake signals
  assign core_req_enq_valid = core_req_valid_i && core_req_ready_o && !proberead_allocatewrite_conf && tag_probeRead_ready && (mshr_mshr_status_st0!=3'b011) && (mshr_mshr_status_st0!=3'b001);
  assign core_req_deq_ready = core_req_st1_ready && !((core_req_opcode_st1==4'b0011)&&read_hit_st1&&core_req_st1_valid);

  //core_req_st0 ready
  assign core_req_st0_ready = core_req_enq_ready && !proberead_allocatewrite_conf && !inflight_read_write_miss_w && !readmiss_same_addr && tag_probeRead_ready && (mshr_mshr_status_st0!=3'b011) && (mshr_mshr_status_st0!=3'b001);

  //secondary full return
  reg secondary_full_return;
  
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      secondary_full_return <= 'd0;
    end
    else begin
      secondary_full_return <= (mshr_probe_out_mshr_status==3'b100);
    end
  end

  //control signals: st0
  wire is_read_noen      ;
  wire is_write_noen     ;
  wire is_lr_noen        ;
  wire is_sc_noen        ;
  wire is_amo_noen       ;
  wire is_flush_noen     ;
  wire is_invalidate_noen;
  wire is_wait_mshr_noen ;

  wire is_read_st0      ;
  wire is_write_st0     ;
  wire is_lr_st0        ;
  wire is_sc_st0        ;
  wire is_amo_st0       ;
  wire is_flush_st0     ;
  wire is_invalidate_st0;
  wire is_wait_mshr_st0 ;

  dcache_control control_gen (
    .opcode        (core_req_opcode_i ),
    .param         (core_req_param_i  ),
    .is_read       (is_read_noen      ),
    .is_write      (is_write_noen     ),
    .is_lr         (is_lr_noen        ),
    .is_sc         (is_sc_noen        ),
    .is_amo        (is_amo_noen       ),
    .is_flush      (is_flush_noen     ),
    .is_invalidate (is_invalidate_noen),
    .is_wait_mshr  (is_wait_mshr_noen )
  );

  assign is_read_st0       = (core_req_valid_i&&core_req_ready_o) ? is_read_noen       : 'd0;
  assign is_write_st0      = (core_req_valid_i&&core_req_ready_o) ? is_write_noen      : 'd0;
  assign is_lr_st0         = (core_req_valid_i&&core_req_ready_o) ? is_lr_noen         : 'd0;
  assign is_sc_st0         = (core_req_valid_i&&core_req_ready_o) ? is_sc_noen         : 'd0;
  assign is_amo_st0        = (core_req_valid_i&&core_req_ready_o) ? is_amo_noen        : 'd0;
  assign is_flush_st0      = (core_req_valid_i&&core_req_ready_o) ? is_flush_noen      : 'd0;
  assign is_invalidate_st0 = (core_req_valid_i&&core_req_ready_o) ? is_invalidate_noen : 'd0;
  assign is_wait_mshr_st0  = (core_req_valid_i&&core_req_ready_o) ? is_wait_mshr_noen  : 'd0;

  //Queue: coreReqControl_st1_Q
  wire is_read_st1      ;
  wire is_write_st1     ;
  wire is_lr_st1        ;
  wire is_sc_st1        ;
  wire is_amo_st1       ;
  wire is_flush_st1     ;
  wire is_invalidate_st1;
  wire is_wait_mshr_st1 ;

  wire       core_req_control_st1_enq_valid;
  wire       core_req_control_st1_enq_ready;
  wire [7:0] core_req_control_st1_enq_bits ;
  wire       core_req_control_st1_deq_valid;
  wire       core_req_control_st1_deq_ready;
  wire [7:0] core_req_control_st1_deq_bits ;

  assign core_req_control_st1_enq_bits = {is_read_st0      ,
                                          is_write_st0     ,
                                          is_lr_st0        ,
                                          is_sc_st0        ,
                                          is_amo_st0       ,
                                          is_flush_st0     ,
                                          is_invalidate_st0,
                                          is_wait_mshr_st0 };

  stream_fifo_pipe_true #(
    .DATA_WIDTH (8),
    .FIFO_DEPTH (1)
  )
  core_req_control_st1_q (
    .clk       (clk                           ),
    .rst_n     (rst_n                         ),
    .w_ready_o (core_req_control_st1_enq_ready),
    .w_valid_i (core_req_control_st1_enq_valid),
    .w_data_i  (core_req_control_st1_enq_bits ),
    .r_valid_o (core_req_control_st1_deq_valid),
    .r_ready_i (core_req_control_st1_deq_ready),
    .r_data_o  (core_req_control_st1_deq_bits )
  );

  assign is_read_st1       = core_req_control_st1_deq_bits[7];
  assign is_write_st1      = core_req_control_st1_deq_bits[6];
  assign is_lr_st1         = core_req_control_st1_deq_bits[5];
  assign is_sc_st1         = core_req_control_st1_deq_bits[4];
  assign is_amo_st1        = core_req_control_st1_deq_bits[3];
  assign is_flush_st1      = core_req_control_st1_deq_bits[2];
  assign is_invalidate_st1 = core_req_control_st1_deq_bits[1];
  assign is_wait_mshr_st1  = core_req_control_st1_deq_bits[0];

  //handshake signals: coreReqControl_st1_Q
  assign core_req_control_st1_enq_valid = core_req_valid_i && core_req_ready_o;
  assign core_req_control_st1_deq_ready = core_req_st1_ready                  ;
  assign core_req_control_st1_deq_fire  = core_req_control_st1_deq_valid && core_req_control_st1_deq_ready;

  //RegNext(inject_tag_probe), after inflightReadWriteMiss come back, use it;
  reg inject_tag_probe_reg             ;
  reg core_req_control_st1_deq_fire_reg;
  
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      core_req_control_st1_deq_fire_reg <= 'd0;
    end
    else begin
      core_req_control_st1_deq_fire_reg <= core_req_control_st1_deq_fire;
    end
  end  
  
  //connect hit/miss signals
  assign cache_hit_st1  = tag_hit_st1                                                    ;
  assign cache_miss_st1 = !tag_hit_st1                                                   ;
  assign read_hit_st1   = cache_hit_st1 && is_read_st1 && core_req_control_st1_deq_fire  ;
  assign read_miss_st1  = cache_miss_st1 && is_read_st1 && core_req_control_st1_deq_fire ;
  assign write_hit_st1  = cache_hit_st1 && is_write_st1 && (inject_tag_probe_reg ? core_req_control_st1_deq_fire_reg : core_req_control_st1_deq_fire);
  assign write_miss_st1 = cache_miss_st1 && is_write_st1 && core_req_control_st1_deq_fire;

  //Queue: coreRsp_st2_valid_from_coreReq_Reg
  wire core_rsp_from_core_st2_enq_valid;
  wire core_rsp_from_core_st2_enq_ready;
  wire core_rsp_from_core_st2_enq_bits ;
  wire core_rsp_from_core_st2_deq_valid;
  wire core_rsp_from_core_st2_deq_ready;
  wire core_rsp_from_core_st2_deq_bits ;

  stream_fifo_pipe_true #(
    .DATA_WIDTH (1),
    .FIFO_DEPTH (1)
  )
  core_rsp_from_core_st2 (
    .clk       (clk                             ),
    .rst_n     (rst_n                           ),
    .w_ready_o (core_rsp_from_core_st2_enq_ready),
    .w_valid_i (core_rsp_from_core_st2_enq_valid),
    .w_data_i  (core_rsp_from_core_st2_enq_bits ),
    .r_valid_o (core_rsp_from_core_st2_deq_valid),
    .r_ready_i (core_rsp_from_core_st2_deq_ready),
    .r_data_o  (core_rsp_from_core_st2_deq_bits )
  );

  //Queue: core_rsp_st2
  reg                                                   core_rsp_st2_enq_valid;//comb logic
  wire                                                  core_rsp_st2_enq_ready;
  wire [`WIDBITS+`DCACHE_NLANES*`XLEN+`DCACHE_NLANES:0] core_rsp_st2_enq_bits ;
  wire                                                  core_rsp_st2_deq_valid;
  wire                                                  core_rsp_st2_deq_ready;
  wire [`WIDBITS+`DCACHE_NLANES*`XLEN+`DCACHE_NLANES:0] core_rsp_st2_deq_bits ;

  stream_fifo_pipe_true #(
    .DATA_WIDTH (`WIDBITS+`DCACHE_NLANES*`XLEN+`DCACHE_NLANES+1),
    .FIFO_DEPTH (2)
  )
  core_rsp_st2 (
    .clk       (clk                   ),
    .rst_n     (rst_n                 ),
    .w_ready_o (core_rsp_st2_enq_ready),
    .w_valid_i (core_rsp_st2_enq_valid),
    .w_data_i  (core_rsp_st2_enq_bits ),
    .r_valid_o (core_rsp_st2_deq_valid),
    .r_ready_i (core_rsp_st2_deq_ready),
    .r_data_o  (core_rsp_st2_deq_bits )
  );

  //for coreRsp: st2 signals
  wire core_rsp_st2_valid;

  reg [`DCACHE_NLANES-1:0]                         core_rsp_st2_activemask  ;
  reg [`DCACHE_NLANES*`DCACHE_BLOCKOFFSETBITS-1:0] core_rsp_st2_blockoffset ;
  reg [`DCACHE_NLANES*`BYTESOFWORD-1:0]            core_rsp_st2_wordoffset1h;

  //Queue: readHit_st2
  wire read_hit_st2_enq_valid;
  wire read_hit_st2_enq_ready;
  wire read_hit_st2_enq_bits ;
  wire read_hit_st2_deq_valid;
  wire read_hit_st2_deq_ready;
  wire read_hit_st2_deq_bits ;

  stream_fifo_pipe_true #(
    .DATA_WIDTH (1),
    .FIFO_DEPTH (1)
  )
  readhit_st2 (
    .clk       (clk                   ),
    .rst_n     (rst_n                 ),
    .w_ready_o (read_hit_st2_enq_ready),
    .w_valid_i (read_hit_st2_enq_valid),
    .w_data_i  (read_hit_st2_enq_bits ),
    .r_valid_o (read_hit_st2_deq_valid),
    .r_ready_i (read_hit_st2_deq_ready),
    .r_data_o  (read_hit_st2_deq_bits )
  );

  assign read_hit_st2_enq_bits = read_hit_st1;

  //Queue: coreRsp_Q
  wire core_rsp_q_enq_valid;
  wire core_rsp_q_enq_ready;
  wire core_rsp_q_deq_valid;
  wire core_rsp_q_deq_ready;
  wire [`WIDBITS+`DCACHE_NLANES*`XLEN+`DCACHE_NLANES:0]core_rsp_q_enq_bits;
  wire [`WIDBITS+`DCACHE_NLANES*`XLEN+`DCACHE_NLANES:0]core_rsp_q_deq_bits;

`ifdef T28_MEM
  stream_fifo_dpsram_16X1060 #(
    .DATA_WIDTH (`WIDBITS+`DCACHE_NLANES*`XLEN+`DCACHE_NLANES+1),
    .FIFO_DEPTH (16/*CORE_RSP_Q_ENTRIES*/)
  )
  core_rsp_q (
    .clk       (clk                 ),
    .rst_n     (rst_n               ),
    .w_ready_o (core_rsp_q_enq_ready),
    .w_valid_i (core_rsp_q_enq_valid),
    .w_data_i  (core_rsp_q_enq_bits ),
    .r_valid_o (core_rsp_q_deq_valid),
    .r_ready_i (core_rsp_q_deq_ready),
    .r_data_o  (core_rsp_q_deq_bits )
  );
`else
  /*stream_fifo*/stream_fifo_useSRAM #(
    .DATA_WIDTH (`WIDBITS+`DCACHE_NLANES*`XLEN+`DCACHE_NLANES+1),
    .FIFO_DEPTH (16/*CORE_RSP_Q_ENTRIES*/)
  )
  core_rsp_q (
    .clk       (clk                 ),
    .rst_n     (rst_n               ),
    .w_ready_o (core_rsp_q_enq_ready),
    .w_valid_i (core_rsp_q_enq_valid),
    .w_data_i  (core_rsp_q_enq_bits ),
    .r_valid_o (core_rsp_q_deq_valid),
    .r_ready_i (core_rsp_q_deq_ready),
    .r_data_o  (core_rsp_q_deq_bits )
  );
`endif

  //readHit_st2_valid is equal to read_hit_st2
  wire read_hit_st2_valid;
  
  assign read_hit_st2_valid = read_hit_st2_deq_valid && read_hit_st2_deq_ready && read_hit_st2_deq_bits;

  //injectTagProbe: to hold a probeRead require
  wire inject_tag_probe;

  reg  inflight_read_write_miss_reg; //RegNext(inflight_read_write_miss)
  reg  mshr_mshr_status_st1        ; //RegNext(mshr_mshr_status_st0)

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      inflight_read_write_miss_reg <= 'd0;
      mshr_mshr_status_st1         <= 'd0;
      inject_tag_probe_reg         <= 'd0;
    end
    else begin
      inflight_read_write_miss_reg <= inflight_read_write_miss;
      mshr_mshr_status_st1         <= mshr_mshr_status_st0    ;
      inject_tag_probe_reg         <= inject_tag_probe        ;
    end
  end

  assign inflight_read_write_miss_w = (is_write_noen&&(mshr_mshr_status_st1!='d0)) || inflight_read_write_miss;
  assign inject_tag_probe = inflight_read_write_miss ^ inflight_read_write_miss_reg;

  //readmiss_sameadd: indicate one cacheline is missed for two times(not only for read)
  assign readmiss_same_addr = mshr_missreq_valid && (mshr_probe_blockaddr==mshr_missreq_blockaddr) && core_req_valid_i && core_req_deq_valid;

  //for invalidate and flush
  wire core_req_invorflu_valid_st0;
  wire core_req_invorflu_valid_st1;
  wire core_req_inv_st0           ;
  wire core_req_inv_st1           ;

  //core_req_invorflu_valid_st0/1, core_req_inv_st0/1: in the same stage?
  assign core_req_invorflu_valid_st0 = core_req_deq_valid && (core_req_opcode_st1==3'b011) && (core_req_param_st1!=4'b0010);
  assign core_req_invorflu_valid_st1 = core_req_st1_valid && (is_invalidate_st1 || is_flush_st1);
  assign core_req_inv_st0            = core_req_deq_valid && (core_req_opcode_st1==3'b011) && (core_req_param_st1==4'b0000);
  assign core_req_inv_st1            = is_invalidate_st1; //TODO: don't need core_req_st1_valid?

  assign core_req_st1_valid = core_req_deq_valid && !(mshr_missrsp_out_valid && !secondary_full_return);

  //mshrMissTI: for mshrMissReq.targetInfo
  wire [`WIDBITS-1:0]                               mshr_miss_ti_st1_instrid     ;
  wire [`DCACHE_NLANES-1:0]                         mshr_miss_ti_st1_activemask  ;
  wire [`DCACHE_NLANES*`DCACHE_BLOCKOFFSETBITS-1:0] mshr_miss_ti_st1_blockoffset ;//[0:`DCACHE_NLANES-1];
  wire [`DCACHE_NLANES*`BYTESOFWORD-1:0]            mshr_miss_ti_st1_wordoffset1h;//[0:`DCACHE_NLANES-1];

  assign mshr_miss_ti_st1_instrid      = core_req_instrid_st1     ;
  assign mshr_miss_ti_st1_activemask   = core_req_activemask_st1  ;
  assign mshr_miss_ti_st1_blockoffset  = core_req_blockoffset_st1 ;
  assign mshr_miss_ti_st1_wordoffset1h = core_req_wordoffset1h_st1;

  //MemReqArb
  wire                                                    memreq_arb_in0_valid          ;
  wire                                                    memreq_arb_in0_ready          ;
  wire                                                    memreq_arb_in0_has_corersp    ;
  wire [`WIDBITS-1:0]                                     memreq_arb_in0_corersp_instrid;
  wire [2:0]                                              memreq_arb_in0_a_opcode       ;
  wire [2:0]                                              memreq_arb_in0_a_param        ;
  wire [2+$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS:0] memreq_arb_in0_a_source       ;
  wire [`XLEN-1:0]                                        memreq_arb_in0_a_addr         ;
  wire [`DCACHE_BLOCKWORDS*`XLEN-1:0]                     memreq_arb_in0_a_data         ;
  wire [`DCACHE_BLOCKWORDS*`BYTESOFWORD-1:0]              memreq_arb_in0_a_mask         ;
  wire                                                    memreq_arb_in1_valid          ;
  wire                                                    memreq_arb_in1_ready          ;
  wire                                                    memreq_arb_in1_has_corersp    ;
  wire [`WIDBITS-1:0]                                     memreq_arb_in1_corersp_instrid;
  wire [2:0]                                              memreq_arb_in1_a_opcode       ;
  wire [2:0]                                              memreq_arb_in1_a_param        ;
  wire [2+$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS:0] memreq_arb_in1_a_source       ;
  wire [`XLEN-1:0]                                        memreq_arb_in1_a_addr         ;
  wire [`DCACHE_BLOCKWORDS*`XLEN-1:0]                     memreq_arb_in1_a_data         ;
  wire [`DCACHE_BLOCKWORDS*`BYTESOFWORD-1:0]              memreq_arb_in1_a_mask         ;
  wire                                                    memreq_arb_in2_valid          ;
  wire                                                    memreq_arb_in2_ready          ;
  wire                                                    memreq_arb_in2_has_corersp    ;
  wire [`WIDBITS-1:0]                                     memreq_arb_in2_corersp_instrid;
  wire [2:0]                                              memreq_arb_in2_a_opcode       ;
  wire [2:0]                                              memreq_arb_in2_a_param        ;
  wire [2+$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS:0] memreq_arb_in2_a_source       ;
  wire [`XLEN-1:0]                                        memreq_arb_in2_a_addr         ;
  wire [`DCACHE_BLOCKWORDS*`XLEN-1:0]                     memreq_arb_in2_a_data         ;
  wire [`DCACHE_BLOCKWORDS*`BYTESOFWORD-1:0]              memreq_arb_in2_a_mask         ;
  wire                                                    memreq_arb_out_valid          ;
  wire                                                    memreq_arb_out_ready          ;
  reg                                                     memreq_arb_out_has_corersp    ;
  reg  [`WIDBITS-1:0]                                     memreq_arb_out_corersp_instrid;
  reg  [2:0]                                              memreq_arb_out_a_opcode       ;
  reg  [2:0]                                              memreq_arb_out_a_param        ;
  reg  [2+$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS:0] memreq_arb_out_a_source       ;
  reg  [`XLEN-1:0]                                        memreq_arb_out_a_addr         ;
  reg  [`DCACHE_BLOCKWORDS*`XLEN-1:0]                     memreq_arb_out_a_data         ;
  reg  [`DCACHE_BLOCKWORDS*`BYTESOFWORD-1:0]              memreq_arb_out_a_mask         ;

  wire [2:0]  memreq_arb_valid_cat          ;
  wire [2:0]  memreq_arb_choose_bin         ;

  assign memreq_arb_valid_cat = {memreq_arb_in2_valid,memreq_arb_in1_valid,memreq_arb_in0_valid};

  fixed_pri_arb #(
    .ARB_WIDTH (3)
  )
  memreqarb (
    .req   (memreq_arb_valid_cat ),
    .grant (memreq_arb_choose_bin)
  );

  assign memreq_arb_out_valid = |memreq_arb_valid_cat;
  assign memreq_arb_in0_ready = memreq_arb_out_ready ;
  assign memreq_arb_in1_ready = memreq_arb_out_ready && !memreq_arb_in0_valid;
  assign memreq_arb_in2_ready = memreq_arb_out_ready && !memreq_arb_in0_valid && !memreq_arb_in1_valid;
  
  always@(*) begin
    if(memreq_arb_choose_bin[0]) begin
      memreq_arb_out_has_corersp     = memreq_arb_in0_has_corersp    ;
      memreq_arb_out_corersp_instrid = memreq_arb_in0_corersp_instrid;
      memreq_arb_out_a_opcode        = memreq_arb_in0_a_opcode       ;
      memreq_arb_out_a_param         = memreq_arb_in0_a_param        ;
      memreq_arb_out_a_source        = memreq_arb_in0_a_source       ;
      memreq_arb_out_a_addr          = memreq_arb_in0_a_addr         ;
      memreq_arb_out_a_data          = memreq_arb_in0_a_data         ;
      memreq_arb_out_a_mask          = memreq_arb_in0_a_mask         ;
    end
    else if(memreq_arb_choose_bin[1]) begin
      memreq_arb_out_has_corersp     = memreq_arb_in1_has_corersp    ;
      memreq_arb_out_corersp_instrid = memreq_arb_in1_corersp_instrid;
      memreq_arb_out_a_opcode        = memreq_arb_in1_a_opcode       ;
      memreq_arb_out_a_param         = memreq_arb_in1_a_param        ;
      memreq_arb_out_a_source        = memreq_arb_in1_a_source       ;
      memreq_arb_out_a_addr          = memreq_arb_in1_a_addr         ;
      memreq_arb_out_a_data          = memreq_arb_in1_a_data         ;
      memreq_arb_out_a_mask          = memreq_arb_in1_a_mask         ;
    end
    else begin
      memreq_arb_out_has_corersp     = memreq_arb_in2_has_corersp    ;
      memreq_arb_out_corersp_instrid = memreq_arb_in2_corersp_instrid;
      memreq_arb_out_a_opcode        = memreq_arb_in2_a_opcode       ;
      memreq_arb_out_a_param         = memreq_arb_in2_a_param        ;
      memreq_arb_out_a_source        = memreq_arb_in2_a_source       ;
      memreq_arb_out_a_addr          = memreq_arb_in2_a_addr         ;
      memreq_arb_out_a_data          = memreq_arb_in2_a_data         ;
      memreq_arb_out_a_mask          = memreq_arb_in2_a_mask         ;
    end
  end

  //missMemReq
  wire                                                    miss_mem_req_has_corersp    ;
  wire [`WIDBITS-1:0]                                     miss_mem_req_corersp_instrid;
  wire [2:0]                                              miss_mem_req_a_opcode       ;
  wire [2:0]                                              miss_mem_req_a_param        ;
  wire [2+$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS:0] miss_mem_req_a_source       ;
  wire [`XLEN-1:0]                                        miss_mem_req_a_addr         ;
  wire [`DCACHE_BLOCKWORDS*`XLEN-1:0]                     miss_mem_req_a_data         ;
  wire [`DCACHE_BLOCKWORDS*`BYTESOFWORD-1:0]              miss_mem_req_a_mask         ;

  wire                                                    read_miss_req_has_corersp    ;
  wire [`WIDBITS-1:0]                                     read_miss_req_corersp_instrid;
  wire [2:0]                                              read_miss_req_a_opcode       ;
  wire [2:0]                                              read_miss_req_a_param        ;
  wire [2+$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS:0] read_miss_req_a_source       ;
  wire [`XLEN-1:0]                                        read_miss_req_a_addr         ;
  wire [`DCACHE_BLOCKWORDS*`XLEN-1:0]                     read_miss_req_a_data         ;
  wire [`DCACHE_BLOCKWORDS*`BYTESOFWORD-1:0]              read_miss_req_a_mask         ;

  wire                                                    write_miss_req_has_corersp    ;
  wire [`WIDBITS-1:0]                                     write_miss_req_corersp_instrid;
  wire [2:0]                                              write_miss_req_a_opcode       ;
  wire [2:0]                                              write_miss_req_a_param        ;
  wire [2+$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS:0] write_miss_req_a_source       ;
  wire [`XLEN-1:0]                                        write_miss_req_a_addr         ;
  wire [`DCACHE_BLOCKWORDS*`XLEN-1:0]                     write_miss_req_a_data         ;
  wire [`DCACHE_BLOCKWORDS*`BYTESOFWORD-1:0]              write_miss_req_a_mask         ;

  //LaneAddrOH: not use
  //wire [`DCACHE_BLOCKWORDS-1:0]      lane_addr_oh    [0:`DCACHE_NLANES-1];
  //wire [`DCACHE_BLOCKOFFSETBITS-1:0] activelane_addr [0:`DCACHE_NLANES-1];
  //wire [`DCACHE_NLANES-1:0]          activelane_mask                     ;


  //genData: cannot handle double precision
  wire [`DCACHE_NLANES*`XLEN-1:0] core_req_st1_data_map_byte;

  gen_data_map_per_byte #(
    .DATA_NUM   (`DCACHE_NLANES),
    .DATA_WIDTH (`XLEN         )
  )
  gen_data (
    .data_i (core_req_data_st1         ),
    .mask_i (core_req_wordoffset1h_st1 ),
    .data_o (core_req_st1_data_map_byte)
  );

  //remapData
  wire [`DCACHE_NLANES-1:0]                         core_req_st1_remap_activemask  ;
  wire [`DCACHE_BLOCKOFFSETBITS*`DCACHE_NLANES-1:0] core_req_st1_remap_blockoffset ;
  wire [`BYTESOFWORD*`DCACHE_NLANES-1:0]            core_req_st1_remap_wordoffset1h;
  wire [`XLEN*`DCACHE_NLANES-1:0]                   core_req_st1_data_map_sameword ;

  gen_data_map_same_word remap_data_per_word(
    .perLaneAddr_activeMask_i        (core_req_activemask_st1        ),
    .perLaneAddr_blockOffset_i       (core_req_blockoffset_st1       ),
    .perLaneAddr_wordOffset1H_i      (core_req_wordoffset1h_st1      ),
    .data_i                          (core_req_st1_data_map_byte     ),
    .perLaneAddrRemap_activeMask_o   (core_req_st1_remap_activemask  ),
    .perLaneAddrRemap_blockOffset_o  (core_req_st1_remap_blockoffset ),
    .perLaneAddrRemap_wordOffset1H_o (core_req_st1_remap_wordoffset1h),
    .data_o                          (core_req_st1_data_map_sameword )
  );

  //for data remap
  wire [`DCACHE_NLANES-1:0] laneblock_conv  [0:`DCACHE_BLOCKWORDS-1];
  wire [`BYTESOFWORD-1:0]   wordoffset_conv [0:`DCACHE_BLOCKWORDS-1];

  wire [`DCACHE_NLANES*`XLEN-1:0] write_miss_req_a_data_remap        [0:`DCACHE_BLOCKWORDS-1];
  wire [`XLEN*`DCACHE_NLANES-1:0] write_miss_req_a_data_remap_bitcat [0:`DCACHE_BLOCKWORDS-1];

  wire [`DCACHE_NLANES*`BYTESOFWORD-1:0] wordoffset_conv_remap        [0:`DCACHE_BLOCKWORDS-1];
  wire [`BYTESOFWORD*`DCACHE_NLANES-1:0] wordoffset_conv_remap_bitcat [0:`DCACHE_BLOCKWORDS-1];

  //TODO: has a better plan? (reduce tree?)
  genvar j,k;
  generate
    for(j=0;j<`DCACHE_BLOCKWORDS;j=j+1) begin: LANE2BLOCK_B1
      assign write_miss_req_a_mask[`BYTESOFWORD*(j+1)-1 -:`BYTESOFWORD] = wordoffset_conv[j];
      for(k=0;k<`DCACHE_NLANES;k=k+1) begin: LANE2BLOCK_B2
        assign laneblock_conv[j][k] = ((core_req_blockoffset_st1[`DCACHE_BLOCKOFFSETBITS*(k+1)-1 -:`DCACHE_BLOCKOFFSETBITS]==j)&&core_req_activemask_st1[k]) ? 1'b1 : 1'b0;
        assign write_miss_req_a_data_remap[j][`XLEN*(k+1)-1 -:`XLEN] = laneblock_conv[j][k] ? core_req_st1_data_map_sameword[`XLEN*(k+1)-1 -:`XLEN] : 'd0;
        assign wordoffset_conv_remap[j][`BYTESOFWORD*(k+1)-1 -:`BYTESOFWORD] = laneblock_conv[j][k] ? core_req_st1_remap_wordoffset1h[`BYTESOFWORD*(k+1)-1 -:`BYTESOFWORD] : 'd0;
      end
    end
  endgenerate

  genvar x,y,z;
  generate
    for(x=0;x<`DCACHE_BLOCKWORDS;x=x+1) begin: DATA_BITCAT_B1
      for(y=0;y<`XLEN;y=y+1) begin: DATA_BITCAT_B2
        for(z=0;z<`DCACHE_NLANES;z=z+1) begin: DATA_BITCAT_B3
          assign write_miss_req_a_data_remap_bitcat[x][`DCACHE_NLANES*y+z] = write_miss_req_a_data_remap[x][`XLEN*z+y];
        end
      end
    end
  endgenerate

  genvar n,m;
  generate
    for(n=0;n<`DCACHE_BLOCKWORDS;n=n+1) begin: DATA_OR_B1
      for(m=0;m<`XLEN;m=m+1) begin: DATA_OR_B2
        assign write_miss_req_a_data[`XLEN*n+m] = |write_miss_req_a_data_remap_bitcat[n][`DCACHE_NLANES*(m+1)-1 -:`DCACHE_NLANES];
      end
    end
  endgenerate

  genvar a,b,c;
  generate
    for(a=0;a<`DCACHE_BLOCKWORDS;a=a+1) begin: WORD_BITCAT_B1
      for(b=0;b<`BYTESOFWORD;b=b+1) begin: WORD_BITCAT_B2
        for(c=0;c<`DCACHE_NLANES;c=c+1) begin: WORD_BITCAT_B3
          assign wordoffset_conv_remap_bitcat[a][`DCACHE_NLANES*b+c] = wordoffset_conv_remap[a][`BYTESOFWORD*c+b];
        end
      end
    end
  endgenerate

  genvar p,q;
  generate
    for(p=0;p<`DCACHE_BLOCKWORDS;p=p+1) begin: WORD_OR_B1
      for(q=0;q<`BYTESOFWORD;q=q+1) begin: WORD_OR_B2
        assign wordoffset_conv[p][q] = |wordoffset_conv_remap_bitcat[p][`DCACHE_NLANES*(q+1)-1 -:`DCACHE_NLANES];
      end
    end
  endgenerate

  //missMemReq connection
  assign write_miss_req_has_corersp     = 1'b1                ;
  assign write_miss_req_corersp_instrid = core_req_instrid_st1;
  assign write_miss_req_a_opcode        = `TLAOP_PUTPART      ;//PutPartialData:Get
  assign write_miss_req_a_param         = 3'b000              ;//regular write
  assign write_miss_req_a_source        = 'd0                 ;
  assign write_miss_req_a_addr          = {core_req_tag_st1,core_req_setidx_st1,{(`XLEN-`BABITS){1'b0}}};

  assign read_miss_req_has_corersp     = 1'b0      ;
  assign read_miss_req_corersp_instrid = 'd0       ;
  assign read_miss_req_a_opcode        = `TLAOP_GET;//Get
  assign read_miss_req_a_param         = 3'b000    ;//regular read
  assign read_miss_req_a_source        = {3'b001,mshr_probe_out_a_source,core_req_setidx_st1}          ;
  assign read_miss_req_a_addr          = {core_req_tag_st1,core_req_setidx_st1,{(`XLEN-`BABITS){1'b0}}};
  assign read_miss_req_a_data          = 'd0                                                           ;
  assign read_miss_req_a_mask          = {(`DCACHE_BLOCKWORDS*`BYTESOFWORD){1'b1}}                     ;

  assign miss_mem_req_has_corersp     = write_miss_st1 ? write_miss_req_has_corersp     : read_miss_req_has_corersp    ;
  assign miss_mem_req_corersp_instrid = write_miss_st1 ? write_miss_req_corersp_instrid : read_miss_req_corersp_instrid;
  assign miss_mem_req_a_opcode        = write_miss_st1 ? write_miss_req_a_opcode        : read_miss_req_a_opcode       ;
  assign miss_mem_req_a_param         = write_miss_st1 ? write_miss_req_a_param         : read_miss_req_a_param        ;
  assign miss_mem_req_a_source        = write_miss_st1 ? write_miss_req_a_source        : read_miss_req_a_source       ;
  assign miss_mem_req_a_addr          = write_miss_st1 ? write_miss_req_a_addr          : read_miss_req_a_addr         ;
  assign miss_mem_req_a_data          = write_miss_st1 ? write_miss_req_a_data          : read_miss_req_a_data         ;
  assign miss_mem_req_a_mask          = write_miss_st1 ? write_miss_req_a_mask          : read_miss_req_a_mask         ;

  //getBankEN
  wire [$clog2(`DCACHE_NLANES)*`DCACHE_BLOCKWORDS-1:0] get_banken_perBankBlockIdx;
  wire [`DCACHE_BLOCKWORDS-1:0]                        get_banken_perBankValid   ;

  get_data_access_banken #(
    .NBANK (`DCACHE_BLOCKWORDS),
    .NLANE (`DCACHE_NLANES    )
  )
  get_banken (
    .perLaneBlockIdx_i (core_req_blockoffset_st1  ),
    .perLaneVaild_i    (core_req_activemask_st1   ),
    .perBankBlockIdx_o (get_banken_perBankBlockIdx),
    .perBankValid_o    (get_banken_perBankValid   )
  );

  //for change getBankEN.perBankBlockIdx into vector
  wire [$clog2(`DCACHE_NLANES)-1:0] get_banken_perBankBlockIdx_v      [0:`DCACHE_BLOCKWORDS-1];
  
  genvar e;
  generate
    for(e=0;e<`DCACHE_BLOCKWORDS;e=e+1) begin: PERBANK_BLOCKIDX
      assign get_banken_perBankBlockIdx_v[e] = get_banken_perBankBlockIdx[$clog2(`DCACHE_NLANES)*(e+1)-1 -:$clog2(`DCACHE_NLANES)];
    end
  endgenerate

  //for change core_req_st1_remap into vector
  wire [`XLEN-1:0]        core_req_st1_data_map_sameword_v  [0:`DCACHE_NLANES-1];
  wire [`BYTESOFWORD-1:0] core_req_st1_remap_wordoffset1h_v [0:`DCACHE_NLANES-1];

  genvar f;
  generate
    for(f=0;f<`DCACHE_NLANES;f=f+1) begin: DATA_REMAP
      assign core_req_st1_data_map_sameword_v[f]  = core_req_st1_data_map_sameword[`XLEN*(f+1)-1 -:`XLEN];
      assign core_req_st1_remap_wordoffset1h_v[f] = core_req_st1_remap_wordoffset1h[`BYTESOFWORD*(f+1)-1 -:`BYTESOFWORD];
    end
  endgenerate

  //kinds of data_access req:
  //data_access InvOrFlu req
  wire [SRAM_SETIDXBITS-1:0] data_invorflu_sram_rreq_setidx [0:`DCACHE_BLOCKWORDS-1];

  //data_access WriteHit req
  wire [SRAM_SETIDXBITS-1:0] data_writehit_sram_wreq_setidx    [0:`DCACHE_BLOCKWORDS-1];
  wire [`XLEN-1:0]           data_writehit_sram_wreq_data      [0:`DCACHE_BLOCKWORDS-1];
  wire [`BYTESOFWORD-1:0]    data_writehit_sram_wreq_waymask   [0:`DCACHE_BLOCKWORDS-1];

  //data_access ReadHit req
  wire [SRAM_SETIDXBITS-1:0] data_readhit_sram_rreq_setidx     [0:`DCACHE_BLOCKWORDS-1];

  //data_access replaceread req
  wire [SRAM_SETIDXBITS-1:0] data_replaceread_sram_rreq_setidx [0:`DCACHE_BLOCKWORDS-1];

  //data_access missrsp req
  wire [SRAM_SETIDXBITS-1:0] data_missrsp_sram_wreq_setidx    [0:`DCACHE_BLOCKWORDS-1];
  wire [`XLEN-1:0]           data_missrsp_sram_wreq_data      [0:`DCACHE_BLOCKWORDS-1];
  wire [`BYTESOFWORD-1:0]    data_missrsp_sram_wreq_waymask   [0:`DCACHE_BLOCKWORDS-1];

  //for SRAM setidx cat
  //wire [$clog2(`DCACHE_NWAYS)-1:0] tag_dirtyWayMask_bin_st0      ;
  wire [$clog2(`DCACHE_NWAYS)-1:0] tag_waymaskHit_bin_st1        ;
  wire [$clog2(`DCACHE_NWAYS)-1:0] tag_waymaskReplacement_bin_st1;
  reg  [$clog2(`DCACHE_NWAYS)-1:0] tag_waymaskReplacement_bin_st2; //for miss replace dirty

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      tag_waymaskReplacement_bin_st2 <= 'd0;
    end
    else begin
      tag_waymaskReplacement_bin_st2 <= tag_waymaskReplacement_bin_st1;
    end
  end

  wire [`DCACHE_NWAYS-1:0] tag_dirtyWayMask_oh_st0;

  assign tag_dirtyWayMask_oh_st0 = 1 << tag_dirtyWayMask_st0;

  one2bin #(
    .ONE_WIDTH (`DCACHE_NWAYS        ),
    .BIN_WIDTH ($clog2(`DCACHE_NWAYS))
  )
  waymaskhit_oh2bin (
    .oh  (tag_waymaskHit_st1    ),
    .bin (tag_waymaskHit_bin_st1)
  );

  one2bin #(
    .ONE_WIDTH (`DCACHE_NWAYS        ),
    .BIN_WIDTH ($clog2(`DCACHE_NWAYS))
  )
  waymaskreplace_oh2bin (
    .oh  (tag_waymaskReplacement_st1    ),
    .bin (tag_waymaskReplacement_bin_st1)
  );

  //Queue: memRsp_Q
  wire mem_rsp_q_enq_valid;
  wire mem_rsp_q_enq_ready;
  wire mem_rsp_q_deq_valid;
  wire mem_rsp_q_deq_ready;
  wire [5+$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS+`XLEN+`DCACHE_BLOCKWORDS*`XLEN:0] mem_rsp_q_enq_bits;
  wire [5+$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS+`XLEN+`DCACHE_BLOCKWORDS*`XLEN:0] mem_rsp_q_deq_bits;

  assign mem_rsp_q_enq_bits = {mem_rsp_d_opcode_i,
                               mem_rsp_d_source_i,
                               mem_rsp_d_addr_i  ,
                               mem_rsp_d_data_i  };

  stream_fifo #(
    .DATA_WIDTH (6+$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS+`XLEN+`DCACHE_BLOCKWORDS*`XLEN),
    .FIFO_DEPTH (1)
  )
  mem_rsp_q (
    .clk       (clk                ),
    .rst_n     (rst_n              ),
    .w_ready_o (mem_rsp_q_enq_ready),
    .w_valid_i (mem_rsp_q_enq_valid),
    .w_data_i  (mem_rsp_q_enq_bits ),
    .r_valid_o (mem_rsp_q_deq_valid),
    .r_ready_i (mem_rsp_q_deq_ready),
    .r_data_o  (mem_rsp_q_deq_bits )
  );

  wire [2:0]                                               mem_rsp_d_opcode_st0;
  wire [2+$clog2(`DCACHE_WSHR_ENTRY)+`DCACHE_SETIDXBITS:0] mem_rsp_d_source_st0;
  wire [`XLEN-1:0]                                         mem_rsp_d_addr_st0  ;
  wire [`DCACHE_BLOCKWORDS*`XLEN-1:0]                      mem_rsp_d_data_st0  ;

  assign mem_rsp_d_opcode_st0 = mem_rsp_q_deq_bits[5+$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS+`XLEN+`DCACHE_BLOCKWORDS*`XLEN -:3];
  assign mem_rsp_d_source_st0 = mem_rsp_q_deq_bits[2+$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS+`XLEN+`DCACHE_BLOCKWORDS*`XLEN -:3+$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS];
  assign mem_rsp_d_addr_st0   = mem_rsp_q_deq_bits[`XLEN+`DCACHE_BLOCKWORDS*`XLEN-1 -:`XLEN];
  assign mem_rsp_d_data_st0   = mem_rsp_q_deq_bits[`DCACHE_BLOCKWORDS*`XLEN-1:0];

  //kinds of memRsp
  wire mem_rsp_is_invorflu;
  wire mem_rsp_is_write   ;
  wire mem_rsp_is_read    ;

  assign mem_rsp_is_invorflu = mem_rsp_d_opcode_st0 == 3'b010;//hintAck
  assign mem_rsp_is_write    = mem_rsp_d_opcode_st0 == 3'b000;//AccessAck
  assign mem_rsp_is_read     = mem_rsp_d_opcode_st0 == 3'b001;//AccessAckData

  //pipeline reg: memRsp_st1
  reg [2:0]                                              mem_rsp_d_opcode_st1;
  reg [2+$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS:0] mem_rsp_d_source_st1;
  reg [`XLEN-1:0]                                        mem_rsp_d_addr_st1  ;
  reg [`DCACHE_BLOCKWORDS*`XLEN-1:0]                     mem_rsp_d_data_st1  ;

  //pipeline reg: memRsp_st2, for miss replace dirty
  reg [`DCACHE_BLOCKWORDS*`XLEN-1:0]                     mem_rsp_d_data_st2  ;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      mem_rsp_d_opcode_st1 <= 'd0;
      mem_rsp_d_source_st1 <= 'd0;
      mem_rsp_d_addr_st1   <= 'd0;
      mem_rsp_d_data_st1   <= 'd0;
      mem_rsp_d_data_st2   <= 'd0;
    end
    else begin
      mem_rsp_d_data_st2   <= mem_rsp_d_data_st1;
      if(mem_rsp_q_deq_valid && mem_rsp_q_deq_ready && mem_rsp_is_read) begin
        mem_rsp_d_opcode_st1 <= mem_rsp_d_opcode_st0;
        mem_rsp_d_source_st1 <= mem_rsp_d_source_st0;
        mem_rsp_d_addr_st1   <= mem_rsp_d_addr_st0  ;
        mem_rsp_d_data_st1   <= mem_rsp_d_data_st0  ;
      end
      else begin
        mem_rsp_d_opcode_st1 <= mem_rsp_d_opcode_st1;
        mem_rsp_d_source_st1 <= mem_rsp_d_source_st1;
        mem_rsp_d_addr_st1   <= mem_rsp_d_addr_st1  ;
        mem_rsp_d_data_st1   <= mem_rsp_d_data_st1  ;
      end
    end
  end

  //for flush
  wire flush_stall        ;
  wire invalidate_no_dirty;
  wire flush_no_dirty     ;
  
  //reg invorflu_already_flush   ; //is useful?
  reg core_req_tag_hasdirty_st1;
  reg core_req_tag_hasdirty_st2;//if InvOrFlu need 4 cycles to start a flush req
  reg waitfor_l2_flush         ;
  reg waitfor_l2_flush_st2     ;

  //TODO: can't handle when there still exist infligh L2 rsp
  assign flush_stall         = is_flush_noen || is_invalidate_noen || waitfor_l2_flush              ;
  //assign flush_stall         = is_flush_st0 || is_invalidate_st0 || waitfor_l2_flush              ;
  assign invalidate_no_dirty = core_req_st1_valid && is_invalidate_st1 && !core_req_tag_hasdirty_st1;
  assign flush_no_dirty = core_req_st1_valid && is_flush_st1 && !core_req_tag_hasdirty_st1;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      core_req_tag_hasdirty_st1 <= 'd0;
      core_req_tag_hasdirty_st2 <= 'd0;
    end
    else begin
      core_req_tag_hasdirty_st1 <= tag_hasDirty_st0         ;
      core_req_tag_hasdirty_st2 <= core_req_tag_hasdirty_st1;
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      waitfor_l2_flush <= 'd0;
    end
    else begin
      if(core_req_valid_i && core_req_ready_o && (is_invalidate_noen || is_flush_noen)) begin
      //if(core_req_valid_i && core_req_ready_o && (is_invalidate_noen || is_flush_noen) && !tag_hasDirty_st0) begin
        waitfor_l2_flush <= 1'b1;
      end
      else if(mem_rsp_is_invorflu) begin
        waitfor_l2_flush <= 1'b0;
      end
      else begin
        waitfor_l2_flush <= waitfor_l2_flush;
      end
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      waitfor_l2_flush_st2 <= 'd0;
    end
    else begin
      //if(waitfor_l2_flush && memreq_arb_in2_valid && memreq_arb_in2_ready && !core_req_tag_hasdirty_st1) begin
      if(waitfor_l2_flush && memreq_arb_in2_valid && memreq_arb_in2_ready && !tag_hasDirty_st0) begin
        waitfor_l2_flush_st2 <= 1'b1;
      end
      else if(mem_rsp_is_invorflu) begin
        waitfor_l2_flush_st2 <= 1'b0;
      end
      else if((invalidate_no_dirty || flush_no_dirty) && waitfor_l2_flush) begin
        waitfor_l2_flush_st2 <= 1'b1;
      end
    end
  end

  //inflight_read_write_miss: when writes, readmiss is not completely replied 
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      inflight_read_write_miss <= 'd0;
    end
    else begin
      //if(inflight_read_write_miss && (mshr_mshr_status_st0=='d0)) begin
      if(inflight_read_write_miss && mshr_empty) begin
        inflight_read_write_miss <= 1'd0;
      end
      else if(is_write_st0 && (mshr_mshr_status_st0!='d0)) begin
        inflight_read_write_miss <= 1'd1;
      end
      else begin
        inflight_read_write_miss <= inflight_read_write_miss;
      end
    end
  end

  //wshr
  wire                                          wshr_pushReq_valid    ;
  wire                                          wshr_pushReq_ready    ;
  wire [`DCACHE_SETIDXBITS+`DCACHE_TAGBITS-1:0] wshr_pushReq_blockAddr;
  wire                                          wshr_conflict         ;
  wire [$clog2(`DCACHE_WSHR_ENTRY)-1:0]         wshr_pushedIdx        ;
  wire                                          wshr_empty            ;
  wire                                          wshr_popReq_valid     ;
  wire [$clog2(`DCACHE_WSHR_ENTRY)-1:0]         wshr_popReq_bits      ;

  dcache_wshr #(
    .DEPTH (`DCACHE_WSHR_ENTRY        ),
    .WIDTH ($clog2(`DCACHE_WSHR_ENTRY))
  )
  wshr_access (
    .clk                 (clk                   ),
    .rst_n               (rst_n                 ),
    .pushReq_valid_i     (wshr_pushReq_valid    ),
    .pushReq_ready_o     (wshr_pushReq_ready    ),
    .pushReq_blockAddr_i (wshr_pushReq_blockAddr),
    .conflict_o          (wshr_conflict         ),
    .pushedIdx_o         (wshr_pushedIdx        ),
    .empty_o             (wshr_empty            ),
    .popReq_valid_i      (wshr_popReq_valid     ),
    .popReq_bits_i       (wshr_popReq_bits      )
  );
  
  //core_req_st1_ready
  always@(*) begin
    if(is_read_st1 || is_write_st1) begin
      if(tag_hit_st1) begin //regular read/write hit
        core_req_st1_ready = core_rsp_st2_enq_ready && core_rsp_from_core_st2_enq_ready && !(mshr_missrsp_out_valid&&!secondary_full_return);
      end
      else if(is_read_st1) begin //read miss
        core_req_st1_ready = mshr_missreq_ready && memreq_arb_in1_ready && (mshr_probe_out_mshr_status==3'b000||mshr_probe_out_mshr_status==3'b010) && !(mshr_missrsp_out_valid&&!secondary_full_return);
      end
      else begin //write miss TODO: add hit in-flight miss
        core_req_st1_ready = core_rsp_q_enq_ready && memreq_arb_in1_ready && !(mshr_missrsp_out_valid&&!secondary_full_return) && !inflight_read_write_miss_w;
      end
    end
    else if(is_invalidate_st1) begin //invalidate
      core_req_st1_ready = !core_req_tag_hasdirty_st1 && mshr_empty && wshr_empty && !flush_stall;
    end
    else if(is_flush_st1) begin //flush
      core_req_st1_ready = !core_req_tag_hasdirty_st1 && wshr_empty && !flush_stall;
    end
    else if(is_wait_mshr_st1) begin //waitMSHR
      core_req_st1_ready = mshr_empty;
    end
    else if(is_amo_st1) begin //TODO: AMO
      core_req_st1_ready = 1'b1;
    end
    else begin
      core_req_st1_ready = 1'b0;
    end
  end

  //waitMSHR, flush, invalidate can be passed to st2(coreRsp)
  wire wait_mshr_core_rsp_st1;
  wire flu_core_rsp_st1      ;
  wire inv_core_rsp_st1      ;

  assign wait_mshr_core_rsp_st1 = core_req_st1_valid && is_wait_mshr_st1 && mshr_empty;
  assign flu_core_rsp_st1       = core_req_st1_valid && is_flush_st1 && !core_req_tag_hasdirty_st1 && wshr_empty;
  assign inv_core_rsp_st1       = core_req_st1_valid && is_invalidate_st1 && !core_req_tag_hasdirty_st1 && mshr_empty && wshr_empty;

  //InvOrFlu can be passed to st2(memReq)
  wire invorflu_memreq_valid_st1;

  assign invorflu_memreq_valid_st1 = core_req_st1_valid && (is_invalidate_st1||is_flush_st1) && (core_req_tag_hasdirty_st1||core_req_tag_hasdirty_st2);
  //assign invorflu_memreq_valid_st1 = core_req_st1_valid && (is_invalidate_st1||is_flush_st1) && core_req_tag_hasdirty_st1;

  reg  invorflu_memreq_valid_st2;//RegNext(invorflu_memreq_valid_st1)
  
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      invorflu_memreq_valid_st2 <= 'd0;
    end
    else begin
      invorflu_memreq_valid_st2 <= invorflu_memreq_valid_st1;
    end
  end

  //InvOrFlu MemReq
  wire                                                    invorflu_memreq_has_corersp    ;
  wire [`WIDBITS-1:0]                                     invorflu_memreq_corersp_instrid;
  wire [2:0]                                              invorflu_memreq_a_opcode       ;
  wire [2:0]                                              invorflu_memreq_a_param        ;
  wire [2+$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS:0] invorflu_memreq_a_source       ;
  wire [`XLEN-1:0]                                        invorflu_memreq_a_addr         ;
  wire [`DCACHE_BLOCKWORDS*`XLEN-1:0]                     invorflu_memreq_a_data         ;
  wire [`DCACHE_BLOCKWORDS*`BYTESOFWORD-1:0]              invorflu_memreq_a_mask         ;

  //L2_flush MemReq
  wire                                                    l2flush_memreq_has_corersp    ;
  wire [`WIDBITS-1:0]                                     l2flush_memreq_corersp_instrid;
  wire [2:0]                                              l2flush_memreq_a_opcode       ;
  wire [2:0]                                              l2flush_memreq_a_param        ;
  wire [2+$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS:0] l2flush_memreq_a_source       ;
  wire [`XLEN-1:0]                                        l2flush_memreq_a_addr         ;
  wire [`DCACHE_BLOCKWORDS*`XLEN-1:0]                     l2flush_memreq_a_data         ;
  wire [`DCACHE_BLOCKWORDS*`BYTESOFWORD-1:0]              l2flush_memreq_a_mask         ;

  //dirtyReplace MemReq: st1
  wire                                                    dirty_replace_memreq_has_corersp    ;
  wire [`WIDBITS-1:0]                                     dirty_replace_memreq_corersp_instrid;
  wire [2:0]                                              dirty_replace_memreq_a_opcode       ;
  wire [2:0]                                              dirty_replace_memreq_a_param        ;
  wire [2+$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS:0] dirty_replace_memreq_a_source       ;
  wire [`XLEN-1:0]                                        dirty_replace_memreq_a_addr         ;
  wire [`DCACHE_BLOCKWORDS*`XLEN-1:0]                     dirty_replace_memreq_a_data         ;
  wire [`DCACHE_BLOCKWORDS*`BYTESOFWORD-1:0]              dirty_replace_memreq_a_mask         ;

  //InvOrFlu, L2_flush, dirtyReplace MemReq connection
  wire [`DCACHE_BLOCKWORDS*`XLEN-1:0] data_access_rrsp    ;//cat DataAccess read data

  reg [`DCACHE_SETIDXBITS-1:0] tag_dirtySetIdx_st1        ;//RegNext(tag_dirtySetIdx_st0)
  reg [`XLEN-1:0]              tag_addrReplacement_st2    ;//RegNext(tag_addrReplacement_st1)
  reg                          tag_allocateWrite_valid_st1;//RegNext(tag_allocateWrite_valid)

  //invorflu: addr_st2
  //reg [`XLEN-1:0] invorflu_memreq_a_addr_st2;
  wire tag_allocate_write_ready    ;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      tag_dirtySetIdx_st1         <= 'd0;
      tag_addrReplacement_st2     <= 'd0;
      tag_allocateWrite_valid_st1 <= 'd0;
      //invorflu_memreq_a_addr_st2  <= 'd0;
    end
    else begin
      tag_dirtySetIdx_st1         <= tag_dirtySetIdx_st0    ;
      tag_addrReplacement_st2     <= tag_addrReplacement_st1;
      tag_allocateWrite_valid_st1 <= (tag_allocateWrite_valid_st1 && !tag_allocate_write_ready) ? 1'b1 : tag_allocateWrite_valid;
      //tag_allocateWrite_valid_st1 <= tag_allocateWrite_valid;
      //invorflu_memreq_a_addr_st2  <= invorflu_memreq_a_addr ;
    end
  end

  assign invorflu_memreq_has_corersp     = waitfor_l2_flush_st2                                           ;
  assign invorflu_memreq_corersp_instrid = core_req_instrid_st1                                           ;
  assign invorflu_memreq_a_opcode        = waitfor_l2_flush_st2 ? l2flush_memreq_a_opcode : `TLAOP_PUTFULL;//PutPartialData:Get
  assign invorflu_memreq_a_param         = waitfor_l2_flush_st2 ? l2flush_memreq_a_param : 'd0            ;//regular write
  assign invorflu_memreq_a_source        = 'd0                                                            ;
  assign invorflu_memreq_a_addr          = {tag_dirtyTag_st1,tag_dirtySetIdx_st1,{(`XLEN-`BABITS){1'b0}}} ;
  assign invorflu_memreq_a_data          = data_access_rrsp                                               ;
  assign invorflu_memreq_a_mask          = {(`DCACHE_BLOCKWORDS*`BYTESOFWORD){1'b1}}                      ;

  assign l2flush_memreq_has_corersp     = 1'b1                                                          ;
  assign l2flush_memreq_corersp_instrid = core_req_instrid_st1                                          ;
  assign l2flush_memreq_a_opcode        = `TLAOP_FLUSH                                                  ;//3'd5
  assign l2flush_memreq_a_param         = is_invalidate_st1 ? `TLAPARAM_INV :`TLAPARAM_FLUSH            ;
  assign l2flush_memreq_a_source        = 'd0                                                           ;
  assign l2flush_memreq_a_addr          = {tag_dirtyTag_st1,tag_dirtySetIdx_st1,{(`XLEN-`BABITS){1'b0}}};
  assign l2flush_memreq_a_data          = 'd0                                                           ;
  assign l2flush_memreq_a_mask          = {(`DCACHE_BLOCKWORDS*`BYTESOFWORD){1'b1}}                     ;

  assign dirty_replace_memreq_has_corersp     = 'd0                                      ;
  assign dirty_replace_memreq_corersp_instrid = 'd0                                      ;//DontCare
  assign dirty_replace_memreq_a_opcode        = `TLAOP_PUTFULL                           ;//'d0
  assign dirty_replace_memreq_a_param         = 'd0                                      ;//regular write
  assign dirty_replace_memreq_a_source        = 'd0                                      ;//DontCare TODO: change source information
  assign dirty_replace_memreq_a_addr          = tag_addrReplacement_st2                  ;
  assign dirty_replace_memreq_a_data          = data_access_rrsp                         ;
  assign dirty_replace_memreq_a_mask          = {(`DCACHE_BLOCKWORDS*`BYTESOFWORD){1'b1}};

  //tagReqCtrl is for allocateWrite: indicate tag can be accessed(ready). tag is in use(valid)
  reg  tag_req_ready_ctrl;
  wire tag_req_valid_ctrl;

  //tag_allocate_write_ready: ready to write a new tag(for tag replace)
  //ensure when !needReplace, will not allocateWrite
  //wire tag_allocate_write_ready    ;
  wire tag_allocate_write_ready_mod;
  wire tag_allocate_write_fire     ;

  assign tag_req_valid_ctrl           = !tag_req_ready_ctrl                                    ;
  assign tag_allocate_write_ready_mod = tag_req_ready_ctrl || tag_allocate_write_ready         ;
  assign tag_allocate_write_fire      = tag_allocateWrite_valid && tag_allocate_write_ready_mod;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      tag_req_ready_ctrl <= 'd0;
    end
    else begin
      if(tag_allocate_write_fire && !(mem_rsp_q_deq_valid&&mem_rsp_q_deq_ready)) begin
        tag_req_ready_ctrl <= 1'b0;
      end
      else if(!tag_req_valid_ctrl && (mem_rsp_q_deq_valid&&mem_rsp_q_deq_ready)) begin
        tag_req_ready_ctrl <= 1'b1;
      end
      else begin
        tag_req_ready_ctrl <= tag_req_ready_ctrl;
      end
    end
  end

  //memRsp_Q handshake signals
  assign mem_rsp_q_enq_valid = mem_rsp_valid_i;
  assign mem_rsp_q_deq_ready = mem_rsp_is_write || mem_rsp_is_invorflu || (mem_rsp_is_read&&tag_allocate_write_ready_mod&&mshr_missrsp_in_ready);//&& core_rsp_q_enq_ready); //TODO: why need enq.ready ?

  //tagReplaceStatus: indicate there is a tagaccess replacement require(need be replied)
  reg tag_replace_status ;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      tag_replace_status <= 'd0;
    end
    else begin
      if(!tag_replace_status && tag_needReplace) begin
        tag_replace_status <= 1'b1;
      end
      else if(tag_replace_status && memreq_arb_in0_ready) begin
        tag_replace_status <= 1'b0;
      end
      else begin
        tag_replace_status <= tag_replace_status;
      end
    end
  end

  assign tag_allocate_write_ready = tag_replace_status ? memreq_arb_in0_ready : !tag_needReplace;

  //data_access enable
  //dataInvOrFluValid: can read SRAM for InvOrFlu
  wire data_invorflu_valid;

  assign data_invorflu_valid = (core_req_invorflu_valid_st0||core_req_invorflu_valid_st1) && tag_hasDirty_st0;

  //dataReplaceReadValid: enable to read SRAM dirtylane
  wire data_replaceread_valid;

  assign data_replaceread_valid = tag_allocateWrite_valid_st1 && (tag_replace_status=='d0) && tag_needReplace;

  //dataFillValid: enable to write a new cacheline
  wire data_fill_valid;

  //assign data_fill_valid = tag_allocateWrite_valid_st1 && (tag_replace_status=='d0) && !tag_needReplace;
  assign data_fill_valid = tag_allocateWriteTagSRAMWValid_st1;
  
  //connect proberead_allocatewrite_conf: probeRead conflict with allocateWrite
  //why RegNext(tag_allocateWrite_valid): tag is allocateWriting, cannot start a new tag probeRead
  assign proberead_allocatewrite_conf = core_req_valid_i && tag_allocateWrite_valid_st1;

  // missRspTI: miss rsp, for coreRsp
  wire [`WIDBITS-1:0]                               miss_rsp_ti_st1_instrid     ;
  wire [`DCACHE_NLANES-1:0]                         miss_rsp_ti_st1_activemask  ;
  wire [`DCACHE_NLANES*`DCACHE_BLOCKOFFSETBITS-1:0] miss_rsp_ti_st1_blockoffset ;//[0:`DCACHE_NLANES-1];
  wire [`DCACHE_NLANES*`BYTESOFWORD-1:0]            miss_rsp_ti_st1_wordoffset1h;//[0:`DCACHE_NLANES-1];

  assign miss_rsp_ti_st1_instrid      = mshr_missrsp_out_targetinfo[`TIWIDTH-1 -:`WIDBITS];
  assign miss_rsp_ti_st1_activemask   = mshr_missrsp_out_targetinfo[`TIWIDTH-`WIDBITS-1 -:`DCACHE_NLANES];
  assign miss_rsp_ti_st1_blockoffset  = mshr_missrsp_out_targetinfo[`TIWIDTH-`WIDBITS-`DCACHE_NLANES-1 -:`DCACHE_NLANES*`DCACHE_BLOCKOFFSETBITS];
  assign miss_rsp_ti_st1_wordoffset1h = mshr_missrsp_out_targetinfo[`DCACHE_NLANES*`BYTESOFWORD-1:0];

  //tagaccess connection
  assign tag_probeRead_valid                = (core_req_valid_i&&core_req_ready_o) || inject_tag_probe;
  assign tag_probeRead_setIdx               = inject_tag_probe ? core_req_setidx_st1 : core_req_setidx_i;
  assign tag_tagFromCore_st1                = core_req_tag_st1;
  assign tag_probeIsWrite_st1               = is_write_st1 && (core_req_control_st1_deq_valid  || inject_tag_probe_reg) && cache_hit_st1;
  assign tag_coreReq_q_deq_fire             = (core_req_deq_valid && core_req_deq_ready) || inject_tag_probe_reg;
  assign tag_allocateWrite_valid            = tag_req_valid_ctrl && mem_rsp_q_deq_valid && mem_rsp_is_read && mem_rsp_q_deq_ready;
  //assign tag_allocateWrite_valid            = tag_req_valid_ctrl && mem_rsp_q_deq_valid && mem_rsp_is_read;
  assign tag_allocateWrite_setIdx           = mem_rsp_d_source_st0[`DCACHE_SETIDXBITS-1:0];
  assign tag_allocateWriteData_st1          = mshr_missrsp_out_blockaddr[`BABITS-1 -:`DCACHE_TAGBITS];
  assign tag_allocateWriteTagSRAMWValid_st1 = tag_allocateWrite_valid_st1 && tag_allocate_write_ready;
  //assign tag_allocateWriteTagSRAMWValid_st1 = tag_allocateWrite_valid_st1;
  assign tag_mem_req_fire                   = mem_req_valid_o && mem_req_ready_i                     ;
  assign tag_flushChoosen_valid             = (core_req_invorflu_valid_st0||core_req_invorflu_valid_st1) && tag_hasDirty_st0; //TODO: add LR/SC conditions
  assign tag_flushChoosen                   = {tag_dirtySetIdx_st0,tag_dirtyWayMask_oh_st0}; //TODO: add LR/SC conditions
  assign tag_invalidateAll                  = (core_req_st1_valid && is_invalidate_st1 && !core_req_tag_hasdirty_st1);
  assign tag_tagready_st1                   = core_req_st1_ready;

  //mshr connection
  assign mshr_probe_valid            = core_req_valid_i && core_req_st0_ready;
  assign mshr_probe_blockaddr        = {core_req_tag_i,core_req_setidx_i}    ;
  assign mshr_missreq_valid          = read_miss_st1 && !mshr_missrsp_out_valid && core_req_st1_valid && mshr_probe_status;
  assign mshr_missreq_blockaddr      = {core_req_tag_st1,core_req_setidx_st1};
  assign mshr_missreq_targetinfo     = {mshr_miss_ti_st1_instrid     ,
                                        mshr_miss_ti_st1_activemask  ,
                                        mshr_miss_ti_st1_blockoffset ,
                                        mshr_miss_ti_st1_wordoffset1h};
  //assign mshr_missrsp_in_valid       = mem_rsp_q_deq_valid && mem_rsp_is_read && core_rsp_q_enq_ready;
  assign mshr_missrsp_in_valid       = mem_rsp_q_deq_valid && mem_rsp_is_read && core_rsp_q_enq_ready && mem_rsp_q_deq_ready ;
  assign mshr_missrsp_in_instrid     = mem_rsp_d_source_st0[`DCACHE_SETIDXBITS+$clog2(`DCACHE_MSHRENTRY)-1:`DCACHE_SETIDXBITS];
  assign mshr_stage1_ready           = core_req_st1_ready                    ;
  assign mshr_stage2_ready           = memreq_arb_in1_ready                  ;

  //SRAM: DataAccess
  //connect SRAM_REQ
  wire [`DCACHE_SETIDXBITS-1:0] miss_rsp_setidx_st1  ;
  reg  [`DCACHE_SETIDXBITS-1:0] miss_rsp_setidx_st2  ;//RegNext(miss_rsp_setidx_st1), for miss replace dirty
  reg                           data_access_w_req_mux;//RegNext(mem_rsp_q_deq_valid && mem_rsp_is_read)
                                                      //choose missrsp data for sram

  assign miss_rsp_setidx_st1 = mem_rsp_d_source_st1[`DCACHE_SETIDXBITS-1:0];

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      data_access_w_req_mux <= 'd0;
      miss_rsp_setidx_st2   <= 'd0;
    end
    else begin
      data_access_w_req_mux <= mem_rsp_q_deq_valid && mem_rsp_is_read;
      miss_rsp_setidx_st2   <= miss_rsp_setidx_st1                   ;
    end
  end

  wire [`DCACHE_BLOCKWORDS-1:0] data_access_r_req_valid                           ;
  reg  [SRAM_SETIDXBITS-1:0]    data_access_r_req_setid   [0:`DCACHE_BLOCKWORDS-1];//comb logic
  wire [`XLEN-1:0]              data_access_r_resp_data   [0:`DCACHE_BLOCKWORDS-1];
  wire [`DCACHE_BLOCKWORDS-1:0] data_access_w_req_valid                           ;
  wire [SRAM_SETIDXBITS-1:0]    data_access_w_req_setid   [0:`DCACHE_BLOCKWORDS-1];
  wire [`BYTESOFWORD-1:0]       data_access_w_req_waymask [0:`DCACHE_BLOCKWORDS-1];
  wire [`XLEN-1:0]              data_access_w_req_data    [0:`DCACHE_BLOCKWORDS-1];

  //for miss replace dirty
  reg  miss_replace_dirty_reg;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      miss_replace_dirty_reg <= 'd0;
    end
    else begin
      miss_replace_dirty_reg <= (!tag_allocateWriteTagSRAMWValid_st1 && tag_allocateWrite_valid_st1);
    end
  end

  genvar i;
  generate 
    for(i=0;i<`DCACHE_BLOCKWORDS;i=i+1) begin: SRAM_REQ
      assign data_invorflu_sram_rreq_setidx[i]    = {tag_dirtySetIdx_st0,tag_dirtyWayMask_st0}      ;

      assign data_writehit_sram_wreq_setidx[i]    = {core_req_setidx_st1,tag_waymaskHit_bin_st1}                      ;
      assign data_writehit_sram_wreq_data[i]      = core_req_st1_data_map_sameword_v[get_banken_perBankBlockIdx_v[i]] ;
      assign data_writehit_sram_wreq_waymask[i]   = core_req_st1_remap_wordoffset1h_v[get_banken_perBankBlockIdx_v[i]];
      
      assign data_readhit_sram_rreq_setidx[i]     = {core_req_setidx_st1,tag_waymaskHit_bin_st1}        ;
      
      assign data_replaceread_sram_rreq_setidx[i] = {miss_rsp_setidx_st1,tag_waymaskReplacement_bin_st1};
      
      assign data_missrsp_sram_wreq_setidx[i]     = miss_replace_dirty_reg ? {miss_rsp_setidx_st2,tag_waymaskReplacement_bin_st2} : {miss_rsp_setidx_st1,tag_waymaskReplacement_bin_st1};
      assign data_missrsp_sram_wreq_data[i]       = miss_replace_dirty_reg ? mem_rsp_d_data_st2[`XLEN*(i+1)-1 -:`XLEN] : mem_rsp_d_data_st1[`XLEN*(i+1)-1 -:`XLEN];
      assign data_missrsp_sram_wreq_waymask[i]    = {(`DCACHE_BLOCKWORDS*`BYTESOFWORD){1'b1}}           ;

      assign data_access_r_req_valid[i]   = read_hit_st1 || data_replaceread_valid || data_invorflu_valid ;
      assign data_access_w_req_valid[i]   = data_fill_valid || (write_hit_st1&&get_banken_perBankValid[i]);
      assign data_access_w_req_setid[i]   = (data_access_w_req_mux || miss_replace_dirty_reg) ? data_missrsp_sram_wreq_setidx[i] : data_writehit_sram_wreq_setidx[i]  ;
      assign data_access_w_req_waymask[i] = (data_access_w_req_mux || miss_replace_dirty_reg) ? data_missrsp_sram_wreq_waymask[i] : data_writehit_sram_wreq_waymask[i];
      assign data_access_w_req_data[i]    = (data_access_w_req_mux || miss_replace_dirty_reg) ? data_missrsp_sram_wreq_data[i] : data_writehit_sram_wreq_data[i]      ;

      always@(*) begin //SRAM read require
        if(data_replaceread_valid) begin //replace
          data_access_r_req_setid[i] = data_replaceread_sram_rreq_setidx[i];
        end
        else if(data_invorflu_valid) begin //invorflu
          data_access_r_req_setid[i] = data_invorflu_sram_rreq_setidx[i]   ;
        end
        else begin //read hit
          data_access_r_req_setid[i] = data_readhit_sram_rreq_setidx[i]    ;
        end
      end

      sram_template #(
        .GEN_WIDTH (8              ),//single byte
        .NUM_SET   (SRAM_NSETS     ),
        .NUM_WAY   (`BYTESOFWORD   ),
        .SET_DEPTH (SRAM_SETIDXBITS)
      )
      data_access (
        .clk             (clk                         ),
        .rst_n           (rst_n                       ),
        .r_req_valid_i   (data_access_r_req_valid[i]  ),
        .r_req_setid_i   (data_access_r_req_setid[i]  ),
        .r_resp_data_o   (data_access_r_resp_data[i]  ),
        .w_req_valid_i   (data_access_w_req_valid[i]  ),
        .w_req_setid_i   (data_access_w_req_setid[i]  ),
        .w_req_waymask_i (data_access_w_req_waymask[i]),
        .w_req_data_i    (data_access_w_req_data[i]   )
      );

      assign data_access_rrsp[`XLEN*(i+1)-1 -:`XLEN] = data_access_r_resp_data[i];

    end
  endgenerate

  //coreRsp_st2 connection:
  reg                            core_rsp_st2_enq_is_write  ;
  reg [`WIDBITS-1:0]             core_rsp_st2_enq_instrid   ;
  reg [`DCACHE_NLANES*`XLEN-1:0] core_rsp_st2_enq_data      ;
  reg [`DCACHE_NLANES-1:0]       core_rsp_st2_enq_activemask;

  wire                            core_rsp_st2_deq_is_write  ;
  wire [`WIDBITS-1:0]             core_rsp_st2_deq_instrid   ;
  wire [`DCACHE_NLANES*`XLEN-1:0] core_rsp_st2_deq_data      ;
  wire [`DCACHE_NLANES-1:0]       core_rsp_st2_deq_activemask;

  wire core_rsp_st2_valid_from_memreq;

  assign core_rsp_st2_deq_ready = core_rsp_q_enq_ready && !core_rsp_st2_valid_from_memreq;

  always@(*) begin
    if(cache_hit_st1 && ((core_req_deq_valid&&core_req_deq_ready)||inject_tag_probe_reg) && core_rsp_from_core_st2_enq_ready) begin //cachehit resp
      core_rsp_st2_enq_valid    = 1'b1        ;
      //core_rsp_st2_enq_data     = 'd0         ;//DontCare
      core_rsp_st2_enq_is_write = is_write_st1;
    end
    else if(mshr_missrsp_out_valid) begin //miss resp
      core_rsp_st2_enq_valid    = 1'b1              ;
      //core_rsp_st2_enq_data     = mem_rsp_d_data_st1;
      core_rsp_st2_enq_is_write = 1'b0              ;
    end
    else if(wait_mshr_core_rsp_st1 || flu_core_rsp_st1 || inv_core_rsp_st1) begin //waitmshr, flush, invalidate resp
      core_rsp_st2_enq_valid    = 1'b1;
      //core_rsp_st2_enq_data     = 'd0 ;//DontCare
      core_rsp_st2_enq_is_write = 1'b0;
    end
    else if(read_hit_st2_valid && !core_rsp_q_enq_ready) begin //hold ReadHit resp
      core_rsp_st2_enq_valid    = 1'b1            ;
      //core_rsp_st2_enq_data     = data_access_rrsp;
      core_rsp_st2_enq_is_write = 1'b0            ;
    end
    else begin
      core_rsp_st2_enq_valid    = 1'b0;
      //core_rsp_st2_enq_data     = 'd0 ;//DontCare
      core_rsp_st2_enq_is_write = 1'b0;
    end
  end

  always@(*) begin
    if(mshr_missrsp_out_valid) begin
      core_rsp_st2_enq_data     = mem_rsp_d_data_st1;
    end
    else if(read_hit_st2_valid) begin
      core_rsp_st2_enq_data     = data_access_rrsp  ;
    end
    else begin
      core_rsp_st2_enq_data     = 'd0               ;
    end
  end

  always@(*) begin
    if((cache_hit_st1&&((core_req_deq_valid&&core_req_deq_ready)||inject_tag_probe_reg)) || wait_mshr_core_rsp_st1 || flu_core_rsp_st1 || inv_core_rsp_st1) begin //comes from coreReq
      core_rsp_st2_enq_instrid    = core_req_instrid_st1   ;
      core_rsp_st2_enq_activemask = core_req_activemask_st1;
    end
    else if(mshr_missrsp_out_valid) begin //comes from mshr
      core_rsp_st2_enq_instrid    = miss_rsp_ti_st1_instrid   ;
      core_rsp_st2_enq_activemask = miss_rsp_ti_st1_activemask;
    end
    else begin
      core_rsp_st2_enq_instrid    = miss_rsp_ti_st1_instrid   ;
      core_rsp_st2_enq_activemask = miss_rsp_ti_st1_activemask;
    end
  end

  assign core_rsp_st2_enq_bits = {core_rsp_st2_enq_is_write  ,
                                  core_rsp_st2_enq_instrid   ,
                                  core_rsp_st2_enq_data      ,
                                  core_rsp_st2_enq_activemask};

  assign core_rsp_st2_deq_is_write   = core_rsp_st2_deq_bits[`WIDBITS+`DCACHE_NLANES*`XLEN+`DCACHE_NLANES];
  assign core_rsp_st2_deq_instrid    = core_rsp_st2_deq_bits[`WIDBITS+`DCACHE_NLANES*`XLEN+`DCACHE_NLANES-1 -:`WIDBITS];
  assign core_rsp_st2_deq_data       = core_rsp_st2_deq_bits[`DCACHE_NLANES*`XLEN+`DCACHE_NLANES-1:`DCACHE_NLANES];
  assign core_rsp_st2_deq_activemask = core_rsp_st2_deq_bits[`DCACHE_NLANES-1:0];

  //coreRsp_st2_perLaneAddr connection: 
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      core_rsp_st2_activemask   <= 'd0;
      core_rsp_st2_blockoffset  <= 'd0;
      core_rsp_st2_wordoffset1h <= 'd0;
    end
    else begin
      if((cache_hit_st1&&core_req_deq_valid&&core_req_deq_ready) || wait_mshr_core_rsp_st1 || flu_core_rsp_st1 || inv_core_rsp_st1) begin //comes from coreReq
       core_rsp_st2_activemask   <= core_req_activemask_st1  ;
       core_rsp_st2_blockoffset  <= core_req_blockoffset_st1 ;
       core_rsp_st2_wordoffset1h <= core_req_wordoffset1h_st1;
      end
      else if(mshr_missrsp_out_valid) begin //comes from mshr
        core_rsp_st2_activemask   <= miss_rsp_ti_st1_activemask  ;
        core_rsp_st2_blockoffset  <= miss_rsp_ti_st1_blockoffset ;
        core_rsp_st2_wordoffset1h <= miss_rsp_ti_st1_wordoffset1h;
      end
      else begin //hold
        core_rsp_st2_activemask   <= core_rsp_st2_activemask  ;
        core_rsp_st2_blockoffset  <= core_rsp_st2_blockoffset ;
        core_rsp_st2_wordoffset1h <= core_rsp_st2_wordoffset1h;
      end
    end
  end

  //indicate where the coreRsp comes from
  wire core_rsp_st2_valid_from_corereq;
  reg  core_rsp_st2_valid_from_memrsp ;
  //wire core_rsp_st2_valid_from_memreq ;

  //handshake signals: readHit_st2
  assign read_hit_st2_enq_valid = core_req_st1_valid;
  assign read_hit_st2_deq_ready = !(core_rsp_st2_valid_from_memreq || core_rsp_st2_valid_from_memrsp);

  //coreRsp_st2_valid: indicate coreRsp can be passed to coreRsp_Q
  assign core_rsp_st2_valid = core_rsp_st2_valid_from_corereq || core_rsp_st2_valid_from_memrsp || core_rsp_st2_valid_from_memreq;

  //MemOrder to CoreOrder
  wire [`DCACHE_BLOCKWORDS*`XLEN-1:0] core_rsp_st2_data_memorder ;
  wire [`DCACHE_NLANES*`XLEN-1:0]     core_rsp_st2_data_coreorder;

  wire [`XLEN-1:0]                    core_rsp_st2_data_memorder_forselect [0:`DCACHE_BLOCKWORDS-1];
  wire [`DCACHE_BLOCKOFFSETBITS-1:0]  mem2core_blockoffset_choose          [0:`DCACHE_NLANES-1];

  assign core_rsp_st2_data_memorder = read_hit_st2_valid ? data_access_rrsp : core_rsp_st2_deq_data;
  
  genvar d;
  generate
    for(d=0;d<`DCACHE_NLANES;d=d+1) begin: MEM2CORE_ORDER
      assign mem2core_blockoffset_choose[d] = core_rsp_st2_blockoffset[`DCACHE_BLOCKOFFSETBITS*(d+1)-1 -:`DCACHE_BLOCKOFFSETBITS];
      assign core_rsp_st2_data_coreorder[`XLEN*(d+1)-1 -:`XLEN] = core_rsp_st2_data_memorder_forselect[mem2core_blockoffset_choose[d]];
    end
  endgenerate

  genvar g;
  generate
    for(g=0;g<`DCACHE_BLOCKWORDS;g=g+1) begin: MEMORDER_S2V
      assign core_rsp_st2_data_memorder_forselect[g] = core_rsp_st2_data_memorder[`XLEN*(g+1)-1 -:`XLEN];
    end
  endgenerate

  //coreRspFromMemReq
  wire                            corersp_from_memreq_is_write  ;
  wire [`WIDBITS-1:0]             corersp_from_memreq_instrid   ;
  wire [`DCACHE_NLANES-1:0]       corersp_from_memreq_activemask;

  //coreRsp_Q connection
  wire                            core_rsp_q_enq_is_write  ;
  wire [`WIDBITS-1:0]             core_rsp_q_enq_instrid   ;
  wire [`DCACHE_NLANES*`XLEN-1:0] core_rsp_q_enq_data      ;
  wire [`DCACHE_NLANES-1:0]       core_rsp_q_enq_activemask;

  assign core_rsp_q_enq_is_write   = core_rsp_st2_valid_from_memreq ? corersp_from_memreq_is_write   : core_rsp_st2_deq_is_write  ;
  assign core_rsp_q_enq_instrid    = core_rsp_st2_valid_from_memreq ? corersp_from_memreq_instrid    : core_rsp_st2_deq_instrid   ;
  assign core_rsp_q_enq_data       = core_rsp_st2_data_coreorder                                                                  ;
  assign core_rsp_q_enq_activemask = core_rsp_st2_valid_from_memreq ? corersp_from_memreq_activemask : core_rsp_st2_deq_activemask;

  //TODO: memRsp invorflu don't need RSP to Core?
  //assign core_rsp_q_enq_valid = core_rsp_st2_valid || (mem_rsp_is_invorflu&&mem_rsp_q_deq_valid&&mem_rsp_q_deq_ready);
  assign core_rsp_q_enq_valid = core_rsp_st2_valid;
  assign core_rsp_q_deq_ready = core_rsp_ready_i  ;

  assign core_rsp_q_enq_bits = {core_rsp_q_enq_is_write  ,
                                core_rsp_q_enq_instrid   ,
                                core_rsp_q_enq_data      ,
                                core_rsp_q_enq_activemask};

  //coreReqmemConflict_Reg: not use
  //reg corereq_mem_conflict_reg;

  //dirtyReplace_st2
  /*
  reg                                                    dirty_replace_st2_has_corersp    ;
  reg [`WIDBITS-1:0]                                     dirty_replace_st2_corersp_instrid;
  reg [2:0]                                              dirty_replace_st2_a_opcode       ;
  reg [2:0]                                              dirty_replace_st2_a_param        ;
  reg [2+$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS:0] dirty_replace_st2_a_source       ;
  reg [`XLEN-1:0]                                        dirty_replace_st2_a_addr         ;
  reg [`DCACHE_BLOCKWORDS*`XLEN-1:0]                     dirty_replace_st2_a_data         ;
  reg [`DCACHE_BLOCKWORDS*`BYTESOFWORD-1:0]              dirty_replace_st2_a_mask         ;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      dirty_replace_st2_has_corersp     <= 'd0;
      dirty_replace_st2_corersp_instrid <= 'd0;
      dirty_replace_st2_a_opcode        <= 'd0;
      dirty_replace_st2_a_param         <= 'd0;
      dirty_replace_st2_a_source        <= 'd0;
      dirty_replace_st2_a_addr          <= 'd0;
      dirty_replace_st2_a_data          <= 'd0;
      dirty_replace_st2_a_mask          <= 'd0;
    end
    else begin
      dirty_replace_st2_has_corersp     <= dirty_replace_memreq_has_corersp    ;
      dirty_replace_st2_corersp_instrid <= dirty_replace_memreq_corersp_instrid;
      dirty_replace_st2_a_opcode        <= dirty_replace_memreq_a_opcode       ;
      dirty_replace_st2_a_param         <= dirty_replace_memreq_a_param        ;
      dirty_replace_st2_a_source        <= dirty_replace_memreq_a_source       ;
      dirty_replace_st2_a_addr          <= dirty_replace_memreq_a_addr         ;
      dirty_replace_st2_a_data          <= dirty_replace_memreq_a_data         ;
      dirty_replace_st2_a_mask          <= dirty_replace_memreq_a_mask         ;
    end
  end
  */

  //for flushL2:
  wire flush_l2    ;//when waitfor_l2_flush: enable to start a L2flush require
  reg  flush_l2_reg;//regEnable(flush_l2)

  assign flush_l2 = (!mem_rsp_is_invorflu&&!mem_rsp_is_write&&mem_rsp_q_deq_valid&&mem_rsp_q_deq_ready) || (!flush_l2_reg&&(invalidate_no_dirty||flush_no_dirty)&&memreq_arb_in2_ready);
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      flush_l2_reg <= 'd0;
    end
    else if(mem_rsp_is_invorflu) begin
      flush_l2_reg <= 'd0;
    end
    else begin
      flush_l2_reg <= (memreq_arb_in2_valid&&memreq_arb_in2_ready) ? flush_l2 : flush_l2_reg;
    end
  end

  //Queue: memReq_Q
  wire mem_req_q_enq_valid;
  wire mem_req_q_enq_ready;
  wire mem_req_q_deq_valid;
  wire mem_req_q_deq_ready;
  wire [`WIDBITS+$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS+`XLEN+`DCACHE_BLOCKWORDS*`XLEN+`DCACHE_BLOCKWORDS*`BYTESOFWORD+9:0] mem_req_q_enq_bits;
  wire [`WIDBITS+$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS+`XLEN+`DCACHE_BLOCKWORDS*`XLEN+`DCACHE_BLOCKWORDS*`BYTESOFWORD+9:0] mem_req_q_deq_bits;

  wire [4:0] mem_req_q_count   ;
  wire       mem_req_q_alm_full;

  assign mem_req_q_alm_full = (mem_req_q_count > 27); //FIFO_DEPTH - 4

  //memReq_Q.io.enq <> MemReqArb.io.out
  assign mem_req_q_enq_bits = {memreq_arb_out_has_corersp    ,
                               memreq_arb_out_corersp_instrid,
                               memreq_arb_out_a_opcode       ,
                               memreq_arb_out_a_param        ,
                               memreq_arb_out_a_source       ,
                               memreq_arb_out_a_addr         ,
                               memreq_arb_out_a_data         ,
                               memreq_arb_out_a_mask         };

  assign mem_req_q_enq_valid  = memreq_arb_out_valid;
  assign memreq_arb_out_ready = mem_req_q_enq_ready ;

  stream_fifo_useSRAM_with_count #(
    .DATA_WIDTH (`WIDBITS+$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS+`XLEN+`DCACHE_BLOCKWORDS*`XLEN+`DCACHE_BLOCKWORDS*`BYTESOFWORD+10),
    .FIFO_DEPTH (32)
  )
  mem_req_q (
    .clk          (clk                ),
    .rst_n        (rst_n              ),
    .w_ready_o    (mem_req_q_enq_ready),
    .w_valid_i    (mem_req_q_enq_valid),
    .w_data_i     (mem_req_q_enq_bits ),
    .r_valid_o    (mem_req_q_deq_valid),
    .r_ready_i    (mem_req_q_deq_ready),
    .r_data_o     (mem_req_q_deq_bits ),
    .fifo_count_o (mem_req_q_count    )
  );

  wire                                                    mem_req_q_deq_has_corersp    ;
  wire [`WIDBITS-1:0]                                     mem_req_q_deq_corersp_instrid;
  wire [2:0]                                              mem_req_q_deq_a_opcode       ;
  wire [2:0]                                              mem_req_q_deq_a_param        ;
  wire [2+$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS:0] mem_req_q_deq_a_source       ;
  wire [`XLEN-1:0]                                        mem_req_q_deq_a_addr         ;
  wire [`DCACHE_BLOCKWORDS*`XLEN-1:0]                     mem_req_q_deq_a_data         ;
  wire [`DCACHE_BLOCKWORDS*`BYTESOFWORD-1:0]              mem_req_q_deq_a_mask         ;

  assign mem_req_q_deq_has_corersp     = mem_req_q_deq_bits[`WIDBITS+$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS+`XLEN+`DCACHE_BLOCKWORDS*`XLEN+`DCACHE_BLOCKWORDS*`BYTESOFWORD+9];
  assign mem_req_q_deq_corersp_instrid = mem_req_q_deq_bits[`WIDBITS+$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS+`XLEN+`DCACHE_BLOCKWORDS*`XLEN+`DCACHE_BLOCKWORDS*`BYTESOFWORD+8 -:`WIDBITS];
  assign mem_req_q_deq_a_opcode        = mem_req_q_deq_bits[$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS+`XLEN+`DCACHE_BLOCKWORDS*`XLEN+`DCACHE_BLOCKWORDS*`BYTESOFWORD+8 -:3];
  assign mem_req_q_deq_a_param         = mem_req_q_deq_bits[$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS+`XLEN+`DCACHE_BLOCKWORDS*`XLEN+`DCACHE_BLOCKWORDS*`BYTESOFWORD+5 -:3];
  assign mem_req_q_deq_a_source        = mem_req_q_deq_bits[$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS+`XLEN+`DCACHE_BLOCKWORDS*`XLEN+`DCACHE_BLOCKWORDS*`BYTESOFWORD+2 -:3+$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS];
  assign mem_req_q_deq_a_addr          = mem_req_q_deq_bits[`XLEN+`DCACHE_BLOCKWORDS*`XLEN+`DCACHE_BLOCKWORDS*`BYTESOFWORD-1 -:`XLEN];
  assign mem_req_q_deq_a_data          = mem_req_q_deq_bits[`DCACHE_BLOCKWORDS*`XLEN+`DCACHE_BLOCKWORDS*`BYTESOFWORD-1 -:`DCACHE_BLOCKWORDS*`XLEN];
  assign mem_req_q_deq_a_mask          = mem_req_q_deq_bits[`DCACHE_BLOCKWORDS*`BYTESOFWORD-1:0];

  //coreRsp_st2_valid_from_coreReq_Reg connection
  assign core_rsp_from_core_st2_enq_valid = core_req_st1_valid || inject_tag_probe_reg;
  assign core_rsp_from_core_st2_enq_bits  = read_hit_st1 || write_hit_st1             ;
  assign core_rsp_from_core_st2_deq_ready = !(core_rsp_st2_valid_from_memrsp||core_rsp_st2_valid_from_memreq) && core_rsp_q_enq_ready;

  assign core_rsp_st2_valid_from_corereq = core_rsp_from_core_st2_deq_bits && core_rsp_from_core_st2_deq_valid && core_rsp_from_core_st2_deq_ready;
  assign core_rsp_st2_valid_from_memreq  = wshr_pushReq_valid && mem_req_q_deq_has_corersp && !core_rsp_st2_valid_from_memrsp;

  always@(posedge clk or negedge rst_n) begin //regEnable(mshr_missrsp_out_valid)
    if(!rst_n) begin
      core_rsp_st2_valid_from_memrsp <= 'd0;
    end
    else begin
      core_rsp_st2_valid_from_memrsp <= core_rsp_q_enq_ready ? mshr_missrsp_out_valid : core_rsp_st2_valid_from_memrsp;
    end
  end
  
  //connect memreqarb
  //MemReqArb.in(0) = dirtyReplace_st1
  assign memreq_arb_in0_valid           = tag_replace_status                  ;
  assign memreq_arb_in0_has_corersp     = dirty_replace_memreq_has_corersp    ;
  assign memreq_arb_in0_corersp_instrid = dirty_replace_memreq_corersp_instrid;
  assign memreq_arb_in0_a_opcode        = dirty_replace_memreq_a_opcode       ;
  assign memreq_arb_in0_a_param         = dirty_replace_memreq_a_param        ;
  assign memreq_arb_in0_a_source        = dirty_replace_memreq_a_source       ;
  assign memreq_arb_in0_a_addr          = dirty_replace_memreq_a_addr         ;
  assign memreq_arb_in0_a_data          = dirty_replace_memreq_a_data         ;
  assign memreq_arb_in0_a_mask          = dirty_replace_memreq_a_mask         ;
  //MemReqArb.in(1) = miss_mem_req
  //assign memreq_arb_in1_valid           = core_req_st1_valid && core_req_deq_valid && core_req_deq_ready && ((write_miss_st1||read_miss_st1)&&mshr_probe_out_mshr_status=='d0) && !inject_tag_probe; //mshr_probe_out_mshr_status=='d0: only primary available
  assign memreq_arb_in1_valid           = core_req_st1_valid && core_req_deq_valid && core_req_deq_ready && (write_miss_st1||(read_miss_st1&&mshr_probe_out_mshr_status=='d0)) && !inject_tag_probe;
  assign memreq_arb_in1_has_corersp     = miss_mem_req_has_corersp    ;
  assign memreq_arb_in1_corersp_instrid = miss_mem_req_corersp_instrid;
  assign memreq_arb_in1_a_opcode        = miss_mem_req_a_opcode       ;
  assign memreq_arb_in1_a_param         = miss_mem_req_a_param        ;
  assign memreq_arb_in1_a_source        = miss_mem_req_a_source       ;
  assign memreq_arb_in1_a_addr          = miss_mem_req_a_addr         ;
  assign memreq_arb_in1_a_data          = miss_mem_req_a_data         ;
  assign memreq_arb_in1_a_mask          = miss_mem_req_a_mask         ;
  //MemReqArb.in(2) = invorflu_memreq
  assign memreq_arb_in2_valid           = waitfor_l2_flush_st2 ? flush_l2 : invorflu_memreq_valid_st2;//invorflu_memreq_valid_st2?
  assign memreq_arb_in2_has_corersp     = invorflu_memreq_has_corersp    ;
  assign memreq_arb_in2_corersp_instrid = invorflu_memreq_corersp_instrid;
  assign memreq_arb_in2_a_opcode        = invorflu_memreq_a_opcode       ;
  assign memreq_arb_in2_a_param         = invorflu_memreq_a_param        ;
  assign memreq_arb_in2_a_source        = invorflu_memreq_a_source       ;
  assign memreq_arb_in2_a_addr          = invorflu_memreq_a_addr         ;
  assign memreq_arb_in2_a_data          = invorflu_memreq_a_data         ;
  assign memreq_arb_in2_a_mask          = invorflu_memreq_a_mask         ;

  //memReq is write/read
  wire mem_req_is_write_st3;
  wire mem_req_is_read_st3 ;

  assign mem_req_is_write_st3 = (mem_req_q_deq_a_opcode==`TLAOP_PUTFULL) || ((mem_req_q_deq_a_opcode==`TLAOP_PUTPART)&&(mem_req_q_deq_a_param=='d0));
  assign mem_req_is_read_st3  = (mem_req_q_deq_a_opcode==`TLAOP_GET) && (mem_req_q_deq_a_param=='d0);

  //pushWshrValid: enable to push wshr
  wire wshr_protect                ;
  wire corersp_blocked_or_wshr_full;
  wire wshr_pass                   ;
  wire push_wshr_valid             ;

  assign wshr_protect                 = wshr_conflict && (mem_req_is_write_st3||mem_req_is_read_st3) && mem_req_q_deq_valid;// && mem_req_ready_i;
  assign corersp_blocked_or_wshr_full = ((!core_rsp_q_enq_ready&&mem_req_q_deq_has_corersp)||!wshr_pushReq_ready) && mem_req_is_write_st3;
  assign wshr_pass                    = !wshr_protect && !corersp_blocked_or_wshr_full;
  assign push_wshr_valid              = (wshr_pass||invorflu_memreq_valid_st1) && mem_req_q_deq_valid && mem_req_q_deq_ready && mem_req_is_write_st3;

  //wshr connection
  wire [`BABITS-1:0] push_req_ba;

  assign push_req_ba = mem_req_q_deq_a_addr >> (`XLEN-`BABITS);

  assign wshr_pushReq_valid     = push_wshr_valid;
  assign wshr_pushReq_blockAddr = push_req_ba    ;
  assign wshr_popReq_valid      = mem_rsp_q_deq_valid && mem_rsp_is_write;
  assign wshr_popReq_bits       = mem_rsp_d_source_st0[$clog2(`DCACHE_WSHR_ENTRY)+`DCACHE_SETIDXBITS-1:`DCACHE_SETIDXBITS];//ATTENTION: `DCACHE_MSHRENTRY > `DCACHE_WSHR_ENTRY

  //memReq_Q.io.deq.ready
  assign mem_req_q_deq_ready = (wshr_pass||(invorflu_memreq_valid_st1&&wshr_pushReq_ready)) && mem_req_ready_i && !core_rsp_st2_valid_from_memrsp;

  //memReq_st3
  reg [2:0]                                              mem_req_st3_a_opcode;
  reg [2:0]                                              mem_req_st3_a_param ;
  reg [2+$clog2(`DCACHE_MSHRENTRY)+`DCACHE_SETIDXBITS:0] mem_req_st3_a_source;
  reg [`XLEN-1:0]                                        mem_req_st3_a_addr  ;
  reg [`DCACHE_BLOCKWORDS*`XLEN-1:0]                     mem_req_st3_a_data  ;
  reg [`DCACHE_BLOCKWORDS*`BYTESOFWORD-1:0]              mem_req_st3_a_mask  ;

  wire [`DCACHE_SETIDXBITS-1:0] mem_req_setidx_st2;

  assign mem_req_setidx_st2 = mem_req_q_deq_a_addr[`XLEN-`DCACHE_TAGBITS-1 -:`DCACHE_SETIDXBITS];

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      mem_req_st3_a_opcode <= 'd0;
      mem_req_st3_a_param  <= 'd0;
      mem_req_st3_a_addr   <= 'd0;
      mem_req_st3_a_data   <= 'd0;
      mem_req_st3_a_mask   <= 'd0;
    end
    else begin
      if(wshr_pass && mem_req_q_deq_valid && mem_req_q_deq_ready) begin
        mem_req_st3_a_opcode <= mem_req_q_deq_a_opcode;
        mem_req_st3_a_param  <= mem_req_q_deq_a_param ;
        mem_req_st3_a_addr   <= mem_req_q_deq_a_addr  ;
        mem_req_st3_a_data   <= mem_req_q_deq_a_data  ;
        mem_req_st3_a_mask   <= mem_req_q_deq_a_mask  ;
      end
      else begin
        mem_req_st3_a_opcode <= mem_req_st3_a_opcode;
        mem_req_st3_a_param  <= mem_req_st3_a_param ;
        mem_req_st3_a_addr   <= mem_req_st3_a_addr  ;
        mem_req_st3_a_data   <= mem_req_st3_a_data  ;
        mem_req_st3_a_mask   <= mem_req_st3_a_mask  ;
      end
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      mem_req_st3_a_source <= 'd0;
    end
    else begin
      if(mem_req_is_write_st3 && mem_req_q_deq_valid && mem_req_q_deq_ready) begin
        mem_req_st3_a_source <= WM_ENTRY_EQUAL ? {3'b000,wshr_pushedIdx,mem_req_setidx_st2} :{3'b000,{(`DCACHE_MSHRENTRY-`DCACHE_WSHR_ENTRY){1'b0}},wshr_pushedIdx,mem_req_setidx_st2};
      end
      else if(wshr_pass && mem_req_q_deq_valid && mem_req_q_deq_ready) begin
        mem_req_st3_a_source <= mem_req_q_deq_a_source;
      end
      else begin
        mem_req_st3_a_source <= mem_req_st3_a_source;
      end
    end
  end

  //Queue: coreReqMask_Q
  wire                      core_req_mask_q_enq_valid;
  wire                      core_req_mask_q_enq_ready;
  wire                      core_req_mask_q_deq_valid;
  wire                      core_req_mask_q_deq_ready;
  wire [`DCACHE_NLANES-1:0] core_req_mask_q_enq_bits ;
  wire [`DCACHE_NLANES-1:0] core_req_mask_q_deq_bits ;

  stream_fifo #(
    .DATA_WIDTH (`DCACHE_NLANES),
    .FIFO_DEPTH (32)
  )
  core_req_mask_q (
    .clk       (clk                      ),
    .rst_n     (rst_n                    ),
    .w_ready_o (core_req_mask_q_enq_ready),
    .w_valid_i (core_req_mask_q_enq_valid),
    .w_data_i  (core_req_mask_q_enq_bits ),
    .r_valid_o (core_req_mask_q_deq_valid),
    .r_ready_i (core_req_mask_q_deq_ready),
    .r_data_o  (core_req_mask_q_deq_bits )
  );

  //coreReqMask_Q connection
  assign core_req_mask_q_enq_valid = mem_req_q_enq_valid                        ;
  assign core_req_mask_q_deq_ready = mem_req_q_deq_ready && mem_req_q_deq_valid && core_rsp_q_enq_ready &&
    !(wshr_conflict && (mem_req_is_write_st3||mem_req_is_read_st3)) && ! (mem_req_is_write_st3 && !push_wshr_valid);
  assign core_req_mask_q_enq_bits  = core_req_activemask_st1                    ;

  reg [`DCACHE_NLANES-1:0] core_req_mask_q_deq_bits_reg;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      core_req_mask_q_deq_bits_reg <= 'd0;
    end
    else if(core_req_mask_q_deq_valid && core_req_mask_q_deq_ready) begin
      core_req_mask_q_deq_bits_reg <= core_req_mask_q_deq_bits;
    end
    else begin
      core_req_mask_q_deq_bits_reg <= core_req_mask_q_deq_bits_reg;
    end
  end

  //corersp_from_memreq connection
  assign corersp_from_memreq_is_write   = 1'b1                         ;
  assign corersp_from_memreq_instrid    = mem_req_q_deq_corersp_instrid;
  assign corersp_from_memreq_activemask = core_req_mask_q_deq_bits;//(core_req_mask_q_deq_valid && core_req_mask_q_deq_ready) ? core_req_mask_q_deq_bits : core_req_mask_q_deq_bits_reg;

  //mem_req_valid
  reg mem_req_valid;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      mem_req_valid <= 'd0;
    end
    else begin
      mem_req_valid <= ((mem_req_q_deq_valid&&mem_req_q_deq_ready) ^ (mem_req_valid_o&&mem_req_ready_i)) ? (mem_req_q_deq_valid&&mem_req_q_deq_ready) : mem_req_valid;
    end
  end

  //outputs
  assign core_req_ready_o = core_req_enq_ready && !proberead_allocatewrite_conf && !inflight_read_write_miss_w && !inject_tag_probe && !readmiss_same_addr && tag_probeRead_ready && (mshr_mshr_status_st0!=3'b011) && (mshr_mshr_status_st0!=3'b001) && !mem_req_q_alm_full;
  assign mem_rsp_ready_o  = mem_rsp_q_enq_ready;

  //assign core_rsp_valid_o      = core_rsp_q_deq_valid                                             ;
  assign core_rsp_valid_o      = core_rsp_q_deq_valid && core_rsp_q_deq_ready                     ;
  assign core_rsp_is_write_o   = core_rsp_q_deq_bits[`WIDBITS+`DCACHE_NLANES*`XLEN+`DCACHE_NLANES];
  assign core_rsp_instrid_o    = core_rsp_q_deq_bits[`WIDBITS+`DCACHE_NLANES*`XLEN+`DCACHE_NLANES-1 -:`WIDBITS];
  assign core_rsp_data_o       = core_rsp_q_deq_bits[`DCACHE_NLANES*`XLEN+`DCACHE_NLANES-1:`DCACHE_NLANES];
  assign core_rsp_activemask_o = core_rsp_q_deq_bits[`DCACHE_NLANES-1:0];

  assign mem_req_valid_o       = mem_req_valid       ;
  assign mem_req_a_opcode_o    = mem_req_st3_a_opcode;
  assign mem_req_a_param_o     = mem_req_st3_a_param ;
  assign mem_req_a_source_o    = mem_req_st3_a_source;
  assign mem_req_a_addr_o      = mem_req_st3_a_addr  ;
  assign mem_req_a_data_o      = mem_req_st3_a_data  ;
  assign mem_req_a_mask_o      = mem_req_st3_a_mask  ;

endmodule

