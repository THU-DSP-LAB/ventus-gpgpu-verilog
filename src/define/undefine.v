
`undef NUM_CLUSTER

`undef NUM_SM 

`undef NUM_SM_IN_CLUSTER 

`undef NUM_WARP 

`undef NUM_THREAD 

`undef NUM_LANE 

`undef NUM_BLOCK 

`undef NUM_WARP_IN_A_BLOCK 

`undef NUM_FETCH 

`undef NUM_COLLECTORUNIT 

`undef DEPTH_COLLECTORUNIT 

`undef NUM_ISSUE 

`undef NUM_BANK 

`undef DEPTH_BANK 

`undef NUM_VGPR 

`undef NUM_SGPR

`undef NUM_IBUFFER 

`undef NUM_SFU 

`undef NUM_CACHE_IN_SM 

`undef NUM_L2CACHE 

`undef DEPTH_WARP 

`undef DEPTH_THREAD 

`undef DEPTH_IBUFFER 

`undef DEPTH_REGBANK

`undef XLEN

`undef INSTLEN

`undef ADDRLEN

`undef SIZE_IBUFFER

`undef ICACHE_ALIGN

`undef REGIDX_WIDTH

`undef REGEXT_WIDTH

`undef LSU_NUM_ENTRY_EACH_WARP

`undef LSU_NMSHRENTRY 

`undef DCACHE_NSETS 

`undef DCACHE_NWAYS 

`undef DCACHE_BLOCKWORDS 

`undef DCACHE_WSHR_ENTRY 

`undef DCACHE_SETIDXBITS 

`undef DCACHE_WAYIDXBITS

`undef BYTESOFWORD

`undef DCACHE_WORDOFFSETBITS 

`undef DCACHE_BLOCKOFFSETBITS 

`undef DCACHE_TAGBITS 

`undef DCACHE_MSHRENTRY 

`undef DCACHE_MSHRSUBENTRY 

`undef DCACHE_NLANES 

`undef WORDLENGTH 

`undef WIDBITS 

`undef BABITS 

`undef TIWIDTH 

`undef DCACHE_ENTRY_DEPTH 

`undef DCACHE_SUBENTRY_DEPTH 

`undef NUM_CACHE_DEPTH 

`undef NUM_CLUSTER_DEPTH 

`undef D_SOURCE 

`undef A_SOURCE 

`undef CLUSTER_SOURCE 

`undef SHAREDMEM_DEPTH 

`undef SHAREDMEM_NWAYS 

`undef SHAREDMEM_BLOCKWORDS 
 
`undef SHAREMEM_SIZE 

`undef SHAREMEM_NLANES 

`undef SHAREMEM_NBANKS 

`undef SHAREDMEM_BLOCKOFFSETBITS 

`undef SHAREMEM_BANKIDXBITS 

`undef SHAREMEM_BANKOFFSET 

`undef L2CACHE_NSETS 

`undef L2CACHE_NWAYS 

`undef L2CACHE_BLOCKWORDS 

`undef L2CACHE_WRITEBYTES 

`undef L2CACHE_MEMCYCLES 

`undef L2CACHE_PORTFACTOR  

`undef L1CACHE_SOURCEBITS 

`undef NUMBER_CU 

`undef NUMBER_RES_TABLE 

`undef NUMBER_VGPR_SLOTS 

`undef NUMBER_SGPR_SLOTS

`undef NUMBER_LDS_SLOTS

`undef NUMBER_WF_SLOTS 

`undef WG_ID_WIDTH 

`undef WG_NUM_MAX 

`undef WF_COUNT_MAX 

`undef WF_COUNT_PER_WG_MAX 

`undef GDS_SIZE 

`undef NUMBER_ENTRIES 

`undef WAVE_ITEM_WIDTH 

`undef MEM_ADDR_WIDTH 

`undef NUM_SCHEDULER 

`undef RES_TABLE_ADDR_WIDTH 

`undef CU_ID_WIDTH 

`undef VGPR_ID_WIDTH 

`undef SGPR_ID_WIDTH 

`undef LDS_ID_WIDTH 

`undef WG_SLOT_ID_WIDTH 

`undef WF_COUNT_WIDTH 

`undef WF_COUNT_WIDTH_PER_WG 

`undef GDS_ID_WIDTH 

`undef ENTRY_ADDR_WIDTH 

`undef TAG_WIDTH 

`undef INIT_MAX_WG_COUNT 

`undef NUM_SCHEDULER_WIDTH 

`undef NUM_WG_X 

`undef NUM_WG_Y 

`undef NUM_WG_Z 

`undef WG_SIZE_X_WIDTH 

`undef WG_SIZE_Y_WIDTH 

`undef WG_SIZE_Z_WIDTH 

`undef LENGTH_REPLACE_TIME 

`undef TC_DIM_M 

`undef TC_DIM_N 

`undef TC_DIM_K 

//AXI4 parameter 
`undef AXI_ADDR_WIDTH   

`undef AXI_DATA_WIDTH   

`undef AXI_ID_WIDTH     

`undef AXI_LEN_WIDTH    

`undef AXI_SIZE_WIDTH   

`undef AXI_BURST_WIDTH  

`undef AXI_CACHE_WIDTH  

`undef AXI_PROT_WIDTH   

`undef AXI_QOS_WIDTH    

`undef AXI_REGION_WIDTH 

`undef AXI_USER_WIDTH   

`undef AXI_ATOP_WIDTH   

`undef AXI_RESP_WIDTH   

//AXI4LITE parameter
`undef AXILITE_ADDR_WIDTH 

`undef AXILITE_DATA_WIDTH 

`undef AXILITE_PROT_WIDTH 

`undef AXILITE_RESP_WIDTH 

`undef AXILITE_STRB_WIDTH 

//EXECUTION
`undef NUMBER_ALU 

`undef NUMBER_MUL 

`undef NUMBER_FPU 

//l1dcache_undef
`undef TLAOP_GET          

`undef TLAOP_PUTFULL      

`undef TLAOP_PUTPART      

`undef TLAOP_FLUSH        

`undef TLAPARAM_FLUSH     

`undef TLAPARAM_INV       

`undef TLAOP_ARITH        

`undef TLAOP_LOGIC        

`undef TLAPARAM_ARITHMIN  

`undef TLAPARAM_ARITHMAX  

`undef TLAPARAM_ARITHMINU 

`undef TLAPARAM_ARITHMAXU 

`undef TLAPARAM_ARITHADD  

`undef TLAPARAM_LOGICXOR  

`undef TLAPARAM_LOGICOR   

`undef TLAPARAM_LOGICAND  

`undef TLAPARAM_LOGICSWAP 

`undef TLAPARAM_LRSC      


//l2cache_undef
`undef L2CACHE_LEVEL 

`undef L2CACHE_BLOCKBYTES        

`undef L2CACHE_BEATBYTES         

`undef L2CACHE_BLOCKS            

`undef L2CACHE_SIZEBYTES         

`undef L2CACHE_BLOCKBEATS        

`undef L2CACHE_NUM_WARP          

`undef L2CACHE_NUM_SM            

`undef L2CACHE_NUM_SM_IN_CLUSTER 

`undef L2CACHE_NUM_CLUSTER       

`undef OP_BITS            

`undef PARAM_BITS         

`undef SOURCE_BITS        

`undef	URCE_S_BITS				

`undef	URCE_L_BITS				

`undef DATA_BITS                 

`undef MASK_BITS                 

`undef SIZE_BITS                 

`undef MSHRS                     

`undef SECONDARY                 

`undef PUTLISTS                  

`undef PUTBEATS                  

`undef RELLISTS                  

`undef RELBEATS                  

`undef ADDRESS_BITS              

`undef WAY_BITS                  

`undef SET_BITS                  

`undef OFFSET_BITS               

`undef L2C_BITS                  

`undef TAG_BITS                  

`undef PUT_BITS                  

`undef INNER_MASK_BITS           

`undef OUTER_MASK_BITS           

//tilelink interface opcode
`undef PUTFULLDATA           

`undef PUTPARTIALDATA        

`undef ARITHMETICDATA        

`undef LOGICALDATA           

`undef GET                   

`undef HINT                  

`undef ACQUIREBLOCK          

`undef ACQUIREPERM           

`undef PROBE                 

`undef ACCESSACK             

`undef ACCESSACKDATA         

`undef HINTACK               

`undef PROBEACK              

`undef PROBEACKDATA          

`undef RELEASE               

`undef RELEASEDATA           

`undef GRANT                 

`undef GRANTDATA             

`undef RELEASEACK            

`undef GRANTACK              

//decode_df_param
`undef Y     
`undef N     
`undef X     

`undef B_N       
`undef B_B       
`undef B_J       
`undef B_R       
`undef A1_RS1    
`undef A1_VRS1   
`undef A1_IMM    
`undef A1_PC     
`undef A3_X      
`undef A3_VRS3   
`undef A3_SD     
`undef A3_FRS3   
`undef A3_PC     
`undef A1_X      
`undef A2_X      
`undef A2_RS2    
`undef A2_VRS2   
`undef A2_IMM    
`undef A2_SIZE   

//CSR类型
`undef CSR_N     
`undef CSR_W     
`undef CSR_S     
`undef CSR_C     

//立即数类型
`undef IMM_X     
`undef IMM_I     
`undef IMM_S     
`undef IMM_B     
`undef IMM_U     
`undef IMM_2     
`undef IMM_J     
`undef IMM_V     
`undef IMM_Z     
`undef IMM_S11   
`undef IMM_L11   

//字，半字还是字节操作，用于存储指令
`undef MEM_X     
`undef MEM_W     
`undef MEM_B     
`undef MEM_H     
//2表示写存储器，1表示读存储器，0表示非存储指令
`undef M_X       
`undef M_XRD     
`undef M_XWR     
//操作类型
`undef FN_X        
`undef FN_ADD      
`undef FN_SL       
`undef FN_SEQ      
`undef FN_SNE      
`undef FN_XOR      
`undef FN_SR       
`undef FN_OR       
`undef FN_AND      
`undef FN_A1ZERO   
`undef FN_A2ZERO   
`undef FN_SUB      
`undef FN_SRA      
`undef FN_SLT      
`undef FN_SGE      
`undef FN_SLTU     
`undef FN_SGEU     
`undef FN_MAX      
`undef FN_MIN      
`undef FN_MAXU     
`undef FN_MINU     
`undef FN_MUL      
`undef FN_MULH     
`undef FN_MULHU    
`undef FN_MULHSU   
`undef FN_MACC     
`undef FN_NMSAC    
`undef FN_MADD     
`undef FN_NMSUB    

//vls12 inst
`undef FN_VLS12    

//pseudo inst
`undef FN_VMNOR    
`undef FN_VMNAND   
`undef FN_VMXNOR   
`undef FN_VID      
`undef FN_VMORNOT  
`undef FN_VMANDNOT 
`undef FN_VMERGE   


`undef FN_FADD     
`undef FN_FSUB     
`undef FN_FMUL     
`undef FN_FMADD    
`undef FN_FMSUB    
`undef FN_FNMSUB   
`undef FN_FNMADD   


`undef FN_VFMADD   
`undef FN_VFMSUB   
`undef FN_VFNMSUB  
`undef FN_VFNMADD  


`undef FN_FMIN     
`undef FN_FMAX     
`undef FN_FLE      
`undef FN_FLT      
`undef FN_FEQ      
`undef FN_FNE      
`undef FN_FCLASS   
`undef FN_FSGNJ    
`undef FN_FSGNJN   
`undef FN_FSGNJX   

`undef FN_F2IU     
`undef FN_F2I      
`undef FN_IU2F     
`undef FN_I2F      

  // for SFU
`undef FN_DIV      
`undef FN_REM      
`undef FN_DIVU     
`undef FN_REMU     
`undef FN_FDIV     
`undef FN_FSQRT    
`undef FN_EXP      

`undef FN_TTF      
`undef FN_TTH      
`undef FN_TTB      

//for atomic swap
`undef FN_SWAP     
`undef FN_AMOADD   

//below are inst
`undef ADD                
`undef ADDI               
`undef AMOADD_W           
`undef AMOAND_W           
`undef AMOMAX_W           
`undef AMOMAXU_W          
`undef AMOMIN_W           
`undef AMOMINU_W          
`undef AMOOR_W            
`undef AMOSWAP_W          
`undef AMOXOR_W           
`undef AND                
`undef ANDI               
`undef AUIPC              
`undef BARRIER            
`undef BARRIERSUB         
`undef BEQ                
`undef BGE                
`undef BGEU               
`undef BLT                
`undef BLTU               
`undef BNE                
`undef C_ADD              
`undef C_ADDI             
`undef C_ADDI16SP         
`undef C_ADDI4SPN         
`undef C_AND              
`undef C_ANDI             
`undef C_BEQZ             
`undef C_BNEZ             
`undef C_EBREAK           
`undef C_J                
`undef C_JALR             
`undef C_JR               
`undef C_LI               
`undef C_LUI              
`undef C_LW               
`undef C_LWSP             
`undef C_MV               
`undef C_NOP              
`undef C_OR               
`undef C_SUB              
`undef C_SW               
`undef C_SWSP             
`undef C_XOR              
`undef CSRRC              
`undef CSRRCI             
`undef CSRRS              
`undef CSRRSI             
`undef CSRRW              
`undef CSRRWI             
`undef DIV                
`undef DIVU               
`undef EBREAK             
`undef ECALL              
`undef ENDPRG             
`undef FADD_D             
`undef FADD_S             
`undef FCLASS_D           
`undef FCLASS_S           
`undef FCVT_D_S           
`undef FCVT_D_W           
`undef FCVT_D_WU          
`undef FCVT_S_D           
`undef FCVT_S_W           
`undef FCVT_S_WU          
`undef FCVT_W_D           
`undef FCVT_W_S           
`undef FCVT_WU_D          
`undef FCVT_WU_S          
`undef FDIV_D             
`undef FDIV_S             
`undef FENCE              
`undef FEQ_D              
`undef FEQ_S              
`undef FLD                
`undef FLE_D              
`undef FLE_S              
`undef FLT_D              
`undef FLT_S              
`undef FLW                
`undef FMADD_D            
`undef FMADD_S            
`undef FMAX_D             
`undef FMAX_S             
`undef FMIN_D             
`undef FMIN_S             
`undef FMSUB_D            
`undef FMSUB_S            
`undef FMUL_D             
`undef FMUL_S             
`undef FMV_W_X            
`undef FMV_X_W            
`undef FNMADD_D           
`undef FNMADD_S           
`undef FNMSUB_D           
`undef FNMSUB_S           
`undef FSD                
`undef FSGNJ_D            
`undef FSGNJ_S            
`undef FSGNJN_D           
`undef FSGNJN_S           
`undef FSGNJX_D           
`undef FSGNJX_S           
`undef FSQRT_D            
`undef FSQRT_S            
`undef FSUB_D             
`undef FSUB_S             
`undef FSW                
`undef JAL                
`undef JALR               
`undef JOIN               
`undef LB                 
`undef LBU                
`undef LH                 
`undef LHU                
`undef LR_W               
`undef LUI                
`undef LW                 
`undef MUL                
`undef MULH               
`undef MULHSU             
`undef MULHU              
`undef OR                 
`undef ORI                
`undef REGEXT             
`undef REGEXTI            
                          
`undef REM                
`undef REMU               
`undef SB                 
`undef SC_W               
`undef SETRPC             
`undef SH                 
`undef SLL                
`undef SLLI               
`undef SLT                
`undef SLTI               
`undef SLTIU              
`undef SLTU               
`undef SRA                
`undef SRAI               
`undef SRL                
`undef SRLI               
`undef SUB                
`undef SW                 
`undef VAADD_VV           
`undef VAADD_VX           
`undef VAADDU_VV          
`undef VAADDU_VX          
`undef VADC_VIM           
`undef VADC_VVM           
`undef VADC_VXM           
`undef VADD12_VI          
`undef VADD_VI            
`undef VADD_VV            
`undef VADD_VX            
`undef VAMOADDEI16_V      
`undef VAMOADDEI32_V      
`undef VAMOADDEI64_V      
`undef VAMOADDEI8_V       
`undef VAMOANDEI16_V      
`undef VAMOANDEI32_V      
`undef VAMOANDEI64_V      
`undef VAMOANDEI8_V       
`undef VAMOMAXEI16_V      
`undef VAMOMAXEI32_V      
`undef VAMOMAXEI64_V      
`undef VAMOMAXEI8_V       
`undef VAMOMAXUEI16_V     
`undef VAMOMAXUEI32_V     
`undef VAMOMAXUEI64_V     
`undef VAMOMAXUEI8_V      
`undef VAMOMINEI16_V      
`undef VAMOMINEI32_V      
`undef VAMOMINEI64_V      
`undef VAMOMINEI8_V       
`undef VAMOMINUEI16_V     
`undef VAMOMINUEI32_V     
`undef VAMOMINUEI64_V     
`undef VAMOMINUEI8_V      
`undef VAMOOREI16_V       
`undef VAMOOREI32_V       
`undef VAMOOREI64_V       
`undef VAMOOREI8_V        
`undef VAMOSWAPEI16_V     
`undef VAMOSWAPEI32_V     
`undef VAMOSWAPEI64_V     
`undef VAMOSWAPEI8_V      
`undef VAMOXOREI16_V      
`undef VAMOXOREI32_V      
`undef VAMOXOREI64_V      
`undef VAMOXOREI8_V       
`undef VAND_VI            
`undef VAND_VV            
`undef VAND_VX            
`undef VASUB_VV           
`undef VASUB_VX           
`undef VASUBU_VV          
`undef VASUBU_VX          
`undef VBEQ               
`undef VBGE               
`undef VBGEU              
`undef VBLT               
`undef VBLTU              
`undef VBNE               
`undef VCOMPRESS_VM       
`undef VCPOP_M            
`undef VDIV_VV            
`undef VDIV_VX            
`undef VDIVU_VV           
`undef VDIVU_VX           
`undef VFADD_VF           
`undef VFADD_VV           
`undef VFCLASS_V          
`undef VFCVT_F_X_V        
`undef VFCVT_F_XU_V       
`undef VFCVT_RTZ_X_F_V    
`undef VFCVT_RTZ_XU_F_V   
`undef VFCVT_X_F_V        
`undef VFCVT_XU_F_V       
`undef VFDIV_VF           
`undef VFDIV_VV           
`undef VFEXP_V            
`undef VFIRST_M           
`undef VFMACC_VF          
`undef VFMACC_VV          
`undef VFMADD_VF          
`undef VFMADD_VV          
`undef VFMAX_VF           
`undef VFMAX_VV           
`undef VFMERGE_VFM        
`undef VFMIN_VF           
`undef VFMIN_VV           
`undef VFMSAC_VF          
`undef VFMSAC_VV          
`undef VFMSUB_VF          
`undef VFMSUB_VV          
`undef VFMUL_VF           
`undef VFMUL_VV           
`undef VFMV_F_S           
`undef VFMV_S_F           
`undef VFMV_V_F           
`undef VFNCVT_F_F_W       
`undef VFNCVT_F_X_W       
`undef VFNCVT_F_XU_W      
`undef VFNCVT_ROD_F_F_W   
`undef VFNCVT_RTZ_X_F_W   
`undef VFNCVT_RTZ_XU_F_W  
`undef VFNCVT_X_F_W       
`undef VFNCVT_XU_F_W      
`undef VFNMACC_VF         
`undef VFNMACC_VV         
`undef VFNMADD_VF         
`undef VFNMADD_VV         
`undef VFNMSAC_VF         
`undef VFNMSAC_VV         
`undef VFNMSUB_VF         
`undef VFNMSUB_VV         
`undef VFRDIV_VF          
`undef VFREC7_V           
`undef VFREDMAX_VS        
`undef VFREDMIN_VS        
`undef VFREDOSUM_VS       
`undef VFREDUSUM_VS       
`undef VFRSQRT7_V         
`undef VFRSUB_VF          
`undef VFSGNJ_VF          
`undef VFSGNJ_VV          
`undef VFSGNJN_VF         
`undef VFSGNJN_VV         
`undef VFSGNJX_VF         
`undef VFSGNJX_VV         
`undef VFSLIDE1DOWN_VF    
`undef VFSLIDE1UP_VF      
`undef VFSQRT_V           
`undef VFSUB_VF           
`undef VFSUB_VV           
`undef VFTTA_VV           
`undef VFWADD_VF          
`undef VFWADD_VV          
`undef VFWADD_WF          
`undef VFWADD_WV          
`undef VFWCVT_F_F_V       
`undef VFWCVT_F_X_V       
`undef VFWCVT_F_XU_V      
`undef VFWCVT_RTZ_X_F_V   
`undef VFWCVT_RTZ_XU_F_V  
`undef VFWCVT_X_F_V       
`undef VFWCVT_XU_F_V      
`undef VFWMACC_VF         
`undef VFWMACC_VV         
`undef VFWMSAC_VF         
`undef VFWMSAC_VV         
`undef VFWMUL_VF          
`undef VFWMUL_VV          
`undef VFWNMACC_VF        
`undef VFWNMACC_VV        
`undef VFWNMSAC_VF        
`undef VFWNMSAC_VV        
`undef VFWREDOSUM_VS      
`undef VFWREDUSUM_VS      
`undef VFWSUB_VF          
`undef VFWSUB_VV          
`undef VFWSUB_WF          
`undef VFWSUB_WV          
`undef VID_V              
`undef VIOTA_M            
`undef VL1RE16_V          
`undef VL1RE32_V          
`undef VL1RE64_V          
`undef VL1RE8_V           
`undef VL2RE16_V          
`undef VL2RE32_V          
`undef VL2RE64_V          
`undef VL2RE8_V           
`undef VL4RE16_V          
`undef VL4RE32_V          
`undef VL4RE64_V          
`undef VL4RE8_V           
`undef VL8RE16_V          
`undef VL8RE32_V          
`undef VL8RE64_V          
`undef VL8RE8_V           
`undef VLB12_V            
`undef VLB_V              
`undef VLBU12_V           
`undef VLBU_V             
`undef VLE1024_V          
`undef VLE1024FF_V        
`undef VLE128_V           
`undef VLE128FF_V         
`undef VLE16_V            
`undef VLE16FF_V          
`undef VLE256_V           
`undef VLE256FF_V         
`undef VLE32_V            
`undef VLE32FF_V          
`undef VLE512_V           
`undef VLE512FF_V         
`undef VLE64_V            
`undef VLE64FF_V          
`undef VLE8_V             
`undef VLE8FF_V           
`undef VLH12_V            
`undef VLH_V              
`undef VLHU12_V           
`undef VLHU_V             
`undef VLM_V              
`undef VLOXEI1024_V       
`undef VLOXEI128_V        
`undef VLOXEI16_V         
`undef VLOXEI256_V        
`undef VLOXEI32_V         
`undef VLOXEI512_V        
`undef VLOXEI64_V         
`undef VLOXEI8_V          
`undef VLSE1024_V         
`undef VLSE128_V          
`undef VLSE16_V           
`undef VLSE256_V          
`undef VLSE32_V           
`undef VLSE512_V          
`undef VLSE64_V           
`undef VLSE8_V            
`undef VLUXEI1024_V       
`undef VLUXEI128_V        
`undef VLUXEI16_V         
`undef VLUXEI256_V        
`undef VLUXEI32_V         
`undef VLUXEI512_V        
`undef VLUXEI64_V         
`undef VLUXEI8_V          
`undef VLW12_V            
`undef VLW_V              
`undef VMACC_VV           
`undef VMACC_VX           
`undef VMADC_VI           
`undef VMADC_VIM          
`undef VMADC_VV           
`undef VMADC_VVM          
`undef VMADC_VX           
`undef VMADC_VXM          
`undef VMADD_VV           
`undef VMADD_VX           
`undef VMAND_MM           
`undef VMANDN_MM          
`undef VMAX_VV            
`undef VMAX_VX            
`undef VMAXU_VV           
`undef VMAXU_VX           
`undef VMERGE_VIM         
`undef VMERGE_VVM         
`undef VMERGE_VXM         
`undef VMFEQ_VF           
`undef VMFEQ_VV           
`undef VMFGE_VF           
`undef VMFGT_VF           
`undef VMFLE_VF           
`undef VMFLE_VV           
`undef VMFLT_VF           
`undef VMFLT_VV           
`undef VMFNE_VF           
`undef VMFNE_VV           
`undef VMIN_VV            
`undef VMIN_VX            
`undef VMINU_VV           
`undef VMINU_VX           
`undef VMNAND_MM          
`undef VMNOR_MM           
`undef VMOR_MM            
`undef VMORN_MM           
`undef VMSBC_VV           
`undef VMSBC_VVM          
`undef VMSBC_VX           
`undef VMSBC_VXM          
`undef VMSBF_M            
`undef VMSEQ_VI           
`undef VMSEQ_VV           
`undef VMSEQ_VX           
`undef VMSGT_VI           
`undef VMSGT_VX           
`undef VMSGTU_VI          
`undef VMSGTU_VX          
`undef VMSIF_M            
`undef VMSLE_VI           
`undef VMSLE_VV           
`undef VMSLE_VX           
`undef VMSLEU_VI          
`undef VMSLEU_VV          
`undef VMSLEU_VX          
`undef VMSLT_VV           
`undef VMSLT_VX           
`undef VMSLTU_VV          
`undef VMSLTU_VX          
`undef VMSNE_VI           
`undef VMSNE_VV           
`undef VMSNE_VX           
`undef VMSOF_M            
`undef VMUL_VV            
`undef VMUL_VX            
`undef VMULH_VV           
`undef VMULH_VX           
`undef VMULHSU_VV         
`undef VMULHSU_VX         
`undef VMULHU_VV          
`undef VMULHU_VX          
`undef VMV1R_V            
`undef VMV2R_V            
`undef VMV4R_V            
`undef VMV8R_V            
`undef VMV_S_X            
`undef VMV_V_I            
`undef VMV_V_V            
`undef VMV_V_X            
`undef VMV_X_S            
`undef VMXNOR_MM          
`undef VMXOR_MM           
`undef VNCLIP_WI          
`undef VNCLIP_WV          
`undef VNCLIP_WX          
`undef VNCLIPU_WI         
`undef VNCLIPU_WV         
`undef VNCLIPU_WX         
`undef VNMSAC_VV          
`undef VNMSAC_VX          
`undef VNMSUB_VV          
`undef VNMSUB_VX          
`undef VNSRA_WI           
`undef VNSRA_WV           
`undef VNSRA_WX           
`undef VNSRL_WI           
`undef VNSRL_WV           
`undef VNSRL_WX           
`undef VOR_VI             
`undef VOR_VV             
`undef VOR_VX             
`undef VREDAND_VS         
`undef VREDMAX_VS         
`undef VREDMAXU_VS        
`undef VREDMIN_VS         
`undef VREDMINU_VS        
`undef VREDOR_VS          
`undef VREDSUM_VS         
`undef VREDXOR_VS         
`undef VREM_VV            
`undef VREM_VX            
`undef VREMU_VV           
`undef VREMU_VX           
`undef VRGATHER_VI        
`undef VRGATHER_VV        
`undef VRGATHER_VX        
`undef VRGATHEREI16_VV    
`undef VRSUB_VI           
`undef VRSUB_VX           
`undef VS1R_V             
`undef VS2R_V             
`undef VS4R_V             
`undef VS8R_V             
`undef VSADD_VI           
`undef VSADD_VV           
`undef VSADD_VX           
`undef VSADDU_VI          
`undef VSADDU_VV          
`undef VSADDU_VX          
`undef VSB12_V            
`undef VSB_V              
`undef VSBC_VVM           
`undef VSBC_VXM           
`undef VSE1024_V          
`undef VSE128_V           
`undef VSE16_V            
`undef VSE256_V           
`undef VSE32_V            
`undef VSE512_V           
`undef VSE64_V            
`undef VSE8_V             
`undef VSETIVLI           
`undef VSETVL             
`undef VSETVLI            
`undef VSEXT_VF2          
`undef VSEXT_VF4          
`undef VSEXT_VF8          
`undef VSH12_V            
`undef VSH_V              
`undef VSLIDE1DOWN_VX     
`undef VSLIDE1UP_VX       
`undef VSLIDEDOWN_VI      
`undef VSLIDEDOWN_VX      
`undef VSLIDEUP_VI        
`undef VSLIDEUP_VX        
`undef VSLL_VI            
`undef VSLL_VV            
`undef VSLL_VX            
`undef VSM_V              
`undef VSMUL_VV           
`undef VSMUL_VX           
`undef VSOXEI1024_V       
`undef VSOXEI128_V        
`undef VSOXEI16_V         
`undef VSOXEI256_V        
`undef VSOXEI32_V         
`undef VSOXEI512_V        
`undef VSOXEI64_V         
`undef VSOXEI8_V          
`undef VSRA_VI            
`undef VSRA_VV            
`undef VSRA_VX            
`undef VSRL_VI            
`undef VSRL_VV            
`undef VSRL_VX            
`undef VSSE1024_V         
`undef VSSE128_V          
`undef VSSE16_V           
`undef VSSE256_V          
`undef VSSE32_V           
`undef VSSE512_V          
`undef VSSE64_V           
`undef VSSE8_V            
`undef VSSRA_VI           
`undef VSSRA_VV           
`undef VSSRA_VX           
`undef VSSRL_VI           
`undef VSSRL_VV           
`undef VSSRL_VX           
`undef VSSUB_VV           
`undef VSSUB_VX           
`undef VSSUBU_VV          
`undef VSSUBU_VX          
`undef VSUB12_VI          
`undef VSUB_VV            
`undef VSUB_VX            
`undef VSUXEI1024_V       
`undef VSUXEI128_V        
`undef VSUXEI16_V         
`undef VSUXEI256_V        
`undef VSUXEI32_V         
`undef VSUXEI512_V        
`undef VSUXEI64_V         
`undef VSUXEI8_V          
`undef VSW12_V            
`undef VSW_V              
`undef VWADD_VV           
`undef VWADD_VX           
`undef VWADD_WV           
`undef VWADD_WX           
`undef VWADDU_VV          
`undef VWADDU_VX          
`undef VWADDU_WV          
`undef VWADDU_WX          
`undef VWMACC_VV          
`undef VWMACC_VX          
`undef VWMACCSU_VV        
`undef VWMACCSU_VX        
`undef VWMACCU_VV         
`undef VWMACCU_VX         
`undef VWMACCUS_VX        
`undef VWMUL_VV           
`undef VWMUL_VX           
`undef VWMULSU_VV         
`undef VWMULSU_VX         
`undef VWMULU_VV          
`undef VWMULU_VX          
`undef VWREDSUM_VS        
`undef VWREDSUMU_VS       
`undef VWSUB_VV           
`undef VWSUB_VX           
`undef VWSUB_WV           
`undef VWSUB_WX           
`undef VWSUBU_VV          
`undef VWSUBU_VX          
`undef VWSUBU_WV          
`undef VWSUBU_WX          
`undef VXOR_VI            
`undef VXOR_VV            
`undef VXOR_VX            
`undef VZEXT_VF2          
`undef VZEXT_VF4          
`undef VZEXT_VF8          
`undef XOR                
`undef XORI               

//fpu op
`undef FN_FADD   
`undef FN_FSUB   
`undef FN_FMUL   
`undef FN_FMADD  
`undef FN_FMSUB  
`undef FN_FNMSUB 
`undef FN_FNMADD 
`undef FN_FMIN   
`undef FN_FMAX   
`undef FN_FLE    
`undef FN_FLT    
`undef FN_FEQ    
`undef FN_FNE    
`undef FN_FCLASS 
`undef FN_FSGNJ  
`undef FN_FSGNJN 
`undef FN_FSGNJX 
`undef FN_F2IU   
`undef FN_F2I    
`undef FN_F2LU   
`undef FN_F2L    
`undef FN_IU2F   
`undef FN_I2F    
`undef FN_LU2F   
`undef FN_L2F    

//rounding
`undef RNE 
`undef RTZ 
`undef RDN 
`undef RUP 
`undef RMM 

//CSR
`undef CSR_FFLAGS            
`undef CSR_FRM               
`undef CSR_FCSR              
`undef CSR_THREADID          
`undef CSR_WG_WF_COUNT       
`undef CSR_WF_SIZE_DISPATCH  
`undef CSR_KNL_BASE          
`undef CSR_WG_ID             
`undef CSR_WF_TAG_DISPATCH   
`undef CSR_LDS_BASE_DISPATCH 
`undef CSR_PDS_BASEADDR      
`undef CSR_WG_ID_X           
`undef CSR_WG_ID_Y           
`undef CSR_WG_ID_Z           
`undef CSR_PRINT             
`undef CSR_RPC               

//CSR
`undef CSR_VSTART            
`undef CSR_VXSAT             
`undef CSR_VXRM              
`undef CSR_VCSR              
`undef CSR_VL                
`undef CSR_VTYPE             
`undef CSR_VLENB             

`undef CSR_PRV_M             
//Machine Information Registers
`undef CSR_MVENDORID         
`undef CSR_MARCHID           
`undef CSR_MIMPID            
`undef CSR_MHARTID           
//Machine Trap Setup
`undef CSR_MSTATUS           
`undef CSR_MISA              
`undef CSR_MIE               
`undef CSR_MTVEC             
`undef CSR_MCOUNTEREN        
//Machine Trap Handling
`undef CSR_MSCRATCH          
`undef CSR_MEPC              
`undef CSR_MCAUSE            
`undef CSR_MTVAL             
`undef CSR_MIP               
//Machine Counter/Timers
`undef CSR_MCYCLE            
`undef CSR_MINSTRET          
`undef CSR_MCYCLEH           
`undef CSR_MINSTRETH         
//Machine Counter Setup
`undef CSR_MCOUNTINHIBIT     
