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
// Author: Zhang, Qi
// Description:control model

`timescale 1ns/1ns

module dis_controller #(
  parameter NUMBER_CU             = 2                        ,
  parameter CU_ID_WIDTH           = 2                        ,
  parameter RES_TABLE_ADDR_WIDTH  = 1                        ,
  parameter NUMBER_RES_TABLE      = 1 << RES_TABLE_ADDR_WIDTH 
  )
  (
  input                    clk                                 ,
  input                    rst_n                               ,

  input                    inflight_wg_buffer_alloc_valid_i    ,
  input                    inflight_wg_buffer_alloc_available_i,
  input                    allocator_cu_valid_i                ,
  input                    allocator_cu_rejected_i             ,
  input  [CU_ID_WIDTH-1:0] allocator_cu_id_out_i               ,
  input                    grt_wg_alloc_done_i                 ,
  input                    grt_wg_dealloc_done_i               ,
  input  [CU_ID_WIDTH-1:0] grt_wg_alloc_cu_id_i                ,
  input  [CU_ID_WIDTH-1:0] grt_wg_dealloc_cu_id_i              ,
  input                    gpu_interface_alloc_available_i     ,
  input                    gpu_interface_dealloc_available_i   ,
  input  [CU_ID_WIDTH-1:0] gpu_interface_cu_id_i               ,

  output                   dis_controller_start_alloc_o        ,
  output                   dis_controller_alloc_ack_o          ,
  output                   dis_controller_wg_alloc_valid_o     ,
  output                   dis_controller_wg_dealloc_valid_o   ,
  output                   dis_controller_wg_rejected_valid_o  ,
  output [NUMBER_CU-1:0]   dis_controller_cu_busy_o              
  );

  parameter ALLOC_NUM_STATES      = 'h4;

  parameter ST_AL_IDLE            = 4'h0,
            ST_AL_ALLOC           = 4'h2,
            ST_AL_HANDLE_RESULT   = 4'h4,
            ST_AL_ACK_PROPAGATION = 4'h8;                         

  reg [ALLOC_NUM_STATES-1:0] alloc_st;
  wire [NUMBER_CU-1:0] cus_allocating;
  reg [NUMBER_RES_TABLE- 1:0] cu_groups_allocating;
  reg [CU_ID_WIDTH-1:0] alloc_waiting_cu_id;
  reg alloc_waiting;
  reg dis_controller_start_alloc_i;
  reg dis_controller_alloc_ack_i; 
  reg dis_controller_wg_alloc_valid_i; 
  reg dis_controller_wg_dealloc_valid_i; 
  reg dis_controller_wg_rejected_valid_i; 
  wire [RES_TABLE_ADDR_WIDTH-1:0] gpu_interface_cu_res_tbl_addr;

  assign dis_controller_start_alloc_o       = dis_controller_start_alloc_i;
  assign dis_controller_alloc_ack_o         = dis_controller_alloc_ack_i; 
  assign dis_controller_wg_alloc_valid_o    = dis_controller_wg_alloc_valid_i; 
  assign dis_controller_wg_dealloc_valid_o  = dis_controller_wg_dealloc_valid_i; 
  assign dis_controller_wg_rejected_valid_o = dis_controller_wg_rejected_valid_i; 

  assign gpu_interface_cu_res_tbl_addr = gpu_interface_cu_id_i[CU_ID_WIDTH-1:CU_ID_WIDTH-RES_TABLE_ADDR_WIDTH];

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      alloc_st <= ST_AL_IDLE;
      alloc_waiting_cu_id <= 'h0;
      dis_controller_start_alloc_i <= 'h0;
      dis_controller_alloc_ack_i <= 'h0;
    end 
    else begin
      case(alloc_st)
      ST_AL_IDLE            : 
                              begin
                                if(inflight_wg_buffer_alloc_valid_i && !(&cu_groups_allocating)) begin
                                  alloc_st <= ST_AL_ALLOC;
                                  alloc_waiting_cu_id <= alloc_waiting_cu_id;
                                  dis_controller_start_alloc_i <= 'h1;
                                  dis_controller_alloc_ack_i <= 'h0;
                                end 
                                else begin
                                  alloc_st <= alloc_st;
                                  alloc_waiting_cu_id <= alloc_waiting_cu_id;
                                  dis_controller_start_alloc_i <= 'h0;
                                  dis_controller_alloc_ack_i <= 'h0;
                                end 
                              end 
      ST_AL_ALLOC           :   
                              begin
                                if(allocator_cu_valid_i) begin
                                  alloc_st <= ST_AL_HANDLE_RESULT;
                                  alloc_waiting_cu_id <= allocator_cu_id_out_i;
                                  dis_controller_start_alloc_i <= 'h0;
                                  dis_controller_alloc_ack_i <= 'h0;
                                end 
                                else begin
                                  alloc_st <= alloc_st;
                                  alloc_waiting_cu_id <= alloc_waiting_cu_id;
                                  dis_controller_start_alloc_i <= 'h0;
                                  dis_controller_alloc_ack_i <= 'h0;
                                end 
                              end 
      ST_AL_HANDLE_RESULT   :   
                              begin
                                if(!alloc_waiting) begin
                                  alloc_st <= ST_AL_ACK_PROPAGATION;
                                  alloc_waiting_cu_id <= alloc_waiting_cu_id;
                                  dis_controller_start_alloc_i <= 'h0;
                                  dis_controller_alloc_ack_i <= 'h1;
                                end 
                                else begin
                                  alloc_st <= alloc_st;
                                  alloc_waiting_cu_id <= alloc_waiting_cu_id;
                                  dis_controller_start_alloc_i <= 'h0;
                                  dis_controller_alloc_ack_i <= 'h0;
                                end 
                              end 
      ST_AL_ACK_PROPAGATION : 
                              begin
                                alloc_st <= ST_AL_IDLE;
                                alloc_waiting_cu_id <= alloc_waiting_cu_id;
                                dis_controller_start_alloc_i <= 'h0;
                                dis_controller_alloc_ack_i <= 'h0;
                              end 
      default               :
                              begin
                                alloc_st <= ST_AL_IDLE;
                                alloc_waiting_cu_id <= alloc_waiting_cu_id;
                                dis_controller_start_alloc_i <= 'h0;
                                dis_controller_alloc_ack_i <= 'h0;
                              end 
      endcase
    end 
  end 

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      dis_controller_wg_dealloc_valid_i <= 'h0;
      dis_controller_wg_alloc_valid_i <= 'h0;
      dis_controller_wg_rejected_valid_i <= 'h0;
    end   
    else if(gpu_interface_dealloc_available_i && !cu_groups_allocating[gpu_interface_cu_res_tbl_addr]) begin
      dis_controller_wg_dealloc_valid_i <= 'h1;
      dis_controller_wg_alloc_valid_i <= 'h0;
      dis_controller_wg_rejected_valid_i <= 'h0;
    end 
    else if(alloc_waiting && !cu_groups_allocating[alloc_waiting_cu_id[CU_ID_WIDTH-1:CU_ID_WIDTH-RES_TABLE_ADDR_WIDTH]]) begin
      if(allocator_cu_rejected_i) begin
        dis_controller_wg_dealloc_valid_i <= 'h0;
        dis_controller_wg_alloc_valid_i <= 'h0;
        dis_controller_wg_rejected_valid_i <= 'h1;
      end 
      else if(gpu_interface_alloc_available_i && inflight_wg_buffer_alloc_available_i) begin
        dis_controller_wg_dealloc_valid_i <= 'h0;
        dis_controller_wg_alloc_valid_i <= 'h1;
        dis_controller_wg_rejected_valid_i <= 'h0;
      end 
      else begin
        dis_controller_wg_dealloc_valid_i <= 'h0;
        dis_controller_wg_alloc_valid_i <= 'h0;
        dis_controller_wg_rejected_valid_i <= 'h0;
      end 
    end 
    else begin
      dis_controller_wg_dealloc_valid_i <= 'h0;
      dis_controller_wg_alloc_valid_i <= 'h0;
      dis_controller_wg_rejected_valid_i <= 'h0;
    end 
  end 

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      alloc_waiting <= 'h0;
    end 
    else if((alloc_st == ST_AL_ALLOC) && allocator_cu_valid_i) begin
      alloc_waiting <= 'h1;
    end 
    else if(alloc_waiting && !cu_groups_allocating[alloc_waiting_cu_id[CU_ID_WIDTH-1:CU_ID_WIDTH-RES_TABLE_ADDR_WIDTH]]) begin
      alloc_waiting <= 'h0;
    end 
    else begin
      alloc_waiting <= alloc_waiting;
    end 
  end 

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      cu_groups_allocating <= 'h0;
    end 
    else if(gpu_interface_dealloc_available_i && !cu_groups_allocating[gpu_interface_cu_res_tbl_addr]) begin
      cu_groups_allocating[gpu_interface_cu_res_tbl_addr] <= 'h1;
    end
    else if(alloc_waiting && !cu_groups_allocating[alloc_waiting_cu_id[CU_ID_WIDTH-1:CU_ID_WIDTH-RES_TABLE_ADDR_WIDTH]]
            && allocator_cu_rejected_i) begin
      cu_groups_allocating <= cu_groups_allocating;
    end
    else if(alloc_waiting && !cu_groups_allocating[alloc_waiting_cu_id[CU_ID_WIDTH-1:CU_ID_WIDTH-RES_TABLE_ADDR_WIDTH]] 
            && gpu_interface_alloc_available_i && inflight_wg_buffer_alloc_available_i) begin
      cu_groups_allocating[alloc_waiting_cu_id[CU_ID_WIDTH-1:CU_ID_WIDTH-RES_TABLE_ADDR_WIDTH]] <= 'h1;
    end 
    else if(grt_wg_alloc_done_i) begin
      cu_groups_allocating[grt_wg_alloc_cu_id_i[CU_ID_WIDTH-1:CU_ID_WIDTH-RES_TABLE_ADDR_WIDTH]] <= 'h0;
    end 
    else if(grt_wg_dealloc_done_i) begin
      cu_groups_allocating[grt_wg_dealloc_cu_id_i[CU_ID_WIDTH-1:CU_ID_WIDTH-RES_TABLE_ADDR_WIDTH]] <= 'h0;
    end 
    else begin
      cu_groups_allocating <= cu_groups_allocating;
    end 
  end   

  genvar i;
  generate for(i=0;i<NUMBER_CU;i=i+1) begin:B1
    assign cus_allocating[i] = cu_groups_allocating[(i>>(CU_ID_WIDTH-RES_TABLE_ADDR_WIDTH))];
  end
  endgenerate 

  assign dis_controller_cu_busy_o = cus_allocating;

endmodule
