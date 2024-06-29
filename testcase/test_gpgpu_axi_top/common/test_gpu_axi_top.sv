`timescale 1ns/10ps

`include "define.v"

module test_gpu_axi_top;
  reg                            clk                ;
  reg                            rst_n              ;

  wire                           s_axilite_awready_o;
  reg                            s_axilite_awvalid_i;
  reg  [`AXILITE_ADDR_WIDTH-1:0] s_axilite_awaddr_i ;
  reg  [`AXILITE_PROT_WIDTH-1:0] s_axilite_awprot_i ;

  wire                           s_axilite_wready_o ;
  reg                            s_axilite_wvalid_i ;
  reg  [`AXILITE_DATA_WIDTH-1:0] s_axilite_wdata_i  ;
  reg  [`AXILITE_STRB_WIDTH-1:0] s_axilite_wstrb_i  ;

  reg                            s_axilite_bready_i ;
  wire                           s_axilite_bvalid_o ;
  wire [`AXILITE_RESP_WIDTH-1:0] s_axilite_bresp_o  ;

  wire                           s_axilite_arready_o;
  reg                            s_axilite_arvalid_i;
  reg  [`AXILITE_ADDR_WIDTH-1:0] s_axilite_araddr_i ;
  reg  [`AXILITE_PROT_WIDTH-1:0] s_axilite_arprot_i ;

  reg                            s_axilite_rready_i ;
  wire [`AXILITE_DATA_WIDTH-1:0] s_axilite_rdata_o  ;
  wire [`AXILITE_RESP_WIDTH-1:0] s_axilite_rresp_o  ;
  wire                           s_axilite_rvalid_o ;                         

  reg                            m_axi_awready_i    ;
  wire                           m_axi_awvalid_o    ;
  wire [`AXI_ID_WIDTH-1:0]       m_axi_awid_o       ;
  wire [`AXI_ADDR_WIDTH-1:0]     m_axi_awaddr_o     ;
  wire [`AXI_LEN_WIDTH-1:0]      m_axi_awlen_o      ;
  wire [`AXI_SIZE_WIDTH-1:0]     m_axi_awsize_o     ;
  wire [`AXI_BURST_WIDTH-1:0]    m_axi_awburst_o    ;
  wire                           m_axi_awlock_o     ;
  wire [`AXI_CACHE_WIDTH-1:0]    m_axi_awcache_o    ;
  wire [`AXI_PROT_WIDTH-1:0]     m_axi_awprot_o     ;
  wire [`AXI_QOS_WIDTH-1:0]      m_axi_awqos_o      ;
  wire [`AXI_REGION_WIDTH-1:0]   m_axi_awregion_o   ;
  wire [`AXI_ATOP_WIDTH-1:0]     m_axi_awatop_o     ;
  wire [`AXI_USER_WIDTH-1:0]     m_axi_awuser_o     ;

  reg                            m_axi_wready_i     ;
  wire                           m_axi_wvalid_o     ;
  wire [`AXI_DATA_WIDTH-1:0]     m_axi_wdata_o      ;
  wire [(`AXI_DATA_WIDTH/8)-1:0] m_axi_wstrb_o      ;
  wire                           m_axi_wlast_o      ;
  wire [`AXI_USER_WIDTH-1:0]     m_axi_wuser_o      ;

  wire                           m_axi_bready_o     ;
  reg                            m_axi_bvalid_i     ;
  reg  [`AXI_ID_WIDTH-1:0]       m_axi_bid_i        ;
  reg  [`AXI_RESP_WIDTH-1:0]     m_axi_bresp_i      ;
  reg  [`AXI_USER_WIDTH-1:0]     m_axi_buser_i      ;
  
  reg                            m_axi_arready_i    ;
  wire                           m_axi_arvalid_o    ;
  wire [`AXI_ID_WIDTH-1:0]       m_axi_arid_o       ;
  wire [`AXI_ADDR_WIDTH-1:0]     m_axi_araddr_o     ;
  wire [`AXI_LEN_WIDTH-1:0]      m_axi_arlen_o      ;
  wire [`AXI_SIZE_WIDTH-1:0]     m_axi_arsize_o     ;
  wire [`AXI_BURST_WIDTH-1:0]    m_axi_arburst_o    ;
  wire                           m_axi_arlock_o     ;
  wire [`AXI_CACHE_WIDTH-1:0]    m_axi_arcache_o    ;
  wire [`AXI_PROT_WIDTH-1:0]     m_axi_arprot_o     ;
  wire [`AXI_QOS_WIDTH-1:0]      m_axi_arqos_o      ;
  wire [`AXI_REGION_WIDTH-1:0]   m_axi_arregion_o   ;
  wire [`AXI_USER_WIDTH-1:0]     m_axi_aruser_o     ;

  wire                           m_axi_rready_o     ;
  reg                            m_axi_rvalid_i     ;
  reg  [`AXI_ID_WIDTH-1:0]       m_axi_rid_i        ;
  reg  [`AXI_DATA_WIDTH-1:0]     m_axi_rdata_i      ;
  reg  [`AXI_RESP_WIDTH-1:0]     m_axi_rresp_i      ;
  reg                            m_axi_rlast_i      ;
  reg  [`AXI_USER_WIDTH-1:0]     m_axi_ruser_i      ; 

  gpgpu_axi_top u_dut(
    .clk                (clk                ),
    .rst_n              (rst_n              ),
  
    .s_axilite_awready_o(s_axilite_awready_o),
    .s_axilite_awvalid_i(s_axilite_awvalid_i),
    .s_axilite_awaddr_i (s_axilite_awaddr_i ),
    .s_axilite_awprot_i (s_axilite_awprot_i ),
 
    .s_axilite_wready_o (s_axilite_wready_o ),
    .s_axilite_wvalid_i (s_axilite_wvalid_i ),
    .s_axilite_wdata_i  (s_axilite_wdata_i  ),
    .s_axilite_wstrb_i  (s_axilite_wstrb_i  ),

    .s_axilite_bready_i (s_axilite_bready_i ),
    .s_axilite_bvalid_o (s_axilite_bvalid_o ),
    .s_axilite_bresp_o  (s_axilite_bresp_o  ),

    .s_axilite_arready_o(s_axilite_arready_o),
    .s_axilite_arvalid_i(s_axilite_arvalid_i),
    .s_axilite_araddr_i (s_axilite_araddr_i ),
    .s_axilite_arprot_i (s_axilite_arprot_i ),

    .s_axilite_rready_i (s_axilite_rready_i ),
    .s_axilite_rdata_o  (s_axilite_rdata_o  ),
    .s_axilite_rresp_o  (s_axilite_rresp_o  ),
    .s_axilite_rvalid_o (s_axilite_rvalid_o ),

    .m_axi_awready_i    (m_axi_awready_i    ),
    .m_axi_awvalid_o    (m_axi_awvalid_o    ),
    .m_axi_awid_o       (m_axi_awid_o       ),
    .m_axi_awaddr_o     (m_axi_awaddr_o     ),
    .m_axi_awlen_o      (m_axi_awlen_o      ),
    .m_axi_awsize_o     (m_axi_awsize_o     ),
    .m_axi_awburst_o    (m_axi_awburst_o    ),
    .m_axi_awlock_o     (m_axi_awlock_o     ),
    .m_axi_awcache_o    (m_axi_awcache_o    ),
    .m_axi_awprot_o     (m_axi_awprot_o     ),
    .m_axi_awqos_o      (m_axi_awqos_o      ),
    .m_axi_awregion_o   (m_axi_awregion_o   ),
    .m_axi_awatop_o     (m_axi_awatop_o     ),
    .m_axi_awuser_o     (m_axi_awuser_o     ),

    .m_axi_wready_i     (m_axi_wready_i     ),
    .m_axi_wvalid_o     (m_axi_wvalid_o     ),
    .m_axi_wdata_o      (m_axi_wdata_o      ),
    .m_axi_wstrb_o      (m_axi_wstrb_o      ),
    .m_axi_wlast_o      (m_axi_wlast_o      ),
    .m_axi_wuser_o      (m_axi_wuser_o      ),

    .m_axi_bready_o     (m_axi_bready_o     ),
    .m_axi_bvalid_i     (m_axi_bvalid_i     ),
    .m_axi_bid_i        (m_axi_bid_i        ),
    .m_axi_bresp_i      (m_axi_bresp_i      ),
    .m_axi_buser_i      (m_axi_buser_i      ),

    .m_axi_arready_i    (m_axi_arready_i    ),
    .m_axi_arvalid_o    (m_axi_arvalid_o    ),
    .m_axi_arid_o       (m_axi_arid_o       ),
    .m_axi_araddr_o     (m_axi_araddr_o     ),
    .m_axi_arlen_o      (m_axi_arlen_o      ),
    .m_axi_arsize_o     (m_axi_arsize_o     ),
    .m_axi_arburst_o    (m_axi_arburst_o    ),
    .m_axi_arlock_o     (m_axi_arlock_o     ),
    .m_axi_arcache_o    (m_axi_arcache_o    ),
    .m_axi_arprot_o     (m_axi_arprot_o     ),
    .m_axi_arqos_o      (m_axi_arqos_o      ),
    .m_axi_arregion_o   (m_axi_arregion_o   ),
    .m_axi_aruser_o     (m_axi_aruser_o     ),

    .m_axi_rready_o     (m_axi_rready_o     ),
    .m_axi_rvalid_i     (m_axi_rvalid_i     ),
    .m_axi_rid_i        (m_axi_rid_i        ),
    .m_axi_rdata_i      (m_axi_rdata_i      ),
    .m_axi_rresp_i      (m_axi_rresp_i      ),
    .m_axi_rlast_i      (m_axi_rlast_i      ),
    .m_axi_ruser_i      (m_axi_ruser_i      )
    );

  gen_clk u_gen_clk(
    .clk  (clk  )
    );

  gen_rst u_gen_rst( 
    .rst_n(rst_n),
    .clk  (clk  )
    );
  
  host_inter u_host_inter(
    .clk                (clk                ),
    .rst_n              (rst_n              ),
    .s_axilite_awready_o(s_axilite_awready_o),
    .s_axilite_awvalid_i(s_axilite_awvalid_i),
    .s_axilite_awaddr_i (s_axilite_awaddr_i ),
    .s_axilite_awprot_i (s_axilite_awprot_i ),
                                   
    .s_axilite_wready_o (s_axilite_wready_o ),
    .s_axilite_wvalid_i (s_axilite_wvalid_i ),
    .s_axilite_wdata_i  (s_axilite_wdata_i  ),
    .s_axilite_wstrb_i  (s_axilite_wstrb_i  ),
                                    
    .s_axilite_bready_i (s_axilite_bready_i ),
    .s_axilite_bvalid_o (s_axilite_bvalid_o ),
    .s_axilite_bresp_o  (s_axilite_bresp_o  ),
                                    
    .s_axilite_arready_o(s_axilite_arready_o),
    .s_axilite_arvalid_i(s_axilite_arvalid_i),
    .s_axilite_araddr_i (s_axilite_araddr_i ),
    .s_axilite_arprot_i (s_axilite_arprot_i ),
                                    
    .s_axilite_rready_i (s_axilite_rready_i ),
    .s_axilite_rdata_o  (s_axilite_rdata_o  ),
    .s_axilite_rresp_o  (s_axilite_rresp_o  ),
    .s_axilite_rvalid_o (s_axilite_rvalid_o )
    );

  axi_ram #(
    .DATA_WIDTH(64),
    .ADDR_WIDTH(32),
    .ID_WIDTH  (4 )
    ) u_ram(
    .clk          (clk                  ),
    .rst          (~rst_n               ),

    .s_axi_awid   (m_axi_awid_o         ),
    .s_axi_awaddr (m_axi_awaddr_o       ),
    .s_axi_awlen  (m_axi_awlen_o        ),
    .s_axi_awsize (m_axi_awsize_o       ),
    .s_axi_awburst(m_axi_awburst_o      ),
    .s_axi_awlock (m_axi_awlock_o       ),
    .s_axi_awcache(m_axi_awcache_o      ),
    .s_axi_awprot (m_axi_awprot_o       ),
    .s_axi_awvalid(m_axi_awvalid_o      ),
    .s_axi_awready(m_axi_awready_i      ),
    .s_axi_wdata  (m_axi_wdata_o        ),
    .s_axi_wstrb  (m_axi_wstrb_o        ),
    .s_axi_wlast  (m_axi_wlast_o        ),
    .s_axi_wvalid (m_axi_wvalid_o       ),
    .s_axi_wready (m_axi_wready_i       ),
    .s_axi_bid    (m_axi_bid_i          ),
    .s_axi_bresp  (m_axi_bresp_i        ),
    .s_axi_bvalid (m_axi_bvalid_i       ),
    .s_axi_bready (m_axi_bready_o       ),
    .s_axi_arid   (m_axi_arid_o         ),
    .s_axi_araddr (m_axi_araddr_o       ),
    .s_axi_arlen  (m_axi_arlen_o        ),
    .s_axi_arsize (m_axi_arsize_o       ),
    .s_axi_arburst(m_axi_arburst_o      ),
    .s_axi_arlock (m_axi_arlock_o       ),
    .s_axi_arcache(m_axi_arcache_o      ),
    .s_axi_arprot (m_axi_arprot_o       ),
    .s_axi_arvalid(m_axi_arvalid_o      ),
    .s_axi_arready(m_axi_arready_i      ),
    .s_axi_rid    (m_axi_rid_i          ),
    .s_axi_rdata  (m_axi_rdata_i        ),
    .s_axi_rresp  (m_axi_rresp_i        ),
    .s_axi_rlast  (m_axi_rlast_i        ),
    .s_axi_rvalid (m_axi_rvalid_i       ),
    .s_axi_rready (m_axi_rready_o       )
    );

  tc u_tc();

  initial begin
    $fsdbDumpfile("test.fsdb")             ;
    $fsdbDumpvars(0,test_gpu_axi_top,"+mda","+all");
  end

task PASSED;
  $display("");
  $display("########     ###     ######   ######  ######## ######## ");             
  $display("##     ##   ## ##   ##    ## ##    ## ##       ##     ##");             
  $display("##     ##  ##   ##  ##       ##       ##       ##     ##");             
  $display("########  ##     ##  ######   ######  ######   ##     ##");             
  $display("##        #########       ##       ## ##       ##     ##");             
  $display("##        ##     ## ##    ## ##    ## ##       ##     ##");             
  $display("##        ##     ##  ######   ######  ######## ######## ");
  $display("");
endtask

task FAILED;
  $display("");
  $display ("########    ###    #### ##       ######## ######## ");
  $display ("##         ## ##    ##  ##       ##       ##     ##");
  $display ("##        ##   ##   ##  ##       ##       ##     ##");
  $display ("######   ##     ##  ##  ##       ######   ##     ##");
  $display ("##       #########  ##  ##       ##       ##     ##");
  $display ("##       ##     ##  ##  ##       ##       ##     ##");
  $display ("##       ##     ## #### ######## ######## ######## ");
  $display ("");
endtask

endmodule
