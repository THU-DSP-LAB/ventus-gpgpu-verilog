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
// Author: Tang, Yao
// Description:

`timescale 1ns/1ns
`include "define.v"

module cu_handler (
  input                                 clk                          ,
  input                                 rst_n                        ,

  input                                 wg_alloc_en_i                ,
  input   [`WG_ID_WIDTH-1:0]            wg_alloc_wg_id_i             ,
  input   [`WF_COUNT_WIDTH_PER_WG-1:0]  wg_alloc_wf_count_i          ,
  input                                 ready_for_dispatch2cu_i      ,
  input                                 cu2dispatch_wf_done_i        ,
  input   [`TAG_WIDTH-1:0]              cu2dispatch_wf_tag_done_i    ,
  input                                 wg_done_ack_i                ,

  output                                dispatch2cu_wf_dispatch_o    ,
  output  [`TAG_WIDTH-1:0]              dispatch2cu_wf_tag_dispatch_o,
  output                                wg_done_valid_o              ,
  output  [`WG_ID_WIDTH-1:0]            wg_done_wg_id_o              ,
  output                                invalid_due_to_not_ready_o      
  );

  localparam  TAG_WF_COUNT_L       = 0                                               ;
  localparam  TAG_WF_COUNT_H       = TAG_WF_COUNT_L + `WF_COUNT_WIDTH_PER_WG - 1     ;
  localparam  TAG_WG_SLOT_ID_L     = TAG_WF_COUNT_H + 1                              ;
  localparam  TAG_WG_SLOT_ID_H     = TAG_WG_SLOT_ID_L + `WG_SLOT_ID_WIDTH - 1        ;

  localparam  INFO_RAM_WORD_WIDTH  = `WG_ID_WIDTH + `WF_COUNT_WIDTH_PER_WG           ;
  localparam  INFO_RAM_WG_COUNT_L  = 0                                               ;
  localparam  INFO_RAM_WG_COUNT_H  = INFO_RAM_WG_COUNT_L + `WF_COUNT_WIDTH_PER_WG - 1;
  localparam  INFO_RAM_WG_ID_L     = INFO_RAM_WG_COUNT_H + 1                         ;
  localparam  INFO_RAM_WG_ID_H     = INFO_RAM_WG_ID_L + `WG_ID_WIDTH - 1             ;

  localparam  ST_ALLOC_IDLE        = 2'b01                                           ;
  localparam  ST_ALLOCATING        = 2'b10                                           ;

  localparam  ST_DEALLOC_IDLE      = 3'b001                                          ;
  localparam  ST_DEALLOC_READ_RAM  = 3'b010                                          ;
  localparam  ST_DEALLOC_PROPAGATE = 3'b100                                          ;

  // On alloc:
  // Get first wf free slot, slot of first wf is slot of cu
  // zero counter, store wf_id and wf_count
  // output tag of each cu
  reg   [`WG_SLOT_ID_WIDTH-1:0]                       next_free_slot                 ;
  wire  [`WG_SLOT_ID_WIDTH-1:0]                       next_free_slot_comb            ;
  reg   [`NUMBER_WF_SLOTS-1:0]                        used_slot_bitmap               ;
  reg   [`NUMBER_WF_SLOTS-1:0]                        pending_wg_bitmap              ;
  reg   [`NUMBER_WF_SLOTS*`WF_COUNT_WIDTH_PER_WG-1:0] pending_wf_count               ;
  reg   [`WF_COUNT_WIDTH_PER_WG-1:0]                  curr_alloc_wf_count            ;
  reg   [`WG_SLOT_ID_WIDTH-1:0]                       curr_alloc_wf_slot             ;
  reg                                                 dispatch2cu_wf_dispatch_reg    ;
  reg   [`TAG_WIDTH-1:0]                              dispatch2cu_wf_tag_dispatch_reg;

  // On dealloc:
  // Look up counter
  // Check if wg finished
  // Notify gpu_interface
  reg                                   next_served_dealloc_valid     ;
  wire                                  next_served_dealloc_valid_comb;
  reg   [`WG_SLOT_ID_WIDTH-1:0]         next_served_dealloc           ;
  wire  [`WG_SLOT_ID_WIDTH-1:0]         next_served_dealloc_comb      ;

  reg   [`WG_SLOT_ID_WIDTH-1:0]         curr_dealloc_wg_slot          ;
  //reg   [`WF_COUNT_WIDTH_PER_WG-1:0]    curr_dealloc_wf_counter       ;
  //reg   [`WG_ID_WIDTH-1:0]              curr_dealloc_wf_id            ;
  reg                                   info_ram_rd_en                ;
  reg                                   info_ram_rd_valid             ;
  wire  [INFO_RAM_WORD_WIDTH-1:0]       info_ram_rd_reg               ;
  reg                                   info_ram_wr_en                ;
  reg   [`WG_SLOT_ID_WIDTH-1:0]         info_ram_wr_addr              ;
  reg   [INFO_RAM_WORD_WIDTH-1:0]       info_ram_wr_reg               ;
  reg                                   wg_done_valid_reg             ;
  reg   [`WG_ID_WIDTH-1:0]              wg_done_wg_id_reg             ;
  reg   [`WF_COUNT_WIDTH_PER_WG-1:0]    curr_wf_count                 ;
  reg                                   invalid_due_to_not_ready_reg  ;
  wire  [`WG_SLOT_ID_WIDTH-1:0]         cu2dispatch_wf_tag_done_slot  ;

  reg   [1:0]                           alloc_st                      ;
  reg   [2:0]                           dealloc_st                    ;

  wire                                  found_free_slot_valid2        ;
  wire  [`WG_SLOT_ID_WIDTH-1:0]         found_free_slot_id2           ;
  wire                                  found_free_slot_valid         ;
  wire  [`WG_SLOT_ID_WIDTH-1:0]         found_free_slot_id            ;
  wire  [`NUMBER_WF_SLOTS-1:0]          grant                         ;
  wire  [`NUMBER_WF_SLOTS-1:0]          grant2                        ;
  reg                                   next_free_slot_valid          ;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      next_free_slot            <= 'd0;
      next_free_slot_valid      <= 'd0;
      next_served_dealloc_valid <= 'd0;
      next_served_dealloc       <= 'd0;
      info_ram_rd_valid         <= 'd0;
    end
    else begin
      next_free_slot            <= next_free_slot_comb           ;
      next_free_slot_valid      <= found_free_slot_valid2        ;
      next_served_dealloc_valid <= next_served_dealloc_valid_comb;
      next_served_dealloc       <= next_served_dealloc_comb      ;
      info_ram_rd_valid         <= info_ram_rd_en                ;
    end
  end

  ram #(
    .WORD_SIZE(INFO_RAM_WORD_WIDTH),
    .ADDR_SIZE(`WG_SLOT_ID_WIDTH  ),
    .NUM_WORDS(`NUMBER_WF_SLOTS   )
  )
  info_ram (
    .clk      (clk                 ), 
    .rst_n    (rst_n               ),     
             
    .rd_addr_i(curr_dealloc_wg_slot),
    .wr_addr_i(info_ram_wr_addr    ), 
    .wr_word_i(info_ram_wr_reg     ), 
    .wr_en_i  (info_ram_wr_en      ), 
    .rd_en_i  (info_ram_rd_en      ),   
             
    .rd_word_o(info_ram_rd_reg     )
    );

  //alloc state machine
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      alloc_st <= ST_ALLOC_IDLE;
    end
    else begin
      case(alloc_st)
        ST_ALLOC_IDLE : alloc_st <= (wg_alloc_en_i && next_free_slot_valid) ? ST_ALLOCATING : ST_ALLOC_IDLE;
        ST_ALLOCATING : alloc_st <= (curr_alloc_wf_count != 0) ? ST_ALLOCATING : ST_ALLOC_IDLE             ;
        default       : alloc_st <= ST_ALLOC_IDLE                                                          ;
      endcase
    end
  end

  //dealloc state machine
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      dealloc_st <= ST_DEALLOC_IDLE;
    end
    else begin
      case(dealloc_st)
        ST_DEALLOC_IDLE      : dealloc_st <= next_served_dealloc_valid ? ST_DEALLOC_READ_RAM : ST_DEALLOC_IDLE                                        ;
        ST_DEALLOC_READ_RAM  : dealloc_st <= info_ram_rd_valid ? ((curr_wf_count == 0) ? ST_DEALLOC_PROPAGATE : ST_DEALLOC_IDLE) : ST_DEALLOC_READ_RAM;
        ST_DEALLOC_PROPAGATE : dealloc_st <= wg_done_ack_i ? ST_DEALLOC_IDLE : ST_DEALLOC_PROPAGATE                                                   ;
        default              : dealloc_st <= ST_DEALLOC_IDLE                                                                                          ;  
      endcase
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      info_ram_wr_en                  <= 'd0;
      info_ram_wr_addr                <= 'd0;
      info_ram_wr_reg                 <= 'd0;
      info_ram_rd_en                  <= 'd0;
      curr_alloc_wf_count             <= 'd0;
      curr_alloc_wf_slot              <= 'd0;
      curr_dealloc_wg_slot            <= 'd0;
      curr_wf_count                   <= 'd0;
      used_slot_bitmap                <= 'd0;
      dispatch2cu_wf_dispatch_reg     <= 'd0;
      dispatch2cu_wf_tag_dispatch_reg <= 'd0;
      invalid_due_to_not_ready_reg    <= 'd0;
      wg_done_valid_reg               <= 'd0;
      wg_done_wg_id_reg               <= 'd0;
    end

    else if(alloc_st == ST_ALLOC_IDLE && dealloc_st == ST_DEALLOC_IDLE) begin
      if(wg_alloc_en_i && next_free_slot_valid) begin
        info_ram_wr_en                                                                        <= 1'b1                                  ;
        info_ram_rd_en                                                                        <= 1'b0                                  ;
        dispatch2cu_wf_dispatch_reg                                                           <= 1'b0                                  ; 
        invalid_due_to_not_ready_reg                                                          <= 1'b0                                  ;   
        wg_done_valid_reg                                                                     <= 1'b0                                  ;
        info_ram_wr_addr                                                                      <= next_free_slot                        ;
        info_ram_wr_reg                                                                       <= {wg_alloc_wg_id_i,wg_alloc_wf_count_i};
        curr_alloc_wf_count                                                                   <= wg_alloc_wf_count_i                   ;
        curr_alloc_wf_slot                                                                    <= next_free_slot                        ;
        used_slot_bitmap[next_free_slot]                                                      <= 1'b1                                  ;
        //pending_wf_count[(next_free_slot+1)*`WF_COUNT_WIDTH_PER_WG-1-:`WF_COUNT_WIDTH_PER_WG] <= wg_alloc_wf_count_i                   ;
      end
      else if(next_served_dealloc_valid) begin
        info_ram_wr_en                         <= 1'b0                                                                                      ;
        info_ram_rd_en                         <= 1'b1                                                                                      ;
        dispatch2cu_wf_dispatch_reg            <= 1'b0                                                                                      ; 
        invalid_due_to_not_ready_reg           <= 1'b0                                                                                      ;   
        wg_done_valid_reg                      <= 1'b0                                                                                      ;
        curr_dealloc_wg_slot                   <= next_served_dealloc                                                                       ;
        curr_wf_count                          <= pending_wf_count[(next_served_dealloc+1)*`WF_COUNT_WIDTH_PER_WG-1-:`WF_COUNT_WIDTH_PER_WG];
        //pending_wg_bitmap[next_served_dealloc] <= 1'b0                                                                                      ;
      end
      else begin
        info_ram_wr_en               <= 1'b0;
        info_ram_rd_en               <= 1'b0;
        dispatch2cu_wf_dispatch_reg  <= 1'b0; 
        invalid_due_to_not_ready_reg <= 1'b0;   
        wg_done_valid_reg            <= 1'b0;
      end
    end

    else if(alloc_st == ST_ALLOCATING && dealloc_st == ST_DEALLOC_IDLE) begin
      if(curr_alloc_wf_count != 0) begin
        if(ready_for_dispatch2cu_i) begin// Send the counter just to make sure the cu does not have two wf with the same tag
          info_ram_wr_en                  <= 1'b0                                        ;
          info_ram_rd_en                  <= 1'b0                                        ;
          dispatch2cu_wf_dispatch_reg     <= 1'b1                                        ; 
          invalid_due_to_not_ready_reg    <= 1'b0                                        ;   
          wg_done_valid_reg               <= 1'b0                                        ;
          dispatch2cu_wf_tag_dispatch_reg <= {curr_alloc_wf_slot,(curr_alloc_wf_count-1)};
          curr_alloc_wf_count             <= curr_alloc_wf_count - 1                     ;
        end
        else begin
          info_ram_wr_en               <= 1'b0;
          info_ram_rd_en               <= 1'b0;
          dispatch2cu_wf_dispatch_reg  <= 1'b0; 
          invalid_due_to_not_ready_reg <= 1'b1;   
          wg_done_valid_reg            <= 1'b0;
        end
      end
      else begin
        info_ram_wr_en               <= 1'b0;
        info_ram_rd_en               <= 1'b0;
        dispatch2cu_wf_dispatch_reg  <= 1'b0; 
        invalid_due_to_not_ready_reg <= 1'b0;   
        wg_done_valid_reg            <= 1'b0;
      end
    end

    else if(alloc_st == ST_ALLOC_IDLE && dealloc_st == ST_DEALLOC_READ_RAM) begin
      if(info_ram_rd_valid) begin
        if(curr_wf_count == 0) begin
          info_ram_wr_en                         <= 1'b0                                              ;
          info_ram_rd_en                         <= 1'b0                                              ;
          dispatch2cu_wf_dispatch_reg            <= 1'b0                                              ; 
          invalid_due_to_not_ready_reg           <= 1'b0                                              ;   
          wg_done_valid_reg                      <= 1'b1                                              ;
          wg_done_wg_id_reg                      <= info_ram_rd_reg[INFO_RAM_WG_ID_H:INFO_RAM_WG_ID_L];
          used_slot_bitmap[curr_dealloc_wg_slot] <= 1'b0                                              ;
        end
        else begin
          info_ram_wr_en               <= 1'b0;
          info_ram_rd_en               <= 1'b0;
          dispatch2cu_wf_dispatch_reg  <= 1'b0; 
          invalid_due_to_not_ready_reg <= 1'b0;   
          wg_done_valid_reg            <= 1'b0;
        end
      end
      else begin
        info_ram_wr_en               <= 1'b0;
        info_ram_rd_en               <= 1'b0;
        dispatch2cu_wf_dispatch_reg  <= 1'b0; 
        invalid_due_to_not_ready_reg <= 1'b0;   
        wg_done_valid_reg            <= 1'b0;
      end
    end

    else if(alloc_st == ST_ALLOC_IDLE && dealloc_st == ST_DEALLOC_PROPAGATE) begin
      if(wg_done_ack_i) begin
        info_ram_wr_en               <= 1'b0;
        info_ram_rd_en               <= 1'b0;
        dispatch2cu_wf_dispatch_reg  <= 1'b0; 
        invalid_due_to_not_ready_reg <= 1'b0;   
        wg_done_valid_reg            <= 1'b0;
      end
      else begin
        info_ram_wr_en               <= 1'b0;
        info_ram_rd_en               <= 1'b0;
        dispatch2cu_wf_dispatch_reg  <= 1'b0; 
        invalid_due_to_not_ready_reg <= 1'b0;   
        wg_done_valid_reg            <= 1'b1;
      end
    end

    else begin
      info_ram_wr_en               <= 1'b0;
      info_ram_rd_en               <= 1'b0;
      dispatch2cu_wf_dispatch_reg  <= 1'b0; 
      invalid_due_to_not_ready_reg <= 1'b0;   
      wg_done_valid_reg            <= 1'b0;
    end
  end

  assign cu2dispatch_wf_tag_done_slot = cu2dispatch_wf_tag_done_i[TAG_WG_SLOT_ID_H:TAG_WG_SLOT_ID_L];
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      pending_wg_bitmap <= 'd0;
      pending_wf_count  <= 'd0;
    end
    else if(cu2dispatch_wf_done_i) begin
      pending_wg_bitmap[cu2dispatch_wf_tag_done_slot]                                                     <= 1'b1                                                                                                   ;
      pending_wf_count[(cu2dispatch_wf_tag_done_slot+1)*`WF_COUNT_WIDTH_PER_WG-1-:`WF_COUNT_WIDTH_PER_WG] <= pending_wf_count[(cu2dispatch_wf_tag_done_slot+1)*`WF_COUNT_WIDTH_PER_WG-1-:`WF_COUNT_WIDTH_PER_WG] - 1;
    end
    else if(alloc_st == ST_ALLOC_IDLE && dealloc_st == ST_DEALLOC_IDLE) begin
      if(wg_alloc_en_i && next_free_slot_valid) begin
        pending_wf_count[(next_free_slot+1)*`WF_COUNT_WIDTH_PER_WG-1-:`WF_COUNT_WIDTH_PER_WG] <= wg_alloc_wf_count_i;
      end
      else if(next_served_dealloc_valid) begin
        pending_wg_bitmap[next_served_dealloc] <= 1'b0;
      end
      else begin
        pending_wg_bitmap <= pending_wg_bitmap;
        pending_wf_count  <= pending_wf_count ;
      end
    end 
    else begin
      pending_wg_bitmap <= pending_wg_bitmap;
      pending_wf_count  <= pending_wf_count ;
    end
  end

  assign dispatch2cu_wf_dispatch_o     = dispatch2cu_wf_dispatch_reg    ;
  assign dispatch2cu_wf_tag_dispatch_o = dispatch2cu_wf_tag_dispatch_reg;

  assign wg_done_valid_o = wg_done_valid_reg;
  assign wg_done_wg_id_o = wg_done_wg_id_reg;

  //finds the next served deallocation
  assign found_free_slot_valid          = |pending_wg_bitmap   ;
  assign next_served_dealloc_valid_comb = found_free_slot_valid;
  assign next_served_dealloc_comb       = found_free_slot_id   ;

  fixed_pri_arb #(
    .ARB_WIDTH(`NUMBER_WF_SLOTS)
  )
  U_fixed_pri_arb (
    .req  (pending_wg_bitmap),
    .grant(grant            )
    );

  one2bin #(
    .ONE_WIDTH(`NUMBER_WF_SLOTS ),
    .BIN_WIDTH(`WG_SLOT_ID_WIDTH)
  )
  U_one2bin (
    .oh (grant             ),
    .bin(found_free_slot_id)
    );

  //finds next free slot
  assign found_free_slot_valid2 = |(~used_slot_bitmap);
  assign next_free_slot_comb    = found_free_slot_id2 ;

  fixed_pri_arb #(
    .ARB_WIDTH(`NUMBER_WF_SLOTS)
  )
  U_fixed_pri_arb2 (
    .req  (~used_slot_bitmap),
    .grant(grant2           )
    );

  one2bin #(
    .ONE_WIDTH(`NUMBER_WF_SLOTS ),
    .BIN_WIDTH(`WG_SLOT_ID_WIDTH)
  )
  U_one2bin2 (
    .oh (grant2             ),
    .bin(found_free_slot_id2)
    );

  assign invalid_due_to_not_ready_o = invalid_due_to_not_ready_reg;

endmodule

  

    







          

