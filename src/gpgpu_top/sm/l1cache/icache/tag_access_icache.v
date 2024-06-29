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
// Author: Zhang, Qi
// Description:Save the tag and check whether the tag matches
`timescale 1ns/1ns

module tag_access_icache #(
  parameter  TAG_WIDTH = 7 ,
  parameter  NUM_SET   = 32,
  parameter  NUM_WAY   = 2 , 
  parameter  SET_DEPTH = 5 , 
  parameter  WAY_DEPTH = 1
  )
  (
  input                          clk                ,
  input                          rst_n              ,
  
  input                          invalid_i          ,
  input                          r_req_valid_i      ,
  input  [SET_DEPTH-1:0]         r_req_setid_i      ,

  input  [TAG_WIDTH-1:0]         tagFromCore_st1_i  , //tag from warp_scheduler 

  input                          w_req_valid_i      ,
  input  [SET_DEPTH-1:0]         w_req_setid_i      ,
  input  [NUM_WAY*TAG_WIDTH-1:0] w_req_data_i       ,

  //output [WAY_DEPTH-1:0]         wayid_replacement_o, //will be replaced next time
  output [NUM_SET*WAY_DEPTH-1:0] wayid_replacement_o,
  output [WAY_DEPTH-1:0]         wayid_hit_st1_o    , //hit way
  output                         hit_st1_o                      
  );

  wire [NUM_WAY*TAG_WIDTH-1:0] tagBodyAccess_r_resp_data_o;

  //reg [NUM_WAY-1:0] way_valid [0:NUM_SET-1]; //whether there is valid data
  reg [NUM_SET*NUM_WAY-1:0] way_valid;

  reg                 r_req_valid_i_r;
  reg [SET_DEPTH-1:0] r_req_setid_i_r;

  //wire replacement_set_is_full;

  wire [NUM_WAY-1:0] wayid_replacement_one;

  wire [NUM_SET-1:0] lru_valid;
  //wire [SET_DEPTH-1:0] lru_addr;
  wire [NUM_SET*WAY_DEPTH-1:0] lru_update_index;

  //assign lru_addr = w_req_valid_i ? w_req_setid_i : r_req_setid_i_r;

  //assign lru_valid[lru_addr] = w_req_valid_i || hit_st1_o; //when hit or miss allocate

  //assign lru_update_index[(WAY_DEPTH*(lru_addr+1)-1)-:WAY_DEPTH] = w_req_valid_i ? wayid_replacement_o[(WAY_DEPTH*(lru_addr+1)-1)-:WAY_DEPTH] : wayid_hit_st1_o;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      r_req_valid_i_r <= 'h0;
      r_req_setid_i_r <= 'h0;
    end 
    else begin
      r_req_valid_i_r <= r_req_valid_i;
      r_req_setid_i_r <= r_req_setid_i;
    end 
  end 

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      way_valid <= 'h0;
    end 
    else if(w_req_valid_i) begin
      way_valid[(w_req_setid_i*NUM_WAY)+wayid_replacement_o[(WAY_DEPTH*(w_req_setid_i+1)-1)-:WAY_DEPTH]] <= 'h1; 
    end 
    else if(invalid_i) begin
      way_valid <= 'h0;
    end 
    else begin
      way_valid <= way_valid;
    end 
  end 
  
  genvar i;
  generate for(i=0;i<NUM_SET;i=i+1) begin:B1
    //always @(posedge clk or negedge rst_n) begin
    //  if(!rst_n) begin
    //    way_valid[i] <= 'h0;
    //  end 
    //  //else if(w_req_valid_i && (!replacement_set_is_full))begin
    //  else if(w_req_valid_i) begin
    //    way_valid[w_req_setid_i][wayid_replacement_o[(WAY_DEPTH*(w_req_setid_i+1)-1)-:WAY_DEPTH]] <= 'h1;
    //  end 
    //  else begin
    //    way_valid[i] <= way_valid[i];
    //  end 
    //end 

    assign lru_valid[i] = ((hit_st1_o && (i==r_req_setid_i_r)) || (w_req_valid_i && (i==w_req_setid_i))) ? 1'h1 : 1'h0; 
    assign lru_update_index[((WAY_DEPTH*(i+1))-1)-:WAY_DEPTH] = (hit_st1_o && (i==r_req_setid_i_r)) ? wayid_hit_st1_o : 
                                                                (((w_req_valid_i) && (i==w_req_setid_i)) ? wayid_replacement_o[(WAY_DEPTH*(i+1)-1)-:WAY_DEPTH] : 'h0);

    lru_matrix #(
    .NUM_WAY  (NUM_WAY  ),
    .WAY_DEPTH(WAY_DEPTH)
    ) replacement(
    .clk           (clk                                                ),
    .rst_n         (rst_n                                              ),
    .update_entry_i(lru_valid[i]                                       ),
    .update_index_i(lru_update_index[(WAY_DEPTH*(i+1)-1)-:WAY_DEPTH]   ),
    .lru_index_o   (wayid_replacement_o[(WAY_DEPTH*(i+1)-1)-:WAY_DEPTH])
    );
  end
  endgenerate

  sram_template #(
    .GEN_WIDTH(TAG_WIDTH), 
    .NUM_SET  (NUM_SET  ), 
    .NUM_WAY  (NUM_WAY  ),
    .SET_DEPTH(SET_DEPTH),
    .WAY_DEPTH(WAY_DEPTH)
    ) tagBodyAccess(
    .clk            (clk                        ),
    .rst_n          (rst_n                      ),
    .r_req_valid_i  (r_req_valid_i              ),
    .r_req_setid_i  (r_req_setid_i              ),
    .r_resp_data_o  (tagBodyAccess_r_resp_data_o),
    .w_req_valid_i  (w_req_valid_i              ),
    .w_req_setid_i  (w_req_setid_i              ),
    .w_req_waymask_i(wayid_replacement_one      ),
    .w_req_data_i   (w_req_data_i               )
    );

  tag_checker_icache #(
    .TAG_WIDTH(TAG_WIDTH), 
    .NUM_WAY  (NUM_WAY  ), 
    .WAY_DEPTH(WAY_DEPTH) 
    ) iTagChecker(
    .r_req_valid_i  (r_req_valid_i_r                                    ),
    .tag_of_set_i   (tagBodyAccess_r_resp_data_o                        ),
    .tag_from_pipe_i(tagFromCore_st1_i                                  ),
    .way_valid_i    (way_valid[(NUM_WAY*(r_req_setid_i_r+1)-1)-:NUM_WAY]),
    .wayid_o        (wayid_hit_st1_o                                    ),
    .cache_hit_o    (hit_st1_o                                          )
    );

  //replacement_icache #(
  //  .NUM_SET  (NUM_SET  ),
  //  .NUM_WAY  (NUM_WAY  ),
  //  .SET_DEPTH(SET_DEPTH),
  //  .WAY_DEPTH(WAY_DEPTH)
  //  ) Replacement(
  //  .clk               (clk                     ),
  //  .rst_n             (rst_n                   ),
  //  .w_req_valid_i     (w_req_valid_i           ),
  //  .validbits_of_set_i(way_valid[w_req_setid_i]),
  //  .setid_i           (w_req_setid_i           ),
  //  .wayid_o           (wayid_replacement_o     ),
  //  .set_is_full_o     (replacement_set_is_full )
  //  );

  bin2one #(
  .ONE_WIDTH(NUM_WAY  ),
  .BIN_WIDTH(WAY_DEPTH)
  ) bin2one(
  .bin(wayid_replacement_o[(WAY_DEPTH*(w_req_setid_i+1)-1)-:WAY_DEPTH]),
  .oh (wayid_replacement_one                                          )
  );

endmodule
