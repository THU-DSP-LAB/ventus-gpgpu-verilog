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

module simt_stack (
  input                    clk                    ,
  input                    rst_n                  ,

  output                   branch_ctl_ready_o     ,
  input                    branch_ctl_valid_i     ,
  input                    branch_ctl_opcode_i    , //1 -> join / 0 -> branch
  input  [`DEPTH_WARP-1:0] branch_ctl_wid_i       , 
  input  [31:0]            branch_ctl_pc_branch_i , 
  input  [31:0]            branch_ctl_pc_execute_i, //executing pc
  input  [`NUM_THREAD-1:0] branch_ctl_mask_init_i ,

  output                   if_mask_ready_o        ,
  input                    if_mask_valid_i        ,
  input  [`NUM_THREAD-1:0] if_mask_mask_i         , //if mask
  input  [`DEPTH_WARP-1:0] if_mask_wid_i          ,

  input                    pc_reconv_valid_i      ,
  input  [`XLEN-1:0]       pc_reconv_i            , //reconv pc

  input  [`DEPTH_WARP-1:0] input_wid_i            ,
  output [`NUM_THREAD-1:0] out_mask_o             ,

  output                   complete_valid_o       ,
  output [`DEPTH_WARP-1:0] complete_wid_o         ,

  input                    fetch_ctl_ready_i      ,
  output                   fetch_ctl_valid_o      ,
  output [`DEPTH_WARP-1:0] fetch_ctl_wid_o        ,
  output                   fetch_ctl_jump_o       ,
  output [31:0]            fetch_ctl_new_pc_o        
  );

  wire branch_ctl_buf_fire;
  reg  branch_ctl_buf_ready_i;
  wire branch_ctl_buf_valid_o;
  wire branch_ctl_buf_opcode_o;    
  wire [`DEPTH_WARP-1:0] branch_ctl_buf_wid_o;      
  wire [31:0] branch_ctl_buf_pc_branch_o; 
  wire [31:0] branch_ctl_buf_pc_execute_o;
  wire [`NUM_THREAD-1:0] branch_ctl_buf_mask_init_o;  
  wire [(1+`DEPTH_WARP+32+32+`NUM_THREAD)-1:0] branch_ctl_buf_i;
  wire [(1+`DEPTH_WARP+32+32+`NUM_THREAD)-1:0] branch_ctl_buf_o; 

  //wire if_mask_buf_fire;
  //wire if_mask_buf_ready_i;
  //wire if_mask_buf_valid_o;
  //wire [`NUM_THREAD-1:0] if_mask_buf_mask_o;
  //wire [`DEPTH_WARP-1:0] if_mask_buf_wid_o;
  //wire [`NUM_THREAD+`DEPTH_WARP-1:0] if_mask_buf_i;
  //wire [`NUM_THREAD+`DEPTH_WARP-1:0] if_mask_buf_o;

  wire pc_reconv_ready_o;
  wire pc_reconv_buf_valid_o;
  reg  pc_reconv_buf_ready_i;
  wire [`XLEN-1:0] pc_reconv_buf_o;

  wire fetch_ctl_buf_ready_o;
  reg  fetch_ctl_buf_valid_i;
  reg  fetch_ctl_buf_jump_i;
  reg  [31:0] fetch_ctl_buf_new_pc_i;
  wire [`DEPTH_WARP+32+1-1:0] fetch_ctl_buf_i;
  wire [`DEPTH_WARP+32+1-1:0] fetch_ctl_buf_o;

  //reg [`NUM_THREAD-1:0] thread_masks [0:`NUM_WARP-1];
  reg [`NUM_WARP*`NUM_THREAD-1:0] thread_masks;

  wire [`NUM_THREAD-1:0] if_mask,else_mask;
  wire if_only,else_only,div_occur;
                                   
  wire [`DEPTH_THREAD:0] if_cnt,else_cnt; // the number of 1 in the if_mask or else_mask
  wire take_if; 

  //wire push [0:`NUM_WARP-1];
  //wire pop [0:`NUM_WARP-1];
  //wire bj_jump [0:`NUM_WARP-1];
  wire [`NUM_WARP-1:0] push;
  wire [`NUM_WARP-1:0] pop;
  wire [`NUM_WARP-1:0] bj_jump;
  wire [31:0] bj_pc [0:`NUM_WARP-1];
  wire [`NUM_THREAD-1:0] bj_mask [0:`NUM_WARP-1];
  wire bj_empty [0:`NUM_WARP-1];

  reg [31:0]            pushdata_jump_pc ;
  reg [`NUM_THREAD-1:0] pushdata_new_mask;

  assign branch_ctl_buf_i = {branch_ctl_mask_init_i,branch_ctl_pc_execute_i,
                             branch_ctl_pc_branch_i,branch_ctl_wid_i,
                             branch_ctl_opcode_i};

  assign {branch_ctl_buf_mask_init_o,branch_ctl_buf_pc_execute_o,
          branch_ctl_buf_pc_branch_o,branch_ctl_buf_wid_o,
          branch_ctl_buf_opcode_o} = branch_ctl_buf_o;

  assign branch_ctl_buf_fire = branch_ctl_buf_ready_i && branch_ctl_buf_valid_o;

  //assign if_mask_buf_i = {if_mask_wid_i,if_mask_mask_i};
  //assign {if_mask_buf_wid_o,if_mask_buf_mask_o} = if_mask_buf_o;
  //assign {if_mask_buf_wid_o,if_mask_buf_mask_o} = if_mask_buf_i;
  //assign if_mask_buf_wid_o = if_mask_wid_i;
  //assign if_mask_buf_mask_o = if_mask_mask_i;
  //assign if_mask_buf_ready_i = fetch_ctl_buf_ready_o;
  assign if_mask_ready_o = fetch_ctl_buf_ready_o;
  //assign if_mask_buf_fire = if_mask_buf_ready_i && if_mask_buf_valid_o;
  assign if_mask_buf_fire = if_mask_ready_o && if_mask_valid_i;

  //******  output fetch control  ********
  //issue fetch request when: 
  //1. branch happen and take else path  
  //2. join happen and jump indeed happen
  assign fetch_ctl_buf_i = {fetch_ctl_buf_new_pc_i,fetch_ctl_buf_jump_i,branch_ctl_buf_wid_o};
  assign {fetch_ctl_new_pc_o,fetch_ctl_jump_o,fetch_ctl_wid_o} = fetch_ctl_buf_o;

  always @(*) begin
    if(branch_ctl_buf_opcode_o && branch_ctl_buf_valid_o) begin
      fetch_ctl_buf_new_pc_i = (bj_jump[branch_ctl_buf_wid_o]) ? bj_pc[branch_ctl_buf_wid_o] : 'h0;
      fetch_ctl_buf_jump_i = (bj_jump[branch_ctl_buf_wid_o]) ? 'h1 : 'h0;
      fetch_ctl_buf_valid_i = 'h1;
    end
    else if((!branch_ctl_buf_opcode_o) && branch_ctl_buf_valid_o && if_mask_valid_i && ((!take_if) || else_only)) begin
      fetch_ctl_buf_new_pc_i = branch_ctl_buf_pc_branch_o;
      fetch_ctl_buf_jump_i = 'h1;
      fetch_ctl_buf_valid_i = 'h1;
    end
    else begin
      fetch_ctl_buf_new_pc_i = 'h0;
      fetch_ctl_buf_jump_i = 'h0;
      fetch_ctl_buf_valid_i = 'h0;
    end 
  end 

  assign complete_valid_o = (if_mask_buf_fire && (!branch_ctl_buf_opcode_o) && branch_ctl_buf_valid_o && take_if);
  assign complete_wid_o = branch_ctl_buf_wid_o; 

  always @(*) begin
    if(fetch_ctl_buf_ready_o) begin
      if(branch_ctl_buf_valid_o && (!branch_ctl_buf_opcode_o) && (branch_ctl_buf_wid_o == if_mask_wid_i)) begin
        branch_ctl_buf_ready_i = if_mask_buf_fire;
        pc_reconv_buf_ready_i = if_mask_buf_fire;
      end 
      else if(branch_ctl_buf_valid_o && branch_ctl_buf_opcode_o) begin
        branch_ctl_buf_ready_i = 1'h1;
        pc_reconv_buf_ready_i = 1'h1;
      end
      else begin
        branch_ctl_buf_ready_i = 1'h0;
        pc_reconv_buf_ready_i = 1'h0;
      end
    end 
    else begin
      branch_ctl_buf_ready_i = 1'h0;
      pc_reconv_buf_ready_i = 1'h0;
    end 
  end 

  assign if_mask = if_mask_mask_i & branch_ctl_buf_mask_init_o;
  assign else_mask = (~if_mask) & branch_ctl_buf_mask_init_o;

  assign take_if = ((if_cnt < else_cnt) && div_occur) || if_only; // take if first if thread take if path is less than thread take else
  assign if_only = (else_mask == 'h0);
  assign else_only = (if_mask == 'h0);
  assign div_occur = !(if_only || else_only);// div_occur indicate that true divergence occurs, 
                                             // that is, nether if_mask nor else_mask is all zero
  always @(*) begin
    if(take_if) begin
      pushdata_new_mask = else_mask;
      pushdata_jump_pc = branch_ctl_buf_pc_branch_o;
    end
    else begin
      pushdata_new_mask = if_mask;
      pushdata_jump_pc = branch_ctl_buf_pc_execute_o + 3'h4;
    end 
  end 

  genvar i;
  generate for(i=0;i<`NUM_WARP;i=i+1) begin:B1
    assign push[i] = (!branch_ctl_buf_opcode_o) && branch_ctl_buf_fire && (i == branch_ctl_buf_wid_o) && div_occur; 
    assign pop[i] = (branch_ctl_buf_opcode_o) && branch_ctl_buf_fire && (i == branch_ctl_buf_wid_o); //just indicating this is join, maybe not pop, 

    branch_join_stack #(
      .ADDR_WIDTH($clog2(`DEPTH_THREAD)+20)
      ) bjstack(
      .clk                (clk                                              ),
      .rst_n              (rst_n                                            ),
      .push_i             (push[i]                                          ),
      .pop_i              (pop[i]                                           ),
      .pushdata_recon_pc_i(pc_reconv_buf_o                                  ),
      .pushdata_jump_pc_i (pushdata_jump_pc                                 ),
      .pushdata_new_mask_i(pushdata_new_mask                                ),
      .thread_mask_i      (thread_masks[(`NUM_THREAD*(i+1)-1)-:`NUM_THREAD] ),
      .pc_execute_i       (branch_ctl_buf_pc_execute_o                      ),
      .jump_o             (bj_jump[i]                                       ),
      .new_pc_o           (bj_pc[i]                                         ),
      .new_mask_o         (bj_mask[i]                                       ),
      .stack_empty_o      (bj_empty[i]                                      )
      ); 
  end 
  endgenerate

  //************************thread mask register control************************
  //when branch indeed happened, put executing mask into corresponding register
  //when join indeed happened, put new mask into corresponding register
  //genvar j;
  //generate for(j=0;j<`NUM_WARP;j=j+1) begin:B2
  //  always @(posedge clk or negedge rst_n) begin
  //    if(!rst_n) begin
  //      thread_masks[j] <= {`NUM_THREAD{1'h1}};
  //    end 
  //    else if(if_mask_buf_fire && div_occur) begin
  //      thread_masks[branch_ctl_buf_wid_o] <= (take_if) ? if_mask : else_mask;
  //    end
  //    else if(branch_ctl_buf_opcode_o && branch_ctl_buf_valid_o && bj_jump[branch_ctl_buf_wid_o]) begin
  //      thread_masks[branch_ctl_buf_wid_o] <= bj_mask[branch_ctl_buf_wid_o];
  //    end
  //    else begin
  //      thread_masks[j] <= thread_masks[j];
  //    end 
  //  end 
  //end 
  //endgenerate
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      thread_masks <= {`NUM_WARP*`NUM_THREAD{1'h1}};
    end 
    else if(if_mask_buf_fire && div_occur) begin
      thread_masks[(`NUM_THREAD*(branch_ctl_buf_wid_o+1)-1)-:`NUM_THREAD] <= (take_if) ? if_mask : else_mask; 
    end 
    else if(branch_ctl_buf_opcode_o && branch_ctl_buf_valid_o && bj_jump[branch_ctl_buf_wid_o]) begin
      thread_masks[(`NUM_THREAD*(branch_ctl_buf_wid_o+1)-1)-:`NUM_THREAD] <= bj_mask[branch_ctl_buf_wid_o];
    end
    else if(bj_empty[branch_ctl_buf_wid_o]) begin
      thread_masks[(`NUM_THREAD*(branch_ctl_buf_wid_o+1)-1)-:`NUM_THREAD] <= {`NUM_THREAD{1'h1}};
    end 
    else begin
      thread_masks <= thread_masks;
    end 
  end 

  assign out_mask_o = thread_masks[(`NUM_THREAD*(input_wid_i+1)-1)-:`NUM_THREAD];

  //stream_fifo_flow_true #(
  stream_fifo #(
    .DATA_WIDTH(1+`DEPTH_WARP+32+32+`NUM_THREAD),
    .FIFO_DEPTH(1                              )
    ) branch_ctl_buf(
    .clk      (clk                   ),
    .rst_n    (rst_n                 ),
             
    .w_ready_o(branch_ctl_ready_o    ),
    .w_valid_i(branch_ctl_valid_i    ),
    .w_data_i (branch_ctl_buf_i      ),
             
    .r_valid_o(branch_ctl_buf_valid_o),
    .r_ready_i(branch_ctl_buf_ready_i),
    .r_data_o (branch_ctl_buf_o      )
    );   

  //stream_fifo_entry_zero #(
  //  .DATA_WIDTH(`NUM_THREAD+`DEPTH_WARP)
  //  ) if_mask_buf(
  //  .w_ready_o(if_mask_ready_o    ),
  //  .w_valid_i(if_mask_valid_i    ),
  //  .w_data_i (if_mask_buf_i      ),
  //           
  //  .r_valid_o(if_mask_buf_valid_o),
  //  .r_ready_i(if_mask_buf_ready_i),
  //  .r_data_o (if_mask_buf_o      )
  //  );

  //stream_fifo_flow_true #(
  stream_fifo #(
    .DATA_WIDTH(`XLEN),
    .FIFO_DEPTH(1    )
    ) pc_reconv_buf(
    .clk      (clk                  ),
    .rst_n    (rst_n                ),
             
    .w_ready_o(pc_reconv_ready_o    ),
    .w_valid_i(pc_reconv_valid_i    ),
    .w_data_i (pc_reconv_i          ),
             
    .r_valid_o(pc_reconv_buf_valid_o),
    .r_ready_i(pc_reconv_buf_ready_i),
    .r_data_o (pc_reconv_buf_o      )
    );   

  //stream_fifo_flow_true #(
  stream_fifo #(
    .DATA_WIDTH(`DEPTH_WARP+32+1),
    .FIFO_DEPTH(1               )
    ) fetch_ctl_buf(
    .clk      (clk                  ),
    .rst_n    (rst_n                ),
             
    .w_ready_o(fetch_ctl_buf_ready_o),
    .w_valid_i(fetch_ctl_buf_valid_i),
    .w_data_i (fetch_ctl_buf_i      ),
             
    .r_valid_o(fetch_ctl_valid_o    ),
    .r_ready_i(fetch_ctl_ready_i    ),
    .r_data_o (fetch_ctl_buf_o      )
    );   

  pop_cnt #(
    .DATA_LEN(`NUM_THREAD    ),  
    .DATA_WID(`DEPTH_THREAD+1)
    ) cnt_if_mask(
    .data_i(if_mask),
    .data_o(if_cnt )
    );

  pop_cnt #(
    .DATA_LEN(`NUM_THREAD    ),
    .DATA_WID(`DEPTH_THREAD+1)
    ) cnt_else_mask(
    .data_i(else_mask),
    .data_o(else_cnt )
    );

endmodule
