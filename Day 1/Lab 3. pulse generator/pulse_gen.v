`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module pulse_gen(clk, W);
input clk;
output W;

reg state;
integer count;

initial begin
    state = 0;
    count = 0;
end

assign W = state;

always @ (negedge clk)
begin
    case (state)
    0: begin
        if(count == 29) begin
            count <= 1;
            state <= 1;
        end
        else begin
            count <= count + 1;
        end
      end
    1: begin
        if(count == 43) begin
            count <= 1;
            state <= 0;
        end
        else begin
            count <= count + 1;
        end
    end
    
    endcase
end

endmodule
