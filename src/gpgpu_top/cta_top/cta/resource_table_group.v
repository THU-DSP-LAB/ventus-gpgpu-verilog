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
// Author: Gu, Zihan
// Description:

`timescale 1ns/1ns
`include "define.v"

module resource_table_group #(
  parameter NUMBER_CU = 2//NUMBER_CU / NUMBER_RES_TABLE
)(  
  input                                             clk             ,
  input                                             rst_n           ,

  input                                             alloc_en_i      ,
  input                                             dealloc_en_i    ,
  input   [`WG_ID_WIDTH-1:0]                        wg_id_i         ,
  input   [`CU_ID_WIDTH-`RES_TABLE_ADDR_WIDTH-1:0]  sub_cu_id_i     ,
  input   [`LDS_ID_WIDTH-1:0]                       lds_start_i     ,
  input   [`LDS_ID_WIDTH:0]                         lds_size_i      ,
  input   [`VGPR_ID_WIDTH-1:0]                      vgpr_start_i    ,
  input   [`VGPR_ID_WIDTH:0]                        vgpr_size_i     ,
  input   [`SGPR_ID_WIDTH-1:0]                      sgpr_start_i    ,
  input   [`SGPR_ID_WIDTH:0]                        sgpr_size_i     ,
  input   [`WF_COUNT_WIDTH_PER_WG-1:0]              wf_count_i      ,
  input                                             done_cancelled_i,

  output                                            res_tbl_done_o  ,
  output  [`LDS_ID_WIDTH-1:0]                       lds_start_o     ,
  output  [`LDS_ID_WIDTH:0]                         lds_size_o      ,
  output  [`VGPR_ID_WIDTH-1:0]                      vgpr_start_o    ,
  output  [`VGPR_ID_WIDTH:0]                        vgpr_size_o     ,
  output  [`SGPR_ID_WIDTH-1:0]                      sgpr_start_o    ,
  output  [`SGPR_ID_WIDTH:0]                        sgpr_size_o     ,
  output  [`WF_COUNT_WIDTH-1:0]                     wf_count_o      ,
  output  [`WG_SLOT_ID_WIDTH:0]                     wg_count_o      
  );

  localparam  CU_ID_WIDTH = `CU_ID_WIDTH - `RES_TABLE_ADDR_WIDTH;

  reg                                               alloc_en_reg  ;
  reg                                               dealloc_en_reg;
  reg   [`CU_ID_WIDTH-`RES_TABLE_ADDR_WIDTH-1:0]    cu_id_reg     ;
  reg   [`LDS_ID_WIDTH:0]                           lds_size_reg  ;
  reg   [`VGPR_ID_WIDTH:0]                          vgpr_size_reg ;
  reg   [`SGPR_ID_WIDTH:0]                          sgpr_size_reg ;
  reg   [`WF_COUNT_WIDTH-1:0]                       wf_count_reg  ;
  reg   [`LDS_ID_WIDTH-1:0]                         lds_start_reg ;
  reg   [`VGPR_ID_WIDTH-1:0]                        vgpr_start_reg;
  reg   [`SGPR_ID_WIDTH-1:0]                        sgpr_start_reg;
  reg                                               lds_done_out  ;
  reg                                               vgpr_done_out ;
  reg                                               sgpr_done_out ;

  wire  [`WG_SLOT_ID_WIDTH-1:0]                     wg_slot_id_gen ;
  wire  [`WG_SLOT_ID_WIDTH-1:0]                     wg_slot_id_find;
  //wire  [`WG_SLOT_ID_WIDTH:0]                       wg_max_update      ;
  //wire  [CU_ID_WIDTH-1:0]                           wg_max_update_cu_id;

  wire                                              lds_res_table_done         ;
  wire  [`LDS_ID_WIDTH:0]                           lds_cam_biggest_space_size ;
  wire  [`LDS_ID_WIDTH-1:0]                         lds_cam_biggest_space_addr ;
  wire                                              vgpr_res_table_done        ;
  wire  [`VGPR_ID_WIDTH:0]                          vgpr_cam_biggest_space_size;
  wire  [`VGPR_ID_WIDTH-1:0]                        vgpr_cam_biggest_space_addr;
  wire                                              sgpr_res_table_done        ;
  wire  [`SGPR_ID_WIDTH:0]                          sgpr_cam_biggest_space_size;
  wire  [`SGPR_ID_WIDTH-1:0]                        sgpr_cam_biggest_space_addr;
  //wire  [`WF_COUNT_WIDTH-1:0]                       wf_res_tbl_count           ;
  //wire  [`WG_SLOT_ID_WIDTH:0]                       wg_throttling_count        ;

  reg   [`LDS_ID_WIDTH:0]                           lds_size_out  ;
  reg   [`VGPR_ID_WIDTH:0]                          vgpr_size_out ;
  reg   [`SGPR_ID_WIDTH:0]                          sgpr_size_out ;
  reg   [`LDS_ID_WIDTH-1:0]                         lds_start_out ;
  reg   [`VGPR_ID_WIDTH-1:0]                        vgpr_start_out;
  reg   [`SGPR_ID_WIDTH-1:0]                        sgpr_start_out;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      alloc_en_reg   <= 'd0;
      dealloc_en_reg <= 'd0;
    end
    else begin
      alloc_en_reg   <= alloc_en_i  ;
      dealloc_en_reg <= dealloc_en_i;
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      cu_id_reg      <= 'd0; 
      lds_size_reg   <= 'd0;
      vgpr_size_reg  <= 'd0;
      sgpr_size_reg  <= 'd0;
      lds_start_reg  <= 'd0;
      vgpr_start_reg <= 'd0;
      sgpr_start_reg <= 'd0;
    end
    else if(alloc_en_i || dealloc_en_i) begin
      cu_id_reg      <= sub_cu_id_i ;
      lds_size_reg   <= lds_size_i  ;
      vgpr_size_reg  <= vgpr_size_i ;
      sgpr_size_reg  <= sgpr_size_i ;
      lds_start_reg  <= lds_start_i ;
      vgpr_start_reg <= vgpr_start_i;
      sgpr_start_reg <= sgpr_start_i;
    end
    else begin
      cu_id_reg      <= cu_id_reg     ; 
      lds_size_reg   <= lds_size_reg  ;
      vgpr_size_reg  <= vgpr_size_reg ;
      sgpr_size_reg  <= sgpr_size_reg ;
      lds_start_reg  <= lds_start_reg ;
      vgpr_start_reg <= vgpr_start_reg;
      sgpr_start_reg <= sgpr_start_reg;
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      wf_count_reg <= 'd0;
    end
    else if(alloc_en_i) begin
      wf_count_reg <= wf_count_i;
    end
    else if(dealloc_en_i) begin
      wf_count_reg <= 'd0;
    end
    else begin
      wf_count_reg <= wf_count_reg;
    end
  end

  wg_slot_id_convert_opt #(
    .NUMBER_CU  (NUMBER_CU  ),
    .CU_ID_WIDTH(CU_ID_WIDTH)
  )
  wf_slot_id_gen (
   .clk              (clk            ),
   .rst_n            (rst_n          ),
                    
   .wg_id_i          (wg_id_i        ),
   .cu_id_i          (sub_cu_id_i    ),
   .find_and_cancel_i(dealloc_en_i   ),
   .generate_i       (alloc_en_i     ),
   .wg_slot_id_gen_o (wg_slot_id_gen ),
   .wg_slot_id_find_o(wg_slot_id_find)
   );

  resource_table #(
    .NUMBER_CU       (NUMBER_CU         ),
    .CU_ID_WIDTH     (CU_ID_WIDTH       ),
    .RES_ID_WIDTH    (`VGPR_ID_WIDTH    ),//have changed
    .NUMBER_RES_SLOTS(`NUMBER_VGPR_SLOTS)
  )
  vgpr_res_tbl (
    .clk                     (clk                        ),     
    .rst_n                   (rst_n                      ),       
                              
    .alloc_res_en_i          (alloc_en_reg               ),             
    .dealloc_res_en_i        (dealloc_en_reg             ),               
    .alloc_cu_id_i           (cu_id_reg                  ),           
    .dealloc_cu_id_i         (cu_id_reg                  ),               
    .alloc_wg_slot_id_i      (wg_slot_id_gen             ),                 
    .dealloc_wg_slot_id_i    (wg_slot_id_find            ),               
    .alloc_res_size_i        (vgpr_size_reg              ),         
    .alloc_res_start_i       (vgpr_start_reg             ),             
                            
    .res_table_done_o        (vgpr_res_table_done        ),             
    .cam_biggest_space_size_o(vgpr_cam_biggest_space_size), 
    .cam_biggest_space_addr_o(vgpr_cam_biggest_space_addr)
    );

  resource_table #(
    .NUMBER_CU       (NUMBER_CU         ),
    .CU_ID_WIDTH     (CU_ID_WIDTH       ),
    .RES_ID_WIDTH    (`SGPR_ID_WIDTH    ),//have changed
    .NUMBER_RES_SLOTS(`NUMBER_SGPR_SLOTS)
  )
  sgpr_res_tbl (
    .clk                     (clk                        ),         
    .rst_n                   (rst_n                      ),           
                            
    .alloc_res_en_i          (alloc_en_reg               ),             
    .dealloc_res_en_i        (dealloc_en_reg             ),               
    .alloc_cu_id_i           (cu_id_reg                  ),             
    .dealloc_cu_id_i         (cu_id_reg                  ),           
    .alloc_wg_slot_id_i      (wg_slot_id_gen             ),       
    .dealloc_wg_slot_id_i    (wg_slot_id_find            ),           
    .alloc_res_size_i        (sgpr_size_reg              ),       
    .alloc_res_start_i       (sgpr_start_reg             ),             
                            
    .res_table_done_o        (sgpr_res_table_done        ),           
    .cam_biggest_space_size_o(sgpr_cam_biggest_space_size),
    .cam_biggest_space_addr_o(sgpr_cam_biggest_space_addr)
    );

  resource_table #(
    .NUMBER_CU       (NUMBER_CU        ),
    .CU_ID_WIDTH     (CU_ID_WIDTH      ),
    .RES_ID_WIDTH    (`LDS_ID_WIDTH    ),//have changed
    .NUMBER_RES_SLOTS(`NUMBER_LDS_SLOTS)
  )
  lds_res_tbl (
    .clk                     (clk                       ),    
    .rst_n                   (rst_n                     ),  
                            
    .alloc_res_en_i          (alloc_en_reg              ),            
    .dealloc_res_en_i        (dealloc_en_reg            ),              
    .alloc_cu_id_i           (cu_id_reg                 ),          
    .dealloc_cu_id_i         (cu_id_reg                 ),        
    .alloc_wg_slot_id_i      (wg_slot_id_gen            ),            
    .dealloc_wg_slot_id_i    (wg_slot_id_find           ),          
    .alloc_res_size_i        (lds_size_reg              ),        
    .alloc_res_start_i       (lds_start_reg             ),            
                            
    .res_table_done_o        (lds_res_table_done        ),      
    .cam_biggest_space_size_o(lds_cam_biggest_space_size),
    .cam_biggest_space_addr_o(lds_cam_biggest_space_addr)
    );

  wg_resource_table_neo #(
    .NUMBER_CU  (NUMBER_CU  ),
    .CU_ID_WIDTH(CU_ID_WIDTH)
  )
  wf_res_tbl (
    .clk                 (clk             ),          
    .rst_n               (rst_n           ),          
                          
    .cu_id_i             (cu_id_reg       ),  
    .alloc_en_i          (alloc_en_reg    ),  
    .dealloc_en_i        (dealloc_en_reg  ),    
    .wf_count_i          (wf_count_reg    ),  
    .alloc_wg_slot_id_i  (wg_slot_id_gen  ),  
    .dealloc_wg_slot_id_i(wg_slot_id_find ),  
    .wf_count_o          (wf_count_o      )
    );

  //assign wg_max_update       = {(`WG_SLOT_ID_WIDTH+1){1'b0}};
  //assign wg_max_update_cu_id = {CU_ID_WIDTH{1'b0}}          ;

  throttling_engine #(
    .NUMBER_CU  (NUMBER_CU  ),
    .CU_ID_WIDTH(CU_ID_WIDTH)
  )
  wg_throttling (
    .clk                   (clk                          ),    
    .rst_n                 (rst_n                        ),          
                                                                 
    .cu_id_i               (cu_id_reg                    ),                
    .alloc_en_i            (alloc_en_reg                 ),      
    .dealloc_en_i          (dealloc_en_reg               ),        
    .wg_max_update_i       ({(`WG_SLOT_ID_WIDTH+1){1'b0}}),//TODO update throttling table according to cu contention info              
    .wg_max_update_valid_i (1'b0                         ),      
    .wg_max_update_all_cu_i(1'b0                         ),        
    .wg_max_update_cu_id_i ({CU_ID_WIDTH{1'b0}}          ),              
    .wg_count_available_o  (wg_count_o                   )          
    );

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      lds_done_out   <= 'd0;
      lds_size_out   <= 'd0;  
      lds_start_out  <= 'd0; 
    end
    else if(alloc_en_i || dealloc_en_i) begin
      lds_done_out   <= 1'b0;
    end
    else if(lds_res_table_done) begin
      lds_done_out   <= 1'b1                      ;
      lds_size_out   <= lds_cam_biggest_space_size;
      lds_start_out  <= lds_cam_biggest_space_addr;
    end
    else if(done_cancelled_i) begin
      lds_done_out   <= 1'b0;
    end
    else begin
      lds_done_out   <= lds_done_out  ;  
      lds_size_out   <= lds_size_out  ;
      lds_start_out  <= lds_start_out ;
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      vgpr_done_out   <= 'd0;
      vgpr_size_out   <= 'd0;  
      vgpr_start_out  <= 'd0; 
    end
    else if(alloc_en_i || dealloc_en_i) begin
      vgpr_done_out   <= 1'b0;
    end
    else if(vgpr_res_table_done) begin
      vgpr_done_out   <= 1'b1                      ;
      vgpr_size_out   <= vgpr_cam_biggest_space_size;
      vgpr_start_out  <= vgpr_cam_biggest_space_addr;
    end
    else if(done_cancelled_i) begin
      vgpr_done_out   <= 1'b0;
    end
    else begin
      vgpr_done_out   <= vgpr_done_out  ;  
      vgpr_size_out   <= vgpr_size_out  ;
      vgpr_start_out  <= vgpr_start_out ;
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      sgpr_done_out   <= 'd0;
      sgpr_size_out   <= 'd0;  
      sgpr_start_out  <= 'd0; 
    end
    else if(alloc_en_i || dealloc_en_i) begin
      sgpr_done_out   <= 1'b0;
    end
    else if(sgpr_res_table_done) begin
      sgpr_done_out   <= 1'b1                      ;
      sgpr_size_out   <= sgpr_cam_biggest_space_size;
      sgpr_start_out  <= sgpr_cam_biggest_space_addr;
    end
    else if(done_cancelled_i) begin
      sgpr_done_out   <= 1'b0;
    end
    else begin
      sgpr_done_out   <= sgpr_done_out  ;  
      sgpr_size_out   <= sgpr_size_out  ;
      sgpr_start_out  <= sgpr_start_out ;
    end
  end

  assign lds_size_o     = lds_size_out  ;
  assign lds_start_o    = lds_start_out ;
  assign vgpr_size_o    = vgpr_size_out ;
  assign vgpr_start_o   = vgpr_start_out;
  assign sgpr_size_o    = sgpr_size_out ;
  assign sgpr_start_o   = sgpr_start_out;
  assign res_tbl_done_o = lds_done_out && vgpr_done_out && sgpr_done_out;

endmodule
