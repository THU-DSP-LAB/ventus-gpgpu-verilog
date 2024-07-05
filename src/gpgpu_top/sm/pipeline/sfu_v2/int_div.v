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
// Description:integer division
`timescale 1ns/1ns
`include "define.v"
module int_div(
  input                                   clk        ,
  input                                   rst_n      ,

  input   [`XLEN-1:0]                     a_i        ,//被除数dividend
  input   [`XLEN-1:0]                     d_i        ,//除数divisor
  input                                   sign_bit   ,

  input                                   in_valid_i ,
  input                                   out_ready_i,

  output                                  in_ready_o ,
  output                                  out_valid_o,

  output  [`XLEN-1:0]                     q_o        ,//商quotient
  output  [`XLEN-1:0]                     r_o         //余数remainder
  );
  parameter IDLE     = 3'b000;
  parameter PRE      = 3'b001;
  parameter COMPUTE  = 3'b010;
  parameter RECOVERY = 3'b011;
  parameter FINISH   = 3'b100;

  reg [2:0] current_state;
  reg [2:0] next_state;

  wire                                    a_sign         ;
  wire                                    d_sign         ;
  reg                                     q_sign_reg     ;
  reg                                     r_sign_reg     ;
  wire  [`XLEN-1:0]                       unsigned_a     ;
  wire  [`XLEN-1:0]                       unsigned_d     ;
  wire  [`XLEN-2:0]                       a_without_sign ;
  wire                                    overflow       ;
  wire                                    div_by_zero    ;
  reg   [`XLEN-1:0]                       raw_a_reg      ;
  reg   [`XLEN-1:0]                       unsigned_a_reg ;
  reg   [`XLEN-1:0]                       unsigned_d_reg ;
  reg                                     overflow_reg   ;
  reg                                     div_by_zero_reg;

  //pre phase
  wire  [$clog2(`XLEN)-1:0]               a_lez     ;
  wire  [$clog2(`XLEN)-1:0]               d_lez     ;
  wire  [$clog2(`XLEN)-1:0]               iter      ;
  reg   [`XLEN+1:0]                       a_reg     ;
  reg   [`XLEN+1:0]                       d_reg     ;
  wire  [`XLEN+1:0]                       a_norm    ;
  wire  [`XLEN+1:0]                       d_norm    ;
  wire  [`XLEN+1:0]                       d_neg_norm;
  reg   [$clog2(`XLEN)-1:0]               iter_reg  ;
  reg                                     zero_q_reg;

  //compute phase
  reg   [$clog2(`XLEN+1)-1:0]             cnt       ;
  reg   [$clog2(`XLEN+1)-1:0]             cnt_next  ;
  reg   [`XLEN-1:0]                       q         ;
  reg   [`XLEN-1:0]                       qn        ;
  wire                                    sel_pos   ;
  wire                                    sel_neg   ;
  wire  [`XLEN+1:0]                       a_shift   ;
  wire  [`XLEN+1:0]                       a_next    ;

  //recovery phase
  wire                                    rem_is_neg  ;
  wire  [`XLEN-1:0]                       common_q    ;
  wire  [`XLEN-1:0]                       common_r    ;
  reg   [`XLEN-1:0]                       common_q_reg;
  reg   [`XLEN-1:0]                       common_r_reg;
  wire  [`XLEN-1:0]                       recovery_r  ;

  //finish phase
  wire  [`XLEN-1:0]                       signed_q    ;
  wire  [`XLEN-1:0]                       signed_r    ;
  wire  [`XLEN-1:0]                       special_q   ;
  wire  [`XLEN-1:0]                       special_r   ;
  
  assign  a_sign         = sign_bit & a_i[`XLEN-1];
  assign  d_sign         = sign_bit & d_i[`XLEN-1];
  assign  unsigned_a     = a_sign ? (~a_i+1) : a_i;
  assign  unsigned_d     = d_sign ? (~d_i+1) : d_i;
  assign  a_without_sign = a_i[`XLEN-2:0];
  assign  overflow       = sign_bit & a_i[`XLEN-1] & !(|a_without_sign) & (&d_i);
  assign  div_by_zero    = d_i == 'd0;

  //状态跳转
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      current_state <= IDLE;
    end
    else begin
      current_state <= next_state;
    end
  end

  //商和余数的符号
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      q_sign_reg      <= 'd0;
      r_sign_reg      <= 'd0;
      raw_a_reg       <= 'd0;
      unsigned_a_reg  <= 'd0;
      unsigned_d_reg  <= 'd0;
      overflow_reg    <= 'd0;
      div_by_zero_reg <= 'd0;
    end
    else if(in_valid_i & in_ready_o) begin
      q_sign_reg      <= a_sign ^ d_sign;
      r_sign_reg      <= a_sign         ;
      raw_a_reg       <= a_i            ;
      unsigned_a_reg  <= unsigned_a     ;
      unsigned_d_reg  <= unsigned_d     ;
      overflow_reg    <= overflow       ;
      div_by_zero_reg <= div_by_zero    ;
    end
    else begin
      q_sign_reg      <= q_sign_reg     ;
      r_sign_reg      <= r_sign_reg     ;
      raw_a_reg       <= raw_a_reg      ;
      unsigned_a_reg  <= unsigned_a_reg ;
      unsigned_d_reg  <= unsigned_d_reg ;
      overflow_reg    <= overflow_reg   ;
      div_by_zero_reg <= div_by_zero_reg;
    end
  end

  //pre phase
  find_first #(.DATA_WIDTH(`XLEN),
               .DATA_DEPTH($clog2(`XLEN)))
               U_find_first_a(
                              .data_i(unsigned_a_reg),
                              .target(1'b1          ),
                              .data_o(a_lez         )
                             );

  find_first #(.DATA_WIDTH(`XLEN),
               .DATA_DEPTH($clog2(`XLEN)))
               U_find_first_d(
                              .data_i(unsigned_d_reg),
                              .target(1'b1          ),
                              .data_o(d_lez         )
                             );

  assign  iter       = (a_lez > d_lez) ? 'd0 : (d_lez - a_lez + 1);
  assign  a_norm     = {2'd0,(unsigned_a_reg<<a_lez)};
  assign  d_norm     = {1'b0,(unsigned_d_reg<<d_lez),1'b0};
  assign  d_neg_norm = {1'b1,((~unsigned_d_reg+1)<<d_lez),1'b0};

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      iter_reg   <= 'd0;
      zero_q_reg <= 'd0;
    end
    else if(current_state == PRE) begin
      iter_reg   <= iter                             ;
      zero_q_reg <= (unsigned_a_reg < unsigned_d_reg);
    end
    else begin
      iter_reg   <= iter_reg  ;
      zero_q_reg <= zero_q_reg;
    end
  end

  //compute phase
  //assign  cnt_next = (cnt == 'd0) ? 'd0 : (cnt - 1);
  always@(*) begin
   if(cnt == 'd0) begin
    cnt_next = 'd0;
   end
   else begin
    cnt_next = cnt - 1;
   end
  end
  
  assign  sel_pos  = a_reg[`XLEN:`XLEN-1] == 2'b01;
  assign  sel_neg  = a_reg[`XLEN:`XLEN-1] == 2'b10;
  assign  a_shift  = a_reg << 1;
  assign  a_next   = sel_pos ? a_shift + d_neg_norm : (sel_neg ? (a_shift + d_norm) : a_shift);

  //recovery phase
  assign  rem_is_neg = a_reg[`XLEN+1];
  assign  recovery_r = rem_is_neg ? a_reg[`XLEN:1] + d_reg[`XLEN:1] : a_reg[`XLEN:1];
  assign  common_q   = rem_is_neg ? (q + ~qn) : (q - qn);
  assign  common_r   = recovery_r >> d_lez;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      common_q_reg <= 'd0;
      common_r_reg <= 'd0;
    end
    else if(current_state == RECOVERY) begin
      common_q_reg <= common_q;
      common_r_reg <= common_r;
    end
    else begin
      common_q_reg <= common_q_reg;
      common_r_reg <= common_r_reg;
    end
  end

  //finish phase
  assign  signed_q  = q_sign_reg ? (~common_q_reg + 1) : common_q_reg;
  assign  signed_r  = r_sign_reg ? (~common_r_reg + 1) : common_r_reg;
  assign  special_q = div_by_zero_reg ? 32'hffff_ffff : (overflow_reg ? {1'b1,{(`XLEN-1){1'b0}}} : 'd0);
  assign  special_r = (div_by_zero_reg | zero_q_reg) ? raw_a_reg : 'd0;

  assign  q_o = (div_by_zero_reg | zero_q_reg | overflow_reg) ? special_q : signed_q;
  assign  r_o = (div_by_zero_reg | zero_q_reg | overflow_reg) ? special_r : signed_r; 
  assign  out_valid_o = current_state == FINISH;
  assign  in_ready_o  = current_state == IDLE;

  //FSM
  always@(*) begin
    case(current_state)
      IDLE     : begin
        if(in_valid_i & in_ready_o) begin
          if(overflow | div_by_zero) begin
            next_state = FINISH;
          end
          else begin
            next_state = PRE;
          end
        end
        else begin
          next_state = IDLE;
        end
      end

      PRE      : begin
        if(unsigned_a_reg < unsigned_d_reg) begin
          next_state = FINISH;
        end
        else begin
          next_state = COMPUTE;
        end
      end

      COMPUTE  : begin
        if(cnt_next != 'd0) begin
          next_state = COMPUTE;
        end
        else begin
          next_state = RECOVERY;
        end
      end

      RECOVERY : begin
        next_state = FINISH;
      end

      FINISH   : begin
        if(out_ready_i & out_valid_o) begin
          next_state = IDLE;
        end
        else begin
          next_state = FINISH;
        end
      end

      default  : next_state = IDLE;
    endcase
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      a_reg <= 'd0;
      d_reg <= 'd0;
      cnt   <= 'd0;
      q     <= 'd0;
      qn    <= 'd0;
    end
    else begin
      case(current_state)
        IDLE    : begin
          a_reg <= 'd0;
          d_reg <= 'd0;
          cnt   <= 'd0;
        end
        PRE     : begin
          if(unsigned_a_reg < unsigned_d_reg) begin
            cnt <= 'd0;
          end
          else begin
            a_reg <= a_norm;
            d_reg <= d_norm;
            cnt   <= iter  ;
            q     <= 'd0   ;
            qn    <= 'd0   ;
          end
        end
        COMPUTE : begin
          cnt   <= cnt_next;
          a_reg <= a_next  ;
          q     <= {q[`XLEN-2:0],sel_pos};
          qn    <= {qn[`XLEN-2:0],sel_neg};
        end
        RECOVERY: begin
          cnt   <= 'd0     ;
        end
        FINISH  : begin
          cnt   <= 'd0     ;
        end
        default : begin
          a_reg <= 'd0   ;
          d_reg <= 'd0   ;
          cnt   <= 'd0   ;
          q     <= 'd0   ;
          qn    <= 'd0   ;
        end
      endcase
    end
  end

endmodule
  




