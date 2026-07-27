`include "amba_ahb_h.v"

module lcd_drive_if #(
	parameter INFILE  = "./img/kodim03.hex",
	parameter W_ADDR = 32,
	parameter W_DATA = 32,
	parameter WB_DATA = 4,
	parameter W_WB_DATA = 2,
	parameter W_CNT = 16,	
	parameter DEF_HPROT = {`PROT_NOTCACHE, 
	`PROT_UNBUF, `PROT_USER, `PROT_DATA},
	parameter IMG_PIX_W = 8,
	parameter WAVE_PIX_W = 10,
	parameter BMP_HEADER_NUM = 54)
(
	//CLOCK
	HCLK,
	HRESETn,
	//input signals of control port(slave)
	sl_HREADY,
	sl_HSEL,
	sl_HTRANS,
	sl_HBURST,
	sl_HSIZE,
	sl_HADDR,
	sl_HWRITE,
	sl_HWDATA,
	//output signals of control port(slave)
	out_sl_HREADY,				
	out_sl_HRESP,
	out_sl_HRDATA,
	//LCD Drive
    out_valid,
    out_r0, out_g0, out_b0, out_r1, out_g1, out_b1	
);
//CLOCK
input HCLK;
input HRESETn;
//input signals of control port(slave)
input sl_HREADY;
input sl_HSEL;
input [`W_TRANS-1:0] sl_HTRANS;
input [`W_BURST-1:0] sl_HBURST;
input [`W_SIZE-1:0] sl_HSIZE;
input [W_ADDR-1:0] sl_HADDR;
input sl_HWRITE;
input [W_DATA-1:0] sl_HWDATA;
//output signals of control port(slave)
output out_sl_HREADY;				
output [`W_RESP-1:0] out_sl_HRESP;
output reg [W_DATA-1:0] out_sl_HRDATA;

output  out_valid;
output  [IMG_PIX_W-1:0] out_r0, out_g0, out_b0, out_r1, out_g1, out_b1;
//-----------------------------------------------------------------
// Registers
//-----------------------------------------------------------------
parameter WIDTH 	= 768,
		HEIGHT 	= 512,
		START_UP_DELAY = 100,
		VSYNC_CYCLE	= 3,
		VSYNC_DELAY = 3,
		HSYNC_DELAY = 160,
		FRAME_TRANS_DELAY = 200,
		DATA_COUNT = WIDTH * HEIGHT/2;
localparam W_SIZE  = 12;						// Max 4K QHD (3840x1920).
localparam W_FRAME_SIZE  = 2 * W_SIZE + 1;		// Max 4K QHD (3840x1920).
localparam W_DELAY = 12;
			
localparam N_REGS = 11;
localparam W_REGS = 4;

localparam LCD_DRIVE_WIDTH 				= 0;
localparam LCD_DRIVE_HEIGHT 			= 1;
localparam LCD_DRIVE_START_UP_DELAY		= 2;
localparam LCD_DRIVE_VSYNC_CYCLE		= 3;
localparam LCD_DRIVE_VSYNC_DELAY		= 4;
localparam LCD_DRIVE_HSYNC_DELAY		= 5;
localparam LCD_DRIVE_FRAME_TRANS_DELAY	= 6;
localparam LCD_DRIVE_DATA_COUNT			= 7;
localparam LCD_DRIVE_START				= 8;
localparam LCD_DRIVE_BR_MODE			= 9;
localparam LCD_DRIVE_BR_VALUE			= 10;

localparam		ST_IDLE 	= 2'b00,
				ST_VSYNC	= 2'b01,
				ST_HSYNC	= 2'b10,
				ST_DATA		= 2'b11;
reg [1:0] cstate, nstate;	

reg [W_REGS-1:0] q_sel_sl_reg;
reg q_ld_sl_reg;

reg [W_SIZE-1 :0] q_width;
reg [W_SIZE-1 :0] q_height;
reg [W_DELAY-1:0] q_start_up_delay;
reg [W_DELAY-1:0] q_vsync_cycle;
reg [W_DELAY-1:0] q_vsync_delay;
reg [W_DELAY-1:0] q_hsync_delay;
reg [W_DELAY-1:0] q_frame_trans_delay;
reg [W_FRAME_SIZE-1:0] q_data_count;
reg q_br_mode;
reg [IMG_PIX_W-1:0] q_br_value;
reg q_start;

reg 				ctrl_vsync_run;
reg [W_DELAY-1:0]	ctrl_vsync_cnt;
reg 				ctrl_hsync_run;
reg [W_DELAY-1:0]	ctrl_hsync_cnt;
reg 				ctrl_data_run;
reg [W_SIZE-1:0] 	row;
reg [W_SIZE-1:0] 	col;
reg [W_FRAME_SIZE-1:0] data_count;
wire end_frame;

reg VSYNC;
reg HSYNC;
reg [7:0]  DATA_R0;
reg [7:0]  DATA_G0;
reg [7:0]  DATA_B0;
reg [7:0]  DATA_R1;
reg [7:0]  DATA_G1;
reg [7:0]  DATA_B1;
//----------------------------------------------------------
// Decode Stage: Address Phase
//----------------------------------------------------------
always @(posedge HCLK or negedge HRESETn)
begin
	if(~HRESETn)
	begin
		//control
		q_sel_sl_reg <= 0;
		q_ld_sl_reg <= 1'b0;
	end	
	else begin
		if(sl_HSEL && sl_HREADY && ((sl_HTRANS == `TRANS_NONSEQ) || (sl_HTRANS == `TRANS_SEQ)))
		begin
			q_sel_sl_reg <= sl_HADDR[W_REGS+W_WB_DATA-1:W_WB_DATA];
			q_ld_sl_reg <= sl_HWRITE;
		end
		else begin
			q_ld_sl_reg <= 1'b0;
		end
	end
end	
//----------------------------------------------------------
// Decode Stage: Data Phase
//----------------------------------------------------------
always @(posedge HCLK or negedge HRESETn)
begin
	if(~HRESETn)
	begin
		//control
		q_width 			<= WIDTH;
		q_height 			<= HEIGHT;
		q_start_up_delay 	<= START_UP_DELAY;
		q_vsync_cycle 		<= VSYNC_CYCLE;
		q_vsync_delay 		<= VSYNC_DELAY;
		q_hsync_delay 		<= HSYNC_DELAY;
		q_frame_trans_delay <= FRAME_TRANS_DELAY;
		q_data_count 		<= DATA_COUNT;
		q_br_mode			<= 1'b0;
		q_br_value			<= 8'h0;
		q_start 			<= 1'b0;
	end 
	else begin
		//data-transfer state(data phase)
		if(q_ld_sl_reg)
		begin
			case(q_sel_sl_reg)
				LCD_DRIVE_WIDTH: 	begin 
					q_width <= sl_HWDATA[W_SIZE-1 :0];
				end 
				LCD_DRIVE_HEIGHT: begin 
					/* Insert your code */
				end
				LCD_DRIVE_START_UP_DELAY: begin 
					q_start_up_delay <= sl_HWDATA[W_DELAY-1 :0];	
				end
				LCD_DRIVE_VSYNC_CYCLE: begin 
					q_vsync_cycle <= sl_HWDATA[W_DELAY-1 :0];	
				end
				LCD_DRIVE_VSYNC_DELAY: begin 
					q_vsync_delay <= sl_HWDATA[W_DELAY-1 :0];	
				end
				LCD_DRIVE_HSYNC_DELAY: begin 
					q_hsync_delay <= sl_HWDATA[W_DELAY-1 :0];	
				end
				LCD_DRIVE_FRAME_TRANS_DELAY: begin 
					q_frame_trans_delay <= sl_HWDATA[W_DELAY-1 :0];	
				end
				LCD_DRIVE_DATA_COUNT: begin 
					/* Insert your code */
				end
				LCD_DRIVE_START: begin 
					/* Insert your code */
				end
				LCD_DRIVE_BR_MODE: begin 
					/* Insert your code */
				end
				LCD_DRIVE_BR_VALUE: begin 
					/* Insert your code */
				end
			endcase
		end
	end
end

assign out_sl_HREADY = 1'b1;
assign out_sl_HRESP = `RESP_OKAY;
always @*
begin:rdata
	out_sl_HRDATA = 32'h0;
	case(q_sel_sl_reg)
		LCD_DRIVE_WIDTH:   begin 
			out_sl_HRDATA = q_width;
		end
		LCD_DRIVE_HEIGHT: begin 
			/* Insert your code */
		end
		LCD_DRIVE_START_UP_DELAY: begin 
			out_sl_HRDATA = q_start_up_delay;
		end
		LCD_DRIVE_VSYNC_CYCLE: begin 
			out_sl_HRDATA = q_vsync_cycle;
		end
		LCD_DRIVE_VSYNC_DELAY: begin 
			out_sl_HRDATA = q_vsync_delay;
		end
		LCD_DRIVE_HSYNC_DELAY: begin 
			out_sl_HRDATA = q_hsync_delay;
		end
		LCD_DRIVE_FRAME_TRANS_DELAY: begin 
			out_sl_HRDATA = q_frame_trans_delay;
		end
		LCD_DRIVE_DATA_COUNT: begin 
			/* Insert your code */
		end
		LCD_DRIVE_START: begin 
			/* Insert your code */
		end
		LCD_DRIVE_BR_MODE: begin 
			/* Insert your code */
		end
		LCD_DRIVE_BR_VALUE: begin 
			/* Insert your code */
		end
	endcase
end
//-------------------------------------------------
// FSM
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
                //if(/*Insert your code*/)
                //    nstate = ST_VSYNC;
                //else
                //    nstate = ST_IDLE;
        end		
        ST_VSYNC: begin
                if(ctrl_vsync_cnt == q_start_up_delay) 
                    nstate = ST_HSYNC;
                else
                    nstate = ST_VSYNC;
        end	
        ST_HSYNC: begin
                //if(ctrl_hsync_cnt == /*Insert your code*/) 
                //    nstate = ST_DATA;
                //else
                //    nstate = ST_HSYNC;
        end		
        ST_DATA: begin
                if(end_frame)    //end of frame
                    nstate = ST_IDLE;
                else begin
                    //if(col == /*Insert your code*/)//end of line
                    //    nstate = ST_HSYNC;
                    //else
                    //    nstate = ST_DATA;
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
			if(col == q_width - 2) begin
				row <= row + 1;
			end
			//if(col == /*Insert your code*/) 
			//	col <= 0;
			//else 
			//	col <= col + 2;
		end
	end
end
always@(posedge HCLK, negedge HRESETn)
begin
    if(~HRESETn) begin
        data_count <= 0;
    end
    else begin
        if(ctrl_data_run) begin
			if(end_frame)
				data_count <= 0;
			else
				data_count <= data_count + 1;
		end
    end
end
//assign end_frame = (data_count == /*Insert your code*/)? 1'b1: 1'b0;			


//-------------------------------------------------
// Frame buffer
//-------------------------------------------------
//{{{
localparam sizeOfWidth = 8;
localparam sizeOfLengthReal = WIDTH * HEIGHT * 3; 		//BMP : 1179702: 512 * 768 *3 +54
localparam sizeOfLengthReal_frame = sizeOfLengthReal; 	// * `FRAME_NUMBER;
reg [sizeOfWidth - 1 : 0]   total_memory [0 : sizeOfLengthReal_frame - 1];
integer i, j;

integer BMP_header [0 : BMP_HEADER_NUM - 1];
integer temp_BMP   [0 : WIDTH*HEIGHT*3 - 1];
integer org_R  [0 : WIDTH*HEIGHT + 10];
integer org_G  [0 : WIDTH*HEIGHT + 10];
integer org_B  [0 : WIDTH*HEIGHT + 10];
// Read the input file to memory
initial begin
	$readmemh(INFILE, total_memory,0,sizeOfLengthReal_frame-1);
end
// Parse the input pixels
always@(q_start) begin
    if(q_start == 1'b1) begin
        for(i=0; i<WIDTH*HEIGHT*3 ; i=i+1) begin
            temp_BMP[i] = total_memory[i]; //read bmp format image
        end

        for(i=0; i<HEIGHT; i=i+1) begin
            for(j=0; j<WIDTH; j=j+1) begin
				org_R[WIDTH*i+j] = temp_BMP[WIDTH*3*(HEIGHT-i-1)+3*j+0];
				org_G[WIDTH*i+j] = temp_BMP[WIDTH*3*(HEIGHT-i-1)+3*j+1];       
				org_B[WIDTH*i+j] = temp_BMP[WIDTH*3*(HEIGHT-i-1)+3*j+2];		
            end
        end
    end
end

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
        DATA_B0 = org_B[WIDTH * row + col   ];
        DATA_R1 = org_R[WIDTH * row + col +1];
        DATA_G1 = org_G[WIDTH * row + col +1];
        DATA_B1 = org_B[WIDTH * row + col +1];
    end
end
//}}}

//-------------------------------------------------
// Brightness Adjustment
//-------------------------------------------------
brightness_adjustment  #(.IMG_PIX_W(IMG_PIX_W),.WAVE_PIX_W(WAVE_PIX_W))
u_brightness_adjustment(  
    /*input*/ .clk(HCLK),
    /*input*/ .rst_n(HRESETn),
    /*input*/ .in_valid(HSYNC),
    /*input*/ .mode(q_br_mode),
    /*input [IMG_PIX_W-1:0]*/ .value(q_br_value),
    /*input [IMG_PIX_W-1:0]*/ .r0(DATA_R0), 
    /*input [IMG_PIX_W-1:0]*/ .g0(DATA_G0),
    /*input [IMG_PIX_W-1:0]*/ .b0(DATA_B0),
    /*input [IMG_PIX_W-1:0]*/ .r1(DATA_R1),
    /*input [IMG_PIX_W-1:0]*/ .g1(DATA_G1),
    /*input [IMG_PIX_W-1:0]*/ .b1(DATA_B1),
    /*output*/ .out_valid(out_valid),
    /*output [IMG_PIX_W-1:0]*/ .out_r0(out_r0),
    /*output [IMG_PIX_W-1:0]*/ .out_g0(out_g0),
    /*output [IMG_PIX_W-1:0]*/ .out_b0(out_b0),
    /*output [IMG_PIX_W-1:0]*/ .out_r1(out_r1),
    /*output [IMG_PIX_W-1:0]*/ .out_g1(out_g1),
    /*output [IMG_PIX_W-1:0]*/ .out_b1(out_b1)
);

endmodule
