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

module gpgpu_axi_top(
  input                            clk                ,
  input                            rst_n              ,

  output                           s_axilite_awready_o,
  input                            s_axilite_awvalid_i,
  input  [`AXILITE_ADDR_WIDTH-1:0] s_axilite_awaddr_i ,
  input  [`AXILITE_PROT_WIDTH-1:0] s_axilite_awprot_i ,

  output                           s_axilite_wready_o ,
  input                            s_axilite_wvalid_i ,
  input  [`AXILITE_DATA_WIDTH-1:0] s_axilite_wdata_i  ,
  input  [`AXILITE_STRB_WIDTH-1:0] s_axilite_wstrb_i  ,

  input                            s_axilite_bready_i ,
  output                           s_axilite_bvalid_o ,
  output [`AXILITE_RESP_WIDTH-1:0] s_axilite_bresp_o  ,

  output                           s_axilite_arready_o,
  input                            s_axilite_arvalid_i,
  input  [`AXILITE_ADDR_WIDTH-1:0] s_axilite_araddr_i ,
  input  [`AXILITE_PROT_WIDTH-1:0] s_axilite_arprot_i ,

  input                            s_axilite_rready_i ,
  output [`AXILITE_DATA_WIDTH-1:0] s_axilite_rdata_o  ,
  output [`AXILITE_RESP_WIDTH-1:0] s_axilite_rresp_o  ,
  output                           s_axilite_rvalid_o , 

  input                            m_axi_awready_i    ,
  output                           m_axi_awvalid_o    ,
  output [`AXI_ID_WIDTH-1:0]       m_axi_awid_o       ,
  output [`AXI_ADDR_WIDTH-1:0]     m_axi_awaddr_o     ,
  output [`AXI_LEN_WIDTH-1:0]      m_axi_awlen_o      ,
  output [`AXI_SIZE_WIDTH-1:0]     m_axi_awsize_o     ,
  output [`AXI_BURST_WIDTH-1:0]    m_axi_awburst_o    ,
  output                           m_axi_awlock_o     ,
  output [`AXI_CACHE_WIDTH-1:0]    m_axi_awcache_o    ,
  output [`AXI_PROT_WIDTH-1:0]     m_axi_awprot_o     ,
  output [`AXI_QOS_WIDTH-1:0]      m_axi_awqos_o      ,
  output [`AXI_REGION_WIDTH-1:0]   m_axi_awregion_o   ,
  output [`AXI_ATOP_WIDTH-1:0]     m_axi_awatop_o     ,
  output [`AXI_USER_WIDTH-1:0]     m_axi_awuser_o     ,

  input                            m_axi_wready_i     ,
  output                           m_axi_wvalid_o     ,
  output [`AXI_DATA_WIDTH-1:0]     m_axi_wdata_o      ,
  output [(`AXI_DATA_WIDTH/8)-1:0] m_axi_wstrb_o      ,
  output                           m_axi_wlast_o      ,
  output [`AXI_USER_WIDTH-1:0]     m_axi_wuser_o      ,

  output                           m_axi_bready_o     ,
  input                            m_axi_bvalid_i     ,
  input  [`AXI_ID_WIDTH-1:0]       m_axi_bid_i        ,
  input  [`AXI_RESP_WIDTH-1:0]     m_axi_bresp_i      ,
  input  [`AXI_USER_WIDTH-1:0]     m_axi_buser_i      ,
  
  input                            m_axi_arready_i    ,
  output                           m_axi_arvalid_o    ,
  output [`AXI_ID_WIDTH-1:0]       m_axi_arid_o       ,
  output [`AXI_ADDR_WIDTH-1:0]     m_axi_araddr_o     ,
  output [`AXI_LEN_WIDTH-1:0]      m_axi_arlen_o      ,
  output [`AXI_SIZE_WIDTH-1:0]     m_axi_arsize_o     ,
  output [`AXI_BURST_WIDTH-1:0]    m_axi_arburst_o    ,
  output                           m_axi_arlock_o     ,
  output [`AXI_CACHE_WIDTH-1:0]    m_axi_arcache_o    ,
  output [`AXI_PROT_WIDTH-1:0]     m_axi_arprot_o     ,
  output [`AXI_QOS_WIDTH-1:0]      m_axi_arqos_o      ,
  output [`AXI_REGION_WIDTH-1:0]   m_axi_arregion_o   ,
  output [`AXI_USER_WIDTH-1:0]     m_axi_aruser_o     ,

  output                           m_axi_rready_o     ,
  input                            m_axi_rvalid_i     ,
  input  [`AXI_ID_WIDTH-1:0]       m_axi_rid_i        ,
  input  [`AXI_DATA_WIDTH-1:0]     m_axi_rdata_i      ,
  input  [`AXI_RESP_WIDTH-1:0]     m_axi_rresp_i      ,
  input                            m_axi_rlast_i      ,
  input  [`AXI_USER_WIDTH-1:0]     m_axi_ruser_i       
  );  

  wire host_req_valid;
  wire host_req_ready;
  wire [`WG_ID_WIDTH-1:0] host_req_wg_id;
  wire [`WF_COUNT_WIDTH-1:0] host_req_num_wf;
  wire [`WAVE_ITEM_WIDTH-1:0] host_req_wf_size;
  wire [`MEM_ADDR_WIDTH-1:0] host_req_start_pc;
  wire [`WG_SIZE_X_WIDTH*3-1:0] host_req_kernel_size_3d;
  wire [`MEM_ADDR_WIDTH-1:0] host_req_pds_baseaddr;
  wire [`MEM_ADDR_WIDTH-1:0] host_req_csr_knl;
  wire [`VGPR_ID_WIDTH:0] host_req_vgpr_size_total;
  wire [`SGPR_ID_WIDTH:0] host_req_sgpr_size_total;
  wire [`LDS_ID_WIDTH:0] host_req_lds_size_total;
  wire [`GDS_ID_WIDTH:0] host_req_gds_size_total;
  wire [`VGPR_ID_WIDTH:0] host_req_vgpr_size_per_wf;
  wire [`SGPR_ID_WIDTH:0] host_req_sgpr_size_per_wf;
  wire [`MEM_ADDR_WIDTH-1:0] host_req_gds_baseaddr;

  wire host_rsp_valid;
  wire host_rsp_ready;
  wire [`WG_ID_WIDTH-1:0] host_rsp_inflight_wg_buffer_host_wf_done_wg_id;
  
  wire busy_o;               
  wire req_i;                
  wire type_i;               
  wire [3:0] amo_i;                
  wire gnt_o;                
  wire [`AXI_ADDR_WIDTH-1:0] addr_i;               
  wire we_i;                 
  wire [(64/`AXI_DATA_WIDTH)-1:0][`AXI_DATA_WIDTH-1:0] wdata_i;              
  wire [(64/`AXI_DATA_WIDTH)-1:0][(`AXI_DATA_WIDTH/8)-1:0] be_i;                 
  wire [2:0] size_i;               
  wire [`AXI_ID_WIDTH-1:0] id_i;                 
  wire valid_o;             
  wire [(64/`AXI_DATA_WIDTH)-1:0][`AXI_DATA_WIDTH-1:0] rdata_o;              
  wire [`AXI_ID_WIDTH-1:0] id_o;                 
  wire [`AXI_DATA_WIDTH-1:0] critical_word_o;      
  wire critical_word_valid_o;

  wire [`NUM_L2CACHE-1:0] top_out_a_valid;
  wire [`NUM_L2CACHE-1:0] top_out_a_ready;
  wire [`NUM_L2CACHE*`OP_BITS-1:0] top_out_a_opcode;
  wire [`NUM_L2CACHE*`SIZE_BITS-1:0] top_out_a_size;
  wire [`NUM_L2CACHE*`SOURCE_BITS-1:0] top_out_a_source;
  wire [`NUM_L2CACHE*`ADDRESS_BITS-1:0] top_out_a_address;
  wire [`NUM_L2CACHE*`MASK_BITS-1:0] top_out_a_mask;
  wire [`NUM_L2CACHE*`DATA_BITS-1:0] top_out_a_data;
  wire [`NUM_L2CACHE*3-1:0] top_out_a_param;
                                       
  wire [`NUM_L2CACHE-1:0] top_out_d_valid;
  wire [`NUM_L2CACHE-1:0] top_out_d_ready;
  wire [`NUM_L2CACHE*`OP_BITS-1:0] top_out_d_opcode;
  wire [`NUM_L2CACHE*`SIZE_BITS-1:0] top_out_d_size;
  wire [`NUM_L2CACHE*`SOURCE_BITS-1:0] top_out_d_source;
  wire [`NUM_L2CACHE*`DATA_BITS-1:0] top_out_d_data;
  wire [`NUM_L2CACHE*3-1:0] top_out_d_param;

  reg [`OP_BITS-1:0] mem_rsp_opcode;
  reg [`SIZE_BITS-1:0] mem_rsp_source;
  reg [`DATA_BITS-1:0] l2cache_req_data;
  reg [`MASK_BITS-1:0] l2cache_req_mask;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      mem_rsp_opcode <= {`OP_BITS{1'd0}};
      mem_rsp_source <= {`SIZE_BITS{1'd0}};
    end 
    else begin
      mem_rsp_opcode <= (m_axi_rvalid_i) ? 'h1 : ((m_axi_bvalid_i) ? 'h0 : mem_rsp_opcode); //opcode==1 read,opcode==0 write
      mem_rsp_source <= (m_axi_rvalid_i) ? m_axi_rid_i : ((m_axi_bvalid_i) ? m_axi_bid_i : mem_rsp_source);
    end 
  end 

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      l2cache_req_data <= {`DATA_BITS{1'd0}}; 
      l2cache_req_mask <= {`MASK_BITS{1'd0}}; 
    end
    else begin
      l2cache_req_data <= (top_out_a_valid) ? top_out_a_data : l2cache_req_data; 
      l2cache_req_mask <= (top_out_a_valid) ? top_out_a_mask : l2cache_req_mask;
    end 
  end 

  assign req_i = top_out_a_valid;  
  assign top_out_a_ready = !busy_o; //there are no read or write in progress
  assign type_i = 1'd0; //0->single req  1->cacheline req
  assign amo_i = 4'd0;
  assign addr_i = top_out_a_address;
  assign we_i = (top_out_a_opcode != 'h4); //opcode==0 write,opcode==4 read
  assign wdata_i = (top_out_a_valid && top_out_a_ready && gnt_o) ? top_out_a_data : l2cache_req_data;
  assign be_i =  (top_out_a_valid && top_out_a_ready && gnt_o) ? top_out_a_mask : l2cache_req_mask;
  assign size_i = 3'd3; //8bytes
  assign id_i = top_out_a_source;

  assign top_out_d_valid = valid_o;
  assign top_out_d_opcode = mem_rsp_opcode; 
  assign top_out_d_size = 'h0; //dont care
  assign top_out_d_source = mem_rsp_source;
  assign top_out_d_data = rdata_o;
  assign top_out_d_param = 'h0; //dont care
  
  axi4lite_2_cta #(
    .AXILITE_ADDR_WIDTH(`AXILITE_ADDR_WIDTH),
    .AXILITE_DATA_WIDTH(`AXILITE_DATA_WIDTH),
    .AXILITE_PROT_WIDTH(`AXILITE_PROT_WIDTH),
    .AXILITE_RESP_WIDTH(`AXILITE_RESP_WIDTH),  
    .AXILITE_STRB_WIDTH(`AXILITE_STRB_WIDTH)
    ) axi2cta(
    .clk                                             (clk                                           ),
    .rst_n                                           (rst_n                                         ),

    .host_rsp_ready_o                                (host_rsp_ready                                ),
    .host_rsp_valid_i                                (host_rsp_valid                                ),
    .host_rsp_inflight_wg_buffer_host_wf_done_wg_id_i(host_rsp_inflight_wg_buffer_host_wf_done_wg_id),

    .host_req_ready_i                                (host_req_ready                                ),
    .host_req_valid_o                                (host_req_valid                                ),
    .host_req_wg_id_o                                (host_req_wg_id                                ),
    .host_req_num_wf_o                               (host_req_num_wf                               ),
    .host_req_wf_size_o                              (host_req_wf_size                              ),
    .host_req_start_pc_o                             (host_req_start_pc                             ),
    .host_req_kernel_size_3d_o                       (host_req_kernel_size_3d                       ),
    .host_req_pds_baseaddr_o                         (host_req_pds_baseaddr                         ),
    .host_req_csr_knl_o                              (host_req_csr_knl                              ),
    .host_req_vgpr_size_total_o                      (host_req_vgpr_size_total                      ),
    .host_req_sgpr_size_total_o                      (host_req_sgpr_size_total                      ),
    .host_req_lds_size_total_o                       (host_req_lds_size_total                       ),
    .host_req_gds_size_total_o                       (host_req_gds_size_total                       ),
    .host_req_vgpr_size_per_wf_o                     (host_req_vgpr_size_per_wf                     ),
    .host_req_sgpr_size_per_wf_o                     (host_req_sgpr_size_per_wf                     ),
    .host_req_gds_baseaddr_o                         (host_req_gds_baseaddr                         ),

    .s_axilite_awready_o                             (s_axilite_awready_o                           ),
    .s_axilite_awvalid_i                             (s_axilite_awvalid_i                           ),
    .s_axilite_awaddr_i                              (s_axilite_awaddr_i                            ),
    .s_axilite_awprot_i                              (s_axilite_awprot_i                            ),

    .s_axilite_wready_o                              (s_axilite_wready_o                            ),
    .s_axilite_wvalid_i                              (s_axilite_wvalid_i                            ),
    .s_axilite_wdata_i                               (s_axilite_wdata_i                             ),
    .s_axilite_wstrb_i                               (s_axilite_wstrb_i                             ),

    .s_axilite_bready_i                              (s_axilite_bready_i                            ),
    .s_axilite_bvalid_o                              (s_axilite_bvalid_o                            ),
    .s_axilite_bresp_o                               (s_axilite_bresp_o                             ),

    .s_axilite_arready_o                             (s_axilite_arready_o                           ),
    .s_axilite_arvalid_i                             (s_axilite_arvalid_i                           ),
    .s_axilite_araddr_i                              (s_axilite_araddr_i                            ),
    .s_axilite_arprot_i                              (s_axilite_arprot_i                            ),

    .s_axilite_rready_i                              (s_axilite_rready_i                            ),
    .s_axilite_rdata_o                               (s_axilite_rdata_o                             ),
    .s_axilite_rresp_o                               (s_axilite_rresp_o                             ),
    .s_axilite_rvalid_o                              (s_axilite_rvalid_o                            )
    );
  
  GPGPU_top gpgpu_top(
    .clk                                             (clk                                           ),
    .rst_n                                           (rst_n                                         ),
                                                                                                      
    .host_req_valid_i                                (host_req_valid                                ),
    .host_req_ready_o                                (host_req_ready                                ),
    .host_req_wg_id_i                                (host_req_wg_id                                ),
    .host_req_num_wf_i                               (host_req_num_wf                               ),
    .host_req_wf_size_i                              (host_req_wf_size                              ),
    .host_req_start_pc_i                             (host_req_start_pc                             ),
    .host_req_kernel_size_3d_i                       (host_req_kernel_size_3d                       ),
    .host_req_pds_baseaddr_i                         (host_req_pds_baseaddr                         ),
    .host_req_csr_knl_i                              (host_req_csr_knl                              ),
    .host_req_vgpr_size_total_i                      (host_req_vgpr_size_total                      ),
    .host_req_sgpr_size_total_i                      (host_req_sgpr_size_total                      ),
    .host_req_lds_size_total_i                       (host_req_lds_size_total                       ),
    .host_req_gds_size_total_i                       (host_req_gds_size_total                       ),
    .host_req_vgpr_size_per_wf_i                     (host_req_vgpr_size_per_wf                     ),
    .host_req_sgpr_size_per_wf_i                     (host_req_sgpr_size_per_wf                     ),
    .host_req_gds_baseaddr_i                         (host_req_gds_baseaddr                         ),
                                                                                                      
    .host_rsp_valid_o                                (host_rsp_valid                                ),
    .host_rsp_ready_i                                (host_rsp_ready                                ),
    .host_rsp_inflight_wg_buffer_host_wf_done_wg_id_o(host_rsp_inflight_wg_buffer_host_wf_done_wg_id),
   
    `ifdef NO_CACHE
    .icache_mem_rsp_valid_i                          (),
    .icache_mem_rsp_ready_o                          (),
    .icache_mem_rsp_addr_i                           (),
    .icache_mem_rsp_data_i                           (),
    .icache_mem_rsp_source_i                         (),

    .icache_mem_req_valid_o                          ()
    .icache_mem_req_ready_i                          (),
    .icache_mem_req_addr_o                           (),
    .icache_mem_req_source_o                         (),

    .dcache_mem_rsp_valid_i                          (),
    .dcache_mem_rsp_ready_o                          (),
    .dcache_mem_rsp_instrid_i                        (),
    .dcache_mem_rsp_data_i                           (),
    .dcache_mem_rsp_activemask_i                     (),

    .dcache_mem_req_valid_o                          (),
    .dcache_mem_req_ready_i                          (),
    .dcache_mem_req_instrid_o                        (),
    .dcache_mem_req_setidx_o                         (),
    .dcache_mem_req_tag_o                            (),
    .dcache_mem_req_activemask_o                     (),
    .dcache_mem_req_blockoffset_o                    (),
    .dcache_mem_req_wordoffset1h_o                   (),
    .dcache_mem_req_data_o                           (),
    .dcache_mem_req_opcode_o                         (),
    .dcache_mem_req_param_o                          () 
    `else
    .out_a_valid_o                                   (top_out_a_valid                               ),
    .out_a_ready_i                                   (top_out_a_ready                               ),
    .out_a_opcode_o                                  (top_out_a_opcode                              ),
    .out_a_size_o                                    (top_out_a_size                                ),
    .out_a_source_o                                  (top_out_a_source                              ),
    .out_a_address_o                                 (top_out_a_address                             ),
    .out_a_mask_o                                    (top_out_a_mask                                ),
    .out_a_data_o                                    (top_out_a_data                                ),
    .out_a_param_o                                   (top_out_a_param                               ),

    .out_d_valid_i                                   (top_out_d_valid                               ),
    .out_d_ready_o                                   (top_out_d_ready                               ),
    .out_d_opcode_i                                  (top_out_d_opcode                              ),
    .out_d_size_i                                    (top_out_d_size                                ),
    .out_d_source_i                                  (top_out_d_source                              ),
    .out_d_data_i                                    (top_out_d_data                                ),
    .out_d_param_i                                   (top_out_d_param                               )
    `endif
    );

  axi4_adapter_top #(
    .DATA_WIDTH            (64                     ),
    .CACHELINE_BYTE_OFFSET (3                      ),
    .AXI_ADDR_WIDTH        (`AXI_ADDR_WIDTH        ),
    .AXI_DATA_WIDTH        (`AXI_DATA_WIDTH        ),
    .AXI_ID_WIDTH          (`AXI_ID_WIDTH          ),
    .AXI_LEN_WIDTH         (`AXI_LEN_WIDTH         ),
    .AXI_SIZE_WIDTH        (`AXI_SIZE_WIDTH        ),
    .AXI_BURST_WIDTH       (`AXI_BURST_WIDTH       ),
    .AXI_CACHE_WIDTH       (`AXI_CACHE_WIDTH       ),
    .AXI_PROT_WIDTH        (`AXI_PROT_WIDTH        ),
    .AXI_QOS_WIDTH         (`AXI_QOS_WIDTH         ),
    .AXI_REGION_WIDTH      (`AXI_REGION_WIDTH      ),
    .AXI_USER_WIDTH        (`AXI_USER_WIDTH        ),
    .AXI_ATOP_WIDTH        (`AXI_ATOP_WIDTH        ),
    .AXI_RESP_WIDTH        (`AXI_RESP_WIDTH        ) 
    ) l2_2_mem(
    .clk                  (clk                  ), 
    .rst_n                (rst_n                ),

    .busy_o               (busy_o               ),
    .req_i                (req_i                ),
    .type_i               (type_i               ),
    .amo_i                (amo_i                ),
    .gnt_o                (gnt_o                ),
    .addr_i               (addr_i               ),
    .we_i                 (we_i                 ),
    .wdata_i              (wdata_i              ),
    .be_i                 (be_i                 ),
    .size_i               (size_i               ),
    .id_i                 (id_i                 ),
                                                
    .valid_o              (valid_o              ),
    .rdata_o              (rdata_o              ),
    .id_o                 (id_o                 ),
                                                
    .critical_word_o      (critical_word_o      ),
    .critical_word_valid_o(critical_word_valid_o),

    .m_axi_awready_i      (m_axi_awready_i      ),
    .m_axi_awvalid_o      (m_axi_awvalid_o      ),
    .m_axi_awid_o         (m_axi_awid_o         ),
    .m_axi_awaddr_o       (m_axi_awaddr_o       ),
    .m_axi_awlen_o        (m_axi_awlen_o        ),
    .m_axi_awsize_o       (m_axi_awsize_o       ),
    .m_axi_awburst_o      (m_axi_awburst_o      ),
    .m_axi_awlock_o       (m_axi_awlock_o       ),
    .m_axi_awcache_o      (m_axi_awcache_o      ),
    .m_axi_awprot_o       (m_axi_awprot_o       ),
    .m_axi_awqos_o        (m_axi_awqos_o        ),
    .m_axi_awregion_o     (m_axi_awregion_o     ),
    .m_axi_awatop_o       (m_axi_awatop_o       ),
    .m_axi_awuser_o       (m_axi_awuser_o       ),

    .m_axi_wready_i       (m_axi_wready_i       ),
    .m_axi_wvalid_o       (m_axi_wvalid_o       ),
    .m_axi_wdata_o        (m_axi_wdata_o        ),
    .m_axi_wstrb_o        (m_axi_wstrb_o        ),
    .m_axi_wlast_o        (m_axi_wlast_o        ),
    .m_axi_wuser_o        (m_axi_wuser_o        ),

    .m_axi_bready_o       (m_axi_bready_o       ),
    .m_axi_bvalid_i       (m_axi_bvalid_i       ),
    .m_axi_bid_i          (m_axi_bid_i          ),
    .m_axi_bresp_i        (m_axi_bresp_i        ),
    .m_axi_buser_i        (m_axi_buser_i        ),

    .m_axi_arready_i      (m_axi_arready_i      ),
    .m_axi_arvalid_o      (m_axi_arvalid_o      ),
    .m_axi_arid_o         (m_axi_arid_o         ),
    .m_axi_araddr_o       (m_axi_araddr_o       ),
    .m_axi_arlen_o        (m_axi_arlen_o        ),
    .m_axi_arsize_o       (m_axi_arsize_o       ),
    .m_axi_arburst_o      (m_axi_arburst_o      ),
    .m_axi_arlock_o       (m_axi_arlock_o       ),
    .m_axi_arcache_o      (m_axi_arcache_o      ),
    .m_axi_arprot_o       (m_axi_arprot_o       ),
    .m_axi_arqos_o        (m_axi_arqos_o        ),
    .m_axi_arregion_o     (m_axi_arregion_o     ),
    .m_axi_aruser_o       (m_axi_aruser_o       ),

    .m_axi_rready_o       (m_axi_rready_o       ),
    .m_axi_rvalid_i       (m_axi_rvalid_i       ),
    .m_axi_rid_i          (m_axi_rid_i          ),
    .m_axi_rdata_i        (m_axi_rdata_i        ),
    .m_axi_rresp_i        (m_axi_rresp_i        ),
    .m_axi_rlast_i        (m_axi_rlast_i        ),
    .m_axi_ruser_i        (m_axi_ruser_i        )
    );

endmodule
