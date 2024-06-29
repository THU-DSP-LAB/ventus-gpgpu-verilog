
`include "define.v"

module host_inter(
   input                           clk
  ,input                           rst_n
  ,output                          host_req_valid_i
  ,input                           host_req_ready_o
  ,output [`WG_ID_WIDTH-1:0]       host_req_wg_id_i
  ,output [`WF_COUNT_WIDTH-1:0]    host_req_num_wf_i
  ,output [`WAVE_ITEM_WIDTH-1:0]   host_req_wf_size_i
  ,output [`MEM_ADDR_WIDTH-1:0]    host_req_start_pc_i
  ,output [`WG_SIZE_X_WIDTH*3-1:0] host_req_kernel_size_3d_i
  ,output [`MEM_ADDR_WIDTH-1:0]    host_req_pds_baseaddr_i
  ,output [`MEM_ADDR_WIDTH-1:0]    host_req_csr_knl_i
  ,output [`VGPR_ID_WIDTH:0]       host_req_vgpr_size_total_i
  ,output [`SGPR_ID_WIDTH:0]       host_req_sgpr_size_total_i
  ,output [`LDS_ID_WIDTH:0]        host_req_lds_size_total_i
  ,output [`GDS_ID_WIDTH:0]        host_req_gds_size_total_i
  ,output [`VGPR_ID_WIDTH:0]       host_req_vgpr_size_per_wf_i
  ,output [`SGPR_ID_WIDTH:0]       host_req_sgpr_size_per_wf_i
  ,output [`MEM_ADDR_WIDTH-1:0]    host_req_gds_baseaddr_i

  ,input                           host_rsp_valid_o
  ,output                          host_rsp_ready_i
  ,input  [`WG_ID_WIDTH-1:0]       host_rsp_inflight_wg_buffer_host_wf_done_wg_id_o
  );
  //--------------------------------------------------------------------------------
  reg                          host_req_valid_r;
  reg [`WG_ID_WIDTH-1:0]       host_req_wg_id_r;
  reg [`WF_COUNT_WIDTH-1:0]    host_req_num_wf_r;
  reg [`WAVE_ITEM_WIDTH-1:0]   host_req_wf_size_r;
  reg [`MEM_ADDR_WIDTH-1:0]    host_req_start_pc_r;
  reg [`WG_SIZE_X_WIDTH*3-1:0] host_req_kernel_size_3d_r;
  reg [`MEM_ADDR_WIDTH-1:0]    host_req_pds_baseaddr_r;
  reg [`MEM_ADDR_WIDTH-1:0]    host_req_csr_knl_r;
  reg [`VGPR_ID_WIDTH:0]       host_req_vgpr_size_total_r;
  reg [`SGPR_ID_WIDTH:0]       host_req_sgpr_size_total_r;
  reg [`LDS_ID_WIDTH:0]        host_req_lds_size_total_r;
  reg [`GDS_ID_WIDTH:0]        host_req_gds_size_total_r;
  reg [`VGPR_ID_WIDTH:0]       host_req_vgpr_size_per_wf_r;
  reg [`SGPR_ID_WIDTH:0]       host_req_sgpr_size_per_wf_r;
  reg [`MEM_ADDR_WIDTH-1:0]    host_req_gds_baseaddr_r;
  reg                          host_rsp_ready_r;
  
  assign host_req_valid_i            = host_req_valid_r;
  assign host_req_wg_id_i            = host_req_wg_id_r;
  assign host_req_num_wf_i           = host_req_num_wf_r;
  assign host_req_wf_size_i          = host_req_wf_size_r;
  assign host_req_start_pc_i         = host_req_start_pc_r;
  assign host_req_kernel_size_3d_i   = host_req_kernel_size_3d_r;
  assign host_req_pds_baseaddr_i     = host_req_pds_baseaddr_r;
  assign host_req_csr_knl_i          = host_req_csr_knl_r;
  assign host_req_vgpr_size_total_i  = host_req_vgpr_size_total_r;
  assign host_req_sgpr_size_total_i  = host_req_sgpr_size_total_r;
  assign host_req_lds_size_total_i   = host_req_lds_size_total_r;
  assign host_req_gds_size_total_i   = host_req_gds_size_total_r;
  assign host_req_vgpr_size_per_wf_i = host_req_vgpr_size_per_wf_r;
  assign host_req_sgpr_size_per_wf_i = host_req_sgpr_size_per_wf_r;
  assign host_req_gds_baseaddr_i     = host_req_gds_baseaddr_r;
  assign host_rsp_ready_i            = host_rsp_ready_r;
 
  initial begin
    host_req_valid_r           = 1'd0;
    host_req_wg_id_r           = {`WG_ID_WIDTH{1'd0}};
    host_req_num_wf_r          = {`WF_COUNT_WIDTH{1'd0}};
    host_req_wf_size_r         = {`WAVE_ITEM_WIDTH{1'd0}};
    host_req_start_pc_r        = {`MEM_ADDR_WIDTH{1'd0}};
    host_req_kernel_size_3d_r  = {`WG_SIZE_X_WIDTH*3{1'd0}};
    host_req_pds_baseaddr_r    = {`MEM_ADDR_WIDTH{1'd0}};
    host_req_csr_knl_r         = {`MEM_ADDR_WIDTH{1'd0}};
    host_req_vgpr_size_total_r = {`VGPR_ID_WIDTH{1'd0}};
    host_req_sgpr_size_total_r = {`SGPR_ID_WIDTH{1'd0}};
    host_req_lds_size_total_r  = {`LDS_ID_WIDTH{1'd0}};
    host_req_gds_size_total_r  = {`GDS_ID_WIDTH{1'd0}};
    host_req_vgpr_size_per_wf_r= {`VGPR_ID_WIDTH{1'd0}};
    host_req_sgpr_size_per_wf_r= {`SGPR_ID_WIDTH{1'd0}};
    host_req_gds_baseaddr_r    = {`MEM_ADDR_WIDTH{1'd0}};
    host_rsp_ready_r           = {1{1'd0}};
  end

  parameter META_FNAME_SIZE = 128;
  parameter METADATA_SIZE   = 500;

  parameter DATA_FNAME_SIZE = 128;
  parameter DATADATA_SIZE   = 500;
  
  reg [31:0] metadata [METADATA_SIZE-1:0];
  reg [31:0] parsed_base_r  [0:10-1];
  reg [31:0] parsed_size_r  [0:10-1];

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
      $display("Begin test:");
      $display("metadata is %s:", fn_metadata);
      $display("data is %s:", fn_data);
      $display("");
      @(posedge clk);
      noused           <= {metadata[ 1], metadata[ 0]};
      kernel_id        <= {metadata[ 3], metadata[ 2]}; 
      kernal_size0     <= {metadata[ 5], metadata[ 4]}; 
      kernal_size1     <= {metadata[ 7], metadata[ 6]}; 
      kernal_size2     <= {metadata[ 9], metadata[ 8]}; 
      wf_size          <= {metadata[11], metadata[10]}; 
      wg_size          <= {metadata[13], metadata[12]}; 
      metaDataBaseAddr <= {metadata[15], metadata[14]}; 
      ldsSize          <= {metadata[17], metadata[16]}; 
      pdsSize          <= {metadata[19], metadata[18]}; 
      sgprUsage        <= {metadata[21], metadata[20]}; 
      vgprUsage        <= {metadata[23], metadata[22]}; 
      pdsBaseAddr      <= {metadata[25], metadata[24]}; 
      num_buffer       <= {metadata[27], metadata[26]}; 
      pds_size         <= 32'd0;
      @(posedge clk);
      host_req_wg_id_r           <= {`WG_ID_WIDTH{1'd0}};
      host_req_num_wf_r          <= wg_size[31:0];
      host_req_wf_size_r         <= wf_size[31:0];
      host_req_start_pc_r        <= 32'h8000_0000;
      host_req_kernel_size_3d_r  <= {`WG_SIZE_X_WIDTH{1'd0}};
      host_req_pds_baseaddr_r    <= pdsBaseAddr[31:0]+block_id*pds_size*wf_size[31:0]*wg_size[31:0];
      host_req_csr_knl_r         <= metaDataBaseAddr[31:0];
      host_req_vgpr_size_total_r <= wg_size[31:0]*vgprUsage[31:0];
      host_req_sgpr_size_total_r <= wg_size[31:0]*sgprUsage[31:0];
      host_req_lds_size_total_r  <= 128;
      host_req_gds_size_total_r  <= 0;
      host_req_vgpr_size_per_wf_r<= vgprUsage[31:0];
      host_req_sgpr_size_per_wf_r<= sgprUsage[31:0];
      host_req_gds_baseaddr_r    <= 0;
      repeat(1) @(posedge clk);
      @(posedge clk);
      host_req_valid_r           <= 1'b1;
      @(posedge clk)
      host_req_valid_r           <= 1'b0;
      //@(negedge host_req_ready_o) 
      @(negedge /*host_req_ready_o*/test_gpu_top.gpu_test.cta.cta2host_rcvd_ack_o) 
      $display("");
      $display("*********");
      $display("metadata is %s:", fn_metadata);
      $display("data is %s:", fn_data);
      $display("Config finish!");
      $display("");
    end
  endtask

  task exe_finish;
    input [META_FNAME_SIZE*8-1:0] fn_metadata;
    input [DATA_FNAME_SIZE*8-1:0] fn_data;
    integer i;
    begin
      i = 0;
      host_rsp_ready_r           <= 1'b1;
      while(i == 0) begin
        @(posedge clk);
        //if(test_gpu_top.gpu_test.B1[0].l2cache.SourceD_finish_issue_o)
        if(test_gpu_top.host_rsp_valid_o)
          i = 1;
      end
      $display("");
      $display("metadata is %s:", fn_metadata);
      $display("data is %s:", fn_data);
      $display("exe finish!");
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

