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

module vector_regfile_bank(
  input                                   clk               ,
  input                                   rst_n             ,

  // input interface
  input        [`DEPTH_REGBANK-1:0]       rsidx_i           ,
  input                                   rsren_i           ,    
  input        [`XLEN*`NUM_THREAD-1:0]    rd_i              ,
  input        [`DEPTH_REGBANK-1:0]       rdidx_i           ,
  input                                   rdwen_i           ,
  input        [`NUM_THREAD-1:0]          rdwmask_i         ,

  // output interface
  output       [`XLEN*`NUM_THREAD-1:0]    rs_o              ,
  output       [`XLEN*`NUM_THREAD-1:0]    v0_o                
);

  reg [`XLEN*`NUM_THREAD-1:0]   v0_mem    ;
  reg [`XLEN*`NUM_THREAD-1:0]   v0_mem_q  ;

  reg [`XLEN*`NUM_THREAD-1:0]   ram_mask  ;
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      v0_mem_q    <= 'b0;
    end else begin
      v0_mem_q    <= v0_mem    ;
    end
  end

  assign  v0_o  = rsren_i ? v0_mem_q : 'b0;

  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      v0_mem <= 'b0;
    end else if(rdwen_i && rdidx_i== 'b0) begin
      v0_mem <= ram_mask;
    end else begin
      v0_mem <= v0_mem;
    end
  end

  genvar j;
  generate
    for (j=0; j<`NUM_THREAD; j=j+1) begin:ram_mask_output
      always @(*) begin
        if(rdwmask_i[j]) begin
          ram_mask[`XLEN*(j+1)-1-:`XLEN] = rd_i[`XLEN*(j+1)-1-:`XLEN];
        end else begin
          ram_mask[`XLEN*(j+1)-1-:`XLEN] = {`NUM_THREAD{1'b0}};        
        end
      end
    end
  endgenerate
  
  /*
  localparam ADDR_DEPTH = `NUMBER_VGPR_SLOTS/`NUM_BANK;

  reg [`XLEN*`NUM_THREAD-1:0]   v0_mem    ;
  reg [`XLEN*`NUM_THREAD-1:0]   v0_mem_q  ;

  reg                           bypass    ;
  reg [`XLEN*`NUM_THREAD-1:0]   rs_tmp    ;
  reg [`XLEN*`NUM_THREAD-1:0]   rd_q      ;
  wire                          rswen     ;
  reg [`XLEN*`NUM_THREAD-1:0]   ram_mask  ;
  reg [`DEPTH_REGBANK-1:0]      rsidx_q   ;
  
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
      v0_mem_q    <= 'b0;
      rd_q        <= {`XLEN{1'b0}};
      rsidx_q     <= 'b0;
    end else begin
      v0_mem_q    <= v0_mem    ;
      rd_q        <= ram_mask   ;
      rsidx_q     <= rsidx_i;
    end
  end

  assign  rs_o  = bypass ? rd_q : rs_tmp;
  assign  v0_o  = bypass ? (rsidx_q== 'b0 ? rd_q : 'b0) : v0_mem_q;

  //assign  rswen = ((rsidx_i==rdidx_i) && rdwen_i && rdidx_i!= 'b0) ? 1'b0 : 1'b1;
  assign  rswen = ((rsidx_i==rdidx_i) && rdwen_i) ? 1'b0 : 1'b1;
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      v0_mem <= 'b0;
    end else if(rdwen_i && rdidx_i== 'b0) begin
      v0_mem <= ram_mask;
    end else begin
      v0_mem <= v0_mem;
    end
  end

  genvar j;
  generate
    for (j=0; j<`NUM_THREAD; j=j+1) begin:ram_mask_output
      always @(*) begin
        if(rdwmask_i[j]) begin
          ram_mask[`XLEN*(j+1)-1-:`XLEN] = rd_i[`XLEN*(j+1)-1-:`XLEN];
        end else begin
          ram_mask[`XLEN*(j+1)-1-:`XLEN] = {`NUM_THREAD{1'b0}};        
        end
      end
    end
  endgenerate
  */

  //reg [`XLEN*`NUM_THREAD-1:0] mem [0:`NUMBER_VGPR_SLOTS/`NUM_BANK-1];
  //reg [`XLEN*`NUM_THREAD*ADDR_DEPTH-1:0] ram  ;
  //reg [`XLEN*`NUM_THREAD*ADDR_DEPTH-1:0] ram_q;
  //reg bypass;
  //reg [`XLEN*`NUM_THREAD-1:0] ram_mask  ;
  //reg [`XLEN*`NUM_THREAD-1:0] rd_q      ;
  //reg [`DEPTH_REGBANK-1:0]    rsidx_q   ;

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
  //    v0_o = rsidx_q== 'b0 ? rd_q : 'b0;
  //  end else begin
  //    rs_o = ram_q[`XLEN*`NUM_THREAD*(rsidx_q+1)-1-:`XLEN*`NUM_THREAD];
  //    v0_o = ram_q[`XLEN*`NUM_THREAD-1-:`XLEN*`NUM_THREAD];
  //  end
  //end
  //
  //always @(posedge clk or negedge rst_n) begin
  //  if(!rst_n) begin
  //    ram <= 'b0;
  //  end else if(rdwen_i) begin
  //    ram[`XLEN*`NUM_THREAD*(rdidx_i+1)-1-:`XLEN*`NUM_THREAD] <= ram_mask;
  //  end else begin
  //    ram <= ram;
  //  end
  //end

  //genvar j;
  //generate
  //  for (j=0; j<`NUM_THREAD; j=j+1) begin:ram_mask_output
  //    always @(*) begin
  //      if(rdwmask_i[j]) begin
  //        ram_mask[`XLEN*(j+1)-1-:`XLEN] = rd_i[`XLEN*(j+1)-1-:`XLEN];
  //      end else begin
  //        ram_mask[`XLEN*(j+1)-1-:`XLEN] =  'b0;        
  //      end
  //    end
  //  end
  //endgenerate

/*
`ifdef T28_MEM  //256X1024
  GPGPU_RF_2P_256X128M U_GPGPU_RF_2P_256X128M_0
  (
   .AA   (rdidx_i        ),
   .D    (ram_mask[127:0]),
   .BWEB ({128{1'b0}}    ),
   .WEB  (!rdwen_i       ),
   .CLKW (clk            ),
   .AB   (rsidx_i        ),
   .REB  (!rswen         ),
   .CLKR (clk            ),
   .Q    (rs_tmp[127:0]  )
);

  GPGPU_RF_2P_256X128M U_GPGPU_RF_2P_256X128M_1
  (
   .AA   (rdidx_i          ),
   .D    (ram_mask[255:128]),
   .BWEB ({128{1'b0}}      ),
   .WEB  (!rdwen_i         ),
   .CLKW (clk              ),
   .AB   (rsidx_i          ),
   .REB  (!rswen           ),
   .CLKR (clk              ),
   .Q    (rs_tmp[255:128]  )
);

  GPGPU_RF_2P_256X128M U_GPGPU_RF_2P_256X128M_2
  (
   .AA   (rdidx_i          ),
   .D    (ram_mask[383:256]),
   .BWEB ({128{1'b0}}      ),
   .WEB  (!rdwen_i         ),
   .CLKW (clk              ),
   .AB   (rsidx_i          ),
   .REB  (!rswen           ),
   .CLKR (clk              ),
   .Q    (rs_tmp[383:256]  )
);

  GPGPU_RF_2P_256X128M U_GPGPU_RF_2P_256X128M_3
  (
   .AA   (rdidx_i          ),
   .D    (ram_mask[511:384]),
   .BWEB ({128{1'b0}}      ),
   .WEB  (!rdwen_i         ),
   .CLKW (clk              ),
   .AB   (rsidx_i          ),
   .REB  (!rswen           ),
   .CLKR (clk              ),
   .Q    (rs_tmp[511:384]  )
);

  GPGPU_RF_2P_256X128M U_GPGPU_RF_2P_256X128M_4
  (
   .AA   (rdidx_i          ),
   .D    (ram_mask[639:512]),
   .BWEB ({128{1'b0}}      ),
   .WEB  (!rdwen_i         ),
   .CLKW (clk              ),
   .AB   (rsidx_i          ),
   .REB  (!rswen           ),
   .CLKR (clk              ),
   .Q    (rs_tmp[639:512]  )
);

  GPGPU_RF_2P_256X128M U_GPGPU_RF_2P_256X128M_5
  (
   .AA   (rdidx_i          ),
   .D    (ram_mask[767:640]),
   .BWEB ({128{1'b0}}      ),
   .WEB  (!rdwen_i         ),
   .CLKW (clk              ),
   .AB   (rsidx_i          ),
   .REB  (!rswen           ),
   .CLKR (clk              ),
   .Q    (rs_tmp[767:640]  )
);

  GPGPU_RF_2P_256X128M U_GPGPU_RF_2P_256X128M_6
  (
   .AA   (rdidx_i          ),
   .D    (ram_mask[895:768]),
   .BWEB ({128{1'b0}}      ),
   .WEB  (!rdwen_i         ),
   .CLKW (clk              ),
   .AB   (rsidx_i          ),
   .REB  (!rswen           ),
   .CLKR (clk              ),
   .Q    (rs_tmp[895:768]  )
);

  GPGPU_RF_2P_256X128M U_GPGPU_RF_2P_256X128M_7
  (
   .AA   (rdidx_i           ),
   .D    (ram_mask[1023:896]),
   .BWEB ({128{1'b0}}       ),
   .WEB  (!rdwen_i          ),
   .CLKW (clk               ),
   .AB   (rsidx_i           ),
   .REB  (!rswen            ),
   .CLKR (clk               ),
   .Q    (rs_tmp[1023:896]  )
);
`else
dualportSRAM #(
  .BITWIDTH   (`XLEN*`NUM_THREAD          ),
  .DEPTH      (`DEPTH_REGBANK             )
)U_dualportSRAM(
  .CLK        (clk                        ),
  .RSTN       (rst_n                      ),
  .D          (ram_mask                   ),
  .Q          (rs_tmp                     ),
  .REB        (rswen                      ),
  .WEB        (rdwen_i                    ),
  .BWEB       ({`XLEN*`NUM_THREAD{1'b1}}  ),
  .AA         (rdidx_i                    ), //write
  .AB         (rsidx_i                    )  //read
);
`endif
*/

`ifdef T28_MEM  //256X1024
  GPGPU_RF_2P_256X128M U_GPGPU_RF_2P_256X128M_0
  (
   .AA   (rdidx_i        ),
   .D    (ram_mask[127:0]),
   .BWEB ({128{1'b0}}    ),
   .WEB  (!rdwen_i       ),
   .CLKW (clk            ),
   .AB   (rsidx_i        ),
   .REB  (!rsren_i       ),
   .CLKR (clk            ),
   .Q    (rs_o[127:0]  )
);

  GPGPU_RF_2P_256X128M U_GPGPU_RF_2P_256X128M_1
  (
   .AA   (rdidx_i          ),
   .D    (ram_mask[255:128]),
   .BWEB ({128{1'b0}}      ),
   .WEB  (!rdwen_i         ),
   .CLKW (clk              ),
   .AB   (rsidx_i          ),
   .REB  (!rsren_i         ),
   .CLKR (clk              ),
   .Q    (rs_o[255:128]  )
);

  GPGPU_RF_2P_256X128M U_GPGPU_RF_2P_256X128M_2
  (
   .AA   (rdidx_i          ),
   .D    (ram_mask[383:256]),
   .BWEB ({128{1'b0}}      ),
   .WEB  (!rdwen_i         ),
   .CLKW (clk              ),
   .AB   (rsidx_i          ),
   .REB  (!rsren_i         ),
   .CLKR (clk              ),
   .Q    (rs_o[383:256]  )
);

  GPGPU_RF_2P_256X128M U_GPGPU_RF_2P_256X128M_3
  (
   .AA   (rdidx_i          ),
   .D    (ram_mask[511:384]),
   .BWEB ({128{1'b0}}      ),
   .WEB  (!rdwen_i         ),
   .CLKW (clk              ),
   .AB   (rsidx_i          ),
   .REB  (!rsren_i         ),
   .CLKR (clk              ),
   .Q    (rs_o[511:384]  )
);

  GPGPU_RF_2P_256X128M U_GPGPU_RF_2P_256X128M_4
  (
   .AA   (rdidx_i          ),
   .D    (ram_mask[639:512]),
   .BWEB ({128{1'b0}}      ),
   .WEB  (!rdwen_i         ),
   .CLKW (clk              ),
   .AB   (rsidx_i          ),
   .REB  (!rsren_i         ),
   .CLKR (clk              ),
   .Q    (rs_o[639:512]  )
);

  GPGPU_RF_2P_256X128M U_GPGPU_RF_2P_256X128M_5
  (
   .AA   (rdidx_i          ),
   .D    (ram_mask[767:640]),
   .BWEB ({128{1'b0}}      ),
   .WEB  (!rdwen_i         ),
   .CLKW (clk              ),
   .AB   (rsidx_i          ),
   .REB  (!rsren_i         ),
   .CLKR (clk              ),
   .Q    (rs_o[767:640]  )
);

  GPGPU_RF_2P_256X128M U_GPGPU_RF_2P_256X128M_6
  (
   .AA   (rdidx_i          ),
   .D    (ram_mask[895:768]),
   .BWEB ({128{1'b0}}      ),
   .WEB  (!rdwen_i         ),
   .CLKW (clk              ),
   .AB   (rsidx_i          ),
   .REB  (!rsren_i         ),
   .CLKR (clk              ),
   .Q    (rs_o[895:768]  )
);

  GPGPU_RF_2P_256X128M U_GPGPU_RF_2P_256X128M_7
  (
   .AA   (rdidx_i           ),
   .D    (ram_mask[1023:896]),
   .BWEB ({128{1'b0}}       ),
   .WEB  (!rdwen_i          ),
   .CLKW (clk               ),
   .AB   (rsidx_i           ),
   .REB  (!rsren_i          ),
   .CLKR (clk               ),
   .Q    (rs_o[1023:896]  )
);
`else
dualportSRAM #(
  .BITWIDTH   (`XLEN*`NUM_THREAD          ),
  .DEPTH      (`DEPTH_REGBANK             )
)U_dualportSRAM(
  .CLK        (clk                        ),
  .RSTN       (rst_n                      ),
  .D          (ram_mask                   ),
  .Q          (rs_o                       ),
  .REB        (rsren_i                    ),
  .WEB        (rdwen_i                    ),
  .BWEB       ({`XLEN*`NUM_THREAD{1'b1}}  ),
  .AA         (rdidx_i                    ), //write
  .AB         (rsidx_i                    )  //read
);
`endif

endmodule

