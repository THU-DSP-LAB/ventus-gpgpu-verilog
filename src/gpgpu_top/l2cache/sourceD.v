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
// Description:                     bankstore   sourceA   L1 cache                  

`include "define.v"

module sourceD (
  input                                  clk             ,
  input                                  rst_n           ,

  input                                  req_from_mem_i  ,
  input                                  req_hit_i       ,
  input   [`WAY_BITS-1:0]                req_way_i       ,
  input                                  req_dirty_i     ,
  input                                  req_flush_i     ,
  input                                  req_last_flush_i,
  input   [`SET_BITS-1:0]                req_set_i       ,
  //input   [`L2C_BITS-1:0]                req_l2cidx_i    ,
  input   [`OP_BITS-1:0]                 req_opcode_i    ,
  input   [`SIZE_BITS-1:0]               req_size_i      ,
  input   [`SOURCE_BITS-1:0]             req_source_i    ,
  input   [`TAG_BITS-1:0]                req_tag_i       ,
  input   [`OFFSET_BITS-1:0]             req_offset_i    ,
  input   [`PUT_BITS-1:0]                req_put_i       ,
  input   [`DATA_BITS-1:0]               req_data_i      ,
  input   [`MASK_BITS-1:0]               req_mask_i      ,
  input   [2:0]                          req_param_i     ,
  input                                  req_valid_i     ,
  output                                 req_ready_o     ,

  output  [`ADDRESS_BITS-1:0]            d_address_o     ,
  output  [`OP_BITS-1:0]                 d_opcode_o      ,
  output  [`SIZE_BITS-1:0]               d_size_o        ,
  output  [`SOURCE_BITS-1:0]             d_source_o      ,
  output  [`DATA_BITS-1:0]               d_data_o        ,
  output  [2:0]                          d_param_o       ,
  output                                 d_valid_o       ,
  input                                  d_ready_i       ,

  output  [`PUT_BITS-1:0]                pb_pop_index_o  ,
  output                                 pb_pop_valid_o  ,
  //input                                  pb_pop_ready_i  ,

  input   [`DATA_BITS-1:0]               pb_beat_data_i  ,
  input   [`MASK_BITS-1:0]               pb_beat_mask_i  ,

  output  [`WAY_BITS-1:0]                bs_radr_way_o   ,
  output  [`SET_BITS-1:0]                bs_radr_set_o   ,
  output  [`INNER_MASK_BITS-1:0]         bs_radr_mask_o  ,
  output                                 bs_radr_valid_o ,
  input                                  bs_radr_ready_i ,

  input   [`L2CACHE_BEATBYTES*8-1:0]     bs_rdat_data_i  ,

  output  [`WAY_BITS-1:0]                bs_wadr_way_o   ,
  output  [`SET_BITS-1:0]                bs_wadr_set_o   ,
  output  [`INNER_MASK_BITS-1:0]         bs_wadr_mask_o  ,
  output                                 bs_wadr_valid_o ,
  input                                  bs_wadr_ready_i ,

  output  [`L2CACHE_BEATBYTES*8-1:0]     bs_wdat_data_o  ,

  output  [`SET_BITS-1:0]                a_set_o         ,
  //output  [`L2C_BITS-1:0]                a_l2cidx_o      ,
  output  [`OP_BITS-1:0]                 a_opcode_o      ,
  output  [`SIZE_BITS-1:0]               a_size_o        ,
  output  [`SOURCE_BITS-1:0]             a_source_o      ,
  output  [`TAG_BITS-1:0]                a_tag_o         ,
  output  [`OFFSET_BITS-1:0]             a_offset_o      ,
  output  [`PUT_BITS-1:0]                a_put_o         ,
  output  [`DATA_BITS-1:0]               a_data_o        ,
  output  [`MASK_BITS-1:0]               a_mask_o        ,
  output  [2:0]                          a_param_o       ,
  output                                 a_valid_o       ,
  input                                  a_ready_i       ,

  output                                 mshr_wait_o     ,
  output                                 finish_issue_o     
  );
  parameter STAGE_1 = 3'b000;
  parameter STAGE_2 = 3'b001;
  parameter STAGE_3 = 3'b010;
  parameter STAGE_4 = 3'b011;
  parameter STAGE_5 = 3'b100;
  parameter STAGE_6 = 3'b101;
  parameter STAGE_7 = 3'b110;
  parameter STAGE_8 = 3'b111;

  reg     [2:0]                          current_state    ;
  reg     [2:0]                          next_state       ;
  reg                                    busy             ;
  reg                                    tobedone         ;//all resources not ready
  reg                                    mshr_wait_reg    ;
  wire                                   about_to_not_busy;

  reg     [`DATA_BITS-1:0]               pb_beat_reg_data;
  reg     [`MASK_BITS-1:0]               pb_beat_reg_mask;

  reg                                    s1_req_reg_from_mem  ;
  reg                                    s1_req_reg_hit       ;
  reg     [`WAY_BITS-1:0]                s1_req_reg_way       ;
  reg                                    s1_req_reg_dirty     ;
  reg                                    s1_req_reg_flush     ;
  reg                                    s1_req_reg_last_flush;
  reg     [`SET_BITS-1:0]                s1_req_reg_set       ;
  //reg     [`L2C_BITS-1:0]                s1_req_reg_l2cidx    ;
  reg     [`OP_BITS-1:0]                 s1_req_reg_opcode    ; 
  reg     [`SIZE_BITS-1:0]               s1_req_reg_size      ;
  reg     [`SOURCE_BITS-1:0]             s1_req_reg_source    ;
  reg     [`TAG_BITS-1:0]                s1_req_reg_tag       ;
  reg     [`OFFSET_BITS-1:0]             s1_req_reg_offset    ;
  reg     [`PUT_BITS-1:0]                s1_req_reg_put       ;
  reg     [`DATA_BITS-1:0]               s1_req_reg_data      ;
  reg     [`MASK_BITS-1:0]               s1_req_reg_mask      ;
  reg     [2:0]                          s1_req_reg_param     ;

  wire    [`DATA_BITS-1:0]               pb_beat_data         ;
  wire    [`MASK_BITS-1:0]               pb_beat_mask         ;
  wire                                   s1_req_from_mem      ;
  wire                                   s1_req_hit           ;
  wire    [`WAY_BITS-1:0]                s1_req_way           ;
  wire                                   s1_req_dirty         ;
  wire                                   s1_req_flush         ;
  wire                                   s1_req_last_flush    ;
  wire    [`SET_BITS-1:0]                s1_req_set           ;
  //wire    [`L2C_BITS-1:0]                s1_req_l2cidx        ;
  wire    [`OP_BITS-1:0]                 s1_req_opcode        ;
  wire    [`SIZE_BITS-1:0]               s1_req_size          ;
  wire    [`SOURCE_BITS-1:0]             s1_req_source        ;
  wire    [`TAG_BITS-1:0]                s1_req_tag           ;
  wire    [`OFFSET_BITS-1:0]             s1_req_offset        ;
  wire    [`PUT_BITS-1:0]                s1_req_put           ;
  wire    [`DATA_BITS-1:0]               s1_req_data          ;
  wire    [`MASK_BITS-1:0]               s1_req_mask          ;
  wire    [2:0]                          s1_req_param         ;

  reg                                    s_final_req_from_mem  ; 
  reg                                    s_final_req_hit       ;
  reg     [`WAY_BITS-1:0]                s_final_req_way       ;
  reg                                    s_final_req_dirty     ;
  reg                                    s_final_req_flush     ;
  reg                                    s_final_req_last_flush;
  reg     [`SET_BITS-1:0]                s_final_req_set       ;
  //reg     [`L2C_BITS-1:0]                s_final_req_l2cidx    ;
  reg     [`OP_BITS-1:0]                 s_final_req_opcode    ;
  reg     [`SIZE_BITS-1:0]               s_final_req_size      ;
  reg     [`SOURCE_BITS-1:0]             s_final_req_source    ;
  reg     [`TAG_BITS-1:0]                s_final_req_tag       ;
  reg     [`OFFSET_BITS-1:0]             s_final_req_offset    ;
  reg     [`PUT_BITS-1:0]                s_final_req_put       ;
  reg     [`DATA_BITS-1:0]               s_final_req_data      ;
  reg     [`MASK_BITS-1:0]               s_final_req_mask      ;
  reg     [2:0]                          s_final_req_param     ;

  wire                                   s1_need_w             ;
  wire                                   s1_need_r             ;
  wire                                   s1_valid_r            ;
  wire                                   s1_w_valid            ;
  reg                                    read_sent_reg         ;
  wire                                   read_sent             ;
  reg                                    sourceA_sent_reg      ;
  wire                                   sourceA_sent          ;
  reg                                    write_sent_reg        ;
  wire                                   write_sent            ;

  assign pb_pop_valid_o = req_valid_i && req_ready_o && (req_opcode_i == `PUTFULLDATA || req_opcode_i == `PUTPARTIALDATA);
  assign pb_pop_index_o = req_put_i                                                                                      ;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      pb_beat_reg_data      <= 'd0;  
      pb_beat_reg_mask      <= 'd0;
      s1_req_reg_from_mem   <= 'd0;  
      s1_req_reg_hit        <= 'd0;
      s1_req_reg_way        <= 'd0;
      s1_req_reg_dirty      <= 'd0;
      s1_req_reg_flush      <= 'd0;
      s1_req_reg_last_flush <= 'd0;
      s1_req_reg_set        <= 'd0;
      //s1_req_reg_l2cidx     <= 'd0;
      s1_req_reg_opcode     <= 'd5;
      s1_req_reg_size       <= 'd0;
      s1_req_reg_source     <= 'd0;
      s1_req_reg_tag        <= 'd0;
      s1_req_reg_offset     <= 'd0;
      s1_req_reg_put        <= 'd0;
      s1_req_reg_data       <= 'd0;
      s1_req_reg_mask       <= 'd0;
      s1_req_reg_param      <= 'd0;
    end
    else if(req_valid_i && req_ready_o) begin
      pb_beat_reg_data      <= pb_beat_data_i  ; 
      pb_beat_reg_mask      <= pb_beat_mask_i  ;
      s1_req_reg_from_mem   <= req_from_mem_i  ;
      s1_req_reg_hit        <= req_hit_i       ;
      s1_req_reg_way        <= req_way_i       ;
      s1_req_reg_dirty      <= req_dirty_i     ;
      s1_req_reg_flush      <= req_flush_i     ;
      s1_req_reg_last_flush <= req_last_flush_i;
      s1_req_reg_set        <= req_set_i       ;
      //s1_req_reg_l2cidx     <= req_l2cidx_i    ;
      s1_req_reg_opcode     <= req_opcode_i    ;
      s1_req_reg_size       <= req_size_i      ;
      s1_req_reg_source     <= req_source_i    ;
      s1_req_reg_tag        <= req_tag_i       ;
      s1_req_reg_offset     <= req_offset_i    ;
      s1_req_reg_put        <= req_put_i       ;
      s1_req_reg_data       <= req_data_i      ;
      s1_req_reg_mask       <= req_mask_i      ;
      s1_req_reg_param      <= req_param_i     ;
    end
    else begin
      pb_beat_reg_data      <= pb_beat_reg_data     ;   
      pb_beat_reg_mask      <= pb_beat_reg_mask     ;   
      s1_req_reg_from_mem   <= s1_req_reg_from_mem  ;   
      s1_req_reg_hit        <= s1_req_reg_hit       ;   
      s1_req_reg_way        <= s1_req_reg_way       ;   
      s1_req_reg_dirty      <= s1_req_reg_dirty     ;   
      s1_req_reg_flush      <= s1_req_reg_flush     ;   
      s1_req_reg_last_flush <= s1_req_reg_last_flush;   
      s1_req_reg_set        <= s1_req_reg_set       ;   
      //s1_req_reg_l2cidx     <= s1_req_reg_l2cidx    ;   
      s1_req_reg_opcode     <= s1_req_reg_opcode    ;   
      s1_req_reg_size       <= s1_req_reg_size      ;   
      s1_req_reg_source     <= s1_req_reg_source    ;   
      s1_req_reg_tag        <= s1_req_reg_tag       ;   
      s1_req_reg_offset     <= s1_req_reg_offset    ;   
      s1_req_reg_put        <= s1_req_reg_put       ;   
      s1_req_reg_data       <= s1_req_reg_data      ;   
      s1_req_reg_mask       <= s1_req_reg_mask      ;   
      s1_req_reg_param      <= s1_req_reg_param     ;
    end
  end

  //stall if busy
  assign pb_beat_data      = (req_valid_i && req_ready_o) ? pb_beat_data_i   : pb_beat_reg_data     ; 
  assign pb_beat_mask      = (req_valid_i && req_ready_o) ? pb_beat_mask_i   : pb_beat_reg_mask     ;
  assign s1_req_from_mem   = (req_valid_i && req_ready_o) ? req_from_mem_i   : s1_req_reg_from_mem  ;
  assign s1_req_hit        = (req_valid_i && req_ready_o) ? req_hit_i        : s1_req_reg_hit       ;
  assign s1_req_way        = (req_valid_i && req_ready_o) ? req_way_i        : s1_req_reg_way       ;
  assign s1_req_dirty      = (req_valid_i && req_ready_o) ? req_dirty_i      : s1_req_reg_dirty     ;
  assign s1_req_flush      = (req_valid_i && req_ready_o) ? req_flush_i      : s1_req_reg_flush     ;
  assign s1_req_last_flush = (req_valid_i && req_ready_o) ? req_last_flush_i : s1_req_reg_last_flush;
  assign s1_req_set        = (req_valid_i && req_ready_o) ? req_set_i        : s1_req_reg_set       ;
  //assign s1_req_l2cidx     = (req_valid_i && req_ready_o) ? req_l2cidx_i     : s1_req_reg_l2cidx    ;
  assign s1_req_opcode     = (req_valid_i && req_ready_o) ? req_opcode_i     : s1_req_reg_opcode    ;
  assign s1_req_size       = (req_valid_i && req_ready_o) ? req_size_i       : s1_req_reg_size      ;
  assign s1_req_source     = (req_valid_i && req_ready_o) ? req_source_i     : s1_req_reg_source    ;
  assign s1_req_tag        = (req_valid_i && req_ready_o) ? req_tag_i        : s1_req_reg_tag       ;
  assign s1_req_offset     = (req_valid_i && req_ready_o) ? req_offset_i     : s1_req_reg_offset    ;
  assign s1_req_put        = (req_valid_i && req_ready_o) ? req_put_i        : s1_req_reg_put       ;
  assign s1_req_data       = (req_valid_i && req_ready_o) ? req_data_i       : s1_req_reg_data      ;
  assign s1_req_mask       = (req_valid_i && req_ready_o) ? req_mask_i       : s1_req_reg_mask      ;
  assign s1_req_param      = (req_valid_i && req_ready_o) ? req_param_i      : s1_req_reg_param     ;
  
  //s_final_req
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      s_final_req_from_mem   <= 'd0;   
      s_final_req_hit        <= 'd0; 
      s_final_req_way        <= 'd0; 
      s_final_req_dirty      <= 'd0; 
      s_final_req_flush      <= 'd0; 
      s_final_req_last_flush <= 'd0; 
      s_final_req_set        <= 'd0; 
      //s_final_req_l2cidx     <= 'd0; 
      s_final_req_opcode     <= 'd0; 
      s_final_req_size       <= 'd0; 
      s_final_req_source     <= 'd0; 
      s_final_req_tag        <= 'd0; 
      s_final_req_offset     <= 'd0; 
      s_final_req_put        <= 'd0; 
      s_final_req_data       <= 'd0; 
      s_final_req_mask       <= 'd0; 
      s_final_req_param      <= 'd0; 
    end
    else begin
      s_final_req_from_mem   <= s1_req_from_mem  ;  
      s_final_req_hit        <= s1_req_hit       ;
      s_final_req_way        <= s1_req_way       ;
      s_final_req_dirty      <= s1_req_dirty     ;
      s_final_req_flush      <= s1_req_flush     ;
      s_final_req_last_flush <= s1_req_last_flush;
      s_final_req_set        <= s1_req_set       ;
      //s_final_req_l2cidx     <= s1_req_l2cidx    ;
      s_final_req_opcode     <= s1_req_opcode    ;
      s_final_req_size       <= s1_req_size      ;
      s_final_req_source     <= s1_req_source    ;
      s_final_req_tag        <= s1_req_tag       ;
      s_final_req_offset     <= s1_req_offset    ;
      s_final_req_put        <= s1_req_put       ;
      s_final_req_data       <= s1_req_data      ;
      s_final_req_mask       <= s1_req_mask      ;
      s_final_req_param      <= s1_req_param     ;
    end
  end

  //                     s1_need_w      
  assign s1_need_w  = (s1_req_opcode == `PUTFULLDATA || s1_req_opcode == `PUTPARTIALDATA) && !s1_req_from_mem && s1_req_hit;
  //                                                s1_need_r       //add invalid and flush
  assign s1_need_r  = ((s1_req_opcode == `GET) && s1_req_hit) || (!s1_req_hit && s1_req_dirty) || ((s1_req_opcode == `HINT) && s1_req_dirty);
  assign s1_valid_r = s1_need_r                                                                                                             ;
  assign s1_w_valid = s1_need_w                                                                                                             ;

  //   s1_need_r                     
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      read_sent_reg <= 1'b0;
    end
    else if(s1_valid_r && bs_radr_ready_i) begin
      read_sent_reg <= 1'b1;
    end
    else begin
      read_sent_reg <= 1'b0;
    end
  end

  //to banked_store(radr) 
  assign read_sent       = (req_valid_i && req_ready_o) ? 1'b0 : read_sent_reg;
  assign bs_radr_valid_o = s1_valid_r && (!read_sent)                         ;//read hit or miss and dirty 
  assign bs_radr_way_o   = s1_req_way                                         ;
  assign bs_radr_set_o   = s1_req_set                                         ;
  assign bs_radr_mask_o  = s1_req_mask                                        ;

  /*assign about_to_not_busy = ((current_state == STAGE_3) && (a_valid_o && a_ready_i)) || 
                             ((current_state == STAGE_4) && ((!s_final_req_hit && (s_final_req_opcode == `PUTFULLDATA || s_final_req_opcode == `PUTPARTIALDATA)) ? ((a_valid_o && a_ready_i) && (d_valid_o && d_ready_i)) : (d_valid_o && d_ready_i))) || 
                             ((current_state == STAGE_8) && (d_valid_o && d_ready_i)) ||
                             ((current_state == STAGE_7) && (a_valid_o && a_ready_i));*/

  assign req_ready_o = !busy;

  /*always@(posedge clk or negedge rst_n) begin
    if(rst_n) begin
      sourceA_sent_reg <= 1'b0;
    end
    else if((s1_req_opcode == `PUTFULLDATA || s1_req_opcode == `PUTPARTIALDATA) && a_ready_i) begin
      sourceA_sent_reg <= 1'b1;
    end
    else begin
      sourceA_sent_reg <= 1'b0;
    end
  end

  assign sourceA_sent    = (req_valid_i && req_ready_o) ? 1'b0 : sourceA_sent_reg;*/

  //   s1_need_w                     
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      write_sent_reg <= 1'b0;
    end
    else if(s1_w_valid && bs_wadr_ready_i) begin
      write_sent_reg <= 1'b1;
    end
    else begin
      write_sent_reg <= 1'b0;
    end
  end

  //to banked_store(wadr)
  assign write_sent      = (req_valid_i && req_ready_o) ? 1'b0 : write_sent_reg;
  assign bs_wadr_valid_o = s1_w_valid && (!write_sent)                         ;//write hit will write into bs
  assign bs_wadr_set_o   = s1_req_set                                          ;
  assign bs_wadr_way_o   = s1_req_way                                          ;
  assign bs_wdat_data_o  = pb_beat_data                                        ;
  assign bs_wadr_mask_o  = pb_beat_mask                                        ;

  //FSM
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      current_state <= STAGE_1;
      busy          <= 1'b0   ;
      tobedone      <= 1'b0   ;
      mshr_wait_reg <= 1'b0   ;
    end
    else begin
      case(current_state)
        STAGE_1 : begin
          mshr_wait_reg <= 1'b0;
          busy          <= 1'b0;
          if((req_valid_i && req_ready_o) || tobedone) begin
            mshr_wait_reg <= 1'b0;
            if(s1_req_opcode == `GET && bs_radr_ready_i) begin//read
              if(!s1_req_hit) begin//not hit
                if(s1_req_dirty) begin//dirty
                  current_state <= STAGE_3;
                  busy          <= 1'b1   ;
                  tobedone      <= 1'b0   ;
                  mshr_wait_reg <= 1'b1   ;//used for kicking out victim way, to block premature potential miss request of victim way
                end
                else begin//not dirty
                  current_state <= STAGE_4;
                  busy          <= 1'b1   ;
                  tobedone      <= 1'b0   ;
                end
              end
              else begin//hit
                current_state <= STAGE_4;
                busy          <= 1'b1   ;
                tobedone      <= 1'b0   ;
              end
            end
            else if(s1_req_opcode == `PUTFULLDATA || s1_req_opcode == `PUTPARTIALDATA) begin//write
              if(s1_req_hit) begin//hit
                if(bs_wadr_ready_i) begin//bankstore not ready
                  current_state <= STAGE_4;
                  busy          <= 1'b1   ;
                  tobedone      <= 1'b0   ;
                end
                else begin
                  current_state <= STAGE_2;
                  busy          <= 1'b1   ;
                  tobedone      <= 1'b0   ;
                end
              end
              else begin//not hit
                if(s1_req_dirty) begin//dirty
                  current_state <= STAGE_3;
                  mshr_wait_reg <= 1'b1   ;
                  busy          <= 1'b1   ;
                  tobedone      <= 1'b1   ;
                end
                else begin
                  current_state <= STAGE_4;
                  mshr_wait_reg <= 1'b0   ;//?????P142 have changed
                  busy          <= 1'b1   ;
                  tobedone      <= 1'b1   ;
                end
              end
            end
            //hint(invalid and flush)
            else if(s1_req_opcode == `HINT) begin
              if(s1_req_dirty) begin
                if(bs_wadr_ready_i) begin//bankstore not ready
                    current_state <= STAGE_4;
                    busy          <= 1'b1   ;
                    tobedone      <= 1'b0   ;
                end
                else begin
                    current_state <= STAGE_2;
                    busy          <= 1'b1   ;
                    tobedone      <= 1'b0   ;
                end
              end
              else begin
                current_state <= STAGE_4;
                busy          <= 1'b1   ;
                tobedone      <= 1'b0   ;
              end
            end
          end
          else begin
            current_state <= current_state;
            busy          <= busy         ;
            tobedone      <= tobedone     ;
            mshr_wait_reg <= mshr_wait_reg;
          end
        end

        STAGE_2 : begin//bankstore write is not ready,need to wait
          if(bs_wadr_ready_i) begin
            current_state <= STAGE_4;
          end
        end

        STAGE_3 : begin//writeback dirty cache line
          if(a_valid_o && a_ready_i) begin
            current_state <= STAGE_1;
            busy          <= 1'b0   ;
            tobedone      <= 1'b0   ;
            mshr_wait_reg <= 1'b0   ;
          end
          else begin
            current_state <=current_state; 
            busy          <=busy         ;
            tobedone      <=tobedone     ;     
            mshr_wait_reg <=mshr_wait_reg;
          end
        end

        STAGE_4 : begin//ack for miss and hit
          if(!s_final_req_hit && (s_final_req_opcode == `PUTFULLDATA || s_final_req_opcode == `PUTPARTIALDATA)) begin//ack for write miss no allocate
            if((d_valid_o && d_ready_i) && (a_valid_o && a_ready_i)) begin
              busy          <= 1'b0   ;
              current_state <= STAGE_1;
              tobedone      <= 1'b0   ;
              mshr_wait_reg <= 1'b0   ;
            end
            else if(d_valid_o && d_ready_i) begin
              current_state <= STAGE_7;
            end
            else if(a_valid_o && a_ready_i) begin
              current_state <= STAGE_8;
            end
            else begin
              current_state <= current_state;
            end
          end

          else if((s_final_req_hit && (s_final_req_opcode == `GET || s_final_req_opcode == `PUTFULLDATA || s_final_req_opcode == `PUTPARTIALDATA)) || (!s_final_req_hit && (s_final_req_opcode == `GET))) begin //ack for read miss/hit and write hit
            if(d_valid_o && d_ready_i) begin
              current_state <= STAGE_1;
              busy          <= 1'b0   ;
              tobedone      <= 1'b0   ;
              mshr_wait_reg <= 1'b0   ;
            end
            else begin
              current_state <= current_state;
              busy          <= busy         ;
              tobedone      <= tobedone     ;
              mshr_wait_reg <= mshr_wait_reg;
            end
          end

          else begin //hint(invalid and flush)
            if(s_final_req_dirty) begin
              if(a_valid_o && a_ready_i) begin
                current_state <= STAGE_1;
                busy          <= 1'b0   ;
                tobedone      <= 1'b0   ;
                mshr_wait_reg <= 1'b0   ;
              end
              else begin
                current_state <= current_state;
                busy          <= busy         ;
                tobedone      <= tobedone     ;
                mshr_wait_reg <= mshr_wait_reg;
              end
            end
            else begin
              current_state <= STAGE_1;
              busy          <= 1'b0   ;
              tobedone      <= 1'b0   ;
              mshr_wait_reg <= 1'b0   ;
            end
          end
        end

        STAGE_7 : begin
          if(a_valid_o && a_ready_i) begin
            current_state <= STAGE_1;
            busy          <= 1'b0   ;
            tobedone      <= 1'b0   ;
            mshr_wait_reg <= 1'b0   ;
          end
          else begin
            current_state <= current_state;
            busy          <= busy         ;
            tobedone      <= tobedone     ;
            mshr_wait_reg <= mshr_wait_reg;
          end
        end

        STAGE_8 : begin//wait for d(L1 cache) ready
          if(d_valid_o && d_ready_i) begin
            current_state <= STAGE_1;
            busy          <= 1'b0   ;
            tobedone      <= 1'b0   ;
            mshr_wait_reg <= 1'b0   ;
          end
          else begin
            current_state <= current_state;
            busy          <= busy         ;
            tobedone      <= tobedone     ;
            mshr_wait_reg <= mshr_wait_reg;
          end
        end

        default : begin
          current_state <= STAGE_1;
          busy          <= 1'b0   ;
          tobedone      <= 1'b0   ;
          mshr_wait_reg <= 1'b0   ;
        end
      endcase
    end
  end

  //to mshr
  assign mshr_wait_o = mshr_wait_reg;

  //to L1 cache
  assign d_valid_o   = (current_state == STAGE_4 || current_state == STAGE_8) && !(s_final_req_opcode == `HINT && !s_final_req_last_flush);
  assign d_source_o  = s_final_req_source                                                                                                 ;
  assign d_opcode_o  = (s_final_req_opcode == `GET) ? `ACCESSACKDATA : (s_final_req_last_flush ? `HINTACK : `ACCESSACK)                   ;
  assign d_size_o    = s_final_req_size                                                                                                   ;
  assign d_data_o    = (s_final_req_opcode == `GET) ? (s_final_req_hit ? bs_rdat_data_i : s_final_req_data) : 'd0                         ;
  //assign d_address_o = (`L2C_BITS !=0) ? {s_final_req_tag,s_final_req_l2cidx,s_final_req_set,s_final_req_offset}
  //                                     : {s_final_req_tag,s_final_req_set,s_final_req_offset}                                             ;
  assign d_address_o = {s_final_req_tag,s_final_req_set,s_final_req_offset}; //`L2C_BITS != 0;
  assign d_param_o   = 'd0                                                                                                                ;

  //to sourceA(memory) //add invalid and flush
  assign a_valid_o   = (current_state == STAGE_4 || current_state == STAGE_7 || current_state == STAGE_3) && ((!s_final_req_hit && (s_final_req_dirty || s_final_req_opcode == `PUTFULLDATA || s_final_req_opcode == `PUTPARTIALDATA)) || ((s_final_req_opcode == `HINT) && s_final_req_dirty));
  assign a_set_o     = s_final_req_set                                                                                                    ;
  //assign a_l2cidx_o  = s_final_req_l2cidx                                                                                                 ;
  assign a_size_o    = s_final_req_size                                                                                                   ;
  assign a_source_o  = 'd4                                                                                                                ;
  assign a_tag_o     = s_final_req_tag                                                                                                    ;
  assign a_offset_o  = s_final_req_offset                                                                                                 ;
  assign a_put_o     = s_final_req_put                                                                                                    ;
  assign a_mask_o    = s_final_req_mask                                                                                                   ;
  assign a_param_o   = s_final_req_param                                                                                                  ;
  assign a_data_o    = (!s_final_req_dirty && (s_final_req_opcode == `PUTFULLDATA || s_final_req_opcode == `PUTPARTIALDATA)) ? s_final_req_data : bs_rdat_data_i;//have changed
  assign a_opcode_o  = `PUTFULLDATA                                                                                                       ;

  assign finish_issue_o = d_valid_o && s_final_req_last_flush                                                                             ;
endmodule


  
