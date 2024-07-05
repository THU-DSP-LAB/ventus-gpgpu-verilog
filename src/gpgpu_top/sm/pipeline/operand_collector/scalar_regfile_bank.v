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

`timescale 1ns/1ps

module scalar_regfile_bank(
  input                                   clk               ,
  input                                   rst_n             ,

  // input interface
  input        [`DEPTH_REGBANK-1:0]       rsidx_i           ,
  input                                   rsren_i           ,
  input        [`XLEN-1:0]                rd_i              ,
  input        [`DEPTH_REGBANK-1:0]       rdidx_i           ,
  input                                   rdwen_i           ,

  // output interface
  output       [`XLEN-1:0]                rs_o                
);

  /*
  localparam ADDR_DEPTH = `NUMBER_SGPR_SLOTS/`NUM_BANK;
  reg                           bypass  ;
  reg [`XLEN-1:0]               rs_tmp  ;
  reg [`XLEN-1:0]               rd_q    ;
  wire                          rswen   ;
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      bypass    <= 1'b0;
    end else if((rsidx_i==rdidx_i) & rdwen_i) begin
      bypass    <= 1'b1;
    end else begin
      bypass    <= 1'b0;
    end
  end
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      rd_q    <= {`XLEN{1'b0}};
    end else begin
      rd_q    <= rd_i   ;
    end
  end

  assign  rs_o  = bypass ? rd_q : rs_tmp;

  assign  rswen = ((rsidx_i==rdidx_i) && rdwen_i) ? 1'b0 : 1'b1;
  */

  //reg [`XLEN*ADDR_DEPTH-1:0]  ram     ;
  //reg [`XLEN*ADDR_DEPTH-1:0]  ram_q   ;
  //reg                         bypass  ;
  //reg [`XLEN-1:0]             rd_q    ;
  //reg [`DEPTH_REGBANK-1:0]    rsidx_q ;

  //always @(posedge clk or negedge rst_n) begin
  //  if(!rst_n) begin
  //    bypass    <= 1'b0;
  //  end else if((rsidx_i==rdidx_i) & rdwen_i) begin
  //    bypass    <= 1'b1;
  //  end else begin
  //    bypass    <= 1'b0;
  //  end
  //end
  //
  //always @(posedge clk or negedge rst_n) begin
  //  if(!rst_n) begin
  //    ram_q   <= 'b0;
  //    rd_q    <= 'b0;
  //    rsidx_q <= 'b0;
  //  end else begin
  //    ram_q   <= ram    ;
  //    rd_q    <= rd_i   ;
  //    rsidx_q <= rsidx_i;
  //  end
  //end

  //always @(*) begin
  //  if(bypass) begin
  //    rs_o = rd_q;
  //  end else begin
  //    rs_o = ram_q[`XLEN*(rsidx_q+1)-1-:`XLEN];
  //  end
  //end

  //always @(posedge clk or negedge rst_n) begin
  //  if(!rst_n) begin
  //    ram <= 'b0;
  //  end else if(rdwen_i) begin
  //    ram[`XLEN*(rdidx_i+1)-1-:`XLEN] <= rd_i;
  //  end else begin
  //    ram <= ram;
  //  end
  //end

/*
`ifdef T28_MEM  //256x32
  GPGPU_RF_2P_256X32M U_GPGPU_RF_2P_256X32M_0
  (
   .AA   (rdidx_i   ),
   .D    (rd_i      ),
   .BWEB ({32{1'b0}}),
   .WEB  (!rdwen_i  ),
   .CLKW (clk       ),
   .AB   (rsidx_i   ),
   .REB  (!rswen    ),
   .CLKR (clk       ),
   .Q    (rs_tmp    )
);
`else
dualportSRAM #(
  .BITWIDTH   (`XLEN              ),
  .DEPTH      (`DEPTH_REGBANK     )
)U_dualportSRAM(
  .CLK        (clk                ),
  .RSTN       (rst_n              ),
  .D          (rd_i               ),
  .Q          (rs_tmp             ),
  .REB        (rswen              ),
  .WEB        (rdwen_i            ),
  .BWEB       ({`XLEN{1'b1}}      ),
  .AA         (rdidx_i            ),
  .AB         (rsidx_i            )
);
`endif
*/

`ifdef T28_MEM  //256x32
  GPGPU_RF_2P_256X32M U_GPGPU_RF_2P_256X32M_0
  (
   .AA   (rdidx_i   ),
   .D    (rd_i      ),
   .BWEB ({32{1'b0}}),
   .WEB  (!rdwen_i  ),
   .CLKW (clk       ),
   .AB   (rsidx_i   ),
   .REB  (!rsren_i  ),
   .CLKR (clk       ),
   .Q    (rs_o      )
);
`else
dualportSRAM #(
  .BITWIDTH   (`XLEN              ),
  .DEPTH      (`DEPTH_REGBANK     )
)U_dualportSRAM(
  .CLK        (clk                ),
  .RSTN       (rst_n              ),
  .D          (rd_i               ),
  .Q          (rs_o               ),
  .REB        (rsren_i            ),
  .WEB        (rdwen_i            ),
  .BWEB       ({`XLEN{1'b1}}      ),
  .AA         (rdidx_i            ),
  .AB         (rsidx_i            )
);
`endif

endmodule
