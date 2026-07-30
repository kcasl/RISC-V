module dpram(

   clk   ,

   ena   ,  // portA: enable
   wea   ,  // portA: primary synchronous write enable
   addra ,  // portA: address for read/write

   enb   ,  // portB: enable
   addrb ,  // portB: address for read

   dia   ,  // portA: primary data input
   dob      // portB: primary data output

);

   parameter W_DATA = 8;
   parameter N_WORD = 512; 
   parameter W_WORD = $clog2(N_WORD);
   parameter FILENAME = "";
   parameter N_DELAY = 1;

   input clk;  // clock input

   input ena;                 // primary enable
   input wea;                 // primary synchronous write enable
   input [W_WORD-1:0] addra;  // address for read/write
   input enb;                 // read port enable
   input [W_WORD-1:0] addrb;  // address for read
   input [W_DATA-1:0] dia;    // primary data input
   output [W_DATA-1:0] dob;   // primary data output


   // share memory
	reg [W_DATA-1:0] ram[N_WORD-1:0];

   initial
   begin
      if (FILENAME != "") begin
         $display("### Loading internal memory from %s ###", FILENAME);
         $readmemh(FILENAME, ram);
      end
   end

   // write port	
   always @(posedge clk)
   begin: write
      if(ena)
      begin
         if(wea)
            ram[addra] <= dia;
      end
   end

   generate 
      if(N_DELAY == 1) begin: delay_1
         reg [W_DATA-1:0] rdata; // primary data output
         // read port
         always @(posedge clk)
         begin: read
            if(enb)
               rdata <= ram[addrb];
         end
         assign dob = rdata;
      end
      else begin: delay_n
         reg [N_DELAY*W_DATA-1:0] rdata_r;
         always @(posedge clk)
         begin: read
            if(enb)
               rdata_r[0+:W_DATA] <= ram[addrb];
         end

         always @(posedge clk) begin: delay
            integer i;
            for(i = 0; i < N_DELAY-1; i = i+1)
               if(enb)
                  rdata_r[(i+1)*W_DATA+:W_DATA] <= rdata_r[i*W_DATA+:W_DATA];
         end
         assign dob = rdata_r[(N_DELAY-1)*W_DATA+:W_DATA];
      end
   endgenerate
  
endmodule

