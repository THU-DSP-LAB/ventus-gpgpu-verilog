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

module axi4lite_2_cta #(
  parameter AXILITE_ADDR_WIDTH   = 32,
  parameter AXILITE_DATA_WIDTH   = 32,
  parameter AXILITE_PROT_WIDTH   = 3 ,
  parameter AXILITE_RESP_WIDTH   = 2 ,  
  parameter AXILITE_STRB_WIDTH   = 4  
  )
  (
  input                           clk                                             ,
  input                           rst_n                                           ,

  //cta to axi
  output                          host_rsp_ready_o                                ,
  input                           host_rsp_valid_i                                ,
  input  [`WG_ID_WIDTH-1:0]       host_rsp_inflight_wg_buffer_host_wf_done_wg_id_i,

  //axi to cta
  input                           host_req_ready_i                                ,
  output                          host_req_valid_o                                ,
  output [`WG_ID_WIDTH-1:0]       host_req_wg_id_o                                ,
  output [`WF_COUNT_WIDTH-1:0]    host_req_num_wf_o                               ,
  output [`WAVE_ITEM_WIDTH-1:0]   host_req_wf_size_o                              ,
  output [`MEM_ADDR_WIDTH-1:0]    host_req_start_pc_o                             ,
  output [`WG_SIZE_X_WIDTH*3-1:0] host_req_kernel_size_3d_o                       ,
  output [`MEM_ADDR_WIDTH-1:0]    host_req_pds_baseaddr_o                         ,
  output [`MEM_ADDR_WIDTH-1:0]    host_req_csr_knl_o                              ,
  output [`VGPR_ID_WIDTH:0]       host_req_vgpr_size_total_o                      ,
  output [`SGPR_ID_WIDTH:0]       host_req_sgpr_size_total_o                      ,
  output [`LDS_ID_WIDTH:0]        host_req_lds_size_total_o                       ,
  output [`GDS_ID_WIDTH:0]        host_req_gds_size_total_o                       ,
  output [`VGPR_ID_WIDTH:0]       host_req_vgpr_size_per_wf_o                     ,
  output [`SGPR_ID_WIDTH:0]       host_req_sgpr_size_per_wf_o                     ,
  output [`MEM_ADDR_WIDTH-1:0]    host_req_gds_baseaddr_o                         ,

  output                          s_axilite_awready_o                             ,
  input                           s_axilite_awvalid_i                             ,
  input  [AXILITE_ADDR_WIDTH-1:0] s_axilite_awaddr_i                              ,
  input  [AXILITE_PROT_WIDTH-1:0] s_axilite_awprot_i                              ,

  output                          s_axilite_wready_o                              ,
  input                           s_axilite_wvalid_i                              ,
  input  [AXILITE_DATA_WIDTH-1:0] s_axilite_wdata_i                               ,
  input  [AXILITE_STRB_WIDTH-1:0] s_axilite_wstrb_i                               ,

  input                           s_axilite_bready_i                              ,
  output                          s_axilite_bvalid_o                              ,
  output [AXILITE_RESP_WIDTH-1:0] s_axilite_bresp_o                               ,

  output                          s_axilite_arready_o                             ,
  input                           s_axilite_arvalid_i                             ,
  input  [AXILITE_ADDR_WIDTH-1:0] s_axilite_araddr_i                              ,
  input  [AXILITE_PROT_WIDTH-1:0] s_axilite_arprot_i                              ,

  input                           s_axilite_rready_i                              ,
  output [AXILITE_DATA_WIDTH-1:0] s_axilite_rdata_o                               ,
  output [AXILITE_RESP_WIDTH-1:0] s_axilite_rresp_o                               ,
  output                          s_axilite_rvalid_o                               
  );
  
  localparam NUM_REG = 18;

  localparam IDLE      = 5'b00000,
             READADDR  = 5'b00001,
             READDATA  = 5'b00010,
             WRITEADDR = 5'b00100,
             WRITEDATA = 5'b01000,
             WRITERESP = 5'b10000;

  localparam OUT_IDLE  = 1'b0,
             OUT_OUTPUT= 1'b1;

  reg [NUM_REG*AXILITE_DATA_WIDTH-1:0] data_buf;
  reg [AXILITE_DATA_WIDTH-1:0] data_out;

  reg awready,wready,bvalid,arready,rvalid;

  reg [AXILITE_ADDR_WIDTH-1:0] addr;
  reg write;
  wire [AXILITE_DATA_WIDTH-1:0] rdata;
  reg [AXILITE_DATA_WIDTH-1:0] rdata_reg;

  reg s_axilite_rready_r,rvalid_r;

  reg [4:0] state;
  reg out_state;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      out_state <= OUT_IDLE;
    end 
    else begin
      case(out_state)
        OUT_IDLE   : if(data_buf[0]) begin
                       out_state <= OUT_OUTPUT;
                     end 
                     else begin
                       out_state <= out_state;
                     end 
        OUT_OUTPUT : if(host_req_valid_o && host_req_ready_i) begin
                       out_state <= OUT_IDLE;
                     end 
                     else begin
                       out_state <= out_state;
                     end 
        default    : out_state <= out_state; 
      endcase
    end 
  end 

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      state <= IDLE;
      arready <= 1'b0;
      rvalid <= 1'b0;
      awready <= 1'b0;
      write <= 1'b0;
      wready <= 1'b0;
      bvalid <= 1'b0;
      addr <= 'b0;
      data_out <= 'b0;
    end 
    else begin
      case(state)
        IDLE      : begin
                      rvalid <= 1'b0;
                      bvalid <= 1'b0;
                      write <= 1'b0;
                      if(s_axilite_awvalid_i && (out_state == OUT_IDLE)) begin
                        state <= WRITEADDR;
                      end
                      else if(s_axilite_arvalid_i) begin
                        state <= READADDR;
                      end 
                      else begin
                        state <= IDLE;
                      end 
                    end
        READADDR  : begin
                      if(s_axilite_arvalid_i && s_axilite_arready_o/*arready*/) begin
                        state <= READDATA;
                        arready <= 1'b0;
                        addr <= s_axilite_araddr_i[AXILITE_ADDR_WIDTH-1:2];
                      end
                      else begin
                        state <= READADDR;
                        arready <= 1'b1;
                        addr <= addr;
                      end 
                    end
        READDATA  : begin
                      if(s_axilite_rready_i && s_axilite_rvalid_o) begin
                        state <= IDLE;
                        rvalid <= 1'b0;
                      end 
                      else begin
                        state <= READDATA;
                        rvalid <= 1'b1;
                      end 
                    end
        WRITEADDR : begin
                      if(s_axilite_awvalid_i && s_axilite_awready_o/*awready*/) begin
                        state <= WRITEDATA;
                        awready <= 1'b0;
                        addr <= s_axilite_awaddr_i[AXILITE_ADDR_WIDTH-1:2];
                      end
                      else begin
                        state <= WRITEADDR;
                        awready <= 1'b1;
                        addr <= addr;
                      end 
                    end
        WRITEDATA : begin
                      if(s_axilite_wvalid_i && s_axilite_wready_o/*wready*/) begin
                        state <= WRITERESP;
                        data_out <= s_axilite_wdata_i;
                        write <= 1'b1;
                        wready <= 1'b0;
                      end
                      else begin
                        state <= WRITEDATA;
                        data_out <= data_out;
                        write <= write;
                        wready <= 1'b1;
                      end 
                    end
        WRITERESP : begin
                      if(s_axilite_bready_i && s_axilite_bvalid_o/*bvalid*/) begin
                        state <= IDLE;
                        write <= 1'b0;
                        bvalid <= 1'b0;
                      end 
                      else begin
                        state <= WRITERESP;
                        write <= 1'b0;
                        bvalid <= 1'b1;
                      end
                    end
        default   : begin
                      state <= IDLE;
                    end 
      endcase
    end 
  end 

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      s_axilite_rready_r <= 1'b0;
      rvalid_r <= 1'b0;
    end 
    else begin
      s_axilite_rready_r <= s_axilite_rready_i;
      rvalid_r <= rvalid;
    end 
  end 

  assign host_rsp_ready_o = host_rsp_valid_i && (data_buf[17*AXILITE_DATA_WIDTH]==1'd0);

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      rdata_reg <= 'h0;
    end 
    else begin
      rdata_reg <= rdata;
    end 
  end 

  assign rdata = (s_axilite_rready_r || (!rvalid_r)) ? data_buf[((addr+1)*AXILITE_DATA_WIDTH-1)-:AXILITE_DATA_WIDTH] : rdata_reg;

  assign s_axilite_rdata_o = rdata;
  assign s_axilite_awready_o = awready;
  assign s_axilite_wready_o = wready;
  assign s_axilite_bvalid_o = bvalid;
  assign s_axilite_bresp_o = 2'b0;
  assign s_axilite_arready_o = arready;
  assign s_axilite_rvalid_o = rvalid;
  assign s_axilite_rresp_o = 2'b0;

  assign host_req_valid_o = data_buf[0] && (out_state == OUT_OUTPUT);
  assign host_req_wg_id_o = data_buf[(1+1)*AXILITE_DATA_WIDTH-1 -: AXILITE_DATA_WIDTH];           
  assign host_req_num_wf_o = data_buf[(2+1)*AXILITE_DATA_WIDTH-1 -: AXILITE_DATA_WIDTH];         
  assign host_req_wf_size_o = data_buf[(3+1)*AXILITE_DATA_WIDTH-1 -: AXILITE_DATA_WIDTH];        
  assign host_req_start_pc_o = data_buf[(4+1)*AXILITE_DATA_WIDTH-1 -: AXILITE_DATA_WIDTH];       
  assign host_req_vgpr_size_total_o = data_buf[(5+1)*AXILITE_DATA_WIDTH-1 -: AXILITE_DATA_WIDTH]; 
  assign host_req_sgpr_size_total_o = data_buf[(6+1)*AXILITE_DATA_WIDTH-1 -: AXILITE_DATA_WIDTH];   
  assign host_req_lds_size_total_o = data_buf[(7+1)*AXILITE_DATA_WIDTH-1 -: AXILITE_DATA_WIDTH];        
  assign host_req_gds_size_total_o = 'b0;
  assign host_req_vgpr_size_per_wf_o = data_buf[(8+1)*AXILITE_DATA_WIDTH-1 -: AXILITE_DATA_WIDTH];
  assign host_req_sgpr_size_per_wf_o = data_buf[(9+1)*AXILITE_DATA_WIDTH-1 -: AXILITE_DATA_WIDTH]; 
  assign host_req_gds_baseaddr_o = data_buf[(10+1)*AXILITE_DATA_WIDTH-1 -: AXILITE_DATA_WIDTH]; 
  assign host_req_pds_baseaddr_o = data_buf[(11+1)*AXILITE_DATA_WIDTH-1 -: AXILITE_DATA_WIDTH];
  assign host_req_csr_knl_o = data_buf[(12+1)*AXILITE_DATA_WIDTH-1 -: AXILITE_DATA_WIDTH]; 
  assign host_req_kernel_size_3d_o[(`WG_SIZE_X_WIDTH*(0+1)-1)-:`WG_SIZE_X_WIDTH] = data_buf[(13+1)*AXILITE_DATA_WIDTH-1 -: AXILITE_DATA_WIDTH];   
  assign host_req_kernel_size_3d_o[(`WG_SIZE_X_WIDTH*(1+1)-1)-:`WG_SIZE_X_WIDTH] = data_buf[(14+1)*AXILITE_DATA_WIDTH-1 -: AXILITE_DATA_WIDTH];   
  assign host_req_kernel_size_3d_o[(`WG_SIZE_X_WIDTH*(2+1)-1)-:`WG_SIZE_X_WIDTH] = data_buf[(15+1)*AXILITE_DATA_WIDTH-1 -: AXILITE_DATA_WIDTH];   

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      data_buf <= 'b0;
    end 
    else if(host_rsp_valid_i && (!data_buf[17*AXILITE_DATA_WIDTH])) begin
      data_buf[(17+1)*AXILITE_DATA_WIDTH-1 -: AXILITE_DATA_WIDTH] <= 'b1;
      data_buf[(16+1)*AXILITE_DATA_WIDTH-1 -: AXILITE_DATA_WIDTH] <= host_rsp_inflight_wg_buffer_host_wf_done_wg_id_i;
    end
    else if((state==READDATA)&&(addr==17)&&data_buf[17*AXILITE_DATA_WIDTH]&&(rvalid==1'd1)) begin
      data_buf[(17+1)*AXILITE_DATA_WIDTH-1 -: AXILITE_DATA_WIDTH] <= 'b0;
    end 
    else if((out_state == OUT_OUTPUT) && host_req_ready_i && host_req_valid_o) begin
      data_buf[(0+1)*AXILITE_DATA_WIDTH-1 -: AXILITE_DATA_WIDTH] <= 'b0;
    end 
    else if(write) begin
      data_buf[(addr+1)*AXILITE_DATA_WIDTH-1 -: AXILITE_DATA_WIDTH] <= data_out;
    end 
    else begin
      data_buf <= data_buf;
    end 
  end 

endmodule
