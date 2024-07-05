
`timescale 1ns / 1ps

module gen_clk(
  output clk
  );

  localparam PERIOD = 10.0;

  reg clk_r;
  initial begin
   clk_r = 1'b0;
   while(1) begin
    #(PERIOD/2) clk_r = ~clk_r;
   end
  end

  assign clk = clk_r;

endmodule  
