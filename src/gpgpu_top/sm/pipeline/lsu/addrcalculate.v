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
// Author: Tan, Zhiyuan
// Description: Compute the addr of requests, and send them.

`timescale 1ns/1ns

`include "define.v"
//`include "IDecode_define.v"

module addrcalculate #(parameter SHARED_ADDR_MAX = 32'd4096)(
  input                                             clk                       ,
  input                                             rst_n                     ,

  //from fifo(vExeData)
  input                                             from_fifo_valid_i         ,
  output                                            from_fifo_ready_o         ,
  input   [`XLEN*`NUM_THREAD-1:0]                   from_fifo_in1_i           ,
  input   [`XLEN*`NUM_THREAD-1:0]                   from_fifo_in2_i           ,
  input   [`XLEN*`NUM_THREAD-1:0]                   from_fifo_in3_i           ,
  input   [`NUM_THREAD-1:0]                         from_fifo_mask_i          ,
  //from fifo: control signals
  input   [`DEPTH_WARP-1:0]                         from_fifo_wid_i           ,
  input                                             from_fifo_isvec_i         ,
  input   [1:0]                                     from_fifo_mem_whb_i       ,
  input                                             from_fifo_mem_unsigned_i  ,
  input   [5:0]                                     from_fifo_alu_fn_i        ,
  input                                             from_fifo_is_vls12_i      ,
  input                                             from_fifo_disable_mask_i  ,
  input   [1:0]                                     from_fifo_mem_cmd_i       ,
  input   [1:0]                                     from_fifo_mop_i           ,
  input   [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]         from_fifo_reg_idxw_i      ,
  input                                             from_fifo_wvd_i           ,
  input                                             from_fifo_fence_i         ,
  input                                             from_fifo_wxd_i           ,
  input                                             from_fifo_atomic_i        ,
  input                                             from_fifo_aq_i            ,
  input                                             from_fifo_rl_i            ,

  //connect csr
  input   [`XLEN-1:0]                               csr_pds_i                 ,
  input   [`XLEN-1:0]                               csr_numw_i                ,
  input   [`XLEN-1:0]                               csr_tid_i                 ,
  output  [`DEPTH_WARP-1:0]                         csr_wid_o                 ,

  //idx entry
  input   [$clog2(`LSU_NMSHRENTRY)-1:0]             idx_entry_i               ,
  
  //to mshr
  output                                            to_mshr_valid_o           ,
  input                                             to_mshr_ready_i           ,
  output  [`DEPTH_WARP-1:0]                         to_mshr_warp_id_o         ,
  output                                            to_mshr_wfd_o             ,
  output                                            to_mshr_wxd_o             ,
  //output                                            to_mshr_isvec_o           ,
  output  [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]         to_mshr_reg_idxw_o        ,
  output  [`NUM_THREAD-1:0]                         to_mshr_mask_o            ,
  output                                            to_mshr_unsigned_o        ,
  output  [`BYTESOFWORD*`NUM_THREAD-1:0]            to_mshr_wordoffset1h_o    ,
  output                                            to_mshr_iswrite_o         ,

  //to shared
  output                                            to_shared_valid_o         ,
  input                                             to_shared_ready_i         ,
  output  [$clog2(`LSU_NMSHRENTRY)-1:0]             to_shared_instrid_o       ,
  output                                            to_shared_iswrite_o       ,
  output  [`DCACHE_TAGBITS-1:0]                     to_shared_tag_o           ,
  output  [`DCACHE_SETIDXBITS-1:0]                  to_shared_setidx_o        ,
  output  [`NUM_THREAD-1:0]                         to_shared_activemask_o    ,
  output  [`NUM_THREAD*`DCACHE_BLOCKOFFSETBITS-1:0] to_shared_blockoffset_o   ,
  output  [`NUM_THREAD*`BYTESOFWORD-1:0]            to_shared_wordoffset1h_o  ,
  output  [`NUM_THREAD*`XLEN-1:0]                   to_shared_data_o          ,

  //to dcache
  output                                            to_dcache_valid_o         ,
  input                                             to_dcache_ready_i         ,
  output  [$clog2(`LSU_NMSHRENTRY)-1:0]             to_dcache_instrid_o       ,
  output  [`DCACHE_SETIDXBITS-1:0]                  to_dcache_setidx_o        ,
  output  [`DCACHE_TAGBITS-1:0]                     to_dcache_tag_o           ,
  output  [`NUM_THREAD-1:0]                         to_dcache_activemask_o    ,
  output  [`NUM_THREAD*`DCACHE_BLOCKOFFSETBITS-1:0] to_dcache_blockoffset_o   ,
  output  [`NUM_THREAD*`BYTESOFWORD-1:0]            to_dcache_wordoffset1h_o  ,
  output  [`NUM_THREAD*`XLEN-1:0]                   to_dcache_data_o          ,
  output  [2:0]                                     to_dcache_opcode_o        ,
  output  [3:0]                                     to_dcache_param_o         
  );

  //fsm and counter defines
  localparam S_IDLE     = 3'b000,
             S_SAVE     = 3'b001,
             S_SHARED   = 3'b010,
             S_DCACHE   = 3'b011,
             S_DCACHE_1 = 3'b100,
             S_DCACHE_2 = 3'b101;

  parameter DCACHE_TAGBITS = `DCACHE_TAGBITS ;

  reg  [2:0]                            c_state              ;
  reg  [2:0]                            n_state              ;
  reg  [`DEPTH_THREAD-1:0]              cnt                  ;
  //reg_save
  //reg  [`XLEN*`NUM_THREAD-1:0]          reg_save_in1         ;
  //reg  [`XLEN*`NUM_THREAD-1:0]          reg_save_in2         ;
  reg  [`XLEN*`NUM_THREAD-1:0]          reg_save_in3         ;
  reg  [`NUM_THREAD-1:0]                reg_save_mask        ;
  reg  [`DEPTH_WARP-1:0]                reg_save_wid         ;
  reg                                   reg_save_isvec       ;
  reg  [1:0]                            reg_save_mem_whb     ;
  reg                                   reg_save_mem_unsigned;
  reg  [5:0]                            reg_save_alu_fn      ;
  //reg                                   reg_save_is_vls12    ;
  //reg                                   reg_save_disable_mask;
  reg  [1:0]                            reg_save_mem_cmd     ;
  //reg  [1:0]                            reg_save_mop         ;
  reg  [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]reg_save_reg_idxw    ;
  reg                                   reg_save_wvd         ;
  reg                                   reg_save_fence       ;
  reg                                   reg_save_wxd         ;
  reg                                   reg_save_atomic      ;
  reg                                   reg_save_aq          ;
  reg                                   reg_save_rl          ;
  //entry id
  reg [$clog2(`LSU_NMSHRENTRY)-1:0]     reg_entryid          ;

  //input ready and output csr wid
  assign from_fifo_ready_o = c_state==S_IDLE;
  assign csr_wid_o = reg_save_wid;

  //Addr caculate and analyze(comb)
  reg   [`XLEN-1:0]         addr       [0:`NUM_THREAD-1] ;
  reg   [`XLEN-1:0]         addr_add   [0:`NUM_THREAD-1] ;
  reg   [`NUM_THREAD-1:0]   is_shared                    ;
  wire                      all_shared                   ;

  //Addr register
  reg   [`XLEN-1:0]         addr_reg   [0:`NUM_THREAD-1] ;

  /*
  genvar i;
  generate for(i=0;i<`NUM_THREAD;i=i+1) begin:ADDR_CAL
    always@(*) begin
      //for cat, addr_2 is 2-bits
      //addr_2[i] = reg_save_in1[2*(i+1)+`XLEN*i-1:`XLEN*i] + reg_save_in2[2*(i+1)+`XLEN*i-1:`XLEN*i];
      addr_add[i] = reg_save_in1[`XLEN*(i+1)-1-:`XLEN] + reg_save_in2[`XLEN*(i+1)-1-:`XLEN];
      if(reg_save_isvec && reg_save_disable_mask) begin
        if(reg_save_is_vls12) begin
          addr[i] = addr_add[i];
        end
        else begin
          addr[i] = addr_add[i][1:0] + csr_pds_i + {(csr_tid_i[6:0]+i),2'b00} + (({addr_add[i][`XLEN-1:2],2'b00}*csr_numw_i[3:0])<<`DEPTH_THREAD);
        end
      end
      else begin
        if(reg_save_isvec) begin
          addr[i] = reg_save_in1[`XLEN*(i+1)-1-:`XLEN] + ((reg_save_mop==2'b00) ? i<<2 : ((reg_save_mop==2'b11)?reg_save_in2[`XLEN*(i+1)-1-:`XLEN]:i*reg_save_in2[`XLEN*(i+1)-1-:`XLEN]));
        end
        else begin
          addr[i] = addr_add[0];
        end
      end
      is_shared[i] = !reg_save_mask[i] || addr[i]<SHARED_ADDR_MAX;
    end
  end
  endgenerate
  */
  genvar i;
  generate for(i=0;i<`NUM_THREAD;i=i+1) begin:ADDR_CAL
    always@(*) begin
      //for cat, addr_2 is 2-bits
      //addr_2[i] = reg_save_in1[2*(i+1)+`XLEN*i-1:`XLEN*i] + reg_save_in2[2*(i+1)+`XLEN*i-1:`XLEN*i];
      addr_add[i] = from_fifo_in1_i[`XLEN*(i+1)-1-:`XLEN] + from_fifo_in2_i[`XLEN*(i+1)-1-:`XLEN];
      if(from_fifo_isvec_i && from_fifo_disable_mask_i) begin
        if(from_fifo_is_vls12_i) begin
          addr[i] = addr_add[i];
        end
        else begin
          addr[i] = addr_add[i][1:0] + csr_pds_i + {(csr_tid_i[6:0]+i),2'b00} + (({addr_add[i][`XLEN-1:2],2'b00}*csr_numw_i[3:0])<<`DEPTH_THREAD);
        end
      end
      else begin
        if(from_fifo_isvec_i) begin
          addr[i] = from_fifo_in1_i[`XLEN*(i+1)-1-:`XLEN] + ((from_fifo_mop_i==2'b00) ? i<<2 : ((from_fifo_mop_i==2'b11)?from_fifo_in2_i[`XLEN*(i+1)-1-:`XLEN]:i*from_fifo_in2_i[`XLEN*(i+1)-1-:`XLEN]));
        end
        else begin
          addr[i] = addr_add[0];
        end
      end
      is_shared[i] = !from_fifo_mask_i[i] || addr[i]<SHARED_ADDR_MAX;
    end

    always@(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        addr_reg[i] <= 'd0;
      end
      else if(from_fifo_valid_i && from_fifo_ready_o) begin
        addr_reg[i] <= addr[i];
      end
      else begin
        addr_reg[i] <= addr_reg[i];
      end
    end
  end
  endgenerate

  assign all_shared = from_fifo_isvec_i ? (&is_shared) : is_shared[0];

  //PriorityEncoder
  //wire  [`NUM_THREAD-1:0]         pri_mask_oh   ;
  wire  [`DEPTH_THREAD-1:0]       pri_mask_bin  ;
  wire  [`XLEN-1:0]               addr_wire     ;
  wire  [DCACHE_TAGBITS-1:0]      tag           ;
  wire  [`DCACHE_SETIDXBITS-1:0]  setidx        ;
  
  /*
  fixed_pri_arb #(
    .ARB_WIDTH  (`NUM_THREAD) 
  )
  mask_oh(
    .req    (reg_save_mask) ,
    .grant  (pri_mask_oh)   
  );

  one2bin #(
    .ONE_WIDTH  (`NUM_THREAD)   ,
    .BIN_WIDTH  (`DEPTH_THREAD) 
  )
  mask_bin(
    .oh    (pri_mask_oh)  ,
    .bin   (pri_mask_bin) 
  );
  */

  wire tail_zero; 

  lzc #(
    .WIDTH     (`NUM_THREAD  ),
    .MODE      (1'b0         ),
    .CNT_WIDTH (`DEPTH_THREAD)
  )
  pri_encoder_mask (
    .in_i    (reg_save_mask),
    .cnt_o   (pri_mask_bin ),
    .empty_o (tail_zero    )
  );

  assign addr_wire = addr_reg[pri_mask_bin];
  //assign tag       = (reg_save_mask=='d0) ? 'd0 : addr_wire[`XLEN-1:`XLEN-1-DCACHE_TAGBITS+1];
  //assign setidx    = (reg_save_mask=='d0) ? 'd0 : addr_wire[`XLEN-1-DCACHE_TAGBITS:`XLEN-1-DCACHE_TAGBITS-`DCACHE_SETIDXBITS+1];
  assign tag       = addr_wire[`XLEN-1-:`DCACHE_TAGBITS]                  ;
  assign setidx    = addr_wire[`XLEN-1-DCACHE_TAGBITS-:`DCACHE_SETIDXBITS];

  reg  [`NUM_THREAD-1:0]             same_tag                        ;
  reg  [`DCACHE_BLOCKOFFSETBITS-1:0] blockoffset   [0:`NUM_THREAD-1] ;
  reg  [`BYTESOFWORD-1:0]            wordoffset1h  [0:`NUM_THREAD-1] ;

  //_reg: real regs
  reg  [`BYTESOFWORD-1:0]            wordoffset1h_reg [0:`NUM_THREAD-1];
  reg  [`DCACHE_BLOCKOFFSETBITS-1:0] blockoffset_reg  [0:`NUM_THREAD-1];
  //reg  [DCACHE_TAGBITS-1:0]          tag_reg                           ;
  //reg  [`DCACHE_SETIDXBITS-1:0]      setidx_reg                        ;

  genvar j;
  generate for(j=0;j<`NUM_THREAD;j=j+1) begin:SAME_LANE
    always@(*)begin
      //same_tag[j]     = reg_save_mask[j] ? addr[j][`XLEN-1:`DCACHE_BLOCKOFFSETBITS+2]=={tag,setidx} : 1'b0;
      same_tag[j]     = addr_reg[j][`XLEN-1:`DCACHE_BLOCKOFFSETBITS+2] == {tag,setidx}   ;
      //blockoffset[j]  = reg_save_mask[j] ? addr[j][`DCACHE_BLOCKOFFSETBITS+1:2] : 'd0;
      blockoffset[j]  = addr[j][`DCACHE_BLOCKOFFSETBITS+1:2];
      case(from_fifo_mem_whb_i)
        `MEM_W: begin
          wordoffset1h[j] = 4'b1111;
        end
        `MEM_H: begin
          wordoffset1h[j] = (addr[j][1]==1'b0) ? 4'b0011 : 4'b1100;
        end
        `MEM_B: begin
          wordoffset1h[j] = 4'b0001 << addr[j][1:0];
        end
        default: begin
          wordoffset1h[j] = 4'b1111;
        end
      endcase
    end

    always@(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        wordoffset1h_reg[j] <= 'd0;
        blockoffset_reg[j]  <= 'd0;
      end
      else if(from_fifo_valid_i && from_fifo_ready_o) begin
        wordoffset1h_reg[j] <= wordoffset1h[j];
        blockoffset_reg[j]  <= blockoffset[j] ;
      end
      else begin
        wordoffset1h_reg[j] <= wordoffset1h_reg[j];
        blockoffset_reg[j]  <= blockoffset_reg[j] ;
      end
    end
  end
  endgenerate

  /*
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      tag_reg    <= 'd0;
      setidx_reg <= 'd0;
    end
    else if(from_fifo_valid_i && from_fifo_ready_o) begin
      tag_reg    <= tag   ;
      setidx_reg <= setidx;
    end
    else begin
      tag_reg    <= tag_reg   ;
      setidx_reg <= setidx_reg;
    end
  end
  */

  //output to mshr
  assign   to_mshr_valid_o      = (c_state == S_SAVE) && (|reg_save_mem_cmd) ;
  assign   to_mshr_warp_id_o    = reg_save_wid         ;
  assign   to_mshr_wfd_o        = reg_save_wvd         ;
  assign   to_mshr_wxd_o        = reg_save_wxd         ;
  //assign   to_mshr_isvec_o      = reg_save_isvec       ;
  assign   to_mshr_reg_idxw_o   = reg_save_reg_idxw    ;
  assign   to_mshr_mask_o       = reg_save_mask        ;
  assign   to_mshr_unsigned_o   = reg_save_mem_unsigned;
  assign   to_mshr_iswrite_o    = reg_save_mem_cmd[1]  ;

  genvar k;
  generate for(k=0;k<`NUM_THREAD;k=k+1) begin: MSHR
    assign to_mshr_wordoffset1h_o[`BYTESOFWORD*(k+1)-1:`BYTESOFWORD*k] = wordoffset1h_reg[k] ;
  end
  endgenerate

  //data_next: for writing data
  wire    [`XLEN*`NUM_THREAD-1:0]   data_next            ;
  assign   data_next              = reg_save_in3         ;
  
  //output to shared
  assign   to_shared_valid_o    = (c_state == S_SHARED) ;
  assign   to_shared_instrid_o  = reg_entryid           ;
  assign   to_shared_iswrite_o  = reg_save_mem_cmd[1]   ;
  assign   to_shared_tag_o      = tag                   ;
  assign   to_shared_setidx_o   = setidx                ;
  assign   to_shared_data_o     = data_next             ;

  genvar n;
  generate for(n=0;n<`NUM_THREAD;n=n+1) begin: SHARED
    assign   to_shared_blockoffset_o[`DCACHE_BLOCKOFFSETBITS*(n+1)-1:`DCACHE_BLOCKOFFSETBITS*n] = blockoffset_reg[n] ;
    assign   to_shared_wordoffset1h_o[`BYTESOFWORD*(n+1)-1:`BYTESOFWORD*n]                      = wordoffset1h_reg[n];
    //assign   to_shared_wordoffset1h_o[`BYTESOFWORD*(n+1)-1:`BYTESOFWORD*n]                      = to_shared_activemask_o[n] ? wordoffset1h[n] : 'd0;
    assign   to_shared_activemask_o[n]  = reg_save_mask[n] & same_tag[n] ;
  end
  endgenerate

  //output to dcache
  reg   [2:0] opcode_wire     ;
  reg   [3:0] param_wire      ;
  reg   [3:0] param_wire_alt  ;

  assign to_dcache_valid_o      = (c_state==S_DCACHE) || (c_state==S_DCACHE_1) || (c_state==S_DCACHE_2);
  assign to_dcache_instrid_o    = reg_entryid   ;
  assign to_dcache_setidx_o     = setidx        ;
  assign to_dcache_tag_o        = tag           ;
  assign to_dcache_data_o       = data_next     ;
  
  always@(*) begin
    case(reg_save_alu_fn)
      `FN_SWAP   : param_wire_alt = 4'b1111; //16
      `FN_AMOADD : param_wire_alt = 4'b0000; //0
      `FN_XOR    : param_wire_alt = 4'b0001; //1
      `FN_AND    : param_wire_alt = 4'b0011; //3
      `FN_OR     : param_wire_alt = 4'b0010; //2
      `FN_MIN    : param_wire_alt = 4'b0100; //4
      `FN_MAX    : param_wire_alt = 4'b0101; //5
      `FN_MINU   : param_wire_alt = 4'b0110; //6
      `FN_MAXU   : param_wire_alt = 4'b0111; //7
      default    : param_wire_alt = 4'b0001; //1
    endcase
  end

  always@(*) begin
    if(reg_save_atomic) begin
      if(reg_save_aq && reg_save_rl) begin
        opcode_wire = (c_state==S_DCACHE_2) ? 3'b011 : ((c_state==S_DCACHE_1) ? 3'b010         : 3'b011) ;
        param_wire  = (c_state==S_DCACHE_2) ? 4'b0000: ((c_state==S_DCACHE_1) ? param_wire_alt : 4'b0000);
      end
      else if(reg_save_aq) begin
        opcode_wire = (c_state==S_DCACHE_1) ? 3'b010         : 3'b011 ;
        param_wire  = (c_state==S_DCACHE_1) ? param_wire_alt : 4'b0000;
      end
      else if(reg_save_rl) begin
        opcode_wire = (c_state==S_DCACHE_1) ? 3'b011  : 3'b010         ;
        param_wire  = (c_state==S_DCACHE_1) ? 4'b0000 : param_wire_alt ;
      end
      else begin
        opcode_wire = (reg_save_alu_fn==`FN_ADD) ? reg_save_mem_cmd[1] : 3'b010 ;
        param_wire  = param_wire_alt;
      end
    end
    else if(reg_save_fence) begin
      opcode_wire = 3'b011 ;
      param_wire  = 4'b0000;
    end
    else begin
      opcode_wire = reg_save_mem_cmd[1];
      param_wire  = 4'b0000;
    end
  end

  assign to_dcache_opcode_o = opcode_wire;
  assign to_dcache_param_o  = param_wire ;

  genvar m;
  generate for(m=0;m<`NUM_THREAD;m=m+1) begin: DCACHE
    assign to_dcache_blockoffset_o[`DCACHE_BLOCKOFFSETBITS*(m+1)-1:`DCACHE_BLOCKOFFSETBITS*m] = blockoffset_reg[m] ;
    assign to_dcache_wordoffset1h_o[`BYTESOFWORD*(m+1)-1:`BYTESOFWORD*m]                      = wordoffset1h_reg[m];
    assign to_dcache_activemask_o[m] = reg_save_atomic ? (reg_save_mask[m] && (m==pri_mask_bin)) : (reg_save_mask[m] && same_tag[m]);
  end
  endgenerate

  //mask_next: for update mask
  wire  [`NUM_THREAD-1:0]   mask_next;

  genvar x;
  generate for(x=0;x<`NUM_THREAD;x=x+1) begin: MASK_UPDATE
    assign mask_next[x] = reg_save_atomic ? (reg_save_mask[x] && !(x==pri_mask_bin)) : (reg_save_mask[x] && !same_tag[x]);
  end
  endgenerate

  //fsm state transfer
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      c_state <= 3'b000;
    end
    else begin
      c_state <= n_state;
    end
  end

  always@(*) begin
    case(c_state)
      S_IDLE    :begin
        if(from_fifo_valid_i) begin
          n_state = S_SAVE;
        end
        else begin
          n_state = S_IDLE;
        end
      end
      S_SAVE    :begin
        if(|reg_save_mem_cmd) begin
          if(all_shared) begin
            if(to_mshr_valid_o && to_mshr_ready_i) begin
              n_state = S_SHARED;
            end
            else begin
              n_state = S_SAVE;
            end
          end
          else begin
            if(to_mshr_valid_o && to_mshr_ready_i) begin
              n_state = S_DCACHE;
            end
            else begin
              n_state = S_SAVE;
            end
          end
        end
        else begin
          n_state = S_SAVE;
        end
      end
      S_SHARED  :begin
        if(to_shared_valid_o && to_shared_ready_i) begin
          if(cnt>=`NUM_THREAD || mask_next=='d0) begin
            n_state = S_IDLE;
          end
          else begin
            n_state = S_SHARED;
          end
        end
        else begin
          n_state = S_SHARED;
        end
      end
      S_DCACHE  :begin
        if(to_dcache_valid_o && to_dcache_ready_i) begin
          if(reg_save_atomic && (reg_save_aq || reg_save_rl)) begin
            n_state = S_DCACHE_1;
          end
          else if(cnt>=`NUM_THREAD || mask_next=='d0) begin
            n_state = S_IDLE;
          end
          else begin
            n_state = S_DCACHE;
          end
        end
        else begin
          n_state = S_DCACHE;
        end
      end
      S_DCACHE_1:begin
        if(to_dcache_valid_o && to_dcache_ready_i) begin
          if(reg_save_aq && reg_save_rl) begin
            n_state = S_DCACHE_2;
          end
          else if(cnt>=`NUM_THREAD || mask_next=='d0) begin
            n_state = S_IDLE;
          end
          else begin
            n_state = S_DCACHE;
          end
        end
        else begin
          n_state = S_DCACHE_1;
        end
      end
      S_DCACHE_2:begin
        if(to_dcache_valid_o || to_dcache_ready_i) begin
          if(cnt>=`NUM_THREAD || mask_next=='d0) begin
            n_state = S_IDLE;
          end
          else begin
            n_state = S_DCACHE;
          end
        end
        else begin
          n_state = S_DCACHE_2;
        end
      end
      default   :begin
        n_state = S_IDLE;
      end
    endcase
  end

  //fsm operation: count
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      cnt <= 'b0;
    end
    else begin
      case(c_state)
        S_IDLE    :begin
          cnt <= 'b0;
        end
        S_SHARED  :begin
          if(to_shared_valid_o && to_shared_ready_i) begin
            if(cnt>=`NUM_THREAD || mask_next=='d0) begin
              cnt <= 'b0;
            end
            else begin
              cnt <= cnt + 1'b1;
            end
          end
          else begin
            cnt <= cnt;
          end
        end
        S_DCACHE  :begin
          if(to_dcache_valid_o && to_dcache_ready_i) begin
            if(reg_save_atomic && (reg_save_aq || reg_save_rl)) begin
              cnt <= cnt;
            end
            else if(cnt>=`NUM_THREAD || mask_next=='d0) begin
              cnt <= 'b0;
            end
            else begin
              cnt <= cnt + 1'b1;
            end
          end
          else begin
            cnt <= cnt;
          end
        end
        S_DCACHE_1:begin
          if(to_dcache_valid_o && to_dcache_ready_i) begin
            if(reg_save_aq && reg_save_rl) begin
              cnt <= cnt;
            end
            else if(cnt>=`NUM_THREAD || mask_next=='d0) begin
              cnt <= 'b0;
            end
            else begin
              cnt <= cnt + 1'b1;
            end
          end
          else begin
            cnt <= cnt;
          end
        end
        S_DCACHE_2:begin
          if(to_dcache_valid_o || to_dcache_ready_i) begin
            if(cnt>=`NUM_THREAD || mask_next=='d0) begin
              cnt <= 'b0;
            end
            else begin
              cnt <= cnt + 1'b1;
            end
          end
          else begin
            cnt <= cnt;
          end
        end
        default   :begin
          cnt <= cnt;
        end
      endcase
    end
  end

  //fsm operation: reg_entryid
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      reg_entryid <= 'd0;
    end
    else begin
      if((c_state==S_SAVE) && (|reg_save_mem_cmd) && to_mshr_ready_i && to_mshr_valid_o) begin
        reg_entryid <= idx_entry_i;
      end
      else begin
        reg_entryid <= reg_entryid;
      end
    end
  end

  //fsm operatioin: reg_save
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      //reg_save_in1          <= 'd0 ;
      //reg_save_in2          <= 'd0 ;
      reg_save_in3          <= 'd0 ;
      reg_save_mask         <= 'd0 ;
      reg_save_wid          <= 'd0 ;
      reg_save_isvec        <= 'd0 ;
      reg_save_mem_whb      <= 'd0 ;
      reg_save_mem_unsigned <= 'd0 ;
      reg_save_alu_fn       <= 'd0 ;
      //reg_save_is_vls12     <= 'd0 ;
      //reg_save_disable_mask <= 'd0 ;
      reg_save_mem_cmd      <= 'd0 ;
      //reg_save_mop          <= 'd0 ;
      reg_save_reg_idxw     <= 'd0 ;
      reg_save_wvd          <= 'd0 ;
      reg_save_fence        <= 'd0 ;
      reg_save_wxd          <= 'd0 ;
      reg_save_atomic       <= 'd0 ;
      reg_save_aq           <= 'd0 ;
      reg_save_rl           <= 'd0 ;
    end
    else begin
      case(c_state)
        S_IDLE    : begin
          if(from_fifo_valid_i && from_fifo_ready_o) begin
            //reg_save_in1          <= from_fifo_in1_i          ;
            //reg_save_in2          <= from_fifo_in2_i          ;
            reg_save_in3          <= from_fifo_in3_i          ;
            reg_save_mask         <= from_fifo_mask_i         ;
            reg_save_wid          <= from_fifo_wid_i          ;
            reg_save_isvec        <= from_fifo_isvec_i        ;
            reg_save_mem_whb      <= from_fifo_mem_whb_i      ;
            reg_save_mem_unsigned <= from_fifo_mem_unsigned_i ;
            reg_save_alu_fn       <= from_fifo_alu_fn_i       ;
            //reg_save_is_vls12     <= from_fifo_is_vls12_i     ;
            //reg_save_disable_mask <= from_fifo_disable_mask_i ;
            reg_save_mem_cmd      <= from_fifo_mem_cmd_i      ;
            //reg_save_mop          <= from_fifo_mop_i          ;
            reg_save_reg_idxw     <= from_fifo_reg_idxw_i     ;
            reg_save_wvd          <= from_fifo_wvd_i          ;
            reg_save_fence        <= from_fifo_fence_i        ;
            reg_save_wxd          <= from_fifo_wxd_i          ;
            reg_save_atomic       <= from_fifo_atomic_i       ;
            reg_save_aq           <= from_fifo_aq_i           ;
            reg_save_rl           <= from_fifo_rl_i           ;
          end
          else begin
            //reg_save_in1          <= 'd0 ;
            //reg_save_in2          <= 'd0 ;
            reg_save_in3          <= 'd0 ;
            reg_save_mask         <= 'd0 ;
            reg_save_wid          <= 'd0 ;
            reg_save_isvec        <= 'd0 ;
            reg_save_mem_whb      <= 'd0 ;
            reg_save_mem_unsigned <= 'd0 ;
            reg_save_alu_fn       <= 'd0 ;
            //reg_save_is_vls12     <= 'd0 ;
            //reg_save_disable_mask <= 'd0 ;
            reg_save_mem_cmd      <= 'd0 ;
            //reg_save_mop          <= 'd0 ;
            reg_save_reg_idxw     <= 'd0 ;
            reg_save_wvd          <= 'd0 ;
            reg_save_fence        <= 'd0 ;
            reg_save_wxd          <= 'd0 ;
            reg_save_atomic       <= 'd0 ;
            reg_save_aq           <= 'd0 ;
            reg_save_rl           <= 'd0 ;
          end
        end
        S_SHARED  : begin
          if(to_shared_ready_i && to_shared_valid_o) begin
            reg_save_mask <= mask_next;
          end
          else begin
            reg_save_mask <= reg_save_mask;
          end
        end
        S_DCACHE  : begin
          if(to_dcache_ready_i && to_dcache_valid_o) begin
            reg_save_mask <= mask_next;
          end
          else begin
            reg_save_mask <= reg_save_mask;
          end
        end
        default   : begin
          //reg_save_in1          <= reg_save_in1          ;
          //reg_save_in2          <= reg_save_in2          ;
          reg_save_in3          <= reg_save_in3          ;
          reg_save_mask         <= reg_save_mask         ;
          reg_save_wid          <= reg_save_wid          ;
          reg_save_isvec        <= reg_save_isvec        ;
          reg_save_mem_whb      <= reg_save_mem_whb      ;
          reg_save_mem_unsigned <= reg_save_mem_unsigned ;
          reg_save_alu_fn       <= reg_save_alu_fn       ;
          //reg_save_is_vls12     <= reg_save_is_vls12     ;
          //reg_save_disable_mask <= reg_save_disable_mask ;
          reg_save_mem_cmd      <= reg_save_mem_cmd      ;
          //reg_save_mop          <= reg_save_mop          ;
          reg_save_reg_idxw     <= reg_save_reg_idxw     ;
          reg_save_wvd          <= reg_save_wvd          ;
          reg_save_fence        <= reg_save_fence        ;
          reg_save_wxd          <= reg_save_wxd          ;
          reg_save_atomic       <= reg_save_atomic       ;
          reg_save_aq           <= reg_save_aq           ;
          reg_save_rl           <= reg_save_rl           ;
        end
      endcase
    end
  end

endmodule
