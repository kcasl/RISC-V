module counter(clk, din, ena, oflag);
input clk;
input [5:0] din;
input ena;
output reg oflag;
reg [5:0] cnt;

wire run_cnt;
//--------------------------------------------------------------
// Internal counter: cnt
//--------------------------------------------------------------
assign run_cnt = (cnt!=0)?1'b1: 1'b0;	// Check if cnt is zero
										// 1: Not zero, 0: zero
always@(posedge clk) begin
	if(run_cnt)begin
		// Insert your code here
		cnt <= cnt - 1;
	end
	else if (ena) begin
		// Insert your code here
		cnt <= din;
	end
end

//--------------------------------------------------------------
// Output: oflag
//--------------------------------------------------------------
always@(posedge clk) begin
	if(cnt == 1) begin	
		// Insert your code here
		oflag <= 1'b1;
	end
	else begin	
		// Insert your code here
		oflag <= 1'b0;
	end
end

endmodule
