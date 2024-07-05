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
// Description:
`timescale 1ns/1ns
//`include "IDecode_define.v"
`include "define.v"

module  csrexe(
  input                                       clk                             ,
  input                                       rst_n                           ,

  //control signal
  input   [31:0]                              ctrl_inst_i                     ,
  input   [1:0]                               ctrl_csr_i                      ,
  input                                       ctrl_custom_signal_0_i          ,
  input                                       ctrl_isvec_i                    ,
  input   [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]   ctrl_reg_idxw_i                 ,
  input                                       ctrl_wxd_i                      ,
  input   [`DEPTH_WARP-1:0]                   ctrl_wid_i                      ,
  //input   [`XLEN-1:0]                         ctrl_spike_info_pc_i            ,
  //input   [31:0]                              ctrl_spike_info_inst_i          ,

  input                                       in_valid_i                      ,
  input                                       out_ready_i                     ,

  input   [`XLEN-1:0]                         in1_i                           ,
  input   [`DEPTH_WARP*3-1:0]                 rm_wid_i                        ,
  input   [`DEPTH_WARP-1:0]                   lsu_wid_i                       ,
  input   [`DEPTH_WARP-1:0]                   simt_wid_i                      ,

  //CTA2csr
  input                                       CTA2csr_valid_i                 ,
  input   [`WF_COUNT_WIDTH-1:0]               dispatch2cu_wg_wf_count_i       ,
  input   [`WAVE_ITEM_WIDTH-1:0]              dispatch2cu_wf_size_dispatch_i  ,
  input   [`SGPR_ID_WIDTH:0]                  dispatch2cu_sgpr_base_dispatch_i,
  input   [`VGPR_ID_WIDTH:0]                  dispatch2cu_vgpr_base_dispatch_i,
  input   [`TAG_WIDTH-1:0]                    dispatch2cu_wf_tag_dispatch_i   ,
  input   [`LDS_ID_WIDTH:0]                   dispatch2cu_lds_base_dispatch_i ,
  //input   [`MEM_ADDR_WIDTH-1:0]               dispatch2cu_start_pc_dispatch_i ,
  input   [`MEM_ADDR_WIDTH-1:0]               dispatch2cu_pds_base_dispatch_i ,
  //input   [`MEM_ADDR_WIDTH-1:0]               dispatch2cu_gds_base_dispatch_i ,
  input   [`MEM_ADDR_WIDTH-1:0]               dispatch2cu_csr_knl_dispatch_i  ,
  input   [`WG_SIZE_X_WIDTH-1:0]              dispatch2cu_wgid_x_dispatch_i   ,
  input   [`WG_SIZE_Y_WIDTH-1:0]              dispatch2cu_wgid_y_dispatch_i   ,
  input   [`WG_SIZE_Z_WIDTH-1:0]              dispatch2cu_wgid_z_dispatch_i   ,
  input   [31:0]                              dispatch2cu_wg_id_i             ,
  input   [`DEPTH_WARP-1:0]                   wid_i                           ,

  output                                      in_ready_o                      ,
  output                                      out_valid_o                     ,

  output  [`XLEN-1:0]                         wb_wxd_rd_o                     ,
  output                                      wxd_o                           ,
  output  [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]   reg_idxw_o                      ,
  output  [`DEPTH_WARP-1:0]                   warp_id_o                       ,
  //output  [`XLEN-1:0]                         spike_info_pc_o                 ,
  //output  [31:0]                              spike_info_inst_o               ,
  output  [8:0]                               rm_o                            ,
  output  [`NUM_WARP*(`SGPR_ID_WIDTH+1)-1:0]  sgpr_base_o                     ,
  output  [`NUM_WARP*(`VGPR_ID_WIDTH+1)-1:0]  vgpr_base_o                     ,
  output  [`XLEN-1:0]                         lsu_tid_o                       ,
  output  [`XLEN-1:0]                         lsu_pds_o                       ,
  output  [`XLEN-1:0]                         lsu_numw_o                      ,
  output  [`XLEN-1:0]                         simt_rpc_o                      
  );
  
  wire   [31:0]                  ctrl_inst                                               ; 
  wire   [1:0]                   ctrl_csr                                                ; 
  wire                           ctrl_custom_signal_0                                    ; 
  wire                           ctrl_isvec                                              ; 
  wire   [`XLEN-1:0]             in1                                                     ; 
  wire                           write                            [0:`NUM_WARP-1]        ;

  wire                           CTA2csr_valid                    [0:`NUM_WARP-1]        ;
  wire   [`WF_COUNT_WIDTH-1:0]   dispatch2cu_wg_wf_count                                 ;
  wire   [`WAVE_ITEM_WIDTH-1:0]  dispatch2cu_wf_size_dispatch                            ;
  wire   [`SGPR_ID_WIDTH:0]      dispatch2cu_sgpr_base_dispatch                          ;
  wire   [`VGPR_ID_WIDTH:0]      dispatch2cu_vgpr_base_dispatch                          ;
  wire   [`TAG_WIDTH-1:0]        dispatch2cu_wf_tag_dispatch                             ;
  wire   [`LDS_ID_WIDTH:0]       dispatch2cu_lds_base_dispatch                           ;
  //wire   [`MEM_ADDR_WIDTH-1:0]   dispatch2cu_start_pc_dispatch                           ;
  wire   [`MEM_ADDR_WIDTH-1:0]   dispatch2cu_pds_base_dispatch                           ;
  //wire   [`MEM_ADDR_WIDTH-1:0]   dispatch2cu_gds_base_dispatch                           ;
  wire   [`MEM_ADDR_WIDTH-1:0]   dispatch2cu_csr_knl_dispatch                            ;
  wire   [`WG_SIZE_X_WIDTH-1:0]  dispatch2cu_wgid_x_dispatch                             ;
  wire   [`WG_SIZE_Y_WIDTH-1:0]  dispatch2cu_wgid_y_dispatch                             ;
  wire   [`WG_SIZE_Z_WIDTH-1:0]  dispatch2cu_wgid_z_dispatch                             ;
  wire   [31:0]                  dispatch2cu_wg_id                                       ;
  wire   [`DEPTH_WARP-1:0]       wid                                                     ;
  
  wire   [`XLEN-1:0]             wb_wxd_rd                        [0:`NUM_WARP-1]        ;
  wire   [2:0]                   frm                              [0:`NUM_WARP-1]        ;
  wire   [`SGPR_ID_WIDTH:0]      sgpr_base                        [0:`NUM_WARP-1]        ;
  wire   [`VGPR_ID_WIDTH:0]      vgpr_base                        [0:`NUM_WARP-1]        ;
  wire   [`XLEN-1:0]             simt_rpc                         [0:`NUM_WARP-1]        ;
  wire   [`XLEN-1:0]             lsu_tid                          [0:`NUM_WARP-1]        ;
  wire   [`XLEN-1:0]             lsu_pds                          [0:`NUM_WARP-1]        ;
  wire   [`XLEN-1:0]             lsu_numw                         [0:`NUM_WARP-1]        ;
  
  //fifo输入数据
  wire   [`XLEN+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP-1:0] fifo_data_in                  ;
  wire   [`XLEN+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP-1:0] fifo_data_out                 ;
  wire                                                         fifo_in_valid                 ;
  wire                                                         fifo_in_ready                 ;
  wire                                                         fifo_out_valid                ;
  wire                                                         fifo_out_ready                ;
  
  genvar  i;
  generate  
    for(i=0;i<`NUM_WARP;i=i+1) begin : B1//将csrfile例化num_warp次
      csrfile U_vcsr_i (
                           .clk                             (clk                           ), 
                           .rst_n                           (rst_n                         ), 
                                                                                           
                                                                                           
                           .ctrl_inst_i                     (ctrl_inst                     ), 
                           .ctrl_csr_i                      (ctrl_csr                      ),
                           .ctrl_custom_signal_0_i          (ctrl_custom_signal_0          ),
                           .ctrl_isvec_i                    (ctrl_isvec                    ),
                                                                                           
                           .in1_i                           (in1                           ),
                           .write_i                         (write[i]                      ),
                                                                                           
                                                                                           
                           .CTA2csr_valid_i                 (CTA2csr_valid[i]              ),
                           .dispatch2cu_wg_wf_count_i       (dispatch2cu_wg_wf_count       ),
                           .dispatch2cu_wf_size_dispatch_i  (dispatch2cu_wf_size_dispatch  ),
                           .dispatch2cu_sgpr_base_dispatch_i(dispatch2cu_sgpr_base_dispatch),
                           .dispatch2cu_vgpr_base_dispatch_i(dispatch2cu_vgpr_base_dispatch),
                           .dispatch2cu_wf_tag_dispatch_i   (dispatch2cu_wf_tag_dispatch   ),
                           .dispatch2cu_lds_base_dispatch_i (dispatch2cu_lds_base_dispatch ),
                           //.dispatch2cu_start_pc_dispatch_i (dispatch2cu_start_pc_dispatch ),
                           .dispatch2cu_pds_base_dispatch_i (dispatch2cu_pds_base_dispatch ),
                           //.dispatch2cu_gds_base_dispatch_i (dispatch2cu_gds_base_dispatch ),
                           .dispatch2cu_csr_knl_dispatch_i  (dispatch2cu_csr_knl_dispatch  ),
                           .dispatch2cu_wgid_x_dispatch_i   (dispatch2cu_wgid_x_dispatch   ),
                           .dispatch2cu_wgid_y_dispatch_i   (dispatch2cu_wgid_y_dispatch   ),
                           .dispatch2cu_wgid_z_dispatch_i   (dispatch2cu_wgid_z_dispatch   ),
                           .dispatch2cu_wg_id_i             (dispatch2cu_wg_id             ),
                           //.wid_i                           (wid                           ),
                                                                                           
                           .wb_wxd_rd_o                     (wb_wxd_rd[i]                  ),
                           .frm_o                           (frm[i]                        ),
                           .sgpr_base_o                     (sgpr_base[i]                  ),
                           .vgpr_base_o                     (vgpr_base[i]                  ),
                           .simt_rpc_o                      (simt_rpc[i]                   ),
                           .lsu_tid_o                       (lsu_tid[i]                    ),
                           .lsu_pds_o                       (lsu_pds[i]                    ),
                           .lsu_numw_o                      (lsu_numw[i]                   )
                       );

        //将选中的csr寄存器的输入使能拉高
        assign  write[i] = (i == ctrl_wid_i) ? (in_valid_i & in_ready_o) : 1'b0;
        assign  CTA2csr_valid[i] = (i == wid) ? CTA2csr_valid_i : 1'b0         ;
       
        //输出赋值
        assign  vgpr_base_o[((i+1)*(`VGPR_ID_WIDTH+1)-1)-:`VGPR_ID_WIDTH+1]  = vgpr_base[i];
        assign  sgpr_base_o[((i+1)*(`SGPR_ID_WIDTH+1)-1)-:`SGPR_ID_WIDTH+1]  = sgpr_base[i]; 
        //assign  rm_o[((i+1)*3-1)-:3] = frm[i];
    end
    endgenerate

    //ctrl赋值
    assign  ctrl_inst            = ctrl_inst_i;
    assign  ctrl_csr             = ctrl_csr_i;
    assign  ctrl_custom_signal_0 = ctrl_custom_signal_0_i;
    assign  ctrl_isvec           = ctrl_isvec_i;
    assign  in1                  = in1_i;
    //CTA2csr赋值
    assign  dispatch2cu_wg_wf_count         = dispatch2cu_wg_wf_count_i       ;
    assign  dispatch2cu_wf_size_dispatch    = dispatch2cu_wf_size_dispatch_i  ;
    assign  dispatch2cu_sgpr_base_dispatch  = dispatch2cu_sgpr_base_dispatch_i;
    assign  dispatch2cu_vgpr_base_dispatch  = dispatch2cu_vgpr_base_dispatch_i;
    assign  dispatch2cu_wf_tag_dispatch     = dispatch2cu_wf_tag_dispatch_i   ;
    assign  dispatch2cu_lds_base_dispatch   = dispatch2cu_lds_base_dispatch_i ;
    //assign  dispatch2cu_start_pc_dispatch   = dispatch2cu_start_pc_dispatch_i ;
    assign  dispatch2cu_pds_base_dispatch   = dispatch2cu_pds_base_dispatch_i ;
    //assign  dispatch2cu_gds_base_dispatch   = dispatch2cu_gds_base_dispatch_i ;
    assign  dispatch2cu_csr_knl_dispatch    = dispatch2cu_csr_knl_dispatch_i  ; 
    assign  dispatch2cu_wgid_x_dispatch     = dispatch2cu_wgid_x_dispatch_i   ;  
    assign  dispatch2cu_wgid_y_dispatch     = dispatch2cu_wgid_y_dispatch_i   ;  
    assign  dispatch2cu_wgid_z_dispatch     = dispatch2cu_wgid_z_dispatch_i   ;  
    assign  dispatch2cu_wg_id               = dispatch2cu_wg_id_i             ;            
    assign  wid                             = wid_i                           ;

    genvar  j;
    generate
      for(j=0;j<3;j=j+1) begin : B2
        assign rm_o[((j+1)*3-1)-:3] = frm[rm_wid_i[((j+1)*`DEPTH_WARP-1)-:`DEPTH_WARP]];  
      end
    endgenerate

    assign  lsu_tid_o  = lsu_tid[lsu_wid_i]  ;
    assign  lsu_pds_o  = lsu_pds[lsu_wid_i]  ;
    assign  lsu_numw_o = lsu_numw[lsu_wid_i] ;
    assign  simt_rpc_o = simt_rpc[simt_wid_i];
    //fifo输入数据
    assign  fifo_data_in   = {ctrl_reg_idxw_i,ctrl_wxd_i,wb_wxd_rd[ctrl_wid_i],ctrl_wid_i} ;
    assign  fifo_in_valid  = in_valid_i & in_ready_o                                       ;
    assign  fifo_out_ready = out_ready_i                                                   ;
    //fifo输出数据
    assign  out_valid_o    = fifo_out_valid                                                ;
    assign  in_ready_o     = fifo_in_ready & (~CTA2csr_valid_i)                            ;
    assign  reg_idxw_o     = fifo_data_out[`XLEN+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP-1:`XLEN+1+`DEPTH_WARP];
    assign  wxd_o          = fifo_data_out[`XLEN+`DEPTH_WARP]                                                    ;
    assign  wb_wxd_rd_o    = fifo_data_out[`XLEN+`DEPTH_WARP-1:`DEPTH_WARP]                                      ;
    assign  warp_id_o      = fifo_data_out[`DEPTH_WARP-1:0]                                                      ;
    //例化fifo
    stream_fifo_pipe_true #(.DATA_WIDTH(`XLEN+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP),
                            .FIFO_DEPTH(1)
    ) U_fifo(
              .clk        (clk           ),
              .rst_n      (rst_n         ),
              .w_valid_i  (fifo_in_valid ),
              .w_data_i   (fifo_data_in  ),
              .r_ready_i  (fifo_out_ready),

              .w_ready_o  (fifo_in_ready ),
              .r_data_o   (fifo_data_out ),
              .r_valid_o  (fifo_out_valid)
            );
endmodule    
