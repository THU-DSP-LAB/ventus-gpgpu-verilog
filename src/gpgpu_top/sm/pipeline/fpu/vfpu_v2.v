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
// Description:vector fpu(soft_thread!=hard_thread)
`timescale 1ns/1ns
`include "define.v"
//`include "IDecode_define.v"
//`include "fpu_ops.v"

module vfpu_v2 #(
  parameter EXPWIDTH    = 8,
  parameter PRECISION   = 24,
  parameter LEN         = EXPWIDTH + PRECISION,
  parameter SOFT_THREAD = `NUM_THREAD,
  parameter HARD_THREAD = `NUM_THREAD,
  parameter MAX_ITER    = SOFT_THREAD / HARD_THREAD
  )(
  input                                     clk            ,
  input                                     rst_n          ,

  input   [SOFT_THREAD*6-1:0]               op_i           ,
  input   [SOFT_THREAD*3-1:0]               rm_i           ,
  input   [SOFT_THREAD*LEN-1:0]             a_i            ,
  input   [SOFT_THREAD*LEN-1:0]             b_i            ,
  input   [SOFT_THREAD*LEN-1:0]             c_i            ,
  
  input   [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] ctrl_regindex_i,
  input   [`DEPTH_WARP-1:0]                 ctrl_warpid_i  ,
  input   [SOFT_THREAD-1:0]                 ctrl_vecmask_i ,
  input                                     ctrl_wvd_i     ,
  input                                     ctrl_wxd_i     ,

  input                                     in_valid_i     ,
  input                                     out_ready_i    ,

  output                                    in_ready_o     ,
  output                                    out_valid_o    ,

  output  [SOFT_THREAD*64-1:0]              result_o       ,
  output  [SOFT_THREAD*5-1:0]               fflags_o       ,
                                                   
  output  [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] ctrl_regindex_o,
  output  [`DEPTH_WARP-1:0]                 ctrl_warpid_o  ,
  output  [SOFT_THREAD-1:0]                 ctrl_vecmask_o ,
  output                                    ctrl_wvd_o     ,
  output                                    ctrl_wxd_o    
);

  reg     [6*SOFT_THREAD-1:0]               inreg_op                            ;
  reg     [3*SOFT_THREAD-1:0]               inreg_rm                            ;
  reg     [LEN*SOFT_THREAD-1:0]             inreg_a                             ;
  reg     [LEN*SOFT_THREAD-1:0]             inreg_b                             ;
  reg     [LEN*SOFT_THREAD-1:0]             inreg_c                             ;
  reg     [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] inreg_regindex                      ;
  reg     [`DEPTH_WARP-1:0]                 inreg_warpid                        ;
  reg     [SOFT_THREAD-1:0]                 inreg_vecmask                       ;
  reg                                       inreg_wvd                           ;
  reg                                       inreg_wxd                           ;

  //outreg
  reg     [64*SOFT_THREAD-1:0]              outreg_result                       ;
  reg     [5*SOFT_THREAD-1:0]               outreg_fflags                       ;
  reg     [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] outreg_regindex                     ;
  reg     [`DEPTH_WARP-1:0]                 outreg_warpid                       ;
  reg     [SOFT_THREAD-1:0]                 outreg_vecmask                      ;
  reg                                       outreg_wvd                          ;
  reg                                       outreg_wxd                          ;

  reg    [$clog2(MAX_ITER+1)-1:0]         sendns        ;
  reg    [$clog2(MAX_ITER+1)-1:0]         sendcs        ;
  wire                                    send_valid    ;
  wire                                    send_ready    ;
  wire                                    recv_valid    ;
  wire                                    recv_ready    ;
  reg    [$clog2(MAX_ITER+1)-1:0]         recvns        ;
  reg    [$clog2(MAX_ITER+1)-1:0]         recvcs        ;

  //scalar fpu
  wire                                    fpu_in_valid         [0:HARD_THREAD-1];
  wire                                    fpu_out_ready        [0:HARD_THREAD-1];
  wire  [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] fpu_ctrl_regindex    [0:HARD_THREAD-1];
  wire  [`DEPTH_WARP-1:0]                 fpu_ctrl_warpid      [0:HARD_THREAD-1];
  wire  [SOFT_THREAD-1:0]                 fpu_ctrl_vecmask     [0:HARD_THREAD-1];
  wire                                    fpu_ctrl_wvd         [0:HARD_THREAD-1];
  wire                                    fpu_ctrl_wxd         [0:HARD_THREAD-1];
  wire                                    fpu_in_ready         [0:HARD_THREAD-1];
  wire                                    fpu_out_valid        [0:HARD_THREAD-1];
  wire  [63:0]                            fpu_result           [0:HARD_THREAD-1];
  wire  [4:0]                             fpu_fflags           [0:HARD_THREAD-1];
  wire  [2:0]                             fpu_select           [0:HARD_THREAD-1];

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
        sendns = sendcs + 1;
      end
      else begin
        sendns = 'd0;
      end
    end

    else if(sendcs >= 'd1 & sendcs < MAX_ITER) begin
      if(fpu_in_valid[0] & fpu_in_ready[0]) begin
        sendns = sendcs + 1;
      end
      else begin
        sendns = sendcs;
      end
    end

    else begin
      if(fpu_in_valid[0] & fpu_in_ready[0]) begin
        if(in_valid_i & in_ready_o) begin
          sendns = 'd1;
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
    if(recvcs == MAX_ITER) begin
      if(out_ready_i & out_valid_o) begin
        if(fpu_out_ready[0] & fpu_out_valid[0]) begin
          recvns = 'd1;
        end
        else begin
          recvns = 'd0;
        end
      end
      else begin
        recvns = recvcs;
      end
    end

    else begin
      if(fpu_out_ready[0] & fpu_out_valid[0]) begin
        recvns = recvcs + 1;
      end
      else begin
        recvns = recvcs;
      end
    end
  end

  //inreg_ctrl
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
     inreg_regindex            <= 'd0;
     inreg_warpid              <= 'd0;
     inreg_vecmask             <= 'd0;
     inreg_wvd                 <= 'd0;
     inreg_wxd                 <= 'd0;
    end
    else if(sendns == 'd0) begin
     inreg_regindex            <= 'd0;
     inreg_warpid              <= 'd0;
     inreg_vecmask             <= 'd0;
     inreg_wvd                 <= 'd0;
     inreg_wxd                 <= 'd0;
    end
    else if(sendns == 'd1) begin
      if(in_valid_i & in_ready_o) begin
        inreg_regindex            <= ctrl_regindex_i      ;
        inreg_warpid              <= ctrl_warpid_i        ;
        inreg_vecmask             <= ctrl_vecmask_i       ;
        inreg_wvd                 <= ctrl_wvd_i           ;  
        inreg_wxd                 <= ctrl_wxd_i           ;
      end
      else begin
        inreg_regindex            <= inreg_regindex           ;
        inreg_warpid              <= inreg_warpid             ;
        inreg_vecmask             <= inreg_vecmask            ;
        inreg_wvd                 <= inreg_wvd                ;
        inreg_wxd                 <= inreg_wxd                ;
      end
    end
    else begin
      inreg_regindex            <= inreg_regindex           ;
      inreg_warpid              <= inreg_warpid             ;
      inreg_vecmask             <= inreg_vecmask            ;
      inreg_wvd                 <= inreg_wvd                ;
      inreg_wxd                 <= inreg_wxd                ;
    end
  end

  //outreg_ctrl
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      outreg_regindex              <= 'd0;
      outreg_warpid                <= 'd0;
      outreg_vecmask               <= 'd0;
      outreg_wvd                   <= 'd0;
      outreg_wxd                   <= 'd0;
    end
    else if(recvns == 'd0) begin
      outreg_regindex              <= 'd0;
      outreg_warpid                <= 'd0;
      outreg_vecmask               <= 'd0;
      outreg_wvd                   <= 'd0;
      outreg_wxd                   <= 'd0;
    end
    else begin
      if(fpu_out_valid[0] & fpu_out_ready[0]) begin
        if(recvns == 'd1) begin
          outreg_regindex <= fpu_ctrl_regindex[0];
          outreg_warpid   <= fpu_ctrl_warpid[0]  ;
          outreg_vecmask  <= fpu_ctrl_vecmask[0] ;
          outreg_wvd      <= fpu_ctrl_wvd[0]     ;
          outreg_wxd      <= fpu_ctrl_wxd[0]     ;
        end
        else begin
          outreg_regindex <= outreg_regindex;      
          outreg_warpid   <= outreg_warpid  ; 
          outreg_vecmask  <= outreg_vecmask ; 
          outreg_wvd      <= outreg_wvd     ; 
          outreg_wxd      <= outreg_wxd     ;
        end
      end
      else begin
        outreg_regindex <= outreg_regindex;      
        outreg_warpid   <= outreg_warpid  ; 
        outreg_vecmask  <= outreg_vecmask ; 
        outreg_wvd      <= outreg_wvd     ; 
        outreg_wxd      <= outreg_wxd     ;    
      end
    end
  end

  genvar i;
  generate
    for(i=0;i<SOFT_THREAD;i=i+1) begin : A1
      always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          inreg_op[(i+1)*6-1-:6]    <= 'd0;   
          inreg_rm[(i+1)*3-1-:3]    <= 'd0;
          inreg_a[(i+1)*LEN-1-:LEN] <= 'd0;
          inreg_b[(i+1)*LEN-1-:LEN] <= 'd0;
          inreg_c[(i+1)*LEN-1-:LEN] <= 'd0;
          //inreg_regindex            <= 'd0;
          //inreg_warpid              <= 'd0;
          //inreg_vecmask             <= 'd0;
          //inreg_wvd                 <= 'd0;
          //inreg_wxd                 <= 'd0;
        end
        else if(sendns == 'd0) begin
          inreg_op[(i+1)*6-1-:6]    <= 'd0;   
          inreg_rm[(i+1)*3-1-:3]    <= 'd0;
          inreg_a[(i+1)*LEN-1-:LEN] <= 'd0;
          inreg_b[(i+1)*LEN-1-:LEN] <= 'd0;
          inreg_c[(i+1)*LEN-1-:LEN] <= 'd0;
          //inreg_regindex            <= 'd0;
          //inreg_warpid              <= 'd0;
          //inreg_vecmask             <= 'd0;
          //inreg_wvd                 <= 'd0;
          //inreg_wxd                 <= 'd0;
        end
        else if(sendns == 'd1) begin
          if(in_valid_i & in_ready_o) begin
            inreg_op[(i+1)*6-1-:6]    <= op_i[(i+1)*6-1-:6]   ;
            inreg_rm[(i+1)*3-1-:3]    <= rm_i[(i+1)*3-1-:3]   ;
            inreg_a[(i+1)*LEN-1-:LEN] <= a_i[(i+1)*LEN-1-:LEN]; 
            inreg_b[(i+1)*LEN-1-:LEN] <= b_i[(i+1)*LEN-1-:LEN]; 
            inreg_c[(i+1)*LEN-1-:LEN] <= c_i[(i+1)*LEN-1-:LEN]; 
            //inreg_regindex            <= ctrl_regindex_i      ;
            //inreg_warpid              <= ctrl_warpid_i        ;
            //inreg_vecmask             <= ctrl_vecmask_i       ;
            //inreg_wvd                 <= ctrl_wvd_i           ;
            //inreg_wxd                 <= ctrl_wxd_i           ;
          end
          else begin
            inreg_op[(i+1)*6-1-:6]    <= inreg_op[(i+1)*6-1-:6]   ;
            inreg_rm[(i+1)*3-1-:3]    <= inreg_rm[(i+1)*3-1-:3]   ;
            inreg_a[(i+1)*LEN-1-:LEN] <= inreg_a[(i+1)*LEN-1-:LEN]; 
            inreg_b[(i+1)*LEN-1-:LEN] <= inreg_b[(i+1)*LEN-1-:LEN];  
            inreg_c[(i+1)*LEN-1-:LEN] <= inreg_c[(i+1)*LEN-1-:LEN]; 
            //inreg_regindex            <= inreg_regindex           ;
            //inreg_warpid              <= inreg_warpid             ;
            //inreg_vecmask             <= inreg_vecmask            ;
            //inreg_wvd                 <= inreg_wvd                ;
            //inreg_wxd                 <= inreg_wxd                ;
          end
        end
        else begin
          if(fpu_in_valid[0] & fpu_in_ready[0]) begin
            if(i + HARD_THREAD < SOFT_THREAD) begin
              inreg_op[(i+1)*6-1-:6]     <= inreg_op[(i+HARD_THREAD+1)*6-1-:6]   ;
              inreg_rm[(i+1)*3-1-:3]     <= inreg_rm[(i+HARD_THREAD+1)*3-1-:3]   ;
              inreg_a[(i+1)*LEN-1-:LEN]  <= inreg_a[(i+HARD_THREAD+1)*LEN-1-:LEN];
              inreg_b[(i+1)*LEN-1-:LEN]  <= inreg_b[(i+HARD_THREAD+1)*LEN-1-:LEN];
              inreg_c[(i+1)*LEN-1-:LEN]  <= inreg_c[(i+HARD_THREAD+1)*LEN-1-:LEN];
            end
            else begin
              inreg_op[(i+1)*6-1-:6]     <= 'd0; 
              inreg_rm[(i+1)*3-1-:3]     <= 'd0;
              inreg_a[(i+1)*LEN-1-:LEN]  <= 'd0;
              inreg_b[(i+1)*LEN-1-:LEN]  <= 'd0;
              inreg_c[(i+1)*LEN-1-:LEN]  <= 'd0;
            end
          end
          else begin
            inreg_op[(i+1)*6-1-:6]    <= inreg_op[(i+1)*6-1-:6]   ;
            inreg_rm[(i+1)*3-1-:3]    <= inreg_rm[(i+1)*3-1-:3]   ;
            inreg_a[(i+1)*LEN-1-:LEN] <= inreg_a[(i+1)*LEN-1-:LEN]; 
            inreg_b[(i+1)*LEN-1-:LEN] <= inreg_b[(i+1)*LEN-1-:LEN];  
            inreg_c[(i+1)*LEN-1-:LEN] <= inreg_c[(i+1)*LEN-1-:LEN]; 
          end
        end
      end

      always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          outreg_result[(i+1)*64-1-:64]<= 'd0; 
          outreg_fflags[(i+1)*5-1-:5]  <= 'd0;
          //outreg_regindex              <= 'd0;
          //outreg_warpid                <= 'd0;
          //outreg_vecmask               <= 'd0;
          //outreg_wvd                   <= 'd0;
          //outreg_wxd                   <= 'd0;
        end
        else if(recvns == 'd0) begin
          outreg_result[(i+1)*64-1-:64]<= 'd0; 
          outreg_fflags[(i+1)*5-1-:5]  <= 'd0;
          //outreg_regindex              <= 'd0;
          //outreg_warpid                <= 'd0;
          //outreg_vecmask               <= 'd0;
          //outreg_wvd                   <= 'd0;
          //outreg_wxd                   <= 'd0;
        end
        else begin
          if(fpu_out_valid[0] & fpu_out_ready[0]) begin
            if(i + HARD_THREAD < SOFT_THREAD) begin
              outreg_result[(i+1)*64-1-:64] <= outreg_result[(i+HARD_THREAD+1)*64-1-:64];
              outreg_fflags[(i+1)*5-1-:5]   <= outreg_fflags[(i+HARD_THREAD+1)*5-1-:5]  ;
            end
            else begin
              outreg_result[(i+1)*64-1-:64] <= fpu_result[i+HARD_THREAD-SOFT_THREAD];
              outreg_fflags[(i+1)*5-1-:5]   <= fpu_fflags[i+HARD_THREAD-SOFT_THREAD];
            end

            /*if(recvns == 'd1) begin
              outreg_regindex <= fpu_ctrl_regindex[0];
              outreg_warpid   <= fpu_ctrl_warpid[0]  ;
              outreg_vecmask  <= fpu_ctrl_vecmask[0] ;
              outreg_wvd      <= fpu_ctrl_wvd[0]     ;
              outreg_wxd      <= fpu_ctrl_wxd[0]     ;
            end
            else begin
              outreg_regindex <= outreg_regindex;      
              outreg_warpid   <= outreg_warpid  ; 
              outreg_vecmask  <= outreg_vecmask ; 
              outreg_wvd      <= outreg_wvd     ; 
              outreg_wxd      <= outreg_wxd     ;
            end*/
          end
          else begin
            outreg_result[(i+1)*64-1-:64] <= outreg_result[(i+1)*64-1-:64];
            outreg_fflags[(i+1)*5-1-:5]   <= outreg_fflags[(i+1)*5-1-:5]  ;
            //outreg_regindex               <= outreg_regindex ;      
            //outreg_warpid                 <= outreg_warpid   ; 
            //outreg_vecmask                <= outreg_vecmask  ; 
            //outreg_wvd                    <= outreg_wvd      ; 
            //outreg_wxd                    <= outreg_wxd      ;
          end
        end
      end

    assign result_o[(i+1)*64-1-:64] = outreg_result[(i+1)*64-1-:64];
    assign fflags_o[(i+1)*5-1-:5]   = outreg_fflags[(i+1)*5-1-:5]  ;                                          
    end
  endgenerate

  //例化第一个scalar_fpu,CTRLGEN open
  scalar_fpu #(
    .EXPWIDTH(EXPWIDTH),
    .PRECISION(PRECISION),
    .SOFT_THREAD(SOFT_THREAD),
    .HARD_THREAD(HARD_THREAD)
  )
  U_scalar_fpu_with_ctrl (
  .clk            (clk                 ),  
  .rst_n          (rst_n               ),
                                       
  .op_i           (inreg_op[5:0]       ),
  .a_i            (inreg_a[LEN-1:0]    ),
  .b_i            (inreg_b[LEN-1:0]    ),
  .c_i            (inreg_c[LEN-1:0]    ),
  .rm_i           (inreg_rm[2:0]       ),
                            
  .ctrl_regindex_i(inreg_regindex      ),
  .ctrl_warpid_i  (inreg_warpid        ),
  .ctrl_vecmask_i (inreg_vecmask       ),
  .ctrl_wvd_i     (inreg_wvd           ),
  .ctrl_wxd_i     (inreg_wxd           ),
  .ctrl_regindex_o(fpu_ctrl_regindex[0]), 
  .ctrl_warpid_o  (fpu_ctrl_warpid[0]  ), 
  .ctrl_vecmask_o (fpu_ctrl_vecmask[0] ),
  .ctrl_wvd_o     (fpu_ctrl_wvd[0]     ), 
  .ctrl_wxd_o     (fpu_ctrl_wxd[0]     ), 
                                       
  .in_valid_i     (fpu_in_valid[0]     ),          
  .out_ready_i    (fpu_out_ready[0]    ),
                              
  .in_ready_o     (fpu_in_ready[0]     ),
  .out_valid_o    (fpu_out_valid[0]    ),
                              
  .select_o       (fpu_select[0]       ),
  .result_o       (fpu_result[0]       ),
  .fflags_o       (fpu_fflags[0]       )
  );

  assign fpu_in_valid[0]  = (sendcs != 'd0);
  assign fpu_out_ready[0] = out_ready_i || (recvcs != MAX_ITER);

  //例化剩余HARD_THREAD-1个scalar_fpu,CTRLGEN close
  genvar j;
  generate
    for(j=1;j<HARD_THREAD;j=j+1) begin : B1
      scalar_fpu_no_ctrl #(
        .EXPWIDTH(EXPWIDTH),
        .PRECISION(PRECISION),
        .SOFT_THREAD(SOFT_THREAD),
        .HARD_THREAD(HARD_THREAD)
      )
      U_scalar_fpu_without_ctrl (
      .clk            (clk                      ),  
      .rst_n          (rst_n                    ),
                                           
      .op_i           (inreg_op[(j+1)*6-1-:6]   ),
      .a_i            (inreg_a[(j+1)*LEN-1-:LEN]),
      .b_i            (inreg_b[(j+1)*LEN-1-:LEN]),
      .c_i            (inreg_c[(j+1)*LEN-1-:LEN]),
      .rm_i           (inreg_rm[(j+1)*3-1-:3]   ),
                                  
      .in_valid_i     (fpu_in_valid[j]          ),          
      .out_ready_i    (fpu_out_ready[j]         ),
                                  
      .in_ready_o     (fpu_in_ready[j]          ),
      .out_valid_o    (fpu_out_valid[j]         ),
                                  
      .select_o       (fpu_select[j]            ),
      .result_o       (fpu_result[j]            ),
      .fflags_o       (fpu_fflags[j]            )
      );

    assign fpu_in_valid[j]  = (sendcs != 'd0);
    assign fpu_out_ready[j] = out_ready_i || (recvcs != MAX_ITER);
    end
  endgenerate

  assign in_ready_o      = (sendcs == 'd0) || (sendcs == MAX_ITER) && fpu_in_ready[0];
  assign out_valid_o     = recvcs == MAX_ITER                                        ;
  assign ctrl_regindex_o = outreg_regindex                                           ;
  assign ctrl_warpid_o   = outreg_warpid                                             ;
  assign ctrl_vecmask_o  = outreg_vecmask                                            ;
  assign ctrl_wvd_o      = outreg_wvd                                                ;
  assign ctrl_wxd_o      = outreg_wxd                                                ;

endmodule
