`timescale 1ns/1ps

module bmp_image_writer
#(parameter WI = 8,
parameter BMP_HEADER_NUM = 54,
parameter WIDTH 	= 128,
parameter HEIGHT 	= 128,
parameter OUTFILE   = "./out/convout.bmp")(
	input clk,
	input rstn,
	input [WI-1:0] din,
	input vld,
	output reg frame_done
);

// Image parameters
localparam FRAME_SIZE = WIDTH*HEIGHT;
localparam FRAME_SIZE_W = $clog2(FRAME_SIZE);
reg [WI-1:0] out_img[0:FRAME_SIZE-1];	// Output feature map
reg [FRAME_SIZE_W-1:0] pixel_count;
reg [31:0] IW;
reg [31:0] IH;
reg [31:0] SZ;
reg [7:0] BMP_header [0 : BMP_HEADER_NUM - 1];
integer k;
integer fd;
integer i;
integer h, w;
//-------------------------------------------------
// Update the internal buffers.
//-------------------------------------------------
always@(posedge clk, negedge rstn) begin
    if(!rstn) begin
        for(k=0;k<FRAME_SIZE;k=k+1) begin
            out_img[k] <= 0;
        end
		pixel_count <= 0;
		frame_done <= 1'b0;
    end else begin
        if(vld) begin
			if(pixel_count == FRAME_SIZE-1) begin
				pixel_count <= 0;
				frame_done <= 1'b1;
			end
			else begin
				pixel_count <= pixel_count + 1;
			end
            out_img[pixel_count] <= din;
        end
    end
end
//-------------------------------------------------
// Save the output image
//-------------------------------------------------
initial begin
	IW = WIDTH;
	IH = HEIGHT;
	SZ = FRAME_SIZE + BMP_HEADER_NUM;
	BMP_header[ 0] = 66;
	BMP_header[ 1] = 77;
	BMP_header[ 2] = ((SZ & 32'h000000ff) >>  0);
	BMP_header[ 3] = ((SZ & 32'h0000ff00) >>  8);
	BMP_header[ 4] = ((SZ & 32'h00ff0000) >> 16);
	BMP_header[ 5] = ((SZ & 32'hff000000) >> 24);
	BMP_header[ 6] =  0;
	BMP_header[ 7] =  0;
	BMP_header[ 8] =  0;
	BMP_header[ 9] =  0;
	BMP_header[10] = 54;
	BMP_header[11] =  0;
	BMP_header[12] =  0;
	BMP_header[13] =  0;
	BMP_header[14] = 40;
	BMP_header[15] =  0;
	BMP_header[16] =  0;
	BMP_header[17] =  0;
	BMP_header[18] =  ((IW & 32'h000000ff) >>  0);
	BMP_header[19] =  ((IW & 32'h0000ff00) >>  8);
	BMP_header[20] =  ((IW & 32'h00ff0000) >> 16);
	BMP_header[21] =  ((IW & 32'hff000000) >> 24);
	BMP_header[22] =  ((IH & 32'h000000ff) >>  0);
	BMP_header[23] =  ((IH & 32'h0000ff00) >>  8);
	BMP_header[24] =  ((IH & 32'h00ff0000) >> 16);
	BMP_header[25] =  ((IH & 32'hff000000) >> 24);
	BMP_header[26] =  1;
	BMP_header[27] =  0;
	BMP_header[28] = 24;
	BMP_header[29] =  0;
	BMP_header[30] =  0;
	BMP_header[31] =  0;
	BMP_header[32] =  0;
	BMP_header[33] =  0;
	BMP_header[34] =  0;
	BMP_header[35] =  0;
	BMP_header[36] =  0;
	BMP_header[37] =  0;
	BMP_header[38] =  0;
	BMP_header[39] =  0;
	BMP_header[40] =  0;
	BMP_header[41] =  0;
	BMP_header[42] =  0;
	BMP_header[43] =  0;
	BMP_header[44] =  0;
	BMP_header[45] =  0;
	BMP_header[46] =  0;
	BMP_header[47] =  0;
	BMP_header[48] =  0;
	BMP_header[49] =  0;
	BMP_header[50] =  0;
	BMP_header[51] =  0;
	BMP_header[52] =  0;
	BMP_header[53] =  0;
end
// Write the output file
//{{{
initial begin
    // Open file
    fd = $fopen(OUTFILE, "wb+");
	h = 0;
	w = 0;
end

always@(frame_done) begin
    if(frame_done == 1'b1) begin
	// Write header
        for(i=0; i<BMP_HEADER_NUM; i=i+1) begin
            $fwrite(fd, "%c", BMP_header[i][7:0]);
        end

        // Write data
		for(h = 0; h < HEIGHT; h = h + 1) begin
			for(w = 0; w < WIDTH; w = w + 1) begin
				$fwrite(fd, "%c", out_img[(HEIGHT-1-h)*WIDTH + w][7:0]);
				$fwrite(fd, "%c", out_img[(HEIGHT-1-h)*WIDTH + w][7:0]);
				$fwrite(fd, "%c", out_img[(HEIGHT-1-h)*WIDTH + w][7:0]);
			end
		end
		$fclose(fd);

    end
end
//}}}
endmodule
