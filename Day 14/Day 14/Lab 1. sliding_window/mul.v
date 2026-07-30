module mul 
#(parameter WI = 8, 
parameter WO = 2*WI)(
input [WI-1:0] w,
input [WI-1:0] x,
output[WO-1:0] y
);

assign y = $signed(x) * $signed(w);
endmodule
