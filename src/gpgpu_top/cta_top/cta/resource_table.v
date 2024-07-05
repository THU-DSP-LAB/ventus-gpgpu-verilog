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

module resource_table #(
  parameter NUMBER_CU        = 2,
  parameter CU_ID_WIDTH      = 1,
  parameter RES_ID_WIDTH     = 10,
  parameter NUMBER_RES_SLOTS = 1024
  )(
  input                               clk                     ,
  input                               rst_n                   ,

  input                               alloc_res_en_i          ,
  input                               dealloc_res_en_i        ,
  input   [CU_ID_WIDTH-1:0]           alloc_cu_id_i           ,
  input   [CU_ID_WIDTH-1:0]           dealloc_cu_id_i         ,
  input   [`WG_SLOT_ID_WIDTH-1:0]     alloc_wg_slot_id_i      ,
  input   [`WG_SLOT_ID_WIDTH-1:0]     dealloc_wg_slot_id_i    ,
  input   [RES_ID_WIDTH:0]            alloc_res_size_i        ,
  input   [RES_ID_WIDTH-1:0]          alloc_res_start_i       ,

  output                              res_table_done_o        ,
  output  [RES_ID_WIDTH:0]            cam_biggest_space_size_o,
  output  [RES_ID_WIDTH-1:0]          cam_biggest_space_addr_o
  );

  localparam  WG_SLOT_ID_WIDTH_TABLE = `WG_SLOT_ID_WIDTH + 1                            ;
  localparam  TABLE_ADDR_WIDTH       = WG_SLOT_ID_WIDTH_TABLE + CU_ID_WIDTH             ;
  localparam  TABLE_ENTRY_WIDTH      = 2 * WG_SLOT_ID_WIDTH_TABLE + 2 * RES_ID_WIDTH + 1;

  localparam  RES_STRT_L   = 0                                        ;
  localparam  RES_STRT_H   = RES_ID_WIDTH - 1                         ;
  localparam  RES_SIZE_L   = RES_STRT_H + 1                           ;
  localparam  RES_SIZE_H   = RES_SIZE_L + RES_ID_WIDTH                ;
  localparam  PREV_ENTRY_L = RES_SIZE_H + 1                           ;
  localparam  PREV_ENTRY_H = PREV_ENTRY_L + WG_SLOT_ID_WIDTH_TABLE - 1;
  localparam  NEXT_ENTRY_L = PREV_ENTRY_H + 1                         ;
  localparam  NEXT_ENTRY_H = NEXT_ENTRY_L + WG_SLOT_ID_WIDTH_TABLE - 1;

  localparam  NUM_ENTRIES              = NUMBER_CU * (`NUMBER_WF_SLOTS + 1)                ;
  localparam  RES_TABLE_END_TABLE      = (1 << WG_SLOT_ID_WIDTH_TABLE) - 1                 ;
  localparam  RES_TABLE_END_TABLE_U    = RES_TABLE_END_TABLE[WG_SLOT_ID_WIDTH_TABLE-1:0]   ;
  localparam  RES_TABLE_HEAD_POINTER   = (1 << WG_SLOT_ID_WIDTH_TABLE) - 2                 ; 
  localparam  RES_TABLE_HEAD_POINTER_U = RES_TABLE_HEAD_POINTER[WG_SLOT_ID_WIDTH_TABLE-1:0];

  //the states of four state machine
  //main state machine
  localparam  ST_M_IDLE     = 4'b0001;
  localparam  ST_M_ALLOC    = 4'b0010;
  localparam  ST_M_DEALLOC  = 4'b0100;
  localparam  ST_M_FIND_MAX = 4'b1000;
  reg   [3:0]   m_state;
  //reg   [3:0]   m_curr_state;
  //reg   [3:0]   m_next_state;

  //alloc state machine
  localparam  ST_A_IDLE              = 4'b0001;
  localparam  ST_A_FIND_POSITION     = 4'b0010;
  localparam  ST_A_UPDATE_PREV_ENTRY = 4'b0100;
  localparam  ST_A_WRITE_NEW_ENTRY   = 4'b1000;
  reg   [3:0]   a_state;

  //dealloc state machine
  localparam  ST_D_IDLE              = 5'b00001;
  localparam  ST_D_READ_PREV_ENTRY   = 5'b00010;
  localparam  ST_D_READ_NEXT_ENTRY   = 5'b00100;
  localparam  ST_D_UPDATE_PREV_ENTRY = 5'b01000;
  localparam  ST_D_UPDATE_NEXT_ENTRY = 5'b10000;
  reg   [4:0]   d_state;

  //find max state machine
  localparam  ST_F_IDLE       = 4'b0001;
  localparam  ST_F_FIRST_ITEM = 4'b0010;
  localparam  ST_F_SEARCHING  = 4'b0100;
  localparam  ST_F_LAST_ITEM  = 4'b1000;
  reg   [3:0]   f_state;

  //input reg
  reg                                 res_table_done_reg      ;
  reg                                 alloc_res_en_reg        ;
  reg                                 dealloc_res_en_reg      ;
  reg   [CU_ID_WIDTH-1:0]             alloc_cu_id_reg         ;
  reg   [CU_ID_WIDTH-1:0]             dealloc_cu_id_reg       ;
  reg   [WG_SLOT_ID_WIDTH_TABLE-1:0]  alloc_wg_slot_id_reg    ;
  reg   [WG_SLOT_ID_WIDTH_TABLE-1:0]  dealloc_wg_slot_id_reg  ;
  reg   [RES_ID_WIDTH:0]              alloc_res_size_reg      ;
  reg   [RES_ID_WIDTH-1:0]            alloc_res_start_reg     ;

  //ram of resource table
  reg   [NUM_ENTRIES*TABLE_ENTRY_WIDTH-1:0]      resource_table_ram    ;
  reg   [NUMBER_CU*WG_SLOT_ID_WIDTH_TABLE-1:0]   table_head_pointer    ;
  reg   [WG_SLOT_ID_WIDTH_TABLE-1:0]             table_head_pointer_reg;

  //datapath reg
  reg   [TABLE_ENTRY_WIDTH-1:0]       res_table_wr_reg     ;
  reg   [TABLE_ENTRY_WIDTH-1:0]       res_table_rd_reg     ;
  reg   [TABLE_ENTRY_WIDTH-1:0]       res_table_last_rd_reg;
  reg   [CU_ID_WIDTH-1:0]             res_addr_cu_id       ;
  reg   [WG_SLOT_ID_WIDTH_TABLE-1:0]  res_addr_wg_slot     ;
  reg                                 res_table_rd_en      ;
  reg                                 res_table_wr_en      ;
  reg                                 res_table_rd_valid   ;
  reg   [RES_ID_WIDTH:0]              res_table_max_size   ;
  reg   [RES_ID_WIDTH-1:0]            res_table_max_start  ;

  //control signals
  reg                                 alloc_start       ;
  reg                                 dealloc_start     ;
  reg                                 find_max_start    ;
  reg                                 alloc_done        ;
  reg                                 dealloc_done      ;
  reg                                 find_max_done     ;
  reg                                 new_entry_is_last ;
  reg                                 new_entry_is_first;
  reg                                 rem_entry_is_last ;
  reg                                 rem_entry_is_first;
  reg   [NUMBER_CU-1:0]               cu_initialized    ;
  reg                                 cu_initialized_reg;

  assign  res_table_done_o = res_table_done_reg;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      alloc_res_en_reg   <= 'd0;
      dealloc_res_en_reg <= 'd0;
      res_table_rd_valid <= 'd0;
    end
    else begin
      alloc_res_en_reg   <= alloc_res_en_i  ;
      dealloc_res_en_reg <= dealloc_res_en_i;
      res_table_rd_valid <= res_table_rd_en ;
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      alloc_cu_id_reg        <= 'd0;
      alloc_wg_slot_id_reg   <= 'd0;
      alloc_res_size_reg     <= 'd0;
      alloc_res_start_reg    <= 'd0;
      res_addr_cu_id         <= 'd0;
      dealloc_cu_id_reg      <= 'd0;
      dealloc_wg_slot_id_reg <= 'd0;
    end
    else if(alloc_res_en_i) begin
      alloc_cu_id_reg        <= alloc_cu_id_i     ;
      alloc_wg_slot_id_reg   <= alloc_wg_slot_id_i;
      alloc_res_size_reg     <= alloc_res_size_i  ;
      alloc_res_start_reg    <= alloc_res_start_i ;
      res_addr_cu_id         <= alloc_cu_id_i     ;
    end
    else if(dealloc_res_en_i) begin
      dealloc_cu_id_reg      <= dealloc_cu_id_i     ;
      dealloc_wg_slot_id_reg <= dealloc_wg_slot_id_i;
      res_addr_cu_id         <= dealloc_cu_id_i     ;
    end
    else begin
      alloc_cu_id_reg        <= alloc_cu_id_reg       ; 
      alloc_wg_slot_id_reg   <= alloc_wg_slot_id_reg  ; 
      alloc_res_size_reg     <= alloc_res_size_reg    ; 
      alloc_res_start_reg    <= alloc_res_start_reg   ; 
      res_addr_cu_id         <= res_addr_cu_id        ; 
      dealloc_cu_id_reg      <= dealloc_cu_id_reg     ; 
      dealloc_wg_slot_id_reg <= dealloc_wg_slot_id_reg; 
    end
  end

  //main state machine of the resource table
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      alloc_start        <= 1'b0     ;
      dealloc_start      <= 1'b0     ;
      find_max_start     <= 1'b0     ;
      res_table_done_reg <= 1'b0     ;
      m_state            <= ST_M_IDLE;
    end
    else begin
      case(m_state)
        ST_M_IDLE : begin
          if(alloc_res_en_reg) begin
            alloc_start        <= 1'b1      ;
            dealloc_start      <= 1'b0      ;
            find_max_start     <= 1'b0      ;
            res_table_done_reg <= 1'b0      ;
            m_state            <= ST_M_ALLOC;
          end
          else if(dealloc_res_en_reg) begin
            alloc_start        <= 1'b0        ;
            dealloc_start      <= 1'b1        ;
            find_max_start     <= 1'b0        ;
            res_table_done_reg <= 1'b0        ;
            m_state            <= ST_M_DEALLOC;
          end
          else begin
            alloc_start        <= 1'b0   ;  
            dealloc_start      <= 1'b0   ;
            find_max_start     <= 1'b0   ;
            res_table_done_reg <= 1'b0   ;
            m_state            <= m_state;
          end
        end

        ST_M_ALLOC : begin
          if(alloc_done) begin
            alloc_start        <= 1'b0         ;
            dealloc_start      <= 1'b0         ;
            find_max_start     <= 1'b1         ;
            res_table_done_reg <= 1'b0         ;
            m_state            <= ST_M_FIND_MAX;
          end
          else begin
            alloc_start        <= 1'b0   ;
            dealloc_start      <= 1'b0   ;
            find_max_start     <= 1'b0   ;
            res_table_done_reg <= 1'b0   ;
            m_state            <= m_state;
          end
        end

        ST_M_DEALLOC : begin
          if(dealloc_done) begin
            alloc_start        <= 1'b0         ;
            dealloc_start      <= 1'b0         ;
            find_max_start     <= 1'b1         ;
            res_table_done_reg <= 1'b0         ;
            m_state            <= ST_M_FIND_MAX;
          end
          else begin
            alloc_start        <= 1'b0   ; 
            dealloc_start      <= 1'b0   ;
            find_max_start     <= 1'b0   ;
            res_table_done_reg <= 1'b0   ;
            m_state            <= m_state;
          end
        end

        ST_M_FIND_MAX : begin
          if(find_max_done) begin
            alloc_start        <= 1'b0     ;
            dealloc_start      <= 1'b0     ;
            find_max_start     <= 1'b0     ;
            res_table_done_reg <= 1'b1     ;
            m_state            <= ST_M_IDLE;
          end
          else begin
            alloc_start        <= 1'b0   ; 
            dealloc_start      <= 1'b0   ;
            find_max_start     <= 1'b0   ;
            res_table_done_reg <= 1'b0   ;
            m_state            <= m_state;
          end
        end

        default : begin
          alloc_start        <= 1'b0     ;
          dealloc_start      <= 1'b0     ;
          find_max_start     <= 1'b0     ;
          res_table_done_reg <= 1'b0     ;
          m_state            <= ST_M_IDLE;
        end
      endcase
    end
  end

  // All state machines share the same resource table, 
  // so there can be onle one machine out of IDLE state at a given time.
  // alloc state machine
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      alloc_done             <= 1'b0     ;
      new_entry_is_first     <= 1'b0     ;
      new_entry_is_last      <= 1'b0     ;
      a_state                <= ST_A_IDLE;
    end
    else begin
      case(a_state)
        ST_A_IDLE : begin
          if(alloc_start) begin// Start looking for the new entry positon on
            if(table_head_pointer_reg == RES_TABLE_END_TABLE_U || !cu_initialized_reg) begin// Table is clear or cu was not initialized
              alloc_done         <= 1'b0                ;
              new_entry_is_first <= 1'b1                ;
              new_entry_is_last  <= 1'b1                ;
              a_state            <= ST_A_WRITE_NEW_ENTRY;
            end
            else begin
              alloc_done         <= 1'b0              ;
              new_entry_is_last  <= 1'b0              ;
              new_entry_is_first <= 1'b0              ;
              a_state            <= ST_A_FIND_POSITION;
            end
          end
          else begin
            alloc_done         <= 1'b0              ;
            new_entry_is_first <= new_entry_is_first;
            new_entry_is_last  <= new_entry_is_last ;
            a_state            <= a_state           ;
          end
        end

        ST_A_FIND_POSITION : begin
          if(res_table_rd_valid) begin//Look for the entry position
            if(res_table_rd_reg[RES_STRT_H:RES_STRT_L] > alloc_res_start_reg) begin// Found the entry that will be after the new one
              if(res_table_rd_reg[PREV_ENTRY_H:PREV_ENTRY_L] == RES_TABLE_HEAD_POINTER_U) begin// if new entry will be the first entry
                alloc_done         <= 1'b0                ;
                new_entry_is_first <= 1'b1                ;
                a_state            <= ST_A_WRITE_NEW_ENTRY;
              end
              else begin
                alloc_done       <= 1'b0                  ;
                a_state          <= ST_A_UPDATE_PREV_ENTRY;
              end
            end
            else if(res_table_rd_reg[NEXT_ENTRY_H:NEXT_ENTRY_L] == RES_TABLE_END_TABLE_U) begin// if new entry will be the last entry
              alloc_done        <= 1'b0                ;
              new_entry_is_last <= 1'b1                ;
              a_state           <= ST_A_WRITE_NEW_ENTRY;
            end
            else begin// Keep looking for the entry postion
              alloc_done <= 1'b0;
            end
          end
          else begin
            alloc_done         <= 1'b0              ; 
            new_entry_is_first <= new_entry_is_first;
            new_entry_is_last  <= new_entry_is_last ;
            a_state            <= a_state           ;
          end
        end

        ST_A_UPDATE_PREV_ENTRY : begin// Update the previous entry
          alloc_done           <= 1'b0                ;
          a_state              <= ST_A_WRITE_NEW_ENTRY;
        end

        ST_A_WRITE_NEW_ENTRY : begin
          if(new_entry_is_first && new_entry_is_last) begin
            alloc_done             <= 1'b1     ;
            a_state                <= ST_A_IDLE;
          end
          else if(!new_entry_is_first && new_entry_is_last) begin
            alloc_done             <= 1'b1     ;
            a_state                <= ST_A_IDLE;
          end
          else if(new_entry_is_first && !new_entry_is_last) begin
            alloc_done             <= 1'b1     ;
            a_state                <= ST_A_IDLE;
          end
          else begin
            alloc_done             <= 1'b1     ;
            a_state                <= ST_A_IDLE;
          end
        end

        default : begin
          alloc_done         <= 1'b0     ;
          new_entry_is_first <= 1'b0     ;
          new_entry_is_last  <= 1'b0     ;
          a_state            <= ST_A_IDLE;
        end
      endcase
    end
  end

  //dealloc state machine
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      dealloc_done       <= 1'b0     ;
      rem_entry_is_first <= 1'b0     ;
      rem_entry_is_last  <= 1'b0     ;
      d_state            <= ST_D_IDLE;
    end
    else begin
      case(d_state)
        ST_D_IDLE : begin
          if(dealloc_start) begin
            dealloc_done       <= 1'b0                ;
            rem_entry_is_first <= 1'b0                ;
            rem_entry_is_last  <= 1'b0                ;
            d_state            <= ST_D_READ_PREV_ENTRY;
          end
          else begin
            dealloc_done       <= 1'b0              ;
            rem_entry_is_first <= rem_entry_is_first;
            rem_entry_is_last  <= rem_entry_is_last ;
            d_state            <= d_state           ;
          end
        end

        ST_D_READ_PREV_ENTRY : begin
          if(res_table_rd_valid) begin// Read the previous entry
            if(res_table_rd_reg[PREV_ENTRY_H:PREV_ENTRY_L] == RES_TABLE_HEAD_POINTER_U && res_table_rd_reg[NEXT_ENTRY_H:NEXT_ENTRY_L] == RES_TABLE_END_TABLE_U) begin// We are removing the last remaining entry on the table
              dealloc_done <= 1'b1     ;
              d_state      <= ST_D_IDLE;
            end
            else if(res_table_rd_reg[PREV_ENTRY_H:PREV_ENTRY_L] == RES_TABLE_HEAD_POINTER_U) begin// We are removing the first entry on the table
              dealloc_done       <= 1'b0                ;
              rem_entry_is_first <= 1'b1                ;
              d_state            <= ST_D_READ_NEXT_ENTRY;
            end
            else if(res_table_rd_reg[NEXT_ENTRY_H:NEXT_ENTRY_L] == RES_TABLE_END_TABLE_U) begin// We are removing the last entry on the table
              dealloc_done      <= 1'b0                  ;
              rem_entry_is_last <= 1'b1                  ;
              d_state           <= ST_D_UPDATE_PREV_ENTRY;
            end
            else begin// We are removing an entry in the middle of the table
              dealloc_done <= 1'b0                ;
              d_state      <= ST_D_READ_NEXT_ENTRY;
            end
          end
          else begin
            dealloc_done       <= 1'b0              ;
            rem_entry_is_first <= rem_entry_is_first;
            rem_entry_is_last  <= rem_entry_is_last ;
            d_state            <= d_state           ;
          end
        end

        ST_D_READ_NEXT_ENTRY : begin
          dealloc_done <= 1'b0                  ;
          d_state      <= ST_D_UPDATE_PREV_ENTRY;
        end

        ST_D_UPDATE_PREV_ENTRY : begin// In this cycle it is reading the next entry, so we can use the addr_reg to get our the next entry addr
          if(rem_entry_is_first) begin
            dealloc_done <= 1'b0                  ;
            d_state      <= ST_D_UPDATE_NEXT_ENTRY; 
          end
          else if(rem_entry_is_last) begin
            dealloc_done <= 1'b0                  ;
            d_state      <= ST_D_UPDATE_NEXT_ENTRY; 
          end
          else begin
            dealloc_done <= 1'b0                  ;
            d_state      <= ST_D_UPDATE_NEXT_ENTRY; 
          end
        end

        ST_D_UPDATE_NEXT_ENTRY : begin// In this cycle it is writing the previous entry, so we can use the addr_reg to get our the next entry addr
          if(rem_entry_is_first) begin
            dealloc_done <= 1'b1     ;
            d_state      <= ST_D_IDLE;
          end
          else if(rem_entry_is_last) begin
            dealloc_done <= 1'b1     ;
            d_state      <= ST_D_IDLE;
          end
          else begin
            dealloc_done <= 1'b1     ;
            d_state      <= ST_D_IDLE;
          end
        end

        default : begin
          dealloc_done       <= 1'b0     ;          
          rem_entry_is_first <= 1'b0     ;            
          rem_entry_is_last  <= 1'b0     ;              
          d_state            <= ST_D_IDLE;        
        end
      endcase
    end
  end

  //find max state machine
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      find_max_done       <= 1'b0     ;
      res_table_max_size  <= 'd0      ;
      res_table_max_start <= 'd0      ;
      f_state             <= ST_F_IDLE;
    end
    else begin
      case(f_state)
        ST_F_IDLE : begin
          if(find_max_start) begin
            if(table_head_pointer_reg == RES_TABLE_END_TABLE_U) begin// In case table is clear, return 0 and finish
              find_max_done       <= 1'b1            ;
              res_table_max_size  <= NUMBER_RES_SLOTS;
              res_table_max_start <= 'd0             ;
            end
            else begin// otherwise start searching
              find_max_done      <= 1'b0           ;
              res_table_max_size <= 'd0            ;
              f_state            <= ST_F_FIRST_ITEM;
            end
          end
          else begin
            find_max_done       <= 1'b0               ;
            res_table_max_size  <= res_table_max_size ;
            res_table_max_start <= res_table_max_start;
            f_state             <= f_state            ;
          end
        end

        ST_F_FIRST_ITEM : begin// Read the first item,only read first item. If it is alst the last, skip the searching state
          if(res_table_rd_valid) begin
            if(res_table_rd_reg[NEXT_ENTRY_H:NEXT_ENTRY_L] != RES_TABLE_END_TABLE_U) begin// check if end of the table
              find_max_done       <= 1'b0                                          ;
              res_table_max_size  <= {1'b0,res_table_rd_reg[RES_STRT_H:RES_STRT_L]};
              res_table_max_start <= 'd0                                           ;
              f_state             <= ST_F_SEARCHING                                ;
            end
            else begin
              find_max_done       <= 1'b0                                          ;
              res_table_max_size  <= {1'b0,res_table_rd_reg[RES_STRT_H:RES_STRT_L]};
              res_table_max_start <= 'd0                                           ;
              f_state             <= ST_F_LAST_ITEM                                ;
            end
          end
          else begin
            find_max_done       <= 1'b0               ;
            res_table_max_size  <= res_table_max_size ;
            res_table_max_start <= res_table_max_start;
            f_state             <= f_state            ;
          end
        end

        ST_F_SEARCHING : begin
          if(res_table_rd_valid) begin
            if((res_table_rd_reg[NEXT_ENTRY_H:NEXT_ENTRY_L] != RES_TABLE_END_TABLE_U) && 
              (({1'b0,res_table_rd_reg[RES_STRT_H:RES_STRT_L]}-({1'b0,res_table_last_rd_reg[RES_STRT_H:RES_STRT_L]}+res_table_last_rd_reg[RES_SIZE_H:RES_SIZE_L]))>res_table_max_size)) begin// check if the next item is the last and if this is the max res size
              find_max_done       <= 1'b0                                       ;
              res_table_max_size  <= {1'b0,res_table_rd_reg[RES_STRT_H:RES_STRT_L]} - ({1'b0,res_table_last_rd_reg[RES_STRT_H:RES_STRT_L]} + res_table_last_rd_reg[RES_SIZE_H:RES_SIZE_L]);
              res_table_max_start <= {1'b0,res_table_last_rd_reg[RES_STRT_H:RES_STRT_L]} + res_table_last_rd_reg[RES_SIZE_H:RES_SIZE_L];  
            end
            else if((res_table_rd_reg[NEXT_ENTRY_H:NEXT_ENTRY_L] != RES_TABLE_END_TABLE_U) && 
                   (({1'b0,res_table_rd_reg[RES_STRT_H:RES_STRT_L]}-({1'b0,res_table_last_rd_reg[RES_STRT_H:RES_STRT_L]}+res_table_last_rd_reg[RES_SIZE_H:RES_SIZE_L]))<=res_table_max_size)) begin             
              find_max_done       <= 1'b0                                       ;
            end
            else if((res_table_rd_reg[NEXT_ENTRY_H:NEXT_ENTRY_L] == RES_TABLE_END_TABLE_U) && 
                   (({1'b0,res_table_rd_reg[RES_STRT_H:RES_STRT_L]}-({1'b0,res_table_last_rd_reg[RES_STRT_H:RES_STRT_L]}+res_table_last_rd_reg[RES_SIZE_H:RES_SIZE_L]))>res_table_max_size)) begin
              find_max_done       <= 1'b0          ;
              f_state             <= ST_F_LAST_ITEM;
              res_table_max_size  <= {1'b0,res_table_rd_reg[RES_STRT_H:RES_STRT_L]} - ({1'b0,res_table_last_rd_reg[RES_STRT_H:RES_STRT_L]} + res_table_last_rd_reg[RES_SIZE_H:RES_SIZE_L]);
              res_table_max_start <= {1'b0,res_table_last_rd_reg[RES_STRT_H:RES_STRT_L]} + res_table_last_rd_reg[RES_SIZE_H:RES_SIZE_L];
            end
            else begin       
              find_max_done <= 1'b0          ;
              f_state       <= ST_F_LAST_ITEM;
            end
          end
          else begin
            find_max_done       <= 1'b0               ;
            res_table_max_size  <= res_table_max_size ;
            res_table_max_start <= res_table_max_start;
            f_state             <= f_state            ;   
          end
        end

        ST_F_LAST_ITEM : begin// calculate the free space for the last item
          if((NUMBER_RES_SLOTS - ({1'b0,res_table_rd_reg[RES_STRT_H:RES_STRT_L]} + res_table_rd_reg[RES_SIZE_H:RES_SIZE_L])) > res_table_max_size) begin
            find_max_done       <= 1'b1     ;
            f_state             <= ST_F_IDLE;
            res_table_max_size  <= NUMBER_RES_SLOTS - ({1'b0,res_table_rd_reg[RES_STRT_H:RES_STRT_L]} + res_table_rd_reg[RES_SIZE_H:RES_SIZE_L]);
            res_table_max_start <= res_table_rd_reg[RES_STRT_H:RES_STRT_L] + {1'b0,res_table_rd_reg[RES_SIZE_H:RES_SIZE_L]};
          end
          else begin
            find_max_done <= 1'b1     ;
            f_state       <= ST_F_IDLE;
          end
        end

        default : begin
          find_max_done       <= 1'b0     ;
          res_table_max_size  <= 'd0      ;
          res_table_max_start <= 'd0      ;
          f_state             <= ST_F_IDLE;
        end
      endcase
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      res_table_rd_en  <= 1'b0;
      res_table_wr_en  <= 1'b0;
      res_addr_wg_slot <= 'd0 ;
      res_table_wr_reg <= 'd0 ;
    end
    
    else if(a_state == ST_A_IDLE && d_state == ST_D_IDLE && f_state == ST_F_IDLE) begin
      if(alloc_start) begin
        if(table_head_pointer_reg == RES_TABLE_END_TABLE_U || !cu_initialized_reg) begin
          res_table_rd_en <= 1'b0;
          res_table_wr_en <= 1'b0;
        end
        else begin
          res_table_rd_en  <= 1'b1                  ;
          res_table_wr_en  <= 1'b0                  ;
          res_addr_wg_slot <= table_head_pointer_reg;
        end
      end
      else if(dealloc_start) begin
        res_table_rd_en  <= 1'b1                  ;
        res_table_wr_en  <= 1'b0                  ;
        res_addr_wg_slot <= dealloc_wg_slot_id_reg;
      end
      else if(find_max_start) begin
        if(table_head_pointer_reg == RES_TABLE_END_TABLE_U) begin
          res_table_rd_en <= 1'b0;              
          res_table_wr_en <= 1'b0;
        end
        else begin
          res_table_rd_en  <= 1'b1                  ;              
          res_table_wr_en  <= 1'b0                  ;
          res_addr_wg_slot <= table_head_pointer_reg;
        end
      end
      else begin
        res_table_rd_en <= 1'b0; 
        res_table_wr_en <= 1'b0;    
      end
    end
    
    else if(a_state == ST_A_FIND_POSITION && d_state == ST_D_IDLE && f_state == ST_F_IDLE) begin
      if(res_table_rd_valid) begin//Look for the entry position
        if(res_table_rd_reg[RES_STRT_H:RES_STRT_L] > alloc_res_start_reg) begin// Found the entry that will be after the new one
          if(res_table_rd_reg[PREV_ENTRY_H:PREV_ENTRY_L] == RES_TABLE_HEAD_POINTER_U) begin// if new entry will be the first entry
            res_table_rd_en  <= 1'b0                                                                                                      ;
            res_table_wr_en  <= 1'b1                                                                                                      ;
            res_table_wr_reg <= {res_table_rd_reg[NEXT_ENTRY_H:NEXT_ENTRY_L],alloc_wg_slot_id_reg,res_table_rd_reg[RES_SIZE_H:RES_STRT_L]};
          end
          else begin
            res_table_rd_en  <= 1'b0                                                                                                      ;
            res_table_wr_en  <= 1'b1                                                                                                      ;
            res_table_wr_reg <= {res_table_rd_reg[NEXT_ENTRY_H:NEXT_ENTRY_L],alloc_wg_slot_id_reg,res_table_rd_reg[RES_SIZE_H:RES_STRT_L]};
          end
        end
        else if(res_table_rd_reg[NEXT_ENTRY_H:NEXT_ENTRY_L] == RES_TABLE_END_TABLE_U) begin// if new entry will be the last entry
          res_table_rd_en  <= 1'b0                                                            ;
          res_table_wr_en  <= 1'b1                                                            ;
          res_table_wr_reg <= {alloc_wg_slot_id_reg,res_table_rd_reg[PREV_ENTRY_H:RES_STRT_L]};  
        end
        else begin// Keep looking for the entry postion
          res_table_rd_en  <= 1'b1                                       ;
          res_table_wr_en  <= 1'b0                                       ;
          res_addr_wg_slot <= res_table_rd_reg[NEXT_ENTRY_H:NEXT_ENTRY_L];
        end
      end
      else begin
        res_table_rd_en  <= 1'b0            ; 
        res_table_wr_en  <= 1'b0            ;
        res_addr_wg_slot <= res_addr_wg_slot;
        res_table_wr_reg <= res_table_wr_reg;
      end
    end

    else if(a_state == ST_A_UPDATE_PREV_ENTRY && d_state == ST_D_IDLE && f_state == ST_F_IDLE) begin
      res_table_rd_en  <= 1'b0                                                                 ;
      res_table_wr_en  <= 1'b1                                                                 ;
      res_table_wr_reg <= {alloc_wg_slot_id_reg,res_table_last_rd_reg[PREV_ENTRY_H:RES_STRT_L]};
      res_addr_wg_slot <= res_table_rd_reg[PREV_ENTRY_H:PREV_ENTRY_L]                          ;
    end

    else if(a_state == ST_A_WRITE_NEW_ENTRY && d_state == ST_D_IDLE && f_state == ST_F_IDLE) begin
      if(new_entry_is_first && new_entry_is_last) begin
        res_table_rd_en  <= 1'b0                                                                                   ;
        res_table_wr_en  <= 1'b1                                                                                   ;
        res_addr_wg_slot <= alloc_wg_slot_id_reg                                                                   ;
        res_table_wr_reg <= {RES_TABLE_END_TABLE_U,RES_TABLE_HEAD_POINTER_U,alloc_res_size_reg,alloc_res_start_reg};
      end
      else if(!new_entry_is_first && new_entry_is_last) begin
        res_table_rd_en  <= 1'b0                                                                           ;
        res_table_wr_en  <= 1'b1                                                                           ;
        res_addr_wg_slot <= alloc_wg_slot_id_reg                                                           ;
        res_table_wr_reg <= {RES_TABLE_END_TABLE_U,res_addr_wg_slot,alloc_res_size_reg,alloc_res_start_reg};
      end
      else if(new_entry_is_first && !new_entry_is_last) begin
        res_table_rd_en  <= 1'b0                                                                              ;
        res_table_wr_en  <= 1'b1                                                                              ;
        res_addr_wg_slot <= alloc_wg_slot_id_reg                                                              ;
        res_table_wr_reg <= {res_addr_wg_slot,RES_TABLE_HEAD_POINTER_U,alloc_res_size_reg,alloc_res_start_reg};
      end
      else begin
        res_table_rd_en  <= 1'b0                                                                                                      ;
        res_table_wr_en  <= 1'b1                                                                                                      ;
        res_addr_wg_slot <= alloc_wg_slot_id_reg                                                                                      ;
        res_table_wr_reg <= {res_table_last_rd_reg[NEXT_ENTRY_H:NEXT_ENTRY_L],res_addr_wg_slot,alloc_res_size_reg,alloc_res_start_reg};
      end
    end

    else if(a_state == ST_A_IDLE && d_state == ST_D_READ_PREV_ENTRY && f_state == ST_F_IDLE) begin
      if(res_table_rd_valid) begin// Read the previous entry
        if(res_table_rd_reg[PREV_ENTRY_H:PREV_ENTRY_L] == RES_TABLE_HEAD_POINTER_U && res_table_rd_reg[NEXT_ENTRY_H:NEXT_ENTRY_L] == RES_TABLE_END_TABLE_U) begin// We are removing the last remaining entry on the table
          res_table_rd_en <= 1'b0;
          res_table_wr_en <= 1'b0;
        end
        else if(res_table_rd_reg[PREV_ENTRY_H:PREV_ENTRY_L] == RES_TABLE_HEAD_POINTER_U) begin// We are removing the first entry on the table
          res_table_rd_en <= 1'b0;
          res_table_wr_en <= 1'b0;
        end
        else if(res_table_rd_reg[NEXT_ENTRY_H:NEXT_ENTRY_L] == RES_TABLE_END_TABLE_U) begin// We are removing the last entry on the table
          res_table_rd_en  <= 1'b1                                       ;
          res_table_wr_en  <= 1'b0                                       ;
          res_addr_wg_slot <= res_table_rd_reg[PREV_ENTRY_H:PREV_ENTRY_L];
        end
        else begin// We are removing an entry in the middle of the table
          res_table_rd_en  <= 1'b1                                       ;
          res_table_wr_en  <= 1'b0                                       ;
          res_addr_wg_slot <= res_table_rd_reg[PREV_ENTRY_H:PREV_ENTRY_L];
        end
      end
      else begin
          res_table_rd_en  <= 1'b0            ; 
          res_table_wr_en  <= 1'b0            ;
          res_addr_wg_slot <= res_addr_wg_slot;
      end
    end

    else if(a_state == ST_A_IDLE && d_state == ST_D_READ_NEXT_ENTRY && f_state == ST_F_IDLE) begin
      res_table_rd_en  <= 1'b1                                       ;
      res_table_wr_en  <= 1'b0                                       ;
      res_addr_wg_slot <= res_table_rd_reg[NEXT_ENTRY_H:NEXT_ENTRY_L];
    end

    else if(a_state == ST_A_IDLE && d_state == ST_D_UPDATE_PREV_ENTRY && f_state == ST_F_IDLE) begin
      if(rem_entry_is_first) begin
        res_table_rd_en <= 1'b0;
        res_table_wr_en <= 1'b0;
      end
      else if(rem_entry_is_last) begin
        res_table_rd_en <= 1'b0;
        res_table_wr_en <= 1'b0;
      end
      else begin
        res_table_rd_en  <= 1'b0                                                        ;
        res_table_wr_en  <= 1'b1                                                        ;
        res_addr_wg_slot <= res_table_last_rd_reg[PREV_ENTRY_H:PREV_ENTRY_L]            ;
        res_table_wr_reg <= {res_addr_wg_slot,res_table_rd_reg[PREV_ENTRY_H:RES_STRT_L]};
      end
    end

    else if(a_state == ST_A_IDLE && d_state == ST_D_UPDATE_NEXT_ENTRY && f_state == ST_F_IDLE) begin
      if(rem_entry_is_first) begin
        res_table_rd_en  <= 1'b0                                                                                                          ;
        res_table_wr_en  <= 1'b1                                                                                                          ;
        res_table_wr_reg <= {res_table_rd_reg[NEXT_ENTRY_H:NEXT_ENTRY_L],RES_TABLE_HEAD_POINTER_U,res_table_rd_reg[RES_SIZE_H:RES_STRT_L]};
      end
      else if(rem_entry_is_last) begin
        res_table_rd_en  <= 1'b0                                                             ;
        res_table_wr_en  <= 1'b1                                                             ;
        res_table_wr_reg <= {RES_TABLE_END_TABLE_U,res_table_rd_reg[PREV_ENTRY_H:RES_STRT_L]};
      end
      else begin
        res_table_rd_en  <= 1'b0                                                                                                  ;
        res_table_wr_en  <= 1'b1                                                                                                  ;
        res_addr_wg_slot <= res_table_wr_reg[NEXT_ENTRY_H:NEXT_ENTRY_L]                                                           ;
        res_table_wr_reg <= {res_table_rd_reg[NEXT_ENTRY_H:NEXT_ENTRY_L],res_addr_wg_slot,res_table_rd_reg[RES_SIZE_H:RES_STRT_L]};
      end
    end

    else if(a_state == ST_A_IDLE && d_state == ST_D_IDLE && f_state == ST_F_FIRST_ITEM) begin
      if(res_table_rd_valid) begin
        if(res_table_rd_reg[NEXT_ENTRY_H:NEXT_ENTRY_L] != RES_TABLE_END_TABLE_U) begin// check if end of the table
          res_table_rd_en  <= 1'b1                                       ;              
          res_table_wr_en  <= 1'b0                                       ;
          res_addr_wg_slot <= res_table_rd_reg[NEXT_ENTRY_H:NEXT_ENTRY_L];
        end
        else begin
          res_table_rd_en <= 1'b0;              
          res_table_wr_en <= 1'b0;
        end
      end
      else begin
        res_table_rd_en  <= 1'b0            ; 
        res_table_wr_en  <= 1'b0            ;
        res_addr_wg_slot <= res_addr_wg_slot;
      end
    end

    else if(a_state == ST_A_IDLE && d_state == ST_D_IDLE && f_state == ST_F_SEARCHING) begin
      if(res_table_rd_valid) begin
        if(res_table_rd_reg[NEXT_ENTRY_H:NEXT_ENTRY_L] != RES_TABLE_END_TABLE_U) begin// check if the next item is the last and if this is the max res size
          res_table_rd_en  <= 1'b1                                       ;              
          res_table_wr_en  <= 1'b0                                       ;
          res_addr_wg_slot <= res_table_rd_reg[NEXT_ENTRY_H:NEXT_ENTRY_L];
        end
        else begin
          res_table_rd_en <= 1'b0;              
          res_table_wr_en <= 1'b0;
        end
      end
      else begin
        res_table_rd_en  <= 1'b0            ; 
        res_table_wr_en  <= 1'b0            ;  
        res_addr_wg_slot <= res_addr_wg_slot;
      end
    end

    else if(a_state == ST_A_IDLE && d_state == ST_D_IDLE && f_state == ST_F_LAST_ITEM) begin
      res_table_rd_en <= 1'b0;              
      res_table_wr_en <= 1'b0;
    end

    else begin
      res_table_rd_en  <= 1'b0;              
      res_table_wr_en  <= 1'b0;            
      res_addr_wg_slot <= 'd0 ;        
      res_table_wr_reg <= 'd0 ;        
    end
  end

  //datapath of the resource table
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      cu_initialized         <= 'd0;
      table_head_pointer     <= 'd0;
      cu_initialized_reg     <= 'd0;
      table_head_pointer_reg <= 'd0;
    end
    else if(alloc_res_en_reg || dealloc_res_en_reg) begin// Read the head pointer at the start
      cu_initialized_reg     <= cu_initialized[res_addr_cu_id]    ;
      table_head_pointer_reg <= table_head_pointer[(res_addr_cu_id+1)*WG_SLOT_ID_WIDTH_TABLE-1-:WG_SLOT_ID_WIDTH_TABLE];
    end
    else if(a_state == ST_A_WRITE_NEW_ENTRY && d_state == ST_D_IDLE && f_state == ST_F_IDLE) begin
      if(new_entry_is_first) begin
        table_head_pointer_reg <= alloc_wg_slot_id_reg;
      end
      else begin
        table_head_pointer_reg <= table_head_pointer_reg;
      end
    end
    else if(a_state == ST_A_IDLE && d_state == ST_D_READ_PREV_ENTRY && f_state == ST_F_IDLE) begin
      if(res_table_rd_valid) begin
        if(res_table_rd_reg[PREV_ENTRY_H:PREV_ENTRY_L] == RES_TABLE_HEAD_POINTER_U && res_table_rd_reg[NEXT_ENTRY_H:NEXT_ENTRY_L] == RES_TABLE_END_TABLE_U) begin
          table_head_pointer_reg <= RES_TABLE_END_TABLE_U;
        end
        else begin
          table_head_pointer_reg <= table_head_pointer_reg;
        end
      end
      else begin
        table_head_pointer_reg <= table_head_pointer_reg;
      end
    end
    else if(a_state == ST_A_IDLE && d_state == ST_D_UPDATE_NEXT_ENTRY && f_state == ST_F_IDLE) begin
      if(rem_entry_is_first) begin
        table_head_pointer_reg <= res_addr_wg_slot;
      end
      else begin
        table_head_pointer_reg <= table_head_pointer_reg;
      end
    end
    else if(alloc_done || dealloc_done) begin// Write the head pointer at the end
      cu_initialized[res_addr_cu_id]                                                          <= 1'b1                  ;
      table_head_pointer[(res_addr_cu_id+1)*WG_SLOT_ID_WIDTH_TABLE-1-:WG_SLOT_ID_WIDTH_TABLE] <= table_head_pointer_reg;
    end
    else begin
      cu_initialized         <= cu_initialized        ; 
      table_head_pointer     <= table_head_pointer    ;
      cu_initialized_reg     <= cu_initialized_reg    ;
      table_head_pointer_reg <= table_head_pointer_reg;
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      res_table_rd_reg      <= 'd0;
      res_table_last_rd_reg <= 'd0;
      resource_table_ram    <= 'd0;
    end
    else if(res_table_rd_en) begin
      res_table_rd_reg      <= resource_table_ram[(`NUMBER_WF_SLOTS*res_addr_cu_id+res_addr_wg_slot+1)*TABLE_ENTRY_WIDTH-1-:TABLE_ENTRY_WIDTH];
      res_table_last_rd_reg <= res_table_rd_reg                                                                                               ;
    end
    else if(res_table_wr_en) begin
      resource_table_ram[(`NUMBER_WF_SLOTS*res_addr_cu_id+res_addr_wg_slot+1)*TABLE_ENTRY_WIDTH-1-:TABLE_ENTRY_WIDTH] <= res_table_wr_reg;
    end
    else begin
      res_table_rd_reg      <= res_table_rd_reg     ;  
      res_table_last_rd_reg <= res_table_last_rd_reg;
      resource_table_ram    <= resource_table_ram   ;
    end
  end

  assign cam_biggest_space_size_o = res_table_max_size ;
  assign cam_biggest_space_addr_o = res_table_max_start;

endmodule
