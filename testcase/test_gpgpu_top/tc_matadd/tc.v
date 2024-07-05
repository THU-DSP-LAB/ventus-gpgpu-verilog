
`define drv_gpu               u_host_inter.drv_gpu
`define exe_finish            u_host_inter.exe_finish
`define get_result_addr       u_host_inter.get_result_addr
`define parsed_base           u_host_inter.parsed_base_r
`define parsed_size           u_host_inter.parsed_size_r

`define init_mem              u_mem_inter.init_mem
`define tile_read_and_write   u_mem_inter.tile_read_and_write
`define mem                   u_mem_inter.mem
//`define l2_flush_finish      gpu_test.B1[0].l2cache.SourceD_finish_issue_o
`define host_rsp_valid        u_host_inter.host_rsp_valid_o

//**********Selsct matadd test case, remember modify `define NUM_THREAD at the same time**********//
//`define CASE_1W16T
//`define CASE_1W32T
//`define CASE_2W8T
`define CASE_4W4T


module tc;
  //parameter MAX_NUM_BUF     = 10; //the maximun of num_buffer
  //parameter MEM_ADDR        = 32;
  parameter METADATA_SIZE   = 1024; //the maximun size of .data
  parameter DATADATA_SIZE   = 2000; //the maximun size of .metadata

  parameter META_FNAME_SIZE = 128;
  parameter DATA_FNAME_SIZE = 128;

  parameter BUF_NUM         = 18;

  defparam u_host_inter.META_FNAME_SIZE = META_FNAME_SIZE;
  defparam u_host_inter.DATA_FNAME_SIZE = DATA_FNAME_SIZE;
  defparam u_host_inter.METADATA_SIZE   = METADATA_SIZE;
  defparam u_host_inter.DATADATA_SIZE   = DATADATA_SIZE;

  defparam u_mem_inter.META_FNAME_SIZE = META_FNAME_SIZE;
  defparam u_mem_inter.DATA_FNAME_SIZE = DATA_FNAME_SIZE;
  defparam u_mem_inter.METADATA_SIZE   = METADATA_SIZE;
  defparam u_mem_inter.DATADATA_SIZE   = DATADATA_SIZE;
  defparam u_mem_inter.BUF_NUM         = BUF_NUM;

  wire clk  = u_gen_clk.clk;
  wire rstn = u_gen_rst.rst_n;
 
  //reg [31:0] mem_metadata [0:METADATA_SIZE-1];
  //reg [31:0] mem_data     [0:DATADATA_SIZE-1];
  reg [META_FNAME_SIZE*8-1:0] meta_fname[7:0];
  reg [DATA_FNAME_SIZE*8-1:0] data_fname[7:0];

  initial begin
    repeat(500)
    @(posedge clk);
    init_test_file();
    test_matadd();
    repeat(500)
    @(posedge clk);
    $finish();
  end

  initial begin
    //repeat(500)
    //@(posedge clk);
    mem_drv();
  end

  //initial begin
  //  #1000000;
  //  $finish;
  //end 

  task init_test_file;
    begin

     `ifdef CASE_1W16T
      meta_fname[0] = "1w16t/matadd_0.metadata";
      data_fname[0] = "1w16t/matadd_0.data";
     `endif

     `ifdef CASE_1W32T
      meta_fname[0] = "1w32t/matadd_0.metadata";
      data_fname[0] = "1w32t/matadd_0.data";
     `endif
     `ifdef CASE_2W8T
      meta_fname[0] = "2w8t/matadd_0.metadata";
      data_fname[0] = "2w8t/matadd_0.data";
     `endif
     `ifdef CASE_4W4T
      meta_fname[0] = "4w4t/matadd_0.metadata";
      data_fname[0] = "4w4t/matadd_0.data";
     `endif

    end
  endtask

  task test_matadd;
    integer i;
    begin
      for(i=0; i<1; i=i+1) begin
        `init_mem(meta_fname[i], data_fname[i]);
        `drv_gpu(meta_fname[i], data_fname[i]);
        if(i==0) begin
          `get_result_addr(meta_fname[i], data_fname[i]);
        end
        `exe_finish(meta_fname[i], data_fname[i]);
        if(i==0) begin
          print_result();
        end
      end
    end
  endtask

  task mem_drv;
    begin
      while(1) fork
        //`tile_write(0);
        `tile_read_and_write(0);
      join
    end
  endtask

  //task print_mem;
  //  if(`l2_flush_finish) begin
  //    $display("-case_gaussian result-");
  //    $display("-----matrix a:-----");
  //    for(integer addr=32'h90000000; addr<32'h90000000+32'h40; addr=addr+4) begin
  //      //$fwrite(file1,"0x%h %h%h%h%h\n",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
  //      $display("0x%h %h%h%h%h",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
  //    end
  //    $display("-----array b:-----");
  //    for(integer addr=32'h90001000; addr<32'h90001000+32'h10; addr=addr+4) begin
  //      //$fwrite(file1,"0x%h %h%h%h%h\n",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
  //      $display("0x%h %h%h%h%h",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
  //    end
  //    $display("-----tmp value:-----");
  //    for(integer addr=32'h90002000; addr<32'h90002000+32'h40; addr=addr+4) begin
  //      //$fwrite(file1,"0x%h %h%h%h%h\n",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
  //      $display("0x%h %h%h%h%h",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
  //    end
  //    $display("============================================");
  //  end
  //endtask

  task print_result;
    reg [31:0]    sum_16_hard   [15:0];
    reg [15:0]    sum_16_pass   ;

    //if(`l2_flush_finish) begin
    if(`host_rsp_valid) begin
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      $display("----------case_matadd result-----------");
      $display("--------------sum result:--------------");
      for(integer addr=`parsed_base[2]; addr<`parsed_base[2]+`parsed_size[2]; addr=addr+4) begin
        //$fwrite(file1,"0x%h %h%h%h%h\n",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
        $display("          0x%h %h%h%h%h",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
        sum_16_hard[(addr-`parsed_base[2])/4]  = {`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]};
      end

      for(integer j=0; j<16; j=j+1) begin        
        if(sum_16_hard[j]==32'h41800000) begin
          sum_16_pass[j]  = 1'b1;
        end else begin
          sum_16_pass[j]  = 1'b0;
        end
      end

      `ifdef CASE_1W16T
            if(&sum_16_pass) begin
              $display("***********case_matadd_1w16t***********");
              $display("*****************PASS******************");
            end else begin
              $display("***********case_matadd_1w16t***********");
              $display("****************FAILED*****************");
            end
      `endif
      `ifdef CASE_1W32T
            if(&sum_16_pass) begin
              $display("***********case_matadd_1w32t***********");
              $display("*****************PASS******************");
            end else begin
              $display("***********case_matadd_1w32t***********");
              $display("****************FAILED*****************");
            end
      `endif
      `ifdef CASE_2W8T
            if(&sum_16_pass) begin
              $display("***********case_matadd_2w8t************");
              $display("*****************PASS******************");
            end else begin
              $display("***********case_matadd_2w8t************");
              $display("****************FAILED*****************");
            end
      `endif
      `ifdef CASE_4W4T
            if(&sum_16_pass) begin
              $display("***********case_matadd_4w4t************");
              $display("*****************PASS******************");
            end else begin
              $display("***********case_matadd_4w4t************");
              $display("****************FAILED*****************");
            end
      `endif
    end
  endtask

endmodule

