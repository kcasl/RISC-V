//-------------------------------------------------
// CAMERA OUTPUT
//-------------------------------------------------
module display_model
#(parameter WIDTH 	= 768,
			HEIGHT 	= 512,
			INFILE  = "output.bmp",
			BMP_HEADER_NUM = 54
)
(
	input HCLK,
	input HRESETn,
	input RECON_VALID,
    input [7:0]  DATA_RECON_R0,
    input [7:0]  DATA_RECON_G0,
    input [7:0]  DATA_RECON_B0,
    input [7:0]  DATA_RECON_R1,
    input [7:0]  DATA_RECON_G1,
    input [7:0]  DATA_RECON_B1,
	output 	reg	 DEC_DONE
);	
localparam FRAME_SIZE_HALF = WIDTH * HEIGHT/2;
//integer BMP_header [0 : BMP_HEADER_NUM - 1];
reg [7:0] BMP_header [0 : BMP_HEADER_NUM - 1];
reg [7:0] out_BMP  [0 : WIDTH*HEIGHT*3 - 1];
reg [18:0] data_count;
wire done;
integer i = 0;
integer k, l, m;
integer fd; 
reg [31:0] IW;
reg [31:0] IH;
initial begin
	IW = WIDTH;
	IH = HEIGHT;
	BMP_header[ 0] = 66;
	BMP_header[ 1] = 77;
	BMP_header[ 2] = 54;
	BMP_header[ 3] =  0;
	BMP_header[ 4] = 18;
	BMP_header[ 5] =  0;
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

// Update the internal buffers. 
always@(posedge HCLK, negedge HRESETn) begin
    if(!HRESETn) begin
        for(k=0;k<WIDTH*HEIGHT*3;k=k+1) begin
            out_BMP[k] <= 0;
        end
    end else begin
        if(RECON_VALID) begin
            out_BMP[WIDTH*3*(HEIGHT-l-1)+6*m+2] <= DATA_RECON_R0;
            out_BMP[WIDTH*3*(HEIGHT-l-1)+6*m+1] <= DATA_RECON_G0;
            out_BMP[WIDTH*3*(HEIGHT-l-1)+6*m  ] <= DATA_RECON_B0;
            out_BMP[WIDTH*3*(HEIGHT-l-1)+6*m+5] <= DATA_RECON_R1;
            out_BMP[WIDTH*3*(HEIGHT-l-1)+6*m+4] <= DATA_RECON_G1;
            out_BMP[WIDTH*3*(HEIGHT-l-1)+6*m+3] <= DATA_RECON_B1;
        end
    end
end
always@(posedge HCLK, negedge HRESETn)
begin
    if(~HRESETn) begin
        data_count <= 0;
    end
    else begin
        if(RECON_VALID)
			data_count <= data_count + 1;
    end
end
assign done = (data_count == FRAME_SIZE_HALF-1)? 1'b1: 1'b0;
always@(posedge HCLK, negedge HRESETn)
begin
    if(~HRESETn) begin
        DEC_DONE <= 0;
    end
    else begin
		DEC_DONE <= done;
    end
end

// Update l
always@(posedge HCLK, negedge HRESETn) begin
    if(!HRESETn) begin
        l <= 0;
        m <= 0;
    end else begin
        if(RECON_VALID) begin
            if(m == WIDTH/2-1) begin
                m <= 0;
                l <= l + 1;
            end else begin
                m <= m + 1;
            end
        end
    end
end

// Write the output file
//{{{
initial begin
    // Open file
    fd = $fopen(INFILE, "wb+");
end

always@(DEC_DONE) begin
    if(DEC_DONE == 1'b1) begin
	// Write header
        for(i=0; i<BMP_HEADER_NUM; i=i+1) begin
            $fwrite(fd, "%c", BMP_header[i][7:0]);
        end

        // Write data
        for(i=0; i<WIDTH*HEIGHT*3; i=i+6) begin
            $fwrite(fd, "%c", out_BMP[i  ][7:0]);
            $fwrite(fd, "%c", out_BMP[i+1][7:0]);
            $fwrite(fd, "%c", out_BMP[i+2][7:0]);
            $fwrite(fd, "%c", out_BMP[i+3][7:0]);
            $fwrite(fd, "%c", out_BMP[i+4][7:0]);
            $fwrite(fd, "%c", out_BMP[i+5][7:0]);
        end
		$fclose(fd);

    end
end
//}}}
endmodule
