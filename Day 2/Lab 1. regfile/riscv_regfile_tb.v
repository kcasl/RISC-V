`timescale 1ns / 100ps

module riscv_regfile_tb;
    
    wire [31:0] ra0_value_o, rb0_value_o;
    reg [4:0] ra0_i, rb0_i;
	reg [4:0] rd0_i;
    reg [31:0] rd0_value_i;
    reg wr, clk, rstn;

	parameter CLOCK_PERIOD = 10;
	// Components
    riscv_regfile u_riscv_regfile
	 ( 	.clk_i(clk),
		.rstn_i(rstn),
		.ra0_i(ra0_i),
		.rb0_i(rb0_i),
		.rd0_i(rd0_i),
		.rd0_value_i(rd0_value_i),
		.wr(wr),
		.ra0_value_o(ra0_value_o), 
		.rb0_value_o(rb0_value_o)
	); 
     
    // CLOCK   
    initial begin
	clk = 0;
    forever #5 clk = ~clk; 
	end
	
	// Testcase
    initial 
        begin       
            rstn = 0;
            ra0_i = 5'b0000; 		// Select R0
            rb0_i = 5'b0001; 		// Select R1
            wr	  = 0;	
            rd0_i = 5'b0001;
            rd0_value_i = 32'h00000000;
            //#2 		rstn = 0;
            #20 	rstn = 1;		// Reset


        ////////// WRITE /////////
            
            ra0_i = 5'b0000; 		// Select R0
            rb0_i = 5'b0001; 		// Select R1
                
            #20 	rd0_value_i = 32'h1234;

            #20 	wr = 1;			// write to R1
                    rd0_i =  5'b0001;
            #10 	wr = 0; 


            #20 	rb0_i = 5'b0111;// Select R7
                    rd0_i =  5'b0111;
            #20 	rd0_value_i = 32'h5678;

            #20 	wr = 1;			// write to R7
            #10 	wr = 0;
        

        ///////////////////////////



        /////////// READ //////////
            
            #20 	ra0_i = 5'b0100;		// Read R4
                    rb0_i = 5'b0101;		// Read R5
                
            #20 	ra0_i = 5'b0111;		// Read R7

            #20 	rb0_i = 5'b0001;		// Read R1

        ////////////////////////////

            #20 
            #20 	rstn = 0;
            #20 	rstn = 1;
                    
        end
        
    
endmodule



