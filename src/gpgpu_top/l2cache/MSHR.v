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
// Author: TangYao
// Description:Store the req info and hit failed info

`timescale  1ns/1ns
`include "define.v"
//`include "L2cache_define.v"

module MSHR(
  input                               clk                          ,
  input                               rst_n                        ,
  
  //input allocted signals
  input                               mshr_alloc_valid_i           ,
  //input alloc handshake signals
  input                               mshr_alloc_hit_i             ,
  input [`WAY_BITS-1:0]               mshr_alloc_way_i             ,
  input                               mshr_alloc_dirty_i           ,
  input                               mshr_alloc_flush_i           ,
  input                               mshr_alloc_last_flush_i      ,
  input  [`SET_BITS-1:0]              mshr_alloc_set_i             ,
  //input  [`L2C_BITS-1:0]              mshr_alloc_l2cidx_i          ,
  input  [`OP_BITS-1:0]               mshr_alloc_opcode_i          ,
  input  [`SIZE_BITS-1:0]             mshr_alloc_size_i            ,
  input  [`SOURCE_BITS-1:0]           mshr_alloc_source_i          ,
  input  [`TAG_BITS-1:0]              mshr_alloc_tag_i             ,
  input  [`OFFSET_BITS-1:0]           mshr_alloc_offset_i          ,
  input  [`PUT_BITS-1:0]              mshr_alloc_put_i             ,
  input  [`DATA_BITS-1:0]             mshr_alloc_data_i            ,
  input  [`MASK_BITS-1:0]             mshr_alloc_mask_i            ,
  input  [`PARAM_BITS-1:0]            mshr_alloc_param_i           ,
  
  //output status signals
  output                              mshr_status_hit_o            ,
  output  [`WAY_BITS-1:0]             mshr_status_way_o            ,
  output                              mshr_status_dirty_o          ,
  output                              mshr_status_flush_o          ,
  output                              mshr_status_last_flush_o     ,
  output  [`SET_BITS-1:0]             mshr_status_set_o            ,
  //output  [`L2C_BITS-1:0]             mshr_status_l2cidx_o         ,
  output  [`OP_BITS-1:0]              mshr_status_opcode_o         ,
  output  [`SIZE_BITS-1:0]            mshr_status_size_o           ,
  output  [`SOURCE_BITS-1:0]          mshr_status_source_o         ,
  output  [`TAG_BITS-1:0]             mshr_status_tag_o            ,
  output  [`OFFSET_BITS-1:0]          mshr_status_offset_o         ,
  output  [`PUT_BITS-1:0]             mshr_status_put_o            ,
  output  [`DATA_BITS-1:0]            mshr_status_data_o           ,
  output  [`MASK_BITS-1:0]            mshr_status_mask_o           ,
  output  [`PARAM_BITS-1:0]           mshr_status_param_o          ,
  
  //input valid bool
  input                               mshr_valid_i                 ,
  
  //input mshr_wait bool
  input                               mshr_wait_i                  ,
  
  //input  mixed part
  input                               mshr_mixed_i                 ,
  
  //output  schedule  part
  //schedule part a : Decoupled FullRequest
  input                               mshr_schedule_a_ready_i      ,
  output                              mshr_schedule_a_valid_o      ,
  //input  schedule part handshake signals
  output  [`SET_BITS-1:0]             mshr_schedule_a_set_o        ,
  //output  [`L2C_BITS-1:0]             mshr_schedule_a_l2cidx_o     ,
  output  [`OP_BITS-1:0]              mshr_schedule_a_opcode_o     ,
  output  [`SIZE_BITS-1:0]            mshr_schedule_a_size_o       ,
  output  [`SOURCE_BITS-1:0]          mshr_schedule_a_source_o     ,
  output  [`TAG_BITS-1:0]             mshr_schedule_a_tag_o        ,
  output  [`OFFSET_BITS-1:0]          mshr_schedule_a_offset_o     ,
  output  [`PUT_BITS-1:0]             mshr_schedule_a_put_o        ,
  output  [`DATA_BITS-1:0]            mshr_schedule_a_data_o       ,
  output  [`MASK_BITS-1:0]            mshr_schedule_a_mask_o       ,
  output  [`PARAM_BITS-1:0]           mshr_schedule_a_param_o      ,
  
  //schedule part d  : Decoupled DirectoryResult_lite
  input                               mshr_schedule_d_ready_i      ,
  output                              mshr_schedule_d_valid_o      ,
  //schedule part d handshake signals
  output                              mshr_schedule_d_hit_o        ,
  output  [`WAY_BITS-1:0]             mshr_schedule_d_way_o        ,
  output                              mshr_schedule_d_dirty_o      ,
  output                              mshr_schedule_d_flush_o      ,
  output                              mshr_schedule_d_last_flush_o ,
  output  [`SET_BITS-1:0]             mshr_schedule_d_set_o        ,
  //output  [`L2C_BITS-1:0]             mshr_schedule_d_l2cidx_o     ,
  output  [`OP_BITS-1:0]              mshr_schedule_d_opcode_o     ,
  output  [`SIZE_BITS-1:0]            mshr_schedule_d_size_o       ,
  output  [`SOURCE_BITS-1:0]          mshr_schedule_d_source_o     ,
  output  [`TAG_BITS-1:0]             mshr_schedule_d_tag_o        ,
  output  [`OFFSET_BITS-1:0]          mshr_schedule_d_offset_o     ,
  output  [`PUT_BITS-1:0]             mshr_schedule_d_put_o        ,
  output  [`DATA_BITS-1:0]            mshr_schedule_d_data_o       ,
  output  [`MASK_BITS-1:0]            mshr_schedule_d_mask_o       ,
  output  [`PARAM_BITS-1:0]           mshr_schedule_d_param_o      ,
  
  //schedule  data part   
  output  [`DATA_BITS-1:0]            mshr_schedule_data_o         ,
  
  //output  schedule dir part
  input                               mshr_schedule_dir_ready_i    ,
  output                              mshr_schedule_dir_valid_o    ,
  //schedule part dir handshake signals
  output  [`WAY_BITS-1:0]             mshr_schedule_dir_way_o      ,
  output  [`TAG_BITS-1:0]             mshr_schedule_dir_data_tag_o ,
  output  [`SET_BITS-1:0]             mshr_schedule_dir_set_o      ,
  
  //merge part
  input                               mshr_merge_valid_i           ,
  output                              mshr_merge_ready             ,
  //merge part handshake signals
  input  [`MASK_BITS-1:0]             mshr_merge_mask_i            ,
  input  [`DATA_BITS-1:0]             mshr_merge_data_i            ,    
  input  [`OP_BITS-1:0]               mshr_merge_opcode_i          ,
  input  [`PUT_BITS-1:0]              mshr_merge_put_i             ,
  input  [`SOURCE_BITS-1:0]           mshr_merge_source_i          ,
  
  //sinked part
  input                               mshr_sinked_valid_i          ,
  //sinked part handshake signals
  input  [`OP_BITS-1:0]               mshr_sinked_opcode_i         ,
  input  [`SOURCE_BITS-1:0]           mshr_sinked_source_i         ,
  input  [`DATA_BITS-1:0]             mshr_sinked_data_i            
  );
  parameter writeBytes       = 4             ;
  parameter full_mask_bytes  = 8 * writeBytes;
  
  reg                               mixed_reg                      ;
  reg   [`DATA_BITS-1:0]            data_reg                       ;
  //output status signals
  reg                               request_hit_reg                ;
  reg   [`WAY_BITS-1:0]             request_way_reg                ;
  reg                               request_dirty_reg              ;
  reg                               request_flush_reg              ;
  reg                               request_last_flush_reg         ;
  reg   [`SET_BITS-1:0]             request_set_reg                ;
  //reg   [`L2C_BITS-1:0]             request_l2cidx_reg             ;
  reg   [`OP_BITS-1:0]              request_opcode_reg             ;
  reg   [`SIZE_BITS-1:0]            request_size_reg               ;
  reg   [`SOURCE_BITS-1:0]          request_source_reg             ;
  reg   [`TAG_BITS-1:0]             request_tag_reg                ;
  reg   [`OFFSET_BITS-1:0]          request_offset_reg             ;
  reg   [`PUT_BITS-1:0]             request_put_reg                ;
  reg   [`DATA_BITS-1:0]            request_data_reg               ;
  reg   [`MASK_BITS-1:0]            request_mask_reg               ;
  reg   [`PARAM_BITS-1:0]           request_param_reg              ;
  
  wire [`DATA_BITS-1:0] full_mask;
  
  assign full_mask = {{full_mask_bytes{mshr_merge_mask_i[0]}}, {full_mask_bytes{mshr_merge_mask_i[1]}}, {full_mask_bytes{mshr_merge_mask_i[2]}}, {full_mask_bytes{mshr_merge_mask_i[3]}}};
  
  wire [`DATA_BITS-1:0] merge_data;
  assign merge_data = ( mshr_merge_data_i & full_mask ) | (data_reg & (~full_mask));
  
  reg sche_a_valid  ;//init to 0
  reg sche_dir_valid;//init to 0
  reg sink_d_reg    ;//init to 0
  
  
  //output status signals
  assign   mshr_status_hit_o         =      request_hit_reg        ;
  assign   mshr_status_way_o         =      request_way_reg        ;
  assign   mshr_status_dirty_o       =      request_dirty_reg      ;
  assign   mshr_status_flush_o       =      request_flush_reg      ;
  assign   mshr_status_last_flush_o  =      request_last_flush_reg ;
  assign   mshr_status_set_o         =      request_set_reg        ;
  //assign   mshr_status_l2cidx_o      =      request_l2cidx_reg     ;
  assign   mshr_status_opcode_o      =      request_opcode_reg     ;
  assign   mshr_status_size_o        =      request_size_reg       ;
  assign   mshr_status_source_o      =      request_source_reg     ;
  assign   mshr_status_tag_o         =      request_tag_reg        ;
  assign   mshr_status_offset_o      =      request_offset_reg     ;
  assign   mshr_status_put_o         =      request_put_reg        ;
  assign   mshr_status_data_o        =      request_data_reg       ;
  assign   mshr_status_mask_o        =      request_mask_reg       ;
  assign   mshr_status_param_o       =      request_param_reg      ;
  
  always @(posedge clk or negedge rst_n) begin
    if(~rst_n) 
      begin
        request_hit_reg        <= 0;
        request_way_reg        <= 0;
        request_dirty_reg      <= 0;
        request_flush_reg      <= 0;
        request_last_flush_reg <= 0;
        request_set_reg        <= 0;
  //      request_l2cidx_reg     <= 0;
        request_opcode_reg     <= 0;
        request_size_reg       <= 0;
        request_source_reg     <= 0;
        request_tag_reg        <= 0;
        request_offset_reg     <= 0;
        request_put_reg        <= 0;
        request_data_reg       <= 0;
        request_mask_reg       <= 0;
        request_param_reg      <= 0;
        sink_d_reg             <= 0;
      end
    else if(mshr_alloc_valid_i)
      begin
        request_hit_reg        <= mshr_alloc_hit_i            ;
        request_way_reg        <= mshr_alloc_way_i            ;
        request_dirty_reg      <= mshr_alloc_dirty_i          ;
        request_flush_reg      <= mshr_alloc_flush_i          ;
        request_last_flush_reg <= mshr_alloc_last_flush_i     ;
        request_set_reg        <= mshr_alloc_set_i            ;
  //      request_l2cidx_reg     <= mshr_alloc_l2cidx_i         ;
        request_opcode_reg     <= mshr_alloc_opcode_i         ;
        request_size_reg       <= mshr_alloc_size_i           ;
        request_source_reg     <= mshr_alloc_source_i         ;
        request_tag_reg        <= mshr_alloc_tag_i            ;
        request_offset_reg     <= mshr_alloc_offset_i         ;
        request_put_reg        <= mshr_alloc_put_i            ;
        request_data_reg       <= mshr_alloc_data_i           ;
        request_mask_reg       <= mshr_alloc_mask_i           ;
        request_param_reg      <= mshr_alloc_param_i          ;
        sink_d_reg             <= 0;
      end
    else if(mshr_sinked_valid_i)
      sink_d_reg             <= 1'b1;
    else
      begin
        request_hit_reg        <=         request_hit_reg        ;
        request_way_reg        <=         request_way_reg        ;
        request_dirty_reg      <=         request_dirty_reg      ;
        request_flush_reg      <=         request_flush_reg      ;
        request_last_flush_reg <=         request_last_flush_reg ;
        request_set_reg        <=         request_set_reg        ;
  //      request_l2cidx_reg     <=         request_l2cidx_reg     ;
        request_opcode_reg     <=         request_opcode_reg     ;
        request_size_reg       <=         request_size_reg       ;
        request_source_reg     <=         request_source_reg     ;
        request_tag_reg        <=         request_tag_reg        ;
        request_offset_reg     <=         request_offset_reg     ;
        request_put_reg        <=         request_put_reg        ;
        request_data_reg       <=         request_data_reg       ;
        request_mask_reg       <=         request_mask_reg       ;
        request_param_reg      <=         request_param_reg      ;
      end
  end
  
  always @(posedge clk or negedge rst_n) begin
    if(~rst_n) 
      begin
        data_reg <= 0;
      end
    else if(mshr_alloc_valid_i)
      begin
        data_reg <= mshr_alloc_data_i;
      end
    else if(mshr_merge_valid_i)
      begin
        data_reg <= merge_data;
      end 
    else if(mshr_sinked_valid_i)
      begin
        data_reg <= mshr_sinked_data_i;
      end
    else data_reg<= data_reg;
  end
  
  assign mshr_schedule_d_valid_o      = mshr_valid_i && sink_d_reg     ; //为了使得最后全弹出来才拉低，需要知道这个MSHR是否还有效
  assign mshr_schedule_d_hit_o        = 1'b0                           ;//  io.schedule.d.bits.hit := false.B
  assign mshr_schedule_d_way_o        = request_way_reg                ;
  assign mshr_schedule_d_dirty_o      = 1'b0                           ;//  io.schedule.d.bits.dirty := false.B
  assign mshr_schedule_d_flush_o      = request_flush_reg              ;
  assign mshr_schedule_d_last_flush_o = request_last_flush_reg         ;
  assign mshr_schedule_d_set_o        = request_set_reg                ;
  //assign mshr_schedule_d_l2cidx_o     = request_l2cidx_reg             ;
  assign mshr_schedule_d_opcode_o     = request_opcode_reg             ;
  assign mshr_schedule_d_size_o       = request_size_reg               ;
  assign mshr_schedule_d_source_o     = request_source_reg             ;
  assign mshr_schedule_d_tag_o        = request_tag_reg                ;
  assign mshr_schedule_d_offset_o     = request_offset_reg             ;
  assign mshr_schedule_d_put_o        = request_put_reg                ;
  assign mshr_schedule_d_data_o       = data_reg                       ;//io.schedule.d.bits.data := data_reg
  assign mshr_schedule_d_mask_o       = request_mask_reg               ;
  assign mshr_schedule_d_param_o      = request_param_reg              ;
  
  assign mshr_schedule_data_o         = data_reg                       ;//io.schedule.data := data_reg
  
  //process for schedule a part
  assign mshr_schedule_a_valid_o = sche_a_valid && !mshr_wait_i;
  assign mshr_schedule_a_set_o   = request_set_reg             ;
  assign mshr_schedule_a_opcode_o= `GET                        ;
  assign mshr_schedule_a_tag_o   = request_tag_reg             ;
  //assign mshr_schedule_a_l2cidx_o= request_l2cidx_reg        ;
  assign mshr_schedule_a_param_o = request_param_reg           ;
  assign mshr_schedule_a_put_o   = request_put_reg             ;
  assign mshr_schedule_a_offset_o= request_offset_reg          ;
  assign mshr_schedule_a_source_o= request_source_reg          ;
  assign mshr_schedule_a_data_o  = request_data_reg            ;
  assign mshr_schedule_a_size_o  = request_size_reg            ;
  assign mshr_schedule_a_mask_o  = {`MASK_BITS{1'b1}}          ;
  
  always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
      sche_a_valid <= 0; 
    end 
    else if(mshr_schedule_a_valid_o && mshr_schedule_a_ready_i) begin
      sche_a_valid <= 1'b0;
    end
    else if (mshr_alloc_valid_i) begin
      sche_a_valid <= 1'b1;
    end
    else sche_a_valid <= sche_a_valid;
  end

  always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
      sche_dir_valid <= 0;  
    end
    else if(mshr_alloc_valid_i) begin
      sche_dir_valid <= 1'b0;
    end
    else if(mshr_schedule_dir_ready_i && mshr_schedule_dir_valid_o) begin
      sche_dir_valid <= 1'b0;
    end
    else if(mshr_mixed_i) begin
      sche_dir_valid <= 1'b0;
    end
    else if(mshr_sinked_valid_i && !(mshr_mixed_i ||mixed_reg )) begin
      sche_dir_valid <= 1'b1;
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
      mixed_reg <= 0;  
    end
    else if(mshr_alloc_valid_i) begin
      mixed_reg <= 1'b0;
    end
    else if(mshr_mixed_i) begin
      mixed_reg <= 1'b1;
    end
    else mixed_reg <= mixed_reg;
  end
  
  assign mshr_schedule_dir_valid_o    = sche_dir_valid && (request_opcode_reg == `GET );
  assign mshr_schedule_dir_set_o      = request_set_reg                                ;
  assign mshr_schedule_dir_data_tag_o = request_tag_reg                                ;
  assign mshr_schedule_dir_way_o      = request_way_reg                                ;

endmodule
