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
// Description:vector mul(soft_thread!=hard_thread)
`timescale 1ns/1ns
`include "define.v"
//`include "IDecode_define.v"

module  vmul_v2 #(
  parameter SOFT_THREAD = `NUM_THREAD,
  parameter HARD_THREAD = `NUM_THREAD,
  parameter MAX_ITER    = SOFT_THREAD / HARD_THREAD
  )(
  input                                     clk              ,
  input                                     rst_n            ,

  input                                     in_valid_i       ,
  input                                     outx_ready_i     ,
  input                                     outv_ready_i     ,

  input   [SOFT_THREAD*`XLEN-1:0]           in1_i            ,
  input   [SOFT_THREAD*`XLEN-1:0]           in2_i            ,
  input   [SOFT_THREAD*`XLEN-1:0]           in3_i            ,
  input   [SOFT_THREAD-1:0]                 mask_i           ,
  input   [5:0]                             ctrl_alu_fn_i    ,
  input                                     ctrl_reverse_i   ,
  input   [`DEPTH_WARP-1:0]                 ctrl_wid_i       ,
  input   [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] ctrl_reg_idxw_i  ,
  input                                     ctrl_wvd_i       ,
  input                                     ctrl_wxd_i       ,

  output                                    in_ready_o       ,
  output                                    outx_valid_o     ,
  output                                    outv_valid_o     ,
  
  //scalar output
  output  [`XLEN-1:0]                       outx_wb_wxd_rd_o ,
  output                                    outx_wxd_o       ,
  output  [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] outx_reg_idwx_o  ,
  output  [`DEPTH_WARP-1:0]                 outx_warp_id_o   ,

  //vector output
  output  [SOFT_THREAD*`XLEN-1:0]           outv_wb_wxd_rd_o ,
  output  [SOFT_THREAD-1:0]                 outv_wvd_mask_o  ,
  output                                    outv_wvd_o       ,
  output  [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] outv_reg_idxw_o  ,
  output  [`DEPTH_WARP-1:0]                 outv_warp_id_o   
  );  
  //inreg
  //reg    [`XLEN-1:0]                      inreg_in1     [0:SOFT_THREAD-1];
  //reg    [`XLEN-1:0]                      inreg_in2     [0:SOFT_THREAD-1];
  //reg    [`XLEN-1:0]                      inreg_in3     [0:SOFT_THREAD-1];
  reg    [`XLEN*SOFT_THREAD-1:0]          inreg_in1                      ;
  reg    [`XLEN*SOFT_THREAD-1:0]          inreg_in2                      ;
  reg    [`XLEN*SOFT_THREAD-1:0]          inreg_in3                      ;
  reg    [SOFT_THREAD-1:0]                inreg_mask                     ;
  reg    [5:0]                            inreg_alu_fn                   ;
  reg                                     inreg_reverse                  ;
  reg                                     inreg_wxd                      ;
  reg    [`DEPTH_WARP-1:0]                inreg_wid                      ;
  reg    [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]inreg_reg_idxw                 ;
  reg                                     inreg_wvd                      ;

  wire   [`XLEN-1:0]                      hardresult    [0:HARD_THREAD-1];
  wire                                    outfifoready                   ;
  reg    [$clog2(MAX_ITER+1)-1:0]         sendns                         ;
  reg    [$clog2(MAX_ITER+1)-1:0]         sendcs                         ;
  wire                                    send_valid                     ;
  wire                                    send_ready                     ;
  wire                                    recv_valid                     ;
  wire                                    recv_ready                     ;
  reg    [$clog2(MAX_ITER+1)-1:0]         recvns                         ;
  reg    [$clog2(MAX_ITER+1)-1:0]         recvcs                         ;
  
  //resultreg
  //reg    [`XLEN-1:0]                      resultreg_wb_wvd_rd   [0:SOFT_THREAD-1];
  reg    [`XLEN*SOFT_THREAD-1:0]          resultreg_wb_wvd_rd                    ;
  reg    [SOFT_THREAD-1:0]                resultreg_wvd_mask                     ;
  reg                                     resultreg_wvd                          ;
  reg    [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]resultreg_reg_idxw                     ;
  reg    [`DEPTH_WARP-1:0]                resultreg_warp_id                      ;
  wire   [SOFT_THREAD*`XLEN-1:0]          resultreg_wb_wvd_rd_comb               ;

  //result_x输入数据
  wire   [`XLEN+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP-1:0]  result_x_data_in     ;
  wire   [`XLEN+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP-1:0]  result_x_data_out    ;
  wire                                                          result_x_in_valid    ;
  wire                                                          result_x_in_ready    ;
  wire                                                          result_x_out_valid   ;
  wire                                                          result_x_out_ready   ;


  //result_v输入数据
  wire   [SOFT_THREAD*`XLEN+SOFT_THREAD+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP-1:0] result_v_data_in     ;
  wire   [SOFT_THREAD*`XLEN+SOFT_THREAD+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP-1:0] result_v_data_out    ;
  wire                                                                                 result_v_in_valid    ;
  wire                                                                                 result_v_in_ready    ;
  wire                                                                                 result_v_out_valid   ;
  wire                                                                                 result_v_out_ready   ;

  //mul端口
  wire   [`XLEN-1:0]                          mul_in1         [0:HARD_THREAD-1];
  wire   [`XLEN-1:0]                          mul_in2         [0:HARD_THREAD-1];
  wire   [`XLEN-1:0]                          mul_in3         [0:HARD_THREAD-1];
  wire   [`XLEN-1:0]                          mul_result      [0:HARD_THREAD-1];
  wire                                        mul_out_ready   [0:HARD_THREAD-1];
  wire                                        mul_out_valid   [0:HARD_THREAD-1];
  wire                                        mul_in_ready    [0:HARD_THREAD-1];
  wire   [SOFT_THREAD-1:0]                    mul_out_mask    [0:HARD_THREAD-1];
  wire   [5:0]                                mul_out_alu_fn  [0:HARD_THREAD-1];
  wire   [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]    mul_out_reg_idxw[0:HARD_THREAD-1];
  wire   [`DEPTH_WARP-1:0]                    mul_out_wid     [0:HARD_THREAD-1];
  wire                                        mul_out_wvd     [0:HARD_THREAD-1];
  wire                                        mul_out_wxd     [0:HARD_THREAD-1];
  wire   [SOFT_THREAD*`XLEN-1:0]              wb_wvd_rd_comb                   ;

  assign  outfifoready = resultreg_wvd ? result_v_in_ready : result_x_in_ready;
  assign  in_ready_o   = (sendcs == 'd0) | ((sendcs == MAX_ITER) & send_ready);

  genvar i;
  generate 
    for(i=0;i<HARD_THREAD;i=i+1) begin:mul
      assign  mul_out_ready[i] = recv_ready;
      assign  hardresult[i]    = mul_result[i];

      array_multiplier U_mul_i(
                        .clk            (clk                ),   
                        .rst_n          (rst_n              ), 
                                                         
                        .mask_i         (inreg_mask         ), 
                        .a_i            (mul_in1[i]         ), 
                        .b_i            (mul_in2[i]         ), 
                        .c_i            (mul_in3[i]         ), 
                        .ctrl_alu_fn_i  (inreg_alu_fn       ), 
                        .ctrl_reg_idxw_i(inreg_reg_idxw     ), 
                        .ctrl_wid_i     (inreg_wid          ), 
                        .ctrl_wvd_i     (inreg_wvd          ), 
                        .ctrl_wxd_i     (inreg_wxd          ), 
                                                         
                        .in_valid_i     (send_valid         ), 
                        .out_ready_i    (mul_out_ready[i]   ), 
                                                         
                        .in_ready_o     (mul_in_ready[i]    ), 
                        .out_valid_o    (mul_out_valid[i]   ), 
                                                         
                        .mask_o         (mul_out_mask[i]    ), 
                        .ctrl_alu_fn_o  (mul_out_alu_fn[i]  ), 
                        .ctrl_reg_idxw_o(mul_out_reg_idxw[i]), 
                        .ctrl_wid_o     (mul_out_wid[i]     ), 
                        .ctrl_wvd_o     (mul_out_wvd[i]     ), 
                        .ctrl_wxd_o     (mul_out_wxd[i]     ), 
                        .result_o       (mul_result[i]      )
                        );
                        
      assign mul_in1[i] = inreg_reverse ? inreg_in2[(i+1)*`XLEN-1-:`XLEN] : inreg_in1[(i+1)*`XLEN-1-:`XLEN];
      assign mul_in2[i] = inreg_reverse ? inreg_in1[(i+1)*`XLEN-1-:`XLEN] : inreg_in2[(i+1)*`XLEN-1-:`XLEN];
      assign mul_in3[i] = inreg_in3[(i+1)*`XLEN-1-:`XLEN];
    end
  endgenerate

  stream_fifo_pipe_true #(.DATA_WIDTH(`XLEN+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP),
                          .FIFO_DEPTH(1)
    ) U_result_x(
              .clk        (clk               ),
              .rst_n      (rst_n             ),
              .w_valid_i  (result_x_in_valid ),
              .w_data_i   (result_x_data_in  ),
              .r_ready_i  (result_x_out_ready),

              .w_ready_o  (result_x_in_ready ),
              .r_data_o   (result_x_data_out ),
              .r_valid_o  (result_x_out_valid)
            );

  stream_fifo_pipe_true #(.DATA_WIDTH(SOFT_THREAD*`XLEN+SOFT_THREAD+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP),
                          .FIFO_DEPTH(1)
    ) U_result_v(
              .clk        (clk               ),
              .rst_n      (rst_n             ),
              .w_valid_i  (result_v_in_valid ),
              .w_data_i   (result_v_data_in  ),
              .r_ready_i  (result_v_out_ready),

              .w_ready_o  (result_v_in_ready ),
              .r_data_o   (result_v_data_out ),
              .r_valid_o  (result_v_out_valid)
            );

  //sendcs为sendns打一拍后的结果,recvcs为recvns打一拍后的结果
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

  //sendns和sendcs来决定什么时候发送数据
  always@(*) begin
    if(sendcs == 'd0) begin
      if(in_valid_i & in_ready_o) begin
        if(ctrl_wvd_i) begin
          sendns = 'd1;
        end
        else if(ctrl_wxd_i) begin
          sendns = MAX_ITER;
        end
        else begin
          sendns = 'd0;
        end
      end
      else begin
        sendns = 'd0;
      end
    end

    else if(sendcs >= 'd1 & sendcs < MAX_ITER) begin
      sendns = (send_valid & send_ready) ? (sendcs + 1) : sendcs;
    end

    else begin
      if(send_valid & send_ready) begin
        if(in_valid_i & in_ready_o) begin
          if(ctrl_wvd_i) begin
            sendns = 'd1;
          end
          else if(ctrl_wxd_i) begin
            sendns = MAX_ITER;
          end
          else begin
            sendns = 'd0;
          end
        end
        else begin
          sendns = 'd0;
        end
      end
      else begin
        sendns = sendcs;
      end
    end
  end

  //recvns和recvcs来决定什么时候接收数据
  always@(*) begin
    if(recvcs == 'd0) begin
      if(recv_valid & recv_ready) begin
        if(mul_out_wxd[0]) begin
          recvns = MAX_ITER;
        end
        else if(mul_out_wvd[0]) begin
          recvns = 'd1;
        end
        else begin
          recvns = 'd0;
        end
      end
      else begin
        recvns = 'd0;
      end
    end

    else if(recvcs >= 'd1 & recvcs < MAX_ITER) begin
      recvns = (recv_valid & recv_ready) ? (recvcs + 1) : 'd0;
    end

    else begin
      if(outfifoready) begin
        if(recv_valid & recv_ready) begin
          if(mul_out_wxd[0]) begin
            recvns = MAX_ITER;
          end
          else if(mul_out_wvd[0]) begin
            recvns = 'd1;
          end
          else begin
            recvns = 'd0;
          end
        end
        else begin
          recvns = 'd0;
        end
      end
      else begin
        recvns = recvcs;
      end
    end
  end

  //inreg_ctrl
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      inreg_mask    <= 'd0;  
      inreg_alu_fn  <= 'd0;  
      inreg_reverse <= 'd0;  
      inreg_wxd     <= 'd0;  
      inreg_wid     <= 'd0;  
      inreg_reg_idxw<= 'd0;  
      inreg_wvd     <= 'd0; 
    end
    else if(sendns == 'd0) begin
      inreg_mask    <= 'd0;  
      inreg_alu_fn  <= 'd0;  
      inreg_reverse <= 'd0;  
      inreg_wxd     <= 'd0;  
      inreg_wid     <= 'd0;  
      inreg_reg_idxw<= 'd0;  
      inreg_wvd     <= 'd0; 
    end
    else if(sendns == 'd1) begin
      if(in_valid_i & in_ready_o) begin
        inreg_mask    <= mask_i         ;  
        inreg_alu_fn  <= ctrl_alu_fn_i  ;  
        inreg_reverse <= ctrl_reverse_i ;  
        inreg_wxd     <= ctrl_wxd_i     ;  
        inreg_wid     <= ctrl_wid_i     ;  
        inreg_reg_idxw<= ctrl_reg_idxw_i;  
        inreg_wvd     <= ctrl_wvd_i     ;
      end
      else begin
        inreg_mask    <=  inreg_mask    ; 
        inreg_alu_fn  <=  inreg_alu_fn  ; 
        inreg_reverse <=  inreg_reverse ; 
        inreg_wxd     <=  inreg_wxd     ; 
        inreg_wid     <=  inreg_wid     ; 
        inreg_reg_idxw<=  inreg_reg_idxw; 
        inreg_wvd     <=  inreg_wvd     ;
      end
    end
    else begin
      if(in_valid_i & in_ready_o) begin
        inreg_mask    <= mask_i         ;  
        inreg_alu_fn  <= ctrl_alu_fn_i  ;  
        inreg_reverse <= ctrl_reverse_i ;  
        inreg_wxd     <= ctrl_wxd_i     ;  
        inreg_wid     <= ctrl_wid_i     ;  
        inreg_reg_idxw<= ctrl_reg_idxw_i;  
        inreg_wvd     <= ctrl_wvd_i     ;
      end
      else begin
        inreg_mask     <=  inreg_mask    ; 
        inreg_alu_fn   <=  inreg_alu_fn  ; 
        inreg_reverse  <=  inreg_reverse ; 
        inreg_wxd      <=  inreg_wxd     ; 
        inreg_wid      <=  inreg_wid     ; 
        inreg_reg_idxw <=  inreg_reg_idxw; 
        inreg_wvd      <=  inreg_wvd     ; 
      end
    end
  end

  //outreg_ctrl
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      resultreg_wvd_mask<= 'd0;
      resultreg_wvd     <= 'd0;
      resultreg_reg_idxw<= 'd0;
      resultreg_warp_id <= 'd0;
    end
    else if(recvns == 'd0) begin
      resultreg_wvd_mask<= 'd0;
      resultreg_wvd     <= 'd0;
      resultreg_reg_idxw<= 'd0;
      resultreg_warp_id <= 'd0;
    end
    else begin
      if(recv_valid & recv_ready) begin
        if(recvns == MAX_ITER) begin
          resultreg_warp_id <= mul_out_wid[0]     ;
          resultreg_reg_idxw<= mul_out_reg_idxw[0];
          resultreg_wvd     <= mul_out_wvd[0]     ;
          resultreg_wvd_mask<= mul_out_mask[0]    ;
        end
        else begin
          resultreg_warp_id <= 'd0;
          resultreg_reg_idxw<= 'd0;
          resultreg_wvd     <= 'd0;
          resultreg_wvd_mask<= 'd0;
        end
      end
      else begin
        resultreg_wvd_mask<= resultreg_wvd_mask;
        resultreg_wvd     <= resultreg_wvd     ;
        resultreg_reg_idxw<= resultreg_reg_idxw;
        resultreg_warp_id <= resultreg_warp_id ;
      end
    end
  end

  genvar j;
  generate
    for(j=0;j<SOFT_THREAD;j=j+1) begin : A1
      assign  resultreg_wb_wvd_rd_comb[(j+1)*`XLEN-1-:`XLEN] = resultreg_wb_wvd_rd[(j+1)*`XLEN-1-:`XLEN];//将计算结果拼接
      //send
      always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          inreg_in1[(j+1)*`XLEN-1-:`XLEN] <= 'd0;   
          inreg_in2[(j+1)*`XLEN-1-:`XLEN] <= 'd0; 
          inreg_in3[(j+1)*`XLEN-1-:`XLEN] <= 'd0; 
          //inreg_mask                      <= 'd0;  
          //inreg_alu_fn                    <= 'd0;  
          //inreg_reverse                   <= 'd0;  
          //inreg_wxd                       <= 'd0;  
          //inreg_wid                       <= 'd0;  
          //inreg_reg_idxw                  <= 'd0;  
          //inreg_wvd                       <= 'd0; 
        end
        else if(sendns == 'd0) begin
          inreg_in1[(j+1)*`XLEN-1-:`XLEN]   <= 'd0;   
          inreg_in2[(j+1)*`XLEN-1-:`XLEN]   <= 'd0; 
          inreg_in3[(j+1)*`XLEN-1-:`XLEN]   <= 'd0; 
          //inreg_mask                        <= 'd0;  
          //inreg_alu_fn                      <= 'd0;  
          //inreg_reverse                     <= 'd0;  
          //inreg_wxd                         <= 'd0;  
          //inreg_wid                         <= 'd0;  
          //inreg_reg_idxw                    <= 'd0;  
          //inreg_wvd                         <= 'd0;
        end
        else if(sendns == 'd1) begin
          if(in_valid_i & in_ready_o) begin
            inreg_in1[(j+1)*`XLEN-1-:`XLEN] <= in1_i[(j+1)*`XLEN-1-:`XLEN];   
            inreg_in2[(j+1)*`XLEN-1-:`XLEN] <= in2_i[(j+1)*`XLEN-1-:`XLEN]; 
            inreg_in3[(j+1)*`XLEN-1-:`XLEN] <= in3_i[(j+1)*`XLEN-1-:`XLEN]; 
            //inreg_mask                      <= mask_i                     ;  
            //inreg_alu_fn                    <= ctrl_alu_fn_i              ;  
            //inreg_reverse                   <= ctrl_reverse_i             ;  
            //inreg_wxd                       <= ctrl_wxd_i                 ;  
            //inreg_wid                       <= ctrl_wid_i                 ;  
            //inreg_reg_idxw                  <= ctrl_reg_idxw_i            ;  
            //inreg_wvd                       <= ctrl_wvd_i                 ;
          end
          else begin
            inreg_in1[(j+1)*`XLEN-1-:`XLEN] <=  inreg_in1[(j+1)*`XLEN-1-:`XLEN]; 
            inreg_in2[(j+1)*`XLEN-1-:`XLEN] <=  inreg_in2[(j+1)*`XLEN-1-:`XLEN]; 
            inreg_in3[(j+1)*`XLEN-1-:`XLEN] <=  inreg_in3[(j+1)*`XLEN-1-:`XLEN]; 
            //inreg_mask                      <=  inreg_mask                     ; 
            //inreg_alu_fn                    <=  inreg_alu_fn                   ; 
            //inreg_reverse                   <=  inreg_reverse                  ; 
            //inreg_wxd                       <=  inreg_wxd                      ; 
            //inreg_wid                       <=  inreg_wid                      ; 
            //inreg_reg_idxw                  <=  inreg_reg_idxw                 ; 
            //inreg_wvd                       <=  inreg_wvd                      ;
          end
        end
        else begin
          if(in_valid_i & in_ready_o) begin
            inreg_in1[(j+1)*`XLEN-1-:`XLEN] <= in1_i[(j+1)*`XLEN-1-:`XLEN];   
            inreg_in2[(j+1)*`XLEN-1-:`XLEN] <= in2_i[(j+1)*`XLEN-1-:`XLEN]; 
            inreg_in3[(j+1)*`XLEN-1-:`XLEN] <= in3_i[(j+1)*`XLEN-1-:`XLEN]; 
            //inreg_mask                      <= mask_i                     ;  
            //inreg_alu_fn                    <= ctrl_alu_fn_i              ;  
            //inreg_reverse                   <= ctrl_reverse_i             ;  
            //inreg_wxd                       <= ctrl_wxd_i                 ;  
            //inreg_wid                       <= ctrl_wid_i                 ;  
            //inreg_reg_idxw                  <= ctrl_reg_idxw_i            ;  
            //inreg_wvd                       <= ctrl_wvd_i                 ;
          end
          else if(send_valid & send_ready) begin
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
            inreg_in1[(j+1)*`XLEN-1-:`XLEN]   <=  inreg_in1[(j+1)*`XLEN-1-:`XLEN]  ; 
            inreg_in2[(j+1)*`XLEN-1-:`XLEN]   <=  inreg_in2[(j+1)*`XLEN-1-:`XLEN]  ; 
            inreg_in3[(j+1)*`XLEN-1-:`XLEN]   <=  inreg_in3[(j+1)*`XLEN-1-:`XLEN]  ; 
            //inreg_mask     <=  inreg_mask    ; 
            //inreg_alu_fn   <=  inreg_alu_fn  ; 
            //inreg_reverse  <=  inreg_reverse ; 
            //inreg_wxd      <=  inreg_wxd     ; 
            //inreg_wid      <=  inreg_wid     ; 
            //inreg_reg_idxw <=  inreg_reg_idxw; 
            //inreg_wvd      <=  inreg_wvd     ; 
          end

          /*if(send_valid & send_ready) begin
            if(j + HARD_THREAD < SOFT_THREAD) begin
              inreg_in1[j] <= inreg_in1[j+HARD_THREAD];
              inreg_in2[j] <= inreg_in2[j+HARD_THREAD];
              inreg_in3[j] <= inreg_in3[j+HARD_THREAD];
            end
            else begin
              inreg_in1[j] <= 'd0;
              inreg_in2[j] <= 'd0;
              inreg_in3[j] <= 'd0;
            end
          end
          else begin
            inreg_in1[j]     <= inreg_in1[j]        ;
            inreg_in2[j]     <= inreg_in2[j]        ;    
            inreg_in3[j]     <= inreg_in3[j]        ;
          end*/
        end
      end
      //recv
      always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          resultreg_wb_wvd_rd[(j+1)*`XLEN-1-:`XLEN] <= 'd0;
          //resultreg_wvd_mask                        <= 'd0;
          //resultreg_wvd                             <= 'd0;
          //resultreg_reg_idxw                        <= 'd0;
          //resultreg_warp_id                         <= 'd0;
        end
        else if(recvns == 'd0) begin
          resultreg_wb_wvd_rd[(j+1)*`XLEN-1-:`XLEN] <= 'd0;
          //resultreg_wvd_mask                        <= 'd0;
          //resultreg_wvd                             <= 'd0;
          //resultreg_reg_idxw                        <= 'd0;
          //resultreg_warp_id                         <= 'd0;
        end
        else begin
          if(recv_valid & recv_ready) begin
            if(j+HARD_THREAD < SOFT_THREAD) begin
              resultreg_wb_wvd_rd[(j+1)*`XLEN-1-:`XLEN] <= resultreg_wb_wvd_rd[(j+HARD_THREAD+1)*`XLEN-1-:`XLEN];
            end
            else begin
              resultreg_wb_wvd_rd[(j+1)*`XLEN-1-:`XLEN] <= hardresult[j+HARD_THREAD-SOFT_THREAD];
            end

            /*if(recvns == MAX_ITER) begin
              resultreg_warp_id      <= mul_out_wid[0]       ;
              resultreg_reg_idxw     <= mul_out_reg_idxw[0]  ;
              resultreg_wvd          <= mul_out_wvd[0]       ;
              resultreg_wvd_mask     <= mul_out_mask[0]      ;
            end
            else begin
              resultreg_warp_id      <= 'd0;
              resultreg_reg_idxw     <= 'd0;
              resultreg_wvd          <= 'd0;
              resultreg_wvd_mask     <= 'd0;
            end*/
          end
          else begin
            resultreg_wb_wvd_rd[(j+1)*`XLEN-1-:`XLEN] <= resultreg_wb_wvd_rd[(j+1)*`XLEN-1-:`XLEN];
            //resultreg_wvd_mask                        <= resultreg_wvd_mask                       ;
            //resultreg_wvd                             <= resultreg_wvd                            ;
            //resultreg_reg_idxw                        <= resultreg_reg_idxw                       ;
            //resultreg_warp_id                         <= resultreg_warp_id                        ;
          end
        end
      end
    end
  endgenerate

  assign  send_valid = sendcs != 'd0;
  assign  send_ready = mul_in_ready[0];
  assign  recv_valid = mul_out_valid[0];
  assign  recv_ready = (recvcs != MAX_ITER) | ((recvcs == MAX_ITER) & outfifoready);

  //result_v端口赋值
  assign  result_v_data_in   = {resultreg_warp_id,resultreg_wb_wvd_rd_comb,resultreg_reg_idxw,resultreg_wvd,resultreg_wvd_mask};
  assign  result_v_in_valid  = (recvcs == MAX_ITER) & resultreg_wvd;
  assign  result_v_out_ready = outv_ready_i;

  //result_x端口赋值
  assign  result_x_data_in   = {resultreg_warp_id,resultreg_wb_wvd_rd[(SOFT_THREAD-HARD_THREAD+1)*`XLEN-1-:`XLEN],resultreg_reg_idxw,!resultreg_wvd};
  assign  result_x_in_valid  = (recvcs == MAX_ITER) && !resultreg_wvd;
  assign  result_x_out_ready = outx_ready_i;

  //result_v输出拆分
  assign  outv_warp_id_o   = result_v_data_out[SOFT_THREAD*`XLEN+SOFT_THREAD+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP-1-:`DEPTH_WARP];
  assign  outv_wb_wxd_rd_o = result_v_data_out[SOFT_THREAD*`XLEN+SOFT_THREAD+`REGIDX_WIDTH+`REGEXT_WIDTH-:SOFT_THREAD*`XLEN]          ;
  assign  outv_reg_idxw_o  = result_v_data_out[SOFT_THREAD+`REGIDX_WIDTH+`REGEXT_WIDTH-:`REGIDX_WIDTH+`REGEXT_WIDTH]                  ;
  assign  outv_wvd_o       = result_v_data_out[SOFT_THREAD]                                                                           ;
  assign  outv_wvd_mask_o  = result_v_data_out[SOFT_THREAD-1:0]                                                                       ;
  assign  outv_valid_o     = result_v_out_valid                                                                                       ;

  //result_x输出拆分
  assign  outx_warp_id_o   = result_x_data_out[`XLEN+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP-1-:`DEPTH_WARP];
  assign  outx_wb_wxd_rd_o = result_x_data_out[`XLEN+`REGIDX_WIDTH+`REGEXT_WIDTH-:`XLEN]                      ;
  assign  outx_reg_idwx_o  = result_x_data_out[`REGIDX_WIDTH+`REGEXT_WIDTH:1]                                 ;
  assign  outx_wxd_o       = result_x_data_out[0]                                                             ;
  assign  outx_valid_o     = result_x_out_valid                                                               ;

endmodule

  
