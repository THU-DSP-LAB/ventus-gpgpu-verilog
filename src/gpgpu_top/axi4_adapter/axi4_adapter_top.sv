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

module axi4_adapter_top #(
  parameter int unsigned DATA_WIDTH             = 64 ,
  parameter int unsigned CACHELINE_BYTE_OFFSET  = 3  ,

  parameter logic        CRITICAL_WORD_FIRST    = 0  , 
  parameter int unsigned MAX_OUTSTANDING_STORES = 0  ,

  parameter int unsigned AXI_ADDR_WIDTH         = 32 ,
  parameter int unsigned AXI_DATA_WIDTH         = 64 ,
  parameter int unsigned AXI_ID_WIDTH           = 4  ,
  parameter int unsigned AXI_LEN_WIDTH          = 8  ,
  parameter int unsigned AXI_SIZE_WIDTH         = 3  ,
  parameter int unsigned AXI_BURST_WIDTH        = 2  ,
  parameter int unsigned AXI_CACHE_WIDTH        = 4  ,
  parameter int unsigned AXI_PROT_WIDTH         = 3  ,
  parameter int unsigned AXI_QOS_WIDTH          = 4  ,
  parameter int unsigned AXI_REGION_WIDTH       = 4  ,
  parameter int unsigned AXI_USER_WIDTH         = 32 ,
  parameter int unsigned AXI_ATOP_WIDTH         = 6  ,
  parameter int unsigned AXI_RESP_WIDTH         = 2   
  )
  (
  input  logic                                                           clk                  ,  
  input  logic                                                           rst_n                , 

  output logic                                                           busy_o               ,
  input  logic                                                           req_i                , // req valid
  input  logic                                                           type_i               , // req type 0-single req 1-burst req
  input  logic [3:0]                                                     amo_i                , // amo type
  output logic                                                           gnt_o                , // req ready
  input  logic [AXI_ADDR_WIDTH-1:0]                                      addr_i               ,
  input  logic                                                           we_i                 , // write or read
  input  logic [(DATA_WIDTH/AXI_DATA_WIDTH)-1:0][AXI_DATA_WIDTH-1:0]     wdata_i              ,
  input  logic [(DATA_WIDTH/AXI_DATA_WIDTH)-1:0][(AXI_DATA_WIDTH/8)-1:0] be_i                 ,
  input  logic [2:0]                                                     size_i               , // 1,2,4 or 8 bytes
  input  logic [AXI_ID_WIDTH-1:0]                                        id_i                 ,
  // read port
  output logic                                                           valid_o              ,
  output logic [(DATA_WIDTH/AXI_DATA_WIDTH)-1:0][AXI_DATA_WIDTH-1:0]     rdata_o              ,
  output logic [AXI_ID_WIDTH-1:0]                                        id_o                 ,
  // critical word - read port
  output logic [AXI_DATA_WIDTH-1:0]                                      critical_word_o      ,
  output logic                                                           critical_word_valid_o,

  input  logic                                                           m_axi_awready_i      ,
  output logic                                                           m_axi_awvalid_o      ,
  output logic [AXI_ID_WIDTH-1:0]                                        m_axi_awid_o         ,
  output logic [AXI_ADDR_WIDTH-1:0]                                      m_axi_awaddr_o       ,
  output logic [AXI_LEN_WIDTH-1:0]                                       m_axi_awlen_o        ,
  output logic [AXI_SIZE_WIDTH-1:0]                                      m_axi_awsize_o       ,
  output logic [AXI_BURST_WIDTH-1:0]                                     m_axi_awburst_o      ,
  output logic                                                           m_axi_awlock_o       ,
  output logic [AXI_CACHE_WIDTH-1:0]                                     m_axi_awcache_o      ,
  output logic [AXI_PROT_WIDTH-1:0]                                      m_axi_awprot_o       ,
  output logic [AXI_QOS_WIDTH-1:0]                                       m_axi_awqos_o        ,
  output logic [AXI_REGION_WIDTH-1:0]                                    m_axi_awregion_o     ,
  output logic [AXI_ATOP_WIDTH-1:0]                                      m_axi_awatop_o       ,
  output logic [AXI_USER_WIDTH-1:0]                                      m_axi_awuser_o       ,

  input  logic                                                           m_axi_wready_i       ,
  output logic                                                           m_axi_wvalid_o       ,
  output logic [AXI_DATA_WIDTH-1:0]                                      m_axi_wdata_o        ,
  output logic [(AXI_DATA_WIDTH/8)-1:0]                                  m_axi_wstrb_o        ,
  output logic                                                           m_axi_wlast_o        ,
  output logic [AXI_USER_WIDTH-1:0]                                      m_axi_wuser_o        ,

  output logic                                                           m_axi_bready_o       ,
  input  logic                                                           m_axi_bvalid_i       ,
  input  logic [AXI_ID_WIDTH-1:0]                                        m_axi_bid_i          ,
  input  logic [AXI_RESP_WIDTH-1:0]                                      m_axi_bresp_i        ,
  input  logic [AXI_USER_WIDTH-1:0]                                      m_axi_buser_i        ,
  
  input  logic                                                           m_axi_arready_i      ,
  output logic                                                           m_axi_arvalid_o      ,
  output logic [AXI_ID_WIDTH-1:0]                                        m_axi_arid_o         ,
  output logic [AXI_ADDR_WIDTH-1:0]                                      m_axi_araddr_o       ,
  output logic [AXI_LEN_WIDTH-1:0]                                       m_axi_arlen_o        ,
  output logic [AXI_SIZE_WIDTH-1:0]                                      m_axi_arsize_o       ,
  output logic [AXI_BURST_WIDTH-1:0]                                     m_axi_arburst_o      ,
  output logic                                                           m_axi_arlock_o       ,
  output logic [AXI_CACHE_WIDTH-1:0]                                     m_axi_arcache_o      ,
  output logic [AXI_PROT_WIDTH-1:0]                                      m_axi_arprot_o       ,
  output logic [AXI_QOS_WIDTH-1:0]                                       m_axi_arqos_o        ,
  output logic [AXI_REGION_WIDTH-1:0]                                    m_axi_arregion_o     ,
  output logic [AXI_USER_WIDTH-1:0]                                      m_axi_aruser_o       ,

  output logic                                                           m_axi_rready_o       ,
  input  logic                                                           m_axi_rvalid_i       ,
  input  logic [AXI_ID_WIDTH-1:0]                                        m_axi_rid_i          ,
  input  logic [AXI_DATA_WIDTH-1:0]                                      m_axi_rdata_i        ,
  input  logic [AXI_RESP_WIDTH-1:0]                                      m_axi_rresp_i        ,
  input  logic                                                           m_axi_rlast_i        ,
  input  logic [AXI_USER_WIDTH-1:0]                                      m_axi_ruser_i         
  );

  typedef struct packed {
    logic [AXI_ID_WIDTH-1:0]     id    ;
    logic [AXI_ADDR_WIDTH-1:0]   addr  ;
    logic [AXI_LEN_WIDTH-1:0]    len   ;
    logic [AXI_SIZE_WIDTH-1:0]   size  ;
    logic [AXI_BURST_WIDTH-1:0]  burst ;
    logic                        lock  ;
    logic [AXI_CACHE_WIDTH-1:0]  cache ;
    logic [AXI_PROT_WIDTH-1:0]   prot  ;
    logic [AXI_QOS_WIDTH-1:0]    qos   ;
    logic [AXI_REGION_WIDTH-1:0] region;
    logic [AXI_ATOP_WIDTH-1:0]   atop  ;
    logic [AXI_USER_WIDTH-1:0]   user  ;
  } axi_aw_chan_t; 

  typedef struct packed {
    logic [AXI_DATA_WIDTH-1:0]     data;
    logic [(AXI_DATA_WIDTH/8)-1:0] strb;
    logic                          last;
    logic [AXI_USER_WIDTH-1:0]     user;
  } axi_w_chan_t;

  typedef struct packed {
    logic [AXI_ID_WIDTH-1:0]   id  ;
    logic [AXI_RESP_WIDTH-1:0] resp;
    logic [AXI_USER_WIDTH-1:0] user;
  } b_chan_t;

  typedef struct packed {
    logic [AXI_ID_WIDTH-1:0]     id    ;
    logic [AXI_ADDR_WIDTH-1:0]   addr  ;
    logic [AXI_LEN_WIDTH-1:0]    len   ;
    logic [AXI_SIZE_WIDTH-1:0]   size  ;
    logic [AXI_BURST_WIDTH-1:0]  burst ;
    logic                        lock  ;
    logic [AXI_CACHE_WIDTH-1:0]  cache ;
    logic [AXI_PROT_WIDTH-1:0]   prot  ;
    logic [AXI_QOS_WIDTH-1:0]    qos   ;
    logic [AXI_REGION_WIDTH-1:0] region;
    logic [AXI_USER_WIDTH-1:0]   user  ;
  } axi_ar_chan_t; 

  typedef struct packed {
    logic [AXI_ID_WIDTH-1:0]   id  ;
    logic [AXI_DATA_WIDTH-1:0] data;
    logic [AXI_RESP_WIDTH-1:0] resp;
    logic                      last;
    logic [AXI_USER_WIDTH-1:0] user;
  } r_chan_t;

  typedef struct packed {
    axi_aw_chan_t aw      ;
    logic         aw_valid;
    axi_w_chan_t  w       ;
    logic         w_valid ;
    logic         b_ready ;
    axi_ar_chan_t ar      ;
    logic         ar_valid;
    logic         r_ready ;
  } axi_req_t;

  typedef struct packed {
    logic    aw_ready;
    logic    ar_ready;
    logic    w_ready ;
    logic    b_valid ;
    b_chan_t b       ;
    logic    r_valid ;
    r_chan_t r       ;
  } axi_rsp_t;

  axi_req_t adapter_axi_req_o,cut_slv_req_i,cut_mst_req_o;
  axi_rsp_t adapter_axi_rsp_i,cut_slv_resp_o,cut_mst_resp_i;

  // aw channel
  assign adapter_axi_rsp_i.aw_ready = cut_slv_resp_o.aw_ready;
  assign cut_slv_req_i.aw_valid = adapter_axi_req_o.aw_valid;
  assign cut_slv_req_i.aw = adapter_axi_req_o.aw;

  assign cut_mst_resp_i.aw_ready = m_axi_awready_i;
  assign m_axi_awvalid_o = cut_mst_req_o.aw_valid;
  assign m_axi_awid_o = cut_mst_req_o.aw.id;
  assign m_axi_awaddr_o = cut_mst_req_o.aw.addr;
  assign m_axi_awlen_o = cut_mst_req_o.aw.len;
  assign m_axi_awsize_o = cut_mst_req_o.aw.size;
  assign m_axi_awburst_o = cut_mst_req_o.aw.burst;
  assign m_axi_awlock_o = cut_mst_req_o.aw.lock;
  assign m_axi_awcache_o = cut_mst_req_o.aw.cache;
  assign m_axi_awprot_o = cut_mst_req_o.aw.prot;
  assign m_axi_awqos_o = cut_mst_req_o.aw.qos;
  assign m_axi_awregion_o = cut_mst_req_o.aw.region;
  assign m_axi_awatop_o = cut_mst_req_o.aw.atop;
  assign m_axi_awuser_o = cut_mst_req_o.aw.user;

  // w channel
  assign adapter_axi_rsp_i.w_ready = cut_slv_resp_o.w_ready;
  assign cut_slv_req_i.w_valid = adapter_axi_req_o.w_valid;
  assign cut_slv_req_i.w = adapter_axi_req_o.w;
  
  assign cut_mst_resp_i.w_ready = m_axi_wready_i;
  assign m_axi_wvalid_o = cut_mst_req_o.w_valid;
  assign m_axi_wdata_o = cut_mst_req_o.w.data;
  assign m_axi_wstrb_o = cut_mst_req_o.w.strb;
  assign m_axi_wlast_o = cut_mst_req_o.w.last;
  assign m_axi_wuser_o = cut_mst_req_o.w.user;

  // b channel
  assign m_axi_bready_o = cut_mst_req_o.b_ready;
  assign cut_mst_resp_i.b_valid = m_axi_bvalid_i;
  assign cut_mst_resp_i.b.id = m_axi_bid_i;
  assign cut_mst_resp_i.b.resp = m_axi_bresp_i;
  assign cut_mst_resp_i.b.user = m_axi_buser_i;

  assign cut_slv_req_i.b_ready = adapter_axi_req_o.b_ready;
  assign adapter_axi_rsp_i.b_valid = cut_slv_resp_o.b_valid;
  assign adapter_axi_rsp_i.b.id = cut_slv_resp_o.b.id;
  assign adapter_axi_rsp_i.b.resp = cut_slv_resp_o.b.resp;
  assign adapter_axi_rsp_i.b.user = cut_slv_resp_o.b.user;

  // ar channel
  assign adapter_axi_rsp_i.ar_ready = cut_slv_resp_o.ar_ready;
  assign cut_slv_req_i.ar_valid = adapter_axi_req_o.ar_valid;
  assign cut_slv_req_i.ar = adapter_axi_req_o.ar;

  assign cut_mst_resp_i.ar_ready = m_axi_arready_i;
  assign m_axi_arvalid_o = cut_mst_req_o.ar_valid;
  assign m_axi_arid_o = cut_mst_req_o.ar.id;
  assign m_axi_araddr_o = cut_mst_req_o.ar.addr;
  assign m_axi_arlen_o = cut_mst_req_o.ar.len;
  assign m_axi_arsize_o = cut_mst_req_o.ar.size;
  assign m_axi_arburst_o = cut_mst_req_o.ar.burst;
  assign m_axi_arlock_o = cut_mst_req_o.ar.lock;
  assign m_axi_arcache_o = cut_mst_req_o.ar.cache;
  assign m_axi_arprot_o = cut_mst_req_o.ar.prot;
  assign m_axi_arqos_o = cut_mst_req_o.ar.qos;
  assign m_axi_arregion_o = cut_mst_req_o.ar.region;
  assign m_axi_aruser_o = cut_mst_req_o.ar.user;

  // r channel
  assign m_axi_rready_o = cut_mst_req_o.r_ready;
  assign cut_mst_resp_i.r_valid = m_axi_rvalid_i;
  assign cut_mst_resp_i.r.id = m_axi_rid_i;
  assign cut_mst_resp_i.r.data = m_axi_rdata_i;
  assign cut_mst_resp_i.r.resp = m_axi_rresp_i;
  assign cut_mst_resp_i.r.last = m_axi_rlast_i;
  assign cut_mst_resp_i.r.user = m_axi_ruser_i;

  assign cut_slv_req_i.r_ready = adapter_axi_req_o.r_ready;
  assign adapter_axi_rsp_i.r_valid = cut_slv_resp_o.r_valid;
  assign adapter_axi_rsp_i.r.id = cut_slv_resp_o.r.id;
  assign adapter_axi_rsp_i.r.data = cut_slv_resp_o.r.data;
  assign adapter_axi_rsp_i.r.resp = cut_slv_resp_o.r.resp;
  assign adapter_axi_rsp_i.r.last = cut_slv_resp_o.r.last;
  assign adapter_axi_rsp_i.r.user = cut_slv_resp_o.r.user;

  //assign adapter_axi_rsp_i.aw_ready = m_axi_awready_i;
  //assign m_axi_awvalid_o = adapter_axi_req_o.aw_valid;
  //assign m_axi_awid_o = adapter_axi_req_o.aw.id; 
  //assign m_axi_awaddr_o = adapter_axi_req_o.aw.addr;
  //assign m_axi_awlen_o = adapter_axi_req_o.aw.len;
  //assign m_axi_awsize_o = adapter_axi_req_o.aw.size;
  //assign m_axi_awburst_o = adapter_axi_req_o.aw.burst;
  //assign m_axi_awlock_o = adapter_axi_req_o.aw.lock;
  //assign m_axi_awcache_o = adapter_axi_req_o.aw.cache;
  //assign m_axi_awprot_o = adapter_axi_req_o.aw.prot;
  //assign m_axi_awqos_o = adapter_axi_req_o.aw.qos;
  //assign m_axi_awregion_o = adapter_axi_req_o.aw.region;
  //assign m_axi_awatop_o = adapter_axi_req_o.aw.atop;
  //assign m_axi_awuser_o = adapter_axi_req_o.aw.user;

  //assign adapter_axi_rsp_i.w_ready = m_axi_wready_i;
  //assign m_axi_wvalid_o = adapter_axi_req_o.w_valid;
  //assign m_axi_wdata_o = adapter_axi_req_o.w.data;
  //assign m_axi_wstrb_o = adapter_axi_req_o.w.strb;
  //assign m_axi_wlast_o = adapter_axi_req_o.w.last;
  //assign m_axi_wuser_o = adapter_axi_req_o.w.user;

  //assign m_axi_bready_o = adapter_axi_req_o.b_ready;
  //assign adapter_axi_rsp_i.b_valid = m_axi_bvalid_i;
  //assign adapter_axi_rsp_i.b.id = m_axi_bid_i;
  //assign adapter_axi_rsp_i.b.resp = m_axi_bresp_i;
  //assign adapter_axi_rsp_i.b.user = m_axi_buser_i;
  //
  //assign adapter_axi_rsp_i.ar_ready = m_axi_arready_i;
  //assign m_axi_arvalid_o = adapter_axi_req_o.ar_valid;
  //assign m_axi_arid_o = adapter_axi_req_o.ar.id;
  //assign m_axi_araddr_o = adapter_axi_req_o.ar.addr;
  //assign m_axi_arlen_o = adapter_axi_req_o.ar.len;
  //assign m_axi_arsize_o = adapter_axi_req_o.ar.size;
  //assign m_axi_arburst_o = adapter_axi_req_o.ar.burst;
  //assign m_axi_arlock_o = adapter_axi_req_o.ar.lock;
  //assign m_axi_arcache_o = adapter_axi_req_o.ar.cache;
  //assign m_axi_arprot_o = adapter_axi_req_o.ar.prot;
  //assign m_axi_arqos_o = adapter_axi_req_o.ar.qos;
  //assign m_axi_arregion_o = adapter_axi_req_o.ar.region;
  //assign m_axi_aruser_o = adapter_axi_req_o.ar.user;

  //assign m_axi_rready_o = adapter_axi_req_o.r_ready;
  //assign adapter_axi_rsp_i.r_valid = m_axi_rvalid_i;
  //assign adapter_axi_rsp_i.r.id = m_axi_rid_i;
  //assign adapter_axi_rsp_i.r.data = m_axi_rdata_i;
  //assign adapter_axi_rsp_i.r.resp = m_axi_rresp_i;
  //assign adapter_axi_rsp_i.r.last = m_axi_rlast_i;
  //assign adapter_axi_rsp_i.r.user = m_axi_ruser_i;

  axi4_adapter #(
    .DATA_WIDTH            (DATA_WIDTH            ),
    .CRITICAL_WORD_FIRST   (CRITICAL_WORD_FIRST   ), // Critical word first enable
    .CACHELINE_BYTE_OFFSET (CACHELINE_BYTE_OFFSET ),
    .MAX_OUTSTANDING_STORES(MAX_OUTSTANDING_STORES),
    .AXI_ADDR_WIDTH        (AXI_ADDR_WIDTH        ),
    .AXI_DATA_WIDTH        (AXI_DATA_WIDTH        ),
    .AXI_ID_WIDTH          (AXI_ID_WIDTH          ),
    .AXI_LEN_WIDTH         (AXI_LEN_WIDTH         ),
    .AXI_SIZE_WIDTH        (AXI_SIZE_WIDTH        ),
    .AXI_BURST_WIDTH       (AXI_BURST_WIDTH       ),
    .AXI_CACHE_WIDTH       (AXI_CACHE_WIDTH       ),
    .AXI_PROT_WIDTH        (AXI_PROT_WIDTH        ),
    .AXI_QOS_WIDTH         (AXI_QOS_WIDTH         ),
    .AXI_REGION_WIDTH      (AXI_REGION_WIDTH      ),
    .AXI_USER_WIDTH        (AXI_USER_WIDTH        ),
    .AXI_ATOP_WIDTH        (AXI_ATOP_WIDTH        ),
    .AXI_RESP_WIDTH        (AXI_RESP_WIDTH        ),
    .axi_req_t             (axi_req_t             ),
    .axi_rsp_t             (axi_rsp_t             )
    ) axi_adapter(
    .clk_i                (clk                  ),
    .rst_ni               (rst_n                ),

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

    .axi_req_o            (adapter_axi_req_o    ), 
    .axi_resp_i           (adapter_axi_rsp_i    ) 
    );

  axi_cut #(
    .Bypass    (1'b0         ), // bypass enable
    .aw_chan_t (axi_aw_chan_t),
    .w_chan_t  (axi_w_chan_t ),
    .b_chan_t  (b_chan_t     ),
    .ar_chan_t (axi_ar_chan_t),
    .r_chan_t  (r_chan_t     ),
    .axi_req_t (axi_req_t    ),
    .axi_resp_t(axi_rsp_t    )
    ) axi_cut(
    .clk_i (clk  ),
    .rst_ni(rst_n),
    .slv_req_i (cut_slv_req_i ),
    .slv_resp_o(cut_slv_resp_o),
    .mst_req_o (cut_mst_req_o ),
    .mst_resp_i(cut_mst_resp_i)
    );

endmodule
