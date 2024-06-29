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
// Description:fpu execution
`timescale 1ns/1ns
`include "define.v"
//`include "IDecode_define.v"
//`include "fpu_ops.v"
`define FPU_NOT_FOLD 

module fpuexe #(
  //parameter EXPWIDTH    = 8,
  //parameter PRECISION   = 24,
  //parameter LEN         = EXPWIDTH + PRECISION,
  parameter SOFT_THREAD = `NUM_THREAD,
  parameter HARD_THREAD = `NUM_THREAD
  )(
  input                                     clk              ,
  input                                     rst_n            ,

  input   [`NUM_THREAD*`XLEN-1:0]           in1_i            ,
  input   [`NUM_THREAD*`XLEN-1:0]           in2_i            ,
  input   [`NUM_THREAD*`XLEN-1:0]           in3_i            ,
  input   [`NUM_THREAD-1:0]                 mask_i           ,
  input   [2:0]                             rm_i             ,
  input   [5:0]                             ctrl_alu_fn_i    ,
  //input                                     ctrl_force_rm_rtz,
  input   [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] ctrl_reg_idxw_i  ,
  input                                     ctrl_reverse_i   ,
  input   [`DEPTH_WARP-1:0]                 ctrl_wid_i       ,
  input                                     ctrl_wvd_i       ,
  input                                     ctrl_wxd_i       ,

  input                                     in_valid_i       ,
  input                                     out_x_ready_i    ,
  input                                     out_v_ready_i    ,

  output                                    in_ready_o       ,
  output                                    out_x_valid_o    ,
  output                                    out_v_valid_o    ,

  output  [`XLEN-1:0]                       out_x_wb_wxd_rd_o,
  output                                    out_x_wxd_o      ,
  output  [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] out_x_reg_idxw_o ,
  output  [`DEPTH_WARP-1:0]                 out_x_warp_id_o  ,

  output  [`NUM_THREAD*`XLEN-1:0]           out_v_wb_wvd_rd_o,
  output  [`NUM_THREAD-1:0]                 out_v_wvd_mask_o ,
  output                                    out_v_wvd_o      ,
  output  [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] out_v_reg_idxw_o ,
  output  [`DEPTH_WARP-1:0]                 out_v_warp_id_o   
  );
  localparam MAX_ITER = SOFT_THREAD / HARD_THREAD;
  //vfpu input
  reg     [5:0]                             vfpu_op_in       ;
  reg     [`NUM_THREAD*`XLEN-1:0]           vfpu_a_in        ;
  reg     [`NUM_THREAD*`XLEN-1:0]           vfpu_b_in        ;
  reg     [`NUM_THREAD*`XLEN-1:0]           vfpu_c_in        ;
  wire                                      vfpu_out_ready_in;

  //vfpu output
  wire                                      vfpu_in_ready_out ;
  wire                                      vfpu_out_valid_out;
  wire    [`NUM_THREAD*64-1:0]              vfpu_result_out   ;
  wire    [`NUM_THREAD*5-1:0]               vfpu_fflags_out   ;
  wire    [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] vfpu_regindex_out ;
  wire    [`DEPTH_WARP-1:0]                 vfpu_warpid_out   ;
  wire    [`NUM_THREAD-1:0]                 vfpu_vecmask_out  ;
  wire                                      vfpu_wvd_out      ;
  wire                                      vfpu_wxd_out      ;

  //vfpu_v2 output
  //wire                                      vfpu_v2_in_ready_out ;
  //wire                                      vfpu_v2_out_valid_out;
  //wire    [`NUM_THREAD*64-1:0]              vfpu_v2_result_out   ;
  //wire    [`NUM_THREAD*5-1:0]               vfpu_v2_fflags_out   ;
  //wire    [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] vfpu_v2_regindex_out ;
  //wire    [`DEPTH_WARP-1:0]                 vfpu_v2_warpid_out   ;
  //wire    [`NUM_THREAD-1:0]                 vfpu_v2_vecmask_out  ;
  //wire                                      vfpu_v2_wvd_out      ;
  //wire                                      vfpu_v2_wxd_out      ;

  always@(*) begin
    if(ctrl_reverse_i) begin
      vfpu_op_in = ctrl_alu_fn_i;
      vfpu_a_in  = in2_i        ;
      vfpu_b_in  = in1_i        ;
      vfpu_c_in  = in3_i        ;
    end
    else if((ctrl_alu_fn_i == `FN_VFMADD) | (ctrl_alu_fn_i == `FN_VFMSUB) | 
            (ctrl_alu_fn_i == `FN_VFNMADD) | (ctrl_alu_fn_i == `FN_VFNMSUB)) begin
      vfpu_op_in = ctrl_alu_fn_i - 10;
      vfpu_a_in  = in1_i             ;
      vfpu_b_in  = in3_i             ;
      vfpu_c_in  = in2_i             ;
    end
    else begin
      vfpu_op_in = ctrl_alu_fn_i;
      vfpu_a_in  = in1_i        ;
      vfpu_b_in  = in2_i        ;
      vfpu_c_in  = in3_i        ;
    end
  end

`ifdef FPU_NOT_FOLD
  //      vfpu
  vfpu #(
    .EXPWIDTH   (8          ),
    .PRECISION  (24         ),
    .LEN        (32         ),
    .SOFT_THREAD(SOFT_THREAD),
    .HARD_THREAD(HARD_THREAD)
  )
  U_vfpu (
    .clk            (clk                      ),                  
    .rst_n          (rst_n                    ),          

    .op_i           ({`NUM_THREAD{vfpu_op_in}}),  
    .rm_i           ({`NUM_THREAD{rm_i}}      ),        
    .a_i            (vfpu_a_in                ),      
    .b_i            (vfpu_b_in                ),          
    .c_i            (vfpu_c_in                ),          
      
    .ctrl_regindex_i(ctrl_reg_idxw_i          ),              
    .ctrl_warpid_i  (ctrl_wid_i               ),            
    .ctrl_vecmask_i (mask_i                   ),          
    .ctrl_wvd_i     (ctrl_wvd_i               ),          
    .ctrl_wxd_i     (ctrl_wxd_i               ),          

    .in_valid_i     (in_valid_i               ),                
    .out_ready_i    (vfpu_out_ready_in        ),                    

    .in_ready_o     (vfpu_in_ready_out        ),                    
    .out_valid_o    (vfpu_out_valid_out       ),                  

    .result_o       (vfpu_result_out          ),                      
    .fflags_o       (vfpu_fflags_out          ),                  
              
    .ctrl_regindex_o(vfpu_regindex_out        ),                    
    .ctrl_warpid_o  (vfpu_warpid_out          ),                      
    .ctrl_vecmask_o (vfpu_vecmask_out         ),                
    .ctrl_wvd_o     (vfpu_wvd_out             ),                    
    .ctrl_wxd_o     (vfpu_wxd_out             )
    );
`else
  //      vfpu_v2
  vfpu_v2 #(
    .EXPWIDTH   (8          ),
    .PRECISION  (24         ),
    .LEN        (32         ),
    .SOFT_THREAD(SOFT_THREAD),
    .HARD_THREAD(HARD_THREAD),
    .MAX_ITER   (MAX_ITER   )
  )
  U_vfpu_v2 (
    .clk            (clk                      ),                  
    .rst_n          (rst_n                    ),          

    .op_i           ({`NUM_THREAD{vfpu_op_in}}),  
    .rm_i           ({`NUM_THREAD{rm_i}}      ),        
    .a_i            (vfpu_a_in                ),      
    .b_i            (vfpu_b_in                ),          
    .c_i            (vfpu_c_in                ),          
      
    .ctrl_regindex_i(ctrl_reg_idxw_i          ),              
    .ctrl_warpid_i  (ctrl_wid_i               ),            
    .ctrl_vecmask_i (mask_i                   ),          
    .ctrl_wvd_i     (ctrl_wvd_i               ),          
    .ctrl_wxd_i     (ctrl_wxd_i               ),          

    .in_valid_i     (in_valid_i               ),                
    .out_ready_i    (vfpu_out_ready_in        ),                    

    .in_ready_o     (vfpu_in_ready_out        ),                    
    .out_valid_o    (vfpu_out_valid_out       ),                  

    .result_o       (vfpu_result_out          ),                      
    .fflags_o       (vfpu_fflags_out          ),                  
              
    .ctrl_regindex_o(vfpu_regindex_out        ),                    
    .ctrl_warpid_o  (vfpu_warpid_out          ),                      
    .ctrl_vecmask_o (vfpu_vecmask_out         ),                
    .ctrl_wvd_o     (vfpu_wvd_out             ),                    
    .ctrl_wxd_o     (vfpu_wxd_out             )
    );
`endif

    assign vfpu_out_ready_in = vfpu_wvd_out ? out_v_ready_i : out_x_ready_i;
    assign in_ready_o        = vfpu_in_ready_out                           ;
    //out_x
    assign out_x_valid_o     = vfpu_out_valid_out && vfpu_wxd_out;
    assign out_x_wb_wxd_rd_o = vfpu_result_out[31:0]             ;
    assign out_x_reg_idxw_o  = vfpu_regindex_out                 ;
    assign out_x_warp_id_o   = vfpu_warpid_out                   ;
    assign out_x_wxd_o       = vfpu_wxd_out                      ;

    //out_v
    assign out_v_valid_o     = vfpu_out_valid_out && vfpu_wvd_out;
    assign out_v_reg_idxw_o  = vfpu_regindex_out                 ;
    assign out_v_warp_id_o   = vfpu_warpid_out                   ;
    assign out_v_wvd_mask_o  = vfpu_vecmask_out                  ;
    assign out_v_wvd_o       = vfpu_wvd_out                      ;

    genvar i;
    generate 
      for(i=0;i<`NUM_THREAD;i=i+1) begin : A1
        assign out_v_wb_wvd_rd_o[(i+1)*`XLEN-1-:`XLEN] =vfpu_result_out[(2*i+1)*`XLEN-1-:`XLEN];
      end
    endgenerate


endmodule
