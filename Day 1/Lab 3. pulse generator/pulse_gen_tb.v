`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

`define CLOCK_PERIOD 10		//100MHz
// define CLOCK_PERIOD correctly

module pulse_gen_tb();

reg clk;
wire W;

pulse_gen u_pulse_gen
(
.clk(clk),
.W(W)
);

initial begin
clk = 0;
end

always #(`CLOCK_PERIOD/2) clk = ~clk;

endmodule