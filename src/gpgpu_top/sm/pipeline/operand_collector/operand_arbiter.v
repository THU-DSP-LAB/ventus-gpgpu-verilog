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
`include "define.v"
//`include "IDecode_define.v"

`timescale 1ns/1ps

// Arbitrating which reading (TO DO: writing) request should be send to register files
module operand_arbiter(
  input                                                 clk                       ,
  input                                                 rst_n                     ,

  // input interface
  input  [4*`NUM_COLLECTORUNIT-1:0]                     arbiter_valid_i           ,
  input  [`DEPTH_BANK*4*`NUM_COLLECTORUNIT-1:0]         arbiter_bankID_i          , // arbiter_bankID_i[ID(7)(3),ID(7)(2),ID(7)(1),ID(7)(0),ID(6)(3)...ID(0)(1),ID(0)(0)]
  input  [2*4*`NUM_COLLECTORUNIT-1:0]                   arbiter_rsType_i          , // rsType(num_collector)(num_operand)
  input  [`DEPTH_REGBANK*4*`NUM_COLLECTORUNIT-1:0]      arbiter_rsAddr_i          ,
  
  // output interface
  output  [`NUM_BANK-1:0]                               scalar_valid_o            ,
  //input   [`NUM_BANK-1:0]                               scalar_ready_i            ,
  //output  [`DEPTH_BANK*`NUM_BANK-1:0]                   scalar_bankID_o           , // scalar_bankID_o[ID(3),ID(2),ID(1),ID(0)]
  //output  [2*`NUM_BANK-1:0]                             scalar_rsType_o           , // ID(num_bank)
  output  [`DEPTH_REGBANK*`NUM_BANK-1:0]                scalar_rsAddr_o           ,

  output  [`NUM_BANK-1:0]                               vector_valid_o            ,
  //input   [`NUM_BANK-1:0]                               vector_ready_i            ,
  //output  [`DEPTH_BANK*`NUM_BANK-1:0]                   vector_bankID_o           ,
  //output  [2*`NUM_BANK-1:0]                             vector_rsType_o           ,
  output  [`DEPTH_REGBANK*`NUM_BANK-1:0]                vector_rsAddr_o           ,
  
  output  [$clog2(4*`NUM_COLLECTORUNIT)*`NUM_BANK-1:0]  chosen_scalar_o           , // chosen_scalar_o[chosen(3),chosen(2),chosen(1),chosen(0)]
  output  [$clog2(4*`NUM_COLLECTORUNIT)*`NUM_BANK-1:0]  chosen_vector_o             // chosen(num_bank)
);

  parameter DEPTH_4_COLLECTORUNIT = $clog2(4*`NUM_COLLECTORUNIT);

  //wire [`DEPTH_BANK*4*`NUM_COLLECTORUNIT*`NUM_BANK-1:0]         arbiter_scalar_bankID_in          ; // arbiter_scalar_bankID_in[bank(3),bank(2),bank(1),bank(0)],bank(i) have 4*`NUM_COLLECTORUNIT bankID
  //wire [2*4*`NUM_COLLECTORUNIT*`NUM_BANK-1:0]                   arbiter_scalar_rsType_in          ;
  wire [`DEPTH_REGBANK*4*`NUM_COLLECTORUNIT*`NUM_BANK-1:0]      arbiter_scalar_rsAddr_in          ;  
  wire [4*`NUM_COLLECTORUNIT*`NUM_BANK-1:0]                     arbiter_scalar_valid_in           ;  
  //wire [4*`NUM_COLLECTORUNIT*`NUM_BANK-1:0]                     arbiter_scalar_ready_in           ;
  //wire [`DEPTH_BANK*`NUM_BANK-1:0]                              arbiter_scalar_bankID_out         ; // arbiter_scalar_bankID_out[bank(3),bank(2),bank(1),bank(0)],bank(i) have one bankID
  //wire [2*`NUM_BANK-1:0]                                        arbiter_scalar_rsType_out         ;
  wire [`DEPTH_REGBANK*`NUM_BANK-1:0]                           arbiter_scalar_rsAddr_out         ;
  wire [`NUM_BANK-1:0]                                          arbiter_scalar_valid_out          ;
  //wire [`NUM_BANK-1:0]                                          arbiter_scalar_ready_out          ;
  wire [DEPTH_4_COLLECTORUNIT*`NUM_BANK-1:0]                    arbiter_scalar_chosen             ;

  //wire [`DEPTH_BANK*4*`NUM_COLLECTORUNIT*`NUM_BANK-1:0]         arbiter_vector_bankID_in          ;
  //wire [2*4*`NUM_COLLECTORUNIT*`NUM_BANK-1:0]                   arbiter_vector_rsType_in          ;
  wire [`DEPTH_REGBANK*4*`NUM_COLLECTORUNIT*`NUM_BANK-1:0]      arbiter_vector_rsAddr_in          ;
  wire [4*`NUM_COLLECTORUNIT*`NUM_BANK-1:0]                     arbiter_vector_valid_in           ;
  //wire [4*`NUM_COLLECTORUNIT*`NUM_BANK-1:0]                     arbiter_vector_ready_in           ;
  //wire [`DEPTH_BANK*`NUM_BANK-1:0]                              arbiter_vector_bankID_out         ;
  //wire [2*`NUM_BANK-1:0]                                        arbiter_vector_rsType_out         ;
  wire [`DEPTH_REGBANK*`NUM_BANK-1:0]                           arbiter_vector_rsAddr_out         ;
  wire [`NUM_BANK-1:0]                                          arbiter_vector_valid_out          ;
  //wire [`NUM_BANK-1:0]                                          arbiter_vector_ready_out          ;
  wire [DEPTH_4_COLLECTORUNIT*`NUM_BANK-1:0]                    arbiter_vector_chosen             ;

  wire [4*`NUM_COLLECTORUNIT*`NUM_BANK-1:0]                     arbiter_scalar_valid_oh           ;
  wire [4*`NUM_COLLECTORUNIT*`NUM_BANK-1:0]                     arbiter_vector_valid_oh           ;

  //wire [`DEPTH_BANK*4*`NUM_COLLECTORUNIT*`NUM_BANK-1:0]         arbiter_scalar_bankID_out_oh      ; 
  //wire [2*4*`NUM_COLLECTORUNIT*`NUM_BANK-1:0]                   arbiter_scalar_rsType_out_oh      ;
  wire [`DEPTH_REGBANK*4*`NUM_COLLECTORUNIT*`NUM_BANK-1:0]      arbiter_scalar_rsAddr_out_oh      ;
  //wire [`DEPTH_BANK*4*`NUM_COLLECTORUNIT*`NUM_BANK-1:0]         arbiter_vector_bankID_out_oh      ; 
  //wire [2*4*`NUM_COLLECTORUNIT*`NUM_BANK-1:0]                   arbiter_vector_rsType_out_oh      ;
  wire [`DEPTH_REGBANK*4*`NUM_COLLECTORUNIT*`NUM_BANK-1:0]      arbiter_vector_rsAddr_out_oh      ;
  
  // arbiter input_num:4*`NUM_COLLECTORUNIT, ouput_num:one
  // mapping input signals from collector units to inputs of Arbiters
  genvar n;
  generate
    for (n=0; n<`NUM_BANK; n=n+1) begin:bank_loop_1
      //assign arbiter_scalar_bankID_in[`DEPTH_BANK*4*`NUM_COLLECTORUNIT*(n+1)-1-:`DEPTH_BANK*4*`NUM_COLLECTORUNIT]               = arbiter_bankID_i;
      //assign arbiter_scalar_rsType_in[2*4*`NUM_COLLECTORUNIT*(n+1)-1-:2*4*`NUM_COLLECTORUNIT]                                   = arbiter_rsType_i;
      assign arbiter_scalar_rsAddr_in[`DEPTH_REGBANK*4*`NUM_COLLECTORUNIT*(n+1)-1-:`DEPTH_REGBANK*4*`NUM_COLLECTORUNIT]         = arbiter_rsAddr_i;
      //assign arbiter_vector_bankID_in[`DEPTH_BANK*4*`NUM_COLLECTORUNIT*(n+1)-1-:`DEPTH_BANK*4*`NUM_COLLECTORUNIT]               = arbiter_bankID_i;
      //assign arbiter_vector_rsType_in[2*4*`NUM_COLLECTORUNIT*(n+1)-1-:2*4*`NUM_COLLECTORUNIT]                                   = arbiter_rsType_i;
      assign arbiter_vector_rsAddr_in[`DEPTH_REGBANK*4*`NUM_COLLECTORUNIT*(n+1)-1-:`DEPTH_REGBANK*4*`NUM_COLLECTORUNIT]         = arbiter_rsAddr_i;

      assign arbiter_scalar_valid_out[n] = |arbiter_scalar_valid_in[4*`NUM_COLLECTORUNIT*(n+1)-1-:4*`NUM_COLLECTORUNIT]; 
      assign arbiter_vector_valid_out[n] = |arbiter_vector_valid_in[4*`NUM_COLLECTORUNIT*(n+1)-1-:4*`NUM_COLLECTORUNIT]; 

      //assign  arbiter_scalar_bankID_out[`DEPTH_BANK*(n+1)-1-:`DEPTH_BANK] = 
      //        arbiter_scalar_bankID_out_oh[`DEPTH_BANK*4*`NUM_COLLECTORUNIT*n+(arbiter_scalar_chosen[DEPTH_4_COLLECTORUNIT*(n+1)-1-:DEPTH_4_COLLECTORUNIT]+1)*`DEPTH_BANK-1-:`DEPTH_BANK];
      
      //assign  arbiter_scalar_rsType_out[2*(n+1)-1-:2] = 
      //        arbiter_scalar_rsType_out_oh[2*4*`NUM_COLLECTORUNIT*n+(arbiter_scalar_chosen[DEPTH_4_COLLECTORUNIT*(n+1)-1-:DEPTH_4_COLLECTORUNIT]+1)*2-1-:2];
      
      assign  arbiter_scalar_rsAddr_out[`DEPTH_REGBANK*(n+1)-1-:`DEPTH_REGBANK] = 
              arbiter_scalar_rsAddr_out_oh[`DEPTH_REGBANK*4*`NUM_COLLECTORUNIT*n+(arbiter_scalar_chosen[DEPTH_4_COLLECTORUNIT*(n+1)-1-:DEPTH_4_COLLECTORUNIT]+1)*`DEPTH_REGBANK-1-:`DEPTH_REGBANK];
      
      //assign  arbiter_vector_bankID_out[`DEPTH_BANK*(n+1)-1-:`DEPTH_BANK] = 
      //        arbiter_vector_bankID_out_oh[`DEPTH_BANK*4*`NUM_COLLECTORUNIT*n+(arbiter_vector_chosen[DEPTH_4_COLLECTORUNIT*(n+1)-1-:DEPTH_4_COLLECTORUNIT]+1)*`DEPTH_BANK-1-:`DEPTH_BANK];
      
      //assign  arbiter_vector_rsType_out[2*(n+1)-1-:2] = 
      //        arbiter_vector_rsType_out_oh[2*4*`NUM_COLLECTORUNIT*n+(arbiter_vector_chosen[DEPTH_4_COLLECTORUNIT*(n+1)-1-:DEPTH_4_COLLECTORUNIT]+1)*2-1-:2];
      
      assign  arbiter_vector_rsAddr_out[`DEPTH_REGBANK*(n+1)-1-:`DEPTH_REGBANK] = 
              arbiter_vector_rsAddr_out_oh[`DEPTH_REGBANK*4*`NUM_COLLECTORUNIT*n+(arbiter_vector_chosen[DEPTH_4_COLLECTORUNIT*(n+1)-1-:DEPTH_4_COLLECTORUNIT]+1)*`DEPTH_REGBANK-1-:`DEPTH_REGBANK];
    end
  endgenerate
  
  // elaborate valid port of readArbiters  
  genvar i,j,k;
  generate
    for (i=0; i<`NUM_BANK; i=i+1) begin:bank_loop_2
      for (j=0; j<`NUM_COLLECTORUNIT; j=j+1) begin:collector_unit_loop_2
        for (k=0; k<4; k=k+1) begin:operand_loop_2
          assign arbiter_scalar_valid_in[4*`NUM_COLLECTORUNIT*i+j*4+k] = arbiter_valid_i[j*4+k] && (arbiter_bankID_i[(j*4+k+1)*`DEPTH_BANK-1-:`DEPTH_BANK]==i)
                                                                          && (arbiter_rsType_i[(j*4+k+1)*2-1-:2]==2'b01);
          assign arbiter_vector_valid_in[4*`NUM_COLLECTORUNIT*i+j*4+k] = arbiter_valid_i[j*4+k] && (arbiter_bankID_i[(j*4+k+1)*`DEPTH_BANK-1-:`DEPTH_BANK]==i)
                                                                          && (arbiter_rsType_i[(j*4+k+1)*2-1-:2]==2'b10 || arbiter_rsType_i[(j*4+k+1)*2-1-:2]==2'b00);

          //assign arbiter_vector_valid_in[4*`NUM_COLLECTORUNIT*i+j*4+k] = arbiter_valid_i[j*4+k] && (arbiter_bankID_i[(j*4+k+1)*`DEPTH_BANK-1-:`DEPTH_BANK]==i)
          //                                                                && (arbiter_rsType_i[(j*4+k+1)*2-1-:2]==2'b00);
          //assign arbiter_scalar_bankID_out_oh[`DEPTH_BANK*4*`NUM_COLLECTORUNIT*i+(j*4+k+1)*`DEPTH_BANK-1-:`DEPTH_BANK] = 
          //       arbiter_scalar_valid_in[4*`NUM_COLLECTORUNIT*i+j*4+k] ? arbiter_scalar_bankID_in[`DEPTH_BANK*4*`NUM_COLLECTORUNIT*i+(j*4+k+1)*`DEPTH_BANK-1-:`DEPTH_BANK] : 'b0;
          
          //assign arbiter_scalar_rsType_out_oh[2*4*`NUM_COLLECTORUNIT*i+(j*4+k+1)*2-1-:2] = 
          //       arbiter_scalar_valid_in[4*`NUM_COLLECTORUNIT*i+j*4+k] ? arbiter_scalar_rsType_in[2*4*`NUM_COLLECTORUNIT*i+(j*4+k+1)*2-1-:2] : 'b0;
          
          assign arbiter_scalar_rsAddr_out_oh[`DEPTH_REGBANK*4*`NUM_COLLECTORUNIT*i+(j*4+k+1)*`DEPTH_REGBANK-1-:`DEPTH_REGBANK] = 
                 arbiter_scalar_valid_in[4*`NUM_COLLECTORUNIT*i+j*4+k] ? arbiter_scalar_rsAddr_in[`DEPTH_REGBANK*4*`NUM_COLLECTORUNIT*i+(j*4+k+1)*`DEPTH_REGBANK-1-:`DEPTH_REGBANK] : 'b0;
          
          //assign arbiter_vector_bankID_out_oh[`DEPTH_BANK*4*`NUM_COLLECTORUNIT*i+(j*4+k+1)*`DEPTH_BANK-1-:`DEPTH_BANK] = 
          //       arbiter_vector_valid_in[4*`NUM_COLLECTORUNIT*i+j*4+k] ? arbiter_vector_bankID_in[`DEPTH_BANK*4*`NUM_COLLECTORUNIT*i+(j*4+k+1)*`DEPTH_BANK-1-:`DEPTH_BANK] : 'b0;
          
          //assign arbiter_vector_rsType_out_oh[2*4*`NUM_COLLECTORUNIT*i+(j*4+k+1)*2-1-:2] = 
          //       arbiter_vector_valid_in[4*`NUM_COLLECTORUNIT*i+j*4+k] ? arbiter_vector_rsType_in[2*4*`NUM_COLLECTORUNIT*i+(j*4+k+1)*2-1-:2] : 'b0;
          
          assign arbiter_vector_rsAddr_out_oh[`DEPTH_REGBANK*4*`NUM_COLLECTORUNIT*i+(j*4+k+1)*`DEPTH_REGBANK-1-:`DEPTH_REGBANK] = 
                 arbiter_vector_valid_in[4*`NUM_COLLECTORUNIT*i+j*4+k] ? arbiter_vector_rsAddr_in[`DEPTH_REGBANK*4*`NUM_COLLECTORUNIT*i+(j*4+k+1)*`DEPTH_REGBANK-1-:`DEPTH_REGBANK] : 'b0;

        end
      end
    end
  endgenerate


  //assign arbiter_scalar_ready_in  = {4*`NUM_COLLECTORUNIT*`NUM_BANK{1'b1}}     ; // TODO generatefor
  //assign arbiter_vector_ready_in  = {4*`NUM_COLLECTORUNIT*`NUM_BANK{1'b1}}     ;
  /*genvar jj,kk;
  generate
    for (jj=0; jj<`NUM_COLLECTORUNIT; jj=jj+1) begin:collector_unit_loop_3
      for (kk=0; kk<4; kk=kk+1) begin:operand_loop_3
        assign arbiter_ready_o[jj*4+kk]   = 1'b1;
      end
    end
  endgenerate
  */



  assign scalar_valid_o            = arbiter_scalar_valid_out   ;
  //assign arbiter_scalar_ready_out  = scalar_ready_i             ;
  //assign scalar_bankID_o           = arbiter_scalar_bankID_out  ;
  //assign scalar_rsType_o           = arbiter_scalar_rsType_out  ;
  assign scalar_rsAddr_o           = arbiter_scalar_rsAddr_out  ;

  assign vector_valid_o            = arbiter_vector_valid_out   ;  
  //assign arbiter_vector_ready_out  = vector_ready_i             ;
  //assign vector_bankID_o           = arbiter_vector_bankID_out  ;
  //assign vector_rsType_o           = arbiter_vector_rsType_out  ;
  assign vector_rsAddr_o           = arbiter_vector_rsAddr_out  ;
  
  assign chosen_scalar_o           = arbiter_scalar_chosen      ;
  assign chosen_vector_o           = arbiter_vector_chosen      ;
        
  genvar m;
  generate
    for (m=0; m<`NUM_BANK; m=m+1) begin:RRArbiter
      // bankArbiterScalar
      round_robin_arb #(
        .ARB_WIDTH(4*`NUM_COLLECTORUNIT)
      )
      U_round_robin_arb_scalar
      (
        .clk(clk),
        .rst_n(rst_n),
        .req(arbiter_scalar_valid_in[4*`NUM_COLLECTORUNIT*(m+1)-1-:4*`NUM_COLLECTORUNIT]),
        .grant(arbiter_scalar_valid_oh[4*`NUM_COLLECTORUNIT*(m+1)-1-:4*`NUM_COLLECTORUNIT])
      );

      one2bin #(
        .ONE_WIDTH(4*`NUM_COLLECTORUNIT),
        .BIN_WIDTH(DEPTH_4_COLLECTORUNIT)
      )
      U_one2bin_scalar
      (
        .oh(arbiter_scalar_valid_oh[4*`NUM_COLLECTORUNIT*(m+1)-1-:4*`NUM_COLLECTORUNIT]),
        .bin(arbiter_scalar_chosen[DEPTH_4_COLLECTORUNIT*(m+1)-1-:DEPTH_4_COLLECTORUNIT])    
      );
      
      // bankArbiterVector
      round_robin_arb #(
        .ARB_WIDTH(4*`NUM_COLLECTORUNIT)
      )
      U_round_robin_arb_vector
      (
        .clk(clk),
        .rst_n(rst_n),
        .req(arbiter_vector_valid_in[4*`NUM_COLLECTORUNIT*(m+1)-1-:4*`NUM_COLLECTORUNIT]),
        .grant(arbiter_vector_valid_oh[4*`NUM_COLLECTORUNIT*(m+1)-1-:4*`NUM_COLLECTORUNIT])
      );

      one2bin #(
        .ONE_WIDTH(4*`NUM_COLLECTORUNIT),
        .BIN_WIDTH(DEPTH_4_COLLECTORUNIT)
      )
      U_one2bin_vector
      (
        .oh(arbiter_vector_valid_oh[4*`NUM_COLLECTORUNIT*(m+1)-1-:4*`NUM_COLLECTORUNIT]),
        .bin(arbiter_vector_chosen[DEPTH_4_COLLECTORUNIT*(m+1)-1-:DEPTH_4_COLLECTORUNIT])    
      );  
    end
  endgenerate


endmodule
