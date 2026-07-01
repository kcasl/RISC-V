`timescale 1ns/1ps

`include"riscv_defines.v"

module riscv_alu_tb ();

	// Signals
    reg rstn;
    reg clk;
    reg [3:0] alu_op_i;
    reg [31:0] alu_a_i, alu_b_i;
    wire [31:0] alu_p_o;
    wire [4:0] flcnz;

	// ALU module   
	riscv_alu 
	u_riscv_alu  (
		.alu_a_i(alu_a_i), 
		.alu_b_i(alu_b_i),
		.alu_op_i(alu_op_i),
		.alu_p_o(alu_p_o),
		.flcnz(flcnz)
	);


   // Clock and Reset
   parameter p=10;
   initial
   begin
   	clk = 1'b0;
   	forever #(p/2) clk = !clk;
   end

   initial
   begin
   	rstn = 1'b0;		// negedge reset on
   	#(4*p) rstn = 1'b1;	// negedge reset off
   end

   // Test cases	
   initial
   begin:stimuli
		// Initialization
		alu_a_i = 32'h0;
		alu_b_i = 32'h0; 
		alu_op_i = `ALU_ADD;	   
		
		#(8*p) 	alu_a_i = 32'h0;
				alu_b_i = 32'h0; 
				alu_op_i = `ALU_SLTU;
		
		#(4*p)	alu_a_i = 32'h2020;
				alu_b_i = 32'h2021;
				alu_op_i = `ALU_ADD;	
		#(2*p) 	alu_op_i = `ALU_SUB;
		
		#(2*p) 	alu_op_i = `ALU_AND;	
		#(2*p) 	alu_op_i = `ALU_OR;	
		#(2*p) 	alu_op_i = `ALU_XOR;		
		
		
		//----------------------------------------------------------------------------------------
		// ALU operations
		//----------------------------------------------------------------------------------------
		#(8*p)
			   alu_a_i = 32'h0000_2222;
			   alu_b_i = 32'h0000_2222; 
			   alu_op_i = `ALU_SLTU;	
		#(p)   $display("T=%03t ns: %h < %h : %h (Unsigned)\n",$realtime/1000, alu_a_i, alu_b_i,alu_p_o);
			   
		// Addition
		#(4*p)
			   alu_a_i = 32'h0000_1111;
			   alu_b_i = 32'h0000_1111;
			   alu_op_i = `ALU_ADD;	
		#(p)   $display("T=%03t ns: %h + %h = %h\n",$realtime/1000, alu_a_i, alu_b_i,alu_p_o);
			   
		// Subtraction
		#(2*p) alu_op_i = `ALU_SUB;	
		#(p)   $display("T=%03t ns: %h - %h = %h\n",$realtime/1000, alu_a_i, alu_b_i,alu_p_o);
		
		// Comparison
		#(2*p) alu_op_i = `ALU_SLTU;	
		#(p)   $display("T=%03t ns: %h < %h = %h\n",$realtime/1000, alu_a_i, alu_b_i,alu_p_o);
		
		//----------------------------------------------------------------------------------------
		// Logic operations
		//----------------------------------------------------------------------------------------
		// AND
		#(4*p)
			   alu_a_i = 32'h0000_1110;		
			   alu_b_i = 32'h0000_0111;			   
			   alu_op_i = `ALU_AND;	
		#(p)   $display("T=%03t ns: %h & %h = %h\n",$realtime/1000, alu_a_i, alu_b_i,alu_p_o);
		
		// OR
		#(2*p) alu_op_i = `ALU_OR;	
		#(p)   $display("T=%03t ns: %h | %h = %h\n",$realtime/1000, alu_a_i, alu_b_i,alu_p_o);
		
		// XOR
		#(2*p) alu_op_i = `ALU_XOR;	
		#(p)   $display("T=%03t ns: %h ^ %h = %h\n",$realtime/1000, alu_a_i, alu_b_i,alu_p_o);
		
		
		//----------------------------------------------------------------------------------------
		// Shift operations
		//----------------------------------------------------------------------------------------
		#(4*p)
			   alu_a_i = 32'h0000_1111;
			   alu_b_i = 32'h0000_0001;
			   alu_op_i = `ALU_SLL;	
		#(p)   $display("T=%03t ns: %h << %h = %h\n",$realtime/1000, alu_a_i, alu_b_i,alu_p_o);
		
		#(2*p) alu_op_i = `ALU_SRL;	
		#(p)   $display("T=%03t ns: %h >> %h = %h\n",$realtime/1000, alu_a_i, alu_b_i,alu_p_o);
		
		#(2*p) alu_op_i = `ALU_SRA;	
		#(p)   $display("T=%03t ns: %h >>> %h = %h\n",$realtime/1000, alu_a_i, alu_b_i,alu_p_o);
		
		#(2*p)
			   alu_a_i = 32'h7FFF_FFFF;
			   alu_b_i = 32'hFFFF_FFFF;
		
		#(2*p) alu_op_i = `ALU_SLT;			
		#(p)   $display("T=%03t ns: %h < %h = %h\n",$realtime/1000, alu_a_i, alu_b_i,alu_p_o);
		
		#(2*p) alu_op_i = `ALU_SLTU;	
		#(p)   $display("T=%03t ns: %h < %h = %h (Unsigned)\n",$realtime/1000, alu_a_i, alu_b_i,alu_p_o);
   end

    
endmodule

