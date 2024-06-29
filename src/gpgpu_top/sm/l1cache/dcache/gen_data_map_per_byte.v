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
// Author: Chen, Qixiang
// Description:

`timescale 1ns/1ps

module gen_data_map_per_byte #(
  parameter DATA_NUM    = 4   ,
  parameter DATA_WIDTH  = 32
)
(
  input       [DATA_WIDTH*DATA_NUM-1:0]   data_i        ,
  input       [4*DATA_NUM-1:0]            mask_i        ,
  output reg  [DATA_WIDTH*DATA_NUM-1:0]   data_o         
);

  //wire  [2*DATA_NUM-1:0]            mask_bin;
  //wire  [3*DATA_NUM-1:0]            mask_pop_count;

  genvar i;
  generate
    for(i=0; i<DATA_NUM; i=i+1) begin:output_loop
      always@(*) begin
        if(&mask_i[4*(i+1)-1-:4]) begin //  1111
          data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = data_i[DATA_WIDTH*(i+1)-1-:DATA_WIDTH];
        //end else if(mask_pop_count[3*(i+1)-1-:3]==3'h1) begin //  0001 0010 0100 1000
          //data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = data_i[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] >> ((mask_bin[2*(i+1)-1-:2]) << 3);
          //data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = data_i[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] >> {mask_bin[2*(i+1)-1-:2],3'b0};
          //data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = {data_i[DATA_WIDTH*i+DATA_WIDTH/4*(mask_bin[2*(i+1)-1-:2]+1)-1-:DATA_WIDTH/4],{mask_bin[2*(i+1)-1-:2]{8'b0}}};

        /*
        end else if(mask_i[4*(i+1)-1-:4]==4'b0001) begin  //  0001
          data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = {24'b0,data_i[DATA_WIDTH*i+DATA_WIDTH/4-1-:DATA_WIDTH/4]};
        end else if(mask_i[4*(i+1)-1-:4]==4'b0010) begin  //  0010
          data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = {16'b0,data_i[DATA_WIDTH*i+DATA_WIDTH/4*2-1-:DATA_WIDTH/4],8'b0};
        end else if(mask_i[4*(i+1)-1-:4]==4'b0100) begin  //  0100
          data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = {8'b0,data_i[DATA_WIDTH*i+DATA_WIDTH/4*3-1-:DATA_WIDTH/4],16'b0};
        end else if(mask_i[4*(i+1)-1-:4]==4'b1000) begin  //  1000
          data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = {data_i[DATA_WIDTH*i+DATA_WIDTH/4*4-1-:DATA_WIDTH/4],24'b0};
        end else if(mask_i[4*(i+1)-1-:4]==4'b1100) begin  //  1100
          //data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = data_i[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] >> 16;
          data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = {data_i[DATA_WIDTH*(i+1)-1-:DATA_WIDTH/2],{DATA_WIDTH/2{1'b0}}};
        end else if(mask_i[4*(i+1)-1-:4]==4'b0011) begin  //  0011
          data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = {{DATA_WIDTH/2{1'b0}},data_i[DATA_WIDTH*i+DATA_WIDTH/2-1-:DATA_WIDTH/2]};
        end else begin
          //data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = data_i[DATA_WIDTH*(i+1)-1-:DATA_WIDTH];
          data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = {DATA_WIDTH{1'b0}};
        end
        */

        end else if(mask_i[4*(i+1)-1-:4]==4'b0001) begin  //  0001
          data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = {24'b0,data_i[DATA_WIDTH*i+DATA_WIDTH/4-1-:DATA_WIDTH/4]};
        end else if(mask_i[4*(i+1)-1-:4]==4'b0010) begin  //  0010
          data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = {16'b0,data_i[DATA_WIDTH*i+DATA_WIDTH/4-1-:DATA_WIDTH/4],8'b0};
        end else if(mask_i[4*(i+1)-1-:4]==4'b0100) begin  //  0100
          data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = {8'b0,data_i[DATA_WIDTH*i+DATA_WIDTH/4-1-:DATA_WIDTH/4],16'b0};
        end else if(mask_i[4*(i+1)-1-:4]==4'b1000) begin  //  1000
          data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = {data_i[DATA_WIDTH*i+DATA_WIDTH/4-1-:DATA_WIDTH/4],24'b0};
        end else if(mask_i[4*(i+1)-1-:4]==4'b1100) begin  //  1100
          //data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = data_i[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] >> 16;
          data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = {data_i[DATA_WIDTH*i+DATA_WIDTH/2-1-:DATA_WIDTH/2],{DATA_WIDTH/2{1'b0}}};
        end else if(mask_i[4*(i+1)-1-:4]==4'b0011) begin  //  0011
          data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = {{DATA_WIDTH/2{1'b0}},data_i[DATA_WIDTH*i+DATA_WIDTH/2-1-:DATA_WIDTH/2]};
        end else begin
          //data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = data_i[DATA_WIDTH*(i+1)-1-:DATA_WIDTH];
          data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = {DATA_WIDTH{1'b0}};
        end
      end
    end
  endgenerate

  /*
  genvar j;
  generate
    for(j=0; j<DATA_NUM; j=j+1) begin:mask_loop
      pop_cnt #(
        .DATA_LEN (4),
        .DATA_WID (3)
      )
      U_pop_cnt
      (
        .data_i(mask_i        [4*(j+1)-1-:4]),
        .data_o(mask_pop_count[3*(j+1)-1-:3]) 
      );

      one2bin #(
        .ONE_WIDTH(4),
        .BIN_WIDTH(2)
      )
      U_one2bin
      (
        .oh (mask_i   [4*(j+1)-1-:4]   ),
        .bin(mask_bin [2*(j+1)-1-:2]   )    
      );
    end
  endgenerate
  */

endmodule
