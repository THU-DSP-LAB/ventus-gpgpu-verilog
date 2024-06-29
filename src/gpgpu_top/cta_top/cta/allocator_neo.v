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
// Description:存储对应SM的剩余资源信息并与该次wg所需要的资源进行对比
`timescale 1ns/1ns
`include "define.v"

module allocator_neo (
  input                                 clk                                 ,
  input                                 rst_n                               ,

  input   [`WG_ID_WIDTH-1:0]            inflight_wg_buffer_alloc_wg_id_i    ,
  input   [`WF_COUNT_WIDTH_PER_WG-1:0]  inflight_wg_buffer_alloc_num_wf_i   ,
  input   [`VGPR_ID_WIDTH:0]            inflight_wg_buffer_alloc_vgpr_size_i,
  input   [`SGPR_ID_WIDTH:0]            inflight_wg_buffer_alloc_sgpr_size_i,
  input   [`LDS_ID_WIDTH:0]             inflight_wg_buffer_alloc_lds_size_i ,

  input   [`NUMBER_CU-1:0]              dis_controller_cu_busy_i            ,
  input                                 dis_controller_alloc_ack_i          ,
  input                                 dis_controller_start_alloc_i        ,

  input                                 grt_cam_up_valid_i                  ,
  input   [`CU_ID_WIDTH-1:0]            grt_cam_up_cu_id_i                  ,
  input   [`VGPR_ID_WIDTH-1:0]          grt_cam_up_vgpr_strt_i              ,
  input   [`VGPR_ID_WIDTH:0]            grt_cam_up_vgpr_size_i              ,
  input   [`SGPR_ID_WIDTH-1:0]          grt_cam_up_sgpr_strt_i              ,
  input   [`SGPR_ID_WIDTH:0]            grt_cam_up_sgpr_size_i              ,
  input   [`LDS_ID_WIDTH-1:0]           grt_cam_up_lds_strt_i               ,
  input   [`LDS_ID_WIDTH:0]             grt_cam_up_lds_size_i               ,
  input   [`WF_COUNT_WIDTH-1:0]         grt_cam_up_wf_count_i               ,
  input   [`WG_SLOT_ID_WIDTH:0]         grt_cam_up_wg_count_i               ,

  output                                allocator_cu_valid_o                ,
  output                                allocator_cu_rejected_o             ,
  output  [`WG_ID_WIDTH-1:0]            allocator_wg_id_out_o               ,
  output  [`CU_ID_WIDTH-1:0]            allocator_cu_id_out_o               ,
  output  [`WF_COUNT_WIDTH_PER_WG-1:0]  allocator_wf_count_o                ,
  output  [`VGPR_ID_WIDTH:0]            allocator_vgpr_size_out_o           ,
  output  [`SGPR_ID_WIDTH:0]            allocator_sgpr_size_out_o           ,
  output  [`LDS_ID_WIDTH:0]             allocator_lds_size_out_o            ,
  output  [`VGPR_ID_WIDTH-1:0]          allocator_vgpr_start_out_o          ,
  output  [`SGPR_ID_WIDTH-1:0]          allocator_sgpr_start_out_o          ,
  output  [`LDS_ID_WIDTH-1:0]           allocator_lds_start_out_o           
  );

  localparam  RES_SIZE_VGPR_START = 0                                       ;
  localparam  RES_SIZE_VGPR_END   = RES_SIZE_VGPR_START + `VGPR_ID_WIDTH - 1;
  localparam  RES_SIZE_SGPR_START = RES_SIZE_VGPR_END + 1                   ;
  localparam  RES_SIZE_SGPR_END   = RES_SIZE_SGPR_START + `SGPR_ID_WIDTH - 1;
  localparam  RES_SIZE_LDS_START  = RES_SIZE_SGPR_END + 1                   ;
  localparam  RES_SIZE_LDS_END    = RES_SIZE_LDS_START + `LDS_ID_WIDTH - 1  ;

  //input reg
  reg                                   alloc_valid_reg                ;
  reg   [`WG_ID_WIDTH-1:0]              alloc_wg_id_reg                ;
  reg   [`WF_COUNT_WIDTH_PER_WG-1:0]    alloc_num_wf_reg               ;
  reg   [`VGPR_ID_WIDTH:0]              alloc_vgpr_size_reg            ;
  reg   [`SGPR_ID_WIDTH:0]              alloc_sgpr_size_reg            ;
  reg   [`LDS_ID_WIDTH:0]               alloc_lds_size_reg             ;
  reg   [`NUMBER_CU-1:0]                dis_controller_cu_busy_reg     ;

  reg                                   cam_up_valid_reg               ;              
  reg   [`CU_ID_WIDTH-1:0]              cam_up_cu_id_reg               ;              
  reg   [`VGPR_ID_WIDTH-1:0]            cam_up_vgpr_strt_reg           ;              
  reg   [`VGPR_ID_WIDTH:0]              cam_up_vgpr_size_reg           ;              
  reg   [`SGPR_ID_WIDTH-1:0]            cam_up_sgpr_strt_reg           ;              
  reg   [`SGPR_ID_WIDTH:0]              cam_up_sgpr_size_reg           ;              
  reg   [`LDS_ID_WIDTH-1:0]             cam_up_lds_strt_reg            ;              
  reg   [`LDS_ID_WIDTH:0]               cam_up_lds_size_reg            ;              
  reg   [`WF_COUNT_WIDTH-1:0]           cam_up_wf_count_reg            ;              
  reg   [`WG_SLOT_ID_WIDTH:0]           cam_up_wg_count_reg            ;        

  //cam outputs
  wire  [`NUMBER_CU-1:0]                vgpr_search_out                ;
  wire  [`NUMBER_CU-1:0]                sgpr_search_out                ;
  wire  [`NUMBER_CU-1:0]                lds_search_out                 ;
  wire  [`NUMBER_CU-1:0]                wf_search_out                  ;
  wire  [`NUMBER_CU-1:0]                wg_search_out                  ;

  //signals that bypass the cam
  reg                                   cam_wait_valid                 ;
  reg   [`WG_ID_WIDTH-1:0]              cam_wait_wg_id                 ;
  reg   [`WF_COUNT_WIDTH_PER_WG-1:0]    cam_wait_wf_count              ;
  reg   [`VGPR_ID_WIDTH:0]              cam_wait_vgpr_size             ;
  reg   [`SGPR_ID_WIDTH:0]              cam_wait_sgpr_size             ;
  reg   [`LDS_ID_WIDTH:0]               cam_wait_lds_size              ;
  reg   [`NUMBER_CU-1:0]                cam_wait_dis_controller_cu_busy;

  //and cam outputs to check if there is anything we can use, choose the right SM
  reg                                   anded_cam_out_valid            ;
  reg   [`NUMBER_CU-1:0]                anded_cam_out                  ;
  reg   [`WG_ID_WIDTH-1:0]              anded_cam_wg_id                ;
  reg   [`WF_COUNT_WIDTH_PER_WG-1:0]    anded_cam_wf_count             ;
  reg   [`VGPR_ID_WIDTH:0]              anded_cam_vgpr_size            ;
  reg   [`SGPR_ID_WIDTH:0]              anded_cam_sgpr_size            ;
  reg   [`LDS_ID_WIDTH:0]               anded_cam_lds_size             ;

  //output encoder and find if we can use any SM, also addr the res start ram
  reg                                   encoded_cu_out_valid           ;
  reg                                   encoded_cu_found_valid         ;
  wire                                  encoded_cu_found_valid_comb    ;
  reg   [`CU_ID_WIDTH-1:0]              encoded_cu_id                  ;
  wire  [`CU_ID_WIDTH-1:0]              encoded_cu_id_comb             ;
  reg   [`WG_ID_WIDTH-1:0]              encoded_cu_wg_id               ;
  reg   [`WF_COUNT_WIDTH_PER_WG-1:0]    encoded_wf_count               ;
  reg   [`VGPR_ID_WIDTH:0]              encoded_vgpr_size              ;
  reg   [`SGPR_ID_WIDTH:0]              encoded_sgpr_size              ;
  reg   [`LDS_ID_WIDTH:0]               encoded_lds_size               ;
  reg   [`VGPR_ID_WIDTH-1:0]            encoded_vgpr_start             ;
  reg   [`SGPR_ID_WIDTH-1:0]            encoded_sgpr_start             ;
  reg   [`LDS_ID_WIDTH-1:0]             encoded_lds_start              ;

  //res size ram lookup
  reg                                   size_ram_valid                 ;
  reg                                   size_ram_cu_id_found           ;
  reg   [`CU_ID_WIDTH-1:0]              cu_id_out                      ;
  reg   [`VGPR_ID_WIDTH-1:0]            vgpr_start_out                 ;
  reg   [`SGPR_ID_WIDTH-1:0]            sgpr_start_out                 ;
  reg   [`LDS_ID_WIDTH-1:0]             lds_start_out                  ;
  reg   [`WG_ID_WIDTH-1:0]              wg_id_out                      ;
  reg   [`WF_COUNT_WIDTH_PER_WG-1:0]    wf_count_out                   ;
  reg   [`VGPR_ID_WIDTH:0]              vgpr_size_out                  ;
  reg   [`SGPR_ID_WIDTH:0]              sgpr_size_out                  ;
  reg   [`LDS_ID_WIDTH:0]               lds_size_out                   ;

  reg   [`NUMBER_CU-1:0]                cu_initialized                 ;
  reg                                   pipeline_waiting               ;
  wire  [`VGPR_ID_WIDTH-1:0]            encoded_vgpr_start_comb        ;
  wire  [`SGPR_ID_WIDTH-1:0]            encoded_sgpr_start_comb        ;
  wire  [`LDS_ID_WIDTH-1:0]             encoded_lds_start_comb         ;

  wire  [`VGPR_ID_WIDTH*`NUMBER_CU-1:0] vgpr_cam_start_vec             ;
  wire  [`SGPR_ID_WIDTH*`NUMBER_CU-1:0] sgpr_cam_start_vec             ;
  wire  [`LDS_ID_WIDTH*`NUMBER_CU-1:0]  lds_cam_start_vec              ;

  //例化cam
  cam_allocator_neo #(
    .RES_ID_WIDTH(`VGPR_ID_WIDTH)
  )
  vgpr_cam (
    .clk                   (clk                 ),
    .rst_n                 (rst_n               ),
    .cam_wr_en_i           (cam_up_valid_reg    ),
    .cam_wr_addr_i         (cam_up_cu_id_reg    ),
    .cam_wr_data_i         (cam_up_vgpr_size_reg),
    .cam_wr_start_i        (cam_up_vgpr_strt_reg),
    .res_search_en_i       (alloc_valid_reg     ),
    .res_search_size_i     (alloc_vgpr_size_reg ),
    .res_search_out_o      (vgpr_search_out     ),
    .res_search_out_start_o(vgpr_cam_start_vec  )
    );

  cam_allocator_neo #(
    .RES_ID_WIDTH(`SGPR_ID_WIDTH)
  )
  sgpr_cam (
    .clk                   (clk                 ),       
    .rst_n                 (rst_n               ),     
    .cam_wr_en_i           (cam_up_valid_reg    ),       
    .cam_wr_addr_i         (cam_up_cu_id_reg    ),     
    .cam_wr_data_i         (cam_up_sgpr_size_reg),
    .cam_wr_start_i        (cam_up_sgpr_strt_reg),
    .res_search_en_i       (alloc_valid_reg     ),      
    .res_search_size_i     (alloc_sgpr_size_reg ),       
    .res_search_out_o      (sgpr_search_out     ),    
    .res_search_out_start_o(sgpr_cam_start_vec  )   
    );

  cam_allocator_neo #(
    .RES_ID_WIDTH(`LDS_ID_WIDTH)
  )
  lds_cam (
    .clk                   (clk                ),       
    .rst_n                 (rst_n              ),     
    .cam_wr_en_i           (cam_up_valid_reg   ),   
    .cam_wr_addr_i         (cam_up_cu_id_reg   ),     
    .cam_wr_data_i         (cam_up_lds_size_reg), 
    .cam_wr_start_i        (cam_up_lds_strt_reg),
    .res_search_en_i       (alloc_valid_reg    ),   
    .res_search_size_i     (alloc_lds_size_reg ),     
    .res_search_out_o      (lds_search_out     ),  
    .res_search_out_start_o(lds_cam_start_vec  ) 
    );

  cam_allocator #(
    .RES_ID_WIDTH(`WF_COUNT_WIDTH)
  )
  wf_cam (
    .clk                   (clk                       ), 
    .rst_n                 (rst_n                     ), 
    .cam_wr_en_i           (cam_up_valid_reg          ), 
    .cam_wr_addr_i         (cam_up_cu_id_reg          ),   
    .cam_wr_data_i         ({1'b0,cam_up_wf_count_reg}),       
    .res_search_en_i       (alloc_valid_reg           ),   
    .res_search_size_i     ({1'b0,alloc_num_wf_reg}   ),     
    .res_search_out_o      (wf_search_out             )   
    );

  cam_allocator #(
    .RES_ID_WIDTH(`WG_SLOT_ID_WIDTH)
  )
  wg_cam (
    .clk                   (clk                             ), 
    .rst_n                 (rst_n                           ), 
    .cam_wr_en_i           (cam_up_valid_reg                ),   
    .cam_wr_addr_i         (cam_up_cu_id_reg                ),   
    .cam_wr_data_i         (cam_up_wg_count_reg             ),
    .res_search_en_i       (alloc_valid_reg                 ),   
    .res_search_size_i     ({{`WG_SLOT_ID_WIDTH{1'b0}},1'b1}),     
    .res_search_out_o      (wg_search_out                   )   
    );

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      pipeline_waiting <= 1'b0;
    end
    else if(encoded_cu_found_valid && !pipeline_waiting) begin
      pipeline_waiting <= 1'b1;
    end
    else if(dis_controller_alloc_ack_i) begin
      pipeline_waiting <= 1'b0;
    end
    else begin
      pipeline_waiting <= pipeline_waiting;
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      alloc_valid_reg                 <= 'd0;                                  
      alloc_wg_id_reg                 <= 'd0;       
      alloc_num_wf_reg                <= 'd0;          
      alloc_vgpr_size_reg             <= 'd0;              
      alloc_sgpr_size_reg             <= 'd0;                
      alloc_lds_size_reg              <= 'd0;                  
      dis_controller_cu_busy_reg      <= 'd0;                    
      cam_wait_valid                  <= 'd0;                  
      cam_wait_wg_id                  <= 'd0;                        
      cam_wait_wf_count               <= 'd0;                        
      cam_wait_vgpr_size              <= 'd0;                        
      cam_wait_sgpr_size              <= 'd0;                    
      cam_wait_lds_size               <= 'd0;                    
      cam_wait_dis_controller_cu_busy <= 'd0;                          
      anded_cam_out_valid             <= 'd0;                            
      anded_cam_out                   <= 'd0;                                
      anded_cam_wg_id                 <= 'd0;                
      anded_cam_wf_count              <= 'd0;                
      anded_cam_vgpr_size             <= 'd0;            
      anded_cam_sgpr_size             <= 'd0;            
      anded_cam_lds_size              <= 'd0;            
      encoded_cu_out_valid            <= 'd0;                  
      encoded_cu_found_valid          <= 'd0;                  
      encoded_cu_id                   <= 'd0;                      
      encoded_cu_wg_id                <= 'd0;                      
      encoded_wf_count                <= 'd0;                
      encoded_vgpr_size               <= 'd0;                
      encoded_sgpr_size               <= 'd0;          
      encoded_lds_size                <= 'd0;            
      encoded_vgpr_start              <= 'd0;              
      encoded_sgpr_start              <= 'd0;            
      encoded_lds_start               <= 'd0;              
      size_ram_valid                  <= 'd0;            
      size_ram_cu_id_found            <= 'd0;          
      cu_id_out                       <= 'd0;        
      vgpr_start_out                  <= 'd0;        
      sgpr_start_out                  <= 'd0;          
      lds_start_out                   <= 'd0;          
      wg_id_out                       <= 'd0;          
      wf_count_out                    <= 'd0;            
      vgpr_size_out                   <= 'd0;        
      sgpr_size_out                   <= 'd0;            
      lds_size_out                    <= 'd0;          
    end
    else if(!pipeline_waiting) begin
      alloc_valid_reg                 <= dis_controller_start_alloc_i                                                                                           ;       
      alloc_wg_id_reg                 <= inflight_wg_buffer_alloc_wg_id_i                                                                                       ;    
      alloc_num_wf_reg                <= inflight_wg_buffer_alloc_num_wf_i                                                                                      ;   
      alloc_vgpr_size_reg             <= inflight_wg_buffer_alloc_vgpr_size_i                                                                                   ;   
      alloc_sgpr_size_reg             <= inflight_wg_buffer_alloc_sgpr_size_i                                                                                   ;   
      alloc_lds_size_reg              <= inflight_wg_buffer_alloc_lds_size_i                                                                                    ;   
      dis_controller_cu_busy_reg      <= dis_controller_cu_busy_i                                                                                               ; 
      cam_wait_valid                  <= alloc_valid_reg                                                                                                        ;       
      cam_wait_wg_id                  <= alloc_wg_id_reg                                                                                                        ;       
      cam_wait_wf_count               <= alloc_num_wf_reg                                                                                                       ;   
      cam_wait_vgpr_size              <= alloc_vgpr_size_reg                                                                                                    ;       
      cam_wait_sgpr_size              <= alloc_sgpr_size_reg                                                                                                    ;       
      cam_wait_lds_size               <= alloc_lds_size_reg                                                                                                     ;       
      cam_wait_dis_controller_cu_busy <= dis_controller_cu_busy_reg                                                                                             ;     
      anded_cam_out_valid             <= cam_wait_valid                                                                                                         ;       
      anded_cam_out                   <= vgpr_search_out & sgpr_search_out & lds_search_out & wf_search_out & wg_search_out & (~cam_wait_dis_controller_cu_busy);
      anded_cam_wg_id                 <= cam_wait_wg_id                                                                                                         ;   
      anded_cam_wf_count              <= cam_wait_wf_count                                                                                                      ;   
      anded_cam_vgpr_size             <= cam_wait_vgpr_size                                                                                                     ; 
      anded_cam_sgpr_size             <= cam_wait_sgpr_size                                                                                                     ;   
      anded_cam_lds_size              <= cam_wait_lds_size                                                                                                      ;     
      encoded_cu_out_valid            <= anded_cam_out_valid                                                                                                    ;       
      encoded_cu_found_valid          <= encoded_cu_found_valid_comb                                                                                            ;       
      encoded_cu_id                   <= encoded_cu_id_comb                                                                                                     ;   
      encoded_cu_wg_id                <= anded_cam_wg_id                                                                                                        ; 
      encoded_wf_count                <= anded_cam_wf_count                                                                                                     ;       
      encoded_vgpr_size               <= anded_cam_vgpr_size                                                                                                    ;   
      encoded_sgpr_size               <= anded_cam_sgpr_size                                                                                                    ;       
      encoded_lds_size                <= anded_cam_lds_size                                                                                                     ;       
      encoded_vgpr_start              <= encoded_vgpr_start_comb                                                                                                ;       
      encoded_sgpr_start              <= encoded_sgpr_start_comb                                                                                                ;       
      encoded_lds_start               <= encoded_lds_start_comb                                                                                                 ;       
      size_ram_valid                  <= encoded_cu_out_valid                                                                                                   ;     
      size_ram_cu_id_found            <= encoded_cu_found_valid                                                                                                 ;       
      cu_id_out                       <= encoded_cu_id                                                                                                          ;       
      vgpr_start_out                  <= encoded_vgpr_start                                                                                                     ;       
      sgpr_start_out                  <= encoded_sgpr_start                                                                                                     ;       
      lds_start_out                   <= encoded_lds_start                                                                                                      ;     
      wg_id_out                       <= encoded_cu_wg_id                                                                                                       ;   
      wf_count_out                    <= encoded_wf_count                                                                                                       ;     
      vgpr_size_out                   <= encoded_vgpr_size                                                                                                      ;       
      sgpr_size_out                   <= encoded_sgpr_size                                                                                                      ;     
      lds_size_out                    <= encoded_lds_size                                                                                                       ;       
    end
    else begin
      alloc_valid_reg                 <= alloc_valid_reg                ;  
      alloc_wg_id_reg                 <= alloc_wg_id_reg                ;
      alloc_num_wf_reg                <= alloc_num_wf_reg               ;
      alloc_vgpr_size_reg             <= alloc_vgpr_size_reg            ;
      alloc_sgpr_size_reg             <= alloc_sgpr_size_reg            ;
      alloc_lds_size_reg              <= alloc_lds_size_reg             ;
      dis_controller_cu_busy_reg      <= dis_controller_cu_busy_reg     ;
      cam_wait_valid                  <= cam_wait_valid                 ;
      cam_wait_wg_id                  <= cam_wait_wg_id                 ;
      cam_wait_wf_count               <= cam_wait_wf_count              ;
      cam_wait_vgpr_size              <= cam_wait_vgpr_size             ;
      cam_wait_sgpr_size              <= cam_wait_sgpr_size             ;
      cam_wait_lds_size               <= cam_wait_lds_size              ;
      cam_wait_dis_controller_cu_busy <= cam_wait_dis_controller_cu_busy;
      anded_cam_out_valid             <= anded_cam_out_valid            ;
      anded_cam_out                   <= anded_cam_out                  ;
      anded_cam_wg_id                 <= anded_cam_wg_id                ;
      anded_cam_wf_count              <= anded_cam_wf_count             ;
      anded_cam_vgpr_size             <= anded_cam_vgpr_size            ;
      anded_cam_sgpr_size             <= anded_cam_sgpr_size            ;
      anded_cam_lds_size              <= anded_cam_lds_size             ;
      encoded_cu_out_valid            <= encoded_cu_out_valid           ;
      encoded_cu_found_valid          <= encoded_cu_found_valid         ;
      encoded_cu_id                   <= encoded_cu_id                  ;
      encoded_cu_wg_id                <= encoded_cu_wg_id               ;
      encoded_wf_count                <= encoded_wf_count               ;
      encoded_vgpr_size               <= encoded_vgpr_size              ;
      encoded_sgpr_size               <= encoded_sgpr_size              ;
      encoded_lds_size                <= encoded_lds_size               ;
      encoded_vgpr_start              <= encoded_vgpr_start             ;
      encoded_sgpr_start              <= encoded_sgpr_start             ;
      encoded_lds_start               <= encoded_lds_start              ;
      size_ram_valid                  <= size_ram_valid                 ;
      size_ram_cu_id_found            <= size_ram_cu_id_found           ;
      cu_id_out                       <= cu_id_out                      ;
      vgpr_start_out                  <= vgpr_start_out                 ;
      sgpr_start_out                  <= sgpr_start_out                 ;
      lds_start_out                   <= lds_start_out                  ;
      wg_id_out                       <= wg_id_out                      ;
      wf_count_out                    <= wf_count_out                   ;
      vgpr_size_out                   <= vgpr_size_out                  ;
      sgpr_size_out                   <= sgpr_size_out                  ;
      lds_size_out                    <= lds_size_out                   ;
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      cam_up_valid_reg     <= 'd0;  
      cam_up_cu_id_reg     <= 'd0;
      cam_up_vgpr_strt_reg <= 'd0;
      cam_up_vgpr_size_reg <= 'd0;
      cam_up_sgpr_strt_reg <= 'd0;
      cam_up_sgpr_size_reg <= 'd0;
      cam_up_lds_strt_reg  <= 'd0;
      cam_up_lds_size_reg  <= 'd0;
      cam_up_wf_count_reg  <= 'd0;
      cam_up_wg_count_reg  <= 'd0;
    end
    else begin
      cam_up_valid_reg     <= grt_cam_up_valid_i    ; 
      cam_up_cu_id_reg     <= grt_cam_up_cu_id_i    ;
      cam_up_vgpr_strt_reg <= grt_cam_up_vgpr_strt_i;
      cam_up_vgpr_size_reg <= grt_cam_up_vgpr_size_i;
      cam_up_sgpr_strt_reg <= grt_cam_up_sgpr_strt_i;
      cam_up_sgpr_size_reg <= grt_cam_up_sgpr_size_i;
      cam_up_lds_strt_reg  <= grt_cam_up_lds_strt_i ;
      cam_up_lds_size_reg  <= grt_cam_up_lds_size_i ;
      cam_up_wf_count_reg  <= grt_cam_up_wf_count_i ;
      cam_up_wg_count_reg  <= grt_cam_up_wg_count_i ;
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      cu_initialized <= 1'b0;
    end
    else if(cam_up_valid_reg) begin
      cu_initialized[cam_up_cu_id_reg] <= 1'b1;
    end
    else begin
      cu_initialized <= cu_initialized;
    end
  end

  assign allocator_cu_valid_o       = size_ram_valid       ;
  assign allocator_cu_rejected_o    = !size_ram_cu_id_found;
  assign allocator_cu_id_out_o      = cu_id_out            ;
  assign allocator_wg_id_out_o      = wg_id_out            ;
  assign allocator_wf_count_o       = wf_count_out         ;
  assign allocator_vgpr_size_out_o  = vgpr_size_out        ;
  assign allocator_sgpr_size_out_o  = sgpr_size_out        ;
  assign allocator_lds_size_out_o   = lds_size_out         ;
  assign allocator_vgpr_start_out_o = (!cu_initialized[cu_id_out]) ? 'd0 : vgpr_start_out;
  assign allocator_sgpr_start_out_o = (!cu_initialized[cu_id_out]) ? 'd0 : sgpr_start_out;
  assign allocator_lds_start_out_o  = (!cu_initialized[cu_id_out]) ? 'd0 : lds_start_out ;

  //例化prefer_select
  prefer_select #(
    .RANGE   (`NUMBER_CU  ),
    .ID_WIDTH(`CU_ID_WIDTH)
  )
  U_prefer_select (
    .signal_i(anded_cam_out                    ),
    .prefer_i(anded_cam_wg_id[`CU_ID_WIDTH-1:0]),
    .valid_o (encoded_cu_found_valid_comb      ),
    .id_o    (encoded_cu_id_comb               )
    );

  assign encoded_vgpr_start_comb = vgpr_cam_start_vec[(encoded_cu_id_comb+1)*`VGPR_ID_WIDTH-1-:`VGPR_ID_WIDTH];
  assign encoded_sgpr_start_comb = sgpr_cam_start_vec[(encoded_cu_id_comb+1)*`SGPR_ID_WIDTH-1-:`SGPR_ID_WIDTH];
  assign encoded_lds_start_comb  = lds_cam_start_vec[(encoded_cu_id_comb+1)*`LDS_ID_WIDTH-1-:`LDS_ID_WIDTH]   ;

endmodule
