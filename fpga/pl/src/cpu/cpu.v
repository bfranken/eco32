//
// cpu.v -- the ECO32 CPU
//


`timescale 1ns/10ps
`default_nettype none


module cpu(clk, rst,
           test_step, test_good, test_ended);
    input clk;				// system clock
    input rst;				// system reset
    output test_step;			// test step completed
    output test_good;			// test step good
    output test_ended;			// test ended

  wire if1b_ready;
  wire if1a_valid;
  wire [9:0] if1a_counter;
  wire if1b_valid;
  wire [31:0] if1b_vaddr;

  wire if2_ready;
  wire if2_valid;
  wire [29:0] if2_paddr;

  //--------------------------------------
  // module instances
  //--------------------------------------

  if1a if1a_1(
    .clk(clk),
    .rst(rst),
    .if1a_ready_in(if1b_ready),
    .if1a_valid_out(if1a_valid),
    .if1a_counter_out(if1a_counter[9:0])
  );

  if1b if1b_1(
    .clk(clk),
    .rst(rst),
    .if1b_ready_out(if1b_ready),
    .if1b_valid_in(if1a_valid),
    .if1b_counter_in(if1a_counter[9:0]),
    .if1b_ready_in(if2_ready),
    .if1b_valid_out(if1b_valid),
    .if1b_vaddr_out(if1b_vaddr[31:0])
  );

  if2 if2_1(
    .clk(clk),
    .rst(rst),
    .if2_ready_out(if2_ready),
    .if2_valid_in(if1b_valid),
    .if2_vaddr_in(if1b_vaddr[31:0]),
    .if2_ready_in(1'b1),
    .if2_valid_out(if2_valid),
    .if2_paddr_out(if2_paddr[29:0])
  );

  //--------------------------------------
  // test signals
  //--------------------------------------

  wire trigger;
  reg delayed_trigger;

  assign trigger = if1b_valid & (if1b_vaddr[31:0] == 32'h6034);

  always @(posedge clk) begin
    if (rst) begin
      delayed_trigger <= 1'b0;
    end else begin
      delayed_trigger <= trigger;
    end
  end

  assign test_step = delayed_trigger;
  assign test_good = if2_valid & (if2_paddr[29:0] == 32'h00005034);
  assign test_ended = if1b_valid & (if1b_vaddr[31:0] == 32'h0000603C);

endmodule
