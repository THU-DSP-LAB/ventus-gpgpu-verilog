
`include "define.v"

module host_inter(
  input                            clk                ,
  input                            rst_n              ,
  input                            s_axilite_awready_o, 
  output                           s_axilite_awvalid_i,
  output [`AXILITE_ADDR_WIDTH-1:0] s_axilite_awaddr_i ,
  output [`AXILITE_PROT_WIDTH-1:0] s_axilite_awprot_i ,
                                               
  input                            s_axilite_wready_o ,
  output                           s_axilite_wvalid_i ,
  output [`AXILITE_DATA_WIDTH-1:0] s_axilite_wdata_i  ,
  output [`AXILITE_STRB_WIDTH-1:0] s_axilite_wstrb_i  ,
                                               
  output                           s_axilite_bready_i ,
  input                            s_axilite_bvalid_o ,
  input  [`AXILITE_RESP_WIDTH-1:0] s_axilite_bresp_o  ,
                                               
  input                            s_axilite_arready_o,
  output                           s_axilite_arvalid_i,
  output [`AXILITE_ADDR_WIDTH-1:0] s_axilite_araddr_i ,
  output [`AXILITE_PROT_WIDTH-1:0] s_axilite_arprot_i ,
                                               
  output                           s_axilite_rready_i ,
  input  [`AXILITE_DATA_WIDTH-1:0] s_axilite_rdata_o  ,
  input  [`AXILITE_RESP_WIDTH-1:0] s_axilite_rresp_o  ,
  input                            s_axilite_rvalid_o    
  );

  //--------------------------------------------------------------------------------
  reg                           s_axilite_awvalid_r;
  reg [`AXILITE_ADDR_WIDTH-1:0] s_axilite_awaddr_r ;
  reg [`AXILITE_PROT_WIDTH-1:0] s_axilite_awprot_r ;
  reg                           s_axilite_wvalid_r ;
  reg [`AXILITE_DATA_WIDTH-1:0] s_axilite_wdata_r  ;
  reg [`AXILITE_STRB_WIDTH-1:0] s_axilite_wstrb_r  ;
  reg                           s_axilite_bready_r ;
  reg                           s_axilite_arvalid_r;
  reg [`AXILITE_ADDR_WIDTH-1:0] s_axilite_araddr_r ;
  reg [`AXILITE_PROT_WIDTH-1:0] s_axilite_arprot_r ;
  reg                           s_axilite_rready_r ;

  assign s_axilite_awvalid_i = s_axilite_awvalid_r;
  assign s_axilite_awaddr_i  = s_axilite_awaddr_r;
  assign s_axilite_awprot_i  = s_axilite_awprot_r;
  assign s_axilite_wvalid_i  = s_axilite_wvalid_r;
  assign s_axilite_wdata_i   = s_axilite_wdata_r;
  assign s_axilite_wstrb_i   = s_axilite_wstrb_r;
  assign s_axilite_bready_i  = s_axilite_bready_r;
  assign s_axilite_arvalid_i = s_axilite_arvalid_r;
  assign s_axilite_araddr_i  = s_axilite_araddr_r;
  assign s_axilite_arprot_i  = s_axilite_arprot_r;
  assign s_axilite_rready_i  = s_axilite_rready_r;

  initial begin
    s_axilite_awvalid_r = 1'd0;
    s_axilite_awaddr_r  = {`AXILITE_ADDR_WIDTH{1'd0}};
    s_axilite_awprot_r  = {`AXILITE_PROT_WIDTH{1'd0}};
    s_axilite_wvalid_r  = 1'd0;
    s_axilite_wdata_r   = {`AXILITE_DATA_WIDTH{1'd0}};
    s_axilite_wstrb_r   = {`AXILITE_STRB_WIDTH{1'd0}};
    s_axilite_bready_r  = 1'd1; //write response channel always ready
    s_axilite_arvalid_r = 1'd0;
    s_axilite_araddr_r  = {`AXILITE_ADDR_WIDTH{1'd0}};
    s_axilite_arprot_r  = {`AXILITE_PROT_WIDTH{1'd0}};
    s_axilite_rready_r  = 1'd1; //read data channel always ready
  end

  parameter META_FNAME_SIZE = 128;
  parameter METADATA_SIZE   = 500;

  parameter DATA_FNAME_SIZE = 128;
  parameter DATADATA_SIZE   = 500;
  
  reg [31:0] metadata [METADATA_SIZE-1:0];
  reg [31:0] parsed_base_r  [0:10-1];
  reg [31:0] parsed_size_r  [0:10-1];

  reg [31:0] cycle_count  [0:2-1];
  reg [31:0] kernel_cycles       ;

  task drv_gpu;
    input [META_FNAME_SIZE*8-1:0] fn_metadata;
    input [DATA_FNAME_SIZE*8-1:0] fn_data;
    reg [31:0] block_id = 0;
    reg [63:0] noused;
    reg [63:0] kernel_id;
    reg [63:0] kernal_size0;
    reg [63:0] kernal_size1;
    reg [63:0] kernal_size2;
    reg [63:0] wf_size;
    reg [63:0] wg_size;
    reg [63:0] metaDataBaseAddr;
    reg [63:0] ldsSize;
    reg [63:0] pdsSize;
    reg [63:0] sgprUsage;
    reg [63:0] vgprUsage;
    reg [63:0] pdsBaseAddr;
    reg [63:0] num_buffer;
    reg [31:0] pds_size;
    begin
      $readmemh(fn_metadata, metadata);
      $display("============================================");
      $display("*********");
      $display("Begin test:");
      $display("metadata is %s:", fn_metadata);
      $display("data is %s:", fn_data);
      $display("*********");
      $display("");
      @(posedge clk);
      noused           = {metadata[ 1], metadata[ 0]};
      kernel_id        = {metadata[ 3], metadata[ 2]}; 
      kernal_size0     = {metadata[ 5], metadata[ 4]}; 
      kernal_size1     = {metadata[ 7], metadata[ 6]}; 
      kernal_size2     = {metadata[ 9], metadata[ 8]}; 
      wf_size          = {metadata[11], metadata[10]}; 
      wg_size          = {metadata[13], metadata[12]}; 
      metaDataBaseAddr = {metadata[15], metadata[14]}; 
      ldsSize          = {metadata[17], metadata[16]}; 
      pdsSize          = {metadata[19], metadata[18]}; 
      sgprUsage        = {metadata[21], metadata[20]}; 
      vgprUsage        = {metadata[23], metadata[22]}; 
      pdsBaseAddr      = {metadata[25], metadata[24]}; 
      num_buffer       = {metadata[27], metadata[26]}; 
      pds_size         = 32'd0;
      //host to cta
      @(posedge clk);
      axilite_write(32'h0000_0004,{`WG_ID_WIDTH{1'd0}}); //reg[1] host_req_wg_id
      @(posedge clk);
      axilite_write(32'h0000_0008,wg_size[31:0]); //reg[2] host_req_num_wf
      @(posedge clk);
      axilite_write(32'h0000_000c,wf_size[31:0]); //reg[3] host_req_wf_size
      @(posedge clk);
      axilite_write(32'h0000_0010,32'h8000_0000); //reg[4] host_req_start_pc
      @(posedge clk);
      axilite_write(32'h0000_0014,wg_size[31:0]*vgprUsage[31:0]); //reg[5] host_req_vgpr_size_total
      @(posedge clk);
      axilite_write(32'h0000_0018,wg_size[31:0]*sgprUsage[31:0]); //reg[6] host_req_sgpr_size_total
      @(posedge clk);
      axilite_write(32'h0000_001c,32'd128); //reg[7] host_req_lds_size_total
      @(posedge clk);
      axilite_write(32'h0000_0020,vgprUsage[31:0]); //reg[8] host_req_vgpr_size_per_wf
      @(posedge clk);
      axilite_write(32'h0000_0024,sgprUsage[31:0]); //reg[9] host_req_sgpr_size_per_wf
      @(posedge clk);
      axilite_write(32'h0000_0028,32'h0); //reg[10] host_req_gds_baseaddr
      @(posedge clk);
      axilite_write(32'h0000_002c,pdsBaseAddr[31:0]+block_id*pds_size*wf_size[31:0]*wg_size[31:0]); //reg[11] host_req_pds_baseaddr
      @(posedge clk);
      axilite_write(32'h0000_0030,metaDataBaseAddr[31:0]); //reg[12] host_req_csr_knl
      @(posedge clk);
      axilite_write(32'h0000_0034,32'h0); //reg[13] host_req_kernel_size_3d
      @(posedge clk);
      axilite_write(32'h0000_0038,32'h0); //reg[14] host_req_kernel_size_3d
      @(posedge clk);
      axilite_write(32'h0000_003c,32'h0); //reg[15] host_req_kernel_size_3d
      @(posedge clk);
      axilite_write(32'h0000_0000,32'd1); //reg[0] host_req_valid
      @(negedge test_gpu_axi_top.u_dut.gpgpu_top.cta.cta2host_rcvd_ack_o);
      $display("*********");
      $display("metadata is %s:", fn_metadata);
      $display("data is %s:", fn_data);
      $display("Config finish!  time: %p ns",$realtime);
      cycle_count[0] = $realtime;
      $display("*********");
      $display("");
    end
  endtask

  task axilite_write;
    input [`AXILITE_ADDR_WIDTH-1:0] w_addr;
    input [`AXILITE_DATA_WIDTH-1:0] w_data;
    begin
      fork 
        begin:write_addr
          s_axilite_awvalid_r = 1'd1;
          s_axilite_awaddr_r  = w_addr; 
          s_axilite_awprot_r  = {`AXILITE_PROT_WIDTH{1'd0}};
          wait(s_axilite_awready_o);
          @(posedge clk);
          s_axilite_awvalid_r = 1'd0;
        end
        begin:write_data
          s_axilite_wvalid_r  = 1'd1;
          s_axilite_wdata_r   = w_data; 
          s_axilite_wstrb_r   = {`AXILITE_STRB_WIDTH{1'd1}}; 
          wait(s_axilite_wready_o);
          @(posedge clk);
          s_axilite_wvalid_r  = 1'd0;
        end
      join
    end 
  endtask

  task axilite_read;
    input  [`AXILITE_ADDR_WIDTH-1:0] r_addr;
    output [`AXILITE_DATA_WIDTH-1:0] r_data;
    begin
      s_axilite_rready_r  = 1'd1; //read bus always ready
      s_axilite_arvalid_r = 1'd1;
      s_axilite_araddr_r  = r_addr;
      s_axilite_arprot_r  = {`AXILITE_PROT_WIDTH{1'd0}};
      wait(s_axilite_arready_o);
      @(posedge clk);
      s_axilite_arvalid_r = 1'd0;
      wait(s_axilite_rvalid_o);
      #1;
        r_data = s_axilite_rdata_o;
    end
  endtask

  task exe_finish;
    input [META_FNAME_SIZE*8-1:0] fn_metadata;
    input [DATA_FNAME_SIZE*8-1:0] fn_data;
    reg [`AXILITE_DATA_WIDTH-1:0] r_data;
    integer i;
    begin
      i = 0;
      r_data=0;
      while(i == 0) begin
        wait(!s_axilite_rvalid_o)
        axilite_read(32'h0000_0044,r_data);
        @(posedge clk);
        if(r_data)
          i = 1;
          @(posedge clk);
          @(posedge clk);
      end
      $display("*********");
      $display("metadata is %s:", fn_metadata);
      $display("data is %s:", fn_data);
      $display("exe finish!     time: %p ns",$realtime);
      cycle_count[1] = $realtime;
      $display("*********");
      $display("");
      kernel_cycles = (cycle_count[1]-cycle_count[0])/10;
      $display("*********");
      $display("Single kernel need : %p cycles",kernel_cycles);
      $display("*********");
      $display("");
      $display("============================================");
      $display("");
    end
  endtask

  task get_result_addr;
    input [META_FNAME_SIZE*8-1:0] fn_metadata;
    input [DATA_FNAME_SIZE*8-1:0] fn_data;
    reg   [31:0]                  num_buffer;
    integer i;
    begin
      $readmemh(fn_metadata, metadata);
      @(posedge clk);
      num_buffer          = metadata[26]; 
      for(i=0; i<num_buffer; i=i+1) begin
        parsed_base_r[i]  = metadata[28+i*2];
        parsed_size_r[i]  = metadata[28+i*2+num_buffer*2];
      end
    end
  endtask


endmodule
