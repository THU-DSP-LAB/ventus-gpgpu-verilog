`timescale 1ns/10ps

`include "define.v"
`ifdef T28_MEM
`define VGPR_MEM_B0_0 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[0].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_0.MX.mem
`define VGPR_MEM_B0_1 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[0].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_1.MX.mem
`define VGPR_MEM_B0_2 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[0].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_2.MX.mem
`define VGPR_MEM_B0_3 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[0].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_3.MX.mem
`define VGPR_MEM_B0_4 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[0].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_4.MX.mem
`define VGPR_MEM_B0_5 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[0].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_5.MX.mem
`define VGPR_MEM_B0_6 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[0].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_6.MX.mem
`define VGPR_MEM_B0_7 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[0].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_7.MX.mem

`define VGPR_MEM_B1_0 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[1].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_0.MX.mem
`define VGPR_MEM_B1_1 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[1].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_1.MX.mem
`define VGPR_MEM_B1_2 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[1].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_2.MX.mem
`define VGPR_MEM_B1_3 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[1].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_3.MX.mem
`define VGPR_MEM_B1_4 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[1].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_4.MX.mem
`define VGPR_MEM_B1_5 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[1].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_5.MX.mem
`define VGPR_MEM_B1_6 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[1].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_6.MX.mem
`define VGPR_MEM_B1_7 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[1].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_7.MX.mem

`define VGPR_MEM_B2_0 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[2].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_0.MX.mem
`define VGPR_MEM_B2_1 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[2].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_1.MX.mem
`define VGPR_MEM_B2_2 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[2].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_2.MX.mem
`define VGPR_MEM_B2_3 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[2].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_3.MX.mem
`define VGPR_MEM_B2_4 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[2].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_4.MX.mem
`define VGPR_MEM_B2_5 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[2].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_5.MX.mem
`define VGPR_MEM_B2_6 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[2].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_6.MX.mem
`define VGPR_MEM_B2_7 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[2].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_7.MX.mem

`define VGPR_MEM_B3_0 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[3].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_0.MX.mem
`define VGPR_MEM_B3_1 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[3].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_1.MX.mem
`define VGPR_MEM_B3_2 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[3].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_2.MX.mem
`define VGPR_MEM_B3_3 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[3].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_3.MX.mem
`define VGPR_MEM_B3_4 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[3].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_4.MX.mem
`define VGPR_MEM_B3_5 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[3].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_5.MX.mem
`define VGPR_MEM_B3_6 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[3].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_6.MX.mem
`define VGPR_MEM_B3_7 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[3].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_7.MX.mem
                    //test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.regfile_banks[0].U_vector_regfile_bank.U_GPGPU_RF_2P_256X128M_0.MX.mem

`define L1_CORE_RSP_FIFO_0 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.dcache.core_rsp_q.U_GPGPU_RF_2P_16X106M_0.MX.mem
`define L1_CORE_RSP_FIFO_1 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.dcache.core_rsp_q.U_GPGPU_RF_2P_16X106M_1.MX.mem
`define L1_CORE_RSP_FIFO_2 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.dcache.core_rsp_q.U_GPGPU_RF_2P_16X106M_2.MX.mem
`define L1_CORE_RSP_FIFO_3 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.dcache.core_rsp_q.U_GPGPU_RF_2P_16X106M_3.MX.mem
`define L1_CORE_RSP_FIFO_4 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.dcache.core_rsp_q.U_GPGPU_RF_2P_16X106M_4.MX.mem
`define L1_CORE_RSP_FIFO_5 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.dcache.core_rsp_q.U_GPGPU_RF_2P_16X106M_5.MX.mem
`define L1_CORE_RSP_FIFO_6 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.dcache.core_rsp_q.U_GPGPU_RF_2P_16X106M_6.MX.mem
`define L1_CORE_RSP_FIFO_7 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.dcache.core_rsp_q.U_GPGPU_RF_2P_16X106M_7.MX.mem
`define L1_CORE_RSP_FIFO_8 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.dcache.core_rsp_q.U_GPGPU_RF_2P_16X106M_8.MX.mem
`define L1_CORE_RSP_FIFO_9 test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.dcache.core_rsp_q.U_GPGPU_RF_2P_16X106M_9.MX.mem
`endif

module test_gpu_top;
  //GPGPU inputs and outputs
  wire                                  clk                                             ;
  wire                                  rst_n                                           ;

  wire                                  host_req_valid_i                                ;
  wire                                  host_req_ready_o                                ;
  wire [`WG_ID_WIDTH-1:0]               host_req_wg_id_i                                ;
  wire [`WF_COUNT_WIDTH-1:0]            host_req_num_wf_i                               ;
  wire [`WAVE_ITEM_WIDTH-1:0]           host_req_wf_size_i                              ;
  wire [`MEM_ADDR_WIDTH-1:0]            host_req_start_pc_i                             ;
  wire [`WG_SIZE_X_WIDTH*3-1:0]         host_req_kernel_size_3d_i                       ;
  wire [`MEM_ADDR_WIDTH-1:0]            host_req_pds_baseaddr_i                         ;
  wire [`MEM_ADDR_WIDTH-1:0]            host_req_csr_knl_i                              ;
  wire [`VGPR_ID_WIDTH:0]               host_req_vgpr_size_total_i                      ;
  wire [`SGPR_ID_WIDTH:0]               host_req_sgpr_size_total_i                      ;
  wire [`LDS_ID_WIDTH:0]                host_req_lds_size_total_i                       ;
  wire [`GDS_ID_WIDTH:0]                host_req_gds_size_total_i                       ;
  wire [`VGPR_ID_WIDTH:0]               host_req_vgpr_size_per_wf_i                     ;
  wire [`SGPR_ID_WIDTH:0]               host_req_sgpr_size_per_wf_i                     ;
  wire [`MEM_ADDR_WIDTH-1:0]            host_req_gds_baseaddr_i                         ;

  wire                                  host_rsp_valid_o                                ;
  wire                                  host_rsp_ready_i                                ;
  wire [`WG_ID_WIDTH-1:0]               host_rsp_inflight_wg_buffer_host_wf_done_wg_id_o;

  wire [`NUM_L2CACHE-1:0]               out_a_valid_o                                   ;
  wire [`NUM_L2CACHE-1:0]               out_a_ready_i                                   ;
  wire [`NUM_L2CACHE*`OP_BITS-1:0]      out_a_opcode_o                                  ;
  wire [`NUM_L2CACHE*`SIZE_BITS-1:0]    out_a_size_o                                    ;
  wire [`NUM_L2CACHE*`SOURCE_BITS-1:0]  out_a_source_o                                  ;
  wire [`NUM_L2CACHE*`ADDRESS_BITS-1:0] out_a_address_o                                 ;
  wire [`NUM_L2CACHE*`MASK_BITS-1:0]    out_a_mask_o                                    ;
  wire [`NUM_L2CACHE*`DATA_BITS-1:0]    out_a_data_o                                    ;
  wire [`NUM_L2CACHE*3-1:0]             out_a_param_o                                   ;

  wire [`NUM_L2CACHE-1:0]               out_d_valid_i                                   ;
  wire [`NUM_L2CACHE-1:0]               out_d_ready_o                                   ;
  wire [`NUM_L2CACHE*`OP_BITS-1:0]      out_d_opcode_i                                  ;
  wire [`NUM_L2CACHE*`SIZE_BITS-1:0]    out_d_size_i                                    ;
  wire [`NUM_L2CACHE*`SOURCE_BITS-1:0]  out_d_source_i                                  ;
  wire [`NUM_L2CACHE*`DATA_BITS-1:0]    out_d_data_i                                    ;
  wire [`NUM_L2CACHE*3-1:0]             out_d_param_i                                   ;

  GPGPU_top gpu_test(
    .clk                                              (clk                                             ),
    .rst_n                                            (rst_n                                           ),
    .host_req_valid_i                                 (host_req_valid_i                                ),
    .host_req_ready_o                                 (host_req_ready_o                                ),
    .host_req_wg_id_i                                 (host_req_wg_id_i                                ),
    .host_req_num_wf_i                                (host_req_num_wf_i                               ),
    .host_req_wf_size_i                               (host_req_wf_size_i                              ),
    .host_req_start_pc_i                              (host_req_start_pc_i                             ),
    .host_req_kernel_size_3d_i                        (host_req_kernel_size_3d_i                       ),
    .host_req_pds_baseaddr_i                          (host_req_pds_baseaddr_i                         ),
    .host_req_csr_knl_i                               (host_req_csr_knl_i                              ),
    .host_req_vgpr_size_total_i                       (host_req_vgpr_size_total_i                      ),
    .host_req_sgpr_size_total_i                       (host_req_sgpr_size_total_i                      ),
    .host_req_lds_size_total_i                        (host_req_lds_size_total_i                       ),
    .host_req_gds_size_total_i                        (host_req_gds_size_total_i                       ),
    .host_req_vgpr_size_per_wf_i                      (host_req_vgpr_size_per_wf_i                     ),
    .host_req_sgpr_size_per_wf_i                      (host_req_sgpr_size_per_wf_i                     ),
    .host_req_gds_baseaddr_i                          (host_req_gds_baseaddr_i                         ),
    .host_rsp_valid_o                                 (host_rsp_valid_o                                ),
    .host_rsp_ready_i                                 (host_rsp_ready_i                                ),
    .host_rsp_inflight_wg_buffer_host_wf_done_wg_id_o (host_rsp_inflight_wg_buffer_host_wf_done_wg_id_o),
    .out_a_valid_o                                    (out_a_valid_o                                   ),
    .out_a_ready_i                                    (out_a_ready_i                                   ),
    .out_a_opcode_o                                   (out_a_opcode_o                                  ),
    .out_a_size_o                                     (out_a_size_o                                    ),
    .out_a_source_o                                   (out_a_source_o                                  ),
    .out_a_address_o                                  (out_a_address_o                                 ),
    .out_a_mask_o                                     (out_a_mask_o                                    ),
    .out_a_data_o                                     (out_a_data_o                                    ),
    .out_a_param_o                                    (out_a_param_o                                   ),
    .out_d_valid_i                                    (out_d_valid_i                                   ),
    .out_d_ready_o                                    (out_d_ready_o                                   ),
    .out_d_opcode_i                                   (out_d_opcode_i                                  ),
    .out_d_size_i                                     (out_d_size_i                                    ),
    .out_d_source_i                                   (out_d_source_i                                  ),
    .out_d_data_i                                     (out_d_data_i                                    ),
    .out_d_param_i                                    (out_d_param_i                                   )
  );

  gen_clk u_gen_clk (
    .clk                                              (clk                                             )
  );

  gen_rst u_gen_rst(
    .rst_n                                            (rst_n                                           ),
    .clk                                              (clk                                             )
  );

  host_inter u_host_inter (
    .clk                                              (clk                                             ),
    .rst_n                                            (rst_n                                           ),
    .host_req_valid_i                                 (host_req_valid_i                                ),
    .host_req_ready_o                                 (host_req_ready_o                                ),
    .host_req_wg_id_i                                 (host_req_wg_id_i                                ),
    .host_req_num_wf_i                                (host_req_num_wf_i                               ),
    .host_req_wf_size_i                               (host_req_wf_size_i                              ),
    .host_req_start_pc_i                              (host_req_start_pc_i                             ),
    .host_req_kernel_size_3d_i                        (host_req_kernel_size_3d_i                       ),
    .host_req_pds_baseaddr_i                          (host_req_pds_baseaddr_i                         ),
    .host_req_csr_knl_i                               (host_req_csr_knl_i                              ),
    .host_req_vgpr_size_total_i                       (host_req_vgpr_size_total_i                      ),
    .host_req_sgpr_size_total_i                       (host_req_sgpr_size_total_i                      ),
    .host_req_lds_size_total_i                        (host_req_lds_size_total_i                       ),
    .host_req_gds_size_total_i                        (host_req_gds_size_total_i                       ),
    .host_req_vgpr_size_per_wf_i                      (host_req_vgpr_size_per_wf_i                     ),
    .host_req_sgpr_size_per_wf_i                      (host_req_sgpr_size_per_wf_i                     ),
    .host_req_gds_baseaddr_i                          (host_req_gds_baseaddr_i                         ),
    .host_rsp_valid_o                                 (host_rsp_valid_o                                ),
    .host_rsp_ready_i                                 (host_rsp_ready_i                                ),
    .host_rsp_inflight_wg_buffer_host_wf_done_wg_id_o (host_rsp_inflight_wg_buffer_host_wf_done_wg_id_o)
  );

  mem_inter u_mem_inter(
    .clk                                              (clk                                             ),
    .rstn                                             (rst_n                                           ),
    .out_a_valid_o                                    (out_a_valid_o                                   ),
    .out_a_ready_i                                    (out_a_ready_i                                   ),
    .out_a_opcode_o                                   (out_a_opcode_o                                  ),
    .out_a_size_o                                     (out_a_size_o                                    ),
    .out_a_source_o                                   (out_a_source_o                                  ),
    .out_a_address_o                                  (out_a_address_o                                 ),
    .out_a_mask_o                                     (out_a_mask_o                                    ),
    .out_a_data_o                                     (out_a_data_o                                    ),
    .out_a_param_o                                    (out_a_param_o                                   ),
    .out_d_valid_i                                    (out_d_valid_i                                   ),
    .out_d_ready_o                                    (out_d_ready_o                                   ),
    .out_d_opcode_i                                   (out_d_opcode_i                                  ),
    .out_d_size_i                                     (out_d_size_i                                    ),
    .out_d_source_i                                   (out_d_source_i                                  ),
    .out_d_data_i                                     (out_d_data_i                                    ),
    .out_d_param_i                                    (out_d_param_i                                   )
  );

  tc u_tc();

  //gen_print U_gen_print(
  //  .clk                                              (clk                                             ),
  //  .host_req_valid_i                                 (host_req_valid_i                                )
  //);

  initial begin
    $fsdbDumpfile("test.fsdb")             ;
    $fsdbDumpvars(0,test_gpu_top,"+mda","+all");
  end

`ifdef T28_MEM
  integer mem_count;
  //Memory initial
  initial begin
    for(mem_count=0;mem_count<256;mem_count=mem_count+1) begin
      `VGPR_MEM_B0_0[mem_count] = 0;
      `VGPR_MEM_B0_1[mem_count] = 0;
      `VGPR_MEM_B0_2[mem_count] = 0;
      `VGPR_MEM_B0_3[mem_count] = 0;
      `VGPR_MEM_B0_4[mem_count] = 0;
      `VGPR_MEM_B0_5[mem_count] = 0;
      `VGPR_MEM_B0_6[mem_count] = 0;
      `VGPR_MEM_B0_7[mem_count] = 0;

      `VGPR_MEM_B1_0[mem_count] = 0;
      `VGPR_MEM_B1_1[mem_count] = 0;
      `VGPR_MEM_B1_2[mem_count] = 0;
      `VGPR_MEM_B1_3[mem_count] = 0;
      `VGPR_MEM_B1_4[mem_count] = 0;
      `VGPR_MEM_B1_5[mem_count] = 0;
      `VGPR_MEM_B1_6[mem_count] = 0;
      `VGPR_MEM_B1_7[mem_count] = 0;

      `VGPR_MEM_B2_0[mem_count] = 0;
      `VGPR_MEM_B2_1[mem_count] = 0;
      `VGPR_MEM_B2_2[mem_count] = 0;
      `VGPR_MEM_B2_3[mem_count] = 0;
      `VGPR_MEM_B2_4[mem_count] = 0;
      `VGPR_MEM_B2_5[mem_count] = 0;
      `VGPR_MEM_B2_6[mem_count] = 0;
      `VGPR_MEM_B2_7[mem_count] = 0;

      `VGPR_MEM_B3_0[mem_count] = 0;
      `VGPR_MEM_B3_1[mem_count] = 0;
      `VGPR_MEM_B3_2[mem_count] = 0;
      `VGPR_MEM_B3_3[mem_count] = 0;
      `VGPR_MEM_B3_4[mem_count] = 0;
      `VGPR_MEM_B3_5[mem_count] = 0;
      `VGPR_MEM_B3_6[mem_count] = 0;
      `VGPR_MEM_B3_7[mem_count] = 0;
    end
  end

  integer mem_count_1;
  initial begin
    for(mem_count_1=0;mem_count_1<16;mem_count_1=mem_count_1+1) begin
      `L1_CORE_RSP_FIFO_0[mem_count_1] = 0;
      `L1_CORE_RSP_FIFO_1[mem_count_1] = 0;
      `L1_CORE_RSP_FIFO_2[mem_count_1] = 0;
      `L1_CORE_RSP_FIFO_3[mem_count_1] = 0;
      `L1_CORE_RSP_FIFO_4[mem_count_1] = 0;
      `L1_CORE_RSP_FIFO_5[mem_count_1] = 0;
      `L1_CORE_RSP_FIFO_6[mem_count_1] = 0;
      `L1_CORE_RSP_FIFO_7[mem_count_1] = 0;
      `L1_CORE_RSP_FIFO_8[mem_count_1] = 0;
      `L1_CORE_RSP_FIFO_9[mem_count_1] = 0;
    end
  end
`endif

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

task FALIED;
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
