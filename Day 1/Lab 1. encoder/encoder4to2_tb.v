`timescale 1ns/1ps

module encoder4to2_tb; reg din0, din1, din2, din3; wire [1:0] dout; encoder4to2 u_encoder4to2 (.din0(din0), .din1(din1), .din2(din2), .din3(din3), .dout(dout));
    
    initial begin
        
        // Initialization
        din0 = 0;
        din1 = 0;
        din2 = 0;
        din3 = 0;
        
        // Delay 5 ns
        // Test case 1
        #5 	din0 = 1;
        din1     = 0;
        din2     = 0;
        din3     = 0;
        
        // Delay 5 ns
        // Test case 2
        #5 	din0 = 0;
        din1     = 1;
        din2     = 0;
        din3     = 0;
        
        // Delay 5 ns
        // Test case 3
        #5 	din0 = 0;
        din1     = 0;
        din2     = 1;
        din3     = 0;
        
        // Delay 5 ns
        // Test case 4: Insert your code
        //{{{
        #5 	din0 = 0;
        din1     = 0;
        din2     = 0;
        din3     = 1;
        //}}}
        
        // Delay 5 ns / undefined case
        #5 	din0 = 1;
        din1     = 1;
        din2     = 1;
        din3     = 1;
        
    end
    
endmodule
