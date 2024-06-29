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
// Description:根据输入的op判断二进制数是否有符号，并且分情况对二进制数进行前导零预测，然后移位使得最高位为1，去掉最高位即为浮点数的尾数
module int_to_fp_prenorm(
  input   [63:0]                int_i     ,
  input                         sign_i    ,
  input                         long_i    ,
  output  [62:0]                norm_int_o,
  output  [5:0]                 lzc_o     ,
  output                        is_zero_o ,
  output                        sign_o    
  );

  wire                          in_sign     ;
  wire    [63:0]                in_sext     ;
  wire    [63:0]                in_raw      ;
  wire    [63:0]                in_abs      ;
  wire    [63:0]                lza_b       ;

  wire    [63:0]                lza_out     ;

  wire    [63:0]                one_mask    ;
  wire    [5:0]                 pos_lzc     ;
  wire    [5:0]                 neg_lzc     ;
  wire    [5:0]                 lzc         ;
  wire                          lzc_error   ;
  wire    [63:0]                in_shift    ;
  wire    [62:0]                in_shift_s1 ;
  wire    [62:0]                in_norm     ;

  assign in_sign = sign_i && (long_i ? int_i[63] : int_i[31]);
  assign in_sext = {{32{int_i[31]}},int_i[31:0]}             ;
  assign in_raw  = (sign_i && !long_i) ? in_sext : int_i     ;
  assign in_abs  = in_sign ? (~in_raw + 1) : in_raw          ;
  assign lza_b   = ~in_raw                                   ;

  //例化lza
  lza #(
    .LEN(64)
  )
  U_lza (
    .a(64'd0  ),
    .b(lza_b  ),
    .c(lza_out)
    );

  //例化clz,找到最高位的1的位置
  /*clz #(
    .LEN(64)
  )
  U_clz_1 (
    .in (int_i  ),
    .out(pos_lzc)
    );

  clz #(
    .LEN(64)
  )
  U_clz_2 (
    .in (lza_out),
    .out(neg_lzc)
    );*/
  wire lzc_zero_1;
  wire lzc_zero_2;

  lzc #(
    .WIDTH     (64  ),
    .MODE      (1'b1),
    .CNT_WIDTH (6   )
  )
  for_lzc_1 (
    .in_i    (int_i     ),
    .cnt_o   (pos_lzc   ),
    .empty_o (lzc_zero_1)
  );

  lzc #(
    .WIDTH     (64  ),
    .MODE      (1'b1),
    .CNT_WIDTH (6   )
  )
  for_lzc_2 (
    .in_i    (lza_out   ),
    .cnt_o   (neg_lzc   ),
    .empty_o (lzc_zero_2)
  );

  assign lzc = in_sign ? neg_lzc : pos_lzc;

  genvar j;
  generate
    for(j=62;j>=1;j=j-1) begin:mask
      /*always@(*) begin
        if(j==63) begin
          one_mask[j] = lza_out[63];
        end
        else if(j==0) begin
          one_mask[j] = !(|lza_out[63:1]);
        end
        else begin
          one_mask[j] = lza_out[j] && !(|lza_out[63:j+1]);
        end
      end*/
      assign one_mask[j] = lza_out[j] && !(|lza_out[63:j+1]);
    end
  endgenerate

  assign one_mask[0]  = !(|lza_out[63:1]);
  assign one_mask[63] = lza_out[63];

  assign lzc_error   = in_sign ? (!(|(in_abs & one_mask))) : 1'b0        ;
  assign in_shift    = in_abs << lzc                                     ;
  assign in_shift_s1 = in_shift[62:0]                                    ;
  assign in_norm     = lzc_error ? {in_shift_s1[61:0],1'b0} : in_shift_s1;    

  //output
  assign norm_int_o  = in_norm        ;
  assign lzc_o       = lzc + lzc_error;
  assign is_zero_o   = int_i == 'd0   ;
  assign sign_o      = in_sign        ;

endmodule



