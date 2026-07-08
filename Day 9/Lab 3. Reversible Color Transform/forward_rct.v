module forward_rct 
#(
    parameter IMG_PIX_W  = 8,
              WAVE_PIX_W = 10
)
(  
    input clk,
    input rst_n,
    input in_valid,
    input [IMG_PIX_W-1:0] r0, g0, b0,
    input [IMG_PIX_W-1:0] r1, g1, b1,
    output reg out_valid,
    output reg [WAVE_PIX_W-1:0] y0, y1, cb0, cr0
);

/*Signals*/
wire [WAVE_PIX_W-1:0] tmp_y0 = {2'b00, r0} + {1'b0, g0,1'b0} + {2'b00, b0};//r0 + (g0<<<1) + b0
wire [WAVE_PIX_W-1:0] tmp_y1 = {2'b00, r1} + {1'b0, g1,1'b0} + {2'b00, b1};//r1 + (g1<<<1) + b1
wire [WAVE_PIX_W-1:0] tmp_cb = {2'b00, b0} - {2'b00, g0};//b0-g0
wire [WAVE_PIX_W-1:0] tmp_cr = {2'b00, r0} - {2'b00, g0};//r0-g0
/*Sequential logic*/
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        y0  <= 0;
        y1  <= 0;
        cb0 <= 0;
        cr0 <= 0;
        out_valid <= 0;
    end else begin
        if(in_valid) begin
            y0  <= {2'b0,tmp_y0[9:2]};
            //y1  <= /*Insert your code here*/;
            cb0 <= tmp_cb;
            //cr0 <= /*Insert your code here*/;
            out_valid <= 1;
        end else begin
            y0  <= 0;
            y1  <= 0;
            cb0 <= 0;
            cr0 <= 0;
            out_valid <= 0;
        end
    end
end

endmodule
