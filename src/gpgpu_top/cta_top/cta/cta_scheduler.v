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
// Description:cta模块顶层

`timescale 1ns/1ns
`include "define.v"

module cta_scheduler(
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
  //SM inputs
  input   [`NUMBER_CU-1:0]              cu2dispatch_wf_done_i                     ,
  input   [`TAG_WIDTH*`NUMBER_CU-1:0]   cu2dispatch_wf_tag_done_i                 ,
  input   [`NUMBER_CU-1:0]              cu2dispatch_ready_for_dispatch_i          ,
  //outputs to the host
  output                                inflight_wg_buffer_host_rcvd_ack_o        ,
  output                                inflight_wg_buffer_host_wf_done_o         ,
  output  [`WG_ID_WIDTH-1:0]            inflight_wg_buffer_host_wf_done_wg_id_o   ,
  //outputs to the SM
  output  [`NUMBER_CU-1:0]              dispatch2cu_wf_dispatch_o                 ,
  output  [`WF_COUNT_WIDTH_PER_WG-1:0]  dispatch2cu_wg_wf_count_o                 ,
  output  [`WAVE_ITEM_WIDTH-1:0]        dispatch2cu_wf_size_dispatch_o            ,
  output  [`SGPR_ID_WIDTH:0]            dispatch2cu_sgpr_base_dispatch_o          ,
  output  [`VGPR_ID_WIDTH:0]            dispatch2cu_vgpr_base_dispatch_o          ,
  output  [`TAG_WIDTH-1:0]              dispatch2cu_wf_tag_dispatch_o             ,
  output  [`LDS_ID_WIDTH:0]             dispatch2cu_lds_base_dispatch_o           ,
  output  [`MEM_ADDR_WIDTH-1:0]         dispatch2cu_start_pc_dispatch_o           ,
  output  [`WG_SIZE_X_WIDTH*3-1:0]      dispatch2cu_kernel_size_3d_dispatch_o     ,
  output  [`MEM_ADDR_WIDTH-1:0]         dispatch2cu_pds_baseaddr_dispatch_o       ,
  output  [`MEM_ADDR_WIDTH-1:0]         dispatch2cu_csr_knl_dispatch_o            ,
  output  [`MEM_ADDR_WIDTH-1:0]         dispatch2cu_gds_base_dispatch_o           
  );

  //wire to connect all sub-modules
  wire                                  dis_controller_wg_alloc_valid          ;
  wire                                  dis_controller_start_alloc             ;
  wire                                  dis_controller_alloc_ack               ;
  wire                                  dis_controller_wg_dealloc_valid        ;
  wire                                  dis_controller_wg_rejected_valid       ;
  wire  [`NUMBER_CU-1:0]                dis_controller_cu_busy                 ;

  wire  [`WG_ID_WIDTH-1:0]              allocator_wg_id_out                    ;
  wire  [`WG_ID_WIDTH-1:0]              gpu_interface_dealloc_wg_id            ;

  wire                                  inflight_wg_buffer_alloc_valid         ;
  wire                                  inflight_wg_buffer_alloc_available     ;
  wire  [`WG_ID_WIDTH-1:0]              inflight_wg_buffer_alloc_wg_id         ;
  wire  [`WF_COUNT_WIDTH_PER_WG-1:0]    inflight_wg_buffer_alloc_num_wf        ;
  wire  [`VGPR_ID_WIDTH:0]              inflight_wg_buffer_alloc_vgpr_size     ;
  wire  [`SGPR_ID_WIDTH:0]              inflight_wg_buffer_alloc_sgpr_size     ;
  wire  [`LDS_ID_WIDTH:0]               inflight_wg_buffer_alloc_lds_size      ;
  wire  [`GDS_ID_WIDTH:0]               inflight_wg_buffer_alloc_gds_size      ;
  wire                                  inflight_wg_buffer_gpu_valid           ;
  wire  [`VGPR_ID_WIDTH:0]              inflight_wg_buffer_gpu_vgpr_size_per_wf;
  wire  [`SGPR_ID_WIDTH:0]              inflight_wg_buffer_gpu_sgpr_size_per_wf;
  wire  [`WAVE_ITEM_WIDTH-1:0]          inflight_wg_buffer_gpu_wf_size         ;
  wire  [`MEM_ADDR_WIDTH-1:0]           inflight_wg_buffer_start_pc            ;
  wire  [`WG_SIZE_X_WIDTH*3-1:0]        inflight_wg_buffer_kernel_size_3d      ;
  wire  [`MEM_ADDR_WIDTH-1:0]           inflight_wg_buffer_pds_baseaddr        ;
  wire  [`MEM_ADDR_WIDTH-1:0]           inflight_wg_buffer_csr_knl             ;
  wire  [`MEM_ADDR_WIDTH-1:0]           inflight_wg_buffer_gds_base_dispatch   ;

  wire  [`CU_ID_WIDTH-1:0]              allocator_cu_id_out                    ;
  wire  [`WF_COUNT_WIDTH_PER_WG-1:0]    allocator_wf_count                     ;
  wire  [`VGPR_ID_WIDTH-1:0]            allocator_vgpr_start_out               ;
  wire  [`SGPR_ID_WIDTH-1:0]            allocator_sgpr_start_out               ;
  wire  [`LDS_ID_WIDTH-1:0]             allocator_lds_start_out                ;

  wire                                  gpu_interface_alloc_available          ;
  wire                                  gpu_interface_dealloc_available        ;
  wire  [`CU_ID_WIDTH-1:0]              gpu_interface_cu_id                    ;

  wire                                  grt_cam_up_valid                       ;       
  wire  [`CU_ID_WIDTH-1:0]              grt_cam_up_cu_id                       ;
  wire  [`VGPR_ID_WIDTH-1:0]            grt_cam_up_vgpr_strt                   ;
  wire  [`VGPR_ID_WIDTH:0]              grt_cam_up_vgpr_size                   ;
  wire  [`SGPR_ID_WIDTH-1:0]            grt_cam_up_sgpr_strt                   ;
  wire  [`SGPR_ID_WIDTH:0]              grt_cam_up_sgpr_size                   ;
  wire  [`LDS_ID_WIDTH-1:0]             grt_cam_up_lds_strt                    ;
  wire  [`LDS_ID_WIDTH:0]               grt_cam_up_lds_size                    ;
  wire  [`WF_COUNT_WIDTH-1:0]           grt_cam_up_wf_count                    ;
  wire  [`WG_SLOT_ID_WIDTH:0]           grt_cam_up_wg_count                    ;

  wire                                  grt_wg_alloc_done                      ; 
  wire  [`WG_ID_WIDTH-1:0]              grt_wg_alloc_wg_id                     ; 
  wire  [`CU_ID_WIDTH-1:0]              grt_wg_alloc_cu_id                     ; 
  wire                                  grt_wg_dealloc_done                    ; 
  wire  [`WG_ID_WIDTH-1:0]              grt_wg_dealloc_wg_id                   ; 
  wire  [`CU_ID_WIDTH-1:0]              grt_wg_dealloc_cu_id                   ; 

  wire  [`VGPR_ID_WIDTH:0]              allocator_vgpr_size_out                ;
  wire  [`SGPR_ID_WIDTH:0]              allocator_sgpr_size_out                ;
  wire  [`LDS_ID_WIDTH:0]               allocator_lds_size_out                 ;
  wire                                  allocator_cu_valid                     ;
  wire                                  allocator_cu_rejected                  ;

  allocator_neo U_allocator_neo (
    .clk                                 (clk                               ),        
    .rst_n                               (rst_n                             ),          
                                            
    .inflight_wg_buffer_alloc_wg_id_i    (inflight_wg_buffer_alloc_wg_id    ),          
    .inflight_wg_buffer_alloc_num_wf_i   (inflight_wg_buffer_alloc_num_wf   ),            
    .inflight_wg_buffer_alloc_vgpr_size_i(inflight_wg_buffer_alloc_vgpr_size),        
    .inflight_wg_buffer_alloc_sgpr_size_i(inflight_wg_buffer_alloc_sgpr_size),            
    .inflight_wg_buffer_alloc_lds_size_i (inflight_wg_buffer_alloc_lds_size ),        
                                        
    .dis_controller_cu_busy_i            (dis_controller_cu_busy            ),        
    .dis_controller_alloc_ack_i          (dis_controller_alloc_ack          ),            
    .dis_controller_start_alloc_i        (dis_controller_start_alloc        ),            
                                        
    .grt_cam_up_valid_i                  (grt_cam_up_valid                  ),        
    .grt_cam_up_cu_id_i                  (grt_cam_up_cu_id                  ),          
    .grt_cam_up_vgpr_strt_i              (grt_cam_up_vgpr_strt              ),          
    .grt_cam_up_vgpr_size_i              (grt_cam_up_vgpr_size              ),          
    .grt_cam_up_sgpr_strt_i              (grt_cam_up_sgpr_strt              ),          
    .grt_cam_up_sgpr_size_i              (grt_cam_up_sgpr_size              ),          
    .grt_cam_up_lds_strt_i               (grt_cam_up_lds_strt               ),            
    .grt_cam_up_lds_size_i               (grt_cam_up_lds_size               ),            
    .grt_cam_up_wf_count_i               (grt_cam_up_wf_count               ),            
    .grt_cam_up_wg_count_i               (grt_cam_up_wg_count               ),          
                                        
    .allocator_cu_valid_o                (allocator_cu_valid                ),            
    .allocator_cu_rejected_o             (allocator_cu_rejected             ),              
    .allocator_wg_id_out_o               (allocator_wg_id_out               ),          
    .allocator_cu_id_out_o               (allocator_cu_id_out               ),      
    .allocator_wf_count_o                (allocator_wf_count                ),          
    .allocator_vgpr_size_out_o           (allocator_vgpr_size_out           ),              
    .allocator_sgpr_size_out_o           (allocator_sgpr_size_out           ),            
    .allocator_lds_size_out_o            (allocator_lds_size_out            ),            
    .allocator_vgpr_start_out_o          (allocator_vgpr_start_out          ),              
    .allocator_sgpr_start_out_o          (allocator_sgpr_start_out          ),              
    .allocator_lds_start_out_o           (allocator_lds_start_out           )    
    );

  top_resource_table U_top_resource_table (
    .clk                              (clk                            ),            
    .rst_n                            (rst_n                          ),        
    .allocator_wg_id_out_i            (allocator_wg_id_out            ),          
    .allocator_wf_count_i             (allocator_wf_count             ),            
    .allocator_cu_id_out_i            (allocator_cu_id_out            ),                
    .allocator_vgpr_start_out_i       (allocator_vgpr_start_out       ),                  
    .allocator_vgpr_size_out_i        (allocator_vgpr_size_out        ),                  
    .allocator_sgpr_start_out_i       (allocator_sgpr_start_out       ),                  
    .allocator_sgpr_size_out_i        (allocator_sgpr_size_out        ),                
    .allocator_lds_start_out_i        (allocator_lds_start_out        ),                
    .allocator_lds_size_out_i         (allocator_lds_size_out         ),              
    .dis_controller_wg_alloc_valid_i  (dis_controller_wg_alloc_valid  ),                
    .dis_controller_wg_dealloc_valid_i(dis_controller_wg_dealloc_valid),              
    .gpu_interface_cu_id_i            (gpu_interface_cu_id            ),          
    .gpu_interface_dealloc_wg_id_i    (gpu_interface_dealloc_wg_id    ),                    
                                     
    .grt_cam_up_valid_o               (grt_cam_up_valid               ),            
    .grt_cam_up_wf_count_o            (grt_cam_up_wf_count            ),            
    .grt_cam_up_cu_id_o               (grt_cam_up_cu_id               ),              
    .grt_cam_up_vgpr_strt_o           (grt_cam_up_vgpr_strt           ),                
    .grt_cam_up_vgpr_size_o           (grt_cam_up_vgpr_size           ),              
    .grt_cam_up_sgpr_strt_o           (grt_cam_up_sgpr_strt           ),        
    .grt_cam_up_sgpr_size_o           (grt_cam_up_sgpr_size           ),            
    .grt_cam_up_lds_strt_o            (grt_cam_up_lds_strt            ),            
    .grt_cam_up_lds_size_o            (grt_cam_up_lds_size            ),              
    .grt_cam_up_wg_count_o            (grt_cam_up_wg_count            ),            
    .grt_wg_alloc_done_o              (grt_wg_alloc_done              ),        
    .grt_wg_alloc_wg_id_o             (grt_wg_alloc_wg_id             ),      
    .grt_wg_alloc_cu_id_o             (grt_wg_alloc_cu_id             ),    
    .grt_wg_dealloc_done_o            (grt_wg_dealloc_done            ),          
    .grt_wg_dealloc_wg_id_o           (grt_wg_dealloc_wg_id           ),          
    .grt_wg_dealloc_cu_id_o           (grt_wg_dealloc_cu_id           )              
    );

  inflight_wg_buffer U_inflight_wg_buffer (
    .clk                                      (clk                                    ),          
    .rst_n                                    (rst_n                                  ),      
                                                    
    .host_wg_valid_i                          (host_wg_valid_i                        ),
    .host_wg_ready_o                          (host_wg_ready_o                        ),
    .host_wg_id_i                             (host_wg_id_i                           ),                    
    .host_num_wf_i                            (host_num_wf_i                          ),                
    .host_wf_size_i                           (host_wf_size_i                         ),              
    .host_start_pc_i                          (host_start_pc_i                        ),                
    .host_kernel_size_3d_i                    (host_kernel_size_3d_i                  ),                  
    .host_pds_baseaddr_i                      (host_pds_baseaddr_i                    ),                    
    .host_csr_knl_i                           (host_csr_knl_i                         ),                
    .host_gds_baseaddr_i                      (host_gds_baseaddr_i                    ),                
    .host_vgpr_size_total_i                   (host_vgpr_size_total_i                 ),                    
    .host_sgpr_size_total_i                   (host_sgpr_size_total_i                 ),                      
    .host_lds_size_total_i                    (host_lds_size_total_i                  ),                        
    .host_gds_size_total_i                    (host_gds_size_total_i                  ),                    
    .host_vgpr_size_per_wf_i                  (host_vgpr_size_per_wf_i                ),                
    .host_sgpr_size_per_wf_i                  (host_sgpr_size_per_wf_i                ),                    
                                                
    .dis_controller_wg_alloc_valid_i          (dis_controller_wg_alloc_valid          ),                        
    .dis_controller_start_alloc_i             (dis_controller_start_alloc             ),                        
    .dis_controller_wg_dealloc_valid_i        (dis_controller_wg_dealloc_valid        ),                            
    .dis_controller_wg_rejected_valid_i       (dis_controller_wg_rejected_valid       ),                      
                                              
    .allocator_wg_id_out_i                    (allocator_wg_id_out                    ),                    
    .gpu_interface_dealloc_wg_id_i            (gpu_interface_dealloc_wg_id            ),                      
                                              
    .inflight_wg_buffer_host_rcvd_ack_o       (inflight_wg_buffer_host_rcvd_ack_o     ),                        
    .inflight_wg_buffer_host_wf_done_o        (inflight_wg_buffer_host_wf_done_o      ),                  
    .inflight_wg_buffer_host_wf_done_wg_id_o  (inflight_wg_buffer_host_wf_done_wg_id_o),                        
                                              
    .inflight_wg_buffer_alloc_valid_o         (inflight_wg_buffer_alloc_valid         ),                  
    .inflight_wg_buffer_alloc_available_o     (inflight_wg_buffer_alloc_available     ),                
    .inflight_wg_buffer_alloc_wg_id_o         (inflight_wg_buffer_alloc_wg_id         ),              
    .inflight_wg_buffer_alloc_num_wf_o        (inflight_wg_buffer_alloc_num_wf        ),              
    .inflight_wg_buffer_alloc_vgpr_size_o     (inflight_wg_buffer_alloc_vgpr_size     ),                  
    .inflight_wg_buffer_alloc_sgpr_size_o     (inflight_wg_buffer_alloc_sgpr_size     ),                  
    .inflight_wg_buffer_alloc_lds_size_o      (inflight_wg_buffer_alloc_lds_size      ),                      
    .inflight_wg_buffer_alloc_gds_size_o      (inflight_wg_buffer_alloc_gds_size      ),                      
                                              
    .inflight_wg_buffer_gpu_valid_o           (inflight_wg_buffer_gpu_valid           ),                
    .inflight_wg_buffer_gpu_vgpr_size_per_wf_o(inflight_wg_buffer_gpu_vgpr_size_per_wf),                
    .inflight_wg_buffer_gpu_sgpr_size_per_wf_o(inflight_wg_buffer_gpu_sgpr_size_per_wf),                  
    .inflight_wg_buffer_gpu_wf_size_o         (inflight_wg_buffer_gpu_wf_size         ),            
    .inflight_wg_buffer_start_pc_o            (inflight_wg_buffer_start_pc            ),              
    .inflight_wg_buffer_kernel_size_3d_o      (inflight_wg_buffer_kernel_size_3d      ),                        
    .inflight_wg_buffer_pds_baseaddr_o        (inflight_wg_buffer_pds_baseaddr        ),                  
    .inflight_wg_buffer_csr_knl_o             (inflight_wg_buffer_csr_knl             ),                
    .inflight_wg_buffer_gds_baseaddr_o        (inflight_wg_buffer_gds_base_dispatch   )                
    );    

  gpu_interface U_gpu_interface (
    .clk                                      (clk                                    ),                
    .rst_n                                    (rst_n                                  ),            
                                              
    .inflight_wg_buffer_gpu_valid_i           (inflight_wg_buffer_gpu_valid           ),                    
    .inflight_wg_buffer_gpu_wf_size_i         (inflight_wg_buffer_gpu_wf_size         ),                  
    .inflight_wg_buffer_start_pc_i            (inflight_wg_buffer_start_pc            ),            
    .inflight_wg_buffer_kernel_size_3d_i      (inflight_wg_buffer_kernel_size_3d      ),                    
    .inflight_wg_buffer_pds_baseaddr_i        (inflight_wg_buffer_pds_baseaddr        ),              
    .inflight_wg_buffer_csr_knl_i             (inflight_wg_buffer_csr_knl             ),              
    .inflight_wg_buffer_gds_base_dispatch_i   (inflight_wg_buffer_gds_base_dispatch   ),            
    .inflight_wg_buffer_gpu_vgpr_size_per_wf_i(inflight_wg_buffer_gpu_vgpr_size_per_wf),          
    .inflight_wg_buffer_gpu_sgpr_size_per_wf_i(inflight_wg_buffer_gpu_sgpr_size_per_wf),                      
                                             
    .allocator_wg_id_out_i                    (allocator_wg_id_out                    ),          
    .allocator_cu_id_out_i                    (allocator_cu_id_out                    ),        
    .allocator_wf_count_i                     (allocator_wf_count                     ),          
    .allocator_vgpr_start_out_i               (allocator_vgpr_start_out               ),            
    .allocator_sgpr_start_out_i               (allocator_sgpr_start_out               ),        
    .allocator_lds_start_out_i                (allocator_lds_start_out                ),            
                                             
    .cu2dispatch_wf_done_i                    (cu2dispatch_wf_done_i                  ),          
    .cu2dispatch_wf_tag_done_i                (cu2dispatch_wf_tag_done_i              ),            
    .cu2dispatch_ready_for_dispatch_i         (cu2dispatch_ready_for_dispatch_i       ),                        
                                             
    .dis_controller_wg_alloc_valid_i          (dis_controller_wg_alloc_valid          ),        
    .dis_controller_wg_dealloc_valid_i        (dis_controller_wg_dealloc_valid        ),                  
                                             
    .gpu_interface_alloc_available_o          (gpu_interface_alloc_available          ),                
    .gpu_interface_dealloc_available_o        (gpu_interface_dealloc_available        ),                    
    .gpu_interface_cu_id_o                    (gpu_interface_cu_id                    ),              
    .gpu_interface_dealloc_wg_id_o            (gpu_interface_dealloc_wg_id            ),                        
                                             
    .dispatch2cu_wf_dispatch_o                (dispatch2cu_wf_dispatch_o              ),          
    .dispatch2cu_wg_wf_count_o                (dispatch2cu_wg_wf_count_o              ),        
    .dispatch2cu_wf_size_dispatch_o           (dispatch2cu_wf_size_dispatch_o         ),            
    .dispatch2cu_sgpr_base_dispatch_o         (dispatch2cu_sgpr_base_dispatch_o       ),                  
    .dispatch2cu_vgpr_base_dispatch_o         (dispatch2cu_vgpr_base_dispatch_o       ),              
    .dispatch2cu_wf_tag_dispatch_o            (dispatch2cu_wf_tag_dispatch_o          ),                  
    .dispatch2cu_lds_base_dispatch_o          (dispatch2cu_lds_base_dispatch_o        ),                    
    .dispatch2cu_start_pc_dispatch_o          (dispatch2cu_start_pc_dispatch_o        ),                    
    .dispatch2cu_kernel_size_3d_dispatch_o    (dispatch2cu_kernel_size_3d_dispatch_o  ),                        
    .dispatch2cu_pds_baseaddr_dispatch_o      (dispatch2cu_pds_baseaddr_dispatch_o    ),                            
    .dispatch2cu_csr_knl_dispatch_o           (dispatch2cu_csr_knl_dispatch_o         ),            
    .dispatch2cu_gds_base_dispatch_o          (dispatch2cu_gds_base_dispatch_o        )                
    );  

  dis_controller #(
    .NUMBER_CU           (`NUMBER_CU                ),
    .CU_ID_WIDTH         (`CU_ID_WIDTH              ),
    .RES_TABLE_ADDR_WIDTH(`RES_TABLE_ADDR_WIDTH     ),
    .NUMBER_RES_TABLE    (1 << `RES_TABLE_ADDR_WIDTH)
  )
  U_dis_controller (
    .clk                                 (clk                               ),      
    .rst_n                               (rst_n                             ),          
                                        
    .inflight_wg_buffer_alloc_valid_i    (inflight_wg_buffer_alloc_valid    ),              
    .inflight_wg_buffer_alloc_available_i(inflight_wg_buffer_alloc_available),                
    .allocator_cu_valid_i                (allocator_cu_valid                ),        
    .allocator_cu_rejected_i             (allocator_cu_rejected             ),          
    .allocator_cu_id_out_i               (allocator_cu_id_out               ),    
    .grt_wg_alloc_done_i                 (grt_wg_alloc_done                 ),            
    .grt_wg_dealloc_done_i               (grt_wg_dealloc_done               ),        
    .grt_wg_alloc_cu_id_i                (grt_wg_alloc_cu_id                ),      
    .grt_wg_dealloc_cu_id_i              (grt_wg_dealloc_cu_id              ),      
    .gpu_interface_alloc_available_i     (gpu_interface_alloc_available     ),          
    .gpu_interface_dealloc_available_i   (gpu_interface_dealloc_available   ),                
    .gpu_interface_cu_id_i               (gpu_interface_cu_id               ),          
                                        
    .dis_controller_start_alloc_o        (dis_controller_start_alloc        ),            
    .dis_controller_alloc_ack_o          (dis_controller_alloc_ack          ),              
    .dis_controller_wg_alloc_valid_o     (dis_controller_wg_alloc_valid     ),            
    .dis_controller_wg_dealloc_valid_o   (dis_controller_wg_dealloc_valid   ),                  
    .dis_controller_wg_rejected_valid_o  (dis_controller_wg_rejected_valid  ),                  
    .dis_controller_cu_busy_o            (dis_controller_cu_busy            )  
    );

endmodule


