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
// Description:least recently used replacement policy(matrix implementation),ouput in next cycle
`include "define.v"

`timescale 1ns/1ps

module lru_matrix #(
  parameter  NUM_WAY      = 4,         // number way of one set    
  parameter  WAY_DEPTH    = 2
  )
  (
  input                  clk               ,
  input                  rst_n             ,
  
  input                  update_entry_i    , // input update condition
  input  [WAY_DEPTH-1:0] update_index_i    , // input update wayId
  output [WAY_DEPTH-1:0] lru_index_o         // output replacement wayId
  );

  //reg   [NUM_WAY*NUM_WAY-1:0] matrix             ; // matrix[row(i), ,row(1),row(0)]
  reg   [NUM_WAY*NUM_WAY-1:0] matrix_nxt         ;
  reg   [NUM_WAY-1:0]         lru_index_nxt      ;
  wire  [NUM_WAY-1:0]         lru_index_nxt_oh   ;
  wire  [WAY_DEPTH-1:0]       lru_index_nxt_bin  ;

  //reset all unit of matrix to zero
  //always@(posedge clk or negedge rst_n) begin
  //  if(!rst_n) begin
  //      matrix <= {NUM_WAY*NUM_WAY{1'b0}}   ;
  //  end else begin
  //      matrix <= matrix_nxt                ;
  //  end
  //end
  
  //when update_index put in as i, then matrix[j] = {NUM_WAY{1'b1}}, matrix[j][k] = 1'b0
  //genvar i,j,k;
  genvar j,k;
  generate
    for(j=0; j<NUM_WAY; j=j+1) begin:row_loop

      always@(*) begin
        //if(!rst_n) begin
          //lru_index_nxt     = {NUM_WAY{1'b0}}   ;
        //end else if (matrix_nxt[NUM_WAY*(i+1)-1-:NUM_WAY] == {NUM_WAY{1'b0}})begin
        if (matrix_nxt[NUM_WAY*(j+1)-1-:NUM_WAY] == {NUM_WAY{1'b0}})begin
          lru_index_nxt[j]  = 1'b1;
        end else begin
          lru_index_nxt[j]  = 1'b0;
        end
      end

      for(k=0; k<NUM_WAY; k=k+1) begin:column_loop
        always@(posedge clk or negedge rst_n) begin
        //always@(*) begin
            //matrix_nxt = matrix ;
          if(!rst_n) begin
              matrix_nxt[NUM_WAY*j+k] <= 1'b0;
          end else if(update_entry_i && k==update_index_i) begin
              matrix_nxt[NUM_WAY*j+k] <= 1'b0 ;
          end else if(update_entry_i && j==update_index_i) begin
              matrix_nxt[NUM_WAY*j+k] <= 1'b1 ;
          end
        end
      end

    end
  endgenerate

  //output the lru_index
  //generate
  //  for(i=0; i<NUM_WAY; i=i+1) begin:output_loop
  //    always@(*) begin
  //      //if(!rst_n) begin
  //        //lru_index_nxt     = {NUM_WAY{1'b0}}   ;
  //      //end else if (matrix_nxt[NUM_WAY*(i+1)-1-:NUM_WAY] == {NUM_WAY{1'b0}})begin
  //      if (matrix_nxt[NUM_WAY*(i+1)-1-:NUM_WAY] == {NUM_WAY{1'b0}})begin
  //        lru_index_nxt[i]  = 1'b1              ;
  //      end else begin
  //        lru_index_nxt[i]  = {NUM_WAY{1'b0}}   ;
  //      end
  //    end
  //  end
  //endgenerate
  

  //always@(posedge clk or negedge rst_n)begin
  //always@(*)begin
  //    if(!rst_n) begin
  //        lru_index_o = {WAY_DEPTH{1'b0}};
  //    end else begin
  //        lru_index_o = lru_index_nxt_bin;
  //    end
  //end
  assign lru_index_o = lru_index_nxt_bin;

  fixed_pri_arb #(
    .ARB_WIDTH(NUM_WAY)
  )
  U_fixed_pri_arb
  (
    .req  (lru_index_nxt        ),
    .grant(lru_index_nxt_oh     )
  );

  one2bin #(
    .ONE_WIDTH(NUM_WAY),
    .BIN_WIDTH(WAY_DEPTH)
  )
  U_one2bin
  (
    .oh(lru_index_nxt_oh      ),
    .bin(lru_index_nxt_bin    )    
  );

endmodule
