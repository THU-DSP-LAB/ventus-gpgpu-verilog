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
// Author: TangYao 
// Description: Decode every 32-bit width inst into control_signals.
//`include "decode_df_para.v"
`include "define.v"
`timescale 1ns/1ns

module decodeUnit
  (
  input                                         clk                                   ,
  input                                         rst_n                                 ,
  input [`INSTLEN-1:0]                          inst_0_i                              ,
  input [`INSTLEN-1:0]                          inst_1_i                              ,//inst                           
  input                                         inst_mask_0_i                         ,
  input                                         inst_mask_1_i                         ,//mask
  input [`ADDRLEN-1:0]                          pc_i                                  ,//pc              
  input [`DEPTH_WARP-1:0]                       wid_i                                 ,//warp id
  input [`DEPTH_WARP-1:0]                       flush_wid_i                           ,//flush id                  
  input                                         flush_wid_valid_i                     ,//wid flush

  input [`NUM_WARP-1:0]                         ibuffer_ready_i                       ,

  output                                        control_mask_0_o                      ,
  output                                        control_mask_1_o                      ,//control mask         

  output [`INSTLEN-1:0]                         control_Signals_inst_0_o              ,
  output [`DEPTH_WARP-1:0]                      control_Signals_wid_0_o               ,
  output                                        control_Signals_fp_0_o                ,
  output [1:0]                                  control_Signals_branch_0_o            ,
  output                                        control_Signals_simt_stack_0_o        ,
  output                                        control_Signals_simt_stack_op_0_o     ,
  output                                        control_Signals_barrier_0_o           ,
  output [1:0]                                  control_Signals_csr_0_o               ,
  output                                        control_Signals_reverse_0_o           ,
  output [1:0]                                  control_Signals_sel_alu2_0_o          ,
  output [1:0]                                  control_Signals_sel_alu1_0_o          ,
  output [1:0]                                  control_Signals_sel_alu3_0_o          ,
  output                                        control_Signals_isvec_0_o             ,
  output                                        control_Signals_mask_0_o              ,
  output [3:0]                                  control_Signals_sel_imm_0_o           ,
  output [1:0]                                  control_Signals_mem_whb_0_o           ,
  output                                        control_Signals_mem_unsigned_0_o      ,
  output [5:0]                                  control_Signals_alu_fn_0_o            ,
  output                                        control_Signals_force_rm_rtz_0_o      ,
  output                                        control_Signals_is_vls12_0_o          ,
  output                                        control_Signals_mem_0_o               ,
  output                                        control_Signals_mul_0_o               ,
  output                                        control_Signals_tc_0_o                ,
  output                                        control_Signals_disable_mask_0_o      ,
  output                                        control_Signals_custom_signal_0_0_o   ,//custom_signal_0   
  output [1:0]                                  control_Signals_mem_cmd_0_o           ,
  output [1:0]                                  control_Signals_mop_0_o               ,
  output [`REGEXT_WIDTH + `REGIDX_WIDTH -1:0]   control_Signals_reg_idx1_0_o          ,
  output [`REGEXT_WIDTH + `REGIDX_WIDTH -1:0]   control_Signals_reg_idx2_0_o          ,
  output [`REGEXT_WIDTH + `REGIDX_WIDTH -1:0]   control_Signals_reg_idx3_0_o          ,
  output [`REGEXT_WIDTH + `REGIDX_WIDTH -1:0]   control_Signals_reg_idxw_0_o          ,
  output                                        control_Signals_wvd_0_o               ,
  output                                        control_Signals_fence_0_o             ,
  output                                        control_Signals_sfu_0_o               ,
  output                                        control_Signals_readmask_0_o          ,
  output                                        control_Signals_writemask_0_o         ,
  output                                        control_Signals_wxd_0_o               ,
  output [`INSTLEN-1:0]                         control_Signals_pc_0_o                ,
  output [6:0]                                  control_Signals_imm_ext_0_o           ,
  output                                        control_Signals_atomic_0_o            ,
  output                                        control_Signals_aq_0_o                ,
  output                                        control_Signals_rl_0_o                ,
  output [2:0]                                  rm_0_o                                ,
  output                                        rm_is_static_0_o                      ,                                               
  //output                                        control_Signals__spike_info_0_o       ,//val spike_info=if(SPIKE_OUTPUT) Some(new InstWriteBack) else None

  output [`INSTLEN-1:0]                         control_Signals_inst_1_o              ,
  output [`DEPTH_WARP-1:0]                      control_Signals_wid_1_o               ,
  output                                        control_Signals_fp_1_o                ,
  output [1:0]                                  control_Signals_branch_1_o            ,
  output                                        control_Signals_simt_stack_1_o        ,
  output                                        control_Signals_simt_stack_op_1_o     ,
  output                                        control_Signals_barrier_1_o           ,
  output [1:0]                                  control_Signals_csr_1_o               ,
  output                                        control_Signals_reverse_1_o           ,
  output [1:0]                                  control_Signals_sel_alu2_1_o          ,
  output [1:0]                                  control_Signals_sel_alu1_1_o          ,
  output [1:0]                                  control_Signals_sel_alu3_1_o          ,
  output                                        control_Signals_isvec_1_o             ,
  output                                        control_Signals_mask_1_o              ,
  output [3:0]                                  control_Signals_sel_imm_1_o           ,
  output [1:0]                                  control_Signals_mem_whb_1_o           ,
  output                                        control_Signals_mem_unsigned_1_o      ,   
  output [5:0]                                  control_Signals_alu_fn_1_o            ,
  output                                        control_Signals_force_rm_rtz_1_o      ,
  output                                        control_Signals_is_vls12_1_o          ,
  output                                        control_Signals_mem_1_o               ,
  output                                        control_Signals_mul_1_o               ,
  output                                        control_Signals_tc_1_o                ,
  output                                        control_Signals_disable_mask_1_o      ,
  output                                        control_Signals_custom_signal_0_1_o   ,//custom_signal_0   
  output [1:0]                                  control_Signals_mem_cmd_1_o           ,
  output [1:0]                                  control_Signals_mop_1_o               ,
  output [`REGEXT_WIDTH + `REGIDX_WIDTH -1:0]   control_Signals_reg_idx1_1_o          ,
  output [`REGEXT_WIDTH + `REGIDX_WIDTH -1:0]   control_Signals_reg_idx2_1_o          ,
  output [`REGEXT_WIDTH + `REGIDX_WIDTH -1:0]   control_Signals_reg_idx3_1_o          ,
  output [`REGEXT_WIDTH + `REGIDX_WIDTH -1:0]   control_Signals_reg_idxw_1_o          ,
  output                                        control_Signals_wvd_1_o               ,
  output                                        control_Signals_fence_1_o             ,
  output                                        control_Signals_sfu_1_o               ,
  output                                        control_Signals_readmask_1_o          ,
  output                                        control_Signals_writemask_1_o         ,
  output                                        control_Signals_wxd_1_o               ,
  output [31:0]                                 control_Signals_pc_1_o                ,
  output [6:0]                                  control_Signals_imm_ext_1_o           ,
  output                                        control_Signals_atomic_1_o            ,
  output                                        control_Signals_aq_1_o                ,
  output                                        control_Signals_rl_1_o                ,
  output [2:0]                                  rm_1_o                                ,
  output                                        rm_is_static_1_o                                              
    //output                                        control_Signals_spike_info_1_o    //val spike_info=if(SPIKE_OUTPUT) Some(new InstWriteBack) else None    


  //instrDecodeV2
  );
  reg [41:0] ctrlSignals_0;//chisel RTL               
  reg [41:0] ctrlSignals_1;//chisel RTL               

  //class regext,inst_0,regextInfo_pre
  reg [5:0] regextInfo_0_immHigh;
  reg regextInfo_0_isExtI;
  reg regextInfo_0_isExt;
  reg [11:0] regextInfo_0_regprefix;// 0 : rd, 1 : rs1, 2 : rs2, 3 : rs3 ---> 11~9 -> rd, 8~6 -> rs1, 5~3 -> rs2, 2~0 -> rs3

  //class regext,inst_1,regextInfo_pre
  reg [5:0] regextInfo_1_immHigh;
  reg regextInfo_1_isExtI;
  reg regextInfo_1_isExt;
  reg [11:0] regextInfo_1_regprefix;// 0 : rd, 1 : rs1, 2 : rs2, 3 : rs3 --> 11~9 -> rd, 8~6 -> rs1, 5~3 -> rs2, 2~0 -> rs3
  wire maskAfterExt_0 ;
  wire maskAfterExt_1 ;
  reg  [`NUM_WARP-1:0]scratchPads_isExtI;       //inst                        inst_1
  reg  [6*`NUM_WARP-1:0] scratchPads_immHigh;   //inst                        inst_1
  reg  [12*`NUM_WARP-1:0] scratchPads_regPrefix;//inst                        inst_1
 

  
  assign maskAfterExt_0   = inst_mask_0_i &&  !(regextInfo_0_isExtI|regextInfo_0_isExt);
  assign maskAfterExt_1   = inst_mask_1_i &&  !(regextInfo_1_isExtI|regextInfo_1_isExt);
  assign rm_0_o           = inst_0_i[14:12]                                                                                  ;
  assign rm_1_o           = inst_1_i[14:12]                                                                                      ;
  assign rm_is_static_0_o = !control_Signals_isvec_0_o && ((control_Signals_alu_fn_0_o == `FN_FMADD) || (control_Signals_alu_fn_0_o == `FN_FMSUB) || (control_Signals_alu_fn_0_o == `FN_FNMSUB)
                                                        || (control_Signals_alu_fn_0_o == `FN_FNMADD) || (control_Signals_alu_fn_0_o == `FN_FADD) || (control_Signals_alu_fn_0_o == `FN_FSUB) || (control_Signals_alu_fn_0_o == `FN_FMUL)
                                                        || (control_Signals_alu_fn_0_o == `FN_FDIV) || (control_Signals_alu_fn_0_o == `FN_FSQRT) || (control_Signals_alu_fn_0_o == `FN_F2I) || (control_Signals_alu_fn_0_o == `FN_F2IU)
                                                        || (control_Signals_alu_fn_0_o == `FN_I2F) || (control_Signals_alu_fn_0_o == `FN_IU2F));
  assign rm_is_static_1_o = !control_Signals_isvec_1_o && ((control_Signals_alu_fn_1_o == `FN_FMADD) || (control_Signals_alu_fn_1_o == `FN_FMSUB) || (control_Signals_alu_fn_1_o == `FN_FNMSUB)
                                                        || (control_Signals_alu_fn_1_o == `FN_FNMADD) || (control_Signals_alu_fn_1_o == `FN_FADD) || (control_Signals_alu_fn_1_o == `FN_FSUB) || (control_Signals_alu_fn_1_o == `FN_FMUL)
                                                        || (control_Signals_alu_fn_1_o == `FN_FDIV) || (control_Signals_alu_fn_1_o == `FN_FSQRT) || (control_Signals_alu_fn_1_o == `FN_F2I) || (control_Signals_alu_fn_1_o == `FN_F2IU)
                                                        || (control_Signals_alu_fn_1_o == `FN_I2F) || (control_Signals_alu_fn_1_o == `FN_IU2F));

  always @(*) //inst_0         
    begin
      if(!inst_mask_0_i)
        begin
          regextInfo_0_immHigh = 6'b0;
          regextInfo_0_isExtI = 1'b0;
          regextInfo_0_isExt = 1'b0;
          regextInfo_0_regprefix = 12'b0;
        end
      else 
        begin
          /*
            if((inst_0_i[6:0]==7'b0001011)&(inst_0_i[14:12]==3'b010))//      REGEXT      

              regextInfo_0_isExt = 1'b1;
            else if((inst_0_i[6:0]==7'b0001011)&(inst_0_i[14:12]==3'b011))//      REGEXTI      
              regextInfo_0_isExtI = 1'b1;            
              else
                begin
                  regextInfo_0_isExt = 1'b0;
                  regextInfo_0_isExtI = 1'b0;
                end
           */  //def REGEXT             = BitPat("b?????????????????010?????0001011")
            //   def REGEXTI            = BitPat("b?????????????????011?????0001011")
          regextInfo_0_isExt   =  ((inst_0_i[6:0]==7'b0001011)&(inst_0_i[14:12]==3'b010)) ? 1'b1: 1'b0;
          regextInfo_0_isExtI  =  ((inst_0_i[6:0]==7'b0001011)&(inst_0_i[14:12]==3'b011)) ? 1'b1: 1'b0;
          regextInfo_0_immHigh = regextInfo_0_isExtI ? inst_0_i[31:26] : 6'b0;
          if (regextInfo_0_isExt) 
            begin
              regextInfo_0_regprefix = {inst_0_i[22:20],inst_0_i[25:23],inst_0_i[28:26],inst_0_i[31:29]};
            end
          else if(regextInfo_0_isExtI)
            begin
              regextInfo_0_regprefix = {inst_0_i[22:20],3'b000,inst_0_i[25:23],3'b000 };
            end
          else
            regextInfo_0_regprefix = 12'b0;
        end
    end

  always @(*) //inst_0         
    begin
      if(!inst_mask_1_i)
        begin
          regextInfo_1_immHigh = 6'b0;
          regextInfo_1_isExtI = 1'b0;
          regextInfo_1_isExt = 1'b0;
          regextInfo_1_regprefix = 12'b0;
        end
      else 
        begin 
            /*
            if((inst_1_i[6:0]==7'b0001011)&(inst_1_i[14:12]==3'b010))//      REGEXT      
              regextInfo_1_isExt = 1'b1;
            else if((inst_1_i[6:0]==7'b0001011)&(inst_1_i[14:12]==3'b011))
              regextInfo_1_isExtI = 1'b1;
              else
                begin
                  regextInfo_1_isExtI = 1'b0;
                  regextInfo_1_isExt = 1'b0;
                end
*/
          regextInfo_1_isExt   = ((inst_1_i[6:0]==7'b0001011)&(inst_1_i[14:12]==3'b010)) ? 1'b1 : 1'b0;
          regextInfo_1_isExtI  = ((inst_1_i[6:0]==7'b0001011)&(inst_1_i[14:12]==3'b011)) ? 1'b1 : 1'b0;
          regextInfo_1_immHigh = regextInfo_1_isExtI ? inst_1_i[31:26] : 6'b0;
          if(regextInfo_1_isExt) 
            begin
              regextInfo_1_regprefix = {inst_1_i[22:20],inst_1_i[25:23],inst_1_i[28:26],inst_1_i[31:29]};
            end
          else if(regextInfo_1_isExtI)
            begin
              regextInfo_1_regprefix = {inst_1_i[22:20],3'b000,inst_1_i[25:23],3'b000 };
            end
          else
            regextInfo_1_regprefix = 12'b0;
        end
    end
  integer  i;
  always@(posedge clk or negedge rst_n) 
    begin
      if(!rst_n)
        begin
          for(i=0;i<`NUM_WARP;i=i+1)
            begin
              //scratchPads_isExt[i] <= 1'b0;//            NUM_WARP      warp               
              scratchPads_isExtI[i] <= 1'b0;
              //scratchPads_immHigh[i] <= 6'b0;  //reg  [6*`NUM_WARP-1:0] scratchPads_immHigh;//                  inst                        inst_1
              scratchPads_immHigh[(i+1)*6-1-:6]  <= 6'b0;
              //scratchPads_regPrefix[i] <= 12'b0;
              scratchPads_regPrefix[(i+1)*12-1-:12]  <= 12'b0;
            end
        end
      else begin
        if(flush_wid_valid_i)
          begin//      flush_wid                  flush_wid               
            //scratchPads_isExt[flush_wid_i] <= 1'b0;
            scratchPads_isExtI[flush_wid_i] <= 1'b0;

            //scratchPads_immHigh[flush_wid_i] <= 6'b0;
            //scratchPads_regPrefix[flush_wid_i] <= 12'b0;
            scratchPads_immHigh[(flush_wid_i+1)*6-1-:6]  <= 6'b0;
            scratchPads_regPrefix[(flush_wid_i+1)*12-1-:12]  <= 12'b0;
            //      scratchPads      flush_wid         
            if((flush_wid_i != wid_i) && (inst_mask_1_i) && (ibuffer_ready_i[wid_i])) //scratchPads         regextInfo_1         
              begin
                //scratchPads_isExt [wid_i] <= regextInfo_1_isExt;
                scratchPads_isExtI [wid_i] <= regextInfo_1_isExtI;
                //scratchPads_immHigh[wid_i]   <=regextInfo_1_immHigh;
                //scratchPads_regPrefix[wid_i] <=regextInfo_1_regprefix;
                scratchPads_immHigh[(wid_i+1)*6-1-:6]  <= regextInfo_1_immHigh;
                scratchPads_regPrefix[(wid_i+1)*12-1-:12]  <= regextInfo_1_regprefix;
                
              end
            end
            else if(inst_mask_1_i && ibuffer_ready_i[wid_i])//      flush_valid         
              begin
                //scratchPads_isExt [wid_i] <= regextInfo_1_isExt;
                scratchPads_isExtI [wid_i] <= regextInfo_1_isExtI;
                //scratchPads_immHigh[wid_i]   <=regextInfo_1_immHigh;
                //scratchPads_regPrefix[wid_i] <=regextInfo_1_regprefix;
                scratchPads_immHigh[(wid_i+1)*6-1-:6]  <= regextInfo_1_immHigh;
                scratchPads_regPrefix[(wid_i+1)*12-1-:12]  <= regextInfo_1_regprefix;

              end                  
      end 
    end 


    //inst_0_i control                  
  always@(*)
    begin
      casex (inst_0_i)
      //lut 0   
     `BNE            : ctrlSignals_0 = {`N,`N,`N,`B_B,`N,`N,`CSR_N,`N,`A3_PC,  `A2_RS2, `A1_RS1, `IMM_B,`MEM_X,`FN_SNE,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
     `BEQ            : ctrlSignals_0 = {`N,`N,`N,`B_B,`N,`N,`CSR_N,`N,`A3_PC,  `A2_RS2, `A1_RS1, `IMM_B,`MEM_X,`FN_SEQ,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
     `BLT            : ctrlSignals_0 = {`N,`N,`N,`B_B,`N,`N,`CSR_N,`N,`A3_PC,  `A2_RS2, `A1_RS1, `IMM_B,`MEM_X,`FN_SLT,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
     `BLTU           : ctrlSignals_0 = {`N,`N,`N,`B_B,`N,`N,`CSR_N,`N,`A3_PC,  `A2_RS2, `A1_RS1, `IMM_B,`MEM_X,`FN_SLTU,  `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
     `BGE            : ctrlSignals_0 = {`N,`N,`N,`B_B,`N,`N,`CSR_N,`N,`A3_PC,  `A2_RS2, `A1_RS1, `IMM_B,`MEM_X,`FN_SGE,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
     `BGEU           : ctrlSignals_0 = {`N,`N,`N,`B_B,`N,`N,`CSR_N,`N,`A3_PC,  `A2_RS2, `A1_RS1, `IMM_B,`MEM_X,`FN_SGEU,  `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
     `JAL            : ctrlSignals_0 = {`N,`N,`N,`B_J,`N,`N,`CSR_N,`N,`A3_PC,  `A2_SIZE,`A1_PC,  `IMM_J,`MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `JALR           : ctrlSignals_0 = {`N,`N,`N,`B_R,`N,`N,`CSR_N,`N,`A3_PC,  `A2_SIZE,`A1_PC,  `IMM_I,`MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `AUIPC          : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_PC,  `IMM_U,`MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `CSRRW          : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_W,`N,`A3_X,   `A2_X,   `A1_RS1, `IMM_X,`MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `CSRRS          : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_S,`N,`A3_X,   `A2_X,   `A1_RS1, `IMM_X,`MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `CSRRC          : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_C,`N,`A3_X,   `A2_X,   `A1_RS1, `IMM_X,`MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `CSRRWI         : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_W,`N,`A3_X,   `A2_X,   `A1_IMM, `IMM_Z,`MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `CSRRSI         : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_S,`N,`A3_X,   `A2_X,   `A1_IMM, `IMM_Z,`MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `CSRRCI         : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_C,`N,`A3_X,   `A2_X,   `A1_IMM, `IMM_Z,`MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};

     `FENCE          : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_X,   `IMM_I,`MEM_X,`FN_ADD,   `N,`M_X,  `N,`Y,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `LW             : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_I,`MEM_W,`FN_ADD,   `N,`M_XRD,`N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `LH             : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_I,`MEM_H,`FN_ADD,   `N,`M_XRD,`N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `LB             : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_I,`MEM_B,`FN_ADD,   `N,`M_XRD,`N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `LHU            : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_I,`MEM_H,`FN_ADD,   `N,`M_XRD,`Y,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `LBU            : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_I,`MEM_B,`FN_ADD,   `N,`M_XRD,`Y,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `SW             : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_SD,  `A2_IMM, `A1_RS1, `IMM_S,`MEM_W,`FN_ADD,   `N,`M_XWR,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
     `SH             : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_SD,  `A2_IMM, `A1_RS1, `IMM_S,`MEM_H,`FN_ADD,   `N,`M_XWR,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
     `SB             : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_SD,  `A2_IMM, `A1_RS1, `IMM_S,`MEM_B,`FN_ADD,   `N,`M_XWR,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
     `LUI            : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_X,   `IMM_U,`MEM_X,`FN_A1ZERO,`N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `ADDI           : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_I,`MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `SLTI           : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_I,`MEM_X,`FN_SLT,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `SLTIU          : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_I,`MEM_X,`FN_SLTU,  `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `ANDI           : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_I,`MEM_X,`FN_AND,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `ORI            : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_I,`MEM_X,`FN_OR,    `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `XORI           : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_I,`MEM_X,`FN_XOR,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `ADD            : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `SUB            : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_SUB,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `SLT            : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_SLT,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `SLTU           : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_SLTU,  `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `AND            : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_AND,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `OR             : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_OR,    `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `XOR            : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_XOR,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `SLL            : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_SL,    `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `SRL            : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_SR,    `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `SRA            : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_SRA,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `SLLI           : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_2,`MEM_X,`FN_SL,    `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `SRLI           : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_2,`MEM_X,`FN_SR,    `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `SRAI           : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_2,`MEM_X,`FN_SRA,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};

     `MUL            : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_MUL,   `Y,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `MULH           : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_MULH,  `Y,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `MULHSU         : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_MULHSU,`Y,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `MULHU          : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_MULHU, `Y,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `DIV            : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_DIV,   `N,`M_X,  `N,`N,`Y,`N,`N,`N,`Y,`N,`N,`N,`N};
     `DIVU           : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_DIVU,  `N,`M_X,  `N,`N,`Y,`N,`N,`N,`Y,`N,`N,`N,`N};
     `REM            : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_REM,   `N,`M_X,  `N,`N,`Y,`N,`N,`N,`Y,`N,`N,`N,`N};
     `REMU           : ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_REMU,  `N,`M_X,  `N,`N,`Y,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FMADD_S        : ctrlSignals_0 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_FRS3,`A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FMADD, `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FMSUB_S        : ctrlSignals_0 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_FRS3,`A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FMSUB, `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FNMSUB_S       : ctrlSignals_0 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_FRS3,`A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FNMSUB,`N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FNMADD_S       : ctrlSignals_0 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_FRS3,`A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FNMADD,`N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FADD_S         : ctrlSignals_0 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FADD,  `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FSUB_S         : ctrlSignals_0 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FSUB,  `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FMUL_S         : ctrlSignals_0 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FMUL,  `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FDIV_S         : ctrlSignals_0 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FDIV,  `N,`M_X,  `N,`N,`Y,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FSQRT_S        : ctrlSignals_0 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_RS1, `IMM_X,`MEM_X,`FN_FSQRT, `N,`M_X,  `N,`N,`Y,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FSGNJ_S        : ctrlSignals_0 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FSGNJ, `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FSGNJN_S       : ctrlSignals_0 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FSGNJN,`N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FSGNJX_S       : ctrlSignals_0 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FSGNJX,`N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FMIN_S         : ctrlSignals_0 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FMIN,  `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};

     `FMAX_S         : ctrlSignals_0 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FMAX,  `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FCVT_W_S       : ctrlSignals_0 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_RS1, `IMM_X,`MEM_X,`FN_F2I,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FCVT_WU_S      : ctrlSignals_0 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_F2IU,  `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FEQ_S          : ctrlSignals_0 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FEQ,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FLT_S          : ctrlSignals_0 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FLT,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};        
     `FLE_S          : ctrlSignals_0 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FLE,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FCLASS_S       : ctrlSignals_0 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_RS1, `IMM_X,`MEM_X,`FN_FCLASS,`N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FCVT_S_W       : ctrlSignals_0 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_RS1, `IMM_X,`MEM_X,`FN_I2F,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FCVT_S_WU      : ctrlSignals_0 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_IU2F,  `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};

     //lut 1,with code 1010111
     `VFMUL_VV:        ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FMUL,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFMUL_VF:        ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FMUL,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFMADD_VV:       ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_VRS3,`A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_VFMADD,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFMADD_VF:       ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_VRS3,`A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_VFMADD,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFNMADD_VV:      ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_VRS3,`A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_VFNMADD, `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFNMADD_VF:      ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_VRS3,`A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_VFNMADD, `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFMSUB_VV:       ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_VRS3,`A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_VFMSUB,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFMSUB_VF:       ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_VRS3,`A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_VFMSUB,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFNMSUB_VV:      ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_VRS3,`A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_VFNMSUB, `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFNMSUB_VF:      ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_VRS3,`A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_VFNMSUB, `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
 
     `VFMACC_VV:       ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FMADD,   `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFMACC_VF:       ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FMADD,   `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFNMACC_VV:      ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FNMADD,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFNMACC_VF:      ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FNMADD,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFMSAC_VV:       ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FMSUB,   `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFMSAC_VF:       ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FMSUB,   `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFNMSAC_VV:      ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FNMSUB,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFNMSAC_VF:      ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FNMSUB,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VADD_VV:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_ADD,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VADD_VX:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_ADD,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VADD_VI:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_V,`MEM_X,`FN_ADD,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFADD_VV:        ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FADD,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFADD_VF:        ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FADD,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFSUB_VV:        ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FSUB,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFSUB_VF:        ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FSUB,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFRSUB_VF:       ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FSUB,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VSUB_VV:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_SUB,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VSUB_VX:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_SUB,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VRSUB_VX:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_SUB,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VRSUB_VI:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_V,`MEM_X,`FN_SUB,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFMIN_VV:        ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FMIN,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFMIN_VF:        ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FMIN,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFMAX_VV:        ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FMAX,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFMAX_VF:        ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FMAX,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VAND_VV:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_AND,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VAND_VX:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_AND,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VAND_VI:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_V,`MEM_X,`FN_AND,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VOR_VV:          ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_OR,      `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VOR_VX:          ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_OR,      `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VOR_VI:          ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_V,`MEM_X,`FN_OR,      `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VXOR_VV:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_XOR,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VXOR_VX:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_XOR,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VXOR_VI:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_V,`MEM_X,`FN_XOR,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMSEQ_VV:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_SEQ,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMSEQ_VX:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_SEQ,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMSEQ_VI:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_V,`MEM_X,`FN_SEQ,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMSNE_VV:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_SNE,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMSNE_VX:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_SNE,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMSNE_VI:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_V,`MEM_X,`FN_SNE,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMFEQ_VV:        ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FEQ,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMFEQ_VF:        ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FEQ,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMFNE_VV:        ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FNE,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMFNE_VF:        ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FNE,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMFLE_VV:        ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FLE,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMFLE_VF:        ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FLE,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMSLTU_VV:       ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_SLTU,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMSLTU_VX:       ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_SLTU,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMSLT_VV:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_SLT,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMSLT_VX:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_SLT,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMFLT_VV:        ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FLT,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMFLT_VF:        ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FLT,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMFGT_VF:        ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FLT,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMFGE_VF:        ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FLE,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VSLL_VV:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_SL,      `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VSLL_VX:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_SL,      `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VSLL_VI:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_V,`MEM_X,`FN_SL,      `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VSRL_VV:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_SR,      `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VSRL_VX:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_SR,      `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VSRL_VI:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_V,`MEM_X,`FN_SR,      `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VSRA_VV:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_SRA,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VSRA_VX:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_SRA,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VSRA_VI:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_V,`MEM_X,`FN_SRA,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};

     `VMSLEU_VV:       ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_SGEU,    `N,`M_X,`N,`N,`N,`Y,`N,`Y,`N,`N,`N,`N,`N};
     `VMSLEU_VI:       ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_Z,`MEM_X,`FN_SGEU,    `N,`M_X,`N,`N,`N,`Y,`N,`Y,`N,`N,`N,`N,`N};
     `VMSLEU_VX:       ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_SGEU,    `N,`M_X,`N,`N,`N,`Y,`N,`Y,`N,`N,`N,`N,`N};
     `VMSLE_VV:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_SGE,     `N,`M_X,`N,`N,`N,`Y,`N,`Y,`N,`N,`N,`N,`N};
     `VMSLE_VI:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_V,`MEM_X,`FN_SGE,     `N,`M_X,`N,`N,`N,`Y,`N,`Y,`N,`N,`N,`N,`N};
     `VMSLE_VX:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_SGE,     `N,`M_X,`N,`N,`N,`Y,`N,`Y,`N,`N,`N,`N,`N};
     `VMSGTU_VI:       ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_Z,`MEM_X,`FN_SLTU,    `N,`M_X,`N,`N,`N,`Y,`N,`Y,`N,`N,`N,`N,`N};
     `VMSGTU_VX:       ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_SLTU,    `N,`M_X,`N,`N,`N,`Y,`N,`Y,`N,`N,`N,`N,`N};
     `VMSGT_VI:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_V,`MEM_X,`FN_SLT,     `N,`M_X,`N,`N,`N,`Y,`N,`Y,`N,`N,`N,`N,`N};
     `VMSGT_VX:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_SLT,     `N,`M_X,`N,`N,`N,`Y,`N,`Y,`N,`N,`N,`N,`N};

     `VREM_VV:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_REM,     `N,`M_X,`N,`N,`Y,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VREM_VX:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_REM,     `N,`M_X,`N,`N,`Y,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VREMU_VV:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_REMU,    `N,`M_X,`N,`N,`Y,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VREMU_VX:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_REMU,    `N,`M_X,`N,`N,`Y,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VDIV_VV:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_DIV,     `N,`M_X,`N,`N,`Y,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VDIV_VX:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_DIV,     `N,`M_X,`N,`N,`Y,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VDIVU_VV:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_DIVU,    `N,`M_X,`N,`N,`Y,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VDIVU_VX:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_DIVU,    `N,`M_X,`N,`N,`Y,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFDIV_VV:        ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FDIV,    `N,`M_X,`N,`N,`Y,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFDIV_VF:        ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FDIV,    `N,`M_X,`N,`N,`Y,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFRDIV_VF:       ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FDIV,    `N,`M_X,`N,`N,`Y,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFSQRT_V:        ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_X,   `IMM_X,`MEM_X,`FN_FSQRT,   `N,`M_X,`N,`N,`Y,`Y,`N,`N,`N,`N,`N,`N,`N};

     `VMAND_MM:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_AND,     `N,`M_X,`N,`N,`N,`Y,`Y,`Y,`N,`N,`N,`N,`N};
     `VMOR_MM:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_OR,      `N,`M_X,`N,`N,`N,`Y,`Y,`Y,`N,`N,`N,`N,`N};
     `VMXOR_MM:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_XOR,     `N,`M_X,`N,`N,`N,`Y,`Y,`Y,`N,`N,`N,`N,`N};
     `VMANDN_MM:       ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_VMANDNOT,`N,`M_X,`N,`N,`N,`Y,`Y,`Y,`N,`N,`N,`N,`N};
     `VMORN_MM:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_VMORNOT, `N,`M_X,`N,`N,`N,`Y,`Y,`Y,`N,`N,`N,`N,`N};
     `VMNAND_MM:       ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_VMNAND,  `N,`M_X,`N,`N,`N,`Y,`Y,`Y,`N,`N,`N,`N,`N};
     `VMNOR_MM:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_VMNOR,   `N,`M_X,`N,`N,`N,`Y,`Y,`Y,`N,`N,`N,`N,`N};
     `VMXNOR_MM:       ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_VMXNOR,  `N,`M_X,`N,`N,`N,`Y,`Y,`Y,`N,`N,`N,`N,`N};

     `VID_V:           ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_X,   `IMM_X,`MEM_X,`FN_VID,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMERGE_VVM:      ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_VMERGE,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMERGE_VXM:      ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_VMERGE,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMERGE_VIM:      ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_V,`MEM_X,`FN_VMERGE,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
 
     `VMUL_VV:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_MUL,     `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMUL_VX:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_MUL,     `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMULH_VV:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_MULH,    `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMULH_VX:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_MULH,    `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMULHU_VV:       ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_MULHU,   `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMULHU_VX:       ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_MULHU,   `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMULHSU_VV:      ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_MULHSU,  `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMULHSU_VX:      ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_MULHSU,  `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMACC_VV:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_MACC,    `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMACC_VX:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_MACC,    `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VNMSAC_VV:       ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_NMSAC,   `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VNMSAC_VX:       ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_NMSAC,   `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMADD_VV:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_MADD,    `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMADD_VX:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_MADD,    `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VNMSUB_VV:       ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_NMSUB,   `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VNMSUB_VX:       ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_NMSUB,   `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};

     `VMINU_VV:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_MINU,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMAXU_VV:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_MAXU,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMIN_VV:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_MIN,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMAX_VV:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_MAX,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMINU_VX:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_MINU,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMAXU_VX:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_MAXU,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMIN_VX:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_MIN,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMAX_VX:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_MAX,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFSGNJ_VV:       ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FSGNJ,   `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFSGNJ_VF:       ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FSGNJ,   `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFSGNJN_VV:      ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FSGNJN,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFSGNJN_VF:      ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FSGNJN,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFSGNJX_VV:      ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FSGNJX,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFSGNJX_VF:      ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FSGNJX,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFCVT_XU_F_V:    ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_X,   `IMM_X,`MEM_X,`FN_F2IU,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFCVT_X_F_V:     ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_X,   `IMM_X,`MEM_X,`FN_F2I,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFCVT_RTZ_XU_F_V:ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_X,   `IMM_X,`MEM_X,`FN_F2IU,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFCVT_RTZ_X_F_V: ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_X,   `IMM_X,`MEM_X,`FN_F2I,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFCVT_F_XU_V:    ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_X,   `IMM_X,`MEM_X,`FN_IU2F,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFCVT_F_X_V:     ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_X,   `IMM_X,`MEM_X,`FN_I2F,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFCLASS_V:       ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_X,   `IMM_X,`MEM_X,`FN_FCLASS,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMV_V_V:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_VRS1,`IMM_X,`MEM_X,`FN_A2ZERO,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFMV_V_F:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_RS1, `IMM_X,`MEM_X,`FN_A2ZERO,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMV_V_I:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_X,   `IMM_V,`MEM_X,`FN_A1ZERO,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMV_V_X:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_RS1, `IMM_X,`MEM_X,`FN_A2ZERO,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMV_X_S:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_X,   `IMM_X,`MEM_X,`FN_A1ZERO,  `N,`M_X,`N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};//TODO:
     `VMV_S_X:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_RS1, `IMM_X,`MEM_X,`FN_A2ZERO,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFMV_F_S :       ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_X,   `IMM_X,`MEM_X,`FN_A1ZERO,  `N,`M_X,`N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `VFMV_S_F :       ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_RS1, `IMM_X,`MEM_X,`FN_A2ZERO,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VSETVLI:         ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_S,`N,`A3_X,   `A2_X,   `A1_RS1, `IMM_X,`MEM_X,`FN_ADD,     `N,`M_X,`N,`N,`N,`N,`N,`N,`Y,`N,`Y,`N,`N};
     `VSETIVLI:        ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_S,`N,`A3_X,   `A2_X,   `A1_IMM, `IMM_Z,`MEM_X,`FN_ADD,     `N,`M_X,`N,`N,`N,`N,`N,`N,`Y,`N,`Y,`N,`N};
     `VSETVL:          ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_S,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_ADD,     `N,`M_X,`N,`N,`N,`N,`N,`N,`Y,`N,`Y,`N,`N};

     //below is lut(2)// with code 0000111, 0100111, 0101011
      `VLE32_V    :    ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_RS1, `IMM_X,  `MEM_W, `FN_ADD,   `N,`M_XRD,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
      `VLSE32_V   :    ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,  `MEM_W, `FN_ADD,   `N,`M_XRD,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
      `VLOXEI32_V :    ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,  `MEM_W, `FN_ADD,   `N,`M_XRD,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
      `VSE32_V    :    ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_SD,  `A2_X,   `A1_RS1, `IMM_X,  `MEM_W, `FN_ADD,   `N,`M_XWR,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
      `VSSE32_V   :    ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_SD,  `A2_RS2, `A1_RS1, `IMM_X,  `MEM_W, `FN_ADD,   `N,`M_XWR,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
      `VSOXEI32_V :    ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_SD,  `A2_VRS2,`A1_RS1, `IMM_X,  `MEM_W, `FN_ADD,   `N,`M_XWR,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
      `VLW_V      :    ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_VRS1,`IMM_L11,`MEM_W, `FN_ADD,   `N,`M_XRD,`N,`N,`N,`Y,`Y,`N,`N,`N,`Y,`N,`N};
      `VLH_V      :    ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_VRS1,`IMM_L11,`MEM_H, `FN_ADD,   `N,`M_XRD,`N,`N,`N,`Y,`Y,`N,`N,`N,`Y,`N,`N};
      `VLB_V      :    ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_VRS1,`IMM_L11,`MEM_B, `FN_ADD,   `N,`M_XRD,`N,`N,`N,`Y,`Y,`N,`N,`N,`Y,`N,`N};
      `VLHU_V     :    ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_VRS1,`IMM_L11,`MEM_H, `FN_ADD,   `N,`M_XRD,`Y,`N,`N,`Y,`Y,`N,`N,`N,`Y,`N,`N};
      `VLBU_V     :    ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_VRS1,`IMM_L11,`MEM_B, `FN_ADD,   `N,`M_XRD,`Y,`N,`N,`Y,`Y,`N,`N,`N,`Y,`N,`N};
      `VSW_V      :    ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_SD,  `A2_IMM, `A1_VRS1,`IMM_S11,`MEM_W, `FN_ADD,   `N,`M_XWR,`N,`N,`N,`N,`Y,`N,`N,`N,`Y,`N,`N};
      `VSH_V      :    ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_SD,  `A2_IMM, `A1_VRS1,`IMM_S11,`MEM_H, `FN_ADD,   `N,`M_XWR,`N,`N,`N,`N,`Y,`N,`N,`N,`Y,`N,`N};
      `VSB_V      :    ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_SD,  `A2_IMM, `A1_VRS1,`IMM_S11,`MEM_B, `FN_ADD,   `N,`M_XWR,`N,`N,`N,`N,`Y,`N,`N,`N,`Y,`N,`N};
      `VLW12_V    :    ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_VRS1,`IMM_I,  `MEM_W, `FN_VLS12, `N,`M_XRD,`N,`N,`N,`Y,`Y,`N,`N,`N,`Y,`N,`N};
      `VLH12_V    :    ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_VRS1,`IMM_I,  `MEM_H, `FN_VLS12, `N,`M_XRD,`N,`N,`N,`Y,`Y,`N,`N,`N,`Y,`N,`N};
      `VLB12_V    :    ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_VRS1,`IMM_I,  `MEM_B, `FN_VLS12, `N,`M_XRD,`N,`N,`N,`Y,`Y,`N,`N,`N,`Y,`N,`N};
      `VLHU12_V   :    ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_VRS1,`IMM_I,  `MEM_H, `FN_VLS12, `N,`M_XRD,`Y,`N,`N,`Y,`Y,`N,`N,`N,`Y,`N,`N};
      `VLBU12_V   :    ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_VRS1,`IMM_I,  `MEM_B, `FN_VLS12, `N,`M_XRD,`Y,`N,`N,`Y,`Y,`N,`N,`N,`Y,`N,`N};
      `VSW12_V    :    ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_SD,  `A2_IMM, `A1_VRS1,`IMM_S,  `MEM_W, `FN_VLS12, `N,`M_XWR,`N,`N,`N,`N,`Y,`N,`N,`N,`Y,`N,`N};
      `VSH12_V    :    ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_SD,  `A2_IMM, `A1_VRS1,`IMM_S,  `MEM_H, `FN_VLS12, `N,`M_XWR,`N,`N,`N,`N,`Y,`N,`N,`N,`Y,`N,`N};
      `VSB12_V    :    ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_SD,  `A2_IMM, `A1_VRS1,`IMM_S,  `MEM_B, `FN_VLS12, `N,`M_XWR,`N,`N,`N,`N,`Y,`N,`N,`N,`Y,`N,`N};  

      //below is lut(3)  ,atomic,                           
      `LR_W         :  ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_RS1, `IMM_X,  `MEM_W,`FN_ADD,   `N,`M_XRD,`N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`Y};
      `SC_W         :  ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,  `MEM_W,`FN_ADD,   `N,`M_XWR,`N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`Y};
      `AMOSWAP_W    :  ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,  `MEM_W,`FN_SWAP,  `N,`M_XWR,`N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`Y};
      `AMOADD_W     :  ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,  `MEM_W,`FN_AMOADD,`N,`M_XWR,`N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`Y};
      `AMOXOR_W     :  ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,  `MEM_W,`FN_XOR,   `N,`M_XWR,`N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`Y};
      `AMOAND_W     :  ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,  `MEM_W,`FN_AND,   `N,`M_XWR,`N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`Y};
      `AMOOR_W      :  ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,  `MEM_W,`FN_OR,    `N,`M_XWR,`N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`Y};
      `AMOMIN_W     :  ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,  `MEM_W,`FN_MIN,   `N,`M_XWR,`N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`Y};
      `AMOMAX_W     :  ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,  `MEM_W,`FN_MAX,   `N,`M_XWR,`N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`Y};
      `AMOMINU_W    :  ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,  `MEM_W,`FN_MINU,  `N,`M_XWR,`Y,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`Y};
      `AMOMAXU_W    :  ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,  `MEM_W,`FN_MAXU,  `N,`M_XWR,`Y,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`Y};
      //below is lut(4),    
      //with code 1011011, 0001011  
      `VBNE        :   ctrlSignals_0 = {`Y,`N,`N,`B_B,`Y,`N,`CSR_N,`Y,`A3_PC,  `A2_VRS2,`A1_VRS1,`IMM_B,  `MEM_X,`FN_SNE,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`Y,`N,`N};
      `VBEQ        :   ctrlSignals_0 = {`Y,`N,`N,`B_B,`Y,`N,`CSR_N,`Y,`A3_PC,  `A2_VRS2,`A1_VRS1,`IMM_B,  `MEM_X,`FN_SEQ,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`Y,`N,`N};
      `VBLT        :   ctrlSignals_0 = {`Y,`N,`N,`B_B,`Y,`N,`CSR_N,`Y,`A3_PC,  `A2_VRS2,`A1_VRS1,`IMM_B,  `MEM_X,`FN_SLT,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`Y,`N,`N};
      `VBLTU       :   ctrlSignals_0 = {`Y,`N,`N,`B_B,`Y,`N,`CSR_N,`Y,`A3_PC,  `A2_VRS2,`A1_VRS1,`IMM_B,  `MEM_X,`FN_SLTU,  `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`Y,`N,`N};
      `VBGE        :   ctrlSignals_0 = {`Y,`N,`N,`B_B,`Y,`N,`CSR_N,`Y,`A3_PC,  `A2_VRS2,`A1_VRS1,`IMM_B,  `MEM_X,`FN_SGE,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`Y,`N,`N};
      `VBGEU       :   ctrlSignals_0 = {`Y,`N,`N,`B_B,`Y,`N,`CSR_N,`Y,`A3_PC,  `A2_VRS2,`A1_VRS1,`IMM_B,  `MEM_X,`FN_SGEU,  `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`Y,`N,`N};
      `JOIN        :   ctrlSignals_0 = {`Y,`N,`N,`B_B,`Y,`Y,`CSR_N,`N,`A3_PC,  `A2_X,   `A1_X,   `IMM_B,  `MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`Y,`N,`N};
      `SETRPC      :   ctrlSignals_0 = {`N,`N,`N,`B_N,`N,`N,`CSR_W,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_I,  `MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`Y,`N};
      `BARRIER     :   ctrlSignals_0 = {`N,`N,`Y,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_IMM, `IMM_Z,  `MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
      `BARRIERSUB  :   ctrlSignals_0 = {`N,`N,`Y,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_IMM, `IMM_Z,  `MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
      `ENDPRG      :   ctrlSignals_0 = {`N,`N,`Y,`B_N,`N,`Y,`CSR_N,`N,`A3_X,   `A2_X,   `A1_X,   `IMM_X,  `MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
 
      `VADD12_VI  :    ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_IMM, `A1_VRS1,`IMM_I,  `MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`Y,`N,`N,`N,`N,`Y,`N,`N};
      `VSUB12_VI  :    ctrlSignals_0 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_VRS1,`IMM_I,  `MEM_X,`FN_SUB,   `N,`M_X,  `N,`N,`N,`Y,`N,`N,`N,`N,`Y,`N,`N};

      `VFTTA_VV   :    ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_VRS3,`A2_VRS2,`A1_VRS1,`IMM_X,  `MEM_X,`FN_TTF,   `N,`M_X,  `N,`N,`N,`Y,`N,`N,`N,`Y,`N,`N,`N};
      `VFEXP_V    :    ctrlSignals_0 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_X,   `IMM_X,  `MEM_X,`FN_EXP,   `N,`M_X,  `N,`N,`Y,`Y,`N,`N,`N,`N,`N,`N,`N};         
      default :        ctrlSignals_0 = {`N,`X,`X,`B_N,`X,`X,`X,    `X,`A3_X,   `A2_X,   `A1_X,   `IMM_X,`MEM_X,`FN_X,     `N,`M_X,  `X,`X,`X,`X,`X,`X,`X,`X,`X,`X,`X};
      endcase
  end
//c   io.control   
  assign control_Signals_inst_0_o = inst_0_i;
  assign control_Signals_wid_0_o = wid_i;
  assign control_Signals_pc_0_o = pc_i ;        //c.pc := io.pc + (i.U << 2.U) // for multi-fetching
  assign control_Signals_mop_0_o = control_Signals_readmask_0_o ? 2'b11 : inst_0_i[27:26];    //Mux(c.readmask,3.U(2.W),io.inst(i)(27,26))
  assign control_Signals_fp_0_o = ctrlSignals_0[40];
  assign control_Signals_barrier_0_o = ctrlSignals_0[39];
  assign control_Signals_branch_0_o = ctrlSignals_0[38:37];
  assign control_Signals_simt_stack_0_o = ctrlSignals_0[36];
  assign control_Signals_simt_stack_op_0_o = ctrlSignals_0[35];
  assign control_Signals_csr_0_o = ctrlSignals_0[34:33];
  assign control_Signals_reverse_0_o = ctrlSignals_0[32];
  assign control_Signals_isvec_0_o = ctrlSignals_0[41];
  assign control_Signals_sel_alu3_0_o = ctrlSignals_0[31:30];
  assign control_Signals_mask_0_o = (~inst_0_i[25] | control_Signals_alu_fn_0_o == `FN_VMERGE) & control_Signals_isvec_0_o & ! control_Signals_disable_mask_0_o;
  //            mask            v0                                                            v0
  assign control_Signals_sel_alu2_0_o = ctrlSignals_0[29:28];
  assign control_Signals_sel_alu1_0_o = ctrlSignals_0[27:26];
  assign control_Signals_sel_imm_0_o = ctrlSignals_0[25:22];
  assign control_Signals_mem_whb_0_o = ctrlSignals_0[21:20];
  assign control_Signals_alu_fn_0_o = ctrlSignals_0[19:14]; //  def VFCVT_RTZ_X_F_V    = BitPat("b010010??????00111001?????1010111")
  //assign control_Signals_force_rm_rtz_0_o = (inst_0_i == `VFCVT_RTZ_X_F_V) || (inst_0_i ==`VFCVT_RTZ_XU_F_V);
  assign control_Signals_force_rm_rtz_0_o = (inst_0_i[31:26]==6'b010010 && inst_0_i[19:12] == 8'b00111001 && inst_0_i[6:0] == 7'b1010111  )|| (inst_0_i[31:26]==6'b010010 && inst_0_i[19:12] == 8'b00110001 && inst_0_i [6:0] == 7'b1010111 );
  assign control_Signals_is_vls12_0_o = ctrlSignals_0[19:14] == `FN_VLS12; //  def FN_VLS12 = 30.U(6.W)
  assign control_Signals_mul_0_o = ctrlSignals_0[13];
  assign control_Signals_mem_0_o = | control_Signals_mem_cmd_0_o;//         
  assign control_Signals_mem_cmd_0_o = ctrlSignals_0[12:11];
  assign control_Signals_mem_unsigned_0_o = ctrlSignals_0[10];
  assign control_Signals_fence_0_o = ctrlSignals_0[9];
  assign control_Signals_sfu_0_o = ctrlSignals_0[8];
  assign control_Signals_wvd_0_o = ctrlSignals_0[7];
  assign control_Signals_readmask_0_o = ctrlSignals_0[6];
  assign control_Signals_writemask_0_o = 1'b0; 
  assign control_Signals_wxd_0_o = ctrlSignals_0[4];
  assign control_Signals_tc_0_o = ctrlSignals_0[3];
  assign control_Signals_disable_mask_0_o = ctrlSignals_0[2];
  assign control_Signals_custom_signal_0_0_o = ctrlSignals_0[1];//scratchPads_regPrefix                                       
  //assign control_Signals_reg_idx1_0_o = {scratchPads_regPrefix[wid_i][8:6],inst_0_i[16:12]};//0-> scratchPads_regPrefix[wid_i], 1-> regextInfo_pre(0)
  assign control_Signals_reg_idx1_0_o = {scratchPads_regPrefix[(wid_i+1)*12-4-:3],inst_0_i[19:15]};
  //assign control_Signals_reg_idx2_0_o = {scratchPads_regPrefix[wid_i][5:3],inst_0_i[11:7]};
  assign control_Signals_reg_idx2_0_o = {scratchPads_regPrefix[(wid_i+1)*12-7-:3],inst_0_i[24:20]};
  assign control_Signals_reg_idx3_0_o = ( control_Signals_fp_0_o & (!control_Signals_isvec_0_o) ) ? {3'b000,inst_0_i[31:27]}:{scratchPads_regPrefix[(wid_i+1)*12-1-:3],inst_0_i[11:7]};
  //assign control_Signals_reg_idxw_0_o = {scratchPads_regPrefix[wid_i][11:9],inst_0_i[24:20]};
  assign control_Signals_reg_idxw_0_o = {scratchPads_regPrefix[(wid_i+1)*12-1-:3],inst_0_i[11:7]};
  assign control_Signals_imm_ext_0_o = {scratchPads_isExtI[wid_i],scratchPads_immHigh[(wid_i+1)*6-1-:6]};
  assign control_Signals_atomic_0_o = ctrlSignals_0[0];
  assign control_Signals_aq_0_o = ctrlSignals_0[0] & inst_0_i[26];
  assign control_Signals_rl_0_o = ctrlSignals_0[0] & inst_0_i[25];  
  //delete SPIKE_OUTPUT and SPIKE_INFO 
  //scratchPads_immHigh[(wid_i+1)*6-1-:6]  <=
  //scratchPads_regPrefix[(wid_i+1)*12-1-:12]
  //inst_0_i control                  
  always@(*)
    begin
      casex (inst_1_i)
      //lut 0   
     `BNE            : ctrlSignals_1 = {`N,`N,`N,`B_B,`N,`N,`CSR_N,`N,`A3_PC,  `A2_RS2, `A1_RS1, `IMM_B,`MEM_X,`FN_SNE,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
     `BEQ            : ctrlSignals_1 = {`N,`N,`N,`B_B,`N,`N,`CSR_N,`N,`A3_PC,  `A2_RS2, `A1_RS1, `IMM_B,`MEM_X,`FN_SEQ,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
     `BLT            : ctrlSignals_1 = {`N,`N,`N,`B_B,`N,`N,`CSR_N,`N,`A3_PC,  `A2_RS2, `A1_RS1, `IMM_B,`MEM_X,`FN_SLT,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
     `BLTU           : ctrlSignals_1 = {`N,`N,`N,`B_B,`N,`N,`CSR_N,`N,`A3_PC,  `A2_RS2, `A1_RS1, `IMM_B,`MEM_X,`FN_SLTU,  `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
     `BGE            : ctrlSignals_1 = {`N,`N,`N,`B_B,`N,`N,`CSR_N,`N,`A3_PC,  `A2_RS2, `A1_RS1, `IMM_B,`MEM_X,`FN_SGE,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
     `BGEU           : ctrlSignals_1 = {`N,`N,`N,`B_B,`N,`N,`CSR_N,`N,`A3_PC,  `A2_RS2, `A1_RS1, `IMM_B,`MEM_X,`FN_SGEU,  `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
     `JAL            : ctrlSignals_1 = {`N,`N,`N,`B_J,`N,`N,`CSR_N,`N,`A3_PC,  `A2_SIZE,`A1_PC,  `IMM_J,`MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `JALR           : ctrlSignals_1 = {`N,`N,`N,`B_R,`N,`N,`CSR_N,`N,`A3_PC,  `A2_SIZE,`A1_PC,  `IMM_I,`MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `AUIPC          : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_PC,  `IMM_U,`MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `CSRRW          : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_W,`N,`A3_X,   `A2_X,   `A1_RS1, `IMM_X,`MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `CSRRS          : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_S,`N,`A3_X,   `A2_X,   `A1_RS1, `IMM_X,`MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `CSRRC          : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_C,`N,`A3_X,   `A2_X,   `A1_RS1, `IMM_X,`MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `CSRRWI         : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_W,`N,`A3_X,   `A2_X,   `A1_IMM, `IMM_Z,`MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `CSRRSI         : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_S,`N,`A3_X,   `A2_X,   `A1_IMM, `IMM_Z,`MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `CSRRCI         : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_C,`N,`A3_X,   `A2_X,   `A1_IMM, `IMM_Z,`MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};

     `FENCE          : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_X,   `IMM_I,`MEM_X,`FN_ADD,   `N,`M_X,  `N,`Y,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `LW             : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_I,`MEM_W,`FN_ADD,   `N,`M_XRD,`N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `LH             : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_I,`MEM_H,`FN_ADD,   `N,`M_XRD,`N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `LB             : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_I,`MEM_B,`FN_ADD,   `N,`M_XRD,`N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `LHU            : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_I,`MEM_H,`FN_ADD,   `N,`M_XRD,`Y,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `LBU            : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_I,`MEM_B,`FN_ADD,   `N,`M_XRD,`Y,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `SW             : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_SD,  `A2_IMM, `A1_RS1, `IMM_S,`MEM_W,`FN_ADD,   `N,`M_XWR,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
     `SH             : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_SD,  `A2_IMM, `A1_RS1, `IMM_S,`MEM_H,`FN_ADD,   `N,`M_XWR,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
     `SB             : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_SD,  `A2_IMM, `A1_RS1, `IMM_S,`MEM_B,`FN_ADD,   `N,`M_XWR,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
     `LUI            : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_X,   `IMM_U,`MEM_X,`FN_A1ZERO,`N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `ADDI           : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_I,`MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `SLTI           : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_I,`MEM_X,`FN_SLT,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `SLTIU          : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_I,`MEM_X,`FN_SLTU,  `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `ANDI           : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_I,`MEM_X,`FN_AND,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `ORI            : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_I,`MEM_X,`FN_OR,    `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `XORI           : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_I,`MEM_X,`FN_XOR,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `ADD            : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `SUB            : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_SUB,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `SLT            : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_SLT,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `SLTU           : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_SLTU,  `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `AND            : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_AND,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `OR             : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_OR,    `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `XOR            : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_XOR,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `SLL            : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_SL,    `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `SRL            : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_SR,    `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `SRA            : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_SRA,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `SLLI           : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_2,`MEM_X,`FN_SL,    `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `SRLI           : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_2,`MEM_X,`FN_SR,    `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `SRAI           : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_2,`MEM_X,`FN_SRA,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};

     `MUL            : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_MUL,   `Y,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `MULH           : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_MULH,  `Y,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `MULHSU         : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_MULHSU,`Y,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `MULHU          : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_MULHU, `Y,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `DIV            : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_DIV,   `N,`M_X,  `N,`N,`Y,`N,`N,`N,`Y,`N,`N,`N,`N};
     `DIVU           : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_DIVU,  `N,`M_X,  `N,`N,`Y,`N,`N,`N,`Y,`N,`N,`N,`N};
     `REM            : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_REM,   `N,`M_X,  `N,`N,`Y,`N,`N,`N,`Y,`N,`N,`N,`N};
     `REMU           : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_REMU,  `N,`M_X,  `N,`N,`Y,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FMADD_S        : ctrlSignals_1 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_FRS3,`A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FMADD, `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FMSUB_S        : ctrlSignals_1 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_FRS3,`A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FMSUB, `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FNMSUB_S       : ctrlSignals_1 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_FRS3,`A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FNMSUB,`N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FNMADD_S       : ctrlSignals_1 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_FRS3,`A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FNMADD,`N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FADD_S         : ctrlSignals_1 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FADD,  `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FSUB_S         : ctrlSignals_1 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FSUB,  `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FMUL_S         : ctrlSignals_1 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FMUL,  `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FDIV_S         : ctrlSignals_1 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FDIV,  `N,`M_X,  `N,`N,`Y,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FSQRT_S        : ctrlSignals_1 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_RS1, `IMM_X,`MEM_X,`FN_FSQRT, `N,`M_X,  `N,`N,`Y,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FSGNJ_S        : ctrlSignals_1 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FSGNJ, `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FSGNJN_S       : ctrlSignals_1 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FSGNJN,`N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FSGNJX_S       : ctrlSignals_1 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FSGNJX,`N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FMIN_S         : ctrlSignals_1 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FMIN,  `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};

     `FMAX_S         : ctrlSignals_1 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FMAX,  `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FCVT_W_S       : ctrlSignals_1 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_RS1, `IMM_X,`MEM_X,`FN_F2I,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FCVT_WU_S      : ctrlSignals_1 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_F2IU,  `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FEQ_S          : ctrlSignals_1 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FEQ,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FLT_S          : ctrlSignals_1 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FLT,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};        
     `FLE_S          : ctrlSignals_1 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_FLE,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FCLASS_S       : ctrlSignals_1 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_RS1, `IMM_X,`MEM_X,`FN_FCLASS,`N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FCVT_S_W       : ctrlSignals_1 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_RS1, `IMM_X,`MEM_X,`FN_I2F,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `FCVT_S_WU      : ctrlSignals_1 = {`N,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_IU2F,  `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};

     //lut 1,with code 1010111
     `VFMUL_VV:        ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FMUL,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFMUL_VF:        ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FMUL,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFMADD_VV:       ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_VRS3,`A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_VFMADD,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFMADD_VF:       ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_VRS3,`A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_VFMADD,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFNMADD_VV:      ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_VRS3,`A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_VFNMADD, `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFNMADD_VF:      ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_VRS3,`A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_VFNMADD, `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFMSUB_VV:       ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_VRS3,`A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_VFMSUB,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFMSUB_VF:       ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_VRS3,`A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_VFMSUB,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFNMSUB_VV:      ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_VRS3,`A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_VFNMSUB, `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFNMSUB_VF:      ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_VRS3,`A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_VFNMSUB, `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
 
     `VFMACC_VV:       ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FMADD,   `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFMACC_VF:       ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FMADD,   `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFNMACC_VV:      ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FNMADD,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFNMACC_VF:      ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FNMADD,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFMSAC_VV:       ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FMSUB,   `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFMSAC_VF:       ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FMSUB,   `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFNMSAC_VV:      ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FNMSUB,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFNMSAC_VF:      ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FNMSUB,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VADD_VV:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_ADD,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VADD_VX:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_ADD,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VADD_VI:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_V,`MEM_X,`FN_ADD,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFADD_VV:        ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FADD,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFADD_VF:        ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FADD,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFSUB_VV:        ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FSUB,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFSUB_VF:        ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FSUB,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFRSUB_VF:       ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FSUB,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VSUB_VV:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_SUB,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VSUB_VX:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_SUB,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VRSUB_VX:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_SUB,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VRSUB_VI:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_V,`MEM_X,`FN_SUB,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFMIN_VV:        ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FMIN,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFMIN_VF:        ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FMIN,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFMAX_VV:        ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FMAX,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFMAX_VF:        ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FMAX,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VAND_VV:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_AND,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VAND_VX:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_AND,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VAND_VI:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_V,`MEM_X,`FN_AND,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VOR_VV:          ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_OR,      `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VOR_VX:          ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_OR,      `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VOR_VI:          ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_V,`MEM_X,`FN_OR,      `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VXOR_VV:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_XOR,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VXOR_VX:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_XOR,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VXOR_VI:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_V,`MEM_X,`FN_XOR,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMSEQ_VV:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_SEQ,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMSEQ_VX:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_SEQ,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMSEQ_VI:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_V,`MEM_X,`FN_SEQ,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMSNE_VV:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_SNE,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMSNE_VX:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_SNE,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMSNE_VI:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_V,`MEM_X,`FN_SNE,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMFEQ_VV:        ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FEQ,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMFEQ_VF:        ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FEQ,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMFNE_VV:        ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FNE,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMFNE_VF:        ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FNE,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMFLE_VV:        ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FLE,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMFLE_VF:        ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FLE,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMSLTU_VV:       ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_SLTU,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMSLTU_VX:       ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_SLTU,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMSLT_VV:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_SLT,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMSLT_VX:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_SLT,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMFLT_VV:        ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FLT,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMFLT_VF:        ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FLT,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMFGT_VF:        ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FLT,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMFGE_VF:        ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FLE,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VSLL_VV:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_SL,      `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VSLL_VX:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_SL,      `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VSLL_VI:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_V,`MEM_X,`FN_SL,      `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VSRL_VV:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_SR,      `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VSRL_VX:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_SR,      `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VSRL_VI:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_V,`MEM_X,`FN_SR,      `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VSRA_VV:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_SRA,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VSRA_VX:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_SRA,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VSRA_VI:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_V,`MEM_X,`FN_SRA,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};

     `VMSLEU_VV:       ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_SGEU,    `N,`M_X,`N,`N,`N,`Y,`N,`Y,`N,`N,`N,`N,`N};
     `VMSLEU_VI:       ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_Z,`MEM_X,`FN_SGEU,    `N,`M_X,`N,`N,`N,`Y,`N,`Y,`N,`N,`N,`N,`N};
     `VMSLEU_VX:       ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_SGEU,    `N,`M_X,`N,`N,`N,`Y,`N,`Y,`N,`N,`N,`N,`N};
     `VMSLE_VV:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_SGE,     `N,`M_X,`N,`N,`N,`Y,`N,`Y,`N,`N,`N,`N,`N};
     `VMSLE_VI:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_V,`MEM_X,`FN_SGE,     `N,`M_X,`N,`N,`N,`Y,`N,`Y,`N,`N,`N,`N,`N};
     `VMSLE_VX:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_SGE,     `N,`M_X,`N,`N,`N,`Y,`N,`Y,`N,`N,`N,`N,`N};
     `VMSGTU_VI:       ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_Z,`MEM_X,`FN_SLTU,    `N,`M_X,`N,`N,`N,`Y,`N,`Y,`N,`N,`N,`N,`N};
     `VMSGTU_VX:       ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_SLTU,    `N,`M_X,`N,`N,`N,`Y,`N,`Y,`N,`N,`N,`N,`N};
     `VMSGT_VI:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_V,`MEM_X,`FN_SLT,     `N,`M_X,`N,`N,`N,`Y,`N,`Y,`N,`N,`N,`N,`N};
     `VMSGT_VX:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_SLT,     `N,`M_X,`N,`N,`N,`Y,`N,`Y,`N,`N,`N,`N,`N};

     `VREM_VV:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_REM,     `N,`M_X,`N,`N,`Y,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VREM_VX:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_REM,     `N,`M_X,`N,`N,`Y,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VREMU_VV:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_REMU,    `N,`M_X,`N,`N,`Y,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VREMU_VX:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_REMU,    `N,`M_X,`N,`N,`Y,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VDIV_VV:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_DIV,     `N,`M_X,`N,`N,`Y,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VDIV_VX:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_DIV,     `N,`M_X,`N,`N,`Y,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VDIVU_VV:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_DIVU,    `N,`M_X,`N,`N,`Y,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VDIVU_VX:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_DIVU,    `N,`M_X,`N,`N,`Y,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFDIV_VV:        ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FDIV,    `N,`M_X,`N,`N,`Y,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFDIV_VF:        ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FDIV,    `N,`M_X,`N,`N,`Y,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFRDIV_VF:       ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FDIV,    `N,`M_X,`N,`N,`Y,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFSQRT_V:        ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_X,   `IMM_X,`MEM_X,`FN_FSQRT,   `N,`M_X,`N,`N,`Y,`Y,`N,`N,`N,`N,`N,`N,`N};

     `VMAND_MM:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_AND,     `N,`M_X,`N,`N,`N,`Y,`Y,`Y,`N,`N,`N,`N,`N};
     `VMOR_MM:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_OR,      `N,`M_X,`N,`N,`N,`Y,`Y,`Y,`N,`N,`N,`N,`N};
     `VMXOR_MM:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_XOR,     `N,`M_X,`N,`N,`N,`Y,`Y,`Y,`N,`N,`N,`N,`N};
     `VMANDN_MM:       ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_VMANDNOT,`N,`M_X,`N,`N,`N,`Y,`Y,`Y,`N,`N,`N,`N,`N};
     `VMORN_MM:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_VMORNOT, `N,`M_X,`N,`N,`N,`Y,`Y,`Y,`N,`N,`N,`N,`N};
     `VMNAND_MM:       ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_VMNAND,  `N,`M_X,`N,`N,`N,`Y,`Y,`Y,`N,`N,`N,`N,`N};
     `VMNOR_MM:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_VMNOR,   `N,`M_X,`N,`N,`N,`Y,`Y,`Y,`N,`N,`N,`N,`N};
     `VMXNOR_MM:       ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_VMXNOR,  `N,`M_X,`N,`N,`N,`Y,`Y,`Y,`N,`N,`N,`N,`N};

     `VID_V:           ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_X,   `IMM_X,`MEM_X,`FN_VID,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMERGE_VVM:      ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_VMERGE,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMERGE_VXM:      ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_VMERGE,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMERGE_VIM:      ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_IMM, `IMM_V,`MEM_X,`FN_VMERGE,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
 
     `VMUL_VV:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_MUL,     `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMUL_VX:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_MUL,     `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMULH_VV:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_MULH,    `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMULH_VX:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_MULH,    `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMULHU_VV:       ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_MULHU,   `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMULHU_VX:       ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_MULHU,   `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMULHSU_VV:      ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_MULHSU,  `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMULHSU_VX:      ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_MULHSU,  `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMACC_VV:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_MACC,    `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMACC_VX:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_MACC,    `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VNMSAC_VV:       ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_NMSAC,   `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VNMSAC_VX:       ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_NMSAC,   `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMADD_VV:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_MADD,    `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMADD_VX:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_MADD,    `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VNMSUB_VV:       ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_NMSUB,   `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VNMSUB_VX:       ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_VRS3,`A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_NMSUB,   `Y,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};

     `VMINU_VV:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_MINU,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMAXU_VV:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_MAXU,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMIN_VV:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_MIN,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMAX_VV:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_MAX,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMINU_VX:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_MINU,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMAXU_VX:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_MAXU,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMIN_VX:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_MIN,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMAX_VX:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_MAX,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFSGNJ_VV:       ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FSGNJ,   `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFSGNJ_VF:       ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FSGNJ,   `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFSGNJN_VV:      ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FSGNJN,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFSGNJN_VF:      ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FSGNJN,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFSGNJX_VV:      ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_VRS1,`IMM_X,`MEM_X,`FN_FSGNJX,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFSGNJX_VF:      ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,`MEM_X,`FN_FSGNJX,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFCVT_XU_F_V:    ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_X,   `IMM_X,`MEM_X,`FN_F2IU,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFCVT_X_F_V:     ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_X,   `IMM_X,`MEM_X,`FN_F2I,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFCVT_RTZ_XU_F_V:ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_X,   `IMM_X,`MEM_X,`FN_F2IU,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFCVT_RTZ_X_F_V: ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_X,   `IMM_X,`MEM_X,`FN_F2I,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFCVT_F_XU_V:    ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_X,   `IMM_X,`MEM_X,`FN_IU2F,    `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFCVT_F_X_V:     ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_X,   `IMM_X,`MEM_X,`FN_I2F,     `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFCLASS_V:       ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_VRS2,`A1_X,   `IMM_X,`MEM_X,`FN_FCLASS,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMV_V_V:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_VRS1,`IMM_X,`MEM_X,`FN_A2ZERO,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFMV_V_F:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_RS1, `IMM_X,`MEM_X,`FN_A2ZERO,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMV_V_I:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_X,   `IMM_V,`MEM_X,`FN_A1ZERO,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMV_V_X:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_RS1, `IMM_X,`MEM_X,`FN_A2ZERO,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VMV_X_S:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_X,   `IMM_X,`MEM_X,`FN_A1ZERO,  `N,`M_X,`N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};//TODO:
     `VMV_S_X:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_RS1, `IMM_X,`MEM_X,`FN_A2ZERO,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VFMV_F_S :       ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_X,   `IMM_X,`MEM_X,`FN_A1ZERO,  `N,`M_X,`N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`N};
     `VFMV_S_F :       ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_RS1, `IMM_X,`MEM_X,`FN_A2ZERO,  `N,`M_X,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
     `VSETVLI:         ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_S,`N,`A3_X,   `A2_X,   `A1_RS1, `IMM_X,`MEM_X,`FN_ADD,     `N,`M_X,`N,`N,`N,`N,`N,`N,`Y,`N,`Y,`N,`N};
     `VSETIVLI:        ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_S,`N,`A3_X,   `A2_X,   `A1_IMM, `IMM_Z,`MEM_X,`FN_ADD,     `N,`M_X,`N,`N,`N,`N,`N,`N,`Y,`N,`Y,`N,`N};
     `VSETVL:          ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_S,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,`MEM_X,`FN_ADD,     `N,`M_X,`N,`N,`N,`N,`N,`N,`Y,`N,`Y,`N,`N};

     //below is lut(2)// with code 0000111, 0100111, 0101011
      `VLE32_V      :  ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_RS1, `IMM_X,  `MEM_W, `FN_ADD,   `N,`M_XRD,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
      `VLSE32_V     :  ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,  `MEM_W, `FN_ADD,   `N,`M_XRD,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
      `VLOXEI32_V   :  ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_RS1, `IMM_X,  `MEM_W, `FN_ADD,   `N,`M_XRD,`N,`N,`N,`Y,`N,`N,`N,`N,`N,`N,`N};
      `VSE32_V      :  ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_SD,  `A2_X,   `A1_RS1, `IMM_X,  `MEM_W, `FN_ADD,   `N,`M_XWR,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
      `VSSE32_V     :  ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_SD,  `A2_RS2, `A1_RS1, `IMM_X,  `MEM_W, `FN_ADD,   `N,`M_XWR,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
      `VSOXEI32_V   :  ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_SD,  `A2_VRS2,`A1_RS1, `IMM_X,  `MEM_W, `FN_ADD,   `N,`M_XWR,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
      `VLW_V        :  ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_VRS1,`IMM_L11,`MEM_W, `FN_ADD,   `N,`M_XRD,`N,`N,`N,`Y,`Y,`N,`N,`N,`Y,`N,`N};
      `VLH_V        :  ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_VRS1,`IMM_L11,`MEM_H, `FN_ADD,   `N,`M_XRD,`N,`N,`N,`Y,`Y,`N,`N,`N,`Y,`N,`N};
      `VLB_V        :  ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_VRS1,`IMM_L11,`MEM_B, `FN_ADD,   `N,`M_XRD,`N,`N,`N,`Y,`Y,`N,`N,`N,`Y,`N,`N};
      `VLHU_V       :  ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_VRS1,`IMM_L11,`MEM_H, `FN_ADD,   `N,`M_XRD,`Y,`N,`N,`Y,`Y,`N,`N,`N,`Y,`N,`N};
      `VLBU_V       :  ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_VRS1,`IMM_L11,`MEM_B, `FN_ADD,   `N,`M_XRD,`Y,`N,`N,`Y,`Y,`N,`N,`N,`Y,`N,`N};
      `VSW_V        :  ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_SD,  `A2_IMM, `A1_VRS1,`IMM_S11,`MEM_W, `FN_ADD,   `N,`M_XWR,`N,`N,`N,`N,`Y,`N,`N,`N,`Y,`N,`N};
      `VSH_V        :  ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_SD,  `A2_IMM, `A1_VRS1,`IMM_S11,`MEM_H, `FN_ADD,   `N,`M_XWR,`N,`N,`N,`N,`Y,`N,`N,`N,`Y,`N,`N};
      `VSB_V        :  ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_SD,  `A2_IMM, `A1_VRS1,`IMM_S11,`MEM_B, `FN_ADD,   `N,`M_XWR,`N,`N,`N,`N,`Y,`N,`N,`N,`Y,`N,`N};
      `VLW12_V      :  ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_VRS1,`IMM_I,  `MEM_W, `FN_VLS12, `N,`M_XRD,`N,`N,`N,`Y,`Y,`N,`N,`N,`Y,`N,`N};
      `VLH12_V      :  ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_VRS1,`IMM_I,  `MEM_H, `FN_VLS12, `N,`M_XRD,`N,`N,`N,`Y,`Y,`N,`N,`N,`Y,`N,`N};
      `VLB12_V      :  ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_VRS1,`IMM_I,  `MEM_B, `FN_VLS12, `N,`M_XRD,`N,`N,`N,`Y,`Y,`N,`N,`N,`Y,`N,`N};
      `VLHU12_V     :  ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_VRS1,`IMM_I,  `MEM_H, `FN_VLS12, `N,`M_XRD,`Y,`N,`N,`Y,`Y,`N,`N,`N,`Y,`N,`N};
      `VLBU12_V     :  ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_VRS1,`IMM_I,  `MEM_B, `FN_VLS12, `N,`M_XRD,`Y,`N,`N,`Y,`Y,`N,`N,`N,`Y,`N,`N};
      `VSW12_V      :  ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_SD,  `A2_IMM, `A1_VRS1,`IMM_S,  `MEM_W, `FN_VLS12, `N,`M_XWR,`N,`N,`N,`N,`Y,`N,`N,`N,`Y,`N,`N};
      `VSH12_V      :  ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_SD,  `A2_IMM, `A1_VRS1,`IMM_S,  `MEM_H, `FN_VLS12, `N,`M_XWR,`N,`N,`N,`N,`Y,`N,`N,`N,`Y,`N,`N};
      `VSB12_V      :  ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_SD,  `A2_IMM, `A1_VRS1,`IMM_S,  `MEM_B, `FN_VLS12, `N,`M_XWR,`N,`N,`N,`N,`Y,`N,`N,`N,`Y,`N,`N};  

      //below is lut(3)  ,atomic,                           
      `LR_W         :  ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_RS1, `IMM_X,  `MEM_W,`FN_ADD,   `N,`M_XRD,`N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`Y};
      `SC_W         :  ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,  `MEM_W,`FN_ADD,   `N,`M_XWR,`N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`Y};
      `AMOSWAP_W    :  ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,  `MEM_W,`FN_SWAP,  `N,`M_XWR,`N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`Y};
      `AMOADD_W     :  ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,  `MEM_W,`FN_AMOADD,`N,`M_XWR,`N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`Y};
      `AMOXOR_W     :  ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,  `MEM_W,`FN_XOR,   `N,`M_XWR,`N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`Y};
      `AMOAND_W     :  ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,  `MEM_W,`FN_AND,   `N,`M_XWR,`N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`Y};
      `AMOOR_W      :  ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,  `MEM_W,`FN_OR,    `N,`M_XWR,`N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`Y};
      `AMOMIN_W     :  ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,  `MEM_W,`FN_MIN,   `N,`M_XWR,`N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`Y};
      `AMOMAX_W     :  ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,  `MEM_W,`FN_MAX,   `N,`M_XWR,`N,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`Y};
      `AMOMINU_W    :  ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,  `MEM_W,`FN_MINU,  `N,`M_XWR,`Y,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`Y};
      `AMOMAXU_W    :  ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_RS2, `A1_RS1, `IMM_X,  `MEM_W,`FN_MAXU,  `N,`M_XWR,`Y,`N,`N,`N,`N,`N,`Y,`N,`N,`N,`Y};
      //below is lut(4),    
      //with code 1011011, 0001011  
      `VBNE          : ctrlSignals_1 = {`Y,`N,`N,`B_B,`Y,`N,`CSR_N,`Y,`A3_PC,  `A2_VRS2,`A1_VRS1,`IMM_B,  `MEM_X,`FN_SNE,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`Y,`N,`N};
      `VBEQ          : ctrlSignals_1 = {`Y,`N,`N,`B_B,`Y,`N,`CSR_N,`Y,`A3_PC,  `A2_VRS2,`A1_VRS1,`IMM_B,  `MEM_X,`FN_SEQ,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`Y,`N,`N};
      `VBLT          : ctrlSignals_1 = {`Y,`N,`N,`B_B,`Y,`N,`CSR_N,`Y,`A3_PC,  `A2_VRS2,`A1_VRS1,`IMM_B,  `MEM_X,`FN_SLT,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`Y,`N,`N};
      `VBLTU         : ctrlSignals_1 = {`Y,`N,`N,`B_B,`Y,`N,`CSR_N,`Y,`A3_PC,  `A2_VRS2,`A1_VRS1,`IMM_B,  `MEM_X,`FN_SLTU,  `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`Y,`N,`N};
      `VBGE          : ctrlSignals_1 = {`Y,`N,`N,`B_B,`Y,`N,`CSR_N,`Y,`A3_PC,  `A2_VRS2,`A1_VRS1,`IMM_B,  `MEM_X,`FN_SGE,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`Y,`N,`N};
      `VBGEU         : ctrlSignals_1 = {`Y,`N,`N,`B_B,`Y,`N,`CSR_N,`Y,`A3_PC,  `A2_VRS2,`A1_VRS1,`IMM_B,  `MEM_X,`FN_SGEU,  `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`Y,`N,`N};
      `JOIN          : ctrlSignals_1 = {`Y,`N,`N,`B_B,`Y,`Y,`CSR_N,`N,`A3_PC,  `A2_X,   `A1_X,   `IMM_B,  `MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`Y,`N,`N};
      `SETRPC        : ctrlSignals_1 = {`N,`N,`N,`B_N,`N,`N,`CSR_W,`N,`A3_X,   `A2_IMM, `A1_RS1, `IMM_I,  `MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`Y,`N,`N,`Y,`N};
      `BARRIER       : ctrlSignals_1 = {`N,`N,`Y,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_IMM, `IMM_Z,  `MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
      `BARRIERSUB    : ctrlSignals_1 = {`N,`N,`Y,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_X,   `A1_IMM, `IMM_Z,  `MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
      `ENDPRG        : ctrlSignals_1 = {`N,`N,`Y,`B_N,`N,`Y,`CSR_N,`N,`A3_X,   `A2_X,   `A1_X,   `IMM_X,  `MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`N,`N,`N,`N,`N,`N,`N,`N};
      `VADD12_VI     : ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`Y,`A3_X,   `A2_IMM, `A1_VRS1,`IMM_I,  `MEM_X,`FN_ADD,   `N,`M_X,  `N,`N,`N,`Y,`N,`N,`N,`N,`Y,`N,`N};
      `VSUB12_VI     : ctrlSignals_1 = {`Y,`N,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_IMM, `A1_VRS1,`IMM_I,  `MEM_X,`FN_SUB,   `N,`M_X,  `N,`N,`N,`Y,`N,`N,`N,`N,`Y,`N,`N};
      `VFTTA_VV      : ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_VRS3,`A2_VRS2,`A1_VRS1,`IMM_X,  `MEM_X,`FN_TTF,   `N,`M_X,  `N,`N,`N,`Y,`N,`N,`N,`Y,`N,`N,`N};
      `VFEXP_V       : ctrlSignals_1 = {`Y,`Y,`N,`B_N,`N,`N,`CSR_N,`N,`A3_X,   `A2_VRS2,`A1_X,   `IMM_X,  `MEM_X,`FN_EXP,   `N,`M_X,  `N,`N,`Y,`Y,`N,`N,`N,`N,`N,`N,`N};         
      default :        ctrlSignals_1 = {`N,`X,`X,`B_N,`X,`X,`X,    `X,`A3_X,   `A2_X,   `A1_X,   `IMM_X,`MEM_X,`FN_X,     `N,`M_X,  `X,`X,`X,`X,`X,`X,`X,`X,`X,`X,`X};
      endcase
  end
//c   io.control   
  assign control_Signals_inst_1_o = inst_1_i;
  assign control_Signals_wid_1_o = wid_i;
  assign control_Signals_pc_1_o = pc_i + 4 ;        //c.pc := io.pc + (i.U << 2.U) // for multi-fetching
  assign control_Signals_mop_1_o = control_Signals_readmask_1_o ? 2'b11 : inst_1_i[27:26];    //Mux(c.readmask,3.U(2.W),io.inst(i)(27,26))
  assign control_Signals_fp_1_o = ctrlSignals_1[40];
  assign control_Signals_barrier_1_o = ctrlSignals_1[39];
  assign control_Signals_branch_1_o = ctrlSignals_1[38:37];
  assign control_Signals_simt_stack_1_o = ctrlSignals_1[36];
  assign control_Signals_simt_stack_op_1_o = ctrlSignals_1[35];
  assign control_Signals_csr_1_o = ctrlSignals_1[34:33];
  assign control_Signals_reverse_1_o = ctrlSignals_1[32];
  assign control_Signals_isvec_1_o = ctrlSignals_1[41];
  assign control_Signals_sel_alu3_1_o = ctrlSignals_1[31:30];
  assign control_Signals_mask_1_o = (~inst_1_i[25] | control_Signals_alu_fn_1_o == `FN_VMERGE) & control_Signals_isvec_1_o & ! control_Signals_disable_mask_1_o;
  assign control_Signals_sel_alu2_1_o = ctrlSignals_1[29:28];
  assign control_Signals_sel_alu1_1_o = ctrlSignals_1[27:26];
  assign control_Signals_sel_imm_1_o = ctrlSignals_1[25:22];
  assign control_Signals_mem_whb_1_o = ctrlSignals_1[21:20];
  assign control_Signals_alu_fn_1_o = ctrlSignals_1[19:14];
  assign control_Signals_force_rm_rtz_1_o = (inst_1_i[31:26]==6'b010010 && inst_1_i[19:12] == 8'b00111001 && inst_1_i[6:0] == 7'b1010111  )|| (inst_1_i[31:26]==6'b010010 && inst_1_i[19:12] == 8'b00110001 && inst_1_i [6:0] == 7'b1010111 );
  assign control_Signals_is_vls12_1_o = ctrlSignals_1[19:14] == `FN_VLS12;
  assign control_Signals_mul_1_o = ctrlSignals_1[13];
  assign control_Signals_mem_1_o = | control_Signals_mem_cmd_1_o;//         
  assign control_Signals_mem_cmd_1_o = ctrlSignals_1[12:11];
  assign control_Signals_mem_unsigned_1_o = ctrlSignals_1[10];
  assign control_Signals_fence_1_o = ctrlSignals_1[9];
  assign control_Signals_sfu_1_o = ctrlSignals_1[8];
  assign control_Signals_wvd_1_o = ctrlSignals_1[7];
  assign control_Signals_readmask_1_o = ctrlSignals_1[6];
  assign control_Signals_writemask_1_o = 1'b0; //                              
  assign control_Signals_wxd_1_o = ctrlSignals_1[4];
  assign control_Signals_tc_1_o = ctrlSignals_1[3];
  assign control_Signals_disable_mask_1_o = ctrlSignals_1[2];
  assign control_Signals_custom_signal_0_1_o = ctrlSignals_1[1];//regextInfo_0_regprefix
  assign control_Signals_reg_idx1_1_o = {regextInfo_0_regprefix[8:6],inst_1_i[19:15]};//0-> scratchPads_regPrefix[wid_i], 1-> regextInfo_pre(0)
  assign control_Signals_reg_idx2_1_o = {regextInfo_0_regprefix[5:3],inst_1_i[24:20]};
  assign control_Signals_reg_idx3_1_o = ( control_Signals_fp_1_o & !control_Signals_isvec_1_o ) ? {3'b000,inst_1_i[31:27]}:{regextInfo_0_regprefix[11:9],inst_1_i[11:7]};
  assign control_Signals_reg_idxw_1_o = {regextInfo_0_regprefix[11:9],inst_1_i[11:7]};
  assign control_Signals_imm_ext_1_o = {regextInfo_0_isExtI,regextInfo_0_immHigh};
  assign control_Signals_atomic_1_o = ctrlSignals_1[0];
  assign control_Signals_aq_1_o = ctrlSignals_1[0] & inst_1_i[26];
  assign control_Signals_rl_1_o = ctrlSignals_1[0] & inst_1_i[25];  
  //delete SPIKE_OUTPUT and SPIKE_INFO 

  assign control_mask_0_o = maskAfterExt_0;//      control_mask                  
  assign control_mask_1_o = maskAfterExt_1;

endmodule
