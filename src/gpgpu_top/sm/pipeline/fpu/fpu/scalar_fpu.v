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
// Description:scalar fpu
`timescale 1ns/1ns
//`include "fpu_ops.v"
`include "define.v"
`define CTRLGEN

module scalar_fpu #(
  parameter EXPWIDTH    = 8,
  parameter PRECISION   = 24,
  parameter SOFT_THREAD = 4,
  parameter HARD_THREAD = 4
)(
  input                                         clk            ,
  input                                         rst_n          ,

  input      [5:0]                              op_i           ,
  input      [EXPWIDTH+PRECISION-1:0]           a_i            ,
  input      [EXPWIDTH+PRECISION-1:0]           b_i            ,
  input      [EXPWIDTH+PRECISION-1:0]           c_i            ,
  input      [2:0]                              rm_i           ,
`ifdef CTRLGEN
  input      [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]  ctrl_regindex_i,
  input      [`DEPTH_WARP-1:0]                  ctrl_warpid_i  ,
  input      [SOFT_THREAD-1:0]                  ctrl_vecmask_i ,
  input                                         ctrl_wvd_i     ,
  input                                         ctrl_wxd_i     ,
`endif
 
  input                                         in_valid_i     ,
  input                                         out_ready_i    ,

  output reg                                    in_ready_o     ,
  output reg                                    out_valid_o    ,

  output     [2:0]                              select_o       ,
  output reg [63:0]                             result_o       ,
  output reg [4:0]                              fflags_o       
`ifdef CTRLGEN
                                                               ,
  output reg [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]  ctrl_regindex_o,
  output reg [`DEPTH_WARP-1:0]                  ctrl_warpid_o  ,
  output reg [SOFT_THREAD-1:0]                  ctrl_vecmask_o ,
  output reg                                    ctrl_wvd_o     ,
  output reg                                    ctrl_wxd_o     
`endif
  );

  wire    [2:0]                             fu             ;
  wire    [4:0]                             choose_oh      ;
  wire    [2:0]                             choose_bin     ;
  
  //fma 
  wire    [2:0]                             fma_op_in      ;
  wire    [2:0]                             fma_rm_in      ;
  wire    [EXPWIDTH+PRECISION-1:0]          fma_a_in       ;
  wire    [EXPWIDTH+PRECISION-1:0]          fma_b_in       ;
  wire    [EXPWIDTH+PRECISION-1:0]          fma_c_in       ;
  wire                                      fma_in_valid   ;
  wire                                      fma_out_ready  ;
  wire                                      fma_in_ready   ;
  wire                                      fma_out_valid  ;
  wire    [EXPWIDTH+PRECISION-1:0]          fma_result_out ;
  wire    [4:0]                             fma_fflags_out ;
`ifdef CTRLGEN
  wire    [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] fma_ctrl_regindex_in ;
  wire    [`DEPTH_WARP-1:0]                 fma_ctrl_warpid_in   ;
  wire    [SOFT_THREAD-1:0]                 fma_ctrl_vecmask_in  ;
  wire                                      fma_ctrl_wvd_in      ;
  wire                                      fma_ctrl_wxd_in      ;
  wire    [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] fma_ctrl_regindex_out;
  wire    [`DEPTH_WARP-1:0]                 fma_ctrl_warpid_out  ;
  wire    [SOFT_THREAD-1:0]                 fma_ctrl_vecmask_out ;
  wire                                      fma_ctrl_wvd_out     ;
  wire                                      fma_ctrl_wxd_out     ;
`endif

  //fcmp
  wire    [2:0]                             fcmp_op_in      ;
  //wire    [2:0]                             fcmp_rm_in      ;
  wire    [EXPWIDTH+PRECISION-1:0]          fcmp_a_in       ;
  wire    [EXPWIDTH+PRECISION-1:0]          fcmp_b_in       ;
  //wire    [EXPWIDTH+PRECISION-1:0]          fcmp_c_in       ;
  wire                                      fcmp_in_valid   ;
  wire                                      fcmp_out_ready  ;
  wire                                      fcmp_in_ready   ;
  wire                                      fcmp_out_valid  ;
  wire    [EXPWIDTH+PRECISION-1:0]          fcmp_result_out ;
  wire    [4:0]                             fcmp_fflags_out ;
`ifdef CTRLGEN
  wire    [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] fcmp_ctrl_regindex_in ;
  wire    [`DEPTH_WARP-1:0]                 fcmp_ctrl_warpid_in   ;
  wire    [SOFT_THREAD-1:0]                 fcmp_ctrl_vecmask_in  ;
  wire                                      fcmp_ctrl_wvd_in      ;
  wire                                      fcmp_ctrl_wxd_in      ;
  wire    [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] fcmp_ctrl_regindex_out;
  wire    [`DEPTH_WARP-1:0]                 fcmp_ctrl_warpid_out  ;
  wire    [SOFT_THREAD-1:0]                 fcmp_ctrl_vecmask_out ;
  wire                                      fcmp_ctrl_wvd_out     ;
  wire                                      fcmp_ctrl_wxd_out     ;
`endif

  //fpmv
  wire    [2:0]                             fpmv_op_in      ;
  //wire    [2:0]                             fpmv_rm_in      ;
  wire    [EXPWIDTH+PRECISION-1:0]          fpmv_a_in       ;
  wire    [EXPWIDTH+PRECISION-1:0]          fpmv_b_in       ;
  //wire    [EXPWIDTH+PRECISION-1:0]          fpmv_c_in       ;
  wire                                      fpmv_in_valid   ;
  wire                                      fpmv_out_ready  ;
  wire                                      fpmv_in_ready   ;
  wire                                      fpmv_out_valid  ;
  wire    [EXPWIDTH+PRECISION-1:0]          fpmv_result_out ;
  wire    [4:0]                             fpmv_fflags_out ;
`ifdef CTRLGEN
  wire    [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] fpmv_ctrl_regindex_in ;
  wire    [`DEPTH_WARP-1:0]                 fpmv_ctrl_warpid_in   ;
  wire    [SOFT_THREAD-1:0]                 fpmv_ctrl_vecmask_in  ;
  wire                                      fpmv_ctrl_wvd_in      ;
  wire                                      fpmv_ctrl_wxd_in      ;
  wire    [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] fpmv_ctrl_regindex_out;
  wire    [`DEPTH_WARP-1:0]                 fpmv_ctrl_warpid_out  ;
  wire    [SOFT_THREAD-1:0]                 fpmv_ctrl_vecmask_out ;
  wire                                      fpmv_ctrl_wvd_out     ;
  wire                                      fpmv_ctrl_wxd_out     ;
`endif

  //fp_to_int
  wire    [2:0]                             f2i_op_in        ;
  wire    [2:0]                             f2i_rm_in        ;
  wire    [EXPWIDTH+PRECISION-1:0]          f2i_a_in         ;
  wire    [63:0]                            f2i_a_in_64      ;
  //wire    [EXPWIDTH+PRECISION-1:0]          f2i_b_in         ;
  //wire    [EXPWIDTH+PRECISION-1:0]          f2i_c_in         ;
  wire                                      f2i_in_valid     ;
  wire                                      f2i_out_ready    ;
  wire                                      f2i_in_ready     ;
  wire                                      f2i_out_valid    ;
  wire    [EXPWIDTH+PRECISION-1:0]          f2i_result_out   ;
  wire    [63:0]                            f2i_result_out_64;
  wire    [4:0]                             f2i_fflags_out   ;
`ifdef CTRLGEN
  wire    [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] f2i_ctrl_regindex_in ;
  wire    [`DEPTH_WARP-1:0]                 f2i_ctrl_warpid_in   ;
  wire    [SOFT_THREAD-1:0]                 f2i_ctrl_vecmask_in  ;
  wire                                      f2i_ctrl_wvd_in      ;
  wire                                      f2i_ctrl_wxd_in      ;
  wire    [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] f2i_ctrl_regindex_out;
  wire    [`DEPTH_WARP-1:0]                 f2i_ctrl_warpid_out  ;
  wire    [SOFT_THREAD-1:0]                 f2i_ctrl_vecmask_out ;
  wire                                      f2i_ctrl_wvd_out     ;
  wire                                      f2i_ctrl_wxd_out     ;
`endif

  //int_to_fp
  wire    [2:0]                             i2f_op_in        ;
  wire    [2:0]                             i2f_rm_in        ;
  wire    [EXPWIDTH+PRECISION-1:0]          i2f_a_in         ;
  wire    [63:0]                            i2f_a_in_64      ;
  //wire    [EXPWIDTH+PRECISION-1:0]          i2f_b_in         ;
  //wire    [EXPWIDTH+PRECISION-1:0]          i2f_c_in         ;
  wire                                      i2f_in_valid     ;
  wire                                      i2f_out_ready    ;
  wire                                      i2f_in_ready     ;
  wire                                      i2f_out_valid    ;
  wire    [EXPWIDTH+PRECISION-1:0]          i2f_result_out   ;
  wire    [63:0]                            i2f_result_out_64;
  wire    [4:0]                             i2f_fflags_out   ;
`ifdef CTRLGEN
  wire    [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] i2f_ctrl_regindex_in ;
  wire    [`DEPTH_WARP-1:0]                 i2f_ctrl_warpid_in   ;
  wire    [SOFT_THREAD-1:0]                 i2f_ctrl_vecmask_in  ;
  wire                                      i2f_ctrl_wvd_in      ;
  wire                                      i2f_ctrl_wxd_in      ;
  wire    [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] i2f_ctrl_regindex_out;
  wire    [`DEPTH_WARP-1:0]                 i2f_ctrl_warpid_out  ;
  wire    [SOFT_THREAD-1:0]                 i2f_ctrl_vecmask_out ;
  wire                                      i2f_ctrl_wvd_out     ;
  wire                                      i2f_ctrl_wxd_out     ;
`endif

  //fma input
  assign fu                   = op_i[5:3];
  assign fma_op_in            = (fu == 'd0) ? op_i[2:0] : 'd0; 
  assign fma_rm_in            = (fu == 'd0) ? rm_i      : 'd0;
  assign fma_a_in             = (fu == 'd0) ? a_i       : 'd0;
  assign fma_b_in             = (fu == 'd0) ? b_i       : 'd0;
  assign fma_c_in             = (fu == 'd0) ? c_i       : 'd0;
  assign fma_in_valid         = (fu == 'd0) && in_valid_i    ;
  assign fma_out_ready        = out_ready_i                  ;  
`ifdef CTRLGEN
  assign fma_ctrl_regindex_in = (fu == 'd0) ? ctrl_regindex_i : 'd0;
  assign fma_ctrl_warpid_in   = (fu == 'd0) ? ctrl_warpid_i   : 'd0;
  assign fma_ctrl_vecmask_in  = (fu == 'd0) ? ctrl_vecmask_i  : 'd0;
  assign fma_ctrl_wvd_in      = (fu == 'd0) ? ctrl_wvd_i      : 'd0;
  assign fma_ctrl_wxd_in      = (fu == 'd0) ? ctrl_wxd_i      : 'd0;
`endif

  //fcmp input
  assign fcmp_op_in            = (fu == 'd1) ? op_i[2:0] : 'd0; 
  //assign fcmp_rm_in            = (fu == 'd1) ? rm_i      : 'd0;
  assign fcmp_a_in             = (fu == 'd1) ? a_i       : 'd0;
  assign fcmp_b_in             = (fu == 'd1) ? b_i       : 'd0;
  //assign fcmp_c_in             = (fu == 'd1) ? c_i       : 'd0;
  assign fcmp_in_valid         = (fu == 'd1) && in_valid_i    ;
  assign fcmp_out_ready        = out_ready_i                  ;  
`ifdef CTRLGEN
  assign fcmp_ctrl_regindex_in = (fu == 'd1) ? ctrl_regindex_i : 'd0;
  assign fcmp_ctrl_warpid_in   = (fu == 'd1) ? ctrl_warpid_i   : 'd0;
  assign fcmp_ctrl_vecmask_in  = (fu == 'd1) ? ctrl_vecmask_i  : 'd0;
  assign fcmp_ctrl_wvd_in      = (fu == 'd1) ? ctrl_wvd_i      : 'd0;
  assign fcmp_ctrl_wxd_in      = (fu == 'd1) ? ctrl_wxd_i      : 'd0;
`endif

  //fpmv input
  assign fpmv_op_in            = (fu == 'd2) ? op_i[2:0] : 'd0; 
  //assign fpmv_rm_in            = (fu == 'd2) ? rm_i      : 'd0;
  assign fpmv_a_in             = (fu == 'd2) ? a_i       : 'd0;
  assign fpmv_b_in             = (fu == 'd2) ? b_i       : 'd0;
  //assign fpmv_c_in             = (fu == 'd2) ? c_i       : 'd0;
  assign fpmv_in_valid         = (fu == 'd2) && in_valid_i    ;
  assign fpmv_out_ready        = out_ready_i                  ;  
`ifdef CTRLGEN
  assign fpmv_ctrl_regindex_in = (fu == 'd2) ? ctrl_regindex_i : 'd0;
  assign fpmv_ctrl_warpid_in   = (fu == 'd2) ? ctrl_warpid_i   : 'd0;
  assign fpmv_ctrl_vecmask_in  = (fu == 'd2) ? ctrl_vecmask_i  : 'd0;
  assign fpmv_ctrl_wvd_in      = (fu == 'd2) ? ctrl_wvd_i      : 'd0;
  assign fpmv_ctrl_wxd_in      = (fu == 'd2) ? ctrl_wxd_i      : 'd0;
`endif

  //f2i input
  assign f2i_op_in            = (fu == 'd3) ? op_i[2:0] : 'd0             ; 
  assign f2i_rm_in            = (fu == 'd3) ? rm_i      : 'd0             ;
  assign f2i_a_in             = (fu == 'd3) ? a_i       : 'd0             ;
  assign f2i_a_in_64          = {{(64-EXPWIDTH-PRECISION){1'b0}},f2i_a_in};
  //assign f2i_b_in             = (fu == 'd3) ? b_i       : 'd0             ;
  //assign f2i_c_in             = (fu == 'd3) ? c_i       : 'd0             ;
  assign f2i_in_valid         = (fu == 'd3) && in_valid_i                 ;
  assign f2i_out_ready        = out_ready_i                               ;  
`ifdef CTRLGEN
  assign f2i_ctrl_regindex_in = (fu == 'd3) ? ctrl_regindex_i : 'd0;
  assign f2i_ctrl_warpid_in   = (fu == 'd3) ? ctrl_warpid_i   : 'd0;
  assign f2i_ctrl_vecmask_in  = (fu == 'd3) ? ctrl_vecmask_i  : 'd0;
  assign f2i_ctrl_wvd_in      = (fu == 'd3) ? ctrl_wvd_i      : 'd0;
  assign f2i_ctrl_wxd_in      = (fu == 'd3) ? ctrl_wxd_i      : 'd0;
`endif

  //i2f input
  assign i2f_op_in            = (fu == 'd4) ? op_i[2:0] : 'd0             ; 
  assign i2f_rm_in            = (fu == 'd4) ? rm_i      : 'd0             ;
  assign i2f_a_in             = (fu == 'd4) ? a_i       : 'd0             ;
  assign i2f_a_in_64          = {{(64-EXPWIDTH-PRECISION){1'b0}},i2f_a_in};
  //assign i2f_b_in             = (fu == 'd4) ? b_i       : 'd0             ;
  //assign i2f_c_in             = (fu == 'd4) ? c_i       : 'd0             ;
  assign i2f_in_valid         = (fu == 'd4) && in_valid_i                 ;
  assign i2f_out_ready        = out_ready_i                               ;  
`ifdef CTRLGEN
  assign i2f_ctrl_regindex_in = (fu == 'd4) ? ctrl_regindex_i : 'd0;
  assign i2f_ctrl_warpid_in   = (fu == 'd4) ? ctrl_warpid_i   : 'd0;
  assign i2f_ctrl_vecmask_in  = (fu == 'd4) ? ctrl_vecmask_i  : 'd0;
  assign i2f_ctrl_wvd_in      = (fu == 'd4) ? ctrl_wvd_i      : 'd0;
  assign i2f_ctrl_wxd_in      = (fu == 'd4) ? ctrl_wxd_i      : 'd0;
`endif

  //例化fma
  fma #(
    .EXPWIDTH(EXPWIDTH),
    .PRECISION(PRECISION),
    .SOFTTHREAD(SOFT_THREAD),
    .HARDTHREAD(HARD_THREAD)
  )
  U_fma (
    .clk            (clk                  ),  
    .rst_n          (rst_n                ),      
    .in_valid_i     (fma_in_valid         ),        
    .in_ready_o     (fma_in_ready         ),  
    .in_op_i        (fma_op_in            ),  
    .in_a_i         (fma_a_in             ),           
    .in_b_i         (fma_b_in             ),              
    .in_c_i         (fma_c_in             ),              
    .in_rm_i        (fma_rm_in            ),            
`ifdef CTRLGEN
    .in_reg_index_i (fma_ctrl_regindex_in ),            
    .in_warp_id_i   (fma_ctrl_warpid_in   ),            
    .in_vec_mask_i  (fma_ctrl_vecmask_in  ),          
    .in_wvd_i       (fma_ctrl_wvd_in      ),      
    .in_wxd_i       (fma_ctrl_wxd_in      ),   
    .out_reg_index_o(fma_ctrl_regindex_out),         
    .out_warp_id_o  (fma_ctrl_warpid_out  ),      
    .out_vec_mask_o (fma_ctrl_vecmask_out ),       
    .out_wvd_o      (fma_ctrl_wvd_out     ),     
    .out_wxd_o      (fma_ctrl_wxd_out     ),       
`endif 
    .out_valid_o    (fma_out_valid        ),              
    .out_ready_i    (fma_out_ready        ),              
    .out_result_o   (fma_result_out       ),                
    .out_fflags_o   (fma_fflags_out       )
    );

  //例化fcmp
  fcmp #(
    .EXPWIDTH(EXPWIDTH),
    .PRECISION(PRECISION),
    .SOFT_THREAD(SOFT_THREAD)
  )
  U_fcmp (
    .clk            (clk                   ),                    
    .rst_n          (rst_n                 ), 
    .op_i           (fcmp_op_in            ),  
    .a_i            (fcmp_a_in             ),     
    .b_i            (fcmp_b_in             ),             
    .in_valid_i     (fcmp_in_valid         ),                   
    .in_ready_o     (fcmp_in_ready         ),                   
    .out_ready_i    (fcmp_out_ready        ),                    
    .out_valid_o    (fcmp_out_valid        ),                                 
`ifdef CTRLGEN
    .ctrl_regindex_i(fcmp_ctrl_regindex_in ),               
    .ctrl_warpid_i  (fcmp_ctrl_warpid_in   ),                       
    .ctrl_vecmask_i (fcmp_ctrl_vecmask_in  ),          
    .ctrl_wvd_i     (fcmp_ctrl_wvd_in      ),              
    .ctrl_wxd_i     (fcmp_ctrl_wxd_in      ),                    
    .ctrl_regindex_o(fcmp_ctrl_regindex_out),                        
    .ctrl_warpid_o  (fcmp_ctrl_warpid_out  ),                          
    .ctrl_vecmask_o (fcmp_ctrl_vecmask_out ),                         
    .ctrl_wvd_o     (fcmp_ctrl_wvd_out     ),                       
    .ctrl_wxd_o     (fcmp_ctrl_wxd_out     ),                     
`endif
    .result_o       (fcmp_result_out       ),               
    .fflags_o       (fcmp_fflags_out       )
    );

  //例化fpmv
  fpmv #(
    .EXPWIDTH(EXPWIDTH),
    .PRECISION(PRECISION),
    .SOFT_THREAD(SOFT_THREAD)
  )
  U_fpmv (
    .clk            (clk                   ),                    
    .rst_n          (rst_n                 ), 
    .op_i           (fpmv_op_in            ),  
    .a_i            (fpmv_a_in             ),     
    .b_i            (fpmv_b_in             ),             
    .in_valid_i     (fpmv_in_valid         ),                   
    .in_ready_o     (fpmv_in_ready         ),                   
    .out_ready_i    (fpmv_out_ready        ),                    
    .out_valid_o    (fpmv_out_valid        ),                                 
`ifdef CTRLGEN
    .ctrl_regindex_i(fpmv_ctrl_regindex_in ),               
    .ctrl_warpid_i  (fpmv_ctrl_warpid_in   ),                       
    .ctrl_vecmask_i (fpmv_ctrl_vecmask_in  ),          
    .ctrl_wvd_i     (fpmv_ctrl_wvd_in      ),              
    .ctrl_wxd_i     (fpmv_ctrl_wxd_in      ),                    
    .ctrl_regindex_o(fpmv_ctrl_regindex_out),                        
    .ctrl_warpid_o  (fpmv_ctrl_warpid_out  ),                          
    .ctrl_vecmask_o (fpmv_ctrl_vecmask_out ),                         
    .ctrl_wvd_o     (fpmv_ctrl_wvd_out     ),                       
    .ctrl_wxd_o     (fpmv_ctrl_wxd_out     ),                     
`endif
    .result_o       (fpmv_result_out       ),               
    .fflags_o       (fpmv_fflags_out       )
    );

  //例化f2i
  fp_to_int #(
    .EXPWIDTH(EXPWIDTH),
    .PRECISION(PRECISION),
    .SOFT_THREAD(SOFT_THREAD)
  )
  U_f2i (
    .clk            (clk                  ),                    
    .rst_n          (rst_n                ), 
    .op_i           (f2i_op_in            ),  
    .a_i            (f2i_a_in_64          ),     
    .rm_i           (f2i_rm_in            ),             
    .in_valid_i     (f2i_in_valid         ),                   
    .in_ready_o     (f2i_in_ready         ),                   
    .out_ready_i    (f2i_out_ready        ),                    
    .out_valid_o    (f2i_out_valid        ),                                 
`ifdef CTRLGEN
    .ctrl_regindex_i(f2i_ctrl_regindex_in ),               
    .ctrl_warpid_i  (f2i_ctrl_warpid_in   ),                       
    .ctrl_vecmask_i (f2i_ctrl_vecmask_in  ),          
    .ctrl_wvd_i     (f2i_ctrl_wvd_in      ),              
    .ctrl_wxd_i     (f2i_ctrl_wxd_in      ),                    
    .ctrl_regindex_o(f2i_ctrl_regindex_out),                        
    .ctrl_warpid_o  (f2i_ctrl_warpid_out  ),                          
    .ctrl_vecmask_o (f2i_ctrl_vecmask_out ),                         
    .ctrl_wvd_o     (f2i_ctrl_wvd_out     ),                       
    .ctrl_wxd_o     (f2i_ctrl_wxd_out     ),                     
`endif
    .result_o       (f2i_result_out_64    ),               
    .fflags_o       (f2i_fflags_out       )
    );

  //例化i2f
  int_to_fp #(
    .EXPWIDTH(EXPWIDTH),
    .PRECISION(PRECISION),
    .SOFT_THREAD(SOFT_THREAD)
  )
  U_i2f (
    .clk            (clk                  ),                    
    .rst_n          (rst_n                ), 
    .op_i           (i2f_op_in            ),  
    .a_i            (i2f_a_in_64          ),     
    .rm_i           (i2f_rm_in            ),             
    .in_valid_i     (i2f_in_valid         ),                   
    .in_ready_o     (i2f_in_ready         ),                   
    .out_ready_i    (i2f_out_ready        ),                    
    .out_valid_o    (i2f_out_valid        ),                                 
`ifdef CTRLGEN
    .ctrl_regindex_i(i2f_ctrl_regindex_in ),               
    .ctrl_warpid_i  (i2f_ctrl_warpid_in   ),                       
    .ctrl_vecmask_i (i2f_ctrl_vecmask_in  ),          
    .ctrl_wvd_i     (i2f_ctrl_wvd_in      ),              
    .ctrl_wxd_i     (i2f_ctrl_wxd_in      ),                    
    .ctrl_regindex_o(i2f_ctrl_regindex_out),                        
    .ctrl_warpid_o  (i2f_ctrl_warpid_out  ),                          
    .ctrl_vecmask_o (i2f_ctrl_vecmask_out ),                         
    .ctrl_wvd_o     (i2f_ctrl_wvd_out     ),                       
    .ctrl_wxd_o     (i2f_ctrl_wxd_out     ),                     
`endif
    .result_o       (i2f_result_out_64    ),               
    .fflags_o       (i2f_fflags_out       )
    );

  assign f2i_result_out = f2i_result_out_64[EXPWIDTH+PRECISION-1:0];
  assign i2f_result_out = i2f_result_out_64[EXPWIDTH+PRECISION-1:0];

  /*//in_ready_o
  always@(*) begin
    case(fu)
      'd0     : in_ready_o = fma_in_ready ;
      'd1     : in_ready_o = fcmp_in_ready;
      'd2     : in_ready_o = fpmv_in_ready;
      'd3     : in_ready_o = f2i_in_ready ;
      'd4     : in_ready_o = i2f_in_ready ;
      default : in_ready_o = 'd0          ;
    endcase
  end*/

  //arbiter
  fixed_pri_arb #(
    .ARB_WIDTH(5)
  )
  U_arbiter (
    .req  ({i2f_out_valid,f2i_out_valid,fpmv_out_valid,fcmp_out_valid,fma_out_valid}),
    .grant(choose_oh                                                                )
    );

  //one2bin
  one2bin #(
    .ONE_WIDTH(5),
    .BIN_WIDTH(3)
  )
  U_one2bin (
    .oh (choose_oh ),
    .bin(choose_bin)
    );

  //select
  assign select_o = choose_bin;

  always@(*) begin
    case(choose_bin)
      'd0     : begin
        result_o        = fma_result_out       ;
        fflags_o        = fma_fflags_out       ;
`ifdef CTRLGEN
        ctrl_regindex_o = fma_ctrl_regindex_out;
        ctrl_warpid_o   = fma_ctrl_warpid_out  ;
        ctrl_vecmask_o  = fma_ctrl_vecmask_out ;
        ctrl_wvd_o      = fma_ctrl_wvd_out     ;
        ctrl_wxd_o      = fma_ctrl_wxd_out     ;
`endif
        out_valid_o     = fma_out_valid        ;
        in_ready_o      = fma_in_ready         ;
      end

      'd1     : begin
        result_o        = fcmp_result_out       ;
        fflags_o        = fcmp_fflags_out       ;
`ifdef CTRLGEN
        ctrl_regindex_o = fcmp_ctrl_regindex_out;
        ctrl_warpid_o   = fcmp_ctrl_warpid_out  ;
        ctrl_vecmask_o  = fcmp_ctrl_vecmask_out ;
        ctrl_wvd_o      = fcmp_ctrl_wvd_out     ;
        ctrl_wxd_o      = fcmp_ctrl_wxd_out     ;
`endif
        out_valid_o     = fcmp_out_valid        ;
        in_ready_o      = fcmp_in_ready         ;
      end

      'd2     : begin
        result_o        = fpmv_result_out       ;
        fflags_o        = fpmv_fflags_out       ;
`ifdef CTRLGEN
        ctrl_regindex_o = fpmv_ctrl_regindex_out;
        ctrl_warpid_o   = fpmv_ctrl_warpid_out  ;
        ctrl_vecmask_o  = fpmv_ctrl_vecmask_out ;
        ctrl_wvd_o      = fpmv_ctrl_wvd_out     ;
        ctrl_wxd_o      = fpmv_ctrl_wxd_out     ;
`endif
        out_valid_o     = fpmv_out_valid        ;
        in_ready_o      = fpmv_in_ready         ;
      end

      'd3     : begin
        result_o        = f2i_result_out       ;
        fflags_o        = f2i_fflags_out       ;
`ifdef CTRLGEN
        ctrl_regindex_o = f2i_ctrl_regindex_out;
        ctrl_warpid_o   = f2i_ctrl_warpid_out  ;
        ctrl_vecmask_o  = f2i_ctrl_vecmask_out ;
        ctrl_wvd_o      = f2i_ctrl_wvd_out     ;
        ctrl_wxd_o      = f2i_ctrl_wxd_out     ;
`endif
        out_valid_o     = f2i_out_valid        ;
        in_ready_o      = f2i_in_ready         ;
      end

      'd4     : begin
        result_o        = i2f_result_out       ;
        fflags_o        = i2f_fflags_out       ;
`ifdef CTRLGEN
        ctrl_regindex_o = i2f_ctrl_regindex_out;
        ctrl_warpid_o   = i2f_ctrl_warpid_out  ;
        ctrl_vecmask_o  = i2f_ctrl_vecmask_out ;
        ctrl_wvd_o      = i2f_ctrl_wvd_out     ;
        ctrl_wxd_o      = i2f_ctrl_wxd_out     ;
`endif
        out_valid_o     = i2f_out_valid        ;
        in_ready_o      = i2f_in_ready         ;
      end

      default : begin
        result_o        = 'd0;
        fflags_o        = 'd0;
`ifdef CTRLGEN
        ctrl_regindex_o = 'd0;
        ctrl_warpid_o   = 'd0;
        ctrl_vecmask_o  = 'd0;
        ctrl_wvd_o      = 'd0;
        ctrl_wxd_o      = 'd0;
`endif
        out_valid_o     = 'd0;
        in_ready_o      = 'd0;
      end
    endcase
  end

endmodule

