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
// Author: Chen, Qixiang
// Description:
`include "define.v"

`timescale 1ns/1ps

module scoreboard(
  input                                   clk                   ,
  input                                   rst_n                 ,

  // ibuffer interface
  input [2-1:0]                           ibuffer_if_sel_alu1_i ,
  input [2-1:0]                           ibuffer_if_sel_alu2_i ,
  input [2-1:0]                           ibuffer_if_sel_alu3_i ,
  input [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] ibuffer_if_reg_idx1_i ,    
  input [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] ibuffer_if_reg_idx2_i ,
  input [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] ibuffer_if_reg_idx3_i ,
  input [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] ibuffer_if_reg_idxw_i ,
  input                                   ibuffer_if_isvec_i    ,
  input                                   ibuffer_if_readmask_i ,
  input [2-1:0]                           ibuffer_if_branch_i   ,
  input                                   ibuffer_if_mask_i     ,
  input                                   ibuffer_if_wxd_i      ,
  input                                   ibuffer_if_wvd_i      ,
  input                                   ibuffer_if_mem_i      ,

  // ibuffer2issue interface
  input [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] if_reg_idxw_i         ,
  input                                   if_wvd_i              ,
  input                                   if_wxd_i              ,
  input [2-1:0]                           if_branch_i           ,
  input                                   if_barrier_i          ,
  input                                   if_fence_i            ,
  input                                   if_fire_i             ,

  // writeback interface
  input [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] wb_v_reg_idxw_i       ,
  input                                   wb_v_wvd_i            ,
  input                                   wb_v_fire_i           ,
  input [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] wb_x_reg_idxw_i       ,
  input                                   wb_x_wxd_i            ,
  input                                   wb_x_fire_i           ,

  // from warp_sche/simt_stack/lsu/opl
  input                                   br_ctrl_i             ,
  input                                   fence_end_i           ,
  input                                   op_col_in_fire_i      ,
  input                                   op_col_out_fire_i     ,

  // to warp_sche
  output                                  delay_o
);

  // define scoreboard
  reg [(1<<(`REGIDX_WIDTH+`REGEXT_WIDTH))-1:0] vectorReg;
  reg [(1<<(`REGIDX_WIDTH+`REGEXT_WIDTH))-1:0] scalarReg;
  reg beqReg;
  reg opcolReg;
  reg fenceReg; // after LSU rebuild, this could be cancelled

  // define conflict types
  reg read_rs1;
  reg read_rs2;
  reg read_rs3;
  reg read_mask;
  reg read_wb;
  reg read_beq;
  reg read_opcol;
  reg read_fence;

  // set and clear vectorReg
  genvar j;
  generate for(j=0;j<(1<<(`REGIDX_WIDTH+`REGEXT_WIDTH));j=j+1) begin:B0
    always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        vectorReg[j] <= 1'b0;
      end   
      else begin
        vectorReg[j] <= (if_fire_i && if_wvd_i && (j==if_reg_idxw_i)) ? 1'b1 : ((wb_v_fire_i && wb_v_wvd_i && (j==wb_v_reg_idxw_i)) ? 1'b0 : vectorReg[j]); 
      end 
    end 
  end
  endgenerate

  // set and clear scalarReg
  genvar i;
  generate for(i=0;i<(1<<(`REGIDX_WIDTH+`REGEXT_WIDTH));i=i+1) begin:B1
    always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        scalarReg[i] <= 1'b0;
      end   
      else begin
        scalarReg[i] <= (if_fire_i && if_wxd_i && (i==if_reg_idxw_i)) ? ((if_reg_idxw_i=='h0) ? 1'b0 : 1'b1) : ((wb_x_fire_i && wb_x_wxd_i && (i==wb_x_reg_idxw_i)) ? 1'b0 : scalarReg[i]); 
      end 
    end 
  end
  endgenerate

  // set and clear beqReg
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      beqReg <= 1'b0;
    end else if(if_fire_i & (if_branch_i!=2'b0 | if_barrier_i)) begin
      beqReg <= 1'b1;
    end else if(br_ctrl_i) begin
      beqReg <= 1'b0;
    end else begin
      beqReg <= beqReg;
    end
  end

  // set and clear opcolReg
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      opcolReg <= 1'b0;
    end else if(op_col_in_fire_i) begin
      opcolReg <= 1'b1;
    end else if(op_col_out_fire_i) begin
      opcolReg <= 1'b0;
    end else begin
      opcolReg <= opcolReg;
    end
  end

  // set and clear fenceReg
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      fenceReg <= 1'b0;
    end else if(if_fire_i & if_fence_i) begin
      fenceReg <= 1'b1;
    end else if(fence_end_i) begin
      fenceReg <= 1'b0;
    end else begin
      fenceReg <= fenceReg;
    end
  end

  // inst in ibuffer read conflict types
  always @(*) begin
    case (ibuffer_if_sel_alu1_i)
      `A1_RS1: read_rs1 = scalarReg[ibuffer_if_reg_idx1_i];
      `A1_VRS1:read_rs1 = vectorReg[ibuffer_if_reg_idx1_i];
      default: read_rs1 = 1'b0;
    endcase
  end

  always @(*) begin
    case (ibuffer_if_sel_alu2_i)
      `A2_RS2: read_rs2 = scalarReg[ibuffer_if_reg_idx2_i];
      `A2_VRS2:read_rs2 = vectorReg[ibuffer_if_reg_idx2_i];
      default: read_rs2 = 1'b0;
    endcase
  end

  always @(*) begin
    case (ibuffer_if_sel_alu3_i)
      `A3_VRS3:read_rs3 = vectorReg[ibuffer_if_reg_idx3_i];
      `A3_SD:  read_rs3 = ibuffer_if_isvec_i & !ibuffer_if_readmask_i ? vectorReg[ibuffer_if_reg_idx3_i] :
                         ibuffer_if_isvec_i ? vectorReg[ibuffer_if_reg_idx2_i] : scalarReg[ibuffer_if_reg_idx2_i];
      `A3_FRS3:read_rs3 = scalarReg[ibuffer_if_reg_idx3_i];
      `A3_PC:  read_rs3 = ibuffer_if_branch_i == `B_R ? scalarReg[ibuffer_if_reg_idx1_i] : 1'b0;
      default: read_rs3 = 1'b0;
    endcase
  end

  always @(*) begin
    read_mask   = (ibuffer_if_mask_i) ? vectorReg[0] : 1'b0;
    read_wb     = ((ibuffer_if_wxd_i) ? scalarReg[ibuffer_if_reg_idxw_i] : 1'b0) | 
                  ((ibuffer_if_wvd_i) ? vectorReg[ibuffer_if_reg_idxw_i] : 1'b0);
    read_beq    = beqReg;
    read_opcol  = opcolReg;
    read_fence  = ibuffer_if_mem_i && fenceReg;
  end

  assign delay_o = read_rs1|read_rs2|read_rs3|read_mask|read_wb|read_beq|read_opcol|read_fence;

endmodule
