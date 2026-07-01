//-------------------------------------------------------------------------------------------------------
//**** module description begins with “module modulename”
//    : this file descripts the function of module
//-------------------------------------------------------------------------------------------------------

`include"riscv_defines.v"

module riscv_alu
(
//-------------------------------------------------------------------------------------------------------
// **** Input / output ports definition
//     : module input/output could be connected to the other module
//     : Input controlled by designer testbench for simulation.
//     : output monitored by testbench for funtional verification.
//     
//-------------------------------------------------------------------------------------------------------
     input  [  3:0]  alu_op_i		  //*** 4bit operation code (opcode)
    ,input  [ 31:0]  alu_a_i          //*** 32bit operand
    ,input  [ 31:0]  alu_b_i 		  //*** 32bit operand

    // Outputs
    ,output [ 31:0]  alu_p_o
	,output reg [4:0]  flcnz
);
//-----------------------------------------------------------------
// Registers
//-----------------------------------------------------------------
reg [31:0]      result_r;

reg [31:16]     shift_right_fill_r;
reg [31:0]      shift_right_1_r;
reg [31:0]      shift_right_2_r;
reg [31:0]      shift_right_4_r;
reg [31:0]      shift_right_8_r;

reg [31:0]      shift_left_1_r;
reg [31:0]      shift_left_2_r;
reg [31:0]      shift_left_4_r;
reg [31:0]      shift_left_8_r;


wire [31:0]     sub_res_w = alu_a_i - alu_b_i;

//-----------------------------------------------------------------
// Flag for exception cases: Homework
//-----------------------------------------------------------------
always @ (alu_op_i or alu_a_i or alu_b_i or sub_res_w)
begin
	flcnz = 5'b0;
	// Insert your code here
	//{{{
	
		
	//}}}
end
//-----------------------------------------------------------------
// ALU
//-----------------------------------------------------------------
always @ (alu_op_i or alu_a_i or alu_b_i or sub_res_w)
begin
    shift_right_fill_r = 16'b0;
    shift_right_1_r = 32'b0;
    shift_right_2_r = 32'b0;
    shift_right_4_r = 32'b0;
    shift_right_8_r = 32'b0;

    shift_left_1_r = 32'b0;
    shift_left_2_r = 32'b0;
    shift_left_4_r = 32'b0;
    shift_left_8_r = 32'b0;

    case (alu_op_i)
       //----------------------------------------------
       // Shift Left Logical
       //----------------------------------------------   
       `ALU_SLL :														//*** shift left operation by 32bit operand b cases (shift left 1 to 31)
       begin
            if (alu_b_i[0] == 1'b1) 									//*** shift left 1, x2
                shift_left_1_r = {alu_a_i[30:0],1'b0};
            else
                shift_left_1_r = alu_a_i;

            if (alu_b_i[1] == 1'b1)										//*** shift left 2(x4), 3(x8) 
                shift_left_2_r = {shift_left_1_r[29:0],2'b00};          //    :(alu_b_i[1:0]== 2'b10 or 2'b11)
            else
                shift_left_2_r = shift_left_1_r;

			// Insert your code here
			//{{{			
            //if (alu_b_i[2] == 1'b1)										//*** shift left 4(x8) to 7(x128) 
            //    shift_left_4_r = /*Insert your code */					//    :(alu_b_i[2:0]== 3'b100 to 3'b111)
            //else
            //    shift_left_4_r = /*Insert your code */

            //if (alu_b_i[3] == 1'b1)
            //    shift_left_8_r = /*Insert your code */					//*** shift left 8 to 15
            //else														//    :(alu_b_i[3:0]== 4'b1000 to 4'b1111 )
            //    shift_left_8_r = /*Insert your code */
			//}}}
            if (alu_b_i[4] == 1'b1)
                result_r = {shift_left_8_r[15:0],16'b0000000000000000}; //*** shift left 16 to 31
            else														//   :(alu_b_i[4:0]== 5'b10000 to 5'b11111 )
                result_r = shift_left_8_r;
       end
       //----------------------------------------------
       // Shift Right Logical and Shift Right arithmetic
       //----------------------------------------------
       `ALU_SRL,`ALU_SRA :
       begin															//*** shift right operation by 32bit operand b cases (shift right 1 to 31)
            // Arithmetic shift? Fill with 1's if MSB set				
            if (alu_a_i[31] == 1'b1 && alu_op_i == `ALU_SRA)			//*** arithmetic shifting moves n bits to the right
                shift_right_fill_r = 16'b1111111111111111;				//    : insert high order sign bit into emtpy bits
            else														//*** logical shift left
                shift_right_fill_r = 16'b0000000000000000;				//    : zero bits inserted at left of words, right bits shifted off end
			
			// Insert your code here
			//{{{
            //if (alu_b_i[0] == 1'b1)
            //    shift_right_1_r = /*Insert your code */
            //else
            //    shift_right_1_r = /*Insert your code */

            //if (alu_b_i[1] == 1'b1)
            //    shift_right_2_r = /*Insert your code */
            //else
            //    shift_right_2_r = /*Insert your code */
			//}}}
			
            if (alu_b_i[2] == 1'b1)
                shift_right_4_r = {shift_right_fill_r[31:28], shift_right_2_r[31:4]};
            else
                shift_right_4_r = shift_right_2_r;

            if (alu_b_i[3] == 1'b1)
                shift_right_8_r = {shift_right_fill_r[31:24], shift_right_4_r[31:8]};
            else
                shift_right_8_r = shift_right_4_r;

            if (alu_b_i[4] == 1'b1)
                result_r = {shift_right_fill_r[31:16], shift_right_8_r[31:16]};
            else
                result_r = shift_right_8_r;
       end       
       //----------------------------------------------
       // Arithmetic
       //----------------------------------------------
       `ALU_ADD : 
       begin
            result_r      = (alu_a_i + alu_b_i);
       end
       `ALU_SUB : 
       begin
            result_r      = sub_res_w;
       end
       //----------------------------------------------
       // Logical
       //----------------------------------------------       
       `ALU_AND : 
       begin
            result_r      = (alu_a_i & alu_b_i);
       end
       `ALU_OR  : 
       begin
            //result_r      = /*Insert your code */
       end
       `ALU_XOR : 
       begin
            //result_r      = /*Insert your code */
       end
       //----------------------------------------------
       // Comparision
       //----------------------------------------------
       `ALU_SLTU : 	// Unsigned number
       begin
            result_r      = (alu_a_i < alu_b_i) ? 32'h1 : 32'h0;
       end
       `ALU_SLT : 	// Signed numbers
       begin
			//Insert your code
			//{{{
            //if (alu_a_i[31] != alu_b_i[31])
            //    result_r  = /*Insert your code */
            //else
            //    result_r  = sub_res_w[31] ? 32'h1 : 32'h0;            
			//}}}
       end       
       default  : 
       begin
            result_r      = alu_a_i;
       end
    endcase
end
	//}}}

//-------------------------------------------------------------------------------------------------------
//**** signal assignment for output ports
//-------------------------------------------------------------------------------------------------------
assign alu_p_o    = result_r;

//-------------------------------------------------------------------------------------------------------
//**** module description ends with “endmodule”
//-------------------------------------------------------------------------------------------------------
endmodule
