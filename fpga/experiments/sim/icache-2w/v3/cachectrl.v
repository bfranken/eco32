//
// cachectrl.v -- cache controller
//


`timescale 1ns/10ps
`default_nettype none


module cachectrl(clk, rst,
                 cache_ready_out, cache_valid_in, cache_addr_in,
                 cache_ready_in, cache_valid_out, cache_data_out,
                 memory_stb, memory_addr, memory_data, memory_ack);
    input clk;
    input rst;
    //----------------
    output cache_ready_out;
    input cache_valid_in;
    input [15:0] cache_addr_in;
    //----------------
    input cache_ready_in;
    output cache_valid_out;
    output [7:0] cache_data_out;
    //----------------
    output memory_stb;
    output [13:0] memory_addr;
    input [31:0] memory_data;
    input memory_ack;

  reg valid_buf;

  wire [8:0] tag;
  wire [4:0] index;
  wire [1:0] offset;

  reg [8:0] tag_buf;
  reg [4:0] index_buf;
  reg [1:0] offset_buf;

  wire sel_index;
  wire [4:0] cur_index;

  wire set_read;

  reg line_0_valid[0:31];
  reg line_0_valid_out;
  reg [8:0] line_0_tag[0:31];
  reg [8:0] line_0_tag_out;
  reg [31:0] line_0_data[0:31];
  reg [31:0] line_0_data_out;
  wire line_0_hit;

  reg line_1_valid[0:31];
  reg line_1_valid_out;
  reg [8:0] line_1_tag[0:31];
  reg [8:0] line_1_tag_out;
  reg [31:0] line_1_data[0:31];
  reg [31:0] line_1_data_out;
  wire line_1_hit;

  wire [31:0] line_data_out;

  wire hit;

  reg lru[0:31];
  reg lru_out;

  reg memory_ack_buf;

  //--------------------------------------------

  assign cache_ready_out = cache_ready_in & (hit | ~valid_buf);

  always @(posedge clk) begin
    if (rst) begin
      valid_buf <= 1'b0;
    end else begin
      if (cache_ready_out) begin
        valid_buf <= cache_valid_in;
      end
    end
  end

  assign cache_valid_out = valid_buf & hit;

  //--------------------------------------------

  assign tag[8:0] = cache_addr_in[15:7];
  assign index[4:0] = cache_addr_in[6:2];
  assign offset[1:0] = cache_addr_in[1:0];

  always @(posedge clk) begin
    if (cache_ready_out) begin
      tag_buf[8:0] <= tag[8:0];
      index_buf[4:0] <= index[4:0];
      offset_buf[1:0] <= offset[1:0];
    end
  end

  assign cur_index[4:0] = sel_index ? index_buf[4:0] : index[4:0];

  assign set_read = cache_ready_out | memory_ack_buf;

  always @(posedge clk) begin
    if (set_read) begin
      line_0_valid_out <= line_0_valid[cur_index];
      line_0_tag_out <= line_0_tag[cur_index];
      line_0_data_out <= line_0_data[cur_index];
    end
    if (memory_ack & ~lru_out) begin
      line_0_valid[cur_index] <= 1'b1;
      line_0_tag[cur_index] <= tag_buf;
      line_0_data[cur_index] <= memory_data;
    end
  end

  assign line_0_hit =
    line_0_valid_out & (line_0_tag_out[8:0] == tag_buf[8:0]);

  always @(posedge clk) begin
    if (set_read) begin
      line_1_valid_out <= line_1_valid[cur_index];
      line_1_tag_out <= line_1_tag[cur_index];
      line_1_data_out <= line_1_data[cur_index];
    end
    if (memory_ack & lru_out) begin
      line_1_valid[cur_index] <= 1'b1;
      line_1_tag[cur_index] <= tag_buf;
      line_1_data[cur_index] <= memory_data;
    end
  end

  assign line_1_hit =
    line_1_valid_out & (line_1_tag_out[8:0] == tag_buf[8:0]);

  assign line_data_out[31:0] =
    line_1_hit ? line_1_data_out[31:0] : line_0_data_out[31:0];

  assign cache_data_out[7:0] =
    ~offset_buf[1] ?
      (~offset_buf[0] ? line_data_out[31:24] : line_data_out[23:16]) :
      (~offset_buf[0] ? line_data_out[15: 8] : line_data_out[ 7: 0]);

  //--------------------------------------------

  assign hit = line_0_hit | line_1_hit;

  //
  // Note: If read address = write address in the same clock cycle,
  //       the LRU memory must read the same value that just gets
  //       written to the common address (and not the old contents).
  //       This is modeled here with blocking assignments. Check
  //       that your synthesizer translates this behavior correctly!
  //
  always @(posedge clk) begin
    if (cache_valid_out) begin
      lru[index_buf] = line_0_hit;
    end
    if (set_read) begin
      lru_out = lru[cur_index];
    end
  end

  //--------------------------------------------

  initial begin
    #705        // line_0
                line_0_valid[0] = 1'b1;
                line_0_tag[0]   = 9'h000;
                line_0_data[0]  = 32'hC0F00FCF;
                line_0_valid[1] = 1'b1;
                line_0_tag[1]   = ~9'h000;
                line_0_data[1]  = ~32'h80F00FDF;
                line_0_valid[2] = 1'b0;
                line_0_tag[2]   = ~9'h144;
                line_0_data[2]  = ~32'h12345676;
                line_0_valid[3] = 1'b0;
                line_0_tag[3]   = 9'h146;
                line_0_data[3]  = 32'h12345675;
                line_0_valid[4] = 1'b0;
                line_0_tag[4]   = ~9'h148;
                line_0_data[4]  = ~32'h12345674;
                line_0_valid[5] = 1'b0;
                line_0_tag[5]   = 9'h14A;
                line_0_data[5]  = 32'h12345673;
                line_0_valid[6] = 1'b0;
                line_0_tag[6]   = 9'h14C;
                line_0_data[6]  = 32'h12345672;
                line_0_valid[7] = 1'b0;
                line_0_tag[7]   = ~9'h14E;
                line_0_data[7]  = ~32'h12345671;
                // line_1
                line_1_valid[0] = 1'b1;
                line_1_tag[0]   = ~9'h000;
                line_1_data[0]  = ~32'hC0F00FCF;
                line_1_valid[1] = 1'b1;
                line_1_tag[1]   = 9'h000;
                line_1_data[1]  = 32'h80F00FDF;
                line_1_valid[2] = 1'b0;
                line_1_tag[2]   = 9'h144;
                line_1_data[2]  = 32'h12345676;
                line_1_valid[3] = 1'b0;
                line_1_tag[3]   = ~9'h146;
                line_1_data[3]  = ~32'h12345675;
                line_1_valid[4] = 1'b0;
                line_1_tag[4]   = 9'h148;
                line_1_data[4]  = 32'h12345674;
                line_1_valid[5] = 1'b0;
                line_1_tag[5]   = ~9'h14A;
                line_1_data[5]  = ~32'h12345673;
                line_1_valid[6] = 1'b0;
                line_1_tag[6]   = ~9'h14C;
                line_1_data[6]  = ~32'h12345672;
                line_1_valid[7] = 1'b0;
                line_1_tag[7]   = 9'h14E;
                line_1_data[7]  = 32'h12345671;
                // lru
                lru[0] = 1'b1;
                lru[1] = 1'b0;
                lru[2] = 1'b0;
                lru[3] = 1'b0;
                lru[4] = 1'b0;
                lru[5] = 1'b1;
                lru[6] = 1'b0;
                lru[7] = 1'b0;
  end

  //--------------------------------------------

  assign memory_stb = ~hit & valid_buf & ~memory_ack_buf;
  assign memory_addr[13:0] = { tag_buf[8:0], index_buf[4:0] };

  always @(posedge clk) begin
    memory_ack_buf <= memory_ack;
  end

  assign sel_index = memory_ack | memory_ack_buf;

endmodule
