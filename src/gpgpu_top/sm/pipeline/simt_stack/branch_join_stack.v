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
// Description:
`timescale 1ns/1ns

`include "define.v"

module branch_join_stack #(
  parameter ADDR_WIDTH = 2
  )
  (
  input                    clk                ,
  input                    rst_n              ,
  input                    push_i             ,
  input                    pop_i              ,
  input  [31:0]            pushdata_recon_pc_i, //reconvergent pc
  input  [31:0]            pushdata_jump_pc_i , //jump pc
  input  [`NUM_THREAD-1:0] pushdata_new_mask_i, //branch thread active mask
  input  [`NUM_THREAD-1:0] thread_mask_i      , //thread active mask
  input  [31:0]            pc_execute_i       , 
  output                   jump_o             ,
  output [31:0]            new_pc_o           ,
  output [`NUM_THREAD-1:0] new_mask_o         ,
  output                   stack_empty_o       
  );

  reg  [ADDR_WIDTH-1:0] rd_ptr,wr_ptr;
  wire [ADDR_WIDTH-1:0] wr_ptr_add1  ;

  //reg [31:0]            stack_mem_rpc [0:`DEPTH_THREAD-1]; 
  //reg [31:0]            stack_mem_jpc [0:`DEPTH_THREAD-1];
  //reg [`NUM_THREAD-1:0] stack_mem_nmk [0:`DEPTH_THREAD-1];
  reg [((`DEPTH_THREAD+22)*32)-1:0] stack_mem_rpc,stack_mem_jpc;
  reg [((`DEPTH_THREAD+22)*`NUM_THREAD)-1:0] stack_mem_nmk;

  wire is_pop;

  //wire stack_empty_o;

  //assign is_pop = (stack_mem_rpc[rd_ptr] == pc_execute_i); // when TOS reconvergence PC = executing PC, 
                                                             // can pop the entry
                                                             // else when they dont't match, do nothing
  assign is_pop = (stack_mem_rpc[(32*(rd_ptr+1)-1)-:32] == pc_execute_i);
 
  assign jump_o = stack_empty_o ? 1'h0 : is_pop && pop_i;

  assign wr_ptr_add1 = wr_ptr + 1'h1;

  assign stack_empty_o = (wr_ptr == 'h0);

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      rd_ptr <= 'h0;
      wr_ptr <= 'h0;
    end 
    else if(push_i) begin
      rd_ptr <= wr_ptr + 'h1;
      wr_ptr <= wr_ptr + 'h2;
    end 
    else if(jump_o) begin
      rd_ptr <= rd_ptr - 'h1;
      wr_ptr <= wr_ptr - 'h1;
    end 
    else begin
      rd_ptr <= rd_ptr;
      wr_ptr <= wr_ptr;
    end 
  end  

  //genvar i;
  //generate for(i=0;i<`DEPTH_THREAD;i=i+1) begin:B1
  //  always @(posedge clk or negedge rst_n) begin
  //    if(!rst_n) begin
  //      stack_mem_rpc[i] <= 'h0;
  //      stack_mem_jpc[i] <= 'h0;
  //      stack_mem_nmk[i] <= 'h0;
  //    end 
  //    else if(push_i) begin
  //      stack_mem_rpc[i] <= ((i == wr_ptr_add1) || (i == wr_ptr)) ? pushdata_recon_pc_i : stack_mem_rpc[i];
  //      stack_mem_jpc[i] <= (i == wr_ptr_add1) ? pushdata_jump_pc_i : 
  //                          ((i == wr_ptr) ? pushdata_recon_pc_i : stack_mem_jpc[i]);
  //      stack_mem_nmk[i] <= (i == wr_ptr_add1) ? pushdata_new_mask_i :                 
  //                          ((i == wr_ptr) ? thread_mask_i : stack_mem_nmk[i]);
  //    end
  //    else begin
  //      stack_mem_rpc[i] <= stack_mem_rpc[i];
  //      stack_mem_jpc[i] <= stack_mem_jpc[i];
  //      stack_mem_nmk[i] <= stack_mem_nmk[i];
  //    end 
  //  end 
  //end 
  //endgenerate
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      stack_mem_rpc <= 'h0;
      stack_mem_jpc <= 'h0;
      stack_mem_nmk <= 'h0;
    end 
    else if(push_i) begin
      stack_mem_rpc[(32*(wr_ptr_add1+1)-1)-:64] <= {pushdata_recon_pc_i,pushdata_recon_pc_i};
      stack_mem_jpc[(32*(wr_ptr_add1+1)-1)-:64] <= {pushdata_jump_pc_i,pushdata_recon_pc_i};
      stack_mem_nmk[(`NUM_THREAD*(wr_ptr_add1+1)-1)-:(`NUM_THREAD*2)] <= {pushdata_new_mask_i,thread_mask_i}; 
    end 
    else begin
      stack_mem_rpc <= stack_mem_rpc;
      stack_mem_jpc <= stack_mem_jpc;
      stack_mem_nmk <= stack_mem_nmk;
    end 
  end 

  assign new_pc_o = stack_empty_o ? 'h0 : stack_mem_jpc[32*(rd_ptr+1)-1-:32];
  assign new_mask_o = stack_empty_o ? 'h0 : stack_mem_nmk[`NUM_THREAD*(rd_ptr+1)-1-:`NUM_THREAD];

endmodule
