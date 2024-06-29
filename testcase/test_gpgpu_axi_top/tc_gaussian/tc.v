
`define drv_gpu               u_host_inter.drv_gpu
`define exe_finish            u_host_inter.exe_finish
`define get_result_addr       u_host_inter.get_result_addr
`define parsed_base           u_host_inter.parsed_base_r
`define parsed_size           u_host_inter.parsed_size_r
`define kernel_cycles         u_host_inter.kernel_cycles

`define display_mem           u_ram.display_mem
`define store_mem             u_ram.store_mem
`define mem_tmp_1             u_ram.mem_tmp_1
`define mem_tmp_2             u_ram.mem_tmp_2


//**********Selsct gaussian test case, remember modify `define NUM_THREAD at the same time**********
//`define CASE_2W8T
//`define CASE_1W16T
//`define CASE_4W4T
//`define CASE_4W8T


module tc;
  parameter METADATA_SIZE   = 1024; //the maximun size of .data
  parameter DATADATA_SIZE   = 2000; //the maximun size of .metadata

  parameter META_FNAME_SIZE = 128;
  parameter DATA_FNAME_SIZE = 128;

  parameter BUF_NUM         = 18;

  `ifdef CASE_4W8T
  parameter FILE_NUM        = 8;
  `else
  parameter FILE_NUM        = 6;
  `endif

  defparam u_host_inter.META_FNAME_SIZE = META_FNAME_SIZE;
  defparam u_host_inter.DATA_FNAME_SIZE = DATA_FNAME_SIZE;
  defparam u_host_inter.METADATA_SIZE   = METADATA_SIZE;
  defparam u_host_inter.DATADATA_SIZE   = DATADATA_SIZE;

  wire clk  = u_gen_clk.clk;
  wire rstn = u_gen_rst.rst_n;
 
  reg [META_FNAME_SIZE*8-1:0] meta_fname[7:0];
  reg [DATA_FNAME_SIZE*8-1:0] data_fname[7:0];
  
  reg [31:0] sum_cycles = 32'b0;  

  initial begin
    repeat(100)
    @(posedge clk);
    init_test_file();
    test_main();
    repeat(100)
    @(posedge clk);
    $finish();
  end

  task init_test_file;
    begin

     `ifdef CASE_2W8T
     meta_fname[0] = "./softdata/2x8/Fan1_0.metadata";
     meta_fname[1] = "./softdata/2x8/Fan2_0.metadata";
     meta_fname[2] = "./softdata/2x8/Fan1_1.metadata";
     meta_fname[3] = "./softdata/2x8/Fan2_1.metadata";
     meta_fname[4] = "./softdata/2x8/Fan1_2.metadata";
     meta_fname[5] = "./softdata/2x8/Fan2_2.metadata";

     data_fname[0] = "./softdata/2x8/Fan1_0.data";
     data_fname[1] = "./softdata/2x8/Fan2_0.data";
     data_fname[2] = "./softdata/2x8/Fan1_1.data";
     data_fname[3] = "./softdata/2x8/Fan2_1.data";
     data_fname[4] = "./softdata/2x8/Fan1_2.data";
     data_fname[5] = "./softdata/2x8/Fan2_2.data";
     `endif

     `ifdef CASE_1W16T
     meta_fname[0] = "./softdata/1w16t/Fan1_0.metadata";
     meta_fname[1] = "./softdata/1w16t/Fan2_0.metadata";
     meta_fname[2] = "./softdata/1w16t/Fan1_1.metadata";
     meta_fname[3] = "./softdata/1w16t/Fan2_1.metadata";
     meta_fname[4] = "./softdata/1w16t/Fan1_2.metadata";
     meta_fname[5] = "./softdata/1w16t/Fan2_2.metadata";

     data_fname[0] = "./softdata/1w16t/Fan1_0.data";
     data_fname[1] = "./softdata/1w16t/Fan2_0.data";
     data_fname[2] = "./softdata/1w16t/Fan1_1.data";
     data_fname[3] = "./softdata/1w16t/Fan2_1.data";
     data_fname[4] = "./softdata/1w16t/Fan1_2.data";
     data_fname[5] = "./softdata/1w16t/Fan2_2.data";
     `endif

     `ifdef CASE_4W4T
     meta_fname[0] = "./softdata/4x4/Fan1_0.metadata";
     meta_fname[1] = "./softdata/4x4/Fan2_0.metadata";
     meta_fname[2] = "./softdata/4x4/Fan1_1.metadata";
     meta_fname[3] = "./softdata/4x4/Fan2_1.metadata";
     meta_fname[4] = "./softdata/4x4/Fan1_2.metadata";
     meta_fname[5] = "./softdata/4x4/Fan2_2.metadata";

     data_fname[0] = "./softdata/4x4/Fan1_0.data";
     data_fname[1] = "./softdata/4x4/Fan2_0.data";
     data_fname[2] = "./softdata/4x4/Fan1_1.data";
     data_fname[3] = "./softdata/4x4/Fan2_1.data";
     data_fname[4] = "./softdata/4x4/Fan1_2.data";
     data_fname[5] = "./softdata/4x4/Fan2_2.data";
     `endif

     `ifdef CASE_4W8T
     meta_fname[0] = "./softdata/4x8/Fan1_0.metadata";
     meta_fname[1] = "./softdata/4x8/Fan2_0.metadata";
     meta_fname[2] = "./softdata/4x8/Fan1_1.metadata";
     meta_fname[3] = "./softdata/4x8/Fan2_1.metadata";
     meta_fname[4] = "./softdata/4x8/Fan1_2.metadata";
     meta_fname[5] = "./softdata/4x8/Fan2_2.metadata";
     meta_fname[6] = "./softdata/4x8/Fan1_3.metadata";
     meta_fname[7] = "./softdata/4x8/Fan2_3.metadata";

     data_fname[0] = "./softdata/4x8/Fan1_0.data";
     data_fname[1] = "./softdata/4x8/Fan2_0.data";
     data_fname[2] = "./softdata/4x8/Fan1_1.data";
     data_fname[3] = "./softdata/4x8/Fan2_1.data";
     data_fname[4] = "./softdata/4x8/Fan1_2.data";
     data_fname[5] = "./softdata/4x8/Fan2_2.data";
     data_fname[6] = "./softdata/4x8/Fan1_3.data";
     data_fname[7] = "./softdata/4x8/Fan2_3.data";
     `endif
    end
  endtask

  task test_main;
    integer i;
    begin
      for(i=0; i<FILE_NUM; i=i+1) begin
        force u_dut.l2_2_mem.m_axi_bvalid_i = 1'd0;
        init_mem(meta_fname[i], data_fname[i]);
        release u_dut.l2_2_mem.m_axi_bvalid_i;
        `drv_gpu(meta_fname[i], data_fname[i]);
        if(i==0) begin
          `get_result_addr(meta_fname[i], data_fname[i]);
        end
        `exe_finish(meta_fname[i], data_fname[i]);
        sum_cycles = sum_cycles + `kernel_cycles;        
        if(i==(FILE_NUM-1)) begin
          print_result();
        end
        repeat(10)
        @(posedge clk);
      end
    end
  endtask

  task init_mem;
    input      [META_FNAME_SIZE*8-1:0] fn_metadata;
    input      [DATA_FNAME_SIZE*8-1:0] fn_data;
    reg [63:0] buf_num_soft;
    reg [31:0] data         [DATADATA_SIZE-1:0];
    reg [31:0] metadata     [METADATA_SIZE-1:0];
    reg [63:0] buf_ba_w     [BUF_NUM-1:0]; //buffer's base addr
    reg [63:0] buf_size     [BUF_NUM-1:0]; //buffer's size
    reg [63:0] buf_size_tmp [BUF_NUM-1:0]; //size align
    reg [63:0] buf_asize    [BUF_NUM-1:0]; //buffer's allocate size
    reg [63:0] burst_len    [BUF_NUM-1:0]; //burst len
    reg [63:0] burst_len_div[BUF_NUM-1:0];
    reg [63:0] burst_len_mod[BUF_NUM-1:0];
    reg [63:0] burst_times  [BUF_NUM-1:0];
    reg [63:0] burst_data   /*[BUF_NUM-1:0]*/;
    reg [32:0] addr;
    integer i, j, k, l, m;
    begin
      $readmemh(fn_data, data);
      $readmemh(fn_metadata, metadata);
      buf_num_soft = {metadata[27], metadata[26]};

      //buffer base addr init
      for(i=0; i<buf_num_soft; i=i+1) begin
        buf_ba_w[i] = {metadata[i*2+29], metadata[i*2+28]};
      end

      //buffer size init
      for(i=0; i<buf_num_soft; i=i+1) begin
        buf_size[i] = {metadata[i*2+29+(buf_num_soft*2)], metadata[i*2+28+(buf_num_soft*2)]};
      end

      //buffer allocate size init,unused
      for(i=0; i<buf_num_soft; i=i+1) begin
        buf_asize[i] = {metadata[i*2+29+buf_num_soft*4], metadata[i*2+28+buf_num_soft*4]};
      end
      
      for(i=0;i<buf_num_soft;i=i+1) begin
        buf_size_tmp[i] = (buf_size[i]%4==0) ? buf_size[i] : (buf_size[i]/4)*4+4;
        burst_len[i] = buf_size_tmp[i]/4;
        burst_len_div[i] = burst_len[i]/16;
        burst_len_mod[i] = burst_len[i]%16;
        burst_times[i] = (burst_len_mod[i]==0) ? burst_len_div[i] : burst_len_div[i]+1;
        //burst_data[i] = (burst_len_mod[i]==0) ? 16 : (k<burst_times[j]-1) ? 16 : burst_len_mod[i];
      end 

      j=0; //buf_num cnt
      m=0;
      while(j<buf_num_soft) begin
        force u_ram.s_axi_bready  = 1'd1;
        k=0;
        while(k<burst_times[j]) begin
          @(posedge clk);
          if(burst_len_mod[j]==0) begin
            force u_ram.s_axi_awvalid = 1'd1;
            force u_ram.s_axi_awid    = 4'd0;
            force u_ram.s_axi_awaddr  = (k==0) ? buf_ba_w[j] : addr+16*4;//start address
            force u_ram.s_axi_awlen   = 8'hf; //16 times
            force u_ram.s_axi_awsize  = 3'd2; //4bytes
            force u_ram.s_axi_awburst = 2'd1; //INCR
          end
          else begin
            force u_ram.s_axi_awvalid = 1'd1;
            force u_ram.s_axi_awid    = 4'd0;
            force u_ram.s_axi_awaddr  = (k==0) ? buf_ba_w[j] : addr+16*4;//start address
            force u_ram.s_axi_awlen   = (k==(burst_times[j]-1))? burst_len_mod[j]-1 : 8'hf; 
            force u_ram.s_axi_awsize  = 3'd2; //4bytes
            force u_ram.s_axi_awburst = 2'd1; //INCR
          end 
          wait(u_ram.s_axi_awready==1'd1);
          @(posedge clk);
          addr                        = u_ram.s_axi_awaddr;
          release u_ram.s_axi_awvalid;
          release u_ram.s_axi_awid;   
          release u_ram.s_axi_awaddr; 
          release u_ram.s_axi_awlen;  
          release u_ram.s_axi_awsize;
          release u_ram.s_axi_awburst;
          l=0;
          burst_data = (burst_len_mod[j]==0) ? 16 : ((k<burst_times[j]-1) ? 16 : burst_len_mod[j]);
          while(l<burst_data) begin
            force u_ram.s_axi_wvalid  = 1'd1;
            force u_ram.s_axi_wdata   = (l%2==0) ? {32'd0,data[m]} : {data[m],32'd0};
            force u_ram.s_axi_wstrb   = (l%2==0) ? 8'hf : 8'hf0;
            if(l==burst_data-1)begin
              force u_ram.s_axi_wlast = 1'd1;
            end 
            wait(u_ram.s_axi_wready==1'd1);
            @(posedge clk);
            release u_ram.s_axi_wvalid;  
            release u_ram.s_axi_wdata;
            release u_ram.s_axi_wstrb;   
            release u_ram.s_axi_wlast;
            l=l+1;
            m=m+1;
          end 
          k=k+1;
        end
      wait(u_ram.s_axi_bvalid==1'd1);
      @(posedge clk);
      release u_ram.s_axi_bready;
      j=j+1;
      end 
    end
  endtask


  task print_result;
    reg   [31:0]    matrix_a_4_soft   [15:0];
    reg   [31:0]    array_b_4_soft    [3:0] ;
    reg   [15:0]    matrix_4_pass           ;
    reg   [3:0]     array_4_pass            ;
    reg   [31:0]    matrix_a_5_soft   [24:0];
    reg   [31:0]    array_b_5_soft    [4:0] ;
    reg   [24:0]    matrix_5_pass           ;
    reg   [4:0]     array_5_pass            ;
    reg   [31:0]    matrix_addr_size        ;
    reg   [31:0]    array_addr_size         ;
    integer i,j;
    begin
      @(posedge clk);

      matrix_a_4_soft = {32'hbf19999a,32'hbf000000,32'h3f333333,32'h3e99999a,32'h00000000,32'hbf266666,32'hbd4cccc8,32'h3f0ccccc,32'hb26eeef0,32'h31424c20,32'hbf40fc10,32'hbf920d21,32'h00000000,32'hb0c4ec50,32'h32036a80,32'h3f0042df};
      array_b_4_soft  = {32'hbf59999a,32'hbe828f5c,32'h3f5f3ec0,32'hbe8042e0};
      matrix_a_5_soft = {32'h3e4ccccd,32'hbf800000,32'h3e99999a,32'h3f800000,32'h3f333333,32'h00000000,32'h3e4ccccd,32'hbf333333,32'hbf666666,32'hbf000000,32'h32000000,32'hb3a00000,32'h40be6666,32'h40c00000,32'h40700000,32'h32000000,32'hb389999a,32'hb40f0148,32'h3dd11a60,32'h3e9d78e3,32'h33200000,32'hb3000000,32'h34509090,32'h31964000,32'h408591e8};
      array_b_5_soft  = {32'h3fc00000,32'hbf451eb8,32'h40799999,32'hbcff0d0a,32'hbfd5b642};

      matrix_addr_size  = (`parsed_size[1]%8==0) ? `parsed_size[1]/8 : (`parsed_size[1]/8)+1;
      array_addr_size   = (`parsed_size[2]%8==0) ? `parsed_size[2]/8 : (`parsed_size[2]/8)+1;

      $display("----------case_gaussian result----------");
      $display("----------------matrix a:---------------");
      for(i=0; i<matrix_addr_size; i=i+1) begin
        `display_mem(`parsed_base[1]+i*8);        
      end
      //for(integer addr=`parsed_base[1]; addr<`parsed_base[1]+`parsed_size[1]; addr=addr+4) begin
      //  //$fwrite(file1,"0x%h %h%h%h%h\n",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
      //  $display("          0x%h %h%h%h%h",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
      //  `ifdef CASE_4W8T
      //     matrix_a_5_hard[(addr-`parsed_base[1])/4]  = {`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]};
      //   `else
      //     matrix_a_4_hard[(addr-`parsed_base[1])/4]  = {`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]};
      //   `endif
      //end

      $display("----------------array b:----------------");
      for(j=0; j<array_addr_size; j=j+1) begin
        `display_mem(`parsed_base[2]+j*8);        
      end
      //for(integer addr=`parsed_base[2]; addr<`parsed_base[2]+`parsed_size[2]; addr=addr+4) begin
      //  //$fwrite(file1,"0x%h %h%h%h%h\n",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
      //  $display("          0x%h %h%h%h%h",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
      //  `ifdef CASE_4W8T
      //    array_b_5_hard[(addr-`parsed_base[2])/4]  = {`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]};
      //  `else
      //    array_b_4_hard[(addr-`parsed_base[2])/4]  = {`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]};
      //  `endif
      //end
      
      `store_mem(`parsed_base[1],`parsed_base[2],`parsed_size[1],`parsed_size[2],1,1);

      `ifdef CASE_4W8T
        for(integer j=0; j<25; j=j+1) begin        
          if(`mem_tmp_1[j]==matrix_a_5_soft[24-j]) begin
            matrix_5_pass[j]  = 1'b1;
          end else begin
            matrix_5_pass[j]  = 1'b0;
          end
        end
        for(integer i=0; i<5; i=i+1) begin        
          if(`mem_tmp_2[i]==array_b_5_soft[4-i]) begin
            array_5_pass[i]  = 1'b1;
          end else begin
            array_5_pass[i]  = 1'b0;
          end
        end
      `else
        for(integer j=0; j<16; j=j+1) begin        
          if(`mem_tmp_1[j]==matrix_a_4_soft[15-j]) begin
            matrix_4_pass[j]  = 1'b1;
          end else begin
            matrix_4_pass[j]  = 1'b0;
          end
        end
        for(integer i=0; i<4; i=i+1) begin        
          if(`mem_tmp_2[i]==array_b_4_soft[3-i]) begin
            array_4_pass[i]  = 1'b1;
          end else begin
            array_4_pass[i]  = 1'b0;
          end
        end
      `endif

      `ifdef CASE_2W8T
        if((&matrix_4_pass) && (&array_4_pass)) begin
          $display("***********case_guassian_2w8t**********");
          PASSED;
        end else begin
          $display("***********case_guassian_2w8t**********");
          FAILED;
        end
      `endif
      `ifdef CASE_1W16T
        if((&matrix_4_pass) && (&array_4_pass)) begin
          $display("***********case_guassian_1w16t*********");
          PASSED;
        end else begin
          $display("***********case_guassian_1w16t*********");
          FAILED;
        end
      `endif
      `ifdef CASE_4W4T
        if((&matrix_4_pass) && (&array_4_pass)) begin
          $display("***********case_guassian_4w4t**********");
          PASSED;
        end else begin
          $display("***********case_guassian_4w4t**********");
          FAILED;
        end
      `endif
      `ifdef CASE_4W8T
        if((&matrix_5_pass) && (&array_5_pass)) begin
          $display("***********case_guassian_4w8t**********");
          PASSED;
        end else begin
          $display("***********case_guassian_4w8t**********");
          FAILED;
        end
      `endif

      $display("************************************");
      $display("************************************");
      $display("All kernels need : %p cycles",sum_cycles);       
      $display("************************************");
      $display("************************************");
      

    end
  endtask

endmodule

