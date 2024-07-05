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
// Description:计算并缓存SM内核中vgpr、sgpr和lds的剩余资源以及workgroup和warp的使用情况

`timescale 1ns/1ns
`include "define.v"

module top_resource_table (
  input                                 clk                              , 
  input                                 rst_n                            ,
  input   [`WG_ID_WIDTH-1:0]            allocator_wg_id_out_i            ,
  input   [`WF_COUNT_WIDTH_PER_WG-1:0]  allocator_wf_count_i             ,
  input   [`CU_ID_WIDTH-1:0]            allocator_cu_id_out_i            ,
  input   [`VGPR_ID_WIDTH-1:0]          allocator_vgpr_start_out_i       ,
  input   [`VGPR_ID_WIDTH:0]            allocator_vgpr_size_out_i        ,
  input   [`SGPR_ID_WIDTH-1:0]          allocator_sgpr_start_out_i       ,
  input   [`SGPR_ID_WIDTH:0]            allocator_sgpr_size_out_i        ,
  input   [`LDS_ID_WIDTH-1:0]           allocator_lds_start_out_i        ,
  input   [`LDS_ID_WIDTH:0]             allocator_lds_size_out_i         ,
  input                                 dis_controller_wg_alloc_valid_i  ,
  input                                 dis_controller_wg_dealloc_valid_i,
  input   [`CU_ID_WIDTH-1:0]            gpu_interface_cu_id_i            ,
  input   [`WG_ID_WIDTH-1:0]            gpu_interface_dealloc_wg_id_i    ,

  output                                grt_cam_up_valid_o               ,
  output  [`WF_COUNT_WIDTH-1:0]         grt_cam_up_wf_count_o            ,
  output  [`CU_ID_WIDTH-1:0]            grt_cam_up_cu_id_o               ,
  output  [`VGPR_ID_WIDTH-1:0]          grt_cam_up_vgpr_strt_o           ,
  output  [`VGPR_ID_WIDTH:0]            grt_cam_up_vgpr_size_o           ,
  output  [`SGPR_ID_WIDTH-1:0]          grt_cam_up_sgpr_strt_o           ,
  output  [`SGPR_ID_WIDTH:0]            grt_cam_up_sgpr_size_o           ,
  output  [`LDS_ID_WIDTH-1:0]           grt_cam_up_lds_strt_o            ,
  output  [`LDS_ID_WIDTH:0]             grt_cam_up_lds_size_o            ,
  output  [`WG_SLOT_ID_WIDTH:0]         grt_cam_up_wg_count_o            ,
  output                                grt_wg_alloc_done_o              ,
  output  [`WG_ID_WIDTH-1:0]            grt_wg_alloc_wg_id_o             ,
  output  [`CU_ID_WIDTH-1:0]            grt_wg_alloc_cu_id_o             ,
  output                                grt_wg_dealloc_done_o            ,
  output  [`WG_ID_WIDTH-1:0]            grt_wg_dealloc_wg_id_o           ,
  output  [`CU_ID_WIDTH-1:0]            grt_wg_dealloc_cu_id_o           
  );

  reg   [`NUMBER_RES_TABLE-1:0]                       done_array                      ;
  reg   [`NUMBER_RES_TABLE*`WF_COUNT_WIDTH-1:0]       wf_count_array                  ;
  reg   [`NUMBER_RES_TABLE*(`WG_SLOT_ID_WIDTH+1)-1:0] wg_count_array                  ;
  reg   [`NUMBER_RES_TABLE*`VGPR_ID_WIDTH-1:0]        vgpr_start_array                ;
  reg   [`NUMBER_RES_TABLE*(`VGPR_ID_WIDTH+1)-1:0]    vgpr_size_array                 ;
  reg   [`NUMBER_RES_TABLE*`SGPR_ID_WIDTH-1:0]        sgpr_start_array                ;
  reg   [`NUMBER_RES_TABLE*(`SGPR_ID_WIDTH+1)-1:0]    sgpr_size_array                 ;
  reg   [`NUMBER_RES_TABLE*`LDS_ID_WIDTH-1:0]         lds_start_array                 ;
  reg   [`NUMBER_RES_TABLE*(`LDS_ID_WIDTH+1)-1:0]     lds_size_array                  ;
  reg   [`NUMBER_RES_TABLE*`WG_ID_WIDTH-1:0]          wg_id_array                     ;
  reg   [`NUMBER_RES_TABLE*`CU_ID_WIDTH-1:0]          cu_id_array                     ;
  reg   [`NUMBER_RES_TABLE-1:0]                       serviced_array                  ;
  reg   [`NUMBER_RES_TABLE-1:0]                       is_alloc_array                  ;
  reg   [`NUMBER_RES_TABLE-1:0]                       done_cancelled_array            ;
  reg   [`NUMBER_RES_TABLE-1:0]                       command_serviced_array_cancelled;
  
  //rt_group input
  wire  [`WG_ID_WIDTH-1:0]                        rt_group_wg_id     ;
  wire  [`CU_ID_WIDTH-`RES_TABLE_ADDR_WIDTH-1:0]  rt_group_cu_id     ;
  wire  [`NUMBER_RES_TABLE-1:0]                   rt_group_alloc_en  ;
  wire  [`NUMBER_RES_TABLE-1:0]                   rt_group_dealloc_en;

  //rt_group output
  wire  [`NUMBER_RES_TABLE-1:0]                       rt_group_res_tbl_done;
  wire  [`NUMBER_RES_TABLE*`WF_COUNT_WIDTH-1:0]       rt_group_wf_count    ;
  wire  [`NUMBER_RES_TABLE*(`WG_SLOT_ID_WIDTH+1)-1:0] rt_group_wg_count    ;
  wire  [`NUMBER_RES_TABLE*`VGPR_ID_WIDTH-1:0]        rt_group_vgpr_start  ;
  wire  [`NUMBER_RES_TABLE*(`VGPR_ID_WIDTH+1)-1:0]    rt_group_vgpr_size   ;
  wire  [`NUMBER_RES_TABLE*`SGPR_ID_WIDTH-1:0]        rt_group_sgpr_start  ;
  wire  [`NUMBER_RES_TABLE*(`SGPR_ID_WIDTH+1)-1:0]    rt_group_sgpr_size   ;
  wire  [`NUMBER_RES_TABLE*`LDS_ID_WIDTH-1:0]         rt_group_lds_start   ;
  wire  [`NUMBER_RES_TABLE*(`LDS_ID_WIDTH+1)-1:0]     rt_group_lds_size    ;

  wire  [`RES_TABLE_ADDR_WIDTH-1:0]               serviced_id          ;
  reg   [`RES_TABLE_ADDR_WIDTH-1:0]               serviced_id_reg      ;
  wire                                            serviced_id_valid    ;
  //reg                                             serviced_id_valid_reg;
  wire  [`NUMBER_RES_TABLE-1:0]                   req                  ;
  wire  [`NUMBER_RES_TABLE-1:0]                   grant                ;
  wire  [`NUMBER_RES_TABLE:0]                     grant_r              ;

  reg                                             grt_cam_up_valid_reg   ;
  reg                                             grt_wg_alloc_done_reg  ;
  reg                                             grt_wg_dealloc_done_reg;

  assign rt_group_wg_id = dis_controller_wg_alloc_valid_i ? allocator_wg_id_out_i : gpu_interface_dealloc_wg_id_i;
  assign rt_group_cu_id = dis_controller_wg_alloc_valid_i ? allocator_cu_id_out_i[`CU_ID_WIDTH-`RES_TABLE_ADDR_WIDTH-1:0] : gpu_interface_cu_id_i[`CU_ID_WIDTH-`RES_TABLE_ADDR_WIDTH-1:0];

  genvar i;
  generate for(i=0;i<`NUMBER_RES_TABLE;i=i+1) begin : A1//有NUMBER_RES_TABLE个resource_table_group
    assign rt_group_alloc_en[i]   = (dis_controller_wg_alloc_valid_i && (allocator_cu_id_out_i[`CU_ID_WIDTH-1:`CU_ID_WIDTH-`RES_TABLE_ADDR_WIDTH] == i)) ? 1'b1 : 1'b0;
    assign rt_group_dealloc_en[i] = (dis_controller_wg_dealloc_valid_i && (gpu_interface_cu_id_i[`CU_ID_WIDTH-1:`CU_ID_WIDTH-`RES_TABLE_ADDR_WIDTH] == i)) ? 1'b1 : 1'b0;

    resource_table_group #(
      .NUMBER_CU(`NUMBER_CU / `NUMBER_RES_TABLE)
    )
    rt_group (
      .clk             (clk                                                                    ),   
      .rst_n           (rst_n                                                                  ),   
                      
      .alloc_en_i      (rt_group_alloc_en[i]                                                   ),       
      .dealloc_en_i    (rt_group_dealloc_en[i]                                                 ),     
      .wg_id_i         (rt_group_wg_id                                                         ),     
      .sub_cu_id_i     (rt_group_cu_id                                                         ),   
      .lds_start_i     (allocator_lds_start_out_i                                              ), 
      .lds_size_i      (allocator_lds_size_out_i                                               ),   
      .vgpr_start_i    (allocator_vgpr_start_out_i                                             ), 
      .vgpr_size_i     (allocator_vgpr_size_out_i                                              ), 
      .sgpr_start_i    (allocator_sgpr_start_out_i                                             ),           
      .sgpr_size_i     (allocator_sgpr_size_out_i                                              ),         
      .wf_count_i      (allocator_wf_count_i                                                   ),     
      .done_cancelled_i(done_cancelled_array[i]                                                ),         
                        
      .res_tbl_done_o  (rt_group_res_tbl_done[i]                                               ),   
      .lds_start_o     (rt_group_lds_start[(i+1)*`LDS_ID_WIDTH-1-:`LDS_ID_WIDTH]               ),             
      .lds_size_o      (rt_group_lds_size[(i+1)*(`LDS_ID_WIDTH+1)-1-:(`LDS_ID_WIDTH+1)]        ),                 
      .vgpr_start_o    (rt_group_vgpr_start[(i+1)*`VGPR_ID_WIDTH-1-:`VGPR_ID_WIDTH]            ),                 
      .vgpr_size_o     (rt_group_vgpr_size[(i+1)*(`VGPR_ID_WIDTH+1)-1-:(`VGPR_ID_WIDTH+1)]     ),                 
      .sgpr_start_o    (rt_group_sgpr_start[(i+1)*`SGPR_ID_WIDTH-1-:`SGPR_ID_WIDTH]            ),         
      .sgpr_size_o     (rt_group_sgpr_size[(i+1)*(`SGPR_ID_WIDTH+1)-1-:(`SGPR_ID_WIDTH+1)]     ),               
      .wf_count_o      (rt_group_wf_count[(i+1)*`WF_COUNT_WIDTH-1-:`WF_COUNT_WIDTH]            ),       
      .wg_count_o      (rt_group_wg_count[(i+1)*(`WG_SLOT_ID_WIDTH+1)-1-:(`WG_SLOT_ID_WIDTH+1)])
      );

    always@(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        wg_id_array[(i+1)*`WG_ID_WIDTH-1-:`WG_ID_WIDTH] <= 'd0;
        cu_id_array[(i+1)*`CU_ID_WIDTH-1-:`CU_ID_WIDTH] <= 'd0;
        command_serviced_array_cancelled[i]             <= 'd0;
        done_cancelled_array[i]                         <= 'd0;
        is_alloc_array[i]                               <= 'd0;
        serviced_array[i]                               <= 'd0;
      end
      else if(dis_controller_wg_alloc_valid_i && (allocator_cu_id_out_i[`CU_ID_WIDTH-1:`CU_ID_WIDTH-`RES_TABLE_ADDR_WIDTH] == i)) begin
        wg_id_array[(i+1)*`WG_ID_WIDTH-1-:`WG_ID_WIDTH] <= allocator_wg_id_out_i;
        cu_id_array[(i+1)*`CU_ID_WIDTH-1-:`CU_ID_WIDTH] <= allocator_cu_id_out_i;
        command_serviced_array_cancelled[i]             <= 1'b1                 ;
        done_cancelled_array[i]                         <= 1'b0                 ;
        is_alloc_array[i]                               <= 1'b1                 ;
      end
      else if(dis_controller_wg_dealloc_valid_i && (gpu_interface_cu_id_i[`CU_ID_WIDTH-1:`CU_ID_WIDTH-`RES_TABLE_ADDR_WIDTH] == i)) begin
        wg_id_array[(i+1)*`WG_ID_WIDTH-1-:`WG_ID_WIDTH] <= gpu_interface_dealloc_wg_id_i;
        cu_id_array[(i+1)*`CU_ID_WIDTH-1-:`CU_ID_WIDTH] <= gpu_interface_cu_id_i        ;
        command_serviced_array_cancelled[i]             <= 1'b1                         ;
        done_cancelled_array[i]                         <= 1'b0                         ;
        is_alloc_array[i]                               <= 1'b0                         ;
      end
      else if(command_serviced_array_cancelled[i]) begin
        serviced_array[i]                   <= 1'b0;
        command_serviced_array_cancelled[i] <= 1'b0;
      end
      else if(serviced_id_valid && (i == serviced_id)) begin
        done_cancelled_array[i] <= 1'b1;
        serviced_array[i]       <= 1'b1;
      end
      else begin
        wg_id_array[(i+1)*`WG_ID_WIDTH-1-:`WG_ID_WIDTH] <= wg_id_array[(i+1)*`WG_ID_WIDTH-1-:`WG_ID_WIDTH]; 
        cu_id_array[(i+1)*`CU_ID_WIDTH-1-:`CU_ID_WIDTH] <= cu_id_array[(i+1)*`CU_ID_WIDTH-1-:`CU_ID_WIDTH];
        command_serviced_array_cancelled[i]             <= command_serviced_array_cancelled[i]            ;
        done_cancelled_array[i]                         <= done_cancelled_array[i]                        ;
        is_alloc_array[i]                               <= is_alloc_array[i]                              ;
        serviced_array[i]                               <= serviced_array[i]                              ;
      end
    end

    //将rt_group输出寄存
    always@(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        done_array[i]                                                        <= 'd0;          
        wf_count_array[(i+1)*`WF_COUNT_WIDTH-1-:`WF_COUNT_WIDTH]             <= 'd0;              
        wg_count_array[(i+1)*(`WG_SLOT_ID_WIDTH+1)-1-:(`WG_SLOT_ID_WIDTH+1)] <= 'd0;                
        vgpr_start_array[(i+1)*`VGPR_ID_WIDTH-1-:`VGPR_ID_WIDTH]             <= 'd0;        
        vgpr_size_array[(i+1)*(`VGPR_ID_WIDTH+1)-1-:(`VGPR_ID_WIDTH+1)]      <= 'd0;              
        sgpr_start_array[(i+1)*`SGPR_ID_WIDTH-1-:`SGPR_ID_WIDTH]             <= 'd0;          
        sgpr_size_array[(i+1)*(`SGPR_ID_WIDTH+1)-1-:(`SGPR_ID_WIDTH+1)]      <= 'd0;            
        lds_start_array[(i+1)*`LDS_ID_WIDTH-1-:`LDS_ID_WIDTH]                <= 'd0;              
        lds_size_array[(i+1)*(`LDS_ID_WIDTH+1)-1-:(`LDS_ID_WIDTH+1)]         <= 'd0;      
      end
      else begin
        done_array[i]                                                        <= rt_group_res_tbl_done[i]                                               ; 
        wf_count_array[(i+1)*`WF_COUNT_WIDTH-1-:`WF_COUNT_WIDTH]             <= rt_group_wf_count[(i+1)*`WF_COUNT_WIDTH-1-:`WF_COUNT_WIDTH]            ;         
        wg_count_array[(i+1)*(`WG_SLOT_ID_WIDTH+1)-1-:(`WG_SLOT_ID_WIDTH+1)] <= rt_group_wg_count[(i+1)*(`WG_SLOT_ID_WIDTH+1)-1-:(`WG_SLOT_ID_WIDTH+1)];         
        vgpr_start_array[(i+1)*`VGPR_ID_WIDTH-1-:`VGPR_ID_WIDTH]             <= rt_group_vgpr_start[(i+1)*`VGPR_ID_WIDTH-1-:`VGPR_ID_WIDTH]            ;       
        vgpr_size_array[(i+1)*(`VGPR_ID_WIDTH+1)-1-:(`VGPR_ID_WIDTH+1)]      <= rt_group_vgpr_size[(i+1)*(`VGPR_ID_WIDTH+1)-1-:(`VGPR_ID_WIDTH+1)]     ;             
        sgpr_start_array[(i+1)*`SGPR_ID_WIDTH-1-:`SGPR_ID_WIDTH]             <= rt_group_sgpr_start[(i+1)*`SGPR_ID_WIDTH-1-:`SGPR_ID_WIDTH]            ;         
        sgpr_size_array[(i+1)*(`SGPR_ID_WIDTH+1)-1-:(`SGPR_ID_WIDTH+1)]      <= rt_group_sgpr_size[(i+1)*(`SGPR_ID_WIDTH+1)-1-:(`SGPR_ID_WIDTH+1)]     ;         
        lds_start_array[(i+1)*`LDS_ID_WIDTH-1-:`LDS_ID_WIDTH]                <= rt_group_lds_start[(i+1)*`LDS_ID_WIDTH-1-:`LDS_ID_WIDTH]               ;         
        lds_size_array[(i+1)*(`LDS_ID_WIDTH+1)-1-:(`LDS_ID_WIDTH+1)]         <= rt_group_lds_size[(i+1)*(`LDS_ID_WIDTH+1)-1-:(`LDS_ID_WIDTH+1)]        ;   
      end
    end  
  end
  endgenerate

  //同时完成取低位为高优先级
  assign req               = done_array & (~serviced_array);
  assign serviced_id_valid = |req                          ;
  assign grant             = grant_r[`NUMBER_RES_TABLE-1:0];

  fixed_pri_arb #(
    .ARB_WIDTH(`NUMBER_RES_TABLE+1)
  )
  U_fixed_pri_arb (
    .req  ({1'b0,req}  ),
    .grant(grant_r     )
    );

  one2bin #(
    .ONE_WIDTH(`NUMBER_RES_TABLE    ),
    .BIN_WIDTH(`RES_TABLE_ADDR_WIDTH)
  )
  U_one2bin (
    .oh (grant      ),
    .bin(serviced_id)
    );

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      serviced_id_reg       <= 'd0;
      //serviced_id_valid_reg <= 'd0;
    end
    else begin
      serviced_id_reg       <= serviced_id      ;
      //serviced_id_valid_reg <= serviced_id_valid;
    end
  end

  //grt output
  assign grt_cam_up_vgpr_strt_o = vgpr_start_array[(serviced_id_reg+1)*`VGPR_ID_WIDTH-1-:`VGPR_ID_WIDTH]           ;
  assign grt_cam_up_vgpr_size_o = vgpr_size_array[(serviced_id_reg+1)*(`VGPR_ID_WIDTH+1)-1-:(`VGPR_ID_WIDTH+1)]     ;
  assign grt_cam_up_sgpr_strt_o = sgpr_start_array[(serviced_id_reg+1)*`SGPR_ID_WIDTH-1-:`SGPR_ID_WIDTH]            ;
  assign grt_cam_up_sgpr_size_o = sgpr_size_array[(serviced_id_reg+1)*(`SGPR_ID_WIDTH+1)-1-:(`SGPR_ID_WIDTH+1)]     ;
  assign grt_cam_up_lds_strt_o  = lds_start_array[(serviced_id_reg+1)*`LDS_ID_WIDTH-1-:`LDS_ID_WIDTH]               ;
  assign grt_cam_up_lds_size_o  = lds_size_array[(serviced_id_reg+1)*(`LDS_ID_WIDTH+1)-1-:(`LDS_ID_WIDTH+1)]        ;
  assign grt_cam_up_wf_count_o  = wf_count_array[(serviced_id_reg+1)*`WF_COUNT_WIDTH-1-:`WF_COUNT_WIDTH]            ;
  assign grt_cam_up_wg_count_o  = wg_count_array[(serviced_id_reg+1)*(`WG_SLOT_ID_WIDTH+1)-1-:(`WG_SLOT_ID_WIDTH+1)];
  assign grt_cam_up_cu_id_o     = cu_id_array[(serviced_id_reg+1)*`CU_ID_WIDTH-1-:`CU_ID_WIDTH]                     ;

  assign grt_wg_alloc_cu_id_o   = cu_id_array[(serviced_id_reg+1)*`CU_ID_WIDTH-1-:`CU_ID_WIDTH]                     ;
  assign grt_wg_alloc_wg_id_o   = wg_id_array[(serviced_id_reg+1)*`WG_ID_WIDTH-1-:`WG_ID_WIDTH]                     ;
  assign grt_wg_dealloc_cu_id_o = cu_id_array[(serviced_id_reg+1)*`CU_ID_WIDTH-1-:`CU_ID_WIDTH]                     ;
  assign grt_wg_dealloc_wg_id_o = wg_id_array[(serviced_id_reg+1)*`WG_ID_WIDTH-1-:`WG_ID_WIDTH]                     ;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      grt_cam_up_valid_reg    <= 'd0; 
      grt_wg_alloc_done_reg   <= 'd0;
      grt_wg_dealloc_done_reg <= 'd0;
    end
    else if(serviced_id_valid) begin
      if(is_alloc_array[serviced_id]) begin
        grt_cam_up_valid_reg              <= 1'b1;
        grt_wg_alloc_done_reg             <= 1'b1;
        grt_wg_dealloc_done_reg           <= 1'b0;
      end
      else begin
        grt_cam_up_valid_reg              <= 1'b1;
        grt_wg_alloc_done_reg             <= 1'b0;
        grt_wg_dealloc_done_reg           <= 1'b1;
      end
    end
    else begin
      grt_cam_up_valid_reg    <= 1'b0; 
      grt_wg_alloc_done_reg   <= 1'b0;
      grt_wg_dealloc_done_reg <= 1'b0;
    end
  end

  assign grt_cam_up_valid_o     = grt_cam_up_valid_reg   ;
  assign grt_wg_alloc_done_o    = grt_wg_alloc_done_reg  ;
  assign grt_wg_dealloc_done_o  = grt_wg_dealloc_done_reg;

endmodule
