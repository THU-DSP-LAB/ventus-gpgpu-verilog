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
// Description:接收host发来请求并进行缓存,然后给host发送接收成功的响应

`timescale 1ns/1ns
`include "define.v"

module inflight_wg_buffer(
  input                                 clk                                       ,
  input                                 rst_n                                     ,
  //host inputs
  input                                 host_wg_valid_i                           ,
  output                                host_wg_ready_o                           ,//add handshake signal
  input   [`WG_ID_WIDTH-1:0]            host_wg_id_i                              ,
  input   [`WF_COUNT_WIDTH_PER_WG-1:0]  host_num_wf_i                             ,
  input   [`WAVE_ITEM_WIDTH-1:0]        host_wf_size_i                            ,
  input   [`MEM_ADDR_WIDTH-1:0]         host_start_pc_i                           ,
  input   [`WG_SIZE_X_WIDTH*3-1:0]      host_kernel_size_3d_i                     ,
  input   [`MEM_ADDR_WIDTH-1:0]         host_pds_baseaddr_i                       ,
  input   [`MEM_ADDR_WIDTH-1:0]         host_csr_knl_i                            ,
  input   [`MEM_ADDR_WIDTH-1:0]         host_gds_baseaddr_i                       ,
  input   [`VGPR_ID_WIDTH:0]            host_vgpr_size_total_i                    ,
  input   [`SGPR_ID_WIDTH:0]            host_sgpr_size_total_i                    ,
  input   [`LDS_ID_WIDTH:0]             host_lds_size_total_i                     ,
  input   [`GDS_ID_WIDTH:0]             host_gds_size_total_i                     ,
  input   [`VGPR_ID_WIDTH:0]            host_vgpr_size_per_wf_i                   ,
  input   [`SGPR_ID_WIDTH:0]            host_sgpr_size_per_wf_i                   ,
  //dispatch controller inputs
  input                                 dis_controller_wg_alloc_valid_i           ,
  input                                 dis_controller_start_alloc_i              ,
  input                                 dis_controller_wg_dealloc_valid_i         ,
  input                                 dis_controller_wg_rejected_valid_i        ,
  //allocator and gpu interface inputs
  input   [`WG_ID_WIDTH-1:0]            allocator_wg_id_out_i                     ,
  input   [`WG_ID_WIDTH-1:0]            gpu_interface_dealloc_wg_id_i             ,

  //outputs to the host
  output                                inflight_wg_buffer_host_rcvd_ack_o        ,
  output                                inflight_wg_buffer_host_wf_done_o         ,
  output  [`WG_ID_WIDTH-1:0]            inflight_wg_buffer_host_wf_done_wg_id_o   ,
  //outputs to the allocator
  output                                inflight_wg_buffer_alloc_valid_o          ,
  output                                inflight_wg_buffer_alloc_available_o      ,
  output  [`WG_ID_WIDTH-1:0]            inflight_wg_buffer_alloc_wg_id_o          ,
  output  [`WF_COUNT_WIDTH_PER_WG-1:0]  inflight_wg_buffer_alloc_num_wf_o         ,
  output  [`VGPR_ID_WIDTH:0]            inflight_wg_buffer_alloc_vgpr_size_o      ,
  output  [`SGPR_ID_WIDTH:0]            inflight_wg_buffer_alloc_sgpr_size_o      ,
  output  [`LDS_ID_WIDTH:0]             inflight_wg_buffer_alloc_lds_size_o       ,
  output  [`GDS_ID_WIDTH:0]             inflight_wg_buffer_alloc_gds_size_o       ,
  //outputs to the gpu interface
  output                                inflight_wg_buffer_gpu_valid_o            ,
  output  [`VGPR_ID_WIDTH:0]            inflight_wg_buffer_gpu_vgpr_size_per_wf_o ,
  output  [`SGPR_ID_WIDTH:0]            inflight_wg_buffer_gpu_sgpr_size_per_wf_o ,
  output  [`WAVE_ITEM_WIDTH-1:0]        inflight_wg_buffer_gpu_wf_size_o          ,
  output  [`MEM_ADDR_WIDTH-1:0]         inflight_wg_buffer_start_pc_o             ,
  output  [`WG_SIZE_X_WIDTH*3-1:0]      inflight_wg_buffer_kernel_size_3d_o       ,
  output  [`MEM_ADDR_WIDTH-1:0]         inflight_wg_buffer_pds_baseaddr_o         ,
  output  [`MEM_ADDR_WIDTH-1:0]         inflight_wg_buffer_csr_knl_o              ,
  output  [`MEM_ADDR_WIDTH-1:0]         inflight_wg_buffer_gds_baseaddr_o         
  );
  //shared index between two tables
  localparam  SGPR_SIZE_L    = 0                                     ;
  localparam  SGPR_SIZE_H    = SGPR_SIZE_L + `SGPR_ID_WIDTH          ;
  localparam  VGPR_SIZE_L    = SGPR_SIZE_H + 1                       ;
  localparam  VGPR_SIZE_H    = VGPR_SIZE_L + `VGPR_ID_WIDTH          ;
  localparam  WG_ID_L        = VGPR_SIZE_H + 1                       ;
  localparam  WG_ID_H        = WG_ID_L + `WG_ID_WIDTH - 1            ;
  //index for table with waiting wg
  localparam  GDS_SIZE_L     = WG_ID_H + 1                           ;
  localparam  GDS_SIZE_H     = GDS_SIZE_L + `GDS_ID_WIDTH            ;
  localparam  LDS_SIZE_L     = GDS_SIZE_H + 1                        ;
  localparam  LDS_SIZE_H     = LDS_SIZE_L + `LDS_ID_WIDTH            ;
  localparam  WG_COUNT_L     = LDS_SIZE_H + 1                        ;
  localparam  WG_COUNT_H     = WG_COUNT_L + `WF_COUNT_WIDTH_PER_WG-1 ;
  //index for table with read wg
  localparam  WF_SIZE_L      = WG_ID_H + 1                           ;
  localparam  WF_SIZE_H      = WF_SIZE_L + `WAVE_ITEM_WIDTH - 1      ;
  localparam  GDS_BASEADDR_L = WF_SIZE_H + 1                         ;
  localparam  GDS_BASEADDR_H = GDS_BASEADDR_L + `MEM_ADDR_WIDTH - 1  ;
  localparam  START_PC_L     = GDS_BASEADDR_H + 1                    ;
  localparam  START_PC_H     = START_PC_L + `MEM_ADDR_WIDTH - 1      ;
  localparam  KNL_SZ_3D_L    = START_PC_H + 1                        ;
  localparam  KNL_SZ_3D_H    = KNL_SZ_3D_L + 3 * `WG_SIZE_X_WIDTH - 1;
  localparam  PDS_BASEADDR_L = KNL_SZ_3D_H + 1                       ;
  localparam  PDS_BASEADDR_H = PDS_BASEADDR_L + `MEM_ADDR_WIDTH - 1  ;
  localparam  CSR_KNL_L      = PDS_BASEADDR_H + 1                    ;
  localparam  CSR_KNL_H      = CSR_KNL_L + `MEM_ADDR_WIDTH - 1       ;

  localparam  WAIT_ENTRY_WIDTH  = `WG_ID_WIDTH + `WF_COUNT_WIDTH_PER_WG + (`VGPR_ID_WIDTH + 1) + (`SGPR_ID_WIDTH + 1) + (`LDS_ID_WIDTH + 1) + (`GDS_ID_WIDTH + 1);
  localparam  READY_ENTRY_WIDTH = `MEM_ADDR_WIDTH + `MEM_ADDR_WIDTH + 3 * `WG_SIZE_X_WIDTH + `MEM_ADDR_WIDTH + `MEM_ADDR_WIDTH + `WAVE_ITEM_WIDTH + `WG_ID_WIDTH + (`VGPR_ID_WIDTH + 1) + (`SGPR_ID_WIDTH + 1);

  //host state
  localparam  ST_RD_HOST_IDLE          = 4'b0001;
  localparam  ST_RD_HOST_GET_FROM_HOST = 4'b0010;
  localparam  ST_RD_HOST_ACK_TO_HOST   = 4'b0100;
  localparam  ST_RD_HOST_IDLE_BUBBLE   = 4'b1000;
  //allocator state
  localparam  ST_ALLOC_IDLE            = 8'b0000_0001;
  localparam  ST_ALLOC_WAIT_RESULT     = 8'b0000_0010;
  localparam  ST_ALLOC_FIND_ACCEPTED   = 8'b0000_0100;
  localparam  ST_ALLOC_CLEAR_ACCEPTED  = 8'b0000_1000;
  localparam  ST_ALLOC_FIND_REJECTED   = 8'b0001_0000;
  localparam  ST_ALLOC_CLEAR_REJECTED  = 8'b0010_0000;
  localparam  ST_ALLOC_GET_ALLOC_WG    = 8'b0100_0000;
  localparam  ST_ALLOC_UP_ALLOC_WG     = 8'b1000_0000;

  //state
  reg   [7:0]                         inflight_tbl_alloc_st    ;
  reg   [3:0]                         inflight_tbl_rd_host_st  ;

  wire  [`NUMBER_ENTRIES-1:0]         waiting_tbl_valid_rotated;
  wire  [`NUMBER_ENTRIES-1:0]         valid_not_pending        ;

  //host inputs reg
  reg                                 host_wg_valid_reg        ;
  reg   [`WG_ID_WIDTH-1:0]            host_wg_id_reg           ;
  reg   [`WF_COUNT_WIDTH_PER_WG-1:0]  host_num_wf_reg          ;
  reg   [`WAVE_ITEM_WIDTH-1:0]        host_wf_size_reg         ;
  reg   [`MEM_ADDR_WIDTH-1:0]         host_start_pc_reg        ;
  reg   [`WG_SIZE_X_WIDTH*3-1:0]      host_kernel_size_3d_reg  ;
  reg   [`MEM_ADDR_WIDTH-1:0]         host_pds_baseaddr_reg    ;
  reg   [`MEM_ADDR_WIDTH-1:0]         host_csr_knl_reg         ;
  reg   [`MEM_ADDR_WIDTH-1:0]         host_gds_baseaddr_reg    ;
  reg   [`VGPR_ID_WIDTH:0]            host_vgpr_size_total_reg ;
  reg   [`SGPR_ID_WIDTH:0]            host_sgpr_size_total_reg ;
  reg   [`LDS_ID_WIDTH:0]             host_lds_size_total_reg  ;
  reg   [`GDS_ID_WIDTH:0]             host_gds_size_total_reg  ;
  reg   [`VGPR_ID_WIDTH:0]            host_vgpr_size_per_wf_reg;
  reg   [`SGPR_ID_WIDTH:0]            host_sgpr_size_per_wf_reg;
  //dispatch controller inputs reg
  reg                                 dis_controller_wg_alloc_valid_reg   ;
  reg                                 dis_controller_start_alloc_reg      ;
  reg                                 dis_controller_wg_dealloc_valid_reg ;
  reg                                 dis_controller_wg_rejected_valid_reg;
  //allocator and gpu interface inputs reg
  reg   [`WG_ID_WIDTH-1:0]            allocator_wg_id_out_reg        ;
  reg   [`WG_ID_WIDTH-1:0]            gpu_interface_dealloc_wg_id_reg;
  //outputs to the host reg
  reg                                 inflight_wg_buffer_host_rcvd_ack_reg     ;
  reg                                 inflight_wg_buffer_host_wf_done_reg      ;
  reg   [`WG_ID_WIDTH-1:0]            inflight_wg_buffer_host_wf_done_wg_id_reg;
  //outputs to the gpu interface reg
  reg                                 inflight_wg_buffer_gpu_valid_reg           ;
  reg   [`VGPR_ID_WIDTH:0]            inflight_wg_buffer_gpu_vgpr_size_per_wf_reg;
  reg   [`SGPR_ID_WIDTH:0]            inflight_wg_buffer_gpu_sgpr_size_per_wf_reg;
  reg   [`WAVE_ITEM_WIDTH-1:0]        inflight_wg_buffer_gpu_wf_size_reg         ;
  reg   [`MEM_ADDR_WIDTH-1:0]         inflight_wg_buffer_start_pc_reg            ;
  reg   [`WG_SIZE_X_WIDTH*3-1:0]      inflight_wg_buffer_kernel_size_3d_reg      ;
  reg   [`MEM_ADDR_WIDTH-1:0]         inflight_wg_buffer_pds_baseaddr_reg        ;
  reg   [`MEM_ADDR_WIDTH-1:0]         inflight_wg_buffer_csr_knl_reg             ;
  reg   [`MEM_ADDR_WIDTH-1:0]         inflight_wg_buffer_gds_baseaddr_reg        ;
  //outputs to the allocator reg
  reg                                 wg_waiting_alloc_valid                ; 
  reg   [`WG_ID_WIDTH-1:0]            inflight_wg_buffer_alloc_wg_id_reg    ;
  reg   [`WF_COUNT_WIDTH_PER_WG-1:0]  inflight_wg_buffer_alloc_num_wf_reg   ;
  reg   [`VGPR_ID_WIDTH:0]            inflight_wg_buffer_alloc_vgpr_size_reg;
  reg   [`SGPR_ID_WIDTH:0]            inflight_wg_buffer_alloc_sgpr_size_reg;
  reg   [`LDS_ID_WIDTH:0]             inflight_wg_buffer_alloc_lds_size_reg ;
  reg   [`GDS_ID_WIDTH:0]             inflight_wg_buffer_alloc_gds_size_reg ;

  reg   [`NUMBER_ENTRIES-1:0]         waiting_tbl_valid  ;
  reg                                 new_index_wr_en    ;
  reg   [WAIT_ENTRY_WIDTH-1:0]        new_entry_wg_reg   ;
  reg   [READY_ENTRY_WIDTH-1:0]       ready_tbl_wr_reg   ;
  reg   [`ENTRY_ADDR_WIDTH-1:0]       new_index          ;     

  reg   [`WG_ID_WIDTH-1:0]            tbl_walk_wg_id_searched;
  wire  [WAIT_ENTRY_WIDTH-1:0]        table_walk_rd_reg      ;
  wire  [READY_ENTRY_WIDTH-1:0]       ready_tbl_rd_reg       ;
  reg                                 tbl_walk_rd_en         ;
  reg   [`ENTRY_ADDR_WIDTH-1:0]       tbl_walk_idx           ;
  reg                                 tbl_walk_rd_valid      ;

  reg   [`NUMBER_ENTRIES-1:0]         waiting_tbl_pending      ;
  reg   [`ENTRY_ADDR_WIDTH-1:0]       chosen_entry             ;
  reg   [`ENTRY_ADDR_WIDTH-1:0]       chosen_entry_by_allocator;
  reg                                 chosen_entry_is_valid    ;
  reg                                 wait_tbl_busy            ;
  reg   [`ENTRY_ADDR_WIDTH-1:0]       last_chosen_entry_rr     ;

  wire  [`ENTRY_ADDR_WIDTH-1:0]       new_index_comb            ;
  wire  [`ENTRY_ADDR_WIDTH-1:0]       chosen_entry_comb         ;
  wire                                chosen_entry_is_valid_comb;
  wire  [`NUMBER_ENTRIES-1:0]         idx_found_entry_oh        ;
  wire  [`ENTRY_ADDR_WIDTH-1:0]       idx_found_entry           ;
  //wire                                found_entry_valid         ;
  wire  [`ENTRY_ADDR_WIDTH-1:0]       idx_found_entry_c         ;
  wire  [`ENTRY_ADDR_WIDTH-1:0]       idx_found_entry_c_bin     ;
  wire  [`NUMBER_ENTRIES-1:0]         idx_found_entry_c_oh      ;
  wire                                found_entry_valid_c       ;
  wire  [`ENTRY_ADDR_WIDTH:0]         left_degree               ;
  wire  [`ENTRY_ADDR_WIDTH-1:0]       right_degree              ;

  //when inflight_wg_buffer is full,pull down the ready
  assign host_wg_ready_o = !(&waiting_tbl_valid);

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      host_wg_valid_reg                   <= 'd0;  
      host_wg_id_reg                      <= 'd0;
      host_num_wf_reg                     <= 'd0;
      host_wf_size_reg                    <= 'd0;
      host_start_pc_reg                   <= 'd0;
      host_kernel_size_3d_reg             <= 'd0;
      host_pds_baseaddr_reg               <= 'd0;
      host_csr_knl_reg                    <= 'd0;
      host_gds_baseaddr_reg               <= 'd0;
      host_vgpr_size_total_reg            <= 'd0;
      host_sgpr_size_total_reg            <= 'd0;
      host_lds_size_total_reg             <= 'd0;
      host_gds_size_total_reg             <= 'd0;
      host_vgpr_size_per_wf_reg           <= 'd0;
      host_sgpr_size_per_wf_reg           <= 'd0;
      dis_controller_start_alloc_reg      <= 'd0;
      dis_controller_wg_dealloc_valid_reg <= 'd0;
      gpu_interface_dealloc_wg_id_reg     <= 'd0;
      tbl_walk_rd_valid                   <= 'd0;
    end
    else begin
      host_wg_valid_reg                   <= host_wg_valid_i                  ; 
      host_wg_id_reg                      <= host_wg_id_i                     ;
      host_num_wf_reg                     <= host_num_wf_i                    ;
      host_wf_size_reg                    <= host_wf_size_i                   ;
      host_start_pc_reg                   <= host_start_pc_i                  ;
      host_kernel_size_3d_reg             <= host_kernel_size_3d_i            ;
      host_pds_baseaddr_reg               <= host_pds_baseaddr_i              ;
      host_csr_knl_reg                    <= host_csr_knl_i                   ;
      host_gds_baseaddr_reg               <= host_gds_baseaddr_i              ;
      host_vgpr_size_total_reg            <= host_vgpr_size_total_i           ;
      host_sgpr_size_total_reg            <= host_sgpr_size_total_i           ;
      host_lds_size_total_reg             <= host_lds_size_total_i            ;
      host_gds_size_total_reg             <= host_gds_size_total_i            ;
      host_vgpr_size_per_wf_reg           <= host_vgpr_size_per_wf_i          ;
      host_sgpr_size_per_wf_reg           <= host_sgpr_size_per_wf_i          ;
      dis_controller_start_alloc_reg      <= dis_controller_start_alloc_i     ;
      dis_controller_wg_dealloc_valid_reg <= dis_controller_wg_dealloc_valid_i;
      gpu_interface_dealloc_wg_id_reg     <= gpu_interface_dealloc_wg_id_i    ;
      tbl_walk_rd_valid                   <= tbl_walk_rd_en                   ;
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      dis_controller_wg_alloc_valid_reg    <= 'd0;
      dis_controller_wg_rejected_valid_reg <= 'd0;
      allocator_wg_id_out_reg              <= 'd0;
    end
    else if(dis_controller_wg_alloc_valid_i) begin
      dis_controller_wg_alloc_valid_reg    <= 1'b1;
      allocator_wg_id_out_reg              <= allocator_wg_id_out_i;
    end
    else if(dis_controller_wg_rejected_valid_i) begin
      dis_controller_wg_rejected_valid_reg <= 1'b1;
      allocator_wg_id_out_reg              <= allocator_wg_id_out_i;
    end
    else if(inflight_tbl_alloc_st == ST_ALLOC_WAIT_RESULT) begin
      if(dis_controller_wg_alloc_valid_reg) begin
        dis_controller_wg_alloc_valid_reg <= 1'b0;
      end
      else if(dis_controller_wg_rejected_valid_reg) begin
        dis_controller_wg_rejected_valid_reg <= 1'b0;
      end
      else begin
        dis_controller_wg_alloc_valid_reg    <= dis_controller_wg_alloc_valid_reg   ; 
        dis_controller_wg_rejected_valid_reg <= dis_controller_wg_rejected_valid_reg;
      end
    end
    else begin
      dis_controller_wg_alloc_valid_reg    <= dis_controller_wg_alloc_valid_reg   ;
      dis_controller_wg_rejected_valid_reg <= dis_controller_wg_rejected_valid_reg;
      allocator_wg_id_out_reg              <= allocator_wg_id_out_reg             ;
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      inflight_wg_buffer_host_wf_done_reg       <= 'd0;
      inflight_wg_buffer_host_wf_done_wg_id_reg <= 'd0;
    end
    else if(dis_controller_wg_dealloc_valid_reg) begin
      inflight_wg_buffer_host_wf_done_reg       <= 1'b1;
      inflight_wg_buffer_host_wf_done_wg_id_reg <= gpu_interface_dealloc_wg_id_reg;//have changed
    end
    else begin
      inflight_wg_buffer_host_wf_done_reg       <= 1'b0                                     ;
      inflight_wg_buffer_host_wf_done_wg_id_reg <= inflight_wg_buffer_host_wf_done_wg_id_reg;
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      last_chosen_entry_rr <= {`ENTRY_ADDR_WIDTH{1'b1}};
    end
    else if(dis_controller_start_alloc_reg) begin
      last_chosen_entry_rr <= chosen_entry_by_allocator;
    end
    else begin
      last_chosen_entry_rr <= last_chosen_entry_rr;
    end
  end

  assign inflight_wg_buffer_host_rcvd_ack_o      = inflight_wg_buffer_host_rcvd_ack_reg      ;
  assign inflight_wg_buffer_host_wf_done_o       = inflight_wg_buffer_host_wf_done_reg       ;
  assign inflight_wg_buffer_host_wf_done_wg_id_o = inflight_wg_buffer_host_wf_done_wg_id_reg ;

  assign inflight_wg_buffer_gpu_valid_o            = inflight_wg_buffer_gpu_valid_reg           ;  
  assign inflight_wg_buffer_gpu_vgpr_size_per_wf_o = inflight_wg_buffer_gpu_vgpr_size_per_wf_reg;
  assign inflight_wg_buffer_gpu_sgpr_size_per_wf_o = inflight_wg_buffer_gpu_sgpr_size_per_wf_reg;
  assign inflight_wg_buffer_gpu_wf_size_o          = inflight_wg_buffer_gpu_wf_size_reg         ;
  assign inflight_wg_buffer_start_pc_o             = inflight_wg_buffer_start_pc_reg            ;
  assign inflight_wg_buffer_kernel_size_3d_o       = inflight_wg_buffer_kernel_size_3d_reg      ;
  assign inflight_wg_buffer_pds_baseaddr_o         = inflight_wg_buffer_pds_baseaddr_reg        ;
  assign inflight_wg_buffer_csr_knl_o              = inflight_wg_buffer_csr_knl_reg             ;
  assign inflight_wg_buffer_gds_baseaddr_o         = inflight_wg_buffer_gds_baseaddr_reg        ;

  assign inflight_wg_buffer_alloc_valid_o     = wg_waiting_alloc_valid                ;  
  assign inflight_wg_buffer_alloc_wg_id_o     = inflight_wg_buffer_alloc_wg_id_reg    ;
  assign inflight_wg_buffer_alloc_num_wf_o    = inflight_wg_buffer_alloc_num_wf_reg   ;
  assign inflight_wg_buffer_alloc_vgpr_size_o = inflight_wg_buffer_alloc_vgpr_size_reg;
  assign inflight_wg_buffer_alloc_sgpr_size_o = inflight_wg_buffer_alloc_sgpr_size_reg;
  assign inflight_wg_buffer_alloc_lds_size_o  = inflight_wg_buffer_alloc_lds_size_reg ;
  assign inflight_wg_buffer_alloc_gds_size_o  = inflight_wg_buffer_alloc_gds_size_reg ;

  assign inflight_wg_buffer_alloc_available_o = !wait_tbl_busy                            ;
  assign valid_not_pending                    = waiting_tbl_valid & (~waiting_tbl_pending);

  //例化ram
  ram #(
    .WORD_SIZE(WAIT_ENTRY_WIDTH ),
    .ADDR_SIZE(`ENTRY_ADDR_WIDTH),
    .NUM_WORDS(`NUMBER_ENTRIES  )
    )
  U_ram_wg_waiting_allocation (
    .clk      (clk              ),
    .rst_n    (rst_n            ),
    .rd_addr_i(tbl_walk_idx     ),
    .wr_addr_i(new_index        ),
    .wr_word_i(new_entry_wg_reg ),
    .rd_word_o(table_walk_rd_reg),
    .wr_en_i  (new_index_wr_en  ),
    .rd_en_i  (tbl_walk_rd_en   )
    );

  ram #(
    .WORD_SIZE(READY_ENTRY_WIDTH ),
    .ADDR_SIZE(`ENTRY_ADDR_WIDTH ),
    .NUM_WORDS(`NUMBER_ENTRIES   )
    )
  U_ram_wg_ready_start (
    .clk      (clk             ),
    .rst_n    (rst_n           ),
    .rd_addr_i(tbl_walk_idx    ),
    .wr_addr_i(new_index       ),
    .wr_word_i(ready_tbl_wr_reg),
    .rd_word_o(ready_tbl_rd_reg),
    .wr_en_i  (new_index_wr_en ),
    .rd_en_i  (tbl_walk_rd_en  )
    );

  //state machine of host 
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      inflight_tbl_rd_host_st              <= ST_RD_HOST_IDLE;
      new_index_wr_en                      <= 1'b0           ;
      new_entry_wg_reg                     <= 'd0            ;
      ready_tbl_wr_reg                     <= 'd0            ;
      inflight_wg_buffer_host_rcvd_ack_reg <= 1'b0           ;
    end
    else begin
      case(inflight_tbl_rd_host_st) 
        ST_RD_HOST_IDLE : begin
          new_index_wr_en                      <= 1'b0;
          inflight_wg_buffer_host_rcvd_ack_reg <= 1'b0;
          if(host_wg_valid_reg) begin
            if(!(&waiting_tbl_valid)) begin
              inflight_tbl_rd_host_st <= ST_RD_HOST_GET_FROM_HOST;
            end
            else begin
              inflight_tbl_rd_host_st <= inflight_tbl_rd_host_st;
            end
          end
          else begin
            inflight_tbl_rd_host_st <= inflight_tbl_rd_host_st;
          end
        end

        ST_RD_HOST_GET_FROM_HOST : begin
          new_index_wr_en                      <= 1'b1                                                                                                                                                                                        ;
          new_entry_wg_reg                     <= {host_num_wf_reg,host_lds_size_total_reg,host_gds_size_total_reg,host_wg_id_reg,host_vgpr_size_total_reg,host_sgpr_size_total_reg}                                                          ;
          ready_tbl_wr_reg                     <= {host_csr_knl_reg,host_pds_baseaddr_reg,host_kernel_size_3d_reg,host_start_pc_reg,host_gds_baseaddr_reg,host_wf_size_reg,host_wg_id_reg,host_vgpr_size_per_wf_reg,host_sgpr_size_per_wf_reg};
          inflight_tbl_rd_host_st              <= ST_RD_HOST_ACK_TO_HOST                                                                                                                                                                      ;
          inflight_wg_buffer_host_rcvd_ack_reg <= 1'b1                                                                                                                                                                                        ;
        end

        ST_RD_HOST_ACK_TO_HOST : begin
          new_index_wr_en                      <= 1'b0                  ;
          inflight_wg_buffer_host_rcvd_ack_reg <= 1'b0                  ;
          inflight_tbl_rd_host_st              <= ST_RD_HOST_IDLE_BUBBLE;
        end

        ST_RD_HOST_IDLE_BUBBLE : begin
          new_index_wr_en                      <= 1'b0           ;
          inflight_wg_buffer_host_rcvd_ack_reg <= 1'b0           ;
          inflight_tbl_rd_host_st              <= ST_RD_HOST_IDLE;
        end

        default : begin
          inflight_tbl_rd_host_st              <= ST_RD_HOST_IDLE;
          new_index_wr_en                      <= 1'b0           ;
          new_entry_wg_reg                     <= 'd0            ;
          ready_tbl_wr_reg                     <= 'd0            ;
          inflight_wg_buffer_host_rcvd_ack_reg <= 1'b0           ;
        end
      endcase
    end
  end

  //state machine of allocator interface
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      inflight_tbl_alloc_st                       <= ST_ALLOC_IDLE;
      waiting_tbl_pending                         <= 'd0          ;
      wg_waiting_alloc_valid                      <= 1'b0         ;
      wait_tbl_busy                               <= 1'b0         ;
      tbl_walk_wg_id_searched                     <= 'd0          ; 
      tbl_walk_rd_en                              <= 1'b0         ;
      tbl_walk_idx                                <= 'd0          ;
      inflight_wg_buffer_gpu_valid_reg            <= 'd0          ; 
      inflight_wg_buffer_gpu_vgpr_size_per_wf_reg <= 'd0          ;
      inflight_wg_buffer_gpu_sgpr_size_per_wf_reg <= 'd0          ;
      inflight_wg_buffer_gpu_wf_size_reg          <= 'd0          ;
      inflight_wg_buffer_start_pc_reg             <= 'd0          ;
      inflight_wg_buffer_kernel_size_3d_reg       <= 'd0          ;
      inflight_wg_buffer_pds_baseaddr_reg         <= 'd0          ;
      inflight_wg_buffer_csr_knl_reg              <= 'd0          ;
      inflight_wg_buffer_gds_baseaddr_reg         <= 'd0          ;
      chosen_entry_by_allocator                   <= 'd0          ;
      inflight_wg_buffer_alloc_wg_id_reg          <= 'd0          ;     
      inflight_wg_buffer_alloc_num_wf_reg         <= 'd0          ;
      inflight_wg_buffer_alloc_vgpr_size_reg      <= 'd0          ;
      inflight_wg_buffer_alloc_sgpr_size_reg      <= 'd0          ;
      inflight_wg_buffer_alloc_lds_size_reg       <= 'd0          ;
      inflight_wg_buffer_alloc_gds_size_reg       <= 'd0          ;
    end
    else begin
      case(inflight_tbl_alloc_st)
        ST_ALLOC_IDLE : begin//prepare to allocate a wg
          if(dis_controller_start_alloc_reg) begin
            waiting_tbl_pending[chosen_entry_by_allocator] <= 1'b1                ;
            wg_waiting_alloc_valid                         <= 1'b0                ;
            inflight_tbl_alloc_st                          <= ST_ALLOC_WAIT_RESULT;
            inflight_wg_buffer_gpu_valid_reg               <= 1'b0                ;
            wait_tbl_busy                                  <= 1'b1                ;
            tbl_walk_rd_en                                 <= 1'b0                ;
          end
          else if(!wg_waiting_alloc_valid && (|valid_not_pending)) begin
            inflight_tbl_alloc_st <= ST_ALLOC_GET_ALLOC_WG;
            inflight_wg_buffer_gpu_valid_reg <= 1'b0;
            wait_tbl_busy                    <= 1'b1;
            tbl_walk_rd_en                   <= 1'b0;
          end
          else begin
            wait_tbl_busy <= 1'b0;
            inflight_wg_buffer_gpu_valid_reg <= 1'b0;
            tbl_walk_rd_en                   <= 1'b0;
          end
        end
        
        ST_ALLOC_WAIT_RESULT : begin//wait for the result of allocation
          if(dis_controller_wg_alloc_valid_reg) begin
            inflight_wg_buffer_gpu_valid_reg  <= 1'b0                   ;
            wait_tbl_busy                     <= 1'b0                   ;
            tbl_walk_wg_id_searched           <= allocator_wg_id_out_reg;
            tbl_walk_rd_en                    <= 1'b1                   ;
            tbl_walk_idx                      <= 'd0                    ;
            inflight_tbl_alloc_st             <= ST_ALLOC_FIND_ACCEPTED ;
          end
          else if(dis_controller_wg_rejected_valid_reg) begin
            inflight_wg_buffer_gpu_valid_reg     <= 1'b0                   ;
            wait_tbl_busy                        <= 1'b0                   ;
            tbl_walk_wg_id_searched              <= allocator_wg_id_out_reg;
            tbl_walk_rd_en                       <= 1'b1                   ;
            tbl_walk_idx                         <= 'd0                    ;
            inflight_tbl_alloc_st                <= ST_ALLOC_FIND_REJECTED ;
          end
          else begin
            inflight_wg_buffer_gpu_valid_reg     <= 1'b0                                ;
            wait_tbl_busy                        <= 1'b0                                ;
            tbl_walk_wg_id_searched              <= tbl_walk_wg_id_searched             ;
            tbl_walk_rd_en                       <= 1'b0                                ;
            tbl_walk_idx                         <= tbl_walk_idx                        ;
            inflight_tbl_alloc_st                <= inflight_tbl_alloc_st               ;
          end
        end

        ST_ALLOC_FIND_ACCEPTED : begin//find the accepted wg
          if(tbl_walk_rd_valid) begin
            if((table_walk_rd_reg[WG_ID_H:WG_ID_L] == tbl_walk_wg_id_searched) && waiting_tbl_pending[tbl_walk_idx]) begin
              inflight_tbl_alloc_st            <= ST_ALLOC_CLEAR_ACCEPTED;
              inflight_wg_buffer_gpu_valid_reg <= 1'b0                   ;
              wait_tbl_busy                    <= 1'b1                   ;
              tbl_walk_rd_en                   <= 1'b0                   ;
            end
            else begin
              inflight_wg_buffer_gpu_valid_reg <= 1'b0                   ;
              wait_tbl_busy                    <= 1'b1                   ;
              tbl_walk_idx                     <= tbl_walk_idx + 1       ;
              tbl_walk_rd_en                   <= 1'b1                   ;
            end
          end
          else begin
            inflight_tbl_alloc_st            <= inflight_tbl_alloc_st  ;
            tbl_walk_idx                     <= tbl_walk_idx           ;
            tbl_walk_rd_en                   <= 1'b0                   ;
            inflight_wg_buffer_gpu_valid_reg <= 1'b0                   ;
            wait_tbl_busy                    <= 1'b1                   ;
          end
        end

        ST_ALLOC_CLEAR_ACCEPTED : begin//clear the accepted wg
          wait_tbl_busy                               <= 1'b1                                           ;
          tbl_walk_rd_en                              <= 1'b0                                           ;
          waiting_tbl_pending[tbl_walk_idx]           <= 1'b0                                           ;
          inflight_wg_buffer_gpu_valid_reg            <= 1'b1                                           ;
          inflight_wg_buffer_gpu_vgpr_size_per_wf_reg <= ready_tbl_rd_reg[VGPR_SIZE_H:VGPR_SIZE_L]      ;
          inflight_wg_buffer_gpu_sgpr_size_per_wf_reg <= ready_tbl_rd_reg[SGPR_SIZE_H:SGPR_SIZE_L]      ;
          inflight_wg_buffer_gpu_wf_size_reg          <= ready_tbl_rd_reg[WF_SIZE_H:WF_SIZE_L]          ;
          inflight_wg_buffer_start_pc_reg             <= ready_tbl_rd_reg[START_PC_H:START_PC_L]        ;
          inflight_wg_buffer_kernel_size_3d_reg       <= ready_tbl_rd_reg[KNL_SZ_3D_H:KNL_SZ_3D_L]      ;
          inflight_wg_buffer_pds_baseaddr_reg         <= ready_tbl_rd_reg[PDS_BASEADDR_H:PDS_BASEADDR_L];
          inflight_wg_buffer_csr_knl_reg              <= ready_tbl_rd_reg[CSR_KNL_H:CSR_KNL_L]          ;
          inflight_wg_buffer_gds_baseaddr_reg         <= ready_tbl_rd_reg[GDS_BASEADDR_H:GDS_BASEADDR_L];
          inflight_tbl_alloc_st                       <= ST_ALLOC_GET_ALLOC_WG                          ;
        end

        ST_ALLOC_FIND_REJECTED : begin//find the rejected wg
          if(tbl_walk_rd_valid) begin
            if((table_walk_rd_reg[WG_ID_H:WG_ID_L] == tbl_walk_wg_id_searched) && waiting_tbl_pending[tbl_walk_idx]) begin
              inflight_tbl_alloc_st            <= ST_ALLOC_CLEAR_REJECTED;
              inflight_wg_buffer_gpu_valid_reg <= 1'b0                   ;
              wait_tbl_busy                    <= 1'b1                   ;
              tbl_walk_rd_en                   <= 1'b0                   ;
            end
            else begin
              tbl_walk_idx                     <= tbl_walk_idx + 1;
              tbl_walk_rd_en                   <= 1'b1            ;
              inflight_wg_buffer_gpu_valid_reg <= 1'b0            ;
              wait_tbl_busy                    <= 1'b1            ;
            end
          end
          else begin
            inflight_tbl_alloc_st            <= inflight_tbl_alloc_st;
            tbl_walk_idx                     <= tbl_walk_idx         ;
            tbl_walk_rd_en                   <= 1'b0                 ;
            inflight_wg_buffer_gpu_valid_reg <= 1'b0                 ;
            wait_tbl_busy                    <= 1'b1                 ;
          end
        end

        ST_ALLOC_CLEAR_REJECTED : begin//clear the rejected wg
          inflight_wg_buffer_gpu_valid_reg  <= 1'b0                 ;
          wait_tbl_busy                     <= 1'b1                 ;
          tbl_walk_rd_en                    <= 1'b0                 ;
          waiting_tbl_pending[tbl_walk_idx] <= 1'b0                 ;
          inflight_tbl_alloc_st             <= ST_ALLOC_GET_ALLOC_WG;
        end

        ST_ALLOC_GET_ALLOC_WG : begin//get the way to be allocated
          if(chosen_entry_is_valid) begin
            tbl_walk_rd_en                   <= 1'b1                ;
            tbl_walk_idx                     <= chosen_entry        ;
            chosen_entry_by_allocator        <= chosen_entry        ;
            inflight_tbl_alloc_st            <= ST_ALLOC_UP_ALLOC_WG;
            inflight_wg_buffer_gpu_valid_reg <= 1'b0;
            wait_tbl_busy                    <= 1'b1;
          end
          else begin
            inflight_tbl_alloc_st            <= ST_ALLOC_IDLE;
            inflight_wg_buffer_gpu_valid_reg <= 1'b0         ;
            wait_tbl_busy                    <= 1'b1         ;
            tbl_walk_rd_en                   <= 1'b0         ;
          end
        end

        ST_ALLOC_UP_ALLOC_WG : begin//output to allocator
          if(tbl_walk_rd_valid) begin
            inflight_wg_buffer_gpu_valid_reg       <= 1'b0                                      ;
            wait_tbl_busy                          <= 1'b1                                      ;
            tbl_walk_rd_en                         <= 1'b0                                      ;
            wg_waiting_alloc_valid                 <= 1'b1                                      ;
            inflight_wg_buffer_alloc_wg_id_reg     <= table_walk_rd_reg[WG_ID_H:WG_ID_L]        ;
            inflight_wg_buffer_alloc_num_wf_reg    <= table_walk_rd_reg[WG_COUNT_H:WG_COUNT_L]  ;
            inflight_wg_buffer_alloc_vgpr_size_reg <= table_walk_rd_reg[VGPR_SIZE_H:VGPR_SIZE_L];
            inflight_wg_buffer_alloc_sgpr_size_reg <= table_walk_rd_reg[SGPR_SIZE_H:SGPR_SIZE_L];
            inflight_wg_buffer_alloc_lds_size_reg  <= table_walk_rd_reg[LDS_SIZE_H:LDS_SIZE_L]  ;
            inflight_wg_buffer_alloc_gds_size_reg  <= table_walk_rd_reg[GDS_SIZE_H:GDS_SIZE_L]  ;
            inflight_tbl_alloc_st                  <= ST_ALLOC_IDLE                             ;
          end
          else begin
            inflight_wg_buffer_gpu_valid_reg       <= 1'b0                                  ;
            wait_tbl_busy                          <= 1'b1                                  ;
            tbl_walk_rd_en                         <= 1'b0                                  ;
            wg_waiting_alloc_valid                 <= wg_waiting_alloc_valid                ; 
            inflight_wg_buffer_alloc_wg_id_reg     <= inflight_wg_buffer_alloc_wg_id_reg    ; 
            inflight_wg_buffer_alloc_num_wf_reg    <= inflight_wg_buffer_alloc_num_wf_reg   ; 
            inflight_wg_buffer_alloc_vgpr_size_reg <= inflight_wg_buffer_alloc_vgpr_size_reg; 
            inflight_wg_buffer_alloc_sgpr_size_reg <= inflight_wg_buffer_alloc_sgpr_size_reg; 
            inflight_wg_buffer_alloc_lds_size_reg  <= inflight_wg_buffer_alloc_lds_size_reg ; 
            inflight_wg_buffer_alloc_gds_size_reg  <= inflight_wg_buffer_alloc_gds_size_reg ; 
            inflight_tbl_alloc_st                  <= inflight_tbl_alloc_st                 ;
          end
        end

        default : begin
          inflight_tbl_alloc_st                       <= ST_ALLOC_IDLE;
          waiting_tbl_pending                         <= 'd0          ;
          wg_waiting_alloc_valid                      <= 1'b0         ;
          wait_tbl_busy                               <= 1'b1         ;
          tbl_walk_wg_id_searched                     <= 'd0          ;
          tbl_walk_rd_en                              <= 1'b0         ;
          tbl_walk_idx                                <= 'd0          ;
          inflight_wg_buffer_gpu_valid_reg            <= 'd0          ;
          inflight_wg_buffer_gpu_vgpr_size_per_wf_reg <= 'd0          ;
          inflight_wg_buffer_gpu_sgpr_size_per_wf_reg <= 'd0          ;
          inflight_wg_buffer_gpu_wf_size_reg          <= 'd0          ;
          inflight_wg_buffer_start_pc_reg             <= 'd0          ;
          inflight_wg_buffer_kernel_size_3d_reg       <= 'd0          ;
          inflight_wg_buffer_pds_baseaddr_reg         <= 'd0          ;
          inflight_wg_buffer_csr_knl_reg              <= 'd0          ;
          inflight_wg_buffer_gds_baseaddr_reg         <= 'd0          ;
          chosen_entry_by_allocator                   <= 'd0          ;
          inflight_wg_buffer_alloc_wg_id_reg          <= 'd0          ;
          inflight_wg_buffer_alloc_num_wf_reg         <= 'd0          ;
          inflight_wg_buffer_alloc_vgpr_size_reg      <= 'd0          ;
          inflight_wg_buffer_alloc_sgpr_size_reg      <= 'd0          ;
          inflight_wg_buffer_alloc_lds_size_reg       <= 'd0          ;
          inflight_wg_buffer_alloc_gds_size_reg       <= 'd0          ;
        end
      endcase
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      waiting_tbl_valid <= 'd0;
    end
    else if(inflight_tbl_rd_host_st == ST_RD_HOST_ACK_TO_HOST) begin
      waiting_tbl_valid[new_index] <= 1'b1;
    end
    else if(inflight_tbl_alloc_st == ST_ALLOC_CLEAR_ACCEPTED) begin
      waiting_tbl_valid[tbl_walk_idx] <= 1'b0;
    end
    else begin
      waiting_tbl_valid <= waiting_tbl_valid;
    end
  end

  //选择ram存储空间来缓存host发送的wg任务
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      new_index             <= 'd0;
      chosen_entry          <= 'd0;
      chosen_entry_is_valid <= 'd0;
    end
    else begin
      new_index             <= new_index_comb            ;
      chosen_entry          <= chosen_entry_comb         ;
      chosen_entry_is_valid <= chosen_entry_is_valid_comb;
    end
  end

  /*genvar i;
  generate for(i=`NUMBER_ENTRIES-1;i>=0;i=i-1) begin : B1
    assign found_entry_valid   = (!waiting_tbl_valid[i]) ? 1'b1 : 1'b0                      ;
    assign idx_found_entry     = (!waiting_tbl_valid[i]) ? i    : 'd0                       ;
    assign found_entry_valid_c = waiting_tbl_valid[i] ? 1'b1 : 1'b0                         ;
    assign idx_found_entry_c   = waiting_tbl_valid[i] ? (i + last_chosen_entry_rr + 1) : 'd0;
  end
  endgenerate*/

  //以最低位为最高优先级寻找空闲空间来存储host发送的wg
  fixed_pri_arb #(
    .ARB_WIDTH(`NUMBER_ENTRIES))
  U_fixed_pri_arb (
    .req  (~waiting_tbl_valid),
    .grant(idx_found_entry_oh)
    );

  one2bin #(
    .ONE_WIDTH(`NUMBER_ENTRIES  ),
    .BIN_WIDTH(`ENTRY_ADDR_WIDTH))
  U_one2bin (
    .oh (idx_found_entry_oh),
    .bin(idx_found_entry   )
    );
  
  //assign found_entry_valid          = &waiting_tbl_valid ;

  assign new_index_comb             = idx_found_entry    ;
  assign chosen_entry_is_valid_comb = found_entry_valid_c;
  assign chosen_entry_comb          = idx_found_entry_c  ;

  assign left_degree                = `NUMBER_ENTRIES - (1 + last_chosen_entry_rr);
  assign right_degree               = 1 + last_chosen_entry_rr                    ;

  //选择ram中新地址的wg发送给allocator_neo模块进行能否执行的判断(RR)
  genvar j;
  generate for(j=0;j<`NUMBER_ENTRIES;j=j+1) begin :B2
    assign waiting_tbl_valid_rotated[j] = (j >= left_degree) ? valid_not_pending[j - left_degree] : valid_not_pending[j + right_degree];
  end
  endgenerate

  //以最低位为最高优先级寻找寻找下一个发送给allocator_neo模块的wg
  fixed_pri_arb #(
    .ARB_WIDTH(`NUMBER_ENTRIES))
  U_fixed_pri_arb_1 (
    .req  (waiting_tbl_valid_rotated),
    .grant(idx_found_entry_c_oh     )
    );

  one2bin #(
    .ONE_WIDTH(`NUMBER_ENTRIES  ),
    .BIN_WIDTH(`ENTRY_ADDR_WIDTH))
  U_one2bin_1 (
    .oh (idx_found_entry_c_oh ),
    .bin(idx_found_entry_c_bin)
    );

  assign idx_found_entry_c          = idx_found_entry_c_bin + last_chosen_entry_rr + 1;
  assign found_entry_valid_c        = |waiting_tbl_valid_rotated; 

endmodule



