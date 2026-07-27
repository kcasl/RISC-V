module bram(
    clk,	// Clock input
    en,     // RAM enable (select)
    addr,   // Address input(word addressing)
    din,    // Data input
    we,     // Write enable
    dout    // Data output
);

	parameter W_DATA = 32;
	//RAM cell size(# of words)
	parameter N_WORD = 16;
	parameter W_WORD = 4;	
	parameter EN_LOAD_INIT_FILE = 1'b0;
	parameter INIT_FILE = "img/kodim03_32bit.hex";
	
    input                 clk;   // Clock input
    input                 en;    // RAM enable (select)
    input  [W_WORD-1:0]   addr;  // Address input(word addressing) prior to read data by one clock cycle
    input  [W_DATA-1:0]   din;   // Data input
    input                 we;    // Write enable
    output [W_DATA-1:0]   dout;  // Data output

	reg [W_DATA-1:0] q_mem[N_WORD-1:0] /* synthesis syn_ramstyle="block_ram" */;
	reg [W_DATA-1:0] dout = 32'h0000_0000;

	always @(posedge clk)
	begin
		if(en & we)
			q_mem[addr] <= din;
		else if(en)
			dout <=  q_mem[addr];
	end
	
	// synopsys translate_off
	initial
	begin
		if(EN_LOAD_INIT_FILE)
		begin
			$readmemh(INIT_FILE, q_mem);
		end
	end		
	// synopsys translate_on	
endmodule

