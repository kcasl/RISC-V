module riscv_memory #(
  parameter     SIZE     = 8192,
  parameter     FIRMWARE = "mem.hex"
)(
  input         clk_i,
  input         reset_i,

  input  [31:0] iaddr_i,
  output [31:0] irdata_o,
  input         ird_i,

  input  [31:0] daddr_i,
  input  [31:0] dwdata_i,
  output [31:0] drdata_o,
  input   [1:0] dsize_i,
  input         drd_i,
  input         dwr_i
);

//-----------------------------------------------------------------------------
localparam
  SIZE_BYTE = 2'd0,
  SIZE_HALF = 2'd1,
  SIZE_WORD = 2'd2;

localparam
  DEPTH = $clog2(SIZE);

//-----------------------------------------------------------------------------
reg [1:0] daddr_r;
reg [1:0] dsize_r;
reg [31:0] irdata_r;	//Internal instruction register
reg [31:0] drdata_r;	//Internal data register
//-----------------------------------------------------------------------------
wire [31:0] dwdata_w =
    (SIZE_BYTE == dsize_i) ? {4{dwdata_i[7:0]}} :
    (SIZE_HALF == dsize_i) ? {2{dwdata_i[15:0]}} : dwdata_i;

wire [3:0] dbe_byte_w = 
    (2'b00 == daddr_i[1:0]) ? 4'b0001 :
    (2'b01 == daddr_i[1:0]) ? 4'b0010 :
    (2'b10 == daddr_i[1:0]) ? 4'b0100 : 4'b1000;

wire [3:0] dbe_half_w =
    daddr_i[1] ? 4'b1100 : 4'b0011;

wire [3:0] dbe_w =
    (SIZE_BYTE == dsize_i) ? dbe_byte_w :
    (SIZE_HALF == dsize_i) ? dbe_half_w : 4'b1111;

wire [7:0] rdata_byte_w =
    (2'b00 == daddr_r) ? drdata_r[7:0] :
    (2'b01 == daddr_r) ? drdata_r[15:8] :
    (2'b10 == daddr_r) ? drdata_r[23:16] : drdata_r[31:24];

wire [15:0] rdata_half_w =
    daddr_r[1] ? drdata_r[31:16] : drdata_r[15:0];

assign drdata_o =
    (SIZE_BYTE == dsize_r) ? { 24'b0, rdata_byte_w } :
    (SIZE_HALF == dsize_r) ? { 16'b0, rdata_half_w } : drdata_r;


always @(posedge clk_i) begin
  if (reset_i) begin
    daddr_r <= 2'b00;
    dsize_r <= SIZE_BYTE;
  end else begin
    daddr_r <= daddr_i[1:0];
    dsize_r <= dsize_i;
  end
end

//-----------------------------------------------------------------------------
reg [31:0] mem_r [0:SIZE/4-1];

initial begin
  $readmemh(FIRMWARE, mem_r);
end

//-----------------------------------------------------------------------------
// Instruction memory: READ ONLY
//-----------------------------------------------------------------------------
always @(posedge clk_i) begin
  if (~reset_i)
    irdata_r <= 32'h0;
  else if (ird_i)
    irdata_r <= mem_r[iaddr_i[DEPTH:2]];
end

//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Data memory: READ/WRITE
//-----------------------------------------------------------------------------
// Read operation
always @(posedge clk_i) begin
  if (~reset_i)
    drdata_r <= 32'h0;
  else if (drd_i)
    drdata_r <= mem_r[daddr_i[DEPTH:2]];
end

// Write operation operation
always @(posedge clk_i) begin
  if (dbe_w[0] && dwr_i)
    mem_r[daddr_i[DEPTH:2]][7:0] <= dwdata_w[7:0];

  if (dbe_w[1] && dwr_i)
    mem_r[daddr_i[DEPTH:2]][15:8] <= dwdata_w[15:8];

  if (dbe_w[2] && dwr_i)
    mem_r[daddr_i[DEPTH:2]][23:16] <= dwdata_w[23:16];

  if (dbe_w[3] && dwr_i)
    mem_r[daddr_i[DEPTH:2]][31:24] <= dwdata_w[31:24];
end

//-----------------------------------------------------------------------------
assign irdata_o = irdata_r;

endmodule

