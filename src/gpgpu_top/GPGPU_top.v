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
//`include "IDecode_define.v"
//`include "L2cache_define.v"
//`include "l1dcache_define.v"
//`include "fpu_ops.v"
//`define NO_CACHE

module GPGPU_top (
  input                                               clk                                             ,
  input                                               rst_n                                           ,

  input                                               host_req_valid_i                                ,
  output                                              host_req_ready_o                                ,
  input   [`WG_ID_WIDTH-1:0]                          host_req_wg_id_i                                ,
  input   [`WF_COUNT_WIDTH-1:0]                       host_req_num_wf_i                               ,
  input   [`WAVE_ITEM_WIDTH-1:0]                      host_req_wf_size_i                              ,
  input   [`MEM_ADDR_WIDTH-1:0]                       host_req_start_pc_i                             ,
  input   [`WG_SIZE_X_WIDTH*3-1:0]                    host_req_kernel_size_3d_i                       ,
  input   [`MEM_ADDR_WIDTH-1:0]                       host_req_pds_baseaddr_i                         ,
  input   [`MEM_ADDR_WIDTH-1:0]                       host_req_csr_knl_i                              ,
  input   [`VGPR_ID_WIDTH:0]                          host_req_vgpr_size_total_i                      ,
  input   [`SGPR_ID_WIDTH:0]                          host_req_sgpr_size_total_i                      ,
  input   [`LDS_ID_WIDTH:0]                           host_req_lds_size_total_i                       ,
  input   [`GDS_ID_WIDTH:0]                           host_req_gds_size_total_i                       ,
  input   [`VGPR_ID_WIDTH:0]                          host_req_vgpr_size_per_wf_i                     ,
  input   [`SGPR_ID_WIDTH:0]                          host_req_sgpr_size_per_wf_i                     ,
  input   [`MEM_ADDR_WIDTH-1:0]                       host_req_gds_baseaddr_i                         ,

  output                                              host_rsp_valid_o                                ,
  input                                               host_rsp_ready_i                                ,
  output  [`WG_ID_WIDTH-1:0]                          host_rsp_inflight_wg_buffer_host_wf_done_wg_id_o,

`ifdef NO_CACHE
  input                                               icache_mem_rsp_valid_i                          ,
  output                                              icache_mem_rsp_ready_o                          ,
  input  [`XLEN-1:0]                                  icache_mem_rsp_addr_i                           ,
  input  [`DCACHE_BLOCKWORDS*`XLEN-1:0]               icache_mem_rsp_data_i                           ,
  input  [`D_SOURCE-1:0]                              icache_mem_rsp_source_i                         ,

  output                                              icache_mem_req_valid_o                          ,
  input                                               icache_mem_req_ready_i                          ,
  output [`XLEN-1:0]                                  icache_mem_req_addr_o                           ,
  output [`D_SOURCE-1:0]                              icache_mem_req_source_o                         ,

  input                                               dcache_mem_rsp_valid_i                          ,
  output                                              dcache_mem_rsp_ready_o                          ,
  input  [`WIDBITS-1:0]                               dcache_mem_rsp_instrid_i                        ,
  input  [`DCACHE_NLANES*`XLEN-1:0]                   dcache_mem_rsp_data_i                           ,
  input  [`DCACHE_NLANES-1:0]                         dcache_mem_rsp_activemask_i                     ,

  output                                              dcache_mem_req_valid_o                          ,
  input                                               dcache_mem_req_ready_i                          ,
  output [`WIDBITS-1:0]                               dcache_mem_req_instrid_o                        ,
  output [`DCACHE_SETIDXBITS-1:0]                     dcache_mem_req_setidx_o                         ,
  output [`DCACHE_TAGBITS-1:0]                        dcache_mem_req_tag_o                            ,
  output [`DCACHE_NLANES-1:0]                         dcache_mem_req_activemask_o                     ,
  output [`DCACHE_NLANES*`DCACHE_BLOCKOFFSETBITS-1:0] dcache_mem_req_blockoffset_o                    ,
  output [`DCACHE_NLANES*`BYTESOFWORD-1:0]            dcache_mem_req_wordoffset1h_o                   ,
  output [`DCACHE_NLANES*`XLEN-1:0]                   dcache_mem_req_data_o                           ,
  output [2:0]                                        dcache_mem_req_opcode_o                         ,
  output [3:0]                                        dcache_mem_req_param_o                          
`else
  //AXI
  output  [`NUM_L2CACHE-1:0]                          out_a_valid_o                                   ,
  input   [`NUM_L2CACHE-1:0]                          out_a_ready_i                                   ,
  output  [`NUM_L2CACHE*`OP_BITS-1:0]                 out_a_opcode_o                                  ,
  output  [`NUM_L2CACHE*`SIZE_BITS-1:0]               out_a_size_o                                    ,
  output  [`NUM_L2CACHE*`SOURCE_BITS-1:0]             out_a_source_o                                  ,
  output  [`NUM_L2CACHE*`ADDRESS_BITS-1:0]            out_a_address_o                                 ,
  output  [`NUM_L2CACHE*`MASK_BITS-1:0]               out_a_mask_o                                    ,
  output  [`NUM_L2CACHE*`DATA_BITS-1:0]               out_a_data_o                                    ,
  output  [`NUM_L2CACHE*3-1:0]                        out_a_param_o                                   ,

  input   [`NUM_L2CACHE-1:0]                          out_d_valid_i                                   ,
  output  [`NUM_L2CACHE-1:0]                          out_d_ready_o                                   ,
  input   [`NUM_L2CACHE*`OP_BITS-1:0]                 out_d_opcode_i                                  ,
  input   [`NUM_L2CACHE*`SIZE_BITS-1:0]               out_d_size_i                                    ,
  input   [`NUM_L2CACHE*`SOURCE_BITS-1:0]             out_d_source_i                                  ,
  input   [`NUM_L2CACHE*`DATA_BITS-1:0]               out_d_data_i                                    ,
  input   [`NUM_L2CACHE*3-1:0]                        out_d_param_i                                           
`endif
  );

  //CTA2warp and warp2CTA
  wire    [`NUMBER_CU-1:0]                                      cta2warp_valid                            ;
  wire    [`NUMBER_CU-1:0]                                      cta2warp_ready                            ;
  wire    [`NUMBER_CU*`WF_COUNT_WIDTH_PER_WG-1:0]               cta2warp_dispatch2cu_wg_wf_count          ;
  wire    [`NUMBER_CU*`WAVE_ITEM_WIDTH-1:0]                     cta2warp_dispatch2cu_wf_size_dispatch     ;
  wire    [`NUMBER_CU*(`SGPR_ID_WIDTH+1)-1:0]                   cta2warp_dispatch2cu_sgpr_base_dispatch   ;
  wire    [`NUMBER_CU*(`VGPR_ID_WIDTH+1)-1:0]                   cta2warp_dispatch2cu_vgpr_base_dispatch   ;
  wire    [`NUMBER_CU*`TAG_WIDTH-1:0]                           cta2warp_dispatch2cu_wf_tag_dispatch      ;  
  wire    [`NUMBER_CU*(`LDS_ID_WIDTH+1)-1:0]                    cta2warp_dispatch2cu_lds_base_dispatch    ;  
  wire    [`NUMBER_CU*`MEM_ADDR_WIDTH-1:0]                      cta2warp_dispatch2cu_start_pc_dispatch    ;  
  wire    [`NUMBER_CU*`MEM_ADDR_WIDTH-1:0]                      cta2warp_dispatch2cu_pds_baseaddr_dispatch;  
  wire    [`NUMBER_CU*`MEM_ADDR_WIDTH-1:0]                      cta2warp_dispatch2cu_gds_baseaddr_dispatch;  
  wire    [`NUMBER_CU*`MEM_ADDR_WIDTH-1:0]                      cta2warp_dispatch2cu_csr_knl_dispatch     ;  
  wire    [`NUMBER_CU*`WG_SIZE_X_WIDTH-1:0]                     cta2warp_dispatch2cu_wgid_x_dispatch      ;  
  wire    [`NUMBER_CU*`WG_SIZE_Y_WIDTH-1:0]                     cta2warp_dispatch2cu_wgid_y_dispatch      ;  
  wire    [`NUMBER_CU*`WG_SIZE_Z_WIDTH-1:0]                     cta2warp_dispatch2cu_wgid_z_dispatch      ;  
  wire    [`NUMBER_CU*32-1:0]                                   cta2warp_dispatch2cu_wg_id                ; 
  
  wire    [`NUMBER_CU-1:0]                                      warp2cta_valid                            ;
  wire    [`NUMBER_CU-1:0]                                      warp2cta_ready                            ;
  wire    [`NUMBER_CU*`TAG_WIDTH-1:0]                           warp2cta_cu2dispatch_wf_tag_done          ;

  //sm_wrapper mem_req and mem_rsp
`ifdef NO_CACHE
  wire  [`NUMBER_CU-1:0]                                        icache_mem_rsp_valid                      ;
  wire  [`NUMBER_CU-1:0]                                        icache_mem_rsp_ready                      ;
  wire  [`NUMBER_CU*`XLEN-1:0]                                  icache_mem_rsp_addr                       ;
  wire  [`NUMBER_CU*`DCACHE_BLOCKWORDS*`XLEN-1:0]               icache_mem_rsp_data                       ;
  wire  [`NUMBER_CU*`D_SOURCE-1:0]                              icache_mem_rsp_source                     ;

  wire  [`NUMBER_CU-1:0]                                        icache_mem_req_valid                      ;
  wire  [`NUMBER_CU-1:0]                                        icache_mem_req_ready                      ;
  wire  [`NUMBER_CU*`XLEN-1:0]                                  icache_mem_req_addr                       ;
  wire  [`NUMBER_CU*`D_SOURCE-1:0]                              icache_mem_req_source                     ;

  wire  [`NUMBER_CU-1:0]                                        dcache_mem_rsp_valid                      ;
  wire  [`NUMBER_CU-1:0]                                        dcache_mem_rsp_ready                      ;
  wire  [`NUMBER_CU*`WIDBITS-1:0]                               dcache_mem_rsp_instrid                    ;
  wire  [`NUMBER_CU*`DCACHE_NLANES*`XLEN-1:0]                   dcache_mem_rsp_data                       ;
  wire  [`NUMBER_CU*`DCACHE_NLANES-1:0]                         dcache_mem_rsp_activemask                 ;

  wire  [`NUMBER_CU-1:0]                                        dcache_mem_req_valid                      ;
  wire  [`NUMBER_CU-1:0]                                        dcache_mem_req_ready                      ;
  wire  [`NUMBER_CU*`WIDBITS-1:0]                               dcache_mem_req_instrid                    ;
  wire  [`NUMBER_CU*`DCACHE_SETIDXBITS-1:0]                     dcache_mem_req_setidx                     ;
  wire  [`NUMBER_CU*`DCACHE_TAGBITS-1:0]                        dcache_mem_req_tag                        ;
  wire  [`NUMBER_CU*`DCACHE_NLANES-1:0]                         dcache_mem_req_activemask                 ;
  wire  [`NUMBER_CU*`DCACHE_NLANES*`DCACHE_BLOCKOFFSETBITS-1:0] dcache_mem_req_blockoffset                ;
  wire  [`NUMBER_CU*`DCACHE_NLANES*`BYTESOFWORD-1:0]            dcache_mem_req_wordoffset1h               ;
  wire  [`NUMBER_CU*`DCACHE_NLANES*`XLEN-1:0]                   dcache_mem_req_data                       ;
  wire  [`NUMBER_CU*3-1:0]                                      dcache_mem_req_opcode                     ;
  wire  [`NUMBER_CU*4-1:0]                                      dcache_mem_req_param                      ;
`else
  wire    [`NUMBER_CU-1:0]                                      mem_rsp_ready                             ;
  wire    [`NUMBER_CU-1:0]                                      mem_rsp_valid                             ;
  wire    [`NUMBER_CU*3-1:0]                                    mem_rsp_d_opcpde                          ;
  wire    [`NUMBER_CU*`XLEN-1:0]                                mem_rsp_d_addr                            ;
  wire    [`NUMBER_CU*`DCACHE_BLOCKWORDS*`XLEN-1:0]             mem_rsp_d_data                            ;
  wire    [`NUMBER_CU*`D_SOURCE-1:0]                            mem_rsp_d_source                          ;

  wire    [`NUMBER_CU-1:0]                                      mem_req_ready                             ;
  wire    [`NUMBER_CU-1:0]                                      mem_req_valid                             ;
  wire    [`NUMBER_CU*3-1:0]                                    mem_req_a_opcode                          ;
  wire    [`NUMBER_CU*3-1:0]                                    mem_req_a_param                           ;
  wire    [`NUMBER_CU*`XLEN-1:0]                                mem_req_a_addr                            ;
  wire    [`NUMBER_CU*`DCACHE_BLOCKWORDS*`XLEN-1:0]             mem_req_a_data                            ;
  wire    [`NUMBER_CU*`DCACHE_BLOCKWORDS*`BYTESOFWORD-1:0]      mem_req_a_mask                            ;
  wire    [`NUMBER_CU*`D_SOURCE-1:0]                            mem_req_a_source                          ;
  wire    [`NUMBER_CU-1:0]                                      cache_invalid                             ;
`endif

  //sm2cluster_arb mem_req_out and mem_rst_in
  wire    [`NUM_CLUSTER-1:0]                                    mem_req_out_ready                         ;     
  wire    [`NUM_CLUSTER-1:0]                                    mem_req_out_valid                         ;     
  wire    [`NUM_CLUSTER*`OP_BITS-1:0]                           mem_req_out_opcode                        ;
  wire    [`NUM_CLUSTER*`SIZE_BITS-1:0]                         mem_req_out_size                          ;     
  wire    [`NUM_CLUSTER*`SOURCE_BITS-1:0]                       mem_req_out_source                        ;     
  wire    [`NUM_CLUSTER*`ADDRESS_BITS-1:0]                      mem_req_out_address                       ;     
  wire    [`NUM_CLUSTER*`MASK_BITS-1:0]                         mem_req_out_mask                          ;     
  wire    [`NUM_CLUSTER*`DATA_BITS-1:0]                         mem_req_out_data                          ;     
  wire    [`NUM_CLUSTER*3-1:0]                                  mem_req_out_param                         ;     

  wire    [`NUM_CLUSTER-1:0]                                    mem_rsp_in_ready                          ;      
  wire    [`NUM_CLUSTER-1:0]                                    mem_rsp_in_valid                          ;      
  wire    [`NUM_CLUSTER*`OP_BITS-1:0]                           mem_rsp_in_opcode                         ;      
  wire    [`NUM_CLUSTER*`SIZE_BITS-1:0]                         mem_rsp_in_size                           ;      
  wire    [`NUM_CLUSTER*`SOURCE_BITS-1:0]                       mem_rsp_in_source                         ;      
  wire    [`NUM_CLUSTER*`DATA_BITS-1:0]                         mem_rsp_in_data                           ;      
  wire    [`NUM_CLUSTER*3-1:0]                                  mem_rsp_in_param                          ;      
  wire    [`NUM_CLUSTER*`ADDRESS_BITS-1:0]                      mem_rsp_in_address                        ;

  //l2_distribute mem_req_vec_out and mem_rsp_vec_in
  wire    [`NUM_CLUSTER*`NUM_L2CACHE-1:0]                       mem_req_vec_out_valid                     ;
  wire    [`NUM_CLUSTER*`NUM_L2CACHE-1:0]                       mem_req_vec_out_ready                     ;
  wire    [`NUM_CLUSTER*`NUM_L2CACHE*`OP_BITS-1:0]              mem_req_vec_out_opcode                    ;
  wire    [`NUM_CLUSTER*`NUM_L2CACHE*`SIZE_BITS-1:0]            mem_req_vec_out_size                      ;
  wire    [`NUM_CLUSTER*`NUM_L2CACHE*`SOURCE_BITS-1:0]          mem_req_vec_out_source                    ;
  wire    [`NUM_CLUSTER*`NUM_L2CACHE*`ADDRESS_BITS-1:0]         mem_req_vec_out_address                   ;
  wire    [`NUM_CLUSTER*`NUM_L2CACHE*`MASK_BITS-1:0]            mem_req_vec_out_mask                      ;
  wire    [`NUM_CLUSTER*`NUM_L2CACHE*`DATA_BITS-1:0]            mem_req_vec_out_data                      ;
  wire    [`NUM_CLUSTER*`NUM_L2CACHE*3-1:0]                     mem_req_vec_out_param                     ;

  wire    [`NUM_CLUSTER*`NUM_L2CACHE-1:0]                       mem_rsp_vec_in_valid                      ;
  wire    [`NUM_CLUSTER*`NUM_L2CACHE-1:0]                       mem_rsp_vec_in_ready                      ;
  wire    [`NUM_CLUSTER*`NUM_L2CACHE*`ADDRESS_BITS-1:0]         mem_rsp_vec_in_address                    ;
  wire    [`NUM_CLUSTER*`NUM_L2CACHE*`OP_BITS-1:0]              mem_rsp_vec_in_opcode                     ;
  wire    [`NUM_CLUSTER*`NUM_L2CACHE*`SIZE_BITS-1:0]            mem_rsp_vec_in_size                       ;
  wire    [`NUM_CLUSTER*`NUM_L2CACHE*`SOURCE_BITS-1:0]          mem_rsp_vec_in_source                     ;
  wire    [`NUM_CLUSTER*`NUM_L2CACHE*`DATA_BITS-1:0]            mem_rsp_vec_in_data                       ;
  wire    [`NUM_CLUSTER*`NUM_L2CACHE*3-1:0]                     mem_rsp_vec_in_param                      ;

  //cluster_to_l2_arb mem_req_out and mem_rsp_in
  wire    [`NUM_L2CACHE-1:0]                                    cluster_to_l2_arb_mem_req_out_valid       ;
  wire    [`NUM_L2CACHE-1:0]                                    cluster_to_l2_arb_mem_req_out_ready       ;
  wire    [`NUM_L2CACHE*`OP_BITS-1:0]                           cluster_to_l2_arb_mem_req_out_opcode      ;
  wire    [`NUM_L2CACHE*`SIZE_BITS-1:0]                         cluster_to_l2_arb_mem_req_out_size        ;
  wire    [`NUM_L2CACHE*`SOURCE_BITS-1:0]                       cluster_to_l2_arb_mem_req_out_source      ;
  wire    [`NUM_L2CACHE*`ADDRESS_BITS-1:0]                      cluster_to_l2_arb_mem_req_out_address     ;
  wire    [`NUM_L2CACHE*`MASK_BITS-1:0]                         cluster_to_l2_arb_mem_req_out_mask        ;
  wire    [`NUM_L2CACHE*`DATA_BITS-1:0]                         cluster_to_l2_arb_mem_req_out_data        ;
  wire    [`NUM_L2CACHE*`PARAM_BITS-1:0]                        cluster_to_l2_arb_mem_req_out_param       ;

  wire    [`NUM_L2CACHE-1:0]                                    cluster_to_l2_arb_mem_rsp_in_valid        ;    
  wire    [`NUM_L2CACHE-1:0]                                    cluster_to_l2_arb_mem_rsp_in_ready        ;    
  wire    [`NUM_L2CACHE*`OP_BITS-1:0]                           cluster_to_l2_arb_mem_rsp_in_opcode       ;    
  wire    [`NUM_L2CACHE*`SIZE_BITS-1:0]                         cluster_to_l2_arb_mem_rsp_in_size         ;    
  wire    [`NUM_L2CACHE*`SOURCE_BITS-1:0]                       cluster_to_l2_arb_mem_rsp_in_source       ;    
  wire    [`NUM_L2CACHE*`ADDRESS_BITS-1:0]                      cluster_to_l2_arb_mem_rsp_in_address      ;    
  wire    [`NUM_L2CACHE*`DATA_BITS-1:0]                         cluster_to_l2_arb_mem_rsp_in_data         ;    
  wire    [`NUM_L2CACHE*`PARAM_BITS-1:0]                        cluster_to_l2_arb_mem_rsp_in_param        ;  

  //l2_cache out_a and out_d(   AXI      )
  wire    [`NUM_L2CACHE-1:0]                                    l2cache_out_a_valid                       ;                                 
  wire    [`NUM_L2CACHE-1:0]                                    l2cache_out_a_ready                       ;                                 
  wire    [`NUM_L2CACHE*`OP_BITS-1:0]                           l2cache_out_a_opcode                      ;                                 
  wire    [`NUM_L2CACHE*`SIZE_BITS-1:0]                         l2cache_out_a_size                        ;                                 
  wire    [`NUM_L2CACHE*`SOURCE_BITS-1:0]                       l2cache_out_a_source                      ;                                 
  wire    [`NUM_L2CACHE*`ADDRESS_BITS-1:0]                      l2cache_out_a_address                     ;                                 
  wire    [`NUM_L2CACHE*`MASK_BITS-1:0]                         l2cache_out_a_mask                        ;                                 
  wire    [`NUM_L2CACHE*`DATA_BITS-1:0]                         l2cache_out_a_data                        ;                                 
  wire    [`NUM_L2CACHE*3-1:0]                                  l2cache_out_a_param                       ;                                 

  wire    [`NUM_L2CACHE-1:0]                                    l2cache_out_d_valid                       ;                                 
  wire    [`NUM_L2CACHE-1:0]                                    l2cache_out_d_ready                       ;                                 
  wire    [`NUM_L2CACHE*`OP_BITS-1:0]                           l2cache_out_d_opcode                      ;                                 
  wire    [`NUM_L2CACHE*`SIZE_BITS-1:0]                         l2cache_out_d_size                        ;                                
  wire    [`NUM_L2CACHE*`SOURCE_BITS-1:0]                       l2cache_out_d_source                      ;                                 
  wire    [`NUM_L2CACHE*`DATA_BITS-1:0]                         l2cache_out_d_data                        ;                                 
  wire    [`NUM_L2CACHE*3-1:0]                                  l2cache_out_d_param                       ;
  wire    [`NUM_L2CACHE-1:0]                                    l2cache_finish_issue                      ;

  wire                                                          wg_done                                   ;
  reg                                                           is_flushing                               ;

  //TODO: cache_invalid can't multi SM
  assign cache_invalid    = {wg_done,{(`NUMBER_CU-1){1'b0}}};
  //assign cache_invalid    = {/*host_rsp_valid_o*/wg_done,1'b0} ;
  assign host_rsp_valid_o = l2cache_finish_issue && is_flushing;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      is_flushing <= 'd0;
    end
    else if(wg_done) begin
      is_flushing <= 1'b1;
    end
    else if(l2cache_finish_issue) begin
      is_flushing <= 1'b0;
    end
    else begin
      is_flushing <= is_flushing;
    end
  end

  //      cta_interface
  cta_interface cta(
    .clk                                             (clk                                             ),     
    .rst_n                                           (rst_n                                           ),       
                                                       
    .host2cta_valid_i                                (host_req_valid_i                                ),        
    .host2cta_ready_o                                (host_req_ready_o                                ),        
    .host2cta_host_wg_id_i                           (host_req_wg_id_i                                ),    
    .host2cta_host_num_wf_i                          (host_req_num_wf_i                               ),        
    .host2cta_host_wf_size_i                         (host_req_wf_size_i                              ),    
    .host2cta_host_start_pc_i                        (host_req_start_pc_i                             ),        
    .host2cta_host_kernel_size_3d_i                  (host_req_kernel_size_3d_i                       ),            
    .host2cta_host_pds_baseaddr_i                    (host_req_pds_baseaddr_i                         ),                
    .host2cta_host_csr_knl_i                         (host_req_csr_knl_i                              ),        
    .host2cta_host_gds_baseaddr_i                    (host_req_gds_baseaddr_i                         ),        
    .host2cta_host_vgpr_size_total_i                 (host_req_vgpr_size_total_i                      ),        
    .host2cta_host_sgpr_size_total_i                 (host_req_sgpr_size_total_i                      ),        
    .host2cta_host_lds_size_total_i                  (host_req_lds_size_total_i                       ),        
    .host2cta_host_gds_size_total_i                  (host_req_gds_size_total_i                       ),  
    .host2cta_host_vgpr_size_per_wf_i                (host_req_vgpr_size_per_wf_i                     ),      
    .host2cta_host_sgpr_size_per_wf_i                (host_req_sgpr_size_per_wf_i                     ),          
       
    .cta2host_rcvd_ack_o                             (                                                ),
    .cta2host_valid_o                                (/*host_rsp_valid_o*/wg_done                     ),          
    .cta2host_ready_i                                (host_rsp_ready_i                                ),              
    .cta2host_inflight_wg_buffer_host_wf_done_wg_id_o(host_rsp_inflight_wg_buffer_host_wf_done_wg_id_o),    
                                                    
    .cta2warp_valid_o                                (cta2warp_valid                                  ),                  
    .cta2warp_ready_i                                (cta2warp_ready                                  ),                  
    .cta2warp_dispatch2cu_wg_wf_count_o              (cta2warp_dispatch2cu_wg_wf_count                ),                    
    .cta2warp_dispatch2cu_wf_size_dispatch_o         (cta2warp_dispatch2cu_wf_size_dispatch           ),          
    .cta2warp_dispatch2cu_sgpr_base_dispatch_o       (cta2warp_dispatch2cu_sgpr_base_dispatch         ),              
    .cta2warp_dispatch2cu_vgpr_base_dispatch_o       (cta2warp_dispatch2cu_vgpr_base_dispatch         ),            
    .cta2warp_dispatch2cu_wf_tag_dispatch_o          (cta2warp_dispatch2cu_wf_tag_dispatch            ),            
    .cta2warp_dispatch2cu_lds_base_dispatch_o        (cta2warp_dispatch2cu_lds_base_dispatch          ),              
    .cta2warp_dispatch2cu_start_pc_dispatch_o        (cta2warp_dispatch2cu_start_pc_dispatch          ),              
    .cta2warp_dispatch2cu_pds_baseaddr_dispatch_o    (cta2warp_dispatch2cu_pds_baseaddr_dispatch      ),                
    .cta2warp_dispatch2cu_gds_baseaddr_dispatch_o    (cta2warp_dispatch2cu_gds_baseaddr_dispatch      ),                  
    .cta2warp_dispatch2cu_csr_knl_dispatch_o         (cta2warp_dispatch2cu_csr_knl_dispatch           ),                
    .cta2warp_dispatch2cu_wgid_x_dispatch_o          (cta2warp_dispatch2cu_wgid_x_dispatch            ),                
    .cta2warp_dispatch2cu_wgid_y_dispatch_o          (cta2warp_dispatch2cu_wgid_y_dispatch            ),                  
    .cta2warp_dispatch2cu_wgid_z_dispatch_o          (cta2warp_dispatch2cu_wgid_z_dispatch            ),          
    .cta2warp_dispatch2cu_wg_id_o                    (cta2warp_dispatch2cu_wg_id                      ),              
                                                    
    .warp2cta_valid_i                                (warp2cta_valid                                  ),       
    .warp2cta_ready_o                                (warp2cta_ready                                  ),            
    .warp2cta_cu2dispatch_wf_tag_done_i              (warp2cta_cu2dispatch_wf_tag_done                )    
    );

  //      sm_wrapper(num_sm)
  genvar i,p;
  generate for(i=0;i<`NUM_CLUSTER;i=i+1) begin : A1
    for(p=0;p<`NUM_SM_IN_CLUSTER;p=p+1) begin : A2
      sm_wrapper U_sm_wrapper(
        .clk                                     (clk                                                                                                            ),     
        .rst_n                                   (rst_n                                                                                                          ),     
                                                
        .cta_req_ready_o                         (cta2warp_ready[i*`NUM_SM_IN_CLUSTER+p]                                                                         ),     
        .cta_req_valid_i                         (cta2warp_valid[i*`NUM_SM_IN_CLUSTER+p]                                                                         ),    
        .cta_req_dispatch2cu_wg_wf_count_i       (cta2warp_dispatch2cu_wg_wf_count[(i*`NUM_SM_IN_CLUSTER+p+1)*`WF_COUNT_WIDTH_PER_WG-1-:`WF_COUNT_WIDTH_PER_WG]  ),  
        .cta_req_dispatch2cu_wf_size_dispatch_i  (cta2warp_dispatch2cu_wf_size_dispatch[(i*`NUM_SM_IN_CLUSTER+p+1)*`WAVE_ITEM_WIDTH-1-:`WAVE_ITEM_WIDTH]         ),  
        .cta_req_dispatch2cu_sgpr_base_dispatch_i(cta2warp_dispatch2cu_sgpr_base_dispatch[(i*`NUM_SM_IN_CLUSTER+p+1)*(`SGPR_ID_WIDTH+1)-1-:(`SGPR_ID_WIDTH+1)]   ),  
        .cta_req_dispatch2cu_vgpr_base_dispatch_i(cta2warp_dispatch2cu_vgpr_base_dispatch[(i*`NUM_SM_IN_CLUSTER+p+1)*(`VGPR_ID_WIDTH+1)-1-:(`VGPR_ID_WIDTH+1)]   ),       
        .cta_req_dispatch2cu_wf_tag_dispatch_i   (cta2warp_dispatch2cu_wf_tag_dispatch[(i*`NUM_SM_IN_CLUSTER+p+1)*`TAG_WIDTH-1-:`TAG_WIDTH]                      ),   
        .cta_req_dispatch2cu_lds_base_dispatch_i (cta2warp_dispatch2cu_lds_base_dispatch[(i*`NUM_SM_IN_CLUSTER+p+1)*(`LDS_ID_WIDTH+1)-1-:(`LDS_ID_WIDTH+1)]      ),     
        .cta_req_dispatch2cu_start_pc_dispatch_i (cta2warp_dispatch2cu_start_pc_dispatch[(i*`NUM_SM_IN_CLUSTER+p+1)*`MEM_ADDR_WIDTH-1-:`MEM_ADDR_WIDTH]          ),   
        .cta_req_dispatch2cu_pds_base_dispatch_i (cta2warp_dispatch2cu_pds_baseaddr_dispatch[(i*`NUM_SM_IN_CLUSTER+p+1)*`MEM_ADDR_WIDTH-1-:`MEM_ADDR_WIDTH]      ),     
        .cta_req_dispatch2cu_gds_base_dispatch_i (cta2warp_dispatch2cu_gds_baseaddr_dispatch[(i*`NUM_SM_IN_CLUSTER+p+1)*`MEM_ADDR_WIDTH-1-:`MEM_ADDR_WIDTH]      ),       
        .cta_req_dispatch2cu_csr_knl_dispatch_i  (cta2warp_dispatch2cu_csr_knl_dispatch[(i*`NUM_SM_IN_CLUSTER+p+1)*`MEM_ADDR_WIDTH-1-:`MEM_ADDR_WIDTH]           ),  
        .cta_req_dispatch2cu_wgid_x_dispatch_i   (cta2warp_dispatch2cu_wgid_x_dispatch[(i*`NUM_SM_IN_CLUSTER+p+1)*`WG_SIZE_X_WIDTH-1-:`WG_SIZE_X_WIDTH]          ),  
        .cta_req_dispatch2cu_wgid_y_dispatch_i   (cta2warp_dispatch2cu_wgid_y_dispatch[(i*`NUM_SM_IN_CLUSTER+p+1)*`WG_SIZE_Y_WIDTH-1-:`WG_SIZE_Y_WIDTH]          ),  
        .cta_req_dispatch2cu_wgid_z_dispatch_i   (cta2warp_dispatch2cu_wgid_z_dispatch[(i*`NUM_SM_IN_CLUSTER+p+1)*`WG_SIZE_Z_WIDTH-1-:`WG_SIZE_Z_WIDTH]          ),  
        .cta_req_dispatch2cu_wg_id_i             (cta2warp_dispatch2cu_wg_id[(i*`NUM_SM_IN_CLUSTER+p+1)*32-1-:32]                                                ), 
                                                        
        .cta_rsp_ready_i                         (warp2cta_ready[i*`NUM_SM_IN_CLUSTER+p]                                                                         ),   
        .cta_rsp_valid_o                         (warp2cta_valid[i*`NUM_SM_IN_CLUSTER+p]                                                                         ),   
        .cta_rsp_cu2dispatch_wf_tag_done_o       (warp2cta_cu2dispatch_wf_tag_done[(i*`NUM_SM_IN_CLUSTER+p+1)*`TAG_WIDTH-1-:`TAG_WIDTH]                          ),
`ifdef NO_CACHE
        .icache_mem_rsp_valid_i                  (icache_mem_rsp_valid[i*`NUM_SM_IN_CLUSTER+p]                                                                   ),    
        .icache_mem_rsp_ready_o                  (icache_mem_rsp_ready[i*`NUM_SM_IN_CLUSTER+p]                                                                   ),   
        .icache_mem_rsp_addr_i                   (icache_mem_rsp_addr[(i*`NUM_SM_IN_CLUSTER+p+1)*`XLEN-1-:`XLEN]                                                 ),      
        .icache_mem_rsp_data_i                   (icache_mem_rsp_data[(i*`NUM_SM_IN_CLUSTER+p+1)*`DCACHE_BLOCKWORDS*`XLEN-1-:(`DCACHE_BLOCKWORDS*`XLEN)]         ),     
        .icache_mem_rsp_source_i                 (icache_mem_rsp_source[(i*`NUM_SM_IN_CLUSTER+p+1)*`D_SOURCE-1-:`D_SOURCE]                                       ),
        .icache_mem_req_valid_o                  (icache_mem_req_valid[i*`NUM_SM_IN_CLUSTER+p]                                                                   ),
        .icache_mem_req_ready_i                  (icache_mem_req_ready[i*`NUM_SM_IN_CLUSTER+p]                                                                   ), 
        .icache_mem_req_addr_o                   (icache_mem_req_addr[(i*`NUM_SM_IN_CLUSTER+p+1)*`XLEN-1-:`XLEN]                                                 ),  
        .icache_mem_req_source_o                 (icache_mem_req_source[(i*`NUM_SM_IN_CLUSTER+p+1)*`D_SOURCE-1-:`D_SOURCE]                                       ),   
                                                                             
        .dcache_mem_rsp_valid_i                  (dcache_mem_rsp_valid[i*`NUM_SM_IN_CLUSTER+p]                                                                   ),
        .dcache_mem_rsp_ready_o                  (dcache_mem_rsp_ready[i*`NUM_SM_IN_CLUSTER+p]                                                                   ),
        .dcache_mem_rsp_instrid_i                (dcache_mem_rsp_instrid[(i*`NUM_SM_IN_CLUSTER+p+1)*`WIDBITS-1-:`WIDBITS]                                        ),
        .dcache_mem_rsp_data_i                   (dcache_mem_rsp_data[(i*`NUM_SM_IN_CLUSTER+p+1)*`DCACHE_NLANES*`XLEN-1-:`DCACHE_NLANES*`XLEN]                   ),
        .dcache_mem_rsp_activemask_i             (dcache_mem_rsp_activemask[(i*`NUM_SM_IN_CLUSTER+p+1)*`DCACHE_NLANES-1-:`DCACHE_NLANES]                         ),
                                                                             
        .dcache_mem_req_valid_o                  (dcache_mem_req_valid[i*`NUM_SM_IN_CLUSTER+p]                                                                   ),
        .dcache_mem_req_ready_i                  (dcache_mem_req_ready[i*`NUM_SM_IN_CLUSTER+p]                                                                   ),
        .dcache_mem_req_instrid_o                (dcache_mem_req_instrid[(i*`NUM_SM_IN_CLUSTER+p+1)*`WIDBITS-1-:`WIDBITS]                                        ),
        .dcache_mem_req_setidx_o                 (dcache_mem_req_setidx[(i*`NUM_SM_IN_CLUSTER+p+1)*`DCACHE_SETIDXBITS-1-:`DCACHE_SETIDXBITS]                     ),
        .dcache_mem_req_tag_o                    (dcache_mem_req_tag[(i*`NUM_SM_IN_CLUSTER+p+1)*`DCACHE_TAGBITS-1-:`DCACHE_TAGBITS]                              ),
        .dcache_mem_req_activemask_o             (dcache_mem_req_activemask[(i*`NUM_SM_IN_CLUSTER+p+1)*`DCACHE_NLANES-1-:`DCACHE_NLANES]                         ),
        .dcache_mem_req_blockoffset_o            (dcache_mem_req_blockoffset[(i*`NUM_SM_IN_CLUSTER+p+1)*`DCACHE_NLANES*`DCACHE_BLOCKOFFSETBITS-1-:`DCACHE_NLANES*`DCACHE_BLOCKOFFSETBITS]),
        .dcache_mem_req_wordoffset1h_o           (dcache_mem_req_wordoffset1h[(i*`NUM_SM_IN_CLUSTER+p+1)*`DCACHE_NLANES*`BYTESOFWORD-1-:`DCACHE_NLANES*`BYTESOFWORD]),
        .dcache_mem_req_data_o                   (dcache_mem_req_data[(i*`NUM_SM_IN_CLUSTER+p+1)*`DCACHE_NLANES*`XLEN-1-:`DCACHE_NLANES*`XLEN]                   ),
        .dcache_mem_req_opcode_o                 (dcache_mem_req_opcode[(i*`NUM_SM_IN_CLUSTER+p+1)*3-1-:3]                                                       ),
        .dcache_mem_req_param_o                  (dcache_mem_req_param[(i*`NUM_SM_IN_CLUSTER+p+1)*4-1-:4]                                                        )
`else
        .cache_invalid_i                         (cache_invalid[i*`NUM_SM_IN_CLUSTER+p]                                                                          ),
                                                
        .mem_rsp_ready_o                         (mem_rsp_ready[i*`NUM_SM_IN_CLUSTER+p]                                                                          ), 
        .mem_rsp_valid_i                         (mem_rsp_valid[i*`NUM_SM_IN_CLUSTER+p]                                                                          ), 
        .mem_rsp_d_opcode_i                      (mem_rsp_d_opcpde[(i*`NUM_SM_IN_CLUSTER+p+1)*3-1-:3]                                                            ), 
        .mem_rsp_d_addr_i                        (mem_rsp_d_addr[(i*`NUM_SM_IN_CLUSTER+p+1)*`XLEN-1-:`XLEN]                                                      ),   
        .mem_rsp_d_data_i                        (mem_rsp_d_data[(i*`NUM_SM_IN_CLUSTER+p+1)*`DCACHE_BLOCKWORDS*`XLEN-1-:(`DCACHE_BLOCKWORDS*`XLEN)]              ),     
        .mem_rsp_d_source_i                      (mem_rsp_d_source[(i*`NUM_SM_IN_CLUSTER+p+1)*`D_SOURCE-1-:`D_SOURCE]                                            ),
                                                
        .mem_req_ready_i                         (mem_req_ready[i*`NUM_SM_IN_CLUSTER+p]                                                                          ), 
        .mem_req_valid_o                         (mem_req_valid[i*`NUM_SM_IN_CLUSTER+p]                                                                          ),     
        .mem_req_a_opcode_o                      (mem_req_a_opcode[(i*`NUM_SM_IN_CLUSTER+p+1)*3-1-:3]                                                            ), 
        .mem_req_a_param_o                       (mem_req_a_param[(i*`NUM_SM_IN_CLUSTER+p+1)*3-1-:3]                                                             ),   
        .mem_req_a_addr_o                        (mem_req_a_addr[(i*`NUM_SM_IN_CLUSTER+p+1)*`XLEN-1-:`XLEN]                                                      ),     
        .mem_req_a_data_o                        (mem_req_a_data[(i*`NUM_SM_IN_CLUSTER+p+1)*`DCACHE_BLOCKWORDS*`XLEN-1-:(`DCACHE_BLOCKWORDS*`XLEN)]              ),     
        .mem_req_a_mask_o                        (mem_req_a_mask[(i*`NUM_SM_IN_CLUSTER+p+1)*`DCACHE_BLOCKWORDS*`BYTESOFWORD-1-:(`DCACHE_BLOCKWORDS*`BYTESOFWORD)]),     
        .mem_req_a_source_o                      (mem_req_a_source[(i*`NUM_SM_IN_CLUSTER+p+1)*`D_SOURCE-1-:`D_SOURCE]                                            )
`endif

        );
    end
  end
  endgenerate

`ifndef NO_CACHE
  //l2cache   cluster2l2arb
  genvar j;
  generate for(j=0;j<`NUM_L2CACHE;j=j+1) begin : B1
    Scheduler l2cache(
      .clk                  (clk                                                                        ),       
      .rst_n                (rst_n                                                                      ),       
      .sche_in_a_valid_i    (cluster_to_l2_arb_mem_req_out_valid[j]                                     ),     
      .sche_in_a_ready_o    (cluster_to_l2_arb_mem_req_out_ready[j]                                     ),               
      .sche_in_a_opcode_i   (cluster_to_l2_arb_mem_req_out_opcode[(j+1)*`OP_BITS-1-:`OP_BITS]           ),             
      .sche_in_a_size_i     (cluster_to_l2_arb_mem_req_out_size[(j+1)*`SIZE_BITS-1-:`SIZE_BITS]         ),                 
      .sche_in_a_source_i   (cluster_to_l2_arb_mem_req_out_source[(j+1)*`SOURCE_BITS-1-:`SOURCE_BITS]   ),                   
      .sche_in_a_addresss_i (cluster_to_l2_arb_mem_req_out_address[(j+1)*`ADDRESS_BITS-1-:`ADDRESS_BITS]),                     
      .sche_in_a_mask_i     (cluster_to_l2_arb_mem_req_out_mask[(j+1)*`MASK_BITS-1-:`MASK_BITS]         ),                     
      .sche_in_a_data_i     (cluster_to_l2_arb_mem_req_out_data[(j+1)*`DATA_BITS-1-:`DATA_BITS]         ),                       
      .sche_in_a_param_i    (cluster_to_l2_arb_mem_req_out_param[(j+1)*3-1-:3]                          ),                 
      .sche_in_d_valid_o    (cluster_to_l2_arb_mem_rsp_in_valid[j]                                      ),         
      .sche_in_d_ready_i    (cluster_to_l2_arb_mem_rsp_in_ready[j]                                      ),           
      .sche_in_d_address_o  (cluster_to_l2_arb_mem_rsp_in_address[(j+1)*`ADDRESS_BITS-1-:`ADDRESS_BITS] ),             
      .sche_in_d_opcode_o   (cluster_to_l2_arb_mem_rsp_in_opcode[(j+1)*`OP_BITS-1-:`OP_BITS]            ),                 
      .sche_in_d_size_o     (cluster_to_l2_arb_mem_rsp_in_size[(j+1)*`SIZE_BITS-1-:`SIZE_BITS]          ),                   
      .sche_in_d_source_o   (cluster_to_l2_arb_mem_rsp_in_source[(j+1)*`SOURCE_BITS-1-:`SOURCE_BITS]    ),               
      .sche_in_d_data_o     (cluster_to_l2_arb_mem_rsp_in_data[(j+1)*`DATA_BITS-1-:`DATA_BITS]          ),               
      .sche_in_d_param_o    (cluster_to_l2_arb_mem_rsp_in_param[(j+1)*3-1-:3]                           ), 
      .finish_issue_o       (l2cache_finish_issue[j]                                                    ),
      .sche_out_a_valid_o   (l2cache_out_a_valid[j]                                                     ),     
      .sche_out_a_ready_i   (l2cache_out_a_ready[j]                                                     ),         
      .sche_out_a_opcode_o  (l2cache_out_a_opcode[(j+1)*`OP_BITS-1-:`OP_BITS]                           ),             
      .sche_out_a_size_o    (l2cache_out_a_size[(j+1)*`SIZE_BITS-1-:`SIZE_BITS]                         ),         
      .sche_out_a_source_o  (l2cache_out_a_source[(j+1)*`SOURCE_BITS-1-:`SOURCE_BITS]                   ),           
      .sche_out_a_addresss_o(l2cache_out_a_address[(j+1)*`ADDRESS_BITS-1-:`ADDRESS_BITS]                ),             
      .sche_out_a_mask_o    (l2cache_out_a_mask[(j+1)*`MASK_BITS-1-:`MASK_BITS]                         ),         
      .sche_out_a_data_o    (l2cache_out_a_data[(j+1)*`DATA_BITS-1-:`DATA_BITS]                         ),       
      .sche_out_a_param_o   (l2cache_out_a_param[(j+1)*3-1-:3]                                          ), 
      .sche_out_d_valid_i   (l2cache_out_d_valid[j]                                                     ),     
      .sche_out_d_ready_o   (l2cache_out_d_ready[j]                                                     ),       
      .sche_out_d_opcode_i  (l2cache_out_d_opcode[(j+1)*`OP_BITS-1-:`OP_BITS]                           ),       
      //.sche_out_d_size_i    (
      .sche_out_d_source_i  (l2cache_out_d_source[(j+1)*`SOURCE_BITS-1-:`SOURCE_BITS]                   ),     
      .sche_out_d_data_i    (l2cache_out_d_data[(j+1)*`DATA_BITS-1-:`DATA_BITS]                         )     
      //.sche_out_d_param_i   (
      );

    cluster_to_l2_arb cluster2l2Arb(
      .mem_req_vec_in_valid_i   (mem_req_vec_out_valid[(j+1)*`NUM_CLUSTER-1-:`NUM_CLUSTER]                                   ),             
      .mem_req_vec_in_ready_o   (mem_req_vec_out_ready[(j+1)*`NUM_CLUSTER-1-:`NUM_CLUSTER]                                   ),       
      .mem_req_vec_in_opcode_i  (mem_req_vec_out_opcode[(j+1)*`NUM_CLUSTER*`OP_BITS-1-:(`NUM_CLUSTER*`OP_BITS)]              ),         
      .mem_req_vec_in_size_i    (mem_req_vec_out_size[(j+1)*`NUM_CLUSTER*`SIZE_BITS-1-:(`NUM_CLUSTER*`SIZE_BITS)]            ),               
      .mem_req_vec_in_source_i  (mem_req_vec_out_source[(j+1)*`NUM_CLUSTER*`CLUSTER_SOURCE-1-:(`NUM_CLUSTER*`CLUSTER_SOURCE)]),                 
      .mem_req_vec_in_address_i (mem_req_vec_out_address[(j+1)*`NUM_CLUSTER*`ADDRESS_BITS-1-:(`NUM_CLUSTER*`ADDRESS_BITS)]   ),           
      .mem_req_vec_in_mask_i    (mem_req_vec_out_mask[(j+1)*`NUM_CLUSTER*`MASK_BITS-1-:(`NUM_CLUSTER*`MASK_BITS)]            ),                   
      .mem_req_vec_in_data_i    (mem_req_vec_out_data[(j+1)*`NUM_CLUSTER*`DATA_BITS-1-:(`NUM_CLUSTER*`DATA_BITS)]            ),             
      .mem_req_vec_in_param_i   (mem_req_vec_out_param[(j+1)*`NUM_CLUSTER*`PARAM_BITS-1-:(`NUM_CLUSTER*`PARAM_BITS)]         ),               
      .mem_req_out_valid_o      (cluster_to_l2_arb_mem_req_out_valid[j]                                                      ),         
      .mem_req_out_ready_i      (cluster_to_l2_arb_mem_req_out_ready[j]                                                      ),     
      .mem_req_out_opcode_o     (cluster_to_l2_arb_mem_req_out_opcode[(j+1)*`OP_BITS-1-:`OP_BITS]                            ),         
      .mem_req_out_size_o       (cluster_to_l2_arb_mem_req_out_size[(j+1)*`SIZE_BITS-1-:`SIZE_BITS]                          ),           
      .mem_req_out_source_o     (cluster_to_l2_arb_mem_req_out_source[(j+1)*`SOURCE_BITS-1-:`SOURCE_BITS]                    ),           
      .mem_req_out_address_o    (cluster_to_l2_arb_mem_req_out_address[(j+1)*`ADDRESS_BITS-1-:`ADDRESS_BITS]                 ),             
      .mem_req_out_mask_o       (cluster_to_l2_arb_mem_req_out_mask[(j+1)*`MASK_BITS-1-:`MASK_BITS]                          ),             
      .mem_req_out_data_o       (cluster_to_l2_arb_mem_req_out_data[(j+1)*`DATA_BITS-1-:`DATA_BITS]                          ),             
      .mem_req_out_param_o      (cluster_to_l2_arb_mem_req_out_param[(j+1)*`PARAM_BITS-1-:`PARAM_BITS]                       ),             
      .mem_rsp_in_valid_i       (cluster_to_l2_arb_mem_rsp_in_valid[j]                                                       ),         
      .mem_rsp_in_ready_o       (cluster_to_l2_arb_mem_rsp_in_ready[j]                                                       ),     
      .mem_rsp_in_opcode_i      (cluster_to_l2_arb_mem_rsp_in_opcode[(j+1)*`OP_BITS-1-:`OP_BITS]                             ),         
      .mem_rsp_in_size_i        (cluster_to_l2_arb_mem_rsp_in_size[(j+1)*`SIZE_BITS-1-:`SIZE_BITS]                           ),           
      .mem_rsp_in_source_i      (cluster_to_l2_arb_mem_rsp_in_source[(j+1)*`SOURCE_BITS-1-:`SOURCE_BITS]                     ),           
      .mem_rsp_in_address_i     (cluster_to_l2_arb_mem_rsp_in_address[(j+1)*`ADDRESS_BITS-1-:`ADDRESS_BITS]                  ),           
      .mem_rsp_in_data_i        (cluster_to_l2_arb_mem_rsp_in_data[(j+1)*`DATA_BITS-1-:`DATA_BITS]                           ),         
      .mem_rsp_in_param_i       (cluster_to_l2_arb_mem_rsp_in_param[(j+1)*`PARAM_BITS-1-:`PARAM_BITS]                        ),             
      .mem_rsp_vec_out_valid_o  (mem_rsp_vec_in_valid[(j+1)*`NUM_CLUSTER-1-:`NUM_CLUSTER]                                    ),       
      .mem_rsp_vec_out_ready_i  (mem_rsp_vec_in_ready[(j+1)*`NUM_CLUSTER-1-:`NUM_CLUSTER]                                    ),           
      .mem_rsp_vec_out_opcode_o (mem_rsp_vec_in_opcode[(j+1)*`NUM_CLUSTER*`OP_BITS-1-:(`NUM_CLUSTER*`OP_BITS)]               ),   
      .mem_rsp_vec_out_size_o   (mem_rsp_vec_in_size[(j+1)*`NUM_CLUSTER*`SIZE_BITS-1-:(`NUM_CLUSTER*`SIZE_BITS)]             ),       
      .mem_rsp_vec_out_source_o (mem_rsp_vec_in_source[(j+1)*`NUM_CLUSTER*`CLUSTER_SOURCE-1-:(`NUM_CLUSTER*`CLUSTER_SOURCE)] ),               
      .mem_rsp_vec_out_address_o(mem_rsp_vec_in_address[(j+1)*`NUM_CLUSTER*`ADDRESS_BITS-1-:(`NUM_CLUSTER*`ADDRESS_BITS)]    ),                 
      .mem_rsp_vec_out_data_o   (mem_rsp_vec_in_data[(j+1)*`NUM_CLUSTER*`DATA_BITS-1-:(`NUM_CLUSTER*`DATA_BITS)]             ),           
      .mem_rsp_vec_out_param_o  (mem_rsp_vec_in_param[(j+1)*`NUM_CLUSTER*`PARAM_BITS-1-:(`NUM_CLUSTER*`PARAM_BITS)]          ) 
      );

  end
  endgenerate

  genvar k;
  generate for(k=0;k<`NUM_CLUSTER;k=k+1) begin : C1
    sm2cluster_arb sm2clusterArb (
      .clk                       (clk                                                                                                                             ),     
      .rst_n                     (rst_n                                                                                                                           ),     
      .mem_req_vec_in_ready_o    (mem_req_ready[(k+1)*`NUM_SM_IN_CLUSTER-1-:`NUM_SM_IN_CLUSTER]                                                                   ),       
      .mem_req_vec_in_valid_i    (mem_req_valid[(k+1)*`NUM_SM_IN_CLUSTER-1-:`NUM_SM_IN_CLUSTER]                                                                   ),   
      .mem_req_vec_in_a_opcode_i (mem_req_a_opcode[(k+1)*`NUM_SM_IN_CLUSTER*3-1-:(`NUM_SM_IN_CLUSTER*3)]                                                          ),     
      .mem_req_vec_in_a_param_i  (mem_req_a_param[(k+1)*`NUM_SM_IN_CLUSTER*3-1-:(`NUM_SM_IN_CLUSTER*3)]                                                           ),         
      .mem_req_vec_in_a_addr_i   (mem_req_a_addr[(k+1)*`NUM_SM_IN_CLUSTER*`XLEN-1-:(`NUM_SM_IN_CLUSTER*`XLEN)]                                                    ),     
      .mem_req_vec_in_a_data_i   (mem_req_a_data[(k+1)*`NUM_SM_IN_CLUSTER*`DCACHE_BLOCKWORDS*`XLEN-1-:(`NUM_SM_IN_CLUSTER*`DCACHE_BLOCKWORDS*`XLEN)]              ),         
      .mem_req_vec_in_a_mask_i   (mem_req_a_mask[(k+1)*`NUM_SM_IN_CLUSTER*`DCACHE_BLOCKWORDS*`BYTESOFWORD-1-:(`NUM_SM_IN_CLUSTER*`DCACHE_BLOCKWORDS*`BYTESOFWORD)]),       
      .mem_req_vec_in_a_source_i (mem_req_a_source[(k+1)*`NUM_SM_IN_CLUSTER*`D_SOURCE-1-:(`NUM_SM_IN_CLUSTER*`D_SOURCE)]                                          ),   
      .mem_req_out_ready_i       (mem_req_out_ready[k]                                                                                                            ),         
      .mem_req_out_valid_o       (mem_req_out_valid[k]                                                                                                            ),     
      .mem_req_out_opcode_o      (mem_req_out_opcode[(k+1)*`OP_BITS-1-:`OP_BITS]                                                                                  ),     
      .mem_req_out_size_o        (mem_req_out_size[(k+1)*`SIZE_BITS-1-:`SIZE_BITS]                                                                                ),           
      .mem_req_out_source_o      (mem_req_out_source[(k+1)*`CLUSTER_SOURCE-1-:`CLUSTER_SOURCE]                                                                    ),   
      .mem_req_out_address_o     (mem_req_out_address[(k+1)*`ADDRESS_BITS-1-:`ADDRESS_BITS]                                                                       ),   
      .mem_req_out_mask_o        (mem_req_out_mask[(k+1)*`MASK_BITS-1-:`MASK_BITS]                                                                                ),     
      .mem_req_out_data_o        (mem_req_out_data[(k+1)*`DATA_BITS-1-:`DATA_BITS]                                                                                ),       
      .mem_req_out_param_o       (mem_req_out_param[(k+1)*3-1-:3]                                                                                                 ),       
      .mem_rsp_in_ready_o        (mem_rsp_in_ready[k]                                                                                                             ),       
      .mem_rsp_in_valid_i        (mem_rsp_in_valid[k]                                                                                                             ),     
      .mem_rsp_in_opcode_i       (mem_rsp_in_opcode[(k+1)*`OP_BITS-1-:`OP_BITS]                                                                                   ),       
      .mem_rsp_in_size_i         (mem_rsp_in_size[(k+1)*`SIZE_BITS-1-:`SIZE_BITS]                                                                                 ), 
      .mem_rsp_in_source_i       (mem_rsp_in_source[(k+1)*`CLUSTER_SOURCE-1-:`CLUSTER_SOURCE]                                                                     ),     
      .mem_rsp_in_data_i         (mem_rsp_in_data[(k+1)*`DATA_BITS-1-:`DATA_BITS]                                                                                 ),     
      .mem_rsp_in_param_i        (mem_rsp_in_param[(k+1)*3-1-:3]                                                                                                  ),   
      .mem_rsp_in_address_i      (mem_rsp_in_address[(k+1)*`ADDRESS_BITS-1-:`ADDRESS_BITS]                                                                        ),   
      .mem_rsp_vec_out_ready_i   (mem_rsp_ready[(k+1)*`NUM_SM_IN_CLUSTER-1-:`NUM_SM_IN_CLUSTER]                                                                   ),         
      .mem_rsp_vec_out_valid_o   (mem_rsp_valid[(k+1)*`NUM_SM_IN_CLUSTER-1-:`NUM_SM_IN_CLUSTER]                                                                   ),     
      .mem_rsp_vec_out_d_opcode_o(mem_rsp_d_opcpde[(k+1)*`NUM_SM_IN_CLUSTER*3-1-:(`NUM_SM_IN_CLUSTER*3)]                                                          ),         
      .mem_rsp_vec_out_d_addr_o  (mem_rsp_d_addr[(k+1)*`NUM_SM_IN_CLUSTER*`WORDLENGTH-1-:(`NUM_SM_IN_CLUSTER*`WORDLENGTH)]                                        ),   
      .mem_rsp_vec_out_d_data_o  (mem_rsp_d_data[(k+1)*`NUM_SM_IN_CLUSTER*`DCACHE_BLOCKWORDS*`WORDLENGTH-1-:(`NUM_SM_IN_CLUSTER*`DCACHE_BLOCKWORDS*`WORDLENGTH)]  ), 
      .mem_rsp_vec_out_d_source_o(mem_rsp_d_source[(k+1)*`NUM_SM_IN_CLUSTER*`D_SOURCE-1-:(`NUM_SM_IN_CLUSTER*`D_SOURCE)]                                          )   
      );

    l2_distribute l2distribute(
      .mem_req_in_valid_i       (mem_req_out_valid[k]                                                                        ),   
      .mem_req_in_ready_o       (mem_req_out_ready[k]                                                                        ),     
      .mem_req_in_opcode_i      (mem_req_out_opcode[(k+1)*`OP_BITS-1-:`OP_BITS]                                              ),       
      .mem_req_in_size_i        (mem_req_out_size[(k+1)*`SIZE_BITS-1-:`SIZE_BITS]                                            ),       
      .mem_req_in_source_i      (mem_req_out_source[(k+1)*`CLUSTER_SOURCE-1-:`CLUSTER_SOURCE]                                ),         
      .mem_req_in_address_i     (mem_req_out_address[(k+1)*`ADDRESS_BITS-1-:`ADDRESS_BITS]                                   ),       
      .mem_req_in_mask_i        (mem_req_out_mask[(k+1)*`MASK_BITS-1-:`MASK_BITS]                                            ),         
      .mem_req_in_data_i        (mem_req_out_data[(k+1)*`DATA_BITS-1-:`DATA_BITS]                                            ),           
      .mem_req_in_param_i       (mem_req_out_param[(k+1)*3-1-:3]                                                             ),             
      .mem_req_vec_out_valid_o  (mem_req_vec_out_valid[(k+1)*`NUM_L2CACHE-1-:`NUM_L2CACHE]                                   ),            
      .mem_req_vec_out_ready_i  (mem_req_vec_out_ready[(k+1)*`NUM_L2CACHE-1-:`NUM_L2CACHE]                                   ),         
      .mem_req_vec_out_opcode_o (mem_req_vec_out_opcode[(k+1)*`NUM_L2CACHE*`OP_BITS-1-:(`NUM_L2CACHE*`OP_BITS)]              ),               
      .mem_req_vec_out_size_o   (mem_req_vec_out_size[(k+1)*`NUM_L2CACHE*`SIZE_BITS-1-:(`NUM_L2CACHE*`SIZE_BITS)]            ),               
      .mem_req_vec_out_source_o (mem_req_vec_out_source[(k+1)*`NUM_L2CACHE*`CLUSTER_SOURCE-1-:(`NUM_L2CACHE*`CLUSTER_SOURCE)]),                 
      .mem_req_vec_out_address_o(mem_req_vec_out_address[(k+1)*`NUM_L2CACHE*`ADDRESS_BITS-1-:(`NUM_L2CACHE*`ADDRESS_BITS)]   ),             
      .mem_req_vec_out_mask_o   (mem_req_vec_out_mask[(k+1)*`NUM_L2CACHE*`MASK_BITS-1-:(`NUM_L2CACHE*`MASK_BITS)]            ),             
      .mem_req_vec_out_data_o   (mem_req_vec_out_data[(k+1)*`NUM_L2CACHE*`DATA_BITS-1-:(`NUM_L2CACHE*`DATA_BITS)]            ),           
      .mem_req_vec_out_param_o  (mem_req_vec_out_param[(k+1)*`NUM_L2CACHE*3-1-:(`NUM_L2CACHE*3)]                             ),       
      .mem_rsp_vec_in_valid_i   (mem_rsp_vec_in_valid[(k+1)*`NUM_L2CACHE-1-:`NUM_L2CACHE]                                    ),   
      .mem_rsp_vec_in_ready_o   (mem_rsp_vec_in_ready[(k+1)*`NUM_L2CACHE-1-:`NUM_L2CACHE]                                    ),       
      .mem_rsp_vec_in_address_i (mem_rsp_vec_in_address[(k+1)*`NUM_L2CACHE*`ADDRESS_BITS-1-:(`NUM_L2CACHE*`ADDRESS_BITS)]    ),     
      .mem_rsp_vec_in_opcode_i  (mem_rsp_vec_in_opcode[(k+1)*`NUM_L2CACHE*`OP_BITS-1-:(`NUM_L2CACHE*`OP_BITS)]               ),       
      .mem_rsp_vec_in_size_i    (mem_rsp_vec_in_size[(k+1)*`NUM_L2CACHE*`SIZE_BITS-1-:(`NUM_L2CACHE*`SIZE_BITS)]             ),       
      .mem_rsp_vec_in_source_i  (mem_rsp_vec_in_source[(k+1)*`NUM_L2CACHE*`CLUSTER_SOURCE-1-:(`NUM_L2CACHE*`CLUSTER_SOURCE)] ),           
      .mem_rsp_vec_in_data_i    (mem_rsp_vec_in_data[(k+1)*`NUM_L2CACHE*`DATA_BITS-1-:(`NUM_L2CACHE*`DATA_BITS)]             ),         
      .mem_rsp_vec_in_param_i   (mem_rsp_vec_in_param[(k+1)*`NUM_L2CACHE*3-1-:(`NUM_L2CACHE*3)]                              ),   
      .mem_rsp_out_valid_o      (mem_rsp_in_valid[k]                                                                         ),     
      .mem_rsp_out_ready_i      (mem_rsp_in_ready[k]                                                                         ),   
      .mem_rsp_out_address_o    (mem_rsp_in_address[(k+1)*`ADDRESS_BITS-1-:`ADDRESS_BITS]                                    ),   
      .mem_rsp_out_opcode_o     (mem_rsp_in_opcode[(k+1)*`OP_BITS-1-:`OP_BITS]                                               ),   
      .mem_rsp_out_size_o       (mem_rsp_in_size[(k+1)*`SIZE_BITS-1-:`SIZE_BITS]                                             ),     
      .mem_rsp_out_source_o     (mem_rsp_in_source[(k+1)*`CLUSTER_SOURCE-1-:`CLUSTER_SOURCE]                                 ), 
      .mem_rsp_out_data_o       (mem_rsp_in_data[(k+1)*`DATA_BITS-1-:`DATA_BITS]                                             ),   
      .mem_rsp_out_param_o      (mem_rsp_in_param[(k+1)*3-1-:3]                                                              ) 
      );

  end
  endgenerate


  //connect l2_out and gpu_out
  assign out_a_valid_o        = l2cache_out_a_valid  ;
  assign out_a_opcode_o       = l2cache_out_a_opcode ;
  assign out_a_size_o         = l2cache_out_a_size   ;
  assign out_a_source_o       = l2cache_out_a_source ;
  assign out_a_address_o      = l2cache_out_a_address;
  assign out_a_mask_o         = l2cache_out_a_mask   ;
  assign out_a_data_o         = l2cache_out_a_data   ;
  assign out_a_param_o        = l2cache_out_a_param  ;

  assign l2cache_out_a_ready  = out_a_ready_i        ;

  assign l2cache_out_d_valid  = out_d_valid_i        ;
  assign l2cache_out_d_opcode = out_d_opcode_i       ;
  assign l2cache_out_d_size   = out_d_size_i         ;
  assign l2cache_out_d_source = out_d_source_i       ;
  assign l2cache_out_d_data   = out_d_data_i         ;
  assign l2cache_out_d_param  = out_d_param_i        ;

  assign out_d_ready_o        = l2cache_out_d_ready  ;

`endif

`ifdef NO_CACHE
   /*assign out_a_valid_o   = mem_req_valid[1];
   assign out_a_opcode_o  = mem_req_a_opcode[2*`OP_BITS-1:`OP_BITS];
   assign out_a_iswrite_o = mem_req_a_iswrite[1];
   assign out_a_size_o    = 0;
   assign out_a_source_o  = mem_req_a_source[2*`D_SOURCE-1:`D_SOURCE];
   assign out_a_address_o = mem_req_a_addr[2*`ADDRESS_BITS-1:`ADDRESS_BITS];
   assign out_a_mask_o    = mem_req_a_mask[2*`MASK_BITS-1:`MASK_BITS];
   assign out_a_data_o    = mem_req_a_data[2*`DATA_BITS-1:`DATA_BITS];
   assign out_a_param_o   = mem_req_a_param[2*`PARAM_BITS-1:`PARAM_BITS];
   assign out_a_instrid_o = mem_req_a_instrid[1];

   assign mem_req_ready[1] = out_a_ready_i;

   assign mem_rsp_valid[1]                                = out_d_valid_i;
   assign mem_rsp_d_opcpde[2*`OP_BITS-1:`OP_BITS]         = out_d_opcode_i;
   assign mem_rsp_d_source[2*`D_SOURCE-1:`D_SOURCE]       = out_d_source_i;
   assign mem_rsp_d_data[2*`DATA_BITS-1:`DATA_BITS]       = out_d_data_i;
   assign mem_rsp_d_addr[2*`XLEN-1:`XLEN]                 = out_d_address_i;
   assign mem_rsp_d_instrid[1]                            = out_d_instrid_i;
   assign mem_rsp_d_mask[2*`MASK_BITS-1:`MASK_BITS]       = out_d_mask_i;
   //assign mem_rsp_d_param[2*`PARAM_BITS-1:`PARAM_BITS]    = out_d_param_i;

   assign out_d_ready_o = mem_rsp_ready[1];*/
  
  assign icache_mem_rsp_valid[1]                                                    = icache_mem_rsp_valid_i                                            ;       
  assign icache_mem_rsp_ready_o                                                     = icache_mem_rsp_ready[1]                                           ;     
  assign icache_mem_rsp_addr[2*`XLEN-1:`XLEN]                                       = icache_mem_rsp_addr_i                                             ;
  assign icache_mem_rsp_data[2*`DCACHE_BLOCKWORDS*`XLEN-1:`DCACHE_BLOCKWORDS*`XLEN] = icache_mem_rsp_data_i                                             ;        
  assign icache_mem_rsp_source[2*`D_SOURCE-1:`D_SOURCE]                             = icache_mem_rsp_source_i                                           ;     
                               
  assign icache_mem_req_valid_o                                                     = icache_mem_req_valid[1]                                           ;       
  assign icache_mem_req_ready[1]                                                    = icache_mem_req_ready_i                                            ;         
  assign icache_mem_req_addr_o                                                      = icache_mem_req_addr[2*`XLEN-1:`XLEN]                              ;
  assign icache_mem_req_source_o                                                    = icache_mem_req_source[2*`D_SOURCE-1:`D_SOURCE]                    ; 
                               
  assign dcache_mem_rsp_valid[1]                                                    = dcache_mem_rsp_valid_i                                            ;       
  assign dcache_mem_rsp_ready_o                                                     = dcache_mem_rsp_ready[1]                                           ;      
  assign dcache_mem_rsp_instrid[2*`WIDBITS-1:`WIDBITS]                              = dcache_mem_rsp_instrid_i                                          ;     
  assign dcache_mem_rsp_data[2*`DCACHE_NLANES*`XLEN-1:`DCACHE_NLANES*`XLEN]         = dcache_mem_rsp_data_i                                             ;        
  assign dcache_mem_rsp_activemask[2*`DCACHE_NLANES-1:`DCACHE_NLANES]               = dcache_mem_rsp_activemask_i                                       ;  
                               
  assign dcache_mem_req_valid_o                                                     = dcache_mem_req_valid[1]                                           ;
  assign dcache_mem_req_ready[1]                                                    = dcache_mem_req_ready_i                                            ; 
  assign dcache_mem_req_instrid_o                                                   = dcache_mem_req_instrid[2*`WIDBITS-1:`WIDBITS]                     ;
  assign dcache_mem_req_setidx_o                                                    = dcache_mem_req_setidx[2*`DCACHE_SETIDXBITS-1:`DCACHE_SETIDXBITS]  ;
  assign dcache_mem_req_tag_o                                                       = dcache_mem_req_tag[2*`DCACHE_TAGBITS-1:`DCACHE_TAGBITS]           ;
  assign dcache_mem_req_activemask_o                                                = dcache_mem_req_activemask[2*`DCACHE_NLANES-1:`DCACHE_NLANES]      ;
  assign dcache_mem_req_blockoffset_o                                               = dcache_mem_req_blockoffset[2*`DCACHE_NLANES*`DCACHE_BLOCKOFFSETBITS-1:`DCACHE_NLANES*`DCACHE_BLOCKOFFSETBITS];
  assign dcache_mem_req_wordoffset1h_o                                              = dcache_mem_req_wordoffset1h[2*`DCACHE_NLANES*`BYTESOFWORD-1:`DCACHE_NLANES*`BYTESOFWORD];
  assign dcache_mem_req_data_o                                                      = dcache_mem_req_data[2*`DCACHE_NLANES*`XLEN-1:`DCACHE_NLANES*`XLEN];
  assign dcache_mem_req_opcode_o                                                    = dcache_mem_req_opcode[5:3]                                        ;
  assign dcache_mem_req_param_o                                                     = dcache_mem_req_param[7:4]                                         ;

`endif

endmodule


      

