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
// Description:将wg分成warp发送给SM同时接收warp完成信号
 
`timescale 1ns/1ns
`include "define.v"

module gpu_interface (
  input                                   clk                                      ,
  input                                   rst_n                                    ,

  input                                   inflight_wg_buffer_gpu_valid_i           ,
  input   [`WAVE_ITEM_WIDTH-1:0]          inflight_wg_buffer_gpu_wf_size_i         ,
  input   [`MEM_ADDR_WIDTH-1:0]           inflight_wg_buffer_start_pc_i            ,
  input   [`WG_SIZE_X_WIDTH*3-1:0]        inflight_wg_buffer_kernel_size_3d_i      ,
  input   [`MEM_ADDR_WIDTH-1:0]           inflight_wg_buffer_pds_baseaddr_i        ,
  input   [`MEM_ADDR_WIDTH-1:0]           inflight_wg_buffer_csr_knl_i             ,
  input   [`MEM_ADDR_WIDTH-1:0]           inflight_wg_buffer_gds_base_dispatch_i   ,
  input   [`VGPR_ID_WIDTH:0]              inflight_wg_buffer_gpu_vgpr_size_per_wf_i,
  input   [`SGPR_ID_WIDTH:0]              inflight_wg_buffer_gpu_sgpr_size_per_wf_i,

  input   [`WG_ID_WIDTH-1:0]              allocator_wg_id_out_i                    ,
  input   [`CU_ID_WIDTH-1:0]              allocator_cu_id_out_i                    ,
  input   [`WF_COUNT_WIDTH_PER_WG-1:0]    allocator_wf_count_i                     ,
  input   [`VGPR_ID_WIDTH-1:0]            allocator_vgpr_start_out_i               ,
  input   [`SGPR_ID_WIDTH-1:0]            allocator_sgpr_start_out_i               ,
  input   [`LDS_ID_WIDTH-1:0]             allocator_lds_start_out_i                ,

  input   [`NUMBER_CU-1:0]                cu2dispatch_wf_done_i                    ,
  input   [`TAG_WIDTH*`NUMBER_CU-1:0]     cu2dispatch_wf_tag_done_i                ,
  input   [`NUMBER_CU-1:0]                cu2dispatch_ready_for_dispatch_i         ,

  input                                   dis_controller_wg_alloc_valid_i          ,
  input                                   dis_controller_wg_dealloc_valid_i        ,

  output                                  gpu_interface_alloc_available_o          ,
  output                                  gpu_interface_dealloc_available_o        ,
  output  [`CU_ID_WIDTH-1:0]              gpu_interface_cu_id_o                    ,
  output  [`WG_ID_WIDTH-1:0]              gpu_interface_dealloc_wg_id_o            ,

  output  [`NUMBER_CU-1:0]                dispatch2cu_wf_dispatch_o                ,
  output  [`WF_COUNT_WIDTH_PER_WG-1:0]    dispatch2cu_wg_wf_count_o                ,
  output  [`WAVE_ITEM_WIDTH-1:0]          dispatch2cu_wf_size_dispatch_o           ,
  output  [`SGPR_ID_WIDTH:0]              dispatch2cu_sgpr_base_dispatch_o         ,
  output  [`VGPR_ID_WIDTH:0]              dispatch2cu_vgpr_base_dispatch_o         ,
  output  [`TAG_WIDTH-1:0]                dispatch2cu_wf_tag_dispatch_o            ,
  output  [`LDS_ID_WIDTH:0]               dispatch2cu_lds_base_dispatch_o          ,
  output  [`MEM_ADDR_WIDTH-1:0]           dispatch2cu_start_pc_dispatch_o          ,
  output  [`WG_SIZE_X_WIDTH*3-1:0]        dispatch2cu_kernel_size_3d_dispatch_o    ,
  output  [`MEM_ADDR_WIDTH-1:0]           dispatch2cu_pds_baseaddr_dispatch_o      ,
  output  [`MEM_ADDR_WIDTH-1:0]           dispatch2cu_csr_knl_dispatch_o           ,
  output  [`MEM_ADDR_WIDTH-1:0]           dispatch2cu_gds_base_dispatch_o           
  );

  localparam  ST_DEALLOC_IDLE       = 2'b01;
  localparam  ST_DEALLOC_WAIT_ACK   = 2'b10;
  localparam  ST_ALLOC_IDLE         = 4'b0001;
  localparam  ST_ALLOC_WAIT_BUFFER  = 4'b0010;
  localparam  ST_ALLOC_WAIT_HANDLER = 4'b0100;
  localparam  ST_ALLOC_PASS_WF      = 4'b1000;

  reg   [1:0]                             dealloc_st;
  reg   [3:0]                             alloc_st  ;

  // Incomming finished wf -> increment finished count until all wf retire
  // Communicate back to utd
  // Deallocation registers
  reg                                     gpu_interface_dealloc_available_reg;
  reg                                     dis_controller_wg_dealloc_valid_reg;
  reg   [`NUMBER_CU-1:0]                  handler_wg_done_ack                ;
  reg                                     chosen_done_cu_valid               ;
  wire                                    chosen_done_cu_valid_comb          ;
  reg   [`CU_ID_WIDTH-1:0]                chosen_done_cu_id                  ;
  wire  [`CU_ID_WIDTH-1:0]                chosen_done_cu_id_comb             ;
  reg   [`NUMBER_CU-1:0]                  handler_wg_done_valid              ;
  reg   [`NUMBER_CU*`WG_ID_WIDTH-1:0]     handler_wg_done_wg_id              ;
  wire  [`NUMBER_CU-1:0]                  handler_wg_done_valid_w            ;
  wire  [`NUMBER_CU*`WG_ID_WIDTH-1:0]     handler_wg_done_wg_id_w            ;
  reg   [`NUMBER_CU-1:0]                  cu2dispatch_wf_done_reg            ;
  reg   [`NUMBER_CU*`TAG_WIDTH-1:0]       cu2dispatch_wf_tag_done_reg        ;

  // Incomming alloc wg -> get them a tag (find a free slot on the vector),
  // store wgid and wf count,
  // disparch them, one wf at a time
  // Allocation registters
  reg                                           dis_controller_wg_alloc_valid_reg          ;
  reg                                           inflight_wg_buffer_gpu_valid_reg           ;
  reg   [`WAVE_ITEM_WIDTH-1:0]                  inflight_wg_buffer_gpu_wf_size_reg         ;
  reg   [`MEM_ADDR_WIDTH-1:0]                   inflight_wg_buffer_start_pc_reg            ;
  reg   [`WG_SIZE_X_WIDTH*3-1:0]                inflight_wg_buffer_kernel_size_3d_reg      ;
  reg   [`MEM_ADDR_WIDTH-1:0]                   inflight_wg_buffer_pds_baseaddr_reg        ;
  reg   [`MEM_ADDR_WIDTH-1:0]                   inflight_wg_buffer_csr_knl_reg             ;
  reg   [`MEM_ADDR_WIDTH-1:0]                   inflight_wg_buffer_gds_base_dispatch_reg   ;
  reg   [`VGPR_ID_WIDTH-1:0]                    inflight_wg_buffer_gpu_vgpr_size_per_wf_reg;
  reg   [`SGPR_ID_WIDTH-1:0]                    inflight_wg_buffer_gpu_sgpr_size_per_wf_reg;

  reg   [`WG_ID_WIDTH-1:0]                      allocator_wg_id_out_reg     ;
  reg   [`CU_ID_WIDTH-1:0]                      allocator_cu_id_out_reg     ;
  reg   [`WF_COUNT_WIDTH_PER_WG-1:0]            allocator_wf_count_reg      ;
  reg   [`VGPR_ID_WIDTH-1:0]                    allocator_vgpr_start_out_reg;
  reg   [`SGPR_ID_WIDTH-1:0]                    allocator_sgpr_start_out_reg;
  reg   [`LDS_ID_WIDTH-1:0]                     allocator_lds_start_out_reg ;

  reg                                           gpu_interface_alloc_available_reg;
  reg   [`CU_ID_WIDTH-1:0]                      gpu_interface_cu_id_reg          ;
  reg   [`WG_ID_WIDTH-1:0]                      gpu_interface_dealloc_wg_id_reg  ;

  reg   [`NUMBER_CU-1:0]                        dispatch2cu_wf_dispatch_handlers      ;
  reg   [`NUMBER_CU-1:0]                        invalid_due_to_not_ready_handlers     ;
  reg   [`NUMBER_CU*`TAG_WIDTH-1:0]             dispatch2cu_wf_tag_dispatch_handlers  ;
  wire  [`NUMBER_CU-1:0]                        dispatch2cu_wf_dispatch_handlers_w    ;
  wire  [`NUMBER_CU-1:0]                        invalid_due_to_not_ready_handlers_w   ;
  wire  [`NUMBER_CU*`TAG_WIDTH-1:0]             dispatch2cu_wf_tag_dispatch_handlers_w;

  reg   [`NUMBER_CU-1:0]                        handler_wg_alloc_en      ;
  reg   [`NUMBER_CU*`WG_ID_WIDTH-1:0]           handler_wg_alloc_wg_id   ;
  reg   [`NUMBER_CU*`WF_COUNT_WIDTH_PER_WG-1:0] handler_wg_alloc_wf_count;

  reg   [`NUMBER_CU-1:0]                        dispatch2cu_wf_dispatch_reg            ;
  reg   [`WF_COUNT_WIDTH_PER_WG-1:0]            dispatch2cu_wg_wf_count_reg            ;
  reg   [`WAVE_ITEM_WIDTH-1:0]                  dispatch2cu_wf_size_dispatch_reg       ;
  reg   [`SGPR_ID_WIDTH:0]                      dispatch2cu_sgpr_base_dispatch_reg     ;
  reg   [`VGPR_ID_WIDTH:0]                      dispatch2cu_vgpr_base_dispatch_reg     ;
  reg   [`TAG_WIDTH-1:0]                        dispatch2cu_wf_tag_dispatch_reg        ;
  reg   [`LDS_ID_WIDTH:0]                       dispatch2cu_lds_base_dispatch_reg      ;
  reg   [`MEM_ADDR_WIDTH-1:0]                   dispatch2cu_start_pc_dispatch_reg      ;
  reg   [`WG_SIZE_X_WIDTH*3-1:0]                dispatch2cu_kernel_size_3d_dispatch_reg;
  reg   [`MEM_ADDR_WIDTH-1:0]                   dispatch2cu_pds_baseaddr_dispatch_reg  ;
  reg   [`MEM_ADDR_WIDTH-1:0]                   dispatch2cu_csr_knl_dispatch_reg       ;
  reg   [`MEM_ADDR_WIDTH-1:0]                   dispatch2cu_gds_base_dispatch_reg      ;

  wire                                          cu_found_valid;
  wire  [`CU_ID_WIDTH-1:0]                      cu_found      ;
  wire  [`NUMBER_CU-1:0]                        grant         ;

  genvar i;
  generate for(i=0;i<`NUMBER_CU;i=i+1) begin : A1
    cu_handler U_cu_handler (
      .clk                          (clk                                                                              ),      
      .rst_n                        (rst_n                                                                            ),              
                                    
      .wg_alloc_en_i                (handler_wg_alloc_en[i]                                                           ),          
      .wg_alloc_wg_id_i             (handler_wg_alloc_wg_id[(i+1)*`WG_ID_WIDTH-1-:`WG_ID_WIDTH]                       ),          
      .wg_alloc_wf_count_i          (handler_wg_alloc_wf_count[(i+1)*`WF_COUNT_WIDTH_PER_WG-1-:`WF_COUNT_WIDTH_PER_WG]),    
      .ready_for_dispatch2cu_i      (cu2dispatch_ready_for_dispatch_i[i]                                              ),  
      .cu2dispatch_wf_done_i        (cu2dispatch_wf_done_reg[i]                                                       ),      
      .cu2dispatch_wf_tag_done_i    (cu2dispatch_wf_tag_done_reg[(i+1)*`TAG_WIDTH-1-:`TAG_WIDTH]                      ),      
      .wg_done_ack_i                (handler_wg_done_ack[i]                                                           ),        
                                   
      .dispatch2cu_wf_dispatch_o    (dispatch2cu_wf_dispatch_handlers_w[i]                                            ),            
      .dispatch2cu_wf_tag_dispatch_o(dispatch2cu_wf_tag_dispatch_handlers_w[(i+1)*`TAG_WIDTH-1-:`TAG_WIDTH]           ),                
      .wg_done_valid_o              (handler_wg_done_valid_w[i]                                                       ),        
      .wg_done_wg_id_o              (handler_wg_done_wg_id_w[(i+1)*`WG_ID_WIDTH-1-:`WG_ID_WIDTH]                      ),          
      .invalid_due_to_not_ready_o   (invalid_due_to_not_ready_handlers_w[i]                                           )      
      );
  end
  endgenerate

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      dis_controller_wg_alloc_valid_reg    <= 'd0;
      dis_controller_wg_dealloc_valid_reg  <= 'd0;
      inflight_wg_buffer_gpu_valid_reg     <= 'd0;
      cu2dispatch_wf_done_reg              <= 'd0;
      cu2dispatch_wf_tag_done_reg          <= 'd0;
      chosen_done_cu_valid                 <= 'd0;
      chosen_done_cu_id                    <= 'd0;
      dispatch2cu_wf_dispatch_handlers     <= 'd0;
      dispatch2cu_wf_tag_dispatch_handlers <= 'd0;
      handler_wg_done_valid                <= 'd0;
      handler_wg_done_wg_id                <= 'd0;
      invalid_due_to_not_ready_handlers    <= 'd0;
    end
    else begin
      dis_controller_wg_alloc_valid_reg    <= dis_controller_wg_alloc_valid_i       ;
      dis_controller_wg_dealloc_valid_reg  <= dis_controller_wg_dealloc_valid_i     ;
      inflight_wg_buffer_gpu_valid_reg     <= inflight_wg_buffer_gpu_valid_i        ;
      cu2dispatch_wf_done_reg              <= cu2dispatch_wf_done_i                 ;
      cu2dispatch_wf_tag_done_reg          <= cu2dispatch_wf_tag_done_i             ;
      chosen_done_cu_valid                 <= chosen_done_cu_valid_comb             ;
      chosen_done_cu_id                    <= chosen_done_cu_id_comb                ;
      dispatch2cu_wf_dispatch_handlers     <= dispatch2cu_wf_dispatch_handlers_w    ; 
      dispatch2cu_wf_tag_dispatch_handlers <= dispatch2cu_wf_tag_dispatch_handlers_w; 
      handler_wg_done_valid                <= handler_wg_done_valid_w               ;                
      handler_wg_done_wg_id                <= handler_wg_done_wg_id_w               ; 
      invalid_due_to_not_ready_handlers    <= invalid_due_to_not_ready_handlers_w   ;    
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      inflight_wg_buffer_gpu_wf_size_reg          <= 'd0;       
      inflight_wg_buffer_start_pc_reg             <= 'd0;                 
      inflight_wg_buffer_kernel_size_3d_reg       <= 'd0;                   
      inflight_wg_buffer_pds_baseaddr_reg         <= 'd0;                 
      inflight_wg_buffer_csr_knl_reg              <= 'd0;               
      inflight_wg_buffer_gds_base_dispatch_reg    <= 'd0;               
      inflight_wg_buffer_gpu_vgpr_size_per_wf_reg <= 'd0;           
      inflight_wg_buffer_gpu_sgpr_size_per_wf_reg <= 'd0;         
      allocator_wg_id_out_reg                     <= 'd0;         
      allocator_cu_id_out_reg                     <= 'd0;         
      allocator_wf_count_reg                      <= 'd0;         
      allocator_vgpr_start_out_reg                <= 'd0;     
      allocator_sgpr_start_out_reg                <= 'd0;             
      allocator_lds_start_out_reg                 <= 'd0;           
    end
    else if(inflight_wg_buffer_gpu_valid_i) begin
      inflight_wg_buffer_gpu_wf_size_reg          <= inflight_wg_buffer_gpu_wf_size_i         ; 
      inflight_wg_buffer_start_pc_reg             <= inflight_wg_buffer_start_pc_i            ;
      inflight_wg_buffer_kernel_size_3d_reg       <= inflight_wg_buffer_kernel_size_3d_i      ;
      inflight_wg_buffer_pds_baseaddr_reg         <= inflight_wg_buffer_pds_baseaddr_i        ;
      inflight_wg_buffer_csr_knl_reg              <= inflight_wg_buffer_csr_knl_i             ;
      inflight_wg_buffer_gds_base_dispatch_reg    <= inflight_wg_buffer_gds_base_dispatch_i   ;
      inflight_wg_buffer_gpu_vgpr_size_per_wf_reg <= inflight_wg_buffer_gpu_vgpr_size_per_wf_i;
      inflight_wg_buffer_gpu_sgpr_size_per_wf_reg <= inflight_wg_buffer_gpu_sgpr_size_per_wf_i;
    end
    else if(dis_controller_wg_alloc_valid_i) begin
      allocator_wg_id_out_reg      <= allocator_wg_id_out_i     ;                
      allocator_cu_id_out_reg      <= allocator_cu_id_out_i     ;                
      allocator_wf_count_reg       <= allocator_wf_count_i      ;                
      allocator_vgpr_start_out_reg <= allocator_vgpr_start_out_i;                
      allocator_sgpr_start_out_reg <= allocator_sgpr_start_out_i;                
      allocator_lds_start_out_reg  <= allocator_lds_start_out_i ;                
    end
    else begin
      inflight_wg_buffer_gpu_wf_size_reg          <= inflight_wg_buffer_gpu_wf_size_reg         ;  
      inflight_wg_buffer_start_pc_reg             <= inflight_wg_buffer_start_pc_reg            ;
      inflight_wg_buffer_kernel_size_3d_reg       <= inflight_wg_buffer_kernel_size_3d_reg      ;
      inflight_wg_buffer_pds_baseaddr_reg         <= inflight_wg_buffer_pds_baseaddr_reg        ;
      inflight_wg_buffer_csr_knl_reg              <= inflight_wg_buffer_csr_knl_reg             ;
      inflight_wg_buffer_gds_base_dispatch_reg    <= inflight_wg_buffer_gds_base_dispatch_reg   ;
      inflight_wg_buffer_gpu_vgpr_size_per_wf_reg <= inflight_wg_buffer_gpu_vgpr_size_per_wf_reg;
      inflight_wg_buffer_gpu_sgpr_size_per_wf_reg <= inflight_wg_buffer_gpu_sgpr_size_per_wf_reg;
      allocator_wg_id_out_reg                     <= allocator_wg_id_out_reg                    ;
      allocator_cu_id_out_reg                     <= allocator_cu_id_out_reg                    ;
      allocator_wf_count_reg                      <= allocator_wf_count_reg                     ;
      allocator_vgpr_start_out_reg                <= allocator_vgpr_start_out_reg               ;
      allocator_sgpr_start_out_reg                <= allocator_sgpr_start_out_reg               ;
      allocator_lds_start_out_reg                 <= allocator_lds_start_out_reg                ;
    end
  end

  // On allocation
	// Receives wg_id, waits for sizes per wf
	// Pass values to cu_handler -> for each dispatch in 1, pass one wf to cus
	// after passing, sets itself as available again
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      gpu_interface_alloc_available_reg       <= 'd0          ;
      handler_wg_alloc_en                     <= 'd0          ;
      handler_wg_alloc_wg_id                  <= 'd0          ;
      handler_wg_alloc_wf_count               <= 'd0          ;
      alloc_st                                <= ST_ALLOC_IDLE;
      dispatch2cu_wf_dispatch_reg             <= 'd0          ; 
      dispatch2cu_wg_wf_count_reg             <= 'd0          ;
      dispatch2cu_wf_size_dispatch_reg        <= 'd0          ;
      dispatch2cu_sgpr_base_dispatch_reg      <= 'd0          ;
      dispatch2cu_vgpr_base_dispatch_reg      <= 'd0          ;
      dispatch2cu_wf_tag_dispatch_reg         <= 'd0          ;
      dispatch2cu_lds_base_dispatch_reg       <= 'd0          ;
      dispatch2cu_start_pc_dispatch_reg       <= 'd0          ;
      dispatch2cu_kernel_size_3d_dispatch_reg <= 'd0          ;
      dispatch2cu_pds_baseaddr_dispatch_reg   <= 'd0          ;
      dispatch2cu_csr_knl_dispatch_reg        <= 'd0          ;
      dispatch2cu_gds_base_dispatch_reg       <= 'd0          ;
    end
    else begin
      case(alloc_st) 
        ST_ALLOC_IDLE : begin
          if(dis_controller_wg_alloc_valid_reg) begin
            if(inflight_wg_buffer_gpu_valid_reg) begin
              handler_wg_alloc_en[allocator_cu_id_out_reg]                                                            <= 1'b1                   ;
              dispatch2cu_wf_dispatch_reg                                                                             <= 'd0                    ;
              handler_wg_alloc_wg_id[(allocator_cu_id_out_reg+1)*`WG_ID_WIDTH-1-:`WG_ID_WIDTH]                        <= allocator_wg_id_out_reg;
              handler_wg_alloc_wf_count[(allocator_cu_id_out_reg+1)*`WF_COUNT_WIDTH_PER_WG-1-:`WF_COUNT_WIDTH_PER_WG] <= allocator_wf_count_reg ;
              gpu_interface_alloc_available_reg                                                                       <= 1'b0                   ;
              alloc_st                                                                                                <= ST_ALLOC_WAIT_HANDLER  ;
            end
            else begin
              handler_wg_alloc_en               <= 'd0                 ;
              dispatch2cu_wf_dispatch_reg       <= 'd0                 ;
              gpu_interface_alloc_available_reg <= 1'b0                ;
              alloc_st                          <= ST_ALLOC_WAIT_BUFFER;
            end
          end
          else begin
            handler_wg_alloc_en               <= 'd0 ;
            dispatch2cu_wf_dispatch_reg       <= 'd0 ;
            gpu_interface_alloc_available_reg <= 1'b1;
          end
        end

        ST_ALLOC_WAIT_BUFFER : begin
          if(inflight_wg_buffer_gpu_valid_reg) begin
            handler_wg_alloc_en[allocator_cu_id_out_reg]                                                            <= 1'b1                   ;
            dispatch2cu_wf_dispatch_reg                                                                             <= 'd0                    ;
            handler_wg_alloc_wg_id[(allocator_cu_id_out_reg+1)*`WG_ID_WIDTH-1-:`WG_ID_WIDTH]                        <= allocator_wg_id_out_reg;
            handler_wg_alloc_wf_count[(allocator_cu_id_out_reg+1)*`WF_COUNT_WIDTH_PER_WG-1-:`WF_COUNT_WIDTH_PER_WG] <= allocator_wf_count_reg ;
            gpu_interface_alloc_available_reg                                                                       <= 1'b0                   ;
            alloc_st                                                                                                <= ST_ALLOC_WAIT_HANDLER  ;
          end
          else begin
            handler_wg_alloc_en         <= 'd0;
            dispatch2cu_wf_dispatch_reg <= 'd0;
          end
        end

        ST_ALLOC_WAIT_HANDLER : begin
          if(dispatch2cu_wf_dispatch_handlers[allocator_cu_id_out_reg]) begin
            handler_wg_alloc_en                     <= 'd0                                                                                       ;
            dispatch2cu_wf_dispatch_reg             <= {{(`NUMBER_CU-1){1'b0}},1'b1} << allocator_cu_id_out_reg                                  ;
            dispatch2cu_wg_wf_count_reg             <= allocator_wf_count_reg                                                                    ;
            dispatch2cu_wf_size_dispatch_reg        <= inflight_wg_buffer_gpu_wf_size_reg                                                        ;
            dispatch2cu_sgpr_base_dispatch_reg      <= allocator_sgpr_start_out_reg                                                              ;
            dispatch2cu_vgpr_base_dispatch_reg      <= allocator_vgpr_start_out_reg                                                              ;
            dispatch2cu_wf_tag_dispatch_reg         <= dispatch2cu_wf_tag_dispatch_handlers[(allocator_cu_id_out_reg+1)*`TAG_WIDTH-1-:`TAG_WIDTH];
            dispatch2cu_lds_base_dispatch_reg       <= allocator_lds_start_out_reg                                                               ;
            dispatch2cu_start_pc_dispatch_reg       <= inflight_wg_buffer_start_pc_reg                                                           ;
            dispatch2cu_kernel_size_3d_dispatch_reg <= inflight_wg_buffer_kernel_size_3d_reg                                                     ;
            dispatch2cu_pds_baseaddr_dispatch_reg   <= inflight_wg_buffer_pds_baseaddr_reg                                                       ;
            dispatch2cu_csr_knl_dispatch_reg        <= inflight_wg_buffer_csr_knl_reg                                                            ;
            dispatch2cu_gds_base_dispatch_reg       <= inflight_wg_buffer_gds_base_dispatch_reg                                                  ;
            alloc_st                                <= ST_ALLOC_PASS_WF                                                                          ;
          end
          else begin
            handler_wg_alloc_en         <= 'd0;
            dispatch2cu_wf_dispatch_reg <= 'd0;
          end
        end

        ST_ALLOC_PASS_WF : begin
          if(dispatch2cu_wf_dispatch_handlers[allocator_cu_id_out_reg]) begin
            handler_wg_alloc_en                <= 'd0                                                                                       ;
            dispatch2cu_wf_dispatch_reg        <= {{(`NUMBER_CU-1){1'b0}},1'b1} << allocator_cu_id_out_reg                                  ;
            dispatch2cu_wf_tag_dispatch_reg    <= dispatch2cu_wf_tag_dispatch_handlers[(allocator_cu_id_out_reg+1)*`TAG_WIDTH-1-:`TAG_WIDTH];
            dispatch2cu_sgpr_base_dispatch_reg <= dispatch2cu_sgpr_base_dispatch_reg + inflight_wg_buffer_gpu_sgpr_size_per_wf_reg          ;
            dispatch2cu_vgpr_base_dispatch_reg <= dispatch2cu_vgpr_base_dispatch_reg + inflight_wg_buffer_gpu_vgpr_size_per_wf_reg          ;
          end
          else if(invalid_due_to_not_ready_handlers[allocator_cu_id_out_reg]) begin
            handler_wg_alloc_en         <= 'd0;
            dispatch2cu_wf_dispatch_reg <= 'd0;
          end
          else begin
            handler_wg_alloc_en               <= 'd0          ;
            dispatch2cu_wf_dispatch_reg       <= 'd0          ;
            gpu_interface_alloc_available_reg <= 1'b1         ;
            alloc_st                          <= ST_ALLOC_IDLE;
          end
        end

        default : begin
          gpu_interface_alloc_available_reg       <= 'd0          ;
          handler_wg_alloc_en                     <= 'd0          ;
          handler_wg_alloc_wg_id                  <= 'd0          ;
          handler_wg_alloc_wf_count               <= 'd0          ;
          alloc_st                                <= ST_ALLOC_IDLE;
          dispatch2cu_wf_dispatch_reg             <= 'd0          ;
          dispatch2cu_wg_wf_count_reg             <= 'd0          ;
          dispatch2cu_wf_size_dispatch_reg        <= 'd0          ;
          dispatch2cu_sgpr_base_dispatch_reg      <= 'd0          ;
          dispatch2cu_vgpr_base_dispatch_reg      <= 'd0          ;
          dispatch2cu_wf_tag_dispatch_reg         <= 'd0          ;
          dispatch2cu_lds_base_dispatch_reg       <= 'd0          ;
          dispatch2cu_start_pc_dispatch_reg       <= 'd0          ;
          dispatch2cu_kernel_size_3d_dispatch_reg <= 'd0          ;
          dispatch2cu_pds_baseaddr_dispatch_reg   <= 'd0          ;
          dispatch2cu_csr_knl_dispatch_reg        <= 'd0          ;
          dispatch2cu_gds_base_dispatch_reg       <= 'd0          ;
        end
      endcase
    end
  end

  // On dealloc
	// Ack to the handler
	// pass info to the dispatcher
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      gpu_interface_dealloc_available_reg <= 'd0            ;
      gpu_interface_cu_id_reg             <= 'd0            ;
      handler_wg_done_ack                 <= 'd0            ;
      gpu_interface_dealloc_wg_id_reg     <= 'd0            ;
      dealloc_st                          <= ST_DEALLOC_IDLE;
    end
    else begin
      case(dealloc_st) 
        ST_DEALLOC_IDLE : begin
          if(chosen_done_cu_valid) begin
            gpu_interface_dealloc_available_reg    <= 1'b1                                                                     ;
            gpu_interface_cu_id_reg                <= chosen_done_cu_id                                                        ;
            handler_wg_done_ack[chosen_done_cu_id] <= 1'b1                                                                     ;
            gpu_interface_dealloc_wg_id_reg        <= handler_wg_done_wg_id[(chosen_done_cu_id+1)*`WG_ID_WIDTH-1-:`WG_ID_WIDTH];
            dealloc_st                             <= ST_DEALLOC_WAIT_ACK                                                      ;
          end
          else begin
            gpu_interface_dealloc_available_reg <= 'd0;
            handler_wg_done_ack                 <= 'd0;
          end
        end

        ST_DEALLOC_WAIT_ACK : begin
          if(dis_controller_wg_dealloc_valid_reg) begin
            gpu_interface_dealloc_available_reg <= 'd0            ;
            handler_wg_done_ack                 <= 'd0            ;
            dealloc_st                          <= ST_DEALLOC_IDLE;
          end
          else begin
            gpu_interface_dealloc_available_reg <= 1'b1;
            handler_wg_done_ack                 <= 'd0 ;
          end
        end

        default : begin
          gpu_interface_dealloc_available_reg <= 'd0            ;
          gpu_interface_cu_id_reg             <= 'd0            ;
          handler_wg_done_ack                 <= 'd0            ;
          gpu_interface_dealloc_wg_id_reg     <= 'd0            ;
          dealloc_st                          <= ST_DEALLOC_IDLE;
        end
      endcase
    end
  end

  assign cu_found_valid = |handler_wg_done_valid;
  fixed_pri_arb #(
    .ARB_WIDTH(`NUMBER_CU)
  )
  U_fixed_pri_arb (
    .req  (handler_wg_done_valid),
    .grant(grant                )
    );

  one2bin #(
    .ONE_WIDTH(`NUMBER_CU  ),
    .BIN_WIDTH(`CU_ID_WIDTH)
  )
  U_one2bin (
    .oh (grant   ),
    .bin(cu_found)
    );

  assign chosen_done_cu_valid_comb = cu_found_valid;
  assign chosen_done_cu_id_comb    = cu_found      ;

  assign gpu_interface_dealloc_available_o     = gpu_interface_dealloc_available_reg    ;
  assign gpu_interface_dealloc_wg_id_o         = gpu_interface_dealloc_wg_id_reg        ;
  assign gpu_interface_cu_id_o                 = gpu_interface_cu_id_reg                ;
  assign gpu_interface_alloc_available_o       = gpu_interface_alloc_available_reg      ;
  assign dispatch2cu_wf_dispatch_o             = dispatch2cu_wf_dispatch_reg            ;
  assign dispatch2cu_wf_tag_dispatch_o         = dispatch2cu_wf_tag_dispatch_reg        ;
  assign dispatch2cu_wg_wf_count_o             = dispatch2cu_wg_wf_count_reg            ;
  assign dispatch2cu_wf_size_dispatch_o        = dispatch2cu_wf_size_dispatch_reg       ;
  assign dispatch2cu_sgpr_base_dispatch_o      = dispatch2cu_sgpr_base_dispatch_reg     ;
  assign dispatch2cu_vgpr_base_dispatch_o      = dispatch2cu_vgpr_base_dispatch_reg     ;
  assign dispatch2cu_lds_base_dispatch_o       = dispatch2cu_lds_base_dispatch_reg      ;
  assign dispatch2cu_start_pc_dispatch_o       = dispatch2cu_start_pc_dispatch_reg      ;
  assign dispatch2cu_kernel_size_3d_dispatch_o = dispatch2cu_kernel_size_3d_dispatch_reg;
  assign dispatch2cu_pds_baseaddr_dispatch_o   = dispatch2cu_pds_baseaddr_dispatch_reg  ;
  assign dispatch2cu_csr_knl_dispatch_o        = dispatch2cu_csr_knl_dispatch_reg       ;
  assign dispatch2cu_gds_base_dispatch_o       = dispatch2cu_gds_base_dispatch_reg      ;

endmodule
