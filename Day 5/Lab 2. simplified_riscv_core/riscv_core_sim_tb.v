`timescale 1ns / 100ps
module riscv_core_sim_tb;
reg clk_i;
reg reset_i;
wire        lock;
wire [31:0] iaddr;
wire [31:0] irdata;
wire        ird;
wire [31:0] daddr;
wire [31:0] dwdata;
wire [31:0] drdata;
wire  [1:0] dsize;
wire        drd;
wire        dwr;

riscv_memory #(.FIRMWARE("mem.hex"))
u_riscv_memory
(
  ./*input         */clk_i(clk_i),
  ./*input         */reset_i(reset_i),
  ./*input  [31:0] */iaddr_i(iaddr),
  ./*output [31:0] */irdata_o(irdata),
  ./*input         */ird_i(ird),
  ./*input  [31:0] */daddr_i(daddr),
  ./*input  [31:0] */dwdata_i(dwdata),
  ./*output [31:0] */drdata_o(drdata),
  ./*input   [1:0] */dsize_i(dsize),
  ./*input         */drd_i(drd),
  ./*input         */dwr_i(dwr)
);

riscv_core_sim
u_riscv_core_sim
(
  ./*input         */clk_i(clk_i),
  ./*input         */reset_i(reset_i),
  ./*output        */lock_o(lock),
  ./*output [31:0] */iaddr_o(iaddr),
  ./*input  [31:0] */irdata_i(irdata),
  ./*output        */ird_o(ird),
  ./*output [31:0] */daddr_o(daddr),
  ./*output [31:0] */dwdata_o(dwdata),
  ./*input  [31:0] */drdata_i(drdata),
  ./*output  [1:0] */dsize_o(dsize),
  ./*output        */drd_o(drd),
  ./*output        */dwr_o(dwr)
);
// CLOCK   
initial begin
clk_i = 0;
forever #5 clk_i = ~clk_i; 
end

// Testcase
initial 
begin   
	reset_i = 1'b0;
	
	#20 reset_i = 1'b1;	// Reset

end

endmodule
