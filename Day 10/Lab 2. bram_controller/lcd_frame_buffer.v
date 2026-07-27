module lcd_frame_buffer(
    clk,
    en,
    addr,
    din,
    we,
    dout,
	addr_dual_pixel,
	dout_dual_pixel
);

	parameter W_DATA = 24;	//R: 0~7, G:8~15, B:16~23
	parameter WIDTH = 768;
	parameter HEIGHT = 512;
	parameter N_WORD = WIDTH * HEIGHT;
	parameter W_WORD = $clog2(N_WORD);	
	
    input                 clk;   			// Clock input
    input                 en;    			// RAM enable (select)
    input  [W_WORD-1:0]   addr;  			// Address input(word addressing) prior to read data by one clock cycle
    input  [W_DATA-1:0]   din;   		 	// Data input
    input                 we;    			// Write enable
    output [W_DATA-1:0]   dout;    			// Data output
	input  [W_WORD-1:0]   addr_dual_pixel;  // Address input(word addressing) prior to read data by one clock cycle
	output [2*W_DATA-1:0]   dout_dual_pixel;  // Data output

	reg [W_DATA-1:0] q_mem[N_WORD-1:0] 		/* synthesis syn_ramstyle="block_ram" */;
	reg [W_DATA-1:0] dout = 32'h0000_0000;

	always @(posedge clk)
	begin
		if(en & we)
			q_mem[addr] <= din;
		else if(en)
			dout <=  q_mem[addr];
	end
	assign dout_dual_pixel = {q_mem[addr_dual_pixel+1],q_mem[addr_dual_pixel]};
endmodule

