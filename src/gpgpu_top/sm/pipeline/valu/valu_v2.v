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
// Description:vector alu(soft_thread!=hard_thread)
`timescale 1ns/1ns
`include "define.v"
//`include "IDecode_define.v"

module  valu_v2 #(
  parameter SOFT_THREAD = `NUM_THREAD,
  parameter HARD_THREAD = `NUM_THREAD,
  parameter MAX_ITER    = SOFT_THREAD / HARD_THREAD
  )(
  input                                     clk              ,
  input                                     rst_n            ,

  input                                     in_valid_i       ,
  input                                     out_ready_i      ,
  input                                     out2simt_ready_i ,

  input   [SOFT_THREAD*`XLEN-1:0]           in1_i            ,
  input   [SOFT_THREAD*`XLEN-1:0]           in2_i            ,
  input   [SOFT_THREAD*`XLEN-1:0]           in3_i            ,
  input   [SOFT_THREAD-1:0]                 mask_i           ,
  input   [5:0]                             ctrl_alu_fn_i    ,
  input                                     ctrl_reverse_i   ,
  //input                                     ctrl_writemask_i ,
  //input                                     ctrl_readmask_i  ,
  input                                     ctrl_simt_stack_i,
  input   [`DEPTH_WARP-1:0]                 ctrl_wid_i       ,
  input   [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] ctrl_reg_idxw_i  ,
  input                                     ctrl_wvd_i       ,

  output                                    in_ready_o       ,
  output                                    out_valid_o      ,
  output                                    out2simt_valid_o ,

  output  [SOFT_THREAD*`XLEN-1:0]           wb_wvd_rd_o      ,
  output  [SOFT_THREAD-1:0]                 wvd_mask_o       ,
  output                                    wvd_o            ,
  output  [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] reg_idxw_o       ,
  output  [`DEPTH_WARP-1:0]                 warp_id_o        ,

  output  [SOFT_THREAD-1:0]                 if_mask_o        ,
  output  [`DEPTH_WARP-1:0]                 wid_o             
);
  //inreg
  //reg    [`XLEN-1:0]                      inreg_in1     [0:SOFT_THREAD-1];
  //reg    [`XLEN-1:0]                      inreg_in2     [0:SOFT_THREAD-1];
  //reg    [`XLEN-1:0]                      inreg_in3     [0:SOFT_THREAD-1];
  //reg                                     inreg_mask    [0:SOFT_THREAD-1];
  reg    [`XLEN*SOFT_THREAD-1:0]          inreg_in1                      ;
  reg    [`XLEN*SOFT_THREAD-1:0]          inreg_in2                      ;
  reg    [`XLEN*SOFT_THREAD-1:0]          inreg_in3                      ;
  reg    [SOFT_THREAD-1:0]                inreg_mask                     ;
  reg    [5:0]                            inreg_alu_fn                   ;
  reg                                     inreg_reverse                  ;
  reg                                     inreg_simt_stack               ;
  reg    [`DEPTH_WARP-1:0]                inreg_wid                      ;
  reg    [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]inreg_reg_idxw                 ;
  reg                                     inreg_wvd                      ;

  //reg    [`XLEN-1:0]                      hardresult    [0:SOFT_THREAD-1];
  reg    [`XLEN*HARD_THREAD-1:0]          hardresult                     ;
  wire                                    outfifoready                   ;
  reg    [$clog2(MAX_ITER+1)-1:0]         sendns                         ;
  reg    [$clog2(MAX_ITER+1)-1:0]         sendcs                         ;
  wire                                    send_valid                     ;
  wire                                    send_ready                     ;
  wire                                    recv_valid                     ;
  wire                                    recv_ready                     ;
  reg    [$clog2(MAX_ITER+1)-1:0]         recvns                         ;
  reg    [$clog2(MAX_ITER+1)-1:0]         recvcs                         ;
  reg                                     recv_wvd                       ;
  reg                                     recv_simt_stack                ;
  
  //resultreg
  //reg    [`XLEN-1:0]                      resultreg_wb_wvd_rd   [0:SOFT_THREAD-1];
  reg    [`XLEN*SOFT_THREAD-1:0]          resultreg_wb_wvd_rd                    ;
  reg    [SOFT_THREAD-1:0]                resultreg_wvd_mask                     ;
  reg                                     resultreg_wvd                          ;
  reg    [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]resultreg_reg_idxw                     ;
  reg    [`DEPTH_WARP-1:0]                resultreg_warp_id                      ;
  wire   [SOFT_THREAD*`XLEN-1:0]          resultreg_wb_wvd_rd_comb               ;

  //simtreg
  reg    [SOFT_THREAD-1:0]                simtreg_if_mask                        ;
  reg    [`DEPTH_WARP-1:0]                simtreg_wid                            ;

  //result            
  wire   [SOFT_THREAD*`XLEN+SOFT_THREAD+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP-1:0] result_data_in     ;
  wire   [SOFT_THREAD*`XLEN+SOFT_THREAD+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP-1:0] result_data_out    ;
  wire                                                                                 result_in_valid    ;
  wire                                                                                 result_in_ready    ;
  wire                                                                                 result_out_valid   ;
  wire                                                                                 result_out_ready   ;

  //result_simt            
  wire   [`DEPTH_WARP+SOFT_THREAD-1:0]  result_simt_data_in  ;
  wire   [`DEPTH_WARP+SOFT_THREAD-1:0]  result_simt_data_out ;
  wire                                  result_simt_in_valid ;
  wire                                  result_simt_in_ready ;
  wire                                  result_simt_out_valid;
  wire                                  result_simt_out_ready;

  //alu
  //reg    [`XLEN-1:0]                    alu_in1 [0:SOFT_THREAD-1];
  //reg    [`XLEN-1:0]                    alu_in2 [0:SOFT_THREAD-1];
  //reg    [`XLEN-1:0]                    alu_in3 [0:SOFT_THREAD-1];
  //reg    [4:0]                          alu_op  [0:SOFT_THREAD-1];
  reg    [`XLEN*HARD_THREAD-1:0]        alu_in1                  ;
  reg    [`XLEN*HARD_THREAD-1:0]        alu_in2                  ;
  //reg    [`XLEN*HARD_THREAD-1:0]        alu_in3                  ;
  reg    [5*HARD_THREAD-1:0]            alu_op                   ;
  wire   [`XLEN-1:0]                    alu_out [0:HARD_THREAD-1];
  wire                                  alu_cmp [0:HARD_THREAD-1];

  genvar i;
  generate
    for(i=0;i<HARD_THREAD;i=i+1) begin:A1
      alu #(.OPCODE_WIDTH(5)) U_alu_i(
        //.clk  (clk                          ),
        //.rst_n(rst_n                        ),
        .op_i (alu_op[(i+1)*5-1-:5]         ),
        .in1_i(alu_in1[(i+1)*`XLEN-1-:`XLEN]),
        .in2_i(alu_in2[(i+1)*`XLEN-1-:`XLEN]),
        //.in3_i(alu_in3[(i+1)*`XLEN-1-:`XLEN]),
        .out_o(alu_out[i]                   ),
        .cmp_o(alu_cmp[i]                   )
      );
 

      always@(*) begin
        if(inreg_reverse == 1'b1) begin
          alu_op[(i+1)*5-1-:5]             = inreg_alu_fn[4:0]              ;
          alu_in1[(i+1)*`XLEN-1-:`XLEN]    = inreg_in2[(i+1)*`XLEN-1-:`XLEN];
          alu_in2[(i+1)*`XLEN-1-:`XLEN]    = inreg_in1[(i+1)*`XLEN-1-:`XLEN];
          //alu_in3[(i+1)*`XLEN-1-:`XLEN]    = inreg_in3[(i+1)*`XLEN-1-:`XLEN];
          hardresult[(i+1)*`XLEN-1-:`XLEN] = alu_out[i]                     ;
          //wvd_mask[i]  = mask_i[i];
        end

        else if((inreg_alu_fn == `FN_VMANDNOT) | (inreg_alu_fn == `FN_VMORNOT) | (inreg_alu_fn == `FN_VMNAND) |
                (inreg_alu_fn == `FN_VMNOR) | (inreg_alu_fn == `FN_VMXNOR)) begin
          if((inreg_alu_fn == `FN_VMANDNOT) | (inreg_alu_fn == `FN_VMORNOT)) begin
            alu_op[(i+1)*5-1-:5]             = {4'd3,inreg_alu_fn[0]}          ;
            alu_in1[(i+1)*`XLEN-1-:`XLEN]    = ~inreg_in1[(i+1)*`XLEN-1-:`XLEN];
            alu_in2[(i+1)*`XLEN-1-:`XLEN]    = inreg_in2[(i+1)*`XLEN-1-:`XLEN] ;
            //alu_in3[(i+1)*`XLEN-1-:`XLEN]    = inreg_in3[(i+1)*`XLEN-1-:`XLEN] ;
            hardresult[(i+1)*`XLEN-1-:`XLEN] = alu_out[i]                      ;
            //wvd_mask[i]  = mask_i[i];
          end
          else begin
            if(inreg_alu_fn == `FN_VMXNOR) begin
              alu_op[(i+1)*5-1-:5]             = `FN_XOR                        ;
              alu_in1[(i+1)*`XLEN-1-:`XLEN]    = inreg_in1[(i+1)*`XLEN-1-:`XLEN];
              alu_in2[(i+1)*`XLEN-1-:`XLEN]    = inreg_in2[(i+1)*`XLEN-1-:`XLEN];
              //alu_in3[(i+1)*`XLEN-1-:`XLEN]    = inreg_in3[(i+1)*`XLEN-1-:`XLEN];
              hardresult[(i+1)*`XLEN-1-:`XLEN] = ~alu_out[i]                    ;
              //wvd_mask[i]  = mask_i[i];
            end
            else begin
              alu_op[(i+1)*5-1-:5]             = {4'd3,inreg_alu_fn[0]}         ;
              alu_in1[(i+1)*`XLEN-1-:`XLEN]    = inreg_in1[(i+1)*`XLEN-1-:`XLEN];
              alu_in2[(i+1)*`XLEN-1-:`XLEN]    = inreg_in2[(i+1)*`XLEN-1-:`XLEN];
              //alu_in3[(i+1)*`XLEN-1-:`XLEN]    = inreg_in3[(i+1)*`XLEN-1-:`XLEN];
              hardresult[(i+1)*`XLEN-1-:`XLEN] = ~alu_out[i]                    ;
              //wvd_mask[i]  = mask_i[i];
            end
          end
        end
        
        else if(inreg_alu_fn == `FN_VID) begin
          alu_op[(i+1)*5-1-:5]             = inreg_alu_fn[4:0]                               ;
          alu_in1[(i+1)*`XLEN-1-:`XLEN]    = inreg_in1[(i+1)*`XLEN-1-:`XLEN]                 ;
          alu_in2[(i+1)*`XLEN-1-:`XLEN]    = inreg_in2[(i+1)*`XLEN-1-:`XLEN]                 ;
          //alu_in3[(i+1)*`XLEN-1-:`XLEN]    = inreg_in3[(i+1)*`XLEN-1-:`XLEN]                 ;
          hardresult[(i+1)*`XLEN-1-:`XLEN] = (sendcs == 'd0) ? 'd0 : (sendcs-1)*HARD_THREAD+i;
          //wvd_mask[i]  = mask_i[i];
        end

        else if(inreg_alu_fn == `FN_VMERGE) begin
          alu_op[(i+1)*5-1-:5]             = inreg_alu_fn[4:0]                                                                ;
          alu_in1[(i+1)*`XLEN-1-:`XLEN]    = inreg_in1[(i+1)*`XLEN-1-:`XLEN]                                                  ;
          alu_in2[(i+1)*`XLEN-1-:`XLEN]    = inreg_in2[(i+1)*`XLEN-1-:`XLEN]                                                  ;
          //alu_in3[(i+1)*`XLEN-1-:`XLEN]    = inreg_in3[(i+1)*`XLEN-1-:`XLEN]                                                  ;
          hardresult[(i+1)*`XLEN-1-:`XLEN] = inreg_mask[i] ? inreg_in1[(i+1)*`XLEN-1-:`XLEN] : inreg_in2[(i+1)*`XLEN-1-:`XLEN];
          //wvd_mask[i]  = 1'b1;
        end

        else begin
          alu_op[(i+1)*5-1-:5]             = inreg_alu_fn[4:0]              ;
          alu_in1[(i+1)*`XLEN-1-:`XLEN]    = inreg_in1[(i+1)*`XLEN-1-:`XLEN];
          alu_in2[(i+1)*`XLEN-1-:`XLEN]    = inreg_in2[(i+1)*`XLEN-1-:`XLEN];
          //alu_in3[(i+1)*`XLEN-1-:`XLEN]    = inreg_in3[(i+1)*`XLEN-1-:`XLEN];
          hardresult[(i+1)*`XLEN-1-:`XLEN] = alu_out[i]                     ;
          //wvd_mask[i]  = mask_i[i];
        end
      end
    end
  endgenerate

  stream_fifo_pipe_true #(.DATA_WIDTH(SOFT_THREAD*`XLEN+SOFT_THREAD+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP),
                          .FIFO_DEPTH(1)
    ) U_result(
              .clk        (clk             ),
              .rst_n      (rst_n           ),
              .w_valid_i  (result_in_valid ),
              .w_data_i   (result_data_in  ),
              .r_ready_i  (result_out_ready),

              .w_ready_o  (result_in_ready ),
              .r_data_o   (result_data_out ),
              .r_valid_o  (result_out_valid)
            );

  stream_fifo_pipe_true #(.DATA_WIDTH(`DEPTH_WARP+SOFT_THREAD),
                          .FIFO_DEPTH(1)
    ) U_result_simt(
              .clk        (clk                  ),
              .rst_n      (rst_n                ),
              .w_valid_i  (result_simt_in_valid ),
              .w_data_i   (result_simt_data_in  ),
              .r_ready_i  (result_simt_out_ready),

              .w_ready_o  (result_simt_in_ready ),
              .r_data_o   (result_simt_data_out ),
              .r_valid_o  (result_simt_out_valid)
            );

  assign  outfifoready = inreg_simt_stack ? result_simt_in_ready : result_in_ready;
  
  //sendcs   sendns                     ,recvcs   recvns                     
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      //sendns <= 'd0;
      sendcs <= 'd0;
      //recvns <= 'd0;
      recvcs <= 'd0;
    end
    else begin
      sendcs <= sendns;
      recvcs <= recvns;
    end
  end

  //sendns   sendcs                                 
  always@(*) begin
    if(sendcs == 'd0) begin
      sendns = (in_valid_i & in_ready_o) ? (sendcs + 1) : 'd0;
    end
    else if(sendcs >= 'd1 & sendcs < MAX_ITER) begin
      sendns = (send_valid & send_ready) ? (sendcs + 1) : sendcs;
    end
    else begin
      sendns = (send_valid & send_ready) ? ((in_valid_i & in_ready_o) ? 'd1 : 'd0) : sendcs;
    end
  end

  //recvns   recvcs                                 
  always@(*) begin
    if(recvcs >= 'd0 & recvcs < MAX_ITER) begin
      recvns = (recv_valid & recv_ready) ? (recvcs + 1) : recvcs;
    end
    else begin
      recvns = outfifoready ? ((recv_valid & recv_ready) ? 'd1 : 'd0) : recvcs;
    end
  end

  //inreg_ctrl
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      inreg_alu_fn    <= 'd0;
      inreg_reverse   <= 'd0;
      inreg_simt_stack<= 'd0;
      inreg_wid       <= 'd0;
      inreg_reg_idxw  <= 'd0;
      inreg_wvd       <= 'd0;
    end
    else if(sendns == 'd0) begin
      inreg_alu_fn    <= 'd0;
      inreg_reverse   <= 'd0;
      inreg_simt_stack<= 'd0;
      inreg_wid       <= 'd0;
      inreg_reg_idxw  <= 'd0;
      inreg_wvd       <= 'd0;
    end
    else if(sendns == 'd1) begin
      if(in_valid_i & in_ready_o) begin
        inreg_alu_fn    <= ctrl_alu_fn_i    ;
        inreg_reverse   <= ctrl_reverse_i   ;
        inreg_simt_stack<= ctrl_simt_stack_i;
        inreg_wid       <= ctrl_wid_i       ;
        inreg_reg_idxw  <= ctrl_reg_idxw_i  ;
        inreg_wvd       <= ctrl_wvd_i       ;
      end
      else begin
        inreg_alu_fn    <= inreg_alu_fn    ;
        inreg_reverse   <= inreg_reverse   ;
        inreg_simt_stack<= inreg_simt_stack;
        inreg_wid       <= inreg_wid       ;
        inreg_reg_idxw  <= inreg_reg_idxw  ;
        inreg_wvd       <= inreg_wvd       ;
      end
    end
    else begin
      inreg_alu_fn    <= inreg_alu_fn    ;
      inreg_reverse   <= inreg_reverse   ;
      inreg_simt_stack<= inreg_simt_stack;
      inreg_wid       <= inreg_wid       ;
      inreg_reg_idxw  <= inreg_reg_idxw  ;
      inreg_wvd       <= inreg_wvd       ;
    end
  end

  //outreg_ctrl
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      resultreg_wvd     <= 'd0;
      resultreg_reg_idxw<= 'd0;
      resultreg_warp_id <= 'd0;
      simtreg_wid       <= 'd0;
      recv_wvd          <= 'd0;
      recv_simt_stack   <= 'd0;
    end
    else if(recvns == 'd0) begin   
      resultreg_wvd                             <= 'd0;
      resultreg_reg_idxw                        <= 'd0;
      resultreg_warp_id                         <= 'd0;
      simtreg_wid                               <= 'd0;
    end
    else begin
      if(recv_valid & recv_ready) begin
        if(recvns == MAX_ITER) begin
          resultreg_warp_id      <= inreg_wid       ;
          resultreg_reg_idxw     <= inreg_reg_idxw  ;
          resultreg_wvd          <= inreg_wvd       ;
          simtreg_wid            <= inreg_wid       ;
          recv_wvd               <= inreg_wvd       ;
          recv_simt_stack        <= inreg_simt_stack;
        end
        else begin
          resultreg_warp_id      <= 'd0;
          resultreg_reg_idxw     <= 'd0;
          resultreg_wvd          <= 'd0;
          simtreg_wid            <= 'd0;
          recv_wvd               <= 'd0;
          recv_simt_stack        <= 'd0;
        end
      end
      else begin
        resultreg_wvd     <= resultreg_wvd     ;
        resultreg_reg_idxw<= resultreg_reg_idxw;
        resultreg_warp_id <= resultreg_warp_id ;
      end
    end
  end
        
  genvar j;
  generate 
    for(j=0;j<SOFT_THREAD;j=j+1) begin:B1
      assign  resultreg_wb_wvd_rd_comb[(j+1)*`XLEN-1-:`XLEN] = resultreg_wb_wvd_rd[(j+1)*`XLEN-1-:`XLEN];
      //send
      always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          inreg_in1[(j+1)*`XLEN-1-:`XLEN] <= 'd0;
          inreg_in2[(j+1)*`XLEN-1-:`XLEN] <= 'd0;
          inreg_in3[(j+1)*`XLEN-1-:`XLEN] <= 'd0;
          inreg_mask[j]                   <= 'd0;
          //inreg_alu_fn                    <= 'd0;
          //inreg_reverse                   <= 'd0;
          //inreg_simt_stack                <= 'd0;
          //inreg_wid                       <= 'd0;
          //inreg_reg_idxw                  <= 'd0;
          //inreg_wvd                       <= 'd0;
        end
        else if(sendns == 'd0) begin
          inreg_in1[(j+1)*`XLEN-1-:`XLEN]<= 'd0;
          inreg_in2[(j+1)*`XLEN-1-:`XLEN]<= 'd0;
          inreg_in3[(j+1)*`XLEN-1-:`XLEN]<= 'd0;
          inreg_mask[j]                  <= 'd0;
          //inreg_alu_fn                   <= 'd0;
          //inreg_reverse                  <= 'd0;
          //inreg_simt_stack               <= 'd0;
          //inreg_wid                      <= 'd0;
          //inreg_reg_idxw                 <= 'd0;
          //inreg_wvd                      <= 'd0;
        end
        else if(sendns == 'd1) begin
          if(in_valid_i & in_ready_o) begin
            inreg_in1[(j+1)*`XLEN-1-:`XLEN] <= in1_i[(j+1)*`XLEN-1-:`XLEN];
            inreg_in2[(j+1)*`XLEN-1-:`XLEN] <= in2_i[(j+1)*`XLEN-1-:`XLEN];
            inreg_in3[(j+1)*`XLEN-1-:`XLEN] <= in3_i[(j+1)*`XLEN-1-:`XLEN];
            inreg_mask[j]                   <= mask_i[j]                  ;
            //inreg_alu_fn                    <= ctrl_alu_fn_i              ;
            //inreg_reverse                   <= ctrl_reverse_i             ;
            //inreg_simt_stack                <= ctrl_simt_stack_i          ;
            //inreg_wid                       <= ctrl_wid_i                 ;
            //inreg_reg_idxw                  <= ctrl_reg_idxw_i            ;
            //inreg_wvd                       <= ctrl_wvd_i                 ;
          end
          else begin
            inreg_in1[(j+1)*`XLEN-1-:`XLEN] <= inreg_in1[(j+1)*`XLEN-1-:`XLEN];
            inreg_in2[(j+1)*`XLEN-1-:`XLEN] <= inreg_in2[(j+1)*`XLEN-1-:`XLEN];    
            inreg_in3[(j+1)*`XLEN-1-:`XLEN] <= inreg_in3[(j+1)*`XLEN-1-:`XLEN];
            inreg_mask[j]                   <= inreg_mask[j]                  ;
            //inreg_alu_fn                    <= inreg_alu_fn                   ;
            //inreg_reverse                   <= inreg_reverse                  ;
            //inreg_simt_stack                <= inreg_simt_stack               ;
            //inreg_wid                       <= inreg_wid                      ;
            //inreg_reg_idxw                  <= inreg_reg_idxw                 ;
            //inreg_wvd                       <= inreg_wvd                      ;
          end
        end
        else begin
          if(sendcs != sendns) begin
            if(j + HARD_THREAD < SOFT_THREAD) begin
              inreg_in1[(j+1)*`XLEN-1-:`XLEN] <= inreg_in1[(j+HARD_THREAD+1)*`XLEN-1-:`XLEN];
              inreg_in2[(j+1)*`XLEN-1-:`XLEN] <= inreg_in2[(j+HARD_THREAD+1)*`XLEN-1-:`XLEN];
              inreg_in3[(j+1)*`XLEN-1-:`XLEN] <= inreg_in3[(j+HARD_THREAD+1)*`XLEN-1-:`XLEN];
            end
            else begin
              inreg_in1[(j+1)*`XLEN-1-:`XLEN] <= 'd0;
              inreg_in2[(j+1)*`XLEN-1-:`XLEN] <= 'd0;
              inreg_in3[(j+1)*`XLEN-1-:`XLEN] <= 'd0;
            end
          end
          else begin
            inreg_in1[(j+1)*`XLEN-1-:`XLEN] <= inreg_in1[(j+1)*`XLEN-1-:`XLEN];
            inreg_in2[(j+1)*`XLEN-1-:`XLEN] <= inreg_in2[(j+1)*`XLEN-1-:`XLEN];    
            inreg_in3[(j+1)*`XLEN-1-:`XLEN] <= inreg_in3[(j+1)*`XLEN-1-:`XLEN];
          end
        end
      end
      //recv
      always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          resultreg_wb_wvd_rd[(j+1)*`XLEN-1-:`XLEN] <= 'd0;
          resultreg_wvd_mask[j]                     <= 'd0;
          //resultreg_wvd                             <= 'd0;
          //resultreg_reg_idxw                        <= 'd0;
          //resultreg_warp_id                         <= 'd0;
          simtreg_if_mask[j]                        <= 'd0;
          //simtreg_wid                               <= 'd0;
        end
        else if(recvns == 'd0) begin
          resultreg_wb_wvd_rd[(j+1)*`XLEN-1-:`XLEN] <= 'd0;
          resultreg_wvd_mask[j]                     <= 'd0;
          //resultreg_wvd                             <= 'd0;
          //resultreg_reg_idxw                        <= 'd0;
          //resultreg_warp_id                         <= 'd0;
          simtreg_if_mask[j]                        <= 'd0;
          //simtreg_wid                               <= 'd0;
        end
        else begin
          if(recv_valid & recv_ready) begin
            if(j+HARD_THREAD < SOFT_THREAD) begin
              resultreg_wb_wvd_rd[(j+1)*`XLEN-1-:`XLEN] <= resultreg_wb_wvd_rd[(j+HARD_THREAD+1)*`XLEN-1-:`XLEN];
              simtreg_if_mask[j]                        <= simtreg_if_mask[j+HARD_THREAD]                       ;
            end
            else begin
              resultreg_wb_wvd_rd[(j+1)*`XLEN-1-:`XLEN] <= hardresult[(j+HARD_THREAD+1-SOFT_THREAD)*`XLEN-1-:`XLEN];
              simtreg_if_mask[j]                        <= ~alu_cmp[j+HARD_THREAD-SOFT_THREAD]                     ;
            end

            if(recvns == MAX_ITER) begin
              //resultreg_warp_id      <= inreg_wid       ;
              //resultreg_reg_idxw     <= inreg_reg_idxw  ;
              //resultreg_wvd          <= inreg_wvd       ;
              resultreg_wvd_mask[j]  <= inreg_mask[j]   ;
              //simtreg_wid            <= inreg_wid       ;
              //recv_wvd               <= inreg_wvd       ;
              //recv_simt_stack        <= inreg_simt_stack;
            end
            else begin
              //resultreg_warp_id      <= 'd0;
              //resultreg_reg_idxw     <= 'd0;
              //resultreg_wvd          <= 'd0;
              resultreg_wvd_mask[j]  <= 'd0;
              //simtreg_wid            <= 'd0;
              //recv_wvd               <= 'd0;
              //recv_simt_stack        <= 'd0;
            end
          end
          else begin
            resultreg_wb_wvd_rd[(j+1)*`XLEN-1-:`XLEN] <= resultreg_wb_wvd_rd[(j+1)*`XLEN-1-:`XLEN];
            resultreg_wvd_mask[j]                     <= resultreg_wvd_mask[j]                    ;
            //resultreg_wvd                             <= resultreg_wvd                            ;
            //resultreg_reg_idxw                        <= resultreg_reg_idxw                       ;
            //resultreg_warp_id                         <= resultreg_warp_id                        ;
          end
        end
      end
    end
  endgenerate 

  assign send_valid = sendcs != 'd0;
  assign send_ready = recv_ready;
  assign recv_ready = (recvcs != MAX_ITER) | ((recvcs == MAX_ITER) & outfifoready);
  assign recv_valid = send_valid;

  //result            
  assign result_data_in   = {resultreg_warp_id,resultreg_wb_wvd_rd_comb,resultreg_reg_idxw,resultreg_wvd,resultreg_wvd_mask};
  assign result_in_valid  = (recvcs == MAX_ITER) & recv_wvd & !recv_simt_stack                                              ;
  assign result_out_ready = out_ready_i                                                                                     ;

  //result2simt            
  assign result_simt_data_in    = {simtreg_wid,simtreg_if_mask}         ;
  assign result_simt_in_valid   = (recvcs == MAX_ITER) & recv_simt_stack;
  assign result_simt_out_ready  = out2simt_ready_i                      ;

  //result            
  assign  warp_id_o  = result_data_out[SOFT_THREAD*`XLEN+SOFT_THREAD+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP-1-:`DEPTH_WARP]; 
  assign  wb_wvd_rd_o= result_data_out[SOFT_THREAD*`XLEN+SOFT_THREAD+`REGIDX_WIDTH+`REGEXT_WIDTH-:SOFT_THREAD*`XLEN]          ;
  assign  reg_idxw_o = result_data_out[SOFT_THREAD+`REGIDX_WIDTH+`REGEXT_WIDTH-:`REGIDX_WIDTH+`REGEXT_WIDTH]                  ;
  assign  wvd_o      = result_data_out[SOFT_THREAD]                                                                           ;    
  assign  wvd_mask_o = result_data_out[SOFT_THREAD-1:0]                                                                       ;
  assign  out_valid_o= result_out_valid                                                                                       ;

  //result_simt            
  assign  wid_o      = result_simt_data_out[`DEPTH_WARP+SOFT_THREAD-1:SOFT_THREAD];
  assign  if_mask_o  = result_simt_data_out[SOFT_THREAD-1:0]                      ;
  assign  out2simt_valid_o = result_simt_out_valid                                ;

  assign  in_ready_o = (sendcs == 'd0) | ((sendcs == MAX_ITER) & outfifoready);
endmodule
