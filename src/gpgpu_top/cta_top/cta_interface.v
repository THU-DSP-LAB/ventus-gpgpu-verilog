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
// Description:

`timescale 1ns/1ns

`include "define.v"

module cta_interface (
  input                                          clk                                             ,
  input                                          rst_n                                           ,
  //host2cta
  input                                          host2cta_valid_i                                ,
  output                                         host2cta_ready_o                                ,
  input  [`WG_ID_WIDTH-1:0]                      host2cta_host_wg_id_i                           ,
  input  [`WF_COUNT_WIDTH_PER_WG-1:0]            host2cta_host_num_wf_i                          ,
  input  [`WAVE_ITEM_WIDTH-1:0]                  host2cta_host_wf_size_i                         ,
  input  [`MEM_ADDR_WIDTH-1:0]                   host2cta_host_start_pc_i                        ,
  input  [`WG_SIZE_X_WIDTH*3-1:0]                host2cta_host_kernel_size_3d_i                  ,
  input  [`MEM_ADDR_WIDTH-1:0]                   host2cta_host_pds_baseaddr_i                    ,
  input  [`MEM_ADDR_WIDTH-1:0]                   host2cta_host_csr_knl_i                         ,
  input  [`MEM_ADDR_WIDTH-1:0]                   host2cta_host_gds_baseaddr_i                    ,
  input  [`VGPR_ID_WIDTH:0]                      host2cta_host_vgpr_size_total_i                 ,
  input  [`SGPR_ID_WIDTH:0]                      host2cta_host_sgpr_size_total_i                 ,
  input  [`LDS_ID_WIDTH:0]                       host2cta_host_lds_size_total_i                  ,
  input  [`GDS_ID_WIDTH:0]                       host2cta_host_gds_size_total_i                  ,
  input  [`VGPR_ID_WIDTH:0]                      host2cta_host_vgpr_size_per_wf_i                ,
  input  [`SGPR_ID_WIDTH:0]                      host2cta_host_sgpr_size_per_wf_i                ,
  //cta2host
  output                                         cta2host_rcvd_ack_o                             ,
  output                                         cta2host_valid_o                                ,
  input                                          cta2host_ready_i                                ,
  output [`WG_ID_WIDTH-1:0]                      cta2host_inflight_wg_buffer_host_wf_done_wg_id_o,
  //cta2warp
  output [`NUMBER_CU-1:0]                        cta2warp_valid_o                                ,
  input  [`NUMBER_CU-1:0]                        cta2warp_ready_i                                ,
  output [`NUMBER_CU*`WF_COUNT_WIDTH_PER_WG-1:0] cta2warp_dispatch2cu_wg_wf_count_o              ,
  output [`NUMBER_CU*`WAVE_ITEM_WIDTH-1:0]       cta2warp_dispatch2cu_wf_size_dispatch_o         ,
  output [`NUMBER_CU*(`SGPR_ID_WIDTH+1)-1:0]     cta2warp_dispatch2cu_sgpr_base_dispatch_o       ,
  output [`NUMBER_CU*(`VGPR_ID_WIDTH+1)-1:0]     cta2warp_dispatch2cu_vgpr_base_dispatch_o       ,
  output [`NUMBER_CU*`TAG_WIDTH-1:0]             cta2warp_dispatch2cu_wf_tag_dispatch_o          ,
  output [`NUMBER_CU*(`LDS_ID_WIDTH+1)-1:0]      cta2warp_dispatch2cu_lds_base_dispatch_o        ,
  output [`NUMBER_CU*`MEM_ADDR_WIDTH-1:0]        cta2warp_dispatch2cu_start_pc_dispatch_o        ,
  output [`NUMBER_CU*`MEM_ADDR_WIDTH-1:0]        cta2warp_dispatch2cu_pds_baseaddr_dispatch_o    ,
  output [`NUMBER_CU*`MEM_ADDR_WIDTH-1:0]        cta2warp_dispatch2cu_gds_baseaddr_dispatch_o    ,
  output [`NUMBER_CU*`MEM_ADDR_WIDTH-1:0]        cta2warp_dispatch2cu_csr_knl_dispatch_o         ,
  output [`NUMBER_CU*`WG_SIZE_X_WIDTH-1:0]       cta2warp_dispatch2cu_wgid_x_dispatch_o          ,
  output [`NUMBER_CU*`WG_SIZE_Y_WIDTH-1:0]       cta2warp_dispatch2cu_wgid_y_dispatch_o          ,
  output [`NUMBER_CU*`WG_SIZE_Z_WIDTH-1:0]       cta2warp_dispatch2cu_wgid_z_dispatch_o          ,
  output [`NUMBER_CU*32-1:0]                     cta2warp_dispatch2cu_wg_id_o                    ,
  //warp2cta
  input  [`NUMBER_CU-1:0]                        warp2cta_valid_i                                ,
  output [`NUMBER_CU-1:0]                        warp2cta_ready_o                                ,
  input  [`NUMBER_CU*`TAG_WIDTH-1:0]             warp2cta_cu2dispatch_wf_tag_done_i              
);

  //cta_scheduler inputs(from SM)
  wire [`NUMBER_CU-1:0]             cta_sche_cu2dispatch_wf_done                  ;
  wire [`TAG_WIDTH*`NUMBER_CU-1:0]  cta_sche_cu2dispatch_wf_tag_done              ;
  wire [`NUMBER_CU-1:0]             cta_sche_cu2dispatch_ready_for_dispatch       ;

  //cta_scheduler outputs(to host and SM)
  wire                              cta_sche_inflight_wg_buffer_host_rcvd_ack     ;
  wire                              cta_sche_inflight_wg_buffer_host_wf_done      ;
  wire [`WG_ID_WIDTH-1:0]           cta_sche_inflight_wg_buffer_host_wf_done_wg_id;
  wire [`NUMBER_CU-1:0]             cta_sche_dispatch2cu_wf_dispatch              ;
  wire [`WF_COUNT_WIDTH_PER_WG-1:0] cta_sche_dispatch2cu_wg_wf_count              ;
  wire [`WAVE_ITEM_WIDTH-1:0]       cta_sche_dispatch2cu_wf_size_dispatch         ;
  wire [`SGPR_ID_WIDTH:0]           cta_sche_dispatch2cu_sgpr_base_dispatch       ;
  wire [`VGPR_ID_WIDTH:0]           cta_sche_dispatch2cu_vgpr_base_dispatch       ;
  wire [`TAG_WIDTH-1:0]             cta_sche_dispatch2cu_wf_tag_dispatch          ;
  wire [`LDS_ID_WIDTH:0]            cta_sche_dispatch2cu_lds_base_dispatch        ;
  wire [`MEM_ADDR_WIDTH-1:0]        cta_sche_dispatch2cu_start_pc_dispatch        ;
  wire [`WG_SIZE_X_WIDTH*3-1:0]     cta_sche_dispatch2cu_kernel_size_3d_dispatch  ;
  wire [`MEM_ADDR_WIDTH-1:0]        cta_sche_dispatch2cu_pds_baseaddr_dispatch    ;
  wire [`MEM_ADDR_WIDTH-1:0]        cta_sche_dispatch2cu_csr_knl_dispatch         ;
  wire [`MEM_ADDR_WIDTH-1:0]        cta_sche_dispatch2cu_gds_base_dispatch        ;

  cta_scheduler cta_sche (
    .clk                                     (clk                                           ),
    .rst_n                                   (rst_n                                         ),
    .host_wg_valid_i                         (host2cta_valid_i                              ),
    .host_wg_ready_o                         (host2cta_ready_o                              ),
    .host_wg_id_i                            (host2cta_host_wg_id_i                         ),
    .host_num_wf_i                           (host2cta_host_num_wf_i                        ),
    .host_wf_size_i                          (host2cta_host_wf_size_i                       ),
    .host_start_pc_i                         (host2cta_host_start_pc_i                      ),
    .host_kernel_size_3d_i                   (host2cta_host_kernel_size_3d_i                ),
    .host_pds_baseaddr_i                     (host2cta_host_pds_baseaddr_i                  ),
    .host_csr_knl_i                          (host2cta_host_csr_knl_i                       ),
    .host_gds_baseaddr_i                     (host2cta_host_gds_baseaddr_i                  ),
    .host_vgpr_size_total_i                  (host2cta_host_vgpr_size_total_i               ),
    .host_sgpr_size_total_i                  (host2cta_host_sgpr_size_total_i               ),
    .host_lds_size_total_i                   (host2cta_host_lds_size_total_i                ),
    .host_gds_size_total_i                   (host2cta_host_gds_size_total_i                ),
    .host_vgpr_size_per_wf_i                 (host2cta_host_vgpr_size_per_wf_i              ),
    .host_sgpr_size_per_wf_i                 (host2cta_host_sgpr_size_per_wf_i              ),
    .cu2dispatch_wf_done_i                   (cta_sche_cu2dispatch_wf_done                  ),
    .cu2dispatch_wf_tag_done_i               (cta_sche_cu2dispatch_wf_tag_done              ),
    .cu2dispatch_ready_for_dispatch_i        (cta_sche_cu2dispatch_ready_for_dispatch       ),
    .inflight_wg_buffer_host_rcvd_ack_o      (cta_sche_inflight_wg_buffer_host_rcvd_ack     ),
    .inflight_wg_buffer_host_wf_done_o       (cta_sche_inflight_wg_buffer_host_wf_done      ),
    .inflight_wg_buffer_host_wf_done_wg_id_o (cta_sche_inflight_wg_buffer_host_wf_done_wg_id),
    .dispatch2cu_wf_dispatch_o               (cta_sche_dispatch2cu_wf_dispatch              ),
    .dispatch2cu_wg_wf_count_o               (cta_sche_dispatch2cu_wg_wf_count              ),
    .dispatch2cu_wf_size_dispatch_o          (cta_sche_dispatch2cu_wf_size_dispatch         ),
    .dispatch2cu_sgpr_base_dispatch_o        (cta_sche_dispatch2cu_sgpr_base_dispatch       ),
    .dispatch2cu_vgpr_base_dispatch_o        (cta_sche_dispatch2cu_vgpr_base_dispatch       ),
    .dispatch2cu_wf_tag_dispatch_o           (cta_sche_dispatch2cu_wf_tag_dispatch          ),
    .dispatch2cu_lds_base_dispatch_o         (cta_sche_dispatch2cu_lds_base_dispatch        ),
    .dispatch2cu_start_pc_dispatch_o         (cta_sche_dispatch2cu_start_pc_dispatch        ),
    .dispatch2cu_kernel_size_3d_dispatch_o   (cta_sche_dispatch2cu_kernel_size_3d_dispatch  ),
    .dispatch2cu_pds_baseaddr_dispatch_o     (cta_sche_dispatch2cu_pds_baseaddr_dispatch    ),
    .dispatch2cu_csr_knl_dispatch_o          (cta_sche_dispatch2cu_csr_knl_dispatch         ),
    .dispatch2cu_gds_base_dispatch_o         (cta_sche_dispatch2cu_gds_base_dispatch        )
  );

  //assign host2cta_ready_o = cta_sche_inflight_wg_buffer_host_rcvd_ack;
  assign cta2host_rcvd_ack_o = cta_sche_inflight_wg_buffer_host_rcvd_ack;

  wf_done_interface_single wf_done_interface (
    .clk                  (clk                                             ),
    .rst_n                (rst_n                                           ),
    .wf_done_i            (cta_sche_inflight_wg_buffer_host_wf_done        ),
    .wf_done_wg_id_i      (cta_sche_inflight_wg_buffer_host_wf_done_wg_id  ),
    .host_wf_done_ready_i (cta2host_ready_i                                ),
    .host_wf_done_valid_o (cta2host_valid_o                                ),
    .host_wf_done_wg_id_o (cta2host_inflight_wg_buffer_host_wf_done_wg_id_o)
  );

  genvar i;
  generate
    for(i=0;i<`NUMBER_CU;i=i+1) begin: CTA2WARP_OUTPUT
      assign cta2warp_valid_o[i]                                                                        = cta_sche_dispatch2cu_wf_dispatch[i]       ;
      assign cta2warp_dispatch2cu_wg_wf_count_o[`WF_COUNT_WIDTH_PER_WG*(i+1)-1-:`WF_COUNT_WIDTH_PER_WG] = cta_sche_dispatch2cu_wg_wf_count          ;
      assign cta2warp_dispatch2cu_wf_size_dispatch_o[`WAVE_ITEM_WIDTH*(i+1)-1-:`WAVE_ITEM_WIDTH]        = cta_sche_dispatch2cu_wf_size_dispatch     ;
      assign cta2warp_dispatch2cu_sgpr_base_dispatch_o[(`SGPR_ID_WIDTH+1)*(i+1)-1-:(`SGPR_ID_WIDTH+1)]  = cta_sche_dispatch2cu_sgpr_base_dispatch   ;
      assign cta2warp_dispatch2cu_vgpr_base_dispatch_o[(`VGPR_ID_WIDTH+1)*(i+1)-1-:(`VGPR_ID_WIDTH+1)]  = cta_sche_dispatch2cu_vgpr_base_dispatch   ;
      assign cta2warp_dispatch2cu_wf_tag_dispatch_o[`TAG_WIDTH*(i+1)-1-:`TAG_WIDTH]                     = cta_sche_dispatch2cu_wf_tag_dispatch      ;
      assign cta2warp_dispatch2cu_lds_base_dispatch_o[(`LDS_ID_WIDTH+1)*(i+1)-1-:(`LDS_ID_WIDTH+1)]     = cta_sche_dispatch2cu_lds_base_dispatch    ;
      assign cta2warp_dispatch2cu_start_pc_dispatch_o[`MEM_ADDR_WIDTH*(i+1)-1-:`MEM_ADDR_WIDTH]         = cta_sche_dispatch2cu_start_pc_dispatch    ;
      assign cta2warp_dispatch2cu_pds_baseaddr_dispatch_o[`MEM_ADDR_WIDTH*(i+1)-1-:`MEM_ADDR_WIDTH]     = cta_sche_dispatch2cu_pds_baseaddr_dispatch;
      assign cta2warp_dispatch2cu_gds_baseaddr_dispatch_o[`MEM_ADDR_WIDTH*(i+1)-1-:`MEM_ADDR_WIDTH]     = cta_sche_dispatch2cu_gds_base_dispatch    ;
      assign cta2warp_dispatch2cu_csr_knl_dispatch_o[`MEM_ADDR_WIDTH*(i+1)-1-:`MEM_ADDR_WIDTH]          = cta_sche_dispatch2cu_csr_knl_dispatch     ;
      assign cta2warp_dispatch2cu_wgid_x_dispatch_o[`WG_SIZE_X_WIDTH*(i+1)-1-:`WG_SIZE_X_WIDTH]         = 
        cta_sche_dispatch2cu_kernel_size_3d_dispatch[`WG_SIZE_X_WIDTH-1:0]                                                 ;
      assign cta2warp_dispatch2cu_wgid_y_dispatch_o[`WG_SIZE_Y_WIDTH*(i+1)-1-:`WG_SIZE_Y_WIDTH]         = 
        cta_sche_dispatch2cu_kernel_size_3d_dispatch[`WG_SIZE_X_WIDTH+`WG_SIZE_Y_WIDTH-1-:`WG_SIZE_Y_WIDTH]                ;
      assign cta2warp_dispatch2cu_wgid_z_dispatch_o[`WG_SIZE_Z_WIDTH*(i+1)-1-:`WG_SIZE_Z_WIDTH]         = 
        cta_sche_dispatch2cu_kernel_size_3d_dispatch[`WG_SIZE_X_WIDTH+`WG_SIZE_Y_WIDTH+`WG_SIZE_Z_WIDTH-1:`WG_SIZE_Z_WIDTH];
      assign cta2warp_dispatch2cu_wg_id_o[32*(i+1)-1-:32]                                               = 'd0              ;
      assign warp2cta_ready_o[i] = 'd1;
    end
  endgenerate

  assign cta_sche_cu2dispatch_wf_done            = warp2cta_valid_i                  ;
  assign cta_sche_cu2dispatch_wf_tag_done        = warp2cta_cu2dispatch_wf_tag_done_i;
  assign cta_sche_cu2dispatch_ready_for_dispatch = cta2warp_ready_i                  ;

endmodule

