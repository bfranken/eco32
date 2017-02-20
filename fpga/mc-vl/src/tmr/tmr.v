//
// tmr.v -- programmable timer
//


`timescale 1ns/10ps
`default_nettype none


module tmr(clk, rst,
           stb, we, addr,
           data_in, data_out,
           ack, irq);
    input clk;
    input rst;
    input stb;
    input we;
    input [3:2] addr;
    input [31:0] data_in;
    output reg [31:0] data_out;
    output ack;
    output irq;

  reg [31:0] counter;
  reg [31:0] divisor;
  reg divisor_loaded;
  reg expired;
  reg alarm;
  reg ien;

  always @(posedge clk) begin
    if (divisor_loaded) begin
      counter <= divisor;
      expired <= 0;
    end else begin
      if (counter == 32'h00000001) begin
        counter <= divisor;
        expired <= 1;
      end else begin
        counter <= counter - 1;
        expired <= 0;
      end
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      divisor <= 32'hFFFFFFFF;
      divisor_loaded <= 1;
      alarm <= 0;
      ien <= 0;
    end else begin
      if (expired) begin
        alarm <= 1;
      end else begin
        if (stb == 1 && we == 1 && addr[3:2] == 2'b00) begin
          // ctrl
          alarm <= data_in[0];
          ien <= data_in[1];
        end
        if (stb == 1 && we == 1 && addr[3:2] == 2'b01) begin
          // divisor
          divisor <= data_in;
          divisor_loaded <= 1;
        end else begin
          divisor_loaded <= 0;
        end
      end
    end
  end

  always @(*) begin
    case (addr[3:2])
      2'b00:
        // ctrl
        data_out = { 28'h0000000, 2'b00, ien, alarm };
      2'b01:
        // divisor
        data_out = divisor;
      2'b10:
        // counter
        data_out = counter;
      2'b11:
        // not used
        data_out = 32'hxxxxxxxx;
      default:
        data_out = 32'hxxxxxxxx;
    endcase
  end

  assign ack = stb;
  assign irq = ien & alarm;

endmodule