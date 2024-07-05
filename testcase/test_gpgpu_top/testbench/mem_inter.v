
`define host_req_valid          gpu_test.host_req_valid_i
`define l2_flush_finish         test_gpu_top.gpu_test.B1[0].l2cache.SourceD_finish_issue_o
`define mem                     u_mem_inter.mem


module mem_inter(
  input                                     clk,
  input                                     rstn,
  input   [`NUM_L2CACHE-1:0]                out_a_valid_o,
  output  [`NUM_L2CACHE-1:0]                out_a_ready_i,
  input   [`NUM_L2CACHE*`OP_BITS-1:0]       out_a_opcode_o,
  input   [`NUM_L2CACHE*`SIZE_BITS-1:0]     out_a_size_o,
  input   [`NUM_L2CACHE*`SOURCE_BITS-1:0]   out_a_source_o,
  input   [`NUM_L2CACHE*`ADDRESS_BITS-1:0]  out_a_address_o,
  input   [`NUM_L2CACHE*`MASK_BITS-1:0]     out_a_mask_o,
  input   [`NUM_L2CACHE*`DATA_BITS-1:0]     out_a_data_o,
  input   [`NUM_L2CACHE*3-1:0]              out_a_param_o,

  output  [`NUM_L2CACHE-1:0]                out_d_valid_i,
  input   [`NUM_L2CACHE-1:0]                out_d_ready_o,
  output  [`NUM_L2CACHE*`OP_BITS-1:0]       out_d_opcode_i,
  output  [`NUM_L2CACHE*`SIZE_BITS-1:0]     out_d_size_i,
  output  [`NUM_L2CACHE*`SOURCE_BITS-1:0]   out_d_source_i,
  output  [`NUM_L2CACHE*`DATA_BITS-1:0]     out_d_data_i,
  output  [`NUM_L2CACHE*3-1:0]              out_d_param_i
  );
  //---------------------------------------------------------
  reg  [`NUM_L2CACHE-1:0]                out_a_ready_r;
  reg  [`NUM_L2CACHE-1:0]                out_d_valid_r;
  reg  [`NUM_L2CACHE*`OP_BITS-1:0]       out_d_opcode_r;
  reg  [`NUM_L2CACHE*`SIZE_BITS-1:0]     out_d_size_r;
  reg  [`NUM_L2CACHE*`SOURCE_BITS-1:0]   out_d_source_r;
  reg  [`NUM_L2CACHE*`DATA_BITS-1:0]     out_d_data_r;
  reg  [`NUM_L2CACHE*3-1:0]              out_d_param_r;
 
  assign  out_a_ready_i  = out_a_ready_r;
  assign  out_d_valid_i  = out_d_valid_r;
  assign  out_d_opcode_i = out_d_opcode_r;
  assign  out_d_size_i   = out_d_size_r;
  assign  out_d_source_i = out_d_source_r;
  assign  out_d_data_i   = out_d_data_r;
  assign  out_d_param_i  = out_d_param_r;

  initial begin
    out_a_ready_r  = {(`NUM_L2CACHE){1'b0}};
    out_d_valid_r  = {(`NUM_L2CACHE){1'b0}};
    out_d_opcode_r = {(`NUM_L2CACHE){1'b0}};
    out_d_size_r   = {(`NUM_L2CACHE){1'b0}};
    out_d_source_r = {(`NUM_L2CACHE){1'b0}};
    out_d_data_r   = {(`NUM_L2CACHE){1'b0}};
    out_d_param_r  = {(`NUM_L2CACHE){1'b0}};
  end
  
  parameter META_FNAME_SIZE = 128;
  parameter METADATA_SIZE   = 1024;

  parameter DATA_FNAME_SIZE = 128;
  parameter DATADATA_SIZE   = 2000;
  
  parameter BUF_NUM         = 18;   
  parameter MEM_ADDR        = 32;

  reg [31:0] data          [DATADATA_SIZE-1:0];
  reg [31:0] metadata      [METADATA_SIZE-1:0];
  reg [63:0] buf_ba_w      [BUF_NUM-1:0] ; //buffer's base addr
  reg [63:0] buf_size      [BUF_NUM-1:0] ; //buffer's size
  reg [63:0] buf_size_tmp  [BUF_NUM-1:0] ; //size align
  reg [63:0] buf_asize     [BUF_NUM-1:0] ; //buffer's allocate size
  
  logic [7:0] mem [bit unsigned [MEM_ADDR-1:0]];


  task init_mem;
    input [META_FNAME_SIZE*8-1:0] fn_metadata;
    input [DATA_FNAME_SIZE*8-1:0] fn_data;
    reg   [63:0] buf_num_soft;
    reg   [31:0] mem_addr [0:BUF_NUM-1];
    integer i, m;
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
      
      mem_addr[0]       = 32'h0;
      buf_size_tmp[0]   = (buf_size[0]%4==0) ? buf_size[0] : (buf_size[0]/4)*4+4;
      for(i=1;i<buf_num_soft;i=i+1) begin
        mem_addr[i] = mem_addr[i-1] + buf_size_tmp[i-1]; //data base addr+size=end addr
        buf_size_tmp[i] = (buf_size[i]%4==0) ? buf_size[i] : (buf_size[i]/4)*4+4;
      end 

      for(i=0;i<buf_num_soft;i=i+1) begin
        for(int m=0;m<buf_size_tmp[i];m=m+1) begin
          mem[buf_ba_w[i]+m] <= data[(mem_addr[i]+m)/4][(m%4+1)*8-1-:8];
        end
      end
    end
  endtask

  localparam CLOG_L2CAC_N = $clog2(`NUM_L2CACHE);

  task tile_read_and_write;
    input [CLOG_L2CAC_N-1:0] bus_n;
    begin
      @(posedge clk);
      out_a_ready_r[bus_n] = 1'b1;
      if(out_a_valid_o[bus_n] & out_a_ready_i[bus_n] & (out_a_opcode_o[(bus_n*`OP_BITS)+:`OP_BITS] == 4)) begin
        out_a_ready_r[bus_n]                             = 1'b0;
        out_d_valid_r[bus_n]                             = 1'b1;
        out_d_opcode_r[bus_n*`OP_BITS+:`OP_BITS]         = 1'b1;
        out_d_size_r[bus_n*`SIZE_BITS+:`SIZE_BITS]       = out_a_size_o; 
        out_d_source_r[bus_n*`SOURCE_BITS+:`SOURCE_BITS] = out_a_source_o;
        out_d_param_r[bus_n*3+:3]                        = out_a_param_o; 
        for(int k=0;k<`DCACHE_BLOCKWORDS*`BYTESOFWORD;k=k+1) begin
        out_d_data_r[(bus_n*64+(k+1)*8)-1-:8]            = mem[out_a_address_o+k];
        end
      end
      else if((out_a_valid_o[bus_n]&out_a_ready_i[bus_n]&((out_a_opcode_o[(bus_n*`OP_BITS)+:`OP_BITS]==0)||(out_a_opcode_o[(bus_n*`OP_BITS)+:`OP_BITS]==1)))) begin
        out_a_ready_r[bus_n]                             = 1'b0;
        out_d_valid_r[bus_n]                             = 1'b1;
        out_d_opcode_r[bus_n*`OP_BITS+:`OP_BITS]         = 1'b0;
        out_d_size_r[bus_n*`SIZE_BITS+:`SIZE_BITS]       = out_a_size_o; 
        out_d_source_r[bus_n*`SOURCE_BITS+:`SOURCE_BITS] = out_a_source_o;
        out_d_param_r[bus_n*3+:3]                        = out_a_param_o; 
        for(int k=0;k<`DCACHE_BLOCKWORDS*`BYTESOFWORD;k=k+1) begin
        mem[out_a_address_o+k] = out_a_mask_o[k] ? out_a_data_o[(k+1)*8-1-:8] : mem[out_a_address_o+k];
        end
      end 
      else if(out_d_valid_i[bus_n] & out_d_ready_o[bus_n]) begin
        out_d_valid_r[bus_n] = 1'b0;
        out_a_ready_r[bus_n] = 1'b1;
      end
    end
  endtask
  
  //task print_mem;
  //  if(`l2_flush_finish) begin
  //    #200;
  //    for(integer addr=32'h90000000; addr<32'h90000000+32'h40; addr=addr+4) begin
  //      //$fwrite(file1,"0x%h %h%h%h%h\n",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
  //      $display("0x%h %h%h%h%h",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
  //    end
  //    for(integer addr=32'h90001000; addr<32'h90001000+32'h10; addr=addr+4) begin
  //      //$fwrite(file1,"0x%h %h%h%h%h\n",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
  //      $display("0x%h %h%h%h%h",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
  //    end
  //    for(integer addr=32'h90002000; addr<32'h90002000+32'h40; addr=addr+4) begin
  //      //$fwrite(file1,"0x%h %h%h%h%h\n",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
  //      $display("0x%h %h%h%h%h",addr,`mem[addr+3],`mem[addr+2],`mem[addr+1],`mem[addr]);
  //    end
  //  end
  //endtask
  /*
  task print_mem;
    //input [63:0] parsed_base_r  [0:BUF_NUM-1];
    //input [63:0] parsed_size_r  [0:BUF_NUM-1];
    reg   [3:0]     kernelID;
    reg   [31:0]    matrix_a_4_soft [15:0];
    reg   [31:0]    array_b_4_soft   [3:0];
    reg   [31:0]    matrix_a_4_hard [15:0];
    reg   [31:0]    array_b_4_hard   [3:0];
    reg   [15:0]    matrix_4_pass;
    reg   [3:0]     array_4_pass;
    //wire  [31:0]    matrix_a_5_soft [24:0];
    //wire  [31:0]    array_b_5_soft   [4:0];
    //reg   [31:0]    matrix_a_5_hard [24:0];
    //reg   [31:0]    array_b_5_hard   [4:0];
    //reg   [24:0]    matrix_5_pass;
    //reg   [4:0]     array_5_pass;
    integer file1;
    begin
      matrix_a_4_soft = {32'hbf19999a,32'hbf000000,32'h3f333333,32'h3e99999a,32'h00000000,32'hbf266666,32'hbd4cccc8,32'h3f0ccccc,32'hb26eeef0,32'h31424c20,32'hbf40fc10,32'hbf920d21,32'h00000000,32'hb0c4ec50,32'h32036a80,32'h3f0042df};
      array_b_4_soft  = {32'hbf59999a,32'hbe828f5c,32'h3f5f3ec0,32'hbe8042e0};

      file1 = $fopen("mem.txt","w");
      if(file1 == 0) begin
        $display("Open fail!");
      end

      kernelID = 0;
      
      //forever@(posedge clk) begin
      if(`host_req_valid) begin
        $fwrite(file1,"kernel %h\n",kernelID);
        kernelID = kernelID + 1;
      end

      if(`l2_flush_finish) begin
        #100;
        for (integer i=0; i<32; i=i+1) begin
          if(kernelID==i) begin
            $fwrite(file1,"matrix a:\n");
            //for(integer addr=parsed_base_r[1]; addr<parsed_base_r[1]+parsed_size_r[1]; addr=addr+4) begin        
            for(integer addr=32'h90000000; addr<32'h90000000+32'h40; addr=addr+4) begin        
              $fwrite(file1,"0x%h %h%h%h%h\n",addr,mem[addr+3],mem[addr+2],mem[addr+1],mem[addr]);
              //`ifdef CASE_4W8T
                //matrix_a_5_hard[(addr-parsed_base_r[1])/4]  = {mem[addr+3],mem[addr+2],mem[addr+1],mem[addr]};
              //`else
                matrix_a_4_hard[(addr-32'h90000000)/4]  = {mem[addr+3],mem[addr+2],mem[addr+1],mem[addr]};
              //`endif
            end
            $fwrite(file1,"array b:\n");
            //for(integer addr=parsed_base_r[2]; addr<parsed_base_r[2]+parsed_size_r[2]; addr=addr+4) begin        
            for(integer addr=32'h90001000; addr<32'h90001000+32'h10; addr=addr+4) begin        
              $fwrite(file1,"0x%h %h%h%h%h\n",addr,mem[addr+3],mem[addr+2],mem[addr+1],mem[addr]);
              //`ifdef CASE_4W8T
                //array_b_5_hard[(addr-parsed_base_r[2])/4]  = {mem[addr+3],mem[addr+2],mem[addr+1],mem[addr]};
              //`else
                array_b_4_hard[(addr-32'h90001000)/4]  = {mem[addr+3],mem[addr+2],mem[addr+1],mem[addr]};
              //`endif
            end
            //$fwrite(file4,"tmp value:\n");
            //for(integer addr=parsed_base_r[0]; addr<parsed_base_r[0]+parsed_size_r[0]; addr=addr+4) begin        
            //  $fwrite(file4,"0x%h %h%h%h%h\n",addr,mem[addr+3],mem[addr+2],mem[addr+1],mem[addr]);
            //end
            //$fwrite(file4,"base addr and matrix size:\n");
            //for(integer addr=parsed_base_r[3]; addr<parsed_base_r[3]+parsed_size_r[3]; addr=addr+4) begin        
            //  $fwrite(file4,"0x%h %h%h%h%h\n",addr,mem[addr+3],mem[addr+2],mem[addr+1],mem[addr]);
            //end
          end
          `ifdef CASE_4W8T
            if(kernelID==8) begin
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
            end
          `else
            if(kernelID==6) begin
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
            end
          `endif
        end
      end
      $fclose(file1);
      //end
    end
  endtask
  */

endmodule

