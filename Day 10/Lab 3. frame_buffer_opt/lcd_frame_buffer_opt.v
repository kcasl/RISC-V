module lcd_frame_buffer_opt(
    clk,
    en,
    addr,
    din,
    we,
    dout,
	addr_dual_pixel,
	dout_dual_pixel
);
	parameter WAVE_PIX_W = 10;
	parameter W_DATA = 4*WAVE_PIX_W; // Y0: 9~0, Y1: 19~20, U:29:20, V: 39:30
	parameter WIDTH = 768;
	parameter HEIGHT = 512;
	parameter N_WORD = WIDTH * HEIGHT/2;
	parameter W_WORD = $clog2(N_WORD);	
	
    input                 clk;   			// Clock input
    input                 en;    			// RAM enable (select)
    input  [W_WORD-1:0]   addr;  			// Address input(word addressing) prior to read data by one clock cycle
    input  [W_DATA-1:0]   din;   		 	// Data input
    input                 we;    			// Write enable
    output [W_DATA-1:0]   dout;    			// Data output
	input  [W_WORD-1:0]   addr_dual_pixel;  // Address input(word addressing) prior to read data by one clock cycle
	output [W_DATA-1:0]   dout_dual_pixel;  // Data output

	reg [W_DATA-1:0] q_mem[N_WORD-1:0] 		/* synthesis syn_ramstyle="block_ram" */;
	reg [W_DATA-1:0] dout = 0;

	always @(posedge clk)
	begin
		if(en & we)
			q_mem[addr] <= din;
		else if(en)
			dout <=  q_mem[addr];
	end
	assign dout_dual_pixel = q_mem[addr_dual_pixel];
endmodule

