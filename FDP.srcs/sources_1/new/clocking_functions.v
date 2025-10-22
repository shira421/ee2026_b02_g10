`timescale 1ns / 1ps

module freq_625m(input clk, output reg slow_clk);  
    reg [4:0] ctr; //for declaration of the variable itself must do ooutside the inital block
    
    initial begin
        slow_clk = 0; //initalising the start value
        ctr = 0; //initalise the ctr value
    end
    
    always @ (posedge clk) begin
        if (ctr == 4'd7) begin
            slow_clk <= ~slow_clk;
            ctr <= 0;
        end else begin
            ctr <= ctr + 1;
        end
    end 
endmodule
