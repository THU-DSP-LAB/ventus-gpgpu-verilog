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
// Description:sm top
`timescale 1ns/1ns

`include "define.v"
//`include "decode_df_para.v"
//`include "fpu_ops.v"
//`include "IDecode_define.v"
//`include "l1dcache_define.v"
//`define NO_CACHE

module sm_wrapper (
  input                                        clk                                     ,
  input                                        rst_n                                   ,
    
  output                                       cta_req_ready_o                         ,
  input                                        cta_req_valid_i                         ,
  input [`WF_COUNT_WIDTH-1:0]                  cta_req_dispatch2cu_wg_wf_count_i       ,
  input [`WAVE_ITEM_WIDTH-1:0]                 cta_req_dispatch2cu_wf_size_dispatch_i  ,
  input [`SGPR_ID_WIDTH:0]                     cta_req_dispatch2cu_sgpr_base_dispatch_i,
  input [`VGPR_ID_WIDTH:0]                     cta_req_dispatch2cu_vgpr_base_dispatch_i,
  input [`TAG_WIDTH-1:0]                       cta_req_dispatch2cu_wf_tag_dispatch_i   ,
  input [`LDS_ID_WIDTH:0]                      cta_req_dispatch2cu_lds_base_dispatch_i ,
  input [`MEM_ADDR_WIDTH-1:0]                  cta_req_dispatch2cu_start_pc_dispatch_i ,
  input [`MEM_ADDR_WIDTH-1:0]                  cta_req_dispatch2cu_pds_base_dispatch_i ,
  input [`MEM_ADDR_WIDTH-1:0]                  cta_req_dispatch2cu_gds_base_dispatch_i ,
  input [`MEM_ADDR_WIDTH-1:0]                  cta_req_dispatch2cu_csr_knl_dispatch_i  ,
  input [`WG_SIZE_X_WIDTH-1:0]                 cta_req_dispatch2cu_wgid_x_dispatch_i   ,
  input [`WG_SIZE_Y_WIDTH-1:0]                 cta_req_dispatch2cu_wgid_y_dispatch_i   ,
  input [`WG_SIZE_Z_WIDTH-1:0]                 cta_req_dispatch2cu_wgid_z_dispatch_i   ,
  input [31:0]                                 cta_req_dispatch2cu_wg_id_i             ,

  input                                        cta_rsp_ready_i                         ,
  output                                       cta_rsp_valid_o                         ,
  output [`TAG_WIDTH-1:0]                      cta_rsp_cu2dispatch_wf_tag_done_o       ,
  input                                        cache_invalid_i                         ,

`ifdef NO_CACHE
  input                                        icache_mem_rsp_valid_i                  ,
  output                                       icache_mem_rsp_ready_o                  ,
  input  [`XLEN-1:0]                           icache_mem_rsp_addr_i                   ,
  input  [`DCACHE_BLOCKWORDS*`XLEN-1:0]        icache_mem_rsp_data_i                   ,
  input  [`D_SOURCE-1:0]                       icache_mem_rsp_source_i                 ,

  output                                       icache_mem_req_valid_o                  ,
  input                                        icache_mem_req_ready_i                  ,
  output [`XLEN-1:0]                           icache_mem_req_addr_o                   ,
  output [`D_SOURCE-1:0]                       icache_mem_req_source_o                 ,

  input                                        dcache_mem_rsp_valid_i                  ,
  output                                       dcache_mem_rsp_ready_o                  ,
  input  [`WIDBITS-1:0]                        dcache_mem_rsp_instrid_i                ,
  input  [`DCACHE_NLANES*`XLEN-1:0]            dcache_mem_rsp_data_i                   ,
  input  [`DCACHE_NLANES-1:0]                  dcache_mem_rsp_activemask_i             ,

  output                                              dcache_mem_req_valid_o                  ,
  input                                               dcache_mem_req_ready_i                  ,
  output [`WIDBITS-1:0]                               dcache_mem_req_instrid_o                ,
  output [`DCACHE_SETIDXBITS-1:0]                     dcache_mem_req_setidx_o                 ,
  output [`DCACHE_TAGBITS-1:0]                        dcache_mem_req_tag_o                    ,
  output [`DCACHE_NLANES-1:0]                         dcache_mem_req_activemask_o             ,
  output [`DCACHE_NLANES*`DCACHE_BLOCKOFFSETBITS-1:0] dcache_mem_req_blockoffset_o            ,
  output [`DCACHE_NLANES*`BYTESOFWORD-1:0]            dcache_mem_req_wordoffset1h_o           ,
  output [`DCACHE_NLANES*`XLEN-1:0]                   dcache_mem_req_data_o                   ,
  output [2:0]                                        dcache_mem_req_opcode_o                 ,
  output [3:0]                                        dcache_mem_req_param_o                  
`else
  output                                       mem_rsp_ready_o                         ,
  input                                        mem_rsp_valid_i                         ,
  input  [2:0]                                 mem_rsp_d_opcode_i                      ,
  input  [`XLEN-1:0]                           mem_rsp_d_addr_i                        ,
  input  [`DCACHE_BLOCKWORDS*`XLEN-1:0]        mem_rsp_d_data_i                        ,
  input  [`D_SOURCE-1:0]                       mem_rsp_d_source_i                      ,
/*`ifdef NO_CACHE
  input                                        mem_rsp_d_instrid_i                     ,
  input  [`MASK_BITS-1:0]                      mem_rsp_d_mask_i                        ,
`endif*/
  
  input                                        mem_req_ready_i                         ,
  output                                       mem_req_valid_o                         ,
  output [2:0]                                 mem_req_a_opcode_o                      ,
/*`ifdef NO_CACHE
  output                                       mem_req_a_iswrite_o                     ,
  output                                       mem_req_a_instrid_o                     ,
`endif*/
  output [2:0]                                 mem_req_a_param_o                       ,
  output [`XLEN-1:0]                           mem_req_a_addr_o                        ,
  output [`DCACHE_BLOCKWORDS*`XLEN-1:0]        mem_req_a_data_o                        ,
  output [`DCACHE_BLOCKWORDS*`BYTESOFWORD-1:0] mem_req_a_mask_o                        ,
  output [`D_SOURCE-1:0]                       mem_req_a_source_o                      
`endif
  );

  wire cta2warp_warpReq_valid;
  wire [`DEPTH_WARP-1:0] cta2warp_warpReq_wid;
  wire cta2warp_warpRsp_ready;
  wire [`TAG_WIDTH-1:0] cta2warp_wg_id_tag;

  wire pipe_warpRsp_valid;
  wire [`DEPTH_WARP-1:0] pipe_warpRsp_wid;
  wire [`DEPTH_WARP-1:0] pipe_wg_id_lookup;

  wire pipe_icache_req_valid;
  wire [`XLEN-1:0] pipe_icache_req_addr;
  wire [`NUM_FETCH-1:0] pipe_icache_req_mask;
  wire [`DEPTH_WARP-1:0] pipe_icache_req_wid;

  wire pipe_flush_pipe_valid;
  wire [`DEPTH_WARP-1:0] pipe_flush_pipe_wid;

  wire pipe_shared_req_valid;
  wire [`DEPTH_WARP-1:0] pipe_shared_req_instrid;
  wire pipe_shared_req_iswrite;
  wire [`DCACHE_TAGBITS-1:0] pipe_shared_req_tag;
  wire [`DCACHE_SETIDXBITS-1:0] pipe_shared_req_setidx;
  wire [`NUM_THREAD-1:0] pipe_shared_req_activemask;
  wire [`NUM_THREAD*`DCACHE_BLOCKOFFSETBITS-1:0] pipe_shared_req_blockoffset;
  wire [`NUM_THREAD*`BYTESOFWORD-1:0] pipe_shared_req_wordoffset1h;
  wire [`NUM_THREAD*`XLEN-1:0] pipe_shared_req_data;

  wire pipe_shared_rsp_ready;

  wire pipe_dcache_req_valid,pipe_dcache_req_valid_comb;
  wire [`WIDBITS-1:0] pipe_dcache_req_instrid;
  wire [`DCACHE_SETIDXBITS-1:0] pipe_dcache_req_setidx;
  wire [`DCACHE_TAGBITS-1:0] pipe_dcache_req_tag;
  wire [`DCACHE_NLANES-1:0] pipe_dcache_req_activemask;
  wire [`DCACHE_NLANES*`DCACHE_BLOCKOFFSETBITS-1:0] pipe_dcache_req_blockoffset;
  wire [`DCACHE_NLANES*`BYTESOFWORD-1:0] pipe_dcache_req_wordoffset1h;
  wire [`DCACHE_NLANES*`XLEN-1:0] pipe_dcache_req_data;
  wire [2:0] pipe_dcache_req_opcode,pipe_dcache_req_opcode_comb;
  wire [3:0] pipe_dcache_req_param,pipe_dcache_req_param_comb;

  
  //for dcache invalidate
  wire lsu_mshr_is_empty  ;
  wire cache_invalid_valid;
  
  reg  cache_invalid_reg;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      cache_invalid_reg <= 'd0;
    end
    else if(cache_invalid_i)begin
      cache_invalid_reg <= 'd1;
    end
    else if(cache_invalid_valid) begin
      cache_invalid_reg <= 'd0;
    end
    else begin
      cache_invalid_reg <= cache_invalid_reg;
    end
  end

  assign cache_invalid_valid         = cache_invalid_reg && lsu_mshr_is_empty            ;

  assign pipe_dcache_req_valid_comb  = pipe_dcache_req_valid || cache_invalid_valid      ;
  assign pipe_dcache_req_opcode_comb = cache_invalid_valid ? 'd3 : pipe_dcache_req_opcode;
  assign pipe_dcache_req_param_comb  = cache_invalid_valid ? 'd0 : pipe_dcache_req_param ;

  wire pipe_dcache_rsp_ready; 

  wire icache_core_req_ready;
  //wire icache_invalid_i;

  wire icache_mem_rsp_ready,dcache_mem_rsp_ready;
  wire icache_mem_rsp_valid,dcache_mem_rsp_valid;
  wire [2:0] icache_mem_rsp_d_opcode,dcache_mem_rsp_d_opcode;
  wire [`XLEN-1:0] icache_mem_rsp_d_addr,dcache_mem_rsp_d_addr;
  wire [`DCACHE_BLOCKWORDS*`XLEN-1:0] icache_mem_rsp_d_data,dcache_mem_rsp_d_data; 
  wire [`A_SOURCE-1:0] icache_mem_rsp_d_source,dcache_mem_rsp_d_source;

  wire icache_mem_req_ready,dcache_mem_req_ready;
  wire icache_mem_req_valid,dcache_mem_req_valid;
  wire [2:0] icache_mem_req_a_opcode,dcache_mem_req_a_opcode; 
  wire [2:0] icache_mem_req_a_param,dcache_mem_req_a_param; 
  wire [`XLEN-1:0] icache_mem_req_a_addr,dcache_mem_req_a_addr;                         
  wire [(`DCACHE_BLOCKWORDS*`XLEN)-1:0] icache_mem_req_a_data,dcache_mem_req_a_data;
  wire [(`DCACHE_BLOCKWORDS*`BYTESOFWORD)-1:0] icache_mem_req_a_mask,dcache_mem_req_a_mask;
  //wire [`D_SOURCE-1:0] icache_mem_req_a_source,dcache_mem_req_a_source;
  wire [`A_SOURCE-1:0] icache_mem_req_a_source,dcache_mem_req_a_source;

  wire [`WIDBITS-1:0] icache_mem_req_a_source_tmp;

  wire icache_core_rsp_valid;
  wire [`XLEN-1:0] icache_core_rsp_addr;
  wire [`NUM_FETCH*`XLEN-1:0] icache_core_rsp_data;
  wire [`NUM_FETCH-1:0] icache_core_rsp_mask;
  wire [`DEPTH_WARP-1:0] icache_core_rsp_wid;
  wire icache_core_rsp_status;

  wire shared_mem_core_req_ready;

  wire shared_mem_core_rsp_valid;
  
  wire shared_mem_core_rsp_iswrite;
  wire [`WIDBITS-1:0] shared_mem_core_rsp_instrid;
  wire [`SHAREMEM_NLANES*`XLEN-1:0] shared_mem_core_rsp_data;
  wire [`SHAREMEM_NLANES-1:0] shared_mem_core_rsp_activemask;

  wire dcache_core_req_ready;

  wire dcache_core_rsp_valid;
  wire dcache_core_rsp_is_write  ;
  wire [`WIDBITS-1:0]             dcache_core_rsp_instrid   ;
  wire [`DCACHE_NLANES*`XLEN-1:0] dcache_core_rsp_data      ;
  wire [`DCACHE_NLANES-1:0]       dcache_core_rsp_activemask;


/*`ifdef NO_CACHE
  wire [1:0] arb_grant;
  wire       arb_bin;
  reg  [`WIDBITS-1:0] pipe_dcache_req_instrid_reg;
  reg  [`DCACHE_NLANES-1:0] pipe_dcache_req_activemask_reg;
  reg  [`XLEN-1:0] icache_mem_req_a_addr_reg;
`endif*/

  assign icache_mem_req_a_source = icache_mem_req_a_source_tmp;

  assign icache_mem_req_a_opcode = 3'h4;
  assign icache_mem_req_a_data = {`DCACHE_BLOCKWORDS*`XLEN{1'h0}};
  assign icache_mem_req_a_mask = {`DCACHE_BLOCKWORDS*`BYTESOFWORD{1'h1}};
  assign icache_mem_req_a_param = 3'h0; //Dont care

  cta2warp cta2warp(
    .clk                                  (clk                                  ),
    .rst_n                                (rst_n                                ),
       
    .cta_req_ready_o                      (cta_req_ready_o                      ),
    .cta_req_valid_i                      (cta_req_valid_i                      ),
    .cta_req_dispatch2cu_wf_tag_dispatch_i(cta_req_dispatch2cu_wf_tag_dispatch_i),
   
    .cta_rsp_ready_i                      (cta_rsp_ready_i                      ),
    .cta_rsp_valid_o                      (cta_rsp_valid_o                      ),
    .cta_rsp_cu2dispatch_wf_tag_done_o    (cta_rsp_cu2dispatch_wf_tag_done_o    ),
         
    .warpReq_valid_o                      (cta2warp_warpReq_valid               ),
    .warpReq_wid_o                        (cta2warp_warpReq_wid                 ),
             
    .warpRsp_ready_o                      (cta2warp_warpRsp_ready               ),
    .warpRsp_valid_i                      (pipe_warpRsp_valid                   ),
    .warpRsp_wid_i                        (pipe_warpRsp_wid                     ),
                  
    .wg_id_lookup_i                       (pipe_wg_id_lookup                    ),
    .wg_id_tag_o                          (cta2warp_wg_id_tag                   )
    );
  
  pipe pipe(
    .clk                                     (clk                                     ),
    .rst_n                                   (rst_n                                   ),

    //.icache_req_ready_i                      (icache_core_req_ready                   ),
    .icache_req_valid_o                      (pipe_icache_req_valid                   ),
    .icache_req_addr_o                       (pipe_icache_req_addr                    ),
    .icache_req_mask_o                       (pipe_icache_req_mask                    ),
    .icache_req_wid_o                        (pipe_icache_req_wid                     ),

    .icache_rsp_valid_i                      (icache_core_rsp_valid                   ),
    .icache_rsp_addr_i                       (icache_core_rsp_addr                    ),
    .icache_rsp_data_i                       (icache_core_rsp_data                    ),
    .icache_rsp_mask_i                       (icache_core_rsp_mask                    ),
    .icache_rsp_wid_i                        (icache_core_rsp_wid                     ),
    .icache_rsp_status_i                     (icache_core_rsp_status                  ),

    .dcache_req_valid_o                      (pipe_dcache_req_valid                   ),
    .dcache_req_ready_i                      (dcache_core_req_ready                   ),
    .dcache_req_instrid_o                    (pipe_dcache_req_instrid                 ),
    .dcache_req_setidx_o                     (pipe_dcache_req_setidx                  ),
    .dcache_req_tag_o                        (pipe_dcache_req_tag                     ),
    .dcache_req_activemask_o                 (pipe_dcache_req_activemask              ),
    .dcache_req_blockoffset_o                (pipe_dcache_req_blockoffset             ),
    .dcache_req_wordoffset1h_o               (pipe_dcache_req_wordoffset1h            ),
    .dcache_req_data_o                       (pipe_dcache_req_data                    ),
    .dcache_req_opcode_o                     (pipe_dcache_req_opcode                  ),
    .dcache_req_param_o                      (pipe_dcache_req_param                   ),

    .dcache_rsp_valid_i                      (dcache_core_rsp_valid                   ),
    .dcache_rsp_ready_o                      (pipe_dcache_rsp_ready                   ),
    .dcache_rsp_instrid_i                    (dcache_core_rsp_instrid                 ),
    .dcache_rsp_data_i                       (dcache_core_rsp_data                    ),
    .dcache_rsp_activemask_i                 (dcache_core_rsp_activemask              ),

    .shared_req_valid_o                      (pipe_shared_req_valid                   ),
    .shared_req_ready_i                      (shared_mem_core_req_ready               ),
    .shared_req_instrid_o                    (pipe_shared_req_instrid                 ),
    .shared_req_iswrite_o                    (pipe_shared_req_iswrite                 ),
    .shared_req_tag_o                        (pipe_shared_req_tag                     ),
    .shared_req_setidx_o                     (pipe_shared_req_setidx                  ),
    .shared_req_activemask_o                 (pipe_shared_req_activemask              ),
    .shared_req_blockoffset_o                (pipe_shared_req_blockoffset             ),
    .shared_req_wordoffset1h_o               (pipe_shared_req_wordoffset1h            ),
    .shared_req_data_o                       (pipe_shared_req_data                    ),

    .shared_rsp_valid_i                      (shared_mem_core_rsp_valid               ),
    .shared_rsp_ready_o                      (pipe_shared_rsp_ready                   ),
    .shared_rsp_instrid_i                    (shared_mem_core_rsp_instrid             ),
    .shared_rsp_data_i                       (shared_mem_core_rsp_data                ),
    .shared_rsp_activemask_i                 (shared_mem_core_rsp_activemask          ),
                                              
    .flush_pipe_valid_o                      (pipe_flush_pipe_valid                   ),
    .flush_pipe_wid_o                        (pipe_flush_pipe_wid                     ),

    .warpReq_valid_i                         (cta2warp_warpReq_valid                  ),
    .warpReq_dispatch2cu_wg_wf_count_i       (cta_req_dispatch2cu_wg_wf_count_i       ),
    .warpReq_dispatch2cu_wf_size_dispatch_i  (cta_req_dispatch2cu_wf_size_dispatch_i  ),
    .warpReq_dispatch2cu_sgpr_base_dispatch_i(cta_req_dispatch2cu_sgpr_base_dispatch_i),
    .warpReq_dispatch2cu_vgpr_base_dispatch_i(cta_req_dispatch2cu_vgpr_base_dispatch_i),
    .warpReq_dispatch2cu_wf_tag_dispatch_i   (cta_req_dispatch2cu_wf_tag_dispatch_i   ),
    .warpReq_dispatch2cu_lds_base_dispatch_i (cta_req_dispatch2cu_lds_base_dispatch_i ),
    .warpReq_dispatch2cu_start_pc_dispatch_i (cta_req_dispatch2cu_start_pc_dispatch_i ),
    .warpReq_dispatch2cu_pds_base_dispatch_i (cta_req_dispatch2cu_pds_base_dispatch_i ),
    .warpReq_dispatch2cu_csr_knl_dispatch_i  (cta_req_dispatch2cu_csr_knl_dispatch_i  ),
    .warpReq_dispatch2cu_wgid_x_dispatch_i   (cta_req_dispatch2cu_wgid_x_dispatch_i   ),
    .warpReq_dispatch2cu_wgid_y_dispatch_i   (cta_req_dispatch2cu_wgid_y_dispatch_i   ),
    .warpReq_dispatch2cu_wgid_z_dispatch_i   (cta_req_dispatch2cu_wgid_z_dispatch_i   ),
    .warpReq_dispatch2cu_wg_id_i             (cta_req_dispatch2cu_wg_id_i             ),
    .warpReq_wid_i                           (cta2warp_warpReq_wid                    ),

    .warpRsp_ready_i                         (cta2warp_warpRsp_ready                  ),
    .warpRsp_valid_o                         (pipe_warpRsp_valid                      ),
    .warpRsp_wid_o                           (pipe_warpRsp_wid                        ),

    .wg_id_lookup_o                          (pipe_wg_id_lookup                       ),
    .wg_id_tag_i                             (cta2warp_wg_id_tag                      ),

    .lsu_mshr_is_empty_o                     (lsu_mshr_is_empty                       )
    );

`ifdef NO_CACHE 
  assign icache_mem_req_valid_o  = icache_mem_req_valid       ;
  assign icache_mem_req_addr_o   = icache_mem_req_a_addr      ;
  assign icache_mem_req_source_o = icache_mem_req_a_source_tmp;
  assign icache_mem_req_ready    = icache_mem_req_ready_i     ;

  assign icache_mem_rsp_valid    = icache_mem_rsp_valid_i     ;
  assign icache_mem_rsp_d_source = icache_mem_rsp_source_i    ;
  assign icache_mem_rsp_d_addr   = icache_mem_rsp_addr_i      ;
  assign icache_mem_rsp_d_data   = icache_mem_rsp_data_i      ;
  assign icache_mem_rsp_ready_o  = icache_mem_rsp_ready       ;

  assign dcache_mem_req_valid_o        = pipe_dcache_req_valid       ;
  assign dcache_mem_req_instrid_o      = pipe_dcache_req_instrid     ; 
  assign dcache_mem_req_setidx_o       = pipe_dcache_req_setidx      ;
  assign dcache_mem_req_tag_o          = pipe_dcache_req_tag         ;
  assign dcache_mem_req_activemask_o   = pipe_dcache_req_activemask  ;
  assign dcache_mem_req_blockoffset_o  = pipe_dcache_req_blockoffset ;
  assign dcache_mem_req_wordoffset1h_o = pipe_dcache_req_wordoffset1h;
  assign dcache_mem_req_data_o         = pipe_dcache_req_data        ;
  assign dcache_mem_req_opcode_o       = pipe_dcache_req_opcode      ;
  assign dcache_mem_req_param_o        = pipe_dcache_req_param       ;
  assign dcache_core_req_ready         = dcache_mem_req_ready_i      ;

  assign dcache_core_rsp_valid         = dcache_mem_rsp_valid_i      ;      
  assign dcache_core_rsp_instrid       = dcache_mem_rsp_instrid_i    ;
  assign dcache_core_rsp_data          = dcache_mem_rsp_data_i       ;
  assign dcache_core_rsp_activemask    = dcache_mem_rsp_activemask_i ;
  assign dcache_mem_rsp_ready_o        = pipe_dcache_rsp_ready       ;

`endif
    

`ifndef NO_CACHE
  l1cache_arb l1cache_arb(
    .mem_req_in_ready_o    ({dcache_mem_req_ready,icache_mem_req_ready}      ),
    .mem_req_in_valid_i    ({dcache_mem_req_valid,icache_mem_req_valid}      ),
    .mem_req_in_a_opcode_i ({dcache_mem_req_a_opcode,icache_mem_req_a_opcode}),
    .mem_req_in_a_param_i  ({dcache_mem_req_a_param,icache_mem_req_a_param}  ),
    .mem_req_in_a_addr_i   ({dcache_mem_req_a_addr,icache_mem_req_a_addr}    ),
    .mem_req_in_a_data_i   ({dcache_mem_req_a_data,icache_mem_req_a_data}    ),
    .mem_req_in_a_mask_i   ({dcache_mem_req_a_mask,icache_mem_req_a_mask}    ),
    .mem_req_in_a_source_i ({dcache_mem_req_a_source,icache_mem_req_a_source}),

    .mem_req_out_ready_i   (mem_req_ready_i                                  ),
    .mem_req_out_valid_o   (mem_req_valid_o                                  ),
    .mem_req_out_a_opcode_o(mem_req_a_opcode_o                               ),
    .mem_req_out_a_param_o (mem_req_a_param_o                                ),
    .mem_req_out_a_addr_o  (mem_req_a_addr_o                                 ),
    .mem_req_out_a_data_o  (mem_req_a_data_o                                 ),
    .mem_req_out_a_mask_o  (mem_req_a_mask_o                                 ),
    .mem_req_out_a_source_o(mem_req_a_source_o                               ),

    .mem_rsp_in_ready_o    (mem_rsp_ready_o                                  ),
    .mem_rsp_in_valid_i    (mem_rsp_valid_i                                  ),
    .mem_rsp_in_d_opcode_i (mem_rsp_d_opcode_i                               ),
    .mem_rsp_in_d_addr_i   (mem_rsp_d_addr_i                                 ),
    .mem_rsp_in_d_data_i   (mem_rsp_d_data_i                                 ),
    .mem_rsp_in_d_source_i (mem_rsp_d_source_i                               ),

    .mem_rsp_out_ready_i   ({dcache_mem_rsp_ready,icache_mem_rsp_ready}      ),
    .mem_rsp_out_valid_o   ({dcache_mem_rsp_valid,icache_mem_rsp_valid}      ),
    .mem_rsp_out_d_opcode_o({dcache_mem_rsp_d_opcode,icache_mem_rsp_d_opcode}),
    .mem_rsp_out_d_addr_o  ({dcache_mem_rsp_d_addr,icache_mem_rsp_d_addr}    ),
    .mem_rsp_out_d_data_o  ({dcache_mem_rsp_d_data,icache_mem_rsp_d_data}    ),  
    .mem_rsp_out_d_source_o({dcache_mem_rsp_d_source,icache_mem_rsp_d_source})
    );
`endif

  instruction_cache icache(
    .clk               (clk                                     ),
    .rst_n             (rst_n                                   ),
    .invalid_i         (cache_invalid_i                         ),

    //.core_req_ready_o  (icache_core_req_ready                   ),
    .core_req_valid_i  (pipe_icache_req_valid                   ),
    .core_req_addr_i   (pipe_icache_req_addr                    ),
    .core_req_mask_i   (pipe_icache_req_mask                    ),
    .core_req_wid_i    (pipe_icache_req_wid                     ),

    .flush_pipe_valid_i(pipe_flush_pipe_valid                   ),
    .flush_pipe_wid_i  (pipe_flush_pipe_wid                     ),

    .core_rsp_valid_o  (icache_core_rsp_valid                   ),
    .core_rsp_addr_o   (icache_core_rsp_addr                    ),
    .core_rsp_data_o   (icache_core_rsp_data                    ),
    .core_rsp_mask_o   (icache_core_rsp_mask                    ),
    .core_rsp_wid_o    (icache_core_rsp_wid                     ),
    .core_rsp_status_o (icache_core_rsp_status                  ),

    .mem_rsp_ready_o   (icache_mem_rsp_ready                    ),
    .mem_rsp_valid_i   (icache_mem_rsp_valid                    ),
    .mem_rsp_d_source_i(icache_mem_rsp_d_source[`WIDBITS-1:0]   ),
    .mem_rsp_d_addr_i  (icache_mem_rsp_d_addr                   ),
    .mem_rsp_d_data_i  (icache_mem_rsp_d_data                   ),

    .mem_req_ready_i   (icache_mem_req_ready                    ),
    .mem_req_valid_o   (icache_mem_req_valid                    ),
    .mem_req_a_source_o(icache_mem_req_a_source_tmp             ),
    .mem_req_a_addr_o  (icache_mem_req_a_addr                   )
    );

    shared_mem shared_mem(
      .clk                    (clk                           ),
      .rst_n                  (rst_n                         ),
      .core_req_valid_i       (pipe_shared_req_valid         ),
      .core_req_ready_o       (shared_mem_core_req_ready     ),
      .core_req_instrid_i     (pipe_shared_req_instrid       ),
      .core_req_iswrite_i     (pipe_shared_req_iswrite       ),
      .core_req_tag_i         (pipe_shared_req_tag           ),
      .core_req_setidx_i      (pipe_shared_req_setidx        ),
      .core_req_activemask_i  (pipe_shared_req_activemask    ),
      .core_req_blockoffset_i (pipe_shared_req_blockoffset   ),
      .core_req_wordoffset1h_i(pipe_shared_req_wordoffset1h  ),
      .core_req_data_i        (pipe_shared_req_data          ),
      .core_rsp_valid_o       (shared_mem_core_rsp_valid     ),
      .core_rsp_ready_i       (pipe_shared_rsp_ready         ),
      .core_rsp_iswrite_o     (shared_mem_core_rsp_iswrite   ),
      .core_rsp_instrid_o     (shared_mem_core_rsp_instrid   ),
      .core_rsp_data_o        (shared_mem_core_rsp_data      ),
      .core_rsp_activemask_o  (shared_mem_core_rsp_activemask)
      );

`ifndef NO_CACHE
  l1_dcache dcache(
    .clk                    (clk                         ),
    .rst_n                  (rst_n                       ),

    .core_req_valid_i       (pipe_dcache_req_valid_comb  ),
    .core_req_ready_o       (dcache_core_req_ready       ),
    .core_req_instrid_i     (pipe_dcache_req_instrid     ),
    .core_req_setidx_i      (pipe_dcache_req_setidx      ),
    .core_req_tag_i         (pipe_dcache_req_tag         ),
    .core_req_activemask_i  (pipe_dcache_req_activemask  ),
    .core_req_blockoffset_i (pipe_dcache_req_blockoffset ),
    .core_req_wordoffset1h_i(pipe_dcache_req_wordoffset1h),
    .core_req_data_i        (pipe_dcache_req_data        ),
    .core_req_opcode_i      (pipe_dcache_req_opcode_comb ),
    .core_req_param_i       (pipe_dcache_req_param_comb  ),

    .core_rsp_valid_o       (dcache_core_rsp_valid       ),
    .core_rsp_ready_i       (pipe_dcache_rsp_ready       ),
    .core_rsp_is_write_o    (dcache_core_rsp_is_write    ),
    .core_rsp_instrid_o     (dcache_core_rsp_instrid     ),
    .core_rsp_data_o        (dcache_core_rsp_data        ),
    .core_rsp_activemask_o  (dcache_core_rsp_activemask  ),

    .mem_rsp_valid_i        (dcache_mem_rsp_valid        ),
    .mem_rsp_ready_o        (dcache_mem_rsp_ready        ),
    .mem_rsp_d_opcode_i     (dcache_mem_rsp_d_opcode     ),
    .mem_rsp_d_source_i     (dcache_mem_rsp_d_source     ),
    .mem_rsp_d_addr_i       (dcache_mem_rsp_d_addr       ),
    .mem_rsp_d_data_i       (dcache_mem_rsp_d_data       ),

    .mem_req_valid_o        (dcache_mem_req_valid        ),
    .mem_req_ready_i        (dcache_mem_req_ready        ),
    .mem_req_a_opcode_o     (dcache_mem_req_a_opcode     ),
    .mem_req_a_param_o      (dcache_mem_req_a_param      ),
    .mem_req_a_source_o     (dcache_mem_req_a_source     ),
    .mem_req_a_addr_o       (dcache_mem_req_a_addr       ),
    .mem_req_a_data_o       (dcache_mem_req_a_data       ),
    .mem_req_a_mask_o       (dcache_mem_req_a_mask       )
    );
`endif

endmodule
