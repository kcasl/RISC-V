module brightness_adjustment 
#(
    parameter IMG_PIX_W  = 8,
              WAVE_PIX_W = 10
)
(  
    input clk,
    input rst_n,
    input in_valid,
    input mode,
    input [IMG_PIX_W-1:0] value,
    input [IMG_PIX_W-1:0] r0, g0, b0,
    input [IMG_PIX_W-1:0] r1, g1, b1,
    output reg out_valid,
    output reg [IMG_PIX_W-1:0] out_r0, out_g0, out_b0, out_r1, out_g1, out_b1
);

always @(posedge clk, negedge rst_n) begin
    if(~rst_n) begin
        out_valid <= 1'b0;
        out_r0 <= 0;
        out_g0 <= 0;
        out_b0 <= 0;
        out_r1 <= 0;
        out_g1 <= 0;
        out_b1 <= 0;
    end
    else begin
        out_valid <= in_valid;
        if (mode == 1'b1) begin   //brighter
            out_r0 <= ({1'b0, r0} + {1'b0, value} > 255) ? 255 : r0 + value;
            out_g0 <= ({1'b0, g0} + {1'b0, value} > 255) ? 255 : g0 + value;
            out_b0 <= ({1'b0, b0} + {1'b0, value} > 255) ? 255 : b0 + value;
            out_r1 <= ({1'b0, r1} + {1'b0, value} > 255) ? 255 : r1 + value;
            out_g1 <= ({1'b0, g1} + {1'b0, value} > 255) ? 255 : g1 + value;
            out_b1 <= ({1'b0, b1} + {1'b0, value} > 255) ? 255 : b1 + value;
        end
	else begin                //darker
            out_r0 <= (r0 < value) ? 0 : r0 - value;
            out_g0 <= (g0 < value) ? 0 : g0 - value;
            out_b0 <= (b0 < value) ? 0 : b0 - value;
            out_r1 <= (r1 < value) ? 0 : r1 - value;
            out_g1 <= (g1 < value) ? 0 : g1 - value;
            out_b1 <= (b1 < value) ? 0 : b1 - value;
        end
    end
end

endmodule
