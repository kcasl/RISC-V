module inverse_rct 
#(
    parameter IMG_PIX_W  = 8,
              WAVE_PIX_W = 10
)
(
    input clk,
    input rst_n,
    input in_valid,
    input signed [WAVE_PIX_W-1:0] y0, cb0, cr0, 
    input signed [WAVE_PIX_W-1:0] y1, cb1, cr1, 
    //input [WAVE_PIX_W-1:0] y0, cb0, cr0,
    //input [WAVE_PIX_W-1:0] y1, cb1, cr1,
    output reg out_valid,
    output [IMG_PIX_W-1:0] r0, g0, b0,
    output [IMG_PIX_W-1:0] r1, g1, b1
);

/*Signals*/
wire [WAVE_PIX_W-1:0] tmp0;
wire [WAVE_PIX_W-1:0] tmp1;
 reg [WAVE_PIX_W-1:0] r0_tmp;
 reg [WAVE_PIX_W-1:0] g0_tmp;
 reg [WAVE_PIX_W-1:0] b0_tmp;
 reg [WAVE_PIX_W-1:0] r1_tmp;
 reg [WAVE_PIX_W-1:0] g1_tmp;
 reg [WAVE_PIX_W-1:0] b1_tmp;

/*Combinational logic*/
assign tmp0 = y0 - ((cb0 + cr0) >>> 2);
assign tmp1 = y1 - ((cb1 + cr1) >>> 2);

/*Sequential logic*/
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        r0_tmp <= 0;
        g0_tmp <= 0;
        b0_tmp <= 0;
        r1_tmp <= 0;
        g1_tmp <= 0;
        b1_tmp <= 0;
        out_valid <= 0;
    end else begin
        if(in_valid) begin
            r0_tmp <= cr0 + tmp0;
            g0_tmp <= tmp0;
            b0_tmp <= cb0 + tmp0;
            //r1_tmp <= /*Insert your code here*/;
            //g1_tmp <= /*Insert your code here*/;
            //b1_tmp <= /*Insert your code here*/;
            out_valid <= 1;
        end else begin
            r0_tmp <= 0;
            g0_tmp <= 0;
            b0_tmp <= 0;
            r1_tmp <= 0;
            g1_tmp <= 0;
            b1_tmp <= 0;
            out_valid <= 0;
        end
    end
end
assign r0 = (r0_tmp[WAVE_PIX_W-1])? 0 : (r0_tmp[WAVE_PIX_W-2])? 255 : r0_tmp[IMG_PIX_W-1:0];
assign g0 = (g0_tmp[WAVE_PIX_W-1])? 0 : (g0_tmp[WAVE_PIX_W-2])? 255 : g0_tmp[IMG_PIX_W-1:0];
assign b0 = (b0_tmp[WAVE_PIX_W-1])? 0 : (b0_tmp[WAVE_PIX_W-2])? 255 : b0_tmp[IMG_PIX_W-1:0];
assign r1 = (r1_tmp[WAVE_PIX_W-1])? 0 : (r1_tmp[WAVE_PIX_W-2])? 255 : r1_tmp[IMG_PIX_W-1:0];
assign g1 = (g1_tmp[WAVE_PIX_W-1])? 0 : (g1_tmp[WAVE_PIX_W-2])? 255 : g1_tmp[IMG_PIX_W-1:0];
assign b1 = (b1_tmp[WAVE_PIX_W-1])? 0 : (b1_tmp[WAVE_PIX_W-2])? 255 : b1_tmp[IMG_PIX_W-1:0];
endmodule
