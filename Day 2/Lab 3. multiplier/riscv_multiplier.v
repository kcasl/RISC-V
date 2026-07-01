`include "riscv_defines.v"
//-------------------------------------------------------------------------------------------------------
//**** module description begins with “module modulename”
//    : this file descripts the function of module
//-------------------------------------------------------------------------------------------------------

module riscv_multiplier(

//-------------------------------------------------------------------------------------------------------
// **** Input / output ports definition
//     : module input/output could be connected to the other module
//     : Input controlled by designer testbench for simulation.
//     : output monitored by testbench for funtional verification.
//     : clock, reset for synchronous function
//-------------------------------------------------------------------------------------------------------
	input clk_i,
	input rstn_i,
	input [3:0] id_alu_op_r,
	input id_a_signed_r,
	input id_b_signed_r,
	input [31:0] id_ra_value_r, // 32bits multiplicand registser a
	input [31:0] id_rb_value_r, // 32bits multiplier register b
	output [63:0] mul_res_w,	// 64bits multiplier out
	output ex_stall_mul_w
);
	// Signed
	wire mul_negative_w;
	wire [31:0] mul_a_w;
	wire [31:0] mul_b_w;

	assign mul_negative_w = (id_a_signed_r && id_ra_value_r[31]) ^ (id_b_signed_r && id_rb_value_r[31]);
	assign mul_a_w = (id_a_signed_r && id_ra_value_r[31]) ? -id_ra_value_r : id_ra_value_r;
	assign mul_b_w = (id_b_signed_r && id_rb_value_r[31]) ? -id_rb_value_r : id_rb_value_r;

	//-------------------------------------------------------------------------------------------------------
	//*** Multiple sequential adders and shifters
	//-------------------------------------------------------------------------------------------------------
	reg         mul_busy_r;
	reg         mul_ready_r;
	reg   [4:0] mul_count_r; 		//*** 32bit multiplier shift counting 31 down to 0
	reg  [63:0] mul_res_r;          //*** multiplier out 
	wire mul_request_w;
	wire [32:0] mul_sum_w; 
	
	assign mul_sum_w = { 1'b0, mul_res_r[63:32] }  //*** multiplicand a and multipllier b add and shift process 
			+ { 1'b0, mul_res_r[0] ? mul_b_w : 32'h0 }; //*** shift multiplier b, and check b's LSB
														//*** when LSB=1, mul_sum_w gets new adder out 
														//*** when LSB=0, mul_sum_w no value change with previous adder out

	//-------------------------------------------------------------------------------------------------------
	//**** signal assignment for output ports
	//-------------------------------------------------------------------------------------------------------
	assign mul_res_w = mul_negative_w ? -mul_res_r : mul_res_r;

	always @(posedge clk_i or negedge rstn_i) begin						//*** clock based state flows
	  if (~rstn_i) begin
		mul_busy_r  <= 1'b0;
		mul_ready_r <= 1'b0;
		mul_count_r <= 5'd0;
		mul_res_r   <= 64'h0;
	  end else begin
		if (mul_busy_r) begin							    //*** states repeat LSB check - add - shift in sequence during multiplication
		  //Insert your code
		  mul_count_r <= mul_count_r - 5'd1;				//*** counter check for state-end
		  mul_res_r   <= { mul_sum_w, mul_res_r[31:1] };    //*** 64bit width register composed by previous adder result and multiplier b 
															//*** uppper with adder result (or initial multiplicand a), lower with multiplier b
															//*** 1bit shift right per state change

		  if (mul_count_r == 5'd0) begin
			mul_busy_r  <= 1'b0;
			// Insert your code
			mul_busy_r  <= 1'b0;
   			mul_ready_r <= 1'b1;
		  end

		end else if (mul_ready_r) begin        		//*** activating ready signal for 1 clock
		  mul_ready_r <= 1'b0;

		end else if (mul_request_w) begin
		  mul_count_r <= 5'd31;				   		//*** when multiplication requested, set control signals for state
		  mul_busy_r  <= 1'b1;				   		//*** counter value, busy and 64bits internal register
		  // Insert your code
		  mul_res_r <= {32'h0, mul_a_w};		//*** upper 32bits zero and lower 32bit multiplicand a
		end
	  end
	end

	assign mul_request_w  = (`ALU_MULL == id_alu_op_r || `ALU_MULH == id_alu_op_r);
	assign ex_stall_mul_w = mul_request_w && !mul_ready_r;

//-------------------------------------------------------------------------------------------------------
//**** module description ends with “endmodule”
//-------------------------------------------------------------------------------------------------------
endmodule

