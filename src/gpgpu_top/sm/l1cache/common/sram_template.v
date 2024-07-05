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
// Description:sram template module
`timescale 1ns/1ns

module sram_template #(
  parameter  GEN_WIDTH = 32 ,   
  parameter  NUM_SET   = 32 ,
  parameter  NUM_WAY   = 2  , //way should >= 1
  parameter  SET_DEPTH = 5  ,
  parameter  WAY_DEPTH = 1  
  )
  (
  input                          clk            ,
  input                          rst_n          ,
  input                          r_req_valid_i  ,
  input  [SET_DEPTH-1:0]         r_req_setid_i  , 
  output [NUM_WAY*GEN_WIDTH-1:0] r_resp_data_o  , //[GEN_WIDTH-1:0] [0:NUM_WAY-1
  input                          w_req_valid_i  ,
  input  [SET_DEPTH-1:0]         w_req_setid_i  ,
  input  [NUM_WAY-1:0]           w_req_waymask_i,
  input  [NUM_WAY*GEN_WIDTH-1:0] w_req_data_i       
  );
  //parameter MEM_WIDTH = NUM_WAY*GEN_WIDTH;
  //reg [NUM_WAY*GEN_WIDTH-1:0] mem [0:NUM_SET-1]; // Vec(set,Vec(NUM_WAY,GEN_WIDTH))
  //reg [NUM_SET*MEM_WIDTH-1:0] mem;
//raw_rdata
   
  //wire r_en,w_en; //read/write enable
  reg bypass_mask;
  wire [NUM_WAY*GEN_WIDTH-1:0] Q;
  reg  [NUM_WAY*GEN_WIDTH-1:0] w_req_data_i_1; 
  //reg  [GEN_WIDTH-1:0] rdata_r; 
  //assign r_en = r_req_valid_i;
  //assign w_en = w_req_valid_i;
  wire [NUM_WAY*GEN_WIDTH-1:0] w_way_mask ;
  genvar k;
  generate for (k=0;k<NUM_WAY;k=k+1) begin:gen_w_mask
    assign w_way_mask [GEN_WIDTH*k+:GEN_WIDTH] = (w_req_waymask_i[k]) ? {GEN_WIDTH{1'b1}} : {GEN_WIDTH{1'b0}}; 
  end
  endgenerate

  wire read_sram_en;
  
  assign read_sram_en = r_req_valid_i && !(w_req_valid_i && r_req_valid_i && (w_req_setid_i == r_req_setid_i)); 
  
  dualportSRAM #(
  .BITWIDTH     (NUM_WAY*GEN_WIDTH    ),        
  .DEPTH        (SET_DEPTH            ))
  dualportSRAM  (
  .CLK          (clk          ),
  .RSTN         (rst_n        ),
  .D            (w_req_data_i ),
  .Q            (Q            ),
  .REB          (read_sram_en ),
  .WEB          (w_req_valid_i),
  .BWEB         (w_way_mask   ),
  .AA           (w_req_setid_i),
  .AB           (r_req_setid_i));
/*
  genvar i,j;
  generate for(i=0;i<NUM_SET;i=i+1) begin:B1
    for(j=0;j<NUM_WAY;j=j+1) begin:B2
      always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          //mem[i][j] <= 'h0;
          mem[i][(GEN_WIDTH*(j+1)-1)-:GEN_WIDTH] <= 'h0;
        end 
        //else if(w_en && w_req_waymask_i[j]) begin
        else if(w_en) begin
          //mem[w_req_setid_i][(GEN_WIDTH*(j+1)-1) -: GEN_WIDTH] <= w_req_data_i[(GEN_WIDTH*(j+1)-1) -: GEN_WIDTH];
           mem[i][(GEN_WIDTH*(j+1)-1)-:GEN_WIDTH] <= ((i==w_req_setid_i) && w_req_waymask_i[j]) ?  
                                                     w_req_data_i[(GEN_WIDTH*(j+1)-1)-:GEN_WIDTH] : mem[i][(GEN_WIDTH*(j+1)-1)-:GEN_WIDTH];
        end 
        else begin
          //mem[i][j] <= mem[i][j];
          mem[i][(GEN_WIDTH*(j+1)-1)-:GEN_WIDTH] <= mem[i][(GEN_WIDTH*(j+1)-1)-:GEN_WIDTH];
        end 
      end 
    end
  end 
  endgenerate*/

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      bypass_mask <= 1'b0;
    end
    else if(w_req_valid_i && r_req_valid_i && (w_req_setid_i == r_req_setid_i)) 
    begin
      bypass_mask <= 1'b1;      
    end 
    else 
      bypass_mask <= 1'b0;
  end    
  //assign bypass_mask = w_req_valid_i && r_req_valid_i && (w_req_setid_i == r_req_setid_i);
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      w_req_data_i_1 <= 'h0;
    end
    else w_req_data_i_1 <= w_req_data_i;
  end

  assign r_resp_data_o = bypass_mask ? w_req_data_i_1 : Q; 


endmodule
