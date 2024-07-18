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

module axi4_adapter #(
  parameter int unsigned DATA_WIDTH             = 64 ,
  // the AXI subsystem needs to support wrapping reads for this feature
  parameter logic        CRITICAL_WORD_FIRST    = 0  , 
  parameter int unsigned CACHELINE_BYTE_OFFSET  = 3  ,
  parameter int unsigned MAX_OUTSTANDING_STORES = 0  ,

  // AXI types
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
  parameter int unsigned AXI_RESP_WIDTH         = 2  ,

  parameter type axi_req_t = logic,
  parameter type axi_rsp_t = logic
  ) 
  (
  input  logic                                                           clk_i                ,  
  input  logic                                                           rst_ni               , 

  output logic                                                           busy_o               ,
  input  logic                                                           req_i                ,
  input  logic                                                           type_i               ,
  input  logic [3:0]                                                     amo_i                ,
  output logic                                                           gnt_o                ,
  input  logic [AXI_ADDR_WIDTH-1:0]                                      addr_i               ,
  input  logic                                                           we_i                 ,
  input  logic [(DATA_WIDTH/AXI_DATA_WIDTH)-1:0][AXI_DATA_WIDTH-1:0]     wdata_i              ,
  input  logic [(DATA_WIDTH/AXI_DATA_WIDTH)-1:0][(AXI_DATA_WIDTH/8)-1:0] be_i                 ,
  input  logic [2:0]                                                     size_i               ,
  input  logic [AXI_ID_WIDTH-1:0]                                        id_i                 ,
  // read port
  output logic                                                           valid_o              ,
  output logic [(DATA_WIDTH/AXI_DATA_WIDTH)-1:0][AXI_DATA_WIDTH-1:0]     rdata_o              ,
  output logic [AXI_ID_WIDTH-1:0]                                        id_o                 ,
  // critical word - read port
  output logic [AXI_DATA_WIDTH-1:0]                                      critical_word_o      ,
  output logic                                                           critical_word_valid_o,
  // AXI port
  output axi_req_t                                                       axi_req_o            ,
  input  axi_rsp_t                                                       axi_resp_i
  );
  
  //req type
  localparam SINGLE_REQ     = 0;
  localparam CACHE_LINE_REQ = 1;

  localparam BURST_SIZE = (DATA_WIDTH / AXI_DATA_WIDTH) - 1;

  localparam BURST_FIXED = 2'b00;
  localparam BURST_INCR  = 2'b01;
  localparam BURST_WRAP  = 2'b10;

  localparam RESP_OKAY   = 2'b00;
  localparam RESP_EXOKAY = 2'b01;
  localparam RESP_SLVERR = 2'b10;
  localparam RESP_DECERR = 2'b11;

  localparam CACHE_BUFFERABLE = 4'b0001;
  localparam CACHE_MODIFIABLE = 4'b0010;
  localparam CACHE_RD_ALLOC   = 4'b0100;
  localparam CACHE_WR_ALLOC   = 4'b1000;

  localparam ATOP_ATOMICSWAP  = 6'b110000;
  localparam ATOP_ATOMICCMP   = 6'b110001;
  localparam ATOP_NONE        = 2'b00;
  localparam ATOP_ATOMICSTORE = 2'b01;
  localparam ATOP_ATOMICLOAD  = 2'b10;
  localparam ATOP_LITTLE_END  = 1'b0;
  localparam ATOP_BIG_END     = 1'b1;
  localparam ATOP_ADD         = 3'b000;
  localparam ATOP_CLR         = 3'b001;
  localparam ATOP_EOR         = 3'b010;
  localparam ATOP_SET         = 3'b011;
  localparam ATOP_SMAX        = 3'b100;
  localparam ATOP_SMIN        = 3'b101;
  localparam ATOP_UMAX        = 3'b110;
  localparam ATOP_UMIN        = 3'b111;
  localparam ATOP_R_RESP      = 32'd5;

  localparam ADDR_INDEX = ($clog2(DATA_WIDTH/AXI_DATA_WIDTH) > 0) ? $clog2(DATA_WIDTH/AXI_DATA_WIDTH) : 1;

  localparam MAX_OUTSTANDING_AW = MAX_OUTSTANDING_STORES;

  localparam MAX_OUTSTANDING_AW_CNT_WIDTH = $clog2(MAX_OUTSTANDING_AW+1) > 0 ? $clog2(MAX_OUTSTANDING_AW+1) : 1;

  typedef logic [MAX_OUTSTANDING_AW_CNT_WIDTH-1:0] outstanding_aw_cnt_t;

  enum logic [3:0] {
    IDLE,
    WAIT_B_VALID,
    WAIT_AW_READY,
    WAIT_LAST_W_READY,
    WAIT_LAST_W_READY_AW_READY,
    WAIT_AW_READY_BURST,
    WAIT_R_VALID,
    WAIT_R_VALID_MULTIPLE,
    COMPLETE_READ,
    WAIT_AMO_R_VALID
  } state_q, state_d;

  // counter for AXI transfers
  logic [ADDR_INDEX-1:0] cnt_d, cnt_q;
  logic [(DATA_WIDTH/AXI_DATA_WIDTH)-1:0][AXI_DATA_WIDTH-1:0] cache_line_d, cache_line_q;
  // save the address for a read, as we allow for non-cacheline aligned accesses
  logic [(DATA_WIDTH/AXI_DATA_WIDTH)-1:0] addr_offset_d, addr_offset_q;
  logic [AXI_ID_WIDTH-1:0] id_d, id_q;
  logic [ADDR_INDEX-1:0] index;

  // save the atomic operation and size
  typedef enum logic [3:0] {
    AMO_NONE = 4'b0000,
    AMO_LR   = 4'b0001,
    AMO_SC   = 4'b0010,
    AMO_SWAP = 4'b0011,
    AMO_ADD  = 4'b0100,
    AMO_AND  = 4'b0101,
    AMO_OR   = 4'b0110,
    AMO_XOR  = 4'b0111,
    AMO_MAX  = 4'b1000,
    AMO_MAXU = 4'b1001,
    AMO_MIN  = 4'b1010,
    AMO_MINU = 4'b1011,
    AMO_CAS1 = 4'b1100,  // unused, not part of riscv spec, but provided in OpenPiton
    AMO_CAS2 = 4'b1101   // unused, not part of riscv spec, but provided in OpenPiton
  } amo_t;

  logic [3:0] amo_d,amo_q;

  logic [1:0] size_d, size_q;
  // outstanding write transactions counter
  outstanding_aw_cnt_t outstanding_aw_cnt_q, outstanding_aw_cnt_d;
  logic any_outstanding_aw;

  assign any_outstanding_aw = outstanding_aw_cnt_q != '0;

  // Busy if we're not idle
  assign busy_o = state_q != IDLE;

  always_comb begin : axi_fsm
    // Default assignments
    axi_req_o.aw_valid  = 1'b0;
    // Cast to AXI address width
    axi_req_o.aw.addr   = addr_i;
    axi_req_o.aw.prot   = 3'b0;
    axi_req_o.aw.region = 4'b0;
    axi_req_o.aw.len    = 8'b0;
    axi_req_o.aw.size   = size_i;  // 1, 2, 4 or 8 bytes
    axi_req_o.aw.burst  = BURST_INCR;  // Use BURST_INCR for AXI regular transaction
    axi_req_o.aw.lock   = 1'b0;
    axi_req_o.aw.cache  = CACHE_MODIFIABLE;
    axi_req_o.aw.qos    = 4'b0;
    axi_req_o.aw.id     = id_i;
    axi_req_o.aw.atop   = atop_from_amo(amo_i);
    axi_req_o.aw.user   = '0;

    axi_req_o.ar_valid  = 1'b0;
    // Cast to AXI address width
    axi_req_o.ar.addr   = addr_i;
    // in case of a single request or wrapping transfer we can simply begin at the address, if we want to request a cache-line
    // with an incremental transfer we need to output the corresponding base address of the cache line
    if (!CRITICAL_WORD_FIRST && type_i != SINGLE_REQ) begin
      axi_req_o.ar.addr[CACHELINE_BYTE_OFFSET-1:0] = '0;
    end
    axi_req_o.ar.prot = 3'b0;
    axi_req_o.ar.region = 4'b0;
    axi_req_o.ar.len = 8'b0;
    axi_req_o.ar.size = {1'b0, size_i};  // 1, 2, 4 or 8 bytes
    axi_req_o.ar.burst  = (CRITICAL_WORD_FIRST ? BURST_WRAP : BURST_INCR); // wrapping transfer in case of a critical word first strategy
    axi_req_o.ar.lock = 1'b0;
    axi_req_o.ar.cache = CACHE_MODIFIABLE;
    axi_req_o.ar.qos = 4'b0;
    axi_req_o.ar.id = id_i;
    axi_req_o.ar.user = '0;

    axi_req_o.w_valid = 1'b0;
    axi_req_o.w.data = wdata_i[0];
    axi_req_o.w.strb = be_i[0];
    axi_req_o.w.last = 1'b0;
    axi_req_o.w.user = '0;

    axi_req_o.b_ready = 1'b0;
    axi_req_o.r_ready = 1'b0;

    gnt_o = 1'b0;
    valid_o = 1'b0;
    id_o = axi_resp_i.r.id;

    critical_word_o = axi_resp_i.r.data;
    critical_word_valid_o = 1'b0;
    rdata_o = cache_line_q;

    state_d = state_q;
    cnt_d = cnt_q;
    cache_line_d = cache_line_q;
    addr_offset_d = addr_offset_q;
    id_d = id_q;
    amo_d = amo_q;
    size_d = size_q;
    index = '0;

    outstanding_aw_cnt_d = outstanding_aw_cnt_q;

    case (state_q)

      IDLE: begin
        cnt_d = '0;
        // we have an incoming request
        if (req_i) begin
          // is this a read or write?
          // write
          if (we_i) begin
            // multiple outstanding write transactions are only
            // allowed if they are guaranteed not to be reordered
            // i.e. same ID
            if (!any_outstanding_aw || ((id_i == id_q) && (amo_i == AMO_NONE))) begin
              // the data is valid
              axi_req_o.aw_valid = 1'b1;
              axi_req_o.w_valid  = 1'b1;
              // store-conditional requires exclusive access
              axi_req_o.aw.lock  = amo_i == AMO_SC;
              // its a single write
              if (type_i == SINGLE_REQ) begin
                // only a single write so the data is already the last one
                axi_req_o.w.last = 1'b1;
                // single req can be granted here
                gnt_o = axi_resp_i.aw_ready & axi_resp_i.w_ready;
                case ({
                  axi_resp_i.aw_ready, axi_resp_i.w_ready
                })
                  2'b11:   state_d = WAIT_B_VALID;
                  2'b01:   state_d = WAIT_AW_READY;
                  2'b10:   state_d = WAIT_LAST_W_READY;
                  default: state_d = IDLE;
                endcase

                if (axi_resp_i.aw_ready) begin
                  id_d   = id_i;
                  amo_d  = amo_i;
                  size_d = size_i;
                end

                // its a request for the whole cache line
              end else begin
                // bursts of AMOs unsupported
                //assert (amo_i == AMO_NONE)
                //else $fatal("Bursts of atomic operations are not supported");

                axi_req_o.aw.len = BURST_SIZE[7:0];  // number of bursts to do
                axi_req_o.w.data = wdata_i[0];
                axi_req_o.w.strb = be_i[0];

                if (axi_resp_i.w_ready) cnt_d = BURST_SIZE[ADDR_INDEX-1:0] - 1;
                else cnt_d = BURST_SIZE[ADDR_INDEX-1:0];

                case ({
                  axi_resp_i.aw_ready, axi_resp_i.w_ready
                })
                  2'b11:   state_d = WAIT_LAST_W_READY;
                  2'b01:   state_d = WAIT_LAST_W_READY_AW_READY;
                  2'b10:   state_d = WAIT_LAST_W_READY;
                  default: ;
                endcase
              end
            end
            // read
          end else begin
            // only multiple outstanding write transactions are allowed
            if (!any_outstanding_aw) begin

              axi_req_o.ar_valid = 1'b1;
              // load-reserved requires exclusive access
              axi_req_o.ar.lock = amo_i == AMO_LR;

              gnt_o = axi_resp_i.ar_ready;
              if (type_i != SINGLE_REQ) begin
                //assert (amo_i == AMO_NONE)
                //else $fatal("Bursts of atomic operations are not supported");

                axi_req_o.ar.len = BURST_SIZE[7:0];
                cnt_d = BURST_SIZE[ADDR_INDEX-1:0];
              end

              if (axi_resp_i.ar_ready) begin
                state_d = (type_i == SINGLE_REQ) ? WAIT_R_VALID : WAIT_R_VALID_MULTIPLE;
                addr_offset_d = addr_i[ADDR_INDEX-1+3:3];
              end
            end
          end
        end
      end

      // ~> from single write
      WAIT_AW_READY: begin
        axi_req_o.aw_valid = 1'b1;

        if (axi_resp_i.aw_ready) begin
          gnt_o   = 1'b1;
          state_d = WAIT_B_VALID;
          id_d    = id_i;
          amo_d   = amo_i;
          size_d  = size_i;
        end
      end

      // ~> we need to wait for an aw_ready and there is at least one outstanding write
      WAIT_LAST_W_READY_AW_READY: begin
        axi_req_o.w_valid = 1'b1;
        axi_req_o.w.last  = (cnt_q == '0);
        if (type_i == SINGLE_REQ) begin
          axi_req_o.w.data = wdata_i[0];
          axi_req_o.w.strb = be_i[0];
        end else begin
          axi_req_o.w.data = wdata_i[BURST_SIZE[ADDR_INDEX-1:0]-cnt_q];
          axi_req_o.w.strb = be_i[BURST_SIZE[ADDR_INDEX-1:0]-cnt_q];
        end
        axi_req_o.aw_valid = 1'b1;
        // we are here because we want to write a cache line
        axi_req_o.aw.len   = BURST_SIZE[7:0];
        // we got an aw_ready
        case ({
          axi_resp_i.aw_ready, axi_resp_i.w_ready
        })
          // we got an aw ready
          2'b01: begin
            // are there any outstanding transactions?
            if (cnt_q == 0) state_d = WAIT_AW_READY_BURST;
            else  // yes, so reduce the count and stay here
              cnt_d = cnt_q - 1;
          end
          2'b10:   state_d = WAIT_LAST_W_READY;
          2'b11: begin
            // we are finished
            if (cnt_q == 0) begin
              state_d = WAIT_B_VALID;
              gnt_o   = 1'b1;
              // there are outstanding transactions
            end else begin
              state_d = WAIT_LAST_W_READY;
              cnt_d   = cnt_q - 1;
            end
          end
          default: ;
        endcase

      end

      // ~> all data has already been sent, we are only waiting for the aw_ready
      WAIT_AW_READY_BURST: begin
        axi_req_o.aw_valid = 1'b1;
        axi_req_o.aw.len   = BURST_SIZE[7:0];

        if (axi_resp_i.aw_ready) begin
          state_d = WAIT_B_VALID;
          gnt_o   = 1'b1;
        end
      end

      // ~> from write, there is an outstanding write
      WAIT_LAST_W_READY: begin
        axi_req_o.w_valid = 1'b1;

        if (type_i != SINGLE_REQ) begin
          axi_req_o.w.data = wdata_i[BURST_SIZE[ADDR_INDEX-1:0]-cnt_q];
          axi_req_o.w.strb = be_i[BURST_SIZE[ADDR_INDEX-1:0]-cnt_q];
        end

        // this is the last write
        if (cnt_q == '0) begin
          axi_req_o.w.last = 1'b1;
          if (axi_resp_i.w_ready) begin
            state_d = WAIT_B_VALID;
            gnt_o   = 1'b1;
          end
        end else if (axi_resp_i.w_ready) begin
          cnt_d = cnt_q - 1;
        end
      end

      // ~> finish write transaction
      WAIT_B_VALID: begin
        id_o = axi_resp_i.b.id;

        // Write is valid
        if (axi_resp_i.b_valid && !any_outstanding_aw) begin
          axi_req_o.b_ready = 1'b1;

          // some atomics must wait for read data
          // we only accept it after accepting bvalid
          if (amo_returns_data(amo_q)) begin
            if (axi_resp_i.r_valid) begin
              // return read data if valid
              valid_o           = 1'b1;
              axi_req_o.r_ready = 1'b1;
              state_d           = IDLE;
              rdata_o           = axi_resp_i.r.data;
            end else begin
              // wait otherwise
              state_d = WAIT_AMO_R_VALID;
            end
          end else begin
            valid_o = 1'b1;
            state_d = IDLE;

            // store-conditional response
            if (amo_q == AMO_SC) begin
              if (axi_resp_i.b.resp == RESP_EXOKAY) begin
                // success -> return 0
                rdata_o = 'b0;
              end else begin
                // failure -> when request is 64-bit, return 1;
                // when request is 32-bit place a 1 in both upper
                // and lower half words. The right word will be
                // realigned/masked externally
                rdata_o = size_q == 2'b10 ? (1'b1 << 32) | 64'b1 : 64'b1;
              end
            end
          end
          // if the request was not an atomic we can possibly issue
          // other requests while waiting for the response
        end else begin
          if ((amo_q == AMO_NONE) && (outstanding_aw_cnt_q != MAX_OUTSTANDING_AW)) begin
            state_d = IDLE;
            outstanding_aw_cnt_d = outstanding_aw_cnt_q + 1;
          end
        end
      end

      // ~> some atomics wait for read data
      WAIT_AMO_R_VALID: begin
        // acknowledge data and terminate atomic
        if (axi_resp_i.r_valid) begin
          axi_req_o.r_ready = 1'b1;
          state_d           = IDLE;
          valid_o           = 1'b1;
          rdata_o           = axi_resp_i.r.data;
        end
      end

      // ~> cacheline read, single read
      WAIT_R_VALID_MULTIPLE, WAIT_R_VALID: begin
        if (CRITICAL_WORD_FIRST) index = addr_offset_q + (BURST_SIZE[ADDR_INDEX-1:0] - cnt_q);
        else index = BURST_SIZE[ADDR_INDEX-1:0] - cnt_q;

        // reads are always wrapping here
        axi_req_o.r_ready = 1'b1;
        // this is the first read a.k.a the critical word
        if (axi_resp_i.r_valid) begin
          if (CRITICAL_WORD_FIRST) begin
            // this is the first word of a cacheline read, e.g.: the word which was causing the miss
            if (state_q == WAIT_R_VALID_MULTIPLE && cnt_q == BURST_SIZE) begin
              critical_word_valid_o = 1'b1;
              critical_word_o       = axi_resp_i.r.data;
            end
          end else begin
            // check if the address offset matches - then we are getting the critical word
            if (index == addr_offset_q) begin
              critical_word_valid_o = 1'b1;
              critical_word_o       = axi_resp_i.r.data;
            end
          end

          // this is the last read
          if (axi_resp_i.r.last) begin
            id_d    = axi_resp_i.r.id;
            state_d = COMPLETE_READ;
          end

          // save the word
          if (state_q == WAIT_R_VALID_MULTIPLE) begin
            cache_line_d[index] = axi_resp_i.r.data;

          end else cache_line_d[0] = axi_resp_i.r.data;

          // Decrease the counter
          cnt_d = cnt_q - 1;
        end
      end
      // ~> read is complete
      COMPLETE_READ: begin
        valid_o = 1'b1;
        state_d = IDLE;
        id_o    = id_q;
      end

      default: state_d = IDLE;
    endcase

    // This process handles B responses when accepting
    // multiple outstanding write transactions
    if (any_outstanding_aw && axi_resp_i.b_valid) begin
      axi_req_o.b_ready = 1'b1;
      valid_o = 1'b1;
      // Right hand side contains non-registered signal as we want
      // to preserve a possible increment from the WAIT_B_VALID state
      outstanding_aw_cnt_d = outstanding_aw_cnt_d - 1;
    end
  end

  // ----------------
  // Registers
  // ----------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      // start in flushing state and initialize the memory
      state_q              <= IDLE;
      cnt_q                <= '0;
      cache_line_q         <= '0;
      addr_offset_q        <= '0;
      id_q                 <= '0;
      amo_q                <= AMO_NONE;
      size_q               <= '0;
      outstanding_aw_cnt_q <= '0;
    end else begin
      state_q              <= state_d;
      cnt_q                <= cnt_d;
      cache_line_q         <= cache_line_d;
      addr_offset_q        <= addr_offset_d;
      id_q                 <= id_d;
      amo_q                <= amo_d;
      size_q               <= size_d;
      outstanding_aw_cnt_q <= outstanding_aw_cnt_d;
    end
  end

  function automatic logic [AXI_ATOP_WIDTH-1:0] atop_from_amo(logic [3:0] amo);
    logic [AXI_ATOP_WIDTH-1:0] result = 6'b000000;

    unique case (amo)
      AMO_NONE: result = {ATOP_NONE, 4'b0000};
      AMO_SWAP: result = {ATOP_ATOMICSWAP};
      AMO_ADD:
      result = {ATOP_ATOMICLOAD, ATOP_LITTLE_END, ATOP_ADD};
      AMO_AND:
      result = {ATOP_ATOMICLOAD, ATOP_LITTLE_END, ATOP_CLR};
      AMO_OR:
      result = {ATOP_ATOMICLOAD, ATOP_LITTLE_END, ATOP_SET};
      AMO_XOR:
      result = {ATOP_ATOMICLOAD, ATOP_LITTLE_END, ATOP_EOR};
      AMO_MAX:
      result = {ATOP_ATOMICLOAD, ATOP_LITTLE_END, ATOP_SMAX};
      AMO_MAXU:
      result = {ATOP_ATOMICLOAD, ATOP_LITTLE_END, ATOP_UMAX};
      AMO_MIN:
      result = {ATOP_ATOMICLOAD, ATOP_LITTLE_END, ATOP_SMIN};
      AMO_MINU:
      result = {ATOP_ATOMICLOAD, ATOP_LITTLE_END, ATOP_UMIN};
      AMO_CAS1: result = {ATOP_NONE, 4'b0000};  // Unsupported
      AMO_CAS2: result = {ATOP_NONE, 4'b0000};  // Unsupported
      default: result = 6'b000000;
    endcase

    return result;
  endfunction

  function automatic logic amo_returns_data(logic [3:0] amo);
    logic [AXI_ATOP_WIDTH-1:0] atop = atop_from_amo(amo);
    logic           is_load = atop[5:4] == ATOP_ATOMICLOAD;
    logic           is_swap_or_cmp = atop[5:4] == ATOP_ATOMICSWAP[5:4];
    return is_load || is_swap_or_cmp;
  endfunction

endmodule
