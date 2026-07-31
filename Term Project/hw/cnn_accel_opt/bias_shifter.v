`timescale 1ns/1ps
// Bias Shifter
module bias_shifter(
    d_in,
    n_shift,
    d_out
    );

// Parameter declarations
    parameter DATA_BITS = 48;
    parameter SHIFT_W = 5;
	parameter OUT_DATA_BITS = 48;
// Port declarations
    input [DATA_BITS-1:0] d_in;
    input [SHIFT_W-1:0] n_shift;
    output [OUT_DATA_BITS-1:0] d_out;

// Internel port declarations
    reg [DATA_BITS-1:0] d_out_r;

//-------------------------------------------------
// Main body
//-------------------------------------------------
// NOTE: Use a barrel shifter for further optimization
    always @*
    begin
        // d_out_r <= 'h0;
        case (n_shift)
            'd5 : d_out_r = {{ 5{d_in[DATA_BITS-1]}}, d_in[DATA_BITS-1:5]};
            'd6 : d_out_r = {{ 6{d_in[DATA_BITS-1]}}, d_in[DATA_BITS-1:6]};
            'd7 : d_out_r = {{ 7{d_in[DATA_BITS-1]}}, d_in[DATA_BITS-1:7]};
            'd8 : d_out_r = {{ 8{d_in[DATA_BITS-1]}}, d_in[DATA_BITS-1:8]};
            'd9 : d_out_r = {{ 9{d_in[DATA_BITS-1]}}, d_in[DATA_BITS-1:9]};
            'd10: d_out_r = {{10{d_in[DATA_BITS-1]}}, d_in[DATA_BITS-1:10]};
            'd11: d_out_r = {{11{d_in[DATA_BITS-1]}}, d_in[DATA_BITS-1:11]};
            'd12: d_out_r = {{12{d_in[DATA_BITS-1]}}, d_in[DATA_BITS-1:12]};
            'd13: d_out_r = {{13{d_in[DATA_BITS-1]}}, d_in[DATA_BITS-1:13]};
            'd14: d_out_r = {{14{d_in[DATA_BITS-1]}}, d_in[DATA_BITS-1:14]};
            'd15: d_out_r = {{15{d_in[DATA_BITS-1]}}, d_in[DATA_BITS-1:15]};
            'd16: d_out_r = {{16{d_in[DATA_BITS-1]}}, d_in[DATA_BITS-1:16]};
            'd17: d_out_r = {{17{d_in[DATA_BITS-1]}}, d_in[DATA_BITS-1:17]};
            'd18: d_out_r = {{18{d_in[DATA_BITS-1]}}, d_in[DATA_BITS-1:18]};
            'd19: d_out_r = {{19{d_in[DATA_BITS-1]}}, d_in[DATA_BITS-1:19]};
            'd20: d_out_r = {{20{d_in[DATA_BITS-1]}}, d_in[DATA_BITS-1:20]};
            'd21: d_out_r = {{21{d_in[DATA_BITS-1]}}, d_in[DATA_BITS-1:21]};
            'd22: d_out_r = {{22{d_in[DATA_BITS-1]}}, d_in[DATA_BITS-1:22]};
            'd23: d_out_r = {{23{d_in[DATA_BITS-1]}}, d_in[DATA_BITS-1:23]};
            'd24: d_out_r = {{24{d_in[DATA_BITS-1]}}, d_in[DATA_BITS-1:24]};
            'd25: d_out_r = {{25{d_in[DATA_BITS-1]}}, d_in[DATA_BITS-1:25]};
            default: d_out_r = 'h0;
        endcase
    end

    assign d_out = d_out_r[OUT_DATA_BITS-1:0];

endmodule