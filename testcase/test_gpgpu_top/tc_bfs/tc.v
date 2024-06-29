
`define drv_gpu               u_host_inter.drv_gpu
`define exe_finish            u_host_inter.exe_finish
`define get_result_addr       u_host_inter.get_result_addr
`define parsed_base           u_host_inter.parsed_base_r
`define parsed_size           u_host_inter.parsed_size_r

`define init_mem              u_mem_inter.init_mem
`define tile_read_and_write   u_mem_inter.tile_read_and_write
`define mem                   u_mem_inter.mem
//`define l2_flush_finish       gpu_test.B1[0].l2cache.SourceD_finish_issue_o
`define host_rsp_valid        u_host_inter.host_rsp_valid_o

//**********Selsct bfs test case, remember modify `define NUM_THREAD at the same time**********//
`define CASE_2W16T
//`define CASE_4W32T
//`define CASE_4W8T
//`define CASE_8W4T


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
  reg [META_FNAME_SIZE*8-1:0] meta_fname[9:0];
  reg [DATA_FNAME_SIZE*8-1:0] data_fname[9:0];

  initial begin
    repeat(500)
    @(posedge clk);
    init_test_file();
    test_bfs();
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

     `ifdef CASE_2W16T
      meta_fname[0] = "2w16t/BFS_1_0.metadata";
      meta_fname[1] = "2w16t/BFS_2_0.metadata";
      meta_fname[2] = "2w16t/BFS_1_1.metadata";
      meta_fname[3] = "2w16t/BFS_2_1.metadata";
      meta_fname[4] = "2w16t/BFS_1_2.metadata";
      meta_fname[5] = "2w16t/BFS_2_2.metadata";
      meta_fname[6] = "2w16t/BFS_1_3.metadata";
      meta_fname[7] = "2w16t/BFS_2_3.metadata";

      data_fname[0] = "2w16t/BFS_1_0.data";
      data_fname[1] = "2w16t/BFS_2_0.data";
      data_fname[2] = "2w16t/BFS_1_1.data";
      data_fname[3] = "2w16t/BFS_2_1.data";
      data_fname[4] = "2w16t/BFS_1_2.data";
      data_fname[5] = "2w16t/BFS_2_2.data";
      data_fname[6] = "2w16t/BFS_1_3.data";
      data_fname[7] = "2w16t/BFS_2_3.data";
     `endif

     `ifdef CASE_4W32T
      meta_fname[0] = "4x32/BFS_1_0.metadata";
      meta_fname[1] = "4x32/BFS_2_0.metadata";
      meta_fname[2] = "4x32/BFS_1_1.metadata";
      meta_fname[3] = "4x32/BFS_2_1.metadata";
      meta_fname[4] = "4x32/BFS_1_2.metadata";
      meta_fname[5] = "4x32/BFS_2_2.metadata";
      meta_fname[6] = "4x32/BFS_1_3.metadata";
      meta_fname[7] = "4x32/BFS_2_3.metadata";
      meta_fname[8] = "4x32/BFS_1_4.metadata";
      meta_fname[9] = "4x32/BFS_2_4.metadata";

      data_fname[0] = "4x32/BFS_1_0.data";
      data_fname[1] = "4x32/BFS_2_0.data";
      data_fname[2] = "4x32/BFS_1_1.data";
      data_fname[3] = "4x32/BFS_2_1.data";
      data_fname[4] = "4x32/BFS_1_2.data";
      data_fname[5] = "4x32/BFS_2_2.data";
      data_fname[6] = "4x32/BFS_1_3.data";
      data_fname[7] = "4x32/BFS_2_3.data";
      data_fname[8] = "4x32/BFS_1_4.data";
      data_fname[9] = "4x32/BFS_2_4.data";
     `endif

     `ifdef CASE_4W8T
      meta_fname[0] = "4x8/BFS_1_0.metadata";
      meta_fname[1] = "4x8/BFS_2_0.metadata";
      meta_fname[2] = "4x8/BFS_1_1.metadata";
      meta_fname[3] = "4x8/BFS_2_1.metadata";
      meta_fname[4] = "4x8/BFS_1_2.metadata";
      meta_fname[5] = "4x8/BFS_2_2.metadata";
      meta_fname[6] = "4x8/BFS_1_3.metadata";
      meta_fname[7] = "4x8/BFS_2_3.metadata";

      data_fname[0] = "4x8/BFS_1_0.data";
      data_fname[1] = "4x8/BFS_2_0.data";
      data_fname[2] = "4x8/BFS_1_1.data";
      data_fname[3] = "4x8/BFS_2_1.data";
      data_fname[4] = "4x8/BFS_1_2.data";
      data_fname[5] = "4x8/BFS_2_2.data";
      data_fname[6] = "4x8/BFS_1_3.data";
      data_fname[7] = "4x8/BFS_2_3.data";
     `endif

     `ifdef CASE_8W4T
      meta_fname[0] = "8w4t/BFS_1_0.metadata";
      meta_fname[1] = "8w4t/BFS_2_0.metadata";
      meta_fname[2] = "8w4t/BFS_1_1.metadata";
      meta_fname[3] = "8w4t/BFS_2_1.metadata";
      meta_fname[4] = "8w4t/BFS_1_2.metadata";
      meta_fname[5] = "8w4t/BFS_2_2.metadata";
      meta_fname[6] = "8w4t/BFS_1_3.metadata";
      meta_fname[7] = "8w4t/BFS_2_3.metadata";

      data_fname[0] = "8w4t/BFS_1_0.data";
      data_fname[1] = "8w4t/BFS_2_0.data";
      data_fname[2] = "8w4t/BFS_1_1.data";
      data_fname[3] = "8w4t/BFS_2_1.data";
      data_fname[4] = "8w4t/BFS_1_2.data";
      data_fname[5] = "8w4t/BFS_2_2.data";
      data_fname[6] = "8w4t/BFS_1_3.data";
      data_fname[7] = "8w4t/BFS_2_3.data";
     `endif

    end
  endtask

  task test_bfs;
    integer i;
    begin
     `ifdef CASE_4W32T
      for(i=0; i<10; i=i+1) begin
        `init_mem(meta_fname[i], data_fname[i]);
        `drv_gpu(meta_fname[i], data_fname[i]);
        if(i==0) begin
          `get_result_addr(meta_fname[i], data_fname[i]);
        end
        `exe_finish(meta_fname[i], data_fname[i]);
        if(i==9) begin
          print_result();
        end
      end
     `else
      for(i=0; i<8; i=i+1) begin
        `init_mem(meta_fname[i], data_fname[i]);
        `drv_gpu(meta_fname[i], data_fname[i]);
        if(i==0) begin
          `get_result_addr(meta_fname[i], data_fname[i]);
        end
        `exe_finish(meta_fname[i], data_fname[i]);
        if(i==7) begin
          print_result();
        end
      end
     `endif
    end
  endtask

  task mem_drv;
    begin
      while(1) fork
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
    reg [31:0]    result_32_soft  [31:0]  ;
    reg [31:0]    result_32_hard  [31:0]  ;
    reg [31:0]    result_32_pass          ;
    reg [31:0]    result_128_soft [127:0] ;
    reg [31:0]    result_128_hard [127:0] ;
    reg [127:0]   result_128_pass         ;

    result_32_soft  = {0,1,3,2,2,3,1,3,2,1,3,2,2,2,1,2,2,3,2,2,2,1,2,3,1,2,3,2,2,2,1,2};
    result_128_soft  = {0,4,4,3,3,4,3,4,3,3,4,3,3,3,4,3,3,4,4,3,4,2,2,4,4,2,3,1,3,2,4,4,2,4,3,4,3,1,3,4,2,3,3,2,3,2,4,3,3,3,3,4,3,3,4,4,3,2,4,2,3,1,4,3,3,2,1,4,3,3,4,2,3,3,3,3,2,3,3,4,3,3,4,3,4,2,2,3,3,3,3,4,3,3,3,2,3,3,4,4,3,4,4,4,4,2,3,3,3,4,4,3,4,3,4,3,3,4,4,3,2,4,4,3,3,3,3,3};


    if(`l2_flush_finish) begin
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      $display("-------------case_bfs result------------");
      $display("--------------final result :------------");
      for(integer addr=`parsed_base[5]; addr<`parsed_base[5]+`parsed_size[5]; addr=addr+4) begin
        //$fwrite(file1,"0x%h %h%h%h%h\n",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
        $display("          0x%h %h%h%h%h",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
        `ifdef CASE_4W32T
          result_128_hard[(addr-`parsed_base[5])/4]  = {`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]};
        `else
          result_32_hard[(addr-`parsed_base[5])/4]  = {`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]};
        `endif
      end

      `ifdef CASE_4W32T
          for(integer j=0; j<128; j=j+1) begin        
            if(result_128_hard[j]==result_128_soft[127-j]) begin
              result_128_pass[j]  = 1'b1;
            end else begin
              result_128_pass[j]  = 1'b0;
            end
          end
      `else
          for(integer j=0; j<32; j=j+1) begin        
            if(result_32_hard[j]==result_32_soft[31-j]) begin
              result_32_pass[j]  = 1'b1;
            end else begin
              result_32_pass[j]  = 1'b0;
            end
          end
      `endif

      `ifdef CASE_2W16T
            if(&result_32_pass) begin
              $display("***********case_bfs_2w16t**********");
              PASSED;
            end else begin
              $display("***********case_bfs_2w16t**********");
              $display("***************FAILED**************");
            end
      `endif
      `ifdef CASE_4W32T
            if(&result_128_pass) begin
              $display("***********case_bfs_4w32t**********");
              $display("****************PASS***************");
            end else begin
              $display("***********case_bfs_4w32t**********");
              $display("***************FAILED**************");
            end
      `endif
      `ifdef CASE_4W8T
            if(&result_32_pass) begin
              $display("***********case_bfs_4w8t***********");
              $display("****************PASS***************");
            end else begin
              $display("***********case_bfs_4w8t***********");
              $display("***************FAILED**************");
            end
      `endif
      `ifdef CASE_8W4T
            if(&result_32_pass) begin
              $display("***********case_bfs_8w4t***********");
              $display("****************PASS***************");
            end else begin
              $display("***********case_bfs_8w4t***********");
              $display("***************FAILED**************");
            end
      `endif
    end
  endtask


endmodule

