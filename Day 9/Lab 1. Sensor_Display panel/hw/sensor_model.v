module sensor_model
#(parameter WIDTH 	= 768,
			HEIGHT 	= 512,
			INFILE  = "./img/kodim03.hex",
			START_UP_DELAY = 100,
			VSYNC_CYCLE	= 3,
			VSYNC_DELAY = 3,
			HSYNC_DELAY = 160,
			FRAME_TRANS_DELAY = 200,
			BMP_HEADER_NUM = 54
)
(
	input HCLK,
	input HRESETn,
	output reg VSYNC,
	output reg HSYNC,
    output reg [7:0]  DATA_R0,
    output reg [7:0]  DATA_G0,
    output reg [7:0]  DATA_B0,
    output reg [7:0]  DATA_R1,
    output reg [7:0]  DATA_G1,
    output reg [7:0]  DATA_B1,
	output			  ctrl_done
);			
//-------------------------------------------------
// Internal Signals
//-------------------------------------------------
//{{{
localparam sizeOfWidth = 8;
//localparam sizeOfLengthReal = 1179702; 					//BMP : 1179702: 512 * 768 *3 +54
localparam sizeOfLengthReal = WIDTH * HEIGHT * 3; 					//BMP : 1179702: 512 * 768 *3 +54
localparam sizeOfLengthReal_frame = sizeOfLengthReal; 	// * `FRAME_NUMBER;
localparam		ST_IDLE 	= 2'b00,
				ST_VSYNC	= 2'b01,
				ST_HSYNC	= 2'b10,
				ST_DATA		= 2'b11;
reg [1:0] cstate, nstate;				
reg start;
reg HRESETn_d;
reg 		ctrl_vsync_run;
reg [8:0]	ctrl_vsync_cnt;
reg 		ctrl_hsync_run;
reg [8:0]	ctrl_hsync_cnt;
reg 		ctrl_data_run;
//reg [31 : 0]                in_memory    [0 : sizeOfLengthReal_frame/4];
reg [sizeOfWidth - 1 : 0]   total_memory [0 : sizeOfLengthReal_frame - 1];


integer BMP_header [0 : BMP_HEADER_NUM - 1];
integer temp_BMP   [0 : WIDTH*HEIGHT*3 - 1]; 
//integer data_R [0 : WIDTH*HEIGHT - 1];
//integer data_G [0 : WIDTH*HEIGHT - 1];
//integer data_B [0 : WIDTH*HEIGHT - 1];
integer org_R  [0 : WIDTH*HEIGHT + 10];
integer org_G  [0 : WIDTH*HEIGHT + 10];
integer org_B  [0 : WIDTH*HEIGHT + 10];
integer i, j;
reg [ 9:0] row;
reg [10:0] col;
reg [18:0] data_count;
//}}}
//-------------------------------------------------
// Input processing
//-------------------------------------------------
//{{{

// Read the input file to memory
initial begin
	$readmemh(INFILE, total_memory,0,sizeOfLengthReal_frame-1);
end
// Parse the input pixels
always@(start) begin
    if(start == 1'b1) begin
        for(i=0; i<WIDTH*HEIGHT*3 ; i=i+1) begin
            temp_BMP[i] = total_memory[i]; //read bmp format image
        end

        for(i=0; i<HEIGHT; i=i+1) begin
            for(j=0; j<WIDTH; j=j+1) begin
				org_R[WIDTH*i+j] = temp_BMP[WIDTH*3*(HEIGHT-i-1)+3*j+0];
				org_G[WIDTH*i+j] = temp_BMP[WIDTH*3*(HEIGHT-i-1)+3*j+1];
				/* Insert your code here */           
				//org_B[] = ;
                /*************************/			
            end
        end
    end
end

// Start signal
always@(posedge HCLK, negedge HRESETn)
begin
    if(!HRESETn) begin
        start <= 0;
	HRESETn_d <= 0;
    end
    else begin
        HRESETn_d <= HRESETn;
        if(HRESETn == 1'b1 && HRESETn_d == 1'b0)
            start <= 1'b1;
        else
            start <= 1'b0;
    end
end
//}}}
//-------------------------------------------------
// Input processing
//-------------------------------------------------
always@(posedge HCLK, negedge HRESETn)
begin
    if(~HRESETn) begin
        cstate <= ST_IDLE;
    end
    else begin
        cstate <= nstate;
    end
end
always @(*) begin
    case(cstate)
	ST_IDLE: begin
                if(start)
                    nstate = ST_VSYNC;
                else
                    nstate = ST_IDLE;
        end		
        ST_VSYNC: begin
                if(ctrl_vsync_cnt == START_UP_DELAY) 
                    nstate = ST_HSYNC;
                else
                    nstate = ST_VSYNC;
        end	
        ST_HSYNC: begin
                //if(ctrl_hsync_cnt == /* Insert your code here */) 
                //    nstate = /* Insert your code here */;
                //else
                //    nstate = ST_HSYNC;
        end		
        ST_DATA: begin
                if(ctrl_done) begin   //end of frame
					//nstate = /* Insert your code here */;
				end
                else begin
                    if(col == WIDTH - 2)    //end of line
                        nstate = ST_HSYNC;
                    else
                        nstate = ST_DATA;
                    end
        end
        default: nstate = ST_IDLE;
    endcase
end
always @(*) begin
	ctrl_vsync_run = 0;
	ctrl_hsync_run = 0;
	ctrl_data_run  = 0;
	case(cstate)
		ST_VSYNC: 	begin ctrl_vsync_run = 1; end
		ST_HSYNC: 	begin ctrl_hsync_run = 1; end
		ST_DATA: 	begin ctrl_data_run  = 1; end
	endcase
end
always@(posedge HCLK, negedge HRESETn)
begin
    if(~HRESETn) begin
        ctrl_vsync_cnt <= 0;
		ctrl_hsync_cnt <= 0;
    end
    else begin
        if(ctrl_vsync_run)
			ctrl_vsync_cnt <= ctrl_vsync_cnt + 1;
		else 
			ctrl_vsync_cnt <= 0;
			
        if(ctrl_hsync_run)
			ctrl_hsync_cnt <= ctrl_hsync_cnt + 1;			
		else
			ctrl_hsync_cnt <= 0;
    end
end
always@(posedge HCLK, negedge HRESETn)
begin
    if(~HRESETn) begin
        row <= 0;
		col <= 0;
    end
	else begin
		if(ctrl_data_run) begin
			if(col == WIDTH - 2) begin
				row <= row + 1;
			end
			if(col == WIDTH - 2) 
				col <= 0;
			else 
				col <= col + 2;
		end
	end
end
always@(posedge HCLK, negedge HRESETn)
begin
    if(~HRESETn) begin
        data_count <= 0;
    end
    else begin
        if(ctrl_data_run)
			data_count <= data_count + 1;
    end
end
assign ctrl_done = (data_count == 196607)? 1'b1: 1'b0;


// Output
always @(*) begin
    VSYNC   = 1'b0;
    HSYNC   = 1'b0;
    DATA_R0 = 0;
    DATA_G0 = 0;
    DATA_B0 = 0;                                       
    DATA_R1 = 0;
    DATA_G1 = 0;
    DATA_B1 = 0;                                         
    if(ctrl_data_run) begin
        VSYNC   = 1'b0;
        HSYNC   = 1'b1;
        DATA_R0 = org_R[WIDTH * row + col   ];
        DATA_G0 = org_G[WIDTH * row + col   ];
        /* Insert your code here */
        //DATA_B0 ;                                         
        DATA_R1 = org_R[WIDTH * row + col +1];
        DATA_G1 = org_G[WIDTH * row + col +1];
        /* Insert your code here */
        //DATA_B1 ;                             	
        end
end


endmodule
