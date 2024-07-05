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

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * AXI4 RAM
 */
module axi_ram #
  (
  // Width of data bus in bits
  parameter DATA_WIDTH = 64,
  // Width of address bus in bits
  parameter ADDR_WIDTH = 32,
  // Width of wstrb (width of data bus in words)
  parameter STRB_WIDTH = (DATA_WIDTH/8),
  // Width of ID signal
  parameter ID_WIDTH = 4,
  // Extra pipeline register on output
  parameter PIPELINE_OUTPUT = 0,
  //store result from mem
  parameter RESULT_REG_WIDTH = 127
  )
  (
  input  wire                   clk,
  input  wire                   rst,

  input  wire [ID_WIDTH-1:0]    s_axi_awid,
  input  wire [ADDR_WIDTH-1:0]  s_axi_awaddr,
  input  wire [7:0]             s_axi_awlen,
  input  wire [2:0]             s_axi_awsize,
  input  wire [1:0]             s_axi_awburst,
  input  wire                   s_axi_awlock,
  input  wire [3:0]             s_axi_awcache,
  input  wire [2:0]             s_axi_awprot,
  input  wire                   s_axi_awvalid,
  output wire                   s_axi_awready,
  input  wire [DATA_WIDTH-1:0]  s_axi_wdata,
  input  wire [STRB_WIDTH-1:0]  s_axi_wstrb,
  input  wire                   s_axi_wlast,
  input  wire                   s_axi_wvalid,
  output wire                   s_axi_wready,
  output wire [ID_WIDTH-1:0]    s_axi_bid,
  output wire [1:0]             s_axi_bresp,
  output wire                   s_axi_bvalid,
  input  wire                   s_axi_bready,
  input  wire [ID_WIDTH-1:0]    s_axi_arid,
  input  wire [ADDR_WIDTH-1:0]  s_axi_araddr,
  input  wire [7:0]             s_axi_arlen,
  input  wire [2:0]             s_axi_arsize,
  input  wire [1:0]             s_axi_arburst,
  input  wire                   s_axi_arlock,
  input  wire [3:0]             s_axi_arcache,
  input  wire [2:0]             s_axi_arprot,
  input  wire                   s_axi_arvalid,
  output wire                   s_axi_arready,
  output wire [ID_WIDTH-1:0]    s_axi_rid,
  output wire [DATA_WIDTH-1:0]  s_axi_rdata,
  output wire [1:0]             s_axi_rresp,
  output wire                   s_axi_rlast,
  output wire                   s_axi_rvalid,
  input  wire                   s_axi_rready
  );

  parameter VALID_ADDR_WIDTH = ADDR_WIDTH - $clog2(STRB_WIDTH);
  parameter WORD_WIDTH = STRB_WIDTH;
  parameter WORD_SIZE = DATA_WIDTH/WORD_WIDTH;
  
  // bus width assertions
  initial begin
    if (WORD_SIZE * STRB_WIDTH != DATA_WIDTH) begin
        $error("Error: AXI data width not evenly divisble (instance %m)");
        $finish;
    end

    if (2**$clog2(WORD_WIDTH) != WORD_WIDTH) begin
        $error("Error: AXI word width must be even power of two (instance %m)");
        $finish;
    end
  end

  localparam [0:0]
    READ_STATE_IDLE = 1'd0,
    READ_STATE_BURST = 1'd1;

  reg [0:0] read_state_reg = READ_STATE_IDLE, read_state_next;

  localparam [1:0]
    WRITE_STATE_IDLE = 2'd0,
    WRITE_STATE_BURST = 2'd1,
    WRITE_STATE_RESP = 2'd2;

  reg [1:0] write_state_reg = WRITE_STATE_IDLE, write_state_next;

  reg mem_wr_en;
  reg mem_rd_en;

  reg [ID_WIDTH-1:0] read_id_reg = {ID_WIDTH{1'b0}}, read_id_next;
  reg [ADDR_WIDTH-1:0] read_addr_reg = {ADDR_WIDTH{1'b0}}, read_addr_next;
  reg [7:0] read_count_reg = 8'd0, read_count_next;
  reg [2:0] read_size_reg = 3'd0, read_size_next;
  reg [1:0] read_burst_reg = 2'd0, read_burst_next;
  reg [ID_WIDTH-1:0] write_id_reg = {ID_WIDTH{1'b0}}, write_id_next;
  reg [ADDR_WIDTH-1:0] write_addr_reg = {ADDR_WIDTH{1'b0}}, write_addr_next;
  reg [7:0] write_count_reg = 8'd0, write_count_next;
  reg [2:0] write_size_reg = 3'd0, write_size_next;
  reg [1:0] write_burst_reg = 2'd0, write_burst_next;
  
  reg s_axi_awready_reg = 1'b0, s_axi_awready_next;
  reg s_axi_wready_reg = 1'b0, s_axi_wready_next;
  reg [ID_WIDTH-1:0] s_axi_bid_reg = {ID_WIDTH{1'b0}}, s_axi_bid_next;
  reg s_axi_bvalid_reg = 1'b0, s_axi_bvalid_next;
  reg s_axi_arready_reg = 1'b0, s_axi_arready_next;
  reg [ID_WIDTH-1:0] s_axi_rid_reg = {ID_WIDTH{1'b0}}, s_axi_rid_next;
  reg [DATA_WIDTH-1:0] s_axi_rdata_reg = {DATA_WIDTH{1'b0}}, s_axi_rdata_next;
  reg s_axi_rlast_reg = 1'b0, s_axi_rlast_next;
  reg s_axi_rvalid_reg = 1'b0, s_axi_rvalid_next;
  reg [ID_WIDTH-1:0] s_axi_rid_pipe_reg = {ID_WIDTH{1'b0}};
  reg [DATA_WIDTH-1:0] s_axi_rdata_pipe_reg = {DATA_WIDTH{1'b0}};
  reg s_axi_rlast_pipe_reg = 1'b0;
  reg s_axi_rvalid_pipe_reg = 1'b0;

  // (* RAM_STYLE="BLOCK" *)
  reg [DATA_WIDTH-1:0] mem [(2**VALID_ADDR_WIDTH)-1:0];
  //logic [DATA_WIDTH-1:0] mem [bit unsigned [(2**VALID_ADDR_WIDTH)-1:0]];
  
  wire [VALID_ADDR_WIDTH-1:0] s_axi_awaddr_valid = s_axi_awaddr >> (ADDR_WIDTH - VALID_ADDR_WIDTH);
  wire [VALID_ADDR_WIDTH-1:0] s_axi_araddr_valid = s_axi_araddr >> (ADDR_WIDTH - VALID_ADDR_WIDTH);
  wire [VALID_ADDR_WIDTH-1:0] read_addr_valid = read_addr_reg >> (ADDR_WIDTH - VALID_ADDR_WIDTH);
  wire [VALID_ADDR_WIDTH-1:0] write_addr_valid = write_addr_reg >> (ADDR_WIDTH - VALID_ADDR_WIDTH);

  reg [31:0] mem_tmp_1 [127:0];
  reg [31:0] mem_tmp_2 [127:0];
  
  assign s_axi_awready = s_axi_awready_reg;
  assign s_axi_wready = s_axi_wready_reg;
  assign s_axi_bid = s_axi_bid_reg;
  assign s_axi_bresp = 2'b00;
  assign s_axi_bvalid = s_axi_bvalid_reg;
  assign s_axi_arready = s_axi_arready_reg;
  assign s_axi_rid = PIPELINE_OUTPUT ? s_axi_rid_pipe_reg : s_axi_rid_reg;
  assign s_axi_rdata = PIPELINE_OUTPUT ? s_axi_rdata_pipe_reg : s_axi_rdata_reg;
  assign s_axi_rresp = 2'b00;
  assign s_axi_rlast = PIPELINE_OUTPUT ? s_axi_rlast_pipe_reg : s_axi_rlast_reg;
  assign s_axi_rvalid = PIPELINE_OUTPUT ? s_axi_rvalid_pipe_reg : s_axi_rvalid_reg;
  
  integer i, j;
  
  initial begin
    // mem=new[2**VALID_ADDR_WIDTH];
    // two nested loops for smaller number of iterations per loop
    // workaround for synthesizer complaints about large loop counts
    for (i = 0; i < 2**VALID_ADDR_WIDTH; i = i + 2**(VALID_ADDR_WIDTH/2)) begin
        for (j = i; j < i + 2**(VALID_ADDR_WIDTH/2); j = j + 1) begin
            mem[j] = 0;
        end
    end
  end
  
  always @* begin
    write_state_next = WRITE_STATE_IDLE;

    mem_wr_en = 1'b0;

    write_id_next = write_id_reg;
    write_addr_next = write_addr_reg;
    write_count_next = write_count_reg;
    write_size_next = write_size_reg;
    write_burst_next = write_burst_reg;

    s_axi_awready_next = 1'b0;
    s_axi_wready_next = 1'b0;
    s_axi_bid_next = s_axi_bid_reg;
    s_axi_bvalid_next = s_axi_bvalid_reg && !s_axi_bready;

    case (write_state_reg)
        WRITE_STATE_IDLE: begin
            s_axi_awready_next = 1'b1;

            if (s_axi_awready && s_axi_awvalid) begin
                write_id_next = s_axi_awid;
                write_addr_next = s_axi_awaddr;
                write_count_next = s_axi_awlen;
                write_size_next = s_axi_awsize < $clog2(STRB_WIDTH) ? s_axi_awsize : $clog2(STRB_WIDTH);
                write_burst_next = s_axi_awburst;

                s_axi_awready_next = 1'b0;
                s_axi_wready_next = 1'b1;
                write_state_next = WRITE_STATE_BURST;
            end else begin
                write_state_next = WRITE_STATE_IDLE;
            end
        end
        WRITE_STATE_BURST: begin
            s_axi_wready_next = 1'b1;

            if (s_axi_wready && s_axi_wvalid) begin
                mem_wr_en = 1'b1;
                if (write_burst_reg != 2'b00) begin
                    write_addr_next = write_addr_reg + (1 << write_size_reg);
                end
                write_count_next = write_count_reg - 1;
                if (write_count_reg > 0) begin
                    write_state_next = WRITE_STATE_BURST;
                end else begin
                    s_axi_wready_next = 1'b0;
                    if (s_axi_bready || !s_axi_bvalid) begin
                        s_axi_bid_next = write_id_reg;
                        s_axi_bvalid_next = 1'b1;
                        s_axi_awready_next = 1'b1;
                        write_state_next = WRITE_STATE_IDLE;
                    end else begin
                        write_state_next = WRITE_STATE_RESP;
                    end
                end
            end else begin
                write_state_next = WRITE_STATE_BURST;
            end
        end
        WRITE_STATE_RESP: begin
            if (s_axi_bready || !s_axi_bvalid) begin
                s_axi_bid_next = write_id_reg;
                s_axi_bvalid_next = 1'b1;
                s_axi_awready_next = 1'b1;
                write_state_next = WRITE_STATE_IDLE;
            end else begin
                write_state_next = WRITE_STATE_RESP;
            end
        end
    endcase
  end

  always @(posedge clk) begin
    write_state_reg <= write_state_next;

    write_id_reg <= write_id_next;
    write_addr_reg <= write_addr_next;
    write_count_reg <= write_count_next;
    write_size_reg <= write_size_next;
    write_burst_reg <= write_burst_next;

    s_axi_awready_reg <= s_axi_awready_next;
    s_axi_wready_reg <= s_axi_wready_next;
    s_axi_bid_reg <= s_axi_bid_next;
    s_axi_bvalid_reg <= s_axi_bvalid_next;

    for (i = 0; i < WORD_WIDTH; i = i + 1) begin
        if (mem_wr_en & s_axi_wstrb[i]) begin
            mem[write_addr_valid][WORD_SIZE*i +: WORD_SIZE] <= s_axi_wdata[WORD_SIZE*i +: WORD_SIZE];
        end
    end

    if (rst) begin
        write_state_reg <= WRITE_STATE_IDLE;

        s_axi_awready_reg <= 1'b0;
        s_axi_wready_reg <= 1'b0;
        s_axi_bvalid_reg <= 1'b0;
    end
  end

  always @* begin
    read_state_next = READ_STATE_IDLE;

    mem_rd_en = 1'b0;

    s_axi_rid_next = s_axi_rid_reg;
    s_axi_rlast_next = s_axi_rlast_reg;
    s_axi_rvalid_next = s_axi_rvalid_reg && !(s_axi_rready || (PIPELINE_OUTPUT && !s_axi_rvalid_pipe_reg));

    read_id_next = read_id_reg;
    read_addr_next = read_addr_reg;
    read_count_next = read_count_reg;
    read_size_next = read_size_reg;
    read_burst_next = read_burst_reg;

    s_axi_arready_next = 1'b0;

    case (read_state_reg)
        READ_STATE_IDLE: begin
            s_axi_arready_next = 1'b1;

            if (s_axi_arready && s_axi_arvalid) begin
                read_id_next = s_axi_arid;
                read_addr_next = s_axi_araddr;
                read_count_next = s_axi_arlen;
                read_size_next = s_axi_arsize < $clog2(STRB_WIDTH) ? s_axi_arsize : $clog2(STRB_WIDTH);
                read_burst_next = s_axi_arburst;

                s_axi_arready_next = 1'b0;
                read_state_next = READ_STATE_BURST;
            end else begin
                read_state_next = READ_STATE_IDLE;
            end
        end
        READ_STATE_BURST: begin
            if (s_axi_rready || (PIPELINE_OUTPUT && !s_axi_rvalid_pipe_reg) || !s_axi_rvalid_reg) begin
                mem_rd_en = 1'b1;
                s_axi_rvalid_next = 1'b1;
                s_axi_rid_next = read_id_reg;
                s_axi_rlast_next = read_count_reg == 0;
                if (read_burst_reg != 2'b00) begin
                    read_addr_next = read_addr_reg + (1 << read_size_reg);
                end
                read_count_next = read_count_reg - 1;
                if (read_count_reg > 0) begin
                    read_state_next = READ_STATE_BURST;
                end else begin
                    s_axi_arready_next = 1'b1;
                    read_state_next = READ_STATE_IDLE;
                end
            end else begin
                read_state_next = READ_STATE_BURST;
            end
        end
    endcase
  end
  
  always @(posedge clk) begin
    read_state_reg <= read_state_next;

    read_id_reg <= read_id_next;
    read_addr_reg <= read_addr_next;
    read_count_reg <= read_count_next;
    read_size_reg <= read_size_next;
    read_burst_reg <= read_burst_next;

    s_axi_arready_reg <= s_axi_arready_next;
    s_axi_rid_reg <= s_axi_rid_next;
    s_axi_rlast_reg <= s_axi_rlast_next;
    s_axi_rvalid_reg <= s_axi_rvalid_next;

    if (mem_rd_en) begin
        s_axi_rdata_reg <= mem[read_addr_valid];
    end

    if (!s_axi_rvalid_pipe_reg || s_axi_rready) begin
        s_axi_rid_pipe_reg <= s_axi_rid_reg;
        s_axi_rdata_pipe_reg <= s_axi_rdata_reg;
        s_axi_rlast_pipe_reg <= s_axi_rlast_reg;
        s_axi_rvalid_pipe_reg <= s_axi_rvalid_reg;
    end

    if (rst) begin
        read_state_reg <= READ_STATE_IDLE;

        s_axi_arready_reg <= 1'b0;
        s_axi_rvalid_reg <= 1'b0;
        s_axi_rvalid_pipe_reg <= 1'b0;
    end
  end

  task display_mem;
    input [ADDR_WIDTH-1:0] addr;
    reg [VALID_ADDR_WIDTH-1:0] addr_tmp;
    integer k;
    begin
      k=0;
      addr_tmp = addr >> (ADDR_WIDTH - VALID_ADDR_WIDTH);
      while(k==0) begin
      @(posedge clk);
      //$display("====================================");
      $display("          0x%h %h",addr,mem[addr_tmp][31:0]);
      $display("          0x%h %h",addr+4,mem[addr_tmp][63:32]);
      //$display("====================================");
      k=1;
      end
    end
  endtask

  task store_mem;
    input [ADDR_WIDTH-1:0] base_addr_1;
    input [ADDR_WIDTH-1:0] base_addr_2;
    input [31:0]           size_1     ;
    input [31:0]           size_2     ;
    input                  enable_1   ;
    input                  enable_2   ;
    reg [VALID_ADDR_WIDTH-1:0] addr_tmp1,addr_tmp2;
    integer k,l;
    begin
      addr_tmp1 = base_addr_1 >> (ADDR_WIDTH - VALID_ADDR_WIDTH);
      addr_tmp2 = base_addr_2 >> (ADDR_WIDTH - VALID_ADDR_WIDTH);
      @(posedge clk);
      fork begin:addr1
        if(enable_1)
          for(k=0;k<size_1/4;k=k+2) begin
            mem_tmp_1[k] = mem[addr_tmp1+k/2][31:0];
            mem_tmp_1[k+1] = mem[addr_tmp1+k/2][63:32];
          end
      end
      begin:addr2
        if(enable_2)
          for(l=0;l<size_2/4;l=l+2) begin
            mem_tmp_2[l] = mem[addr_tmp2+l/2][31:0];
            mem_tmp_2[l+1] = mem[addr_tmp2+l/2][63:32];
          end
      end
      join
    end
  endtask

endmodule

`resetall
