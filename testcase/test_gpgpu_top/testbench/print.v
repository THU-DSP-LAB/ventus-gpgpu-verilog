`include "define.v"

`define opc_out_valid           test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.out_valid_o
`define opc_out_wid             test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.out_wid_o[2:0]
`define opc_out_inst            test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.out_inst_o[31:0]
`define opc_out_branch          test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.out_branch_o[1:0]
`define opc_out_isvec           test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.out_isvec_o
`define opc_out_pc              test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.out_pc_o[31:0]
`define opc_out_mem_whb         test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.out_mem_whb_o[1:0]      
`define opc_out_is_vls12        test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.out_is_vls12_o     
`define opc_out_mem             test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.out_mem_o          
`define opc_out_mem_cmd         test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.out_mem_cmd_o[1:0]      
`define opc_out_reg_idxw        test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.out_reg_idxw_o[7:0]     
`define opc_out_alu_src1        test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.out_alu_src1_o[1023:0]   
`define opc_out_alu_src2        test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.out_alu_src2_o[1023:0]  
`define opc_out_alu_src3        test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.out_alu_src3_o[1023:0]   
`define opc_out_active_mask     test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.out_active_mask_o[31:0]
`define opc_ws_valid            test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.writeScalar_valid_i
`define opc_ws_rd               test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.writeScalar_rd_i[31:0]   
`define opc_ws_idxw             test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.writeScalar_idxw_i[7:0] 
`define opc_ws_wid              test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.writeScalar_wid_i[2:0]  
`define opc_wv_valid            test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.writeVector_valid_i   
`define opc_wv_rd               test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.writeVector_rd_i[1023:0]      
`define opc_wv_mask             test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.writeVector_wvd_mask_i[31:0]
`define opc_wv_idxw             test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.writeVector_idxw_i[7:0]    
`define opc_wv_wid              test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.operand_collector.writeVector_wid_i[2:0]     

`define lsu2wb_x_valid          test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.lsu2wb.out_x_valid_o
`define lsu2wb_x_wid            test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.lsu2wb.out_x_warp_id_o
`define lsu2wb_x_idxw           test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.lsu2wb.out_x_reg_idxw_o
`define lsu2wb_x_rd             test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.lsu2wb.out_x_wb_wxd_rd_o
`define wb_x_valid              test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.wb.in_x_valid_i
`define lsu2wb_v_valid          test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.lsu2wb.out_v_valid_o
`define lsu2wb_v_wid            test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.lsu2wb.out_v_warp_id_o
`define lsu2wb_v_idxw           test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.lsu2wb.out_v_reg_idxw_o
`define lsu2wb_v_mask           test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.lsu2wb.out_v_wvd_mask_o
`define lsu2wb_v_rd             test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.lsu2wb.out_v_wb_wvd_rd_o
`define wb_v_valid              test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.wb.in_v_valid_i

`define issue_in_mask           test_gpu_top.gpu_test.A1[0].A2[1].U_sm_wrapper.pipe.issue_in_mask
`define l2_flush_finish         test_gpu_top.gpu_test.B1[0].l2cache.SourceD_finish_issue_o



module print(
  input                          clk                    ,
  input                          host_req_valid_i       ,

);

  reg   [2:0]     wid_wb_scalar,wid_wb_vector,wid_lw ;
  reg   [31:0]    pc_wb_scalar,pc_wb_vector,pc_lw  ;
  reg   [31:0]    inst_wb_scalar,inst_wb_vector,inst_lw;
  reg   [7:0]     idxw_wb_scalar,idxw_wb_vector,idxw_lw;
  reg   [31:0]    addr_sw,addr_lw_scalar;
  reg   [1023:0]  addr_lw,addr_lw_vector;
  reg   [3:0]     kernelID;
  wire  [31:0]    matrix_a_4_soft [15:0];
  wire  [31:0]    array_b_4_soft   [3:0];
  reg   [31:0]    matrix_a_4_hard [15:0];
  reg   [31:0]    array_b_4_hard   [3:0];
  reg   [15:0]    matrix_4_pass;
  reg   [3:0]     array_4_pass;
  wire  [31:0]    matrix_a_5_soft [24:0];
  wire  [31:0]    array_b_5_soft   [4:0];
  reg   [31:0]    matrix_a_5_hard [24:0];
  reg   [31:0]    array_b_5_hard   [4:0];
  reg   [24:0]    matrix_5_pass;
  reg   [4:0]     array_5_pass;

  assign matrix_a_4_soft = {32'hbf19999a,32'hbf000000,32'h3f333333,32'h3e99999a,32'h00000000,32'hbf266666,32'hbd4cccc8,32'h3f0ccccc,32'hb26eeef0,32'h31424c20,32'hbf40fc10,32'hbf920d21,32'h00000000,32'hb0c4ec50,32'h32036a80,32'h3f0042df};
  assign array_b_4_soft  = {32'hbf59999a,32'hbe828f5c,32'h3f5f3ec0,32'hbe8042e0};
  assign matrix_a_5_soft = {32'h3e4ccccd,32'hbf800000,32'h3e99999a,32'h3f800000,32'h3f333333,32'h00000000,32'h3e4ccccd,32'hbf333333,32'hbf666666,32'hbf000000,32'h32000000,32'hb3a00000,32'h40be6666,32'h40c00000,32'h40700000,32'h32000000,32'hb389999a,32'hb40f0148,32'h3dd11a60,32'h3e9d78e3,32'h33200000,32'hb3000000,32'h34509090,32'h31964000,32'h408591e8};
  assign array_b_5_soft  = {32'h3fc00000,32'hbf451eb8,32'h40799999,32'hbcff0d0a,32'hbfd5b642};

  initial begin
    integer file1,file2,file3,file4;
    file1 = $fopen("print_reg_writeback_v2.txt","w");
    file2 = $fopen("print_load_mem_v2.txt","w");
    file3 = $fopen("print_store_mem_v2.txt","w");
    file4 = $fopen("mem.txt","w");
    if(file1 == 0) begin
      $display("Open fail!");
    end
    if(file2 == 0) begin
      $display("Open fail!");
    end
    if(file3 == 0) begin
      $display("Open fail!");
    end
    if(file4 == 0) begin
      $display("Open fail!");
    end


    kernelID = 0;
    
    forever@(posedge clk) begin

      if(host_req_valid_i) begin
        $fwrite(file1,"kernel %h\n",kernelID);
        $fwrite(file2,"kernel %h\n",kernelID);
        $fwrite(file3,"kernel %h\n",kernelID);
        $fwrite(file4,"kernel %h\n",kernelID);
        kernelID = kernelID + 1;
      end

      if(l2_flush_finish) begin
        #100;
        for (integer i=0; i<32; i=i+1) begin
          if(kernelID==i) begin
            $fwrite(file4,"matrix a:\n");
            for(integer addr=parsed_base_r[1]; addr<parsed_base_r[1]+parsed_size_r[1]; addr=addr+4) begin        
              $fwrite(file4,"0x%h %h%h%h%h\n",addr,mem[addr+3],mem[addr+2],mem[addr+1],mem[addr]);
              `ifdef CASE_4W8T
                matrix_a_5_hard[(addr-parsed_base_r[1])/4]  = {mem[addr+3],mem[addr+2],mem[addr+1],mem[addr]};
              `else
                matrix_a_4_hard[(addr-parsed_base_r[1])/4]  = {mem[addr+3],mem[addr+2],mem[addr+1],mem[addr]};
              `endif
            end
            $fwrite(file4,"array b:\n");
            for(integer addr=parsed_base_r[2]; addr<parsed_base_r[2]+parsed_size_r[2]; addr=addr+4) begin        
              $fwrite(file4,"0x%h %h%h%h%h\n",addr,mem[addr+3],mem[addr+2],mem[addr+1],mem[addr]);
              `ifdef CASE_4W8T
                array_b_5_hard[(addr-parsed_base_r[2])/4]  = {mem[addr+3],mem[addr+2],mem[addr+1],mem[addr]};
              `else
                array_b_4_hard[(addr-parsed_base_r[2])/4]  = {mem[addr+3],mem[addr+2],mem[addr+1],mem[addr]};
              `endif
            end
            $fwrite(file4,"tmp value:\n");
            for(integer addr=parsed_base_r[0]; addr<parsed_base_r[0]+parsed_size_r[0]; addr=addr+4) begin        
              $fwrite(file4,"0x%h %h%h%h%h\n",addr,mem[addr+3],mem[addr+2],mem[addr+1],mem[addr]);
            end
            $fwrite(file4,"base addr and matrix size:\n");
            for(integer addr=parsed_base_r[3]; addr<parsed_base_r[3]+parsed_size_r[3]; addr=addr+4) begin        
              $fwrite(file4,"0x%h %h%h%h%h\n",addr,mem[addr+3],mem[addr+2],mem[addr+1],mem[addr]);
            end
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
      
      // file1 = print_reg_writeback_v2.txt
      if(opc_out_valid && opc_out_mem_cmd==0 && opc_out_branch!=1) begin
        if(opc_out_isvec) begin
          wid_wb_vector  = opc_out_wid      ;
          pc_wb_vector   = opc_out_pc       ;
          inst_wb_vector = opc_out_inst     ;
          idxw_wb_vector = opc_out_reg_idxw ;
          $fwrite(file1,"core   %h: 0x%h (0x%h) v%d\n",wid_wb_vector,pc_wb_vector,inst_wb_vector,idxw_wb_vector);
        end else begin
          wid_wb_scalar  = opc_out_wid      ;
          pc_wb_scalar   = opc_out_pc       ;
          inst_wb_scalar = opc_out_inst     ;
          idxw_wb_scalar = opc_out_reg_idxw ;
          $fwrite(file1,"core   %h: 0x%h (0x%h) x%d\n",wid_wb_scalar,pc_wb_scalar,inst_wb_scalar,idxw_wb_scalar);
        end
      end

      // scalar reg write back
      if(opc_ws_valid && opc_ws_wid==wid_wb_scalar && opc_ws_idxw==idxw_wb_scalar) begin
        $fwrite(file1,"core   %h: 3 0x%h (0x%h) x%d  0x%h \n",wid_wb_scalar,pc_wb_scalar,inst_wb_scalar,idxw_wb_scalar,opc_ws_rd);
      end
      
      // vector reg write back
      if(opc_wv_valid && opc_wv_wid==wid_wb_vector && opc_wv_idxw==idxw_wb_vector) begin
        $fwrite(file1,"core   %h: 3 0x%h (0x%h) v%d  ",wid_wb_vector,pc_wb_vector,inst_wb_vector,idxw_wb_vector);
        $fwrite(file1,"m:0x%h ",opc_wv_mask);
        for (integer i=0; i<`NUM_THREAD; i=i+1) begin
          $fwrite(file1,"%h ",opc_wv_rd[32*(`NUM_THREAD-i)-1-:32]);
        end
        $fwrite(file1,"\n");
      end
      
      // file2 = print_load_mem_v2.txt
      // print lw/vlw12 inst
      if(opc_out_valid && opc_out_mem_cmd[1:0]==1) begin
        wid_lw  = opc_out_wid      ;
        pc_lw   = opc_out_pc       ;
        inst_lw = opc_out_inst     ;
        idxw_lw = opc_out_reg_idxw ;
        
        for (integer i=0; i<32; i=i+1) begin
          addr_lw[32*(i+1)-1-:32] = opc_out_alu_src2[32*(i+1)-1] ? opc_out_alu_src1[32*(i+1)-1-:32]-(~opc_out_alu_src2[32*(i+1)-1-:32]+32'h1) : opc_out_alu_src1[32*(i+1)-1-:32]+opc_out_alu_src2[32*(i+1)-1-:32]; 
        end
        
        if(opc_out_isvec) begin
          addr_lw_vector = addr_lw;
          $fwrite(file2,"core   %h: 0x%h (0x%h) v%d load mem[0x%h ",wid_lw,pc_lw,inst_lw,idxw_lw,addr_lw[31:0]);
          for (integer i=1; i<`NUM_THREAD-1; i=i+1) begin
          $fwrite(file2,"0x%h ",addr_lw[32*(i+1)-1-:32]);
          end
          $fwrite(file2,"0x%h]\n",addr_lw[32*`NUM_THREAD-1-:32]);
        end else begin
          addr_lw_scalar = addr_lw[31:0];
          $fwrite(file2,"core   %h: 0x%h (0x%h) x%d load mem[0x%h]\n",wid_lw,pc_lw,inst_lw,idxw_lw,addr_lw[31:0]);
        end
      end

      // scalar reg write back from mem
      if(lsu2wb_x_valid && wb_x_valid[2:0]==4) begin
        $fwrite(file2,"core   %h: reg[x%d] 0x%h \n",lsu2wb_x_wid,lsu2wb_x_idxw,lsu2wb_x_rd);
      end

      // vector reg write back from mem
      if(lsu2wb_v_valid && wb_v_valid[2:0]==4) begin
        $fwrite(file2,"core   %h: load reg[v%d] ",lsu2wb_v_wid,lsu2wb_v_idxw);
        $fwrite(file2,"m:0x%h ",lsu2wb_v_mask);
        for (integer i=0; i<`NUM_THREAD; i=i+1) begin
        $fwrite(file2,"%h ",lsu2wb_v_rd[32*(`NUM_THREAD-i)-1-:32]);
        end
        $fwrite(file2,"\n");
      end

      // file3 = print_store_mem_v2.txt
      // print sw/vsw12 inst
      if(opc_out_valid && opc_out_mem_cmd==2) begin
        if(opc_out_is_vls12 || opc_out_isvec) begin
          $fwrite(file3,"core   %h: 0x%h (0x%h) store ",opc_out_wid,opc_out_pc,opc_out_inst);
          $fwrite(file3,"m:0x%h ",issue_in_mask);
          for (integer i=0; i<`NUM_THREAD; i=i+1) begin
          addr_sw = opc_out_alu_src2[32*(i+1)-1] ? opc_out_alu_src1[32*(i+1)-1-:32]-(~opc_out_alu_src2[32*(i+1)-1-:32]+32'h1) : opc_out_alu_src1[32*(i+1)-1-:32]+opc_out_alu_src2[32*(i+1)-1-:32]; 
          if(issue_in_mask[i])begin
          $fwrite(file3,"mem[0x%h] 0x%h ",addr_sw,opc_out_alu_src3[32*(i+1)-1-:32]);
            end
          end
          $fwrite(file3,"\n");
        end else begin
          addr_sw = opc_out_alu_src2[31] ? opc_out_alu_src1[31:0]-(~opc_out_alu_src2[31:0]+32'h1) : opc_out_alu_src1[31:0]+opc_out_alu_src2[31:0]; 
          $fwrite(file3,"core   %h: 0x%h (0x%h) store mem[0x%h] 0x%h \n",opc_out_wid,opc_out_pc,opc_out_inst,addr_sw,opc_out_alu_src3[31:0]);
        end
      end

    end
    $fclose(file1);
    $fclose(file2);
    $fclose(file3);
    $fclose(file4);

  end

`ifdef CASE_2W8T
  always@(posedge clk) begin
    if(kernelID==6 && l2_flush_finish) begin
      #200;
      if((&matrix_4_pass) && (&array_4_pass)) begin
        $display("***********case_guassian_2w8t**********");
        $display("******************PASS*****************");
      end else begin
        $display("***********case_guassian_2w8t**********");
        $display("*****************FAILED****************");
      end
    end
  end
`endif
`ifdef CASE_1W16T
  always@(posedge clk) begin
    if(kernelID==6 && l2_flush_finish) begin
      #200;
      if((&matrix_4_pass) && (&array_4_pass)) begin
        $display("***********case_guassian_1w16t**********");
        $display("******************PASS*****************");
      end else begin
        $display("***********case_guassian_1w16t**********");
        $display("*****************FAILED*****************");
      end
    end
  end
`endif
`ifdef CASE_4W4T
  always@(posedge clk) begin
    if(kernelID==6 && l2_flush_finish) begin
      #200;
      if((&matrix_4_pass) && (&array_4_pass)) begin
        $display("***********case_guassian_4w4t**********");
        $display("******************PASS*****************");
      end else begin
        $display("***********case_guassian_4w4t**********");
        $display("****************FAILED*****************");
      end
    end
  end
`endif
`ifdef CASE_4W8T
  always@(posedge clk) begin
    if(kernelID==8 && l2_flush_finish) begin
      #200;
      if((&matrix_5_pass) && (&array_5_pass)) begin
        $display("***********case_guassian_4w8t**********");
        $display("******************PASS*****************");
      end else begin
        $display("***********case_guassian_4w8t**********");
        $display("****************FAILED*****************");
      end
    end
  end
`endif


endmodule
