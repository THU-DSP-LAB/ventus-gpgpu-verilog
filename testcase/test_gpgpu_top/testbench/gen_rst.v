
module gen_rst(
  output rst_n,
  input  clk
  );
  //-----------------------
  localparam RST_CYCLE_N = 2;

  reg rst_n_r;
  initial begin
   rst_n_r = 0;
   repeat(RST_CYCLE_N)
   @(posedge clk)
   rst_n_r = 1'b1;
  end

  assign rst_n = rst_n_r;

endmodule

