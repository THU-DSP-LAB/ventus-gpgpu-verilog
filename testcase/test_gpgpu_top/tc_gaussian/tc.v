
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

//**********Selsct gaussian test case, remember modify `define NUM_THREAD at the same time**********
`define CASE_2W8T
//`define CASE_1W16T
//`define CASE_4W4T
//`define CASE_4W8T


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
    test_gaussian();
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

     `ifdef CASE_2W8T
     meta_fname[0] = "2x8/Fan1_0.metadata";
     meta_fname[1] = "2x8/Fan2_0.metadata";
     meta_fname[2] = "2x8/Fan1_1.metadata";
     meta_fname[3] = "2x8/Fan2_1.metadata";
     meta_fname[4] = "2x8/Fan1_2.metadata";
     meta_fname[5] = "2x8/Fan2_2.metadata";

     data_fname[0] = "2x8/Fan1_0.data";
     data_fname[1] = "2x8/Fan2_0.data";
     data_fname[2] = "2x8/Fan1_1.data";
     data_fname[3] = "2x8/Fan2_1.data";
     data_fname[4] = "2x8/Fan1_2.data";
     data_fname[5] = "2x8/Fan2_2.data";
     `endif

     `ifdef CASE_1W16T
     meta_fname[0] = "1w16t/Fan1_0.metadata";
     meta_fname[1] = "1w16t/Fan2_0.metadata";
     meta_fname[2] = "1w16t/Fan1_1.metadata";
     meta_fname[3] = "1w16t/Fan2_1.metadata";
     meta_fname[4] = "1w16t/Fan1_2.metadata";
     meta_fname[5] = "1w16t/Fan2_2.metadata";

     data_fname[0] = "1w16t/Fan1_0.data";
     data_fname[1] = "1w16t/Fan2_0.data";
     data_fname[2] = "1w16t/Fan1_1.data";
     data_fname[3] = "1w16t/Fan2_1.data";
     data_fname[4] = "1w16t/Fan1_2.data";
     data_fname[5] = "1w16t/Fan2_2.data";
     `endif

     `ifdef CASE_4W4T
     meta_fname[0] = "4x4/Fan1_0.metadata";
     meta_fname[1] = "4x4/Fan2_0.metadata";
     meta_fname[2] = "4x4/Fan1_1.metadata";
     meta_fname[3] = "4x4/Fan2_1.metadata";
     meta_fname[4] = "4x4/Fan1_2.metadata";
     meta_fname[5] = "4x4/Fan2_2.metadata";

     data_fname[0] = "4x4/Fan1_0.data";
     data_fname[1] = "4x4/Fan2_0.data";
     data_fname[2] = "4x4/Fan1_1.data";
     data_fname[3] = "4x4/Fan2_1.data";
     data_fname[4] = "4x4/Fan1_2.data";
     data_fname[5] = "4x4/Fan2_2.data";
     `endif

     `ifdef CASE_4W8T
     meta_fname[0] = "4x8/Fan1_0.metadata";
     meta_fname[1] = "4x8/Fan2_0.metadata";
     meta_fname[2] = "4x8/Fan1_1.metadata";
     meta_fname[3] = "4x8/Fan2_1.metadata";
     meta_fname[4] = "4x8/Fan1_2.metadata";
     meta_fname[5] = "4x8/Fan2_2.metadata";
     meta_fname[6] = "4x8/Fan1_3.metadata";
     meta_fname[7] = "4x8/Fan2_3.metadata";

     data_fname[0] = "4x8/Fan1_0.data";
     data_fname[1] = "4x8/Fan2_0.data";
     data_fname[2] = "4x8/Fan1_1.data";
     data_fname[3] = "4x8/Fan2_1.data";
     data_fname[4] = "4x8/Fan1_2.data";
     data_fname[5] = "4x8/Fan2_2.data";
     data_fname[6] = "4x8/Fan1_3.data";
     data_fname[7] = "4x8/Fan2_3.data";
     `endif
    end
  endtask

  task test_gaussian;
    integer i;
    begin
     `ifdef CASE_4W8T
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
     `else
      for(i=0; i<6; i=i+1) begin
        `init_mem(meta_fname[i], data_fname[i]);
        `drv_gpu(meta_fname[i], data_fname[i]);
        if(i==0) begin
          `get_result_addr(meta_fname[i], data_fname[i]);
        end
        `exe_finish(meta_fname[i], data_fname[i]);
        if(i==5) begin
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
    reg   [31:0]    matrix_a_4_soft   [15:0];
    reg   [31:0]    array_b_4_soft    [3:0] ;
    reg   [31:0]    matrix_a_4_hard   [15:0];
    reg   [31:0]    array_b_4_hard    [3:0] ;
    reg   [15:0]    matrix_4_pass           ;
    reg   [3:0]     array_4_pass            ;
    reg   [31:0]    matrix_a_5_soft   [24:0];
    reg   [31:0]    array_b_5_soft    [4:0] ;
    reg   [31:0]    matrix_a_5_hard   [24:0];
    reg   [31:0]    array_b_5_hard    [4:0] ;
    reg   [24:0]    matrix_5_pass           ;
    reg   [4:0]     array_5_pass            ;

    matrix_a_4_soft = {32'hbf19999a,32'hbf000000,32'h3f333333,32'h3e99999a,32'h00000000,32'hbf266666,32'hbd4cccc8,32'h3f0ccccc,32'hb26eeef0,32'h31424c20,32'hbf40fc10,32'hbf920d21,32'h00000000,32'hb0c4ec50,32'h32036a80,32'h3f0042df};
    array_b_4_soft  = {32'hbf59999a,32'hbe828f5c,32'h3f5f3ec0,32'hbe8042e0};
    matrix_a_5_soft = {32'h3e4ccccd,32'hbf800000,32'h3e99999a,32'h3f800000,32'h3f333333,32'h00000000,32'h3e4ccccd,32'hbf333333,32'hbf666666,32'hbf000000,32'h32000000,32'hb3a00000,32'h40be6666,32'h40c00000,32'h40700000,32'h32000000,32'hb389999a,32'hb40f0148,32'h3dd11a60,32'h3e9d78e3,32'h33200000,32'hb3000000,32'h34509090,32'h31964000,32'h408591e8};
    array_b_5_soft  = {32'h3fc00000,32'hbf451eb8,32'h40799999,32'hbcff0d0a,32'hbfd5b642};

    //if(`l2_flush_finish) begin
    if(`host_rsp_valid) begin
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      $display("----------case_gaussian result----------");
      $display("----------------matrix a:---------------");
      for(integer addr=`parsed_base[1]; addr<`parsed_base[1]+`parsed_size[1]; addr=addr+4) begin
        //$fwrite(file1,"0x%h %h%h%h%h\n",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
        $display("          0x%h %h%h%h%h",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
        `ifdef CASE_4W8T
           matrix_a_5_hard[(addr-`parsed_base[1])/4]  = {`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]};
         `else
           matrix_a_4_hard[(addr-`parsed_base[1])/4]  = {`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]};
         `endif
      end

      $display("----------------array b:----------------");
      for(integer addr=`parsed_base[2]; addr<`parsed_base[2]+`parsed_size[2]; addr=addr+4) begin
        //$fwrite(file1,"0x%h %h%h%h%h\n",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
        $display("          0x%h %h%h%h%h",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
        `ifdef CASE_4W8T
          array_b_5_hard[(addr-`parsed_base[2])/4]  = {`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]};
        `else
          array_b_4_hard[(addr-`parsed_base[2])/4]  = {`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]};
        `endif
      end

      `ifdef CASE_4W8T
        for(integer j=0; j<25; j=j+1) begin        
          if(matrix_a_5_hard[j]==matrix_a_5_soft[24-j]) begin
            matrix_5_pass[j]  = 1'b1;
          end else begin
            matrix_5_pass[j]  = 1'b0;
          end
        end
        for(integer i=0; i<5; i=i+1) begin        
          if(array_b_5_hard[i]==array_b_5_soft[4-i]) begin
            array_5_pass[i]  = 1'b1;
          end else begin
            array_5_pass[i]  = 1'b0;
          end
        end
      `else
        for(integer j=0; j<16; j=j+1) begin        
          if(matrix_a_4_hard[j]==matrix_a_4_soft[15-j]) begin
            matrix_4_pass[j]  = 1'b1;
          end else begin
            matrix_4_pass[j]  = 1'b0;
          end
        end
        for(integer i=0; i<4; i=i+1) begin        
          if(array_b_4_hard[i]==array_b_4_soft[3-i]) begin
            array_4_pass[i]  = 1'b1;
          end else begin
            array_4_pass[i]  = 1'b0;
          end
        end
      `endif

      `ifdef CASE_2W8T
        if((&matrix_4_pass) && (&array_4_pass)) begin
          $display("***********case_guassian_2w8t**********");
          $display("******************PASS*****************");
        end else begin
          $display("***********case_guassian_2w8t**********");
          $display("*****************FAILED****************");
        end
      `endif
      `ifdef CASE_1W16T
        if((&matrix_4_pass) && (&array_4_pass)) begin
          $display("***********case_guassian_1w16t*********");
          $display("******************PASS*****************");
        end else begin
          $display("***********case_guassian_1w16t*********");
          $display("*****************FAILED****************");
        end
      `endif
      `ifdef CASE_4W4T
        if((&matrix_4_pass) && (&array_4_pass)) begin
          $display("***********case_guassian_4w4t**********");
          PASSED;
        end else begin
          $display("***********case_guassian_4w4t**********");
          $display("****************FAILED*****************");
        end
      `endif
      `ifdef CASE_4W8T
        if((&matrix_5_pass) && (&array_5_pass)) begin
          $display("***********case_guassian_4w8t**********");
          $display("******************PASS*****************");
        end else begin
          $display("***********case_guassian_4w8t**********");
          $display("****************FAILED*****************");
        end
      `endif
    end
  endtask

endmodule

