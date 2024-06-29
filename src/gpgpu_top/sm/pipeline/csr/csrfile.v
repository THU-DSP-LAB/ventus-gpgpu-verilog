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

module  csrfile(
  input                           clk                             ,
  input                           rst_n                           ,

  //control signal
  input   [31:0]                  ctrl_inst_i                     ,
  input   [1:0]                   ctrl_csr_i                      ,
  input                           ctrl_custom_signal_0_i          ,
  input                           ctrl_isvec_i                    ,

  input   [`XLEN-1:0]             in1_i                           ,
  input                           write_i                         ,

  //CTA2csr
  input                           CTA2csr_valid_i                 ,
  input   [`WF_COUNT_WIDTH-1:0]   dispatch2cu_wg_wf_count_i       ,
  input   [`WAVE_ITEM_WIDTH-1:0]  dispatch2cu_wf_size_dispatch_i  ,
  input   [`SGPR_ID_WIDTH:0]      dispatch2cu_sgpr_base_dispatch_i,
  input   [`VGPR_ID_WIDTH:0]      dispatch2cu_vgpr_base_dispatch_i,
  input   [`TAG_WIDTH-1:0]        dispatch2cu_wf_tag_dispatch_i   ,
  input   [`LDS_ID_WIDTH:0]       dispatch2cu_lds_base_dispatch_i ,
  //input   [`MEM_ADDR_WIDTH-1:0]   dispatch2cu_start_pc_dispatch_i ,
  input   [`MEM_ADDR_WIDTH-1:0]   dispatch2cu_pds_base_dispatch_i ,
  //input   [`MEM_ADDR_WIDTH-1:0]   dispatch2cu_gds_base_dispatch_i ,
  input   [`MEM_ADDR_WIDTH-1:0]   dispatch2cu_csr_knl_dispatch_i  ,
  input   [`WG_SIZE_X_WIDTH-1:0]  dispatch2cu_wgid_x_dispatch_i   ,
  input   [`WG_SIZE_Y_WIDTH-1:0]  dispatch2cu_wgid_y_dispatch_i   ,
  input   [`WG_SIZE_Z_WIDTH-1:0]  dispatch2cu_wgid_z_dispatch_i   ,
  input   [31:0]                  dispatch2cu_wg_id_i             ,
  //input   [`DEPTH_WARP-1:0]       wid_i                           ,

  output  [`XLEN-1:0]             wb_wxd_rd_o                     ,
  output  [2:0]                   frm_o                           ,
  output  [`SGPR_ID_WIDTH:0]      sgpr_base_o                     ,
  output  [`VGPR_ID_WIDTH:0]      vgpr_base_o                     ,
  output  [`XLEN-1:0]             simt_rpc_o                      ,
  output  [`XLEN-1:0]             lsu_tid_o                       ,
  output  [`XLEN-1:0]             lsu_pds_o                       ,
  output  [`XLEN-1:0]             lsu_numw_o                      
  );
  // Machine Trap-Vector Base-Address Register (mtvec)
  reg [`XLEN-1:0] mtvec;
  // Machine Interrupt Registers (mip and mie)
  reg             mtip;// timer interrupt-pending bits
  reg             stip;
  reg             utip;
  reg             mtie;// timer interrupt-enable bits
  reg             stie;
  reg             utie;
  reg             msip;// software interrupt-pending bits
  reg             ssip;
  reg             usip;
  reg             msie;// software interrupt-enable bits
  reg             ssie;
  reg             usie;
  reg             meip;// external interrupt-pending bits
  reg             seip;
  reg             ueip;
  reg             meie;// external interrupt-enable bits
  reg             seie;
  reg             ueie;
  reg [`XLEN-1:0] mip;
  reg [`XLEN-1:0] mie;

  
  reg             mie_bit;// interrupt-enable bit
  reg             sie;
  reg             uie;
  reg             mpie;// to support nested tarps
  reg             spie;
  reg             upie;
  reg [1:0]       mpp;
  reg             spp;
  reg             mprv;// memory privilege
  reg             mxr;
  reg             sum;
  reg             tvm;
  reg             tw;
  reg             tsr;
  reg [1:0]       fs;// extension context status
  reg [1:0]       xs;
  reg             sd;//   state dirty
  reg [`XLEN-1:0] mstatus;

  // Machine Scratch Register (mscratch)
  reg [`XLEN-1:0] mscratch;

  // Machine Exception Program Counter (mepc)
  reg [`XLEN-1:0] mepc;

  // Machine Cause Register (mcause)
  reg [`XLEN-1:0] mcause;

  // Machine Trap Value Register (mtval)
  reg [`XLEN-1:0] mtval;

  // thread message register
  reg [`XLEN-1:0]             threadid;
  reg [`WF_COUNT_WIDTH-1:0]   wg_wf_count;
  reg [`WAVE_ITEM_WIDTH-1:0]  wf_size_dispatch;
  reg [`MEM_ADDR_WIDTH-1:0]   knl_base;
  reg [31:0]                  wg_id;
  reg [`TAG_WIDTH-1:0]        wf_tag_dispatch;
  reg [`MEM_ADDR_WIDTH-1:0]   lds_base_dispatch;
  reg [`MEM_ADDR_WIDTH-1:0]   pds_baseaddr;
  reg [`WG_SIZE_X_WIDTH-1:0]  wg_id_x;
  reg [`WG_SIZE_Y_WIDTH-1:0]  wg_id_y;
  reg [`WG_SIZE_Z_WIDTH-1:0]  wg_id_z;
  reg [31:0]                  csr_print;
  reg [31:0]                  rpc;
  reg [`SGPR_ID_WIDTH:0]      sgpr_base_dispatch;
  reg [`VGPR_ID_WIDTH:0]      vgpr_base_dispatch;
  wire [31:0]                 lds_base_dispatch_h;

  // float csr address
  reg             nv;
  reg             dz;
  reg             of;
  reg             uf;
  reg             nx;
  reg [4:0]       fflags;
  reg [2:0]       frm;
  reg [`XLEN-1:0] fcsr;

  // Vector csr address
  reg                         vill;
  reg                         vma;
  reg                         vta;//undisturbed
  reg [2:0]                   vsew;//only support e32
  reg [2:0]                   vlmul;//only support LMUL=1
  reg [`XLEN-1:0]             vlmax;
  //reg [`XLEN-1:0]             vstart;
  //reg                         vxsat;//fix-point accrued saturation flag
  //reg [1:0]                   vxrm;//fix point rounding mode
  //reg [`XLEN-1:0]             vcsr;
  //reg [`XLEN-1:0]             vl;
  reg [`XLEN-1:0]             vtype;
  //reg [`XLEN-1:0]             vlenb;

  wire  [11:0]                csr_addr;
  wire  [`XLEN-1:0]           csr_input;
  wire                        wen;
  wire  [`XLEN-1:0]           wdata;
  reg   [`XLEN-1:0]           csr_rdata;
  reg   [`XLEN-1:0]           csr_wdata;

  assign csr_addr = ctrl_inst_i[31:20];
  assign csr_input = in1_i;
  assign wdata = (wen & ctrl_custom_signal_0_i) ? csr_input : 
                 ((wen & ctrl_isvec_i) ? ((csr_input < vlmax) ? csr_input : vlmax) : csr_rdata);
  assign wen = (|ctrl_csr_i) & write_i;
  assign lds_base_dispatch_h = 32'h70000000;
  
  always@(*) begin
    case(ctrl_csr_i)
      2'b01   : csr_wdata = csr_input;
      2'b10   : csr_wdata = csr_rdata | csr_input;
      2'b11   : csr_wdata = csr_rdata & (~csr_input);
      default : csr_wdata = 'd0;
    endcase
  end

  always@(*) begin
    case(csr_addr)
      `CSR_MSTATUS            : csr_rdata = mstatus;
      `CSR_MIE                : csr_rdata = mie;
      `CSR_MTVEC              : csr_rdata = mtvec;
      `CSR_MSCRATCH           : csr_rdata = mscratch;
      `CSR_MEPC               : csr_rdata = mepc;
      `CSR_MCAUSE             : csr_rdata = mcause;
      `CSR_MTVAL              : csr_rdata = mtval;
      `CSR_MIP                : csr_rdata = mip;
      `CSR_FRM                : csr_rdata = frm;
      `CSR_FCSR               : csr_rdata = fcsr;
      `CSR_FFLAGS             : csr_rdata = fflags;
      `CSR_VTYPE              : csr_rdata = vtype;
      `CSR_THREADID           : csr_rdata = threadid;
      `CSR_WG_WF_COUNT        : csr_rdata = wg_wf_count;
      `CSR_WF_SIZE_DISPATCH   : csr_rdata = wf_size_dispatch;
      `CSR_KNL_BASE           : csr_rdata = knl_base;
      `CSR_WG_ID              : csr_rdata = wg_id;
      `CSR_WF_TAG_DISPATCH    : csr_rdata = wf_tag_dispatch;
      `CSR_LDS_BASE_DISPATCH  : csr_rdata = lds_base_dispatch;
      `CSR_PDS_BASEADDR       : csr_rdata = pds_baseaddr;
      `CSR_WG_ID_X            : csr_rdata = wg_id_x;
      `CSR_WG_ID_Y            : csr_rdata = wg_id_y;
      `CSR_WG_ID_Z            : csr_rdata = wg_id_z;
      `CSR_PRINT              : csr_rdata = csr_print;
      `CSR_RPC                : csr_rdata = rpc;
      default                 : csr_rdata = 'd0;
    endcase
  end

  //output
  assign wb_wxd_rd_o  = wdata;
  assign simt_rpc_o   = rpc;
  assign sgpr_base_o  = sgpr_base_dispatch;
  assign vgpr_base_o  = vgpr_base_dispatch;
  assign frm_o        = frm;
  assign lsu_tid_o    = wf_tag_dispatch * `NUM_THREAD;
  assign lsu_pds_o    = pds_baseaddr;
  assign lsu_numw_o   = wg_wf_count;

  //rpc,csr_print
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      rpc       <= 'd0;
      csr_print <= 'd0;
    end
    else if(wen & ctrl_custom_signal_0_i) begin
      rpc       <= csr_input;
    end
    else if(wen & csr_addr == `CSR_PRINT) begin
      csr_print <= csr_wdata;
    end
    else begin
      rpc       <= rpc;
      csr_print <= csr_print;
    end
  end
  
  //mie and mip 
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      mtip <= 'd0;
      stip <= 'd0;
      utip <= 'd0;
      mtie <= 'd0;
      stie <= 'd0;
      utie <= 'd0;
      msip <= 'd0;
      ssip <= 'd0;
      usip <= 'd0;
      msie <= 'd0;
      ssie <= 'd0;
      usie <= 'd0;
      meip <= 'd0;
      seip <= 'd0;
      ueip <= 'd0;
      meie <= 'd0;
      seie <= 'd0;
      ueie <= 'd0;
    end
    else if(wen & csr_addr == `CSR_MIP) begin
      mtip <= csr_wdata[7];
      stip <= 'd0;
      utip <= 'd0;
      msip <= csr_wdata[3];
      ssip <= 'd0;
      usip <= 'd0;
      meip <= csr_wdata[11];
      seip <= 'd0;
      ueip <= 'd0;
    end
    else if(wen & csr_addr == `CSR_MIE) begin
      mtie <= csr_wdata[7];
      stie <= 'd0;
      utie <= 'd0;
      msie <= csr_wdata[3];
      ssie <= 'd0;
      usie <= 'd0;
      meie <= csr_wdata[11];
      seie <= 'd0;
      ueie <= 'd0;
    end
    else begin
      mtip <= mtip;
      stip <= stip;
      utip <= utip;
      mtie <= mtie;
      stie <= stie;
      utie <= utie;
      msip <= msip;
      ssip <= ssip;
      usip <= usip;
      msie <= msie;
      ssie <= ssie;
      usie <= usie;
      meip <= meip;
      seip <= seip;
      ueip <= ueip;
      meie <= meie;
      seie <= seie;
      ueie <= ueie;
    end
  end

  always @(*) begin
      mip  = {{(`XLEN-12){1'b0}},meip,1'b0,seip,ueip,mtip,1'b0,stip,utip,msip,1'b0,ssip,usip};
      mie  = {{(`XLEN-12){1'b0}},meie,1'b0,seie,ueie,mtie,1'b0,stie,utie,msie,1'b0,ssie,usie};
  end

  //mstatus
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      mie_bit  <= 'd0;
      sie  <= 'd0;
      uie  <= 'd0;
      mpie <= 'd0;
      spie <= 'd0;
      upie <= 'd0;
      mpp  <= 'd0;
      spp  <= 'd0;
      mprv <= 'd0;
      mxr  <= 'd0;
      sum  <= 'd0;
      tvm  <= 'd0;
      tw   <= 'd0;
      tsr  <= 'd0;
      fs   <= 'd0;
      xs   <= 'd0;
      sd   <= 'd0;
    end
    else if(wen & csr_addr == `CSR_MSTATUS) begin
      mie_bit <= csr_wdata[3];
      mpie    <= csr_wdata[7];
      mpp     <= 2'd3;
    end
    else begin
      mie_bit  <= mie_bit;
      sie  <= sie;
      uie  <= uie;
      mpie <= mpie;
      spie <= spie;
      upie <= upie;
      mpp  <= 2'd3;
      spp  <= spp;
      mprv <= mprv;
      mxr  <= mxr;
      sum  <= sum;
      tvm  <= tvm;
      tw   <= tw;
      tsr  <= tsr;
      fs   <= fs;
      xs   <= xs;
      sd   <= sd;
    end
  end

  always @(*) begin
    mstatus = {sd,8'd0,tsr,tw,tvm,mxr,sum,mprv,xs,fs,mpp,2'd0,spp,mpie,1'b0,spie,upie,mie_bit,1'b0,sie,uie};
  end

  //mscratch,mepc,mcause,mtval
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      mscratch <= 'd0;
      mepc     <= 'd0;
      mcause   <= 'd0;
      mtval    <= 'd0;
      mtvec    <= 'd0;
    end
    else if(wen & csr_addr == `CSR_MSCRATCH) begin
      mscratch <= csr_wdata;
    end
    else if(wen & csr_addr == `CSR_MEPC) begin
      mepc     <= csr_wdata;
    end
    else if(wen & csr_addr == `CSR_MCAUSE) begin
      mcause   <= csr_wdata;
    end
    else if(wen & csr_addr == `CSR_MTVAL) begin
      mtval    <= csr_wdata;
    end
    else begin
      mscratch <= mscratch;
      mepc     <= mepc;
      mcause   <= mcause;
      mtval    <= mtval;
      mtvec    <= 'd0;
    end
  end

  //thread message register
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      threadid           <= 'd0;   
      wg_wf_count        <= 'd0;
      wf_size_dispatch   <= 'd0;
      knl_base           <= 'd0;
      wg_id              <= 'd0;
      wf_tag_dispatch    <= 'd0;
      lds_base_dispatch  <= 'd0;
      pds_baseaddr       <= 'd0;
      wg_id_x            <= 'd0;
      wg_id_y            <= 'd0;
      wg_id_z            <= 'd0;
      sgpr_base_dispatch <= 'd0;
      vgpr_base_dispatch <= 'd0;
    end
    else if(CTA2csr_valid_i) begin
      threadid           <= dispatch2cu_wf_tag_dispatch_i[`DEPTH_WARP-1:0]<<`DEPTH_THREAD;
      wg_wf_count        <= dispatch2cu_wg_wf_count_i;
      wf_size_dispatch   <= dispatch2cu_wf_size_dispatch_i;
      knl_base           <= dispatch2cu_csr_knl_dispatch_i;
      wg_id              <= dispatch2cu_wg_id_i;
      wf_tag_dispatch    <= dispatch2cu_wf_tag_dispatch_i[`DEPTH_WARP-1:0];
      lds_base_dispatch  <= {lds_base_dispatch_h[31:`LDS_ID_WIDTH+1],dispatch2cu_lds_base_dispatch_i};
      pds_baseaddr       <= dispatch2cu_pds_base_dispatch_i;
      wg_id_x            <= dispatch2cu_wgid_x_dispatch_i;
      wg_id_y            <= dispatch2cu_wgid_y_dispatch_i;
      wg_id_z            <= dispatch2cu_wgid_z_dispatch_i;
      sgpr_base_dispatch <= dispatch2cu_sgpr_base_dispatch_i;
      vgpr_base_dispatch <= dispatch2cu_vgpr_base_dispatch_i;
    end
    else begin
      threadid           <= threadid;   
      wg_wf_count        <= wg_wf_count;
      wf_size_dispatch   <= wf_size_dispatch;
      knl_base           <= knl_base;
      wg_id              <= wg_id;
      wf_tag_dispatch    <= wf_tag_dispatch;
      lds_base_dispatch  <= lds_base_dispatch;
      pds_baseaddr       <= pds_baseaddr;
      wg_id_x            <= wg_id_x;
      wg_id_y            <= wg_id_y;
      wg_id_z            <= wg_id_z;
      sgpr_base_dispatch <= sgpr_base_dispatch;
      vgpr_base_dispatch <= vgpr_base_dispatch;
    end
  end

  //float csr address
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      nv  <= 'd0;
      dz  <= 'd0;
      of  <= 'd0;
      uf  <= 'd0;
      nx  <= 'd0;
      frm <= 'd0;
    end
    else if(wen & csr_addr == `CSR_FFLAGS) begin
      nv  <= csr_wdata[4];
      dz  <= csr_wdata[3];
      of  <= csr_wdata[2];
      uf  <= csr_wdata[1];
      nx  <= csr_wdata[0];
    end
    else if(wen & csr_addr == `CSR_FRM) begin
      frm <= csr_wdata[2:0];
    end
    else begin
      nv  <= nv;
      dz  <= dz;
      of  <= of;
      uf  <= uf;
      nx  <= nx;
      frm <= frm;
    end
  end

  always @(*) begin
    fflags = {nv,dz,of,uf,nx};
    fcsr   = {24'd0,frm,fflags};
  end

  //Vector csr address
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      vill   <= 'd0;
      vma    <= 'd0;
      vta    <= 'd0;
      vsew   <= 'd0;
      vlmul  <= 'd0;
      vlmax  <= 'd0;
      //vstart <= 'd0;
      //vxsat  <= 'd0;
      //vxrm   <= 'd0;
      //vcsr   <= 'd0;
      //vl     <= 'd0;
      //vlenb  <= 'd0;
    end
    else begin
      vill   <= 'd0;
      vma    <= 'd0;
      vta    <= 'd0;
      vsew   <= 3'd2;
      vlmul  <= 'd0;
      vlmax  <= `NUM_THREAD;
      //vstart <= 'd0;
      //vxsat  <= 'd0;
      //vxrm   <= 'd0;
      //vcsr   <= 'd0;
      //vl     <= 'd0;
      //vlenb  <= 'd0;
    end
  end

  always @(*) begin
    vtype = {vill,23'd0,vma,vta,vsew,vlmul};
  end

endmodule

  
  
      
  

