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
// Author: Chen, Qixiang
// Description:Replacement Unit change lru_matrix
`include "define.v"

`timescale 1ns/1ps

module tag_access_top_v2 #(
  parameter NUM_SET   = `DCACHE_NSETS   , // 32
  parameter NUM_WAY   = `DCACHE_NWAYS   , // 2
  parameter TAG_BITS  = `DCACHE_TAGBITS   // 24   
)
(
  input                                 clk                               ,
  input                                 rst_n                             ,
  
  // From coreReq_pipe0
  input                                 probeRead_valid_i                 , // Probe Channel
  output                                probeRead_ready_o                 , // Probe Channel
  input   [$clog2(NUM_SET)-1:0]         probeRead_setIdx_i                , // Probe Channel
  input   [TAG_BITS-1:0]                tagFromCore_st1_i                 ,
  input                                 probeIsWrite_st1_i                ,
  
  //From coreReq_pipe1
  input                                 coreReq_q_deq_fire_i              ,

  // To coreReq_pipe1
  output                                hit_st1_o                         ,
  output  [NUM_WAY-1:0]                 waymaskHit_st1_o                  ,

  // From memRsp_pipe0
  input                                 allocateWrite_valid_i             , // Allocate Channel
  input   [$clog2(NUM_SET)-1:0]         allocateWrite_setIdx_i            , // Allocate Channel
  input   [TAG_BITS-1:0]                allocateWriteData_st1_i           ,

  // From memRsp_pipe1
  input                                 allocateWriteTagSRAMWValid_st1_i  ,

  // for flush: in order to not change way_dirty
  input                                 mem_req_fire_i                    ,
  
  // To memRsp_pipe1
  output                                needReplace_o                     ,
  output  [NUM_WAY-1:0]                 waymaskReplacement_st1_o          , // onehot,for SRAMTemplate
  output  [`XLEN-1:0]                   addrReplacement_st1_o             ,

  // For InvOrFlu
  output                                hasDirty_st0_o                    ,
  output  [$clog2(NUM_SET)-1:0]         dirtySetIdx_st0_o                 ,
  output  [$clog2(NUM_WAY)-1:0]         dirtyWayMask_st0_o                ,
  output  [TAG_BITS-1:0]                dirtyTag_st1_o                    ,
  
  // For InvOrFlu and LRSC
  input                                 flushChoosen_valid_i              ,
  input  [$clog2(NUM_SET)+NUM_WAY-1:0]  flushChoosen_i                    , // [flushChoosen_setIdx,flushChoosen_waymask]
  
  // For Inv
  input                                 invalidateAll_i                   ,
  input                                 tagready_st1_i                     

);

  wire    probeRead_fire          ;
  reg     probeRead_fire_q        ;
  wire    allocateWrite_fire      ;
  reg     allocateWrite_fire_q    ;


  // for probeRead buffer
  wire                                 probeRead_buf_valid                ; 
  wire                                 probeRead_buf_ready                ; 
  wire   [$clog2(NUM_SET)-1:0]         probeRead_buf_setIdx               ;
  wire                                 probeRead_ready_out                ;

  // for tagAccess read req arbiter(3to1)
  wire   [3-1:0]                       tagAccessRArb_in_valid             ; 
  wire   [3-1:0]                       tagAccessRArb_in_ready             ; 
  wire   [$clog2(NUM_SET)*3-1:0]       tagAccessRArb_in_setIdx            ;
  wire   [3-1:0]                       tagAccessRArb_valid_oh             ; 
  wire   [2-1:0]                       tagAccessRArb_valid_bin            ; 
  wire                                 tagAccessRArb_out_valid            ; 
  wire   [$clog2(NUM_SET)-1:0]         tagAccessRArb_out_setIdx           ;

  // for timeAccess write req arbiter(2to1)
  wire  [2-1:0]                                     timeAccessWArb_in_valid      ;
  wire  [`LENGTH_REPLACE_TIME*NUM_WAY*2-1 :0]       timeAccessWArb_in_data       ;
  wire  [NUM_WAY*2-1:0]                             timeAccessWArb_in_waymask    ;
  wire  [$clog2(NUM_SET)*2-1:0]                     timeAccessWArb_in_setIdx     ;
  wire  [2-1:0]                                     timeAccessWArb_valid_oh      ;
  wire                                              timeAccessWArb_valid_bin     ;
  wire                                              timeAccessWArb_out_valid     ;
  wire  [`LENGTH_REPLACE_TIME*NUM_WAY-1 :0]         timeAccessWArb_out_data      ;
  wire  [NUM_WAY-1:0]                               timeAccessWArb_out_waymask   ;
  wire  [$clog2(NUM_SET)-1:0]                       timeAccessWArb_out_setIdx    ;
  
  // for timeAccess write req conflict
  wire  timeAccessWArb_conflict       ;
  reg   timeAccessWArb_conflict_q     ;
  
  // RegNext
  //reg                               hit_st1_q                     ;
  //reg   [`LENGTH_REPLACE_TIME-1:0]  count_q                       ; 
  reg   [$clog2(NUM_SET)-1:0]       probeRead_setIdx_q            ;
  //reg   [$clog2(NUM_SET)-1:0]       probeRead_setIdx_qq           ;
  //reg   [NUM_WAY-1:0]               waymaskHit_st1_q              ;
  //reg   [$clog2(NUM_SET)-1:0]       allocateWrite_setIdx_q        ;

  // for tagchecker module
  wire  [TAG_BITS*NUM_WAY-1:0]  tagchecker_tag_of_set         ;
  wire  [TAG_BITS-1:0]          tagchecker_tag_from_pipe      ;
  wire  [NUM_WAY-1:0]           tagchecker_valid_of_way       ;
  wire  [NUM_WAY-1:0]           tagchecker_waymask            ;
  wire                          tagchecker_cache_hit          ;
  wire  [$clog2(NUM_WAY)-1:0]   tagchecker_waymask_bin        ;

  // register for way vaild and dirty
  reg [NUM_WAY*NUM_SET-1:0] way_valid ;
  reg [NUM_WAY*NUM_SET-1:0] way_dirty ;

  // RegEnable
  reg [$clog2(NUM_SET)-1:0]   probeRead_setIdx_st1        ;
  reg [$clog2(NUM_SET)-1:0]   allocateWrite_setIdx_st1    ;

  // for cacheHit_hold buffer
  wire                     cacheHit_hold_w_ready    ;
  wire                     cacheHit_hold_w_valid    ;
  wire  [NUM_WAY+1-1:0]    cacheHit_hold_w_data     ; // cacheHit_hold_data = [hit,waymask]
  wire                     cacheHit_hold_r_valid    ;
  wire                     cacheHit_hold_r_ready    ;
  wire  [NUM_WAY+1-1:0]    cacheHit_hold_r_data     ; // cacheHit_hold_data = [hit,waymask]

  // for lru_matrix
  wire                                      replacement_set_is_full       ;
  wire  [$clog2(NUM_WAY)-1:0]               replacement_waymask_st1_bin   ;
  wire  [NUM_WAY-1:0]                       replacement_waymask_st1_oh    ;
  wire  [NUM_SET-1:0]                       lru_update_entry   ; 
  reg   [NUM_SET-1:0]                       probeRead_valid_of_setIdx        ; 
  reg   [NUM_SET-1:0]                       allocateWrite_valid_of_setIdx    ; 
  wire  [$clog2(NUM_WAY)-1:0]               lru_update_index   ; 
  wire  [$clog2(NUM_WAY)*NUM_SET-1:0]       lru_index_out      ;  
  

  wire  [TAG_BITS*NUM_WAY-1:0]                  tagBodyAccess_resp_data   ;

  wire  [TAG_BITS+$clog2(NUM_SET)-1:0]          tag_and_set ; //  [tag,set]

  // For InvOrFlu
  wire                          hasDirty_st0                       ;
  wire   [$clog2(NUM_SET)-1:0]  choosenDirty_setIdx_st0            ;
  wire  [NUM_SET-1:0]           set_dirty;
  wire  [NUM_WAY*NUM_SET-1:0]   way_dirty_after_valid;
  wire  [NUM_WAY-1:0]           choosenDirty_set_valid;
  wire  [$clog2(NUM_WAY)-1:0]   choosenDirty_waymask_st0; //  onehot -> bin
  wire  [TAG_BITS-1:0]          choosenDirty_tag_st1;
  //wire  [NUM_SET-1:0]           set_dirty_oh;
  wire                          set_dirty_zero;
  wire  [$clog2(NUM_SET)-1:0]   set_dirty_bin;
  wire  [NUM_WAY-1:0]           choosenDirty_set_valid_oh;
  wire  [$clog2(NUM_WAY)-1:0]   choosenDirty_set_valid_bin;

  wire  [$clog2(NUM_SET)-1:0]   flushChoosen_setIdx     ;
  wire  [NUM_WAY-1:0]           flushChoosen_waymask    ;
  wire  [$clog2(NUM_WAY)-1:0]   flushChoosen_waymask_bin;

  
  assign probeRead_fire      =  probeRead_valid_i & probeRead_ready_o ;
  assign allocateWrite_fire  =  allocateWrite_valid_i                 ;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      probeRead_fire_q      <= 1'b0;
      allocateWrite_fire_q  <= 1'b0;
    end 
    else begin
      probeRead_fire_q      <= (probeRead_fire_q && !coreReq_q_deq_fire_i) ? probeRead_fire_q : probeRead_fire;
      allocateWrite_fire_q  <= allocateWrite_fire;
    end
  end

  //assign probeRead_buf_ready = (flushChoosen_valid_i || invalidateAll_i) ? tagready_st1_i : coreReq_q_deq_fire_i   ;
  assign probeRead_buf_ready = tagready_st1_i;

  // SRAM to store tag
  // For probe
  assign  tagAccessRArb_in_valid[1]                                      = probeRead_valid_i          ; 
  assign  probeRead_ready_o                                              = tagAccessRArb_in_ready[1]  ; 
  assign  tagAccessRArb_in_setIdx[$clog2(NUM_SET)*2-1-:$clog2(NUM_SET)]  = probeRead_setIdx_i         ;
  // For allocate
  assign  tagAccessRArb_in_valid[0]                                      = allocateWrite_valid_i      ; 
  assign  tagAccessRArb_in_setIdx[$clog2(NUM_SET)*1-1-:$clog2(NUM_SET)]  = allocateWrite_setIdx_i     ;
  // For hasDirty
  //assign  tagAccessRArb_in_valid[2]                                      = !probeRead_valid_i && !allocateWrite_valid_i  ;
  assign  tagAccessRArb_in_valid[2]                                      = flushChoosen_valid_i || invalidateAll_i; 
  assign  tagAccessRArb_in_setIdx[$clog2(NUM_SET)*3-1-:$clog2(NUM_SET)]  = choosenDirty_setIdx_st0                       ;

  assign  tagAccessRArb_in_ready[0]   =    1'b1  ; 
  assign  tagAccessRArb_in_ready[1]   =    !tagAccessRArb_in_valid[0]  ; 
  assign  tagAccessRArb_in_ready[2]   =    !tagAccessRArb_in_valid[1]  ; 
  assign  tagAccessRArb_out_valid     =    tagAccessRArb_in_valid  [tagAccessRArb_valid_bin]  ; 
  assign  tagAccessRArb_out_setIdx    =    tagAccessRArb_in_setIdx [$clog2(NUM_SET)*(tagAccessRArb_valid_bin+1)-1-:$clog2(NUM_SET)]  ;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      probeRead_setIdx_q <=  'b0;
    end 
    else begin
      probeRead_setIdx_q <= (probeRead_fire_q && !coreReq_q_deq_fire_i) ? probeRead_setIdx_q : probeRead_setIdx_i;
    end
  end

  /*
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      hit_st1_q               <= 1'b0;
      probeRead_setIdx_qq     <=  'b0;
      waymaskHit_st1_q        <=  'b0;
      allocateWrite_setIdx_q  <= 'b0;
    end else begin
      hit_st1_q               <= hit_st1_o;
      probeRead_setIdx_qq     <= probeRead_setIdx_q;
      waymaskHit_st1_q        <= waymaskHit_st1_o;
      allocateWrite_setIdx_q  <= allocateWrite_setIdx_i;
    end
  end
  */

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      allocateWrite_setIdx_st1  <= 'b0;
    end else if(allocateWrite_fire) begin
      allocateWrite_setIdx_st1  <= allocateWrite_setIdx_i;
    end else begin
      allocateWrite_setIdx_st1  <= allocateWrite_setIdx_st1;
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      probeRead_setIdx_st1  <= 'b0;
    end else if(probeRead_fire) begin
      probeRead_setIdx_st1  <= probeRead_setIdx_i;
    end else begin
      probeRead_setIdx_st1  <= probeRead_setIdx_st1;
    end
  end

  assign  tagchecker_tag_of_set       = tagBodyAccess_resp_data   ; // st1
  assign  tagchecker_tag_from_pipe    = tagFromCore_st1_i         ; // st1
  assign  tagchecker_valid_of_way     = way_valid[NUM_WAY*(probeRead_setIdx_st1+1)-1-:NUM_WAY]               ; // st1

  // Queue
  //assign  cacheHit_hold_w_ready                 = 1'b1;//!cacheHit_hold_w_valid                            ; // not always high
  assign  cacheHit_hold_w_valid                 = probeRead_buf_valid                               ;
  assign  cacheHit_hold_w_data[NUM_WAY-1:0]     = !probeRead_buf_ready ? tagchecker_waymask : 1'b0  ; // waymask
  assign  cacheHit_hold_w_data[NUM_WAY]         = tagchecker_cache_hit && !probeRead_buf_ready      ; // hit
  assign  cacheHit_hold_r_ready                 = probeRead_buf_ready                               ;
    
  //reg hit_st1_r;
  //
  //always @(posedge clk or negedge rst_n) begin
  //  if(!rst_n) begin
  //    hit_st1_r <= 1'b0;
  //  end
  //  else if(probeRead_fire_q && !coreReq_q_deq_fire_i) begin
  //    hit_st1_r <= hit_st1_o;
  //  end
  //  else begin
  //    hit_st1_r <= hit_st1_r;
  //  end 
  //end 
  
  //assign  hit_st1_o         = ((tagchecker_cache_hit&&coreReq_q_deq_fire_i) || cacheHit_hold_r_data[NUM_WAY]  && cacheHit_hold_r_valid) && probeRead_buf_valid;
  assign  hit_st1_o         = ((tagchecker_cache_hit&&probeRead_fire_q) /*|| cacheHit_hold_r_data[NUM_WAY]  && cacheHit_hold_r_valid*/) && probeRead_buf_valid;
  //assign  waymaskHit_st1_o  = cacheHit_hold_r_valid ? cacheHit_hold_r_data[NUM_WAY-1:0] : tagchecker_waymask;
  assign  waymaskHit_st1_o  = tagchecker_waymask;

  assign  flushChoosen_setIdx   = flushChoosen_i[$clog2(NUM_SET)+NUM_WAY-1:NUM_WAY] ;
  assign  flushChoosen_waymask  = flushChoosen_i[NUM_WAY-1:0]                       ;

  /*
  //for flush, dont need count dirty write
  reg [$clog2(NUM_SET*NUM_WAY)-1:0] cnt_flush;
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      cnt_flush <= 'd0;
    end
    else begin
      if(flushChoosen_valid_i) begin
        cnt_flush <= cnt_flush + 1;
      end
      else if(mem_req_fire_i && cnt_flush!='d0) begin
        cnt_flush <= cnt_flush - 1;
      end
      else begin
        cnt_flush <= cnt_flush;
      end
    end
  end
  */

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      way_dirty <= {(NUM_WAY*NUM_SET){1'b0}};
    //end else if(tagchecker_cache_hit && probeIsWrite_st1_i) begin
    end else if(hit_st1_o && !(probeRead_fire_q && !coreReq_q_deq_fire_i) && probeIsWrite_st1_i) begin
      way_dirty[NUM_WAY*probeRead_setIdx_q+tagchecker_waymask_bin] <= 1'b1;
    //end else if(mem_req_fire_i && cnt_flush!='d0) begin
    end else if(flushChoosen_valid_i) begin
      way_dirty[NUM_WAY*flushChoosen_setIdx+flushChoosen_waymask_bin] <= 1'b0;
    end else if(needReplace_o) begin
      way_dirty[NUM_WAY*allocateWrite_setIdx_st1+replacement_waymask_st1_bin] <= 1'b0;
    end else begin
      way_dirty <= way_dirty;
    end
  end

  assign needReplace_o = way_dirty[NUM_WAY*allocateWrite_setIdx_st1+replacement_waymask_st1_bin] && allocateWrite_fire_q;

  genvar i;
  generate
    for(i=0; i<NUM_SET; i=i+1) begin:lru_input_loop
      always @(*) begin
        //if(probeRead_fire_q && i==probeRead_setIdx_st1) begin
        if(probeRead_fire_q && i==probeRead_setIdx_st1 && hit_st1_o) begin
          probeRead_valid_of_setIdx      [i] = 1'b1; 
          allocateWrite_valid_of_setIdx  [i] = 1'b0; 
        //for miss replace dirty
        //end else if(allocateWrite_fire_q && i==allocateWrite_setIdx_st1) begin
        end else if(allocateWriteTagSRAMWValid_st1_i && i==allocateWrite_setIdx_st1) begin
          probeRead_valid_of_setIdx      [i] = 1'b0; 
          allocateWrite_valid_of_setIdx  [i] = 1'b1; 
        end else begin
          probeRead_valid_of_setIdx      [i] = 1'b0; 
          allocateWrite_valid_of_setIdx  [i] = 1'b0; 
        end
      end
    end
  endgenerate

  // when not full, output PriorityEncoder(~io.validOfSet)))
  wire [NUM_WAY-1:0]         way_nvalid     [0:NUM_SET-1];
  wire [NUM_WAY-1:0]         way_nvalid_oh  [0:NUM_SET-1];
  wire [$clog2(NUM_WAY)-1:0] way_nvalid_bin [0:NUM_SET-1];

  genvar n;
  generate
    for(n=0; n<NUM_SET; n=n+1) begin: NOT_FULL_WAY_OUTPUT
      assign way_nvalid[n] = ~way_valid[NUM_WAY*(n+1)-1-:NUM_WAY];
      
      fixed_pri_arb #(
        .ARB_WIDTH (NUM_WAY)
      )
      nvalid_oh (
        .req   (way_nvalid[n]   ),
        .grant (way_nvalid_oh[n])
      );

      one2bin #(
        .ONE_WIDTH (NUM_WAY        ),
        .BIN_WIDTH ($clog2(NUM_WAY))
      )
      nvalid_bin (
        .oh  (way_nvalid_oh[n] ),
        .bin (way_nvalid_bin[n])
      );
 
    end
  endgenerate
  
  assign  waymaskReplacement_st1_o     = replacement_waymask_st1_oh                                    ;
  //assign  lru_update_entry             = probeRead_valid_of_setIdx | allocateWrite_valid_of_setIdx                                            ;
  //assign  lru_update_index             = probeRead_fire ? probeRead_setIdx_st1 : (allocateWrite_fire ? allocateWrite_setIdx_st1 : 'b0)        ;
  //assign  replacement_waymask_st1_bin  = lru_index_out    [$clog2(NUM_WAY)*(allocateWrite_setIdx_st1+1)-1-:$clog2(NUM_WAY)]                   ;
  assign  lru_update_entry             = allocateWrite_valid_of_setIdx | probeRead_valid_of_setIdx                           ;
  assign  lru_update_index             = (probeRead_fire_q&&hit_st1_o) ? tagchecker_waymask_bin : replacement_waymask_st1_bin;
  assign  replacement_waymask_st1_bin  = &way_valid[NUM_WAY*(allocateWrite_setIdx_st1+1)-1-:NUM_WAY] ? lru_index_out[$clog2(NUM_WAY)*(allocateWrite_setIdx_st1+1)-1-:$clog2(NUM_WAY)] : way_nvalid_bin[allocateWrite_setIdx_st1];
  assign  replacement_set_is_full      = way_valid[NUM_WAY*(allocateWrite_setIdx_st1+1)-1-:NUM_WAY] == {NUM_WAY{1'b1}}; 
  
  
  //assign  tag_and_set   =   {tagBodyAccess_resp_data[`LENGTH_REPLACE_TIME*(replacement_waymask_st1_bin+1)-1-:`LENGTH_REPLACE_TIME],allocateWrite_setIdx_st1}; // tag + setIdx
  assign  tag_and_set   =   {tagBodyAccess_resp_data[TAG_BITS*(replacement_waymask_st1_bin+1)-1-:TAG_BITS],allocateWrite_setIdx_st1};
  assign  addrReplacement_st1_o =  {tag_and_set,{(`DCACHE_BLOCKOFFSETBITS+`DCACHE_WORDOFFSETBITS){1'b0}}}; // tag + setIdx + blockOffset + wordOffset
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      way_valid <= {(NUM_WAY*NUM_SET){1'b0}};
    end else if(allocateWrite_fire_q && !replacement_set_is_full) begin
      way_valid[NUM_WAY*allocateWrite_setIdx_st1+replacement_waymask_st1_bin] <= 1'b1;
    end else if(invalidateAll_i) begin
      way_valid <= {(NUM_WAY*NUM_SET){1'b0}};
    end else begin
      way_valid <= way_valid;
    end
  end

  assign way_dirty_after_valid = way_valid & way_dirty;
  
  genvar j;
  generate
    for(j=0; j<NUM_SET; j=j+1) begin:set_loop
      assign set_dirty[j] = |way_dirty_after_valid[NUM_WAY*(j+1)-1-:NUM_WAY];
    end
  endgenerate

  reg [$clog2(NUM_WAY)-1:0] choosenDirty_waymask_st1;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      choosenDirty_waymask_st1 <= 'd0;
    end
    else begin
      choosenDirty_waymask_st1 <= choosenDirty_waymask_st0;
    end
  end

  assign  hasDirty_st0 = |set_dirty;
  assign  choosenDirty_setIdx_st0 = set_dirty_bin;
  assign  choosenDirty_set_valid = way_dirty_after_valid[NUM_WAY*(choosenDirty_setIdx_st0+1)-1-:NUM_WAY];
  assign  choosenDirty_waymask_st0  = choosenDirty_set_valid_bin;
  assign  choosenDirty_tag_st1 = tagBodyAccess_resp_data[TAG_BITS*(choosenDirty_waymask_st1+1)-1-:TAG_BITS];

  assign  hasDirty_st0_o                   = hasDirty_st0  ;
  assign  dirtySetIdx_st0_o                = choosenDirty_setIdx_st0  ;
  assign  dirtyWayMask_st0_o               = choosenDirty_waymask_st0  ;
  assign  dirtyTag_st1_o                   = choosenDirty_tag_st1  ;





  stream_fifo_pipe_true #(                                                                                 
    .DATA_WIDTH ( $clog2(NUM_SET) ),
    .FIFO_DEPTH ( 1               ) //can't be zero
    )
  U_probe_read_buffer
    (
    .clk      (clk                   ),
    .rst_n    (rst_n                 ),
    .w_ready_o(probeRead_ready_out   ),
    .w_valid_i(probeRead_valid_i     ),
    .w_data_i (probeRead_setIdx_i    ),
    .r_valid_o(probeRead_buf_valid   ),
    .r_ready_i(probeRead_buf_ready   ),
    .r_data_o (probeRead_buf_setIdx  )
    );

  sram_template_l1d_tag #(
    .GEN_WIDTH (TAG_BITS          ) ,
    .NUM_SET   (NUM_SET           ) ,
    .NUM_WAY   (NUM_WAY           ) , //way should >= 1
    .SET_DEPTH ($clog2(NUM_SET)   ) ,
    .WAY_DEPTH ($clog2(NUM_WAY)   )  
    )
  U_tag_body_access
    (
    .clk            (clk                                ),
    .rst_n          (rst_n                              ),
    .r_req_valid_i  (tagAccessRArb_out_valid            ),
    .r_req_setid_i  (tagAccessRArb_out_setIdx           ), 
    .r_resp_data_o  (tagBodyAccess_resp_data            ), //[GEN_WIDTH-1:0] [0:NUM_WAY-1]
    .w_req_valid_i  (/*allocateWrite_fire_q*/ allocateWriteTagSRAMWValid_st1_i   ),
    .w_req_setid_i  (allocateWrite_setIdx_st1           ),
    .w_req_waymask_i(replacement_waymask_st1_oh                  ), 
    .w_req_data_i   ({NUM_WAY{allocateWriteData_st1_i}} )  
    );

  fixed_pri_arb #(
    .ARB_WIDTH(3)
  )
  U_fixed_pri_tagAccessRArb
  (
    .req  (tagAccessRArb_in_valid     ),
    .grant(tagAccessRArb_valid_oh     )
  );

  one2bin #(
    .ONE_WIDTH(3),
    .BIN_WIDTH(2)
  )
  U_one2bin_tagAccessRArb
  (
    .oh(tagAccessRArb_valid_oh      ),
    .bin(tagAccessRArb_valid_bin    )    
  );

  genvar k;
  generate
    for(k=0; k<NUM_SET; k=k+1) begin:lru_module_loop
      
      lru_matrix #(
        .NUM_WAY  (NUM_WAY        ),
        .WAY_DEPTH($clog2(NUM_WAY))
        )
      U_lru_matrix
        (
        .clk               (clk                                                       ),
        .rst_n             (rst_n                                                     ),
        .update_entry_i    (lru_update_entry[k]                                       ),
        .update_index_i    (lru_update_index                                          ),
        .lru_index_o       (lru_index_out[$clog2(NUM_WAY)*(k+1)-1-:$clog2(NUM_WAY)]   )
        );

    end
  endgenerate

  bin2one #(
    .ONE_WIDTH(NUM_WAY),
    .BIN_WIDTH($clog2(NUM_WAY))
  )
  U_bin2one_lru_index_out
  (
    .bin  (replacement_waymask_st1_bin   ),
    .oh   (replacement_waymask_st1_oh    )    
  );



  tag_checker #(
    .NUM_WAY   (NUM_WAY   ),
    .TAG_BITS  (TAG_BITS  )    
  )
  U_tag_checker
  (
    .tag_of_set_i       (tagchecker_tag_of_set     ) ,
    .tag_from_pipe_i    (tagchecker_tag_from_pipe  ) ,
    .valid_of_way_i     (tagchecker_valid_of_way   ) ,
    .waymask_o          (tagchecker_waymask        ) , //  onehot
    .cache_hit_o        (tagchecker_cache_hit      )  
  
  );


  stream_fifo #(
    .DATA_WIDTH ( NUM_WAY+1         ),
    .FIFO_DEPTH ( 1                 ) //can't be zero
    )
  U_cacheHit_hold
    (
    .clk      (clk                     ),
    .rst_n    (rst_n                   ),
    .w_ready_o(cacheHit_hold_w_ready   ),
    .w_valid_i(cacheHit_hold_w_valid   ),
    .w_data_i (cacheHit_hold_w_data    ),
    .r_valid_o(cacheHit_hold_r_valid   ),
    .r_ready_i(cacheHit_hold_r_ready   ),
    .r_data_o (cacheHit_hold_r_data    )
    );

  one2bin #(
    .ONE_WIDTH(NUM_WAY        ),
    .BIN_WIDTH($clog2(NUM_WAY))
  )
  U_one2bin_tagchecker_waymask
  (
    .oh(tagchecker_waymask          ),
    .bin(tagchecker_waymask_bin     )    
  );
  
  /*
  fixed_pri_arb #(
    .ARB_WIDTH(NUM_SET)
  )
  U_fixed_pri_set_dirty
  (
    .req  (set_dirty         ),
    .grant(set_dirty_oh      )
  );

  one2bin #(
    .ONE_WIDTH(NUM_SET        ),
    .BIN_WIDTH($clog2(NUM_SET))
  )
  U_one2bin_set_dirty
  (
    .oh(set_dirty_oh      ),
    .bin(set_dirty_bin    )    
  );
  */

  lzc #(
    .WIDTH     (NUM_SET        ),
    .MODE      (1'b0           ),
    .CNT_WIDTH ($clog2(NUM_SET))
  )
  x_bin (
    .in_i    (set_dirty     ),
    .cnt_o   (set_dirty_bin ),
    .empty_o (set_dirty_zero)
  );


  fixed_pri_arb #(
    .ARB_WIDTH(NUM_WAY)
  )
  U_fixed_pri_choosenDirty_set_valid
  (
    .req  (choosenDirty_set_valid         ),
    .grant(choosenDirty_set_valid_oh      )
  );

  
  one2bin #(
    .ONE_WIDTH(NUM_WAY        ),
    .BIN_WIDTH($clog2(NUM_WAY))
  )
  U_one2bin_chooseDirty_set_valid
  (
    .oh (choosenDirty_set_valid_oh ),
    .bin(choosenDirty_set_valid_bin)    
  );
  
  one2bin #(
    .ONE_WIDTH(NUM_WAY        ),
    .BIN_WIDTH($clog2(NUM_WAY))
  )
  flush_choosen_waymask_oh2bin
  (
    .oh (flushChoosen_waymask    ),
    .bin(flushChoosen_waymask_bin)    
  );




endmodule
