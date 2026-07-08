//-------------------------------------------------------------------------------------------------------
//**** module description begins with ¡°module modulename¡±
//    : this file descripts the function of module
//-------------------------------------------------------------------------------------------------------
module riscv_regfile(	 

//-------------------------------------------------------------------------------------------------------
// **** Input / output ports definition
//     : module input/output could be connected to the other module
//     : Input controlled by designer testbench for simulation.
//     : output monitored by testbench for funtional verification.
//     : clock, reset for synchronous function
//-------------------------------------------------------------------------------------------------------
	input  clk_i
    ,input rstn_i

//-------------------------------------------------------------------------------------------------------
// **** register file read operation 
//    : 5bits read address input, 32bits read data output 
// **** register file write operation
//    : 5bits write address and write enable input, 32bits write data input
//-------------------------------------------------------------------------------------------------------
    ,input  [  4:0]  rd0_i             // address to write
    ,input  [ 31:0]  rd0_value_i        // data to write
    ,input  [  4:0]  ra0_i             // address to read
    ,input  [  4:0]  rb0_i             // address to read
	,input   wr                        // write enable signal
    ,output [ 31:0]  ra0_value_o       // read data from address ra0_i
    ,output [ 31:0]  rb0_value_o       // read data from address rb0_i
);

//-------------------------------------------------------------------------------------------------------
//**** internally used registers (called register files) definition
//    : register file consists of 32 x 32bits register
//    : one register is hard-wired zero, as integer ¡°0¡±, so totally 31 registers defined here.  
//-------------------------------------------------------------------------------------------------------
    reg [31:0] reg_r1_q;
    reg [31:0] reg_r2_q;
    reg [31:0] reg_r3_q;
    reg [31:0] reg_r4_q;
    reg [31:0] reg_r5_q;
    reg [31:0] reg_r6_q;
    reg [31:0] reg_r7_q;
    reg [31:0] reg_r8_q;
    reg [31:0] reg_r9_q;
    reg [31:0] reg_r10_q;
    reg [31:0] reg_r11_q;
    reg [31:0] reg_r12_q;
    reg [31:0] reg_r13_q;
    reg [31:0] reg_r14_q;
    reg [31:0] reg_r15_q;
    reg [31:0] reg_r16_q;
    reg [31:0] reg_r17_q;
    reg [31:0] reg_r18_q;
    reg [31:0] reg_r19_q;
    reg [31:0] reg_r20_q;
    reg [31:0] reg_r21_q;
    reg [31:0] reg_r22_q;
    reg [31:0] reg_r23_q;
    reg [31:0] reg_r24_q;
    reg [31:0] reg_r25_q;
    reg [31:0] reg_r26_q;
    reg [31:0] reg_r27_q;
    reg [31:0] reg_r28_q;
    reg [31:0] reg_r29_q;
    reg [31:0] reg_r30_q;
    reg [31:0] reg_r31_q;

//-------------------------------------------------------------------------------------------------------
//**** wire assignments using different names 
// 		: It is good to understand the usages of register file. 
//-------------------------------------------------------------------------------------------------------
    wire [31:0] x0_zero_w; 
    wire [31:0] x1_ra_w  ; 
    wire [31:0] x2_sp_w  ; 
    wire [31:0] x3_gp_w  ; 
    wire [31:0] x4_tp_w  ; 
    wire [31:0] x5_t0_w  ; 
    wire [31:0] x6_t1_w  ; 
    wire [31:0] x7_t2_w  ; 
    wire [31:0] x8_s0_w  ; 
    wire [31:0] x9_s1_w  ; 
    wire [31:0] x10_a0_w ; 
    wire [31:0] x11_a1_w ; 
    wire [31:0] x12_a2_w ; 
    wire [31:0] x13_a3_w ; 
    wire [31:0] x14_a4_w ; 
    wire [31:0] x15_a5_w ; 
    wire [31:0] x16_a6_w ; 
    wire [31:0] x17_a7_w ; 
    wire [31:0] x18_s2_w ; 
    wire [31:0] x19_s3_w ; 
    wire [31:0] x20_s4_w ; 
    wire [31:0] x21_s5_w ; 
    wire [31:0] x22_s6_w ; 
    wire [31:0] x23_s7_w ; 
    wire [31:0] x24_s8_w ; 
    wire [31:0] x25_s9_w ; 
    wire [31:0] x26_s10_w; 
    wire [31:0] x27_s11_w; 
    wire [31:0] x28_t3_w ; 
    wire [31:0] x29_t4_w ; 
    wire [31:0] x30_t5_w ; 
    wire [31:0] x31_t6_w ; 


    assign x0_zero_w = 32'b0;      //*** hard wired zero
    assign x1_ra_w   = reg_r1_q;   //*** return address
    assign x2_sp_w   = reg_r2_q;   //*** stack pointer
    assign x3_gp_w   = reg_r3_q;   //*** global pointer
    assign x4_tp_w   = reg_r4_q;   //*** thread pointer
    assign x5_t0_w   = reg_r5_q;   //*** temporaries
    assign x6_t1_w   = reg_r6_q;
    assign x7_t2_w   = reg_r7_q;
    assign x8_s0_w   = reg_r8_q;   //*** saved registers
    assign x9_s1_w   = reg_r9_q;
    assign x10_a0_w  = reg_r10_q;  //*** function arguments
    assign x11_a1_w  = reg_r11_q;
    assign x12_a2_w  = reg_r12_q;
    assign x13_a3_w  = reg_r13_q;
    assign x14_a4_w  = reg_r14_q;
    assign x15_a5_w  = reg_r15_q;
    assign x16_a6_w  = reg_r16_q;
    assign x17_a7_w  = reg_r17_q;
    assign x18_s2_w  = reg_r18_q;  //*** temporaries (caller saved registers)
    assign x19_s3_w  = reg_r19_q;
    assign x20_s4_w  = reg_r20_q;
    assign x21_s5_w  = reg_r21_q;
    assign x22_s6_w  = reg_r22_q;
    assign x23_s7_w  = reg_r23_q;
    assign x24_s8_w  = reg_r24_q;
    assign x25_s9_w  = reg_r25_q;
    assign x26_s10_w = reg_r26_q;
    assign x27_s11_w = reg_r27_q;
    assign x28_t3_w  = reg_r28_q;   //*** temporaries (caller saved registers)
    assign x29_t4_w  = reg_r29_q;
    assign x30_t5_w  = reg_r30_q;
    assign x31_t6_w  = reg_r31_q;
//-------------------------------------------------------------------------------------------------------
// **** Flop based register File (for simulation)
//     : Synchronous register write back
//     : Description begins with ¡°always @( ¡±
//-------------------------------------------------------------------------------------------------------
always @ (posedge clk_i or negedge rstn_i)
    
//-------------------------------------------------------------------------------------------------------
//**** reset value ¡°0¡± for initialization
//    : all defined registers set to zero when negative enabled reset signal (1 ->0->1)  
//-------------------------------------------------------------------------------------------------------
	if (!rstn_i) begin
        reg_r1_q       <= 32'h00000000;
        reg_r2_q       <= 32'h00000000;
        reg_r3_q       <= 32'h00000000;
		/*Insert your code */
        //reg_r4_q      
        //reg_r5_q       
        //reg_r6_q       
        //reg_r7_q       
		/*******************/
        reg_r8_q       <= 32'h00000000;
        reg_r9_q       <= 32'h00000000;
        reg_r10_q      <= 32'h00000000;
        reg_r11_q      <= 32'h00000000;
        reg_r12_q      <= 32'h00000000;
        reg_r13_q      <= 32'h00000000;
        reg_r14_q      <= 32'h00000000;
        reg_r15_q      <= 32'h00000000;
        reg_r16_q      <= 32'h00000000;
        reg_r17_q      <= 32'h00000000;
        reg_r18_q      <= 32'h00000000;
        reg_r19_q      <= 32'h00000000;
        reg_r20_q      <= 32'h00000000;
        reg_r21_q      <= 32'h00000000;
        reg_r22_q      <= 32'h00000000;
        reg_r23_q      <= 32'h00000000;
        reg_r24_q      <= 32'h00000000;
        reg_r25_q      <= 32'h00000000;
        reg_r26_q      <= 32'h00000000;
        reg_r27_q      <= 32'h00000000;
        reg_r28_q      <= 32'h00000000;
        reg_r29_q      <= 32'h00000000;
        reg_r30_q      <= 32'h00000000;
        reg_r31_q      <= 32'h00000000;		
    end

//-------------------------------------------------------------------------------------------------------
//**** 32 -32bits register read/write function description
//    : write 32bits new data to new address when write enabled 
//-------------------------------------------------------------------------------------------------------
    else begin 
		if(wr) begin
			if      (rd0_i == 5'd1) reg_r1_q <= rd0_value_i;    
			if      (rd0_i == 5'd2) reg_r2_q <= rd0_value_i;
			if      (rd0_i == 5'd3) reg_r3_q <= rd0_value_i;
			if      (rd0_i == 5'd4) reg_r4_q <= rd0_value_i;
			if      (rd0_i == 5'd5) reg_r5_q <= rd0_value_i;
			if      (rd0_i == 5'd6) reg_r6_q <= rd0_value_i;
			if      (rd0_i == 5'd7) reg_r7_q <= rd0_value_i;
			if      (rd0_i == 5'd8) reg_r8_q <= rd0_value_i;
			if      (rd0_i == 5'd9) reg_r9_q <= rd0_value_i;
			if      (rd0_i == 5'd10) reg_r10_q <= rd0_value_i;
			if      (rd0_i == 5'd11) reg_r11_q <= rd0_value_i;
			if      (rd0_i == 5'd12) reg_r12_q <= rd0_value_i;
			if      (rd0_i == 5'd13) reg_r13_q <= rd0_value_i;
			if      (rd0_i == 5'd14) reg_r14_q <= rd0_value_i;
			if      (rd0_i == 5'd15) reg_r15_q <= rd0_value_i;
			/*Insert your code */
			//if      (rd0_i == 5'd16) 
			//if      (rd0_i == 5'd17) 
			//if      (rd0_i == 5'd18) 
			//if      (rd0_i == 5'd19) 
			/*******************/
			if      (rd0_i == 5'd20) reg_r20_q <= rd0_value_i;
			if      (rd0_i == 5'd21) reg_r21_q <= rd0_value_i;
			if      (rd0_i == 5'd22) reg_r22_q <= rd0_value_i;
			if      (rd0_i == 5'd23) reg_r23_q <= rd0_value_i;
			if      (rd0_i == 5'd24) reg_r24_q <= rd0_value_i;
			if      (rd0_i == 5'd25) reg_r25_q <= rd0_value_i;
			if      (rd0_i == 5'd26) reg_r26_q <= rd0_value_i;
			if      (rd0_i == 5'd27) reg_r27_q <= rd0_value_i;
			if      (rd0_i == 5'd28) reg_r28_q <= rd0_value_i;
			if      (rd0_i == 5'd29) reg_r29_q <= rd0_value_i;
			if      (rd0_i == 5'd30) reg_r30_q <= rd0_value_i;
			if      (rd0_i == 5'd31) reg_r31_q <= rd0_value_i;		
		end
    end

//-------------------------------------------------------------------------------------------------------
//**** 32 -32bits register files read/write function description
//    : asynchronous read by given read adress
//    : default value set to zero
//-------------------------------------------------------------------------------------------------------

    reg [31:0] ra0_value_r;
    reg [31:0] rb0_value_r;
    always @ *
    begin
        case (ra0_i)                  	//**** check the case of address
										//    : case statement
        5'd1: ra0_value_r = reg_r1_q;  //**** assign data according to the address
        5'd2: ra0_value_r = reg_r2_q;
        5'd3: ra0_value_r = reg_r3_q;
        5'd4: ra0_value_r = reg_r4_q;
        5'd5: ra0_value_r = reg_r5_q;
        5'd6: ra0_value_r = reg_r6_q;
        5'd7: ra0_value_r = reg_r7_q;
        5'd8: ra0_value_r = reg_r8_q;
        5'd9: ra0_value_r = reg_r9_q;
		/*Insert your code */
        //5'd10: 
        //5'd11:
        //5'd12: 
        //5'd13: 
		/*******************/
        5'd14: ra0_value_r = reg_r14_q;
        5'd15: ra0_value_r = reg_r15_q;
        5'd16: ra0_value_r = reg_r16_q;
        5'd17: ra0_value_r = reg_r17_q;
        5'd18: ra0_value_r = reg_r18_q;
        5'd19: ra0_value_r = reg_r19_q;
        5'd20: ra0_value_r = reg_r20_q;
        5'd21: ra0_value_r = reg_r21_q;
        5'd22: ra0_value_r = reg_r22_q;
        5'd23: ra0_value_r = reg_r23_q;
        5'd24: ra0_value_r = reg_r24_q;
        5'd25: ra0_value_r = reg_r25_q;
        5'd26: ra0_value_r = reg_r26_q;
        5'd27: ra0_value_r = reg_r27_q;
        5'd28: ra0_value_r = reg_r28_q;
        5'd29: ra0_value_r = reg_r29_q;
        5'd30: ra0_value_r = reg_r30_q;
        5'd31: ra0_value_r = reg_r31_q;		
        default : ra0_value_r = 32'h00000000;
        endcase                            //**** ends with endcase

//-------------------------------------------------------------------------------------------------------
//**** 32 -32bits register file read/write function description
//   : read data outputs are changing according to read adress
//------------------------------------------------------------------------------------------------------- 
        case (rb0_i)
        5'd1: rb0_value_r = reg_r1_q;
        5'd2: rb0_value_r = reg_r2_q;
        5'd3: rb0_value_r = reg_r3_q;
        5'd4: rb0_value_r = reg_r4_q;
        5'd5: rb0_value_r = reg_r5_q;
        5'd6: rb0_value_r = reg_r6_q;
		/*Insert your code */
        //5'd7: 
        //5'd8: 
        //5'd9:
        //5'd10: 
		/*******************/
        5'd11: rb0_value_r = reg_r11_q;
        5'd12: rb0_value_r = reg_r12_q;
        5'd13: rb0_value_r = reg_r13_q;
        5'd14: rb0_value_r = reg_r14_q;
        5'd15: rb0_value_r = reg_r15_q;
        5'd16: rb0_value_r = reg_r16_q;
        5'd17: rb0_value_r = reg_r17_q;
        5'd18: rb0_value_r = reg_r18_q;
        5'd19: rb0_value_r = reg_r19_q;
        5'd20: rb0_value_r = reg_r20_q;
        5'd21: rb0_value_r = reg_r21_q;
        5'd22: rb0_value_r = reg_r22_q;
        5'd23: rb0_value_r = reg_r23_q;
        5'd24: rb0_value_r = reg_r24_q;
        5'd25: rb0_value_r = reg_r25_q;
        5'd26: rb0_value_r = reg_r26_q;
        5'd27: rb0_value_r = reg_r27_q;
        5'd28: rb0_value_r = reg_r28_q;
        5'd29: rb0_value_r = reg_r29_q;
        5'd30: rb0_value_r = reg_r30_q;
        5'd31: rb0_value_r = reg_r31_q;	
        default : rb0_value_r = 32'h00000000;
        endcase
    end


//-------------------------------------------------------------------------------------------------------
//**** signal assignment for output ports
//-------------------------------------------------------------------------------------------------------
    assign ra0_value_o = ra0_value_r;
    assign rb0_value_o = rb0_value_r;

//-------------------------------------------------------------------------------------------------------
//**** module description ends with ¡°endmodule¡±
//-------------------------------------------------------------------------------------------------------
endmodule

