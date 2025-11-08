`timescale 1ns / 1ps

module flexible_clock(input clk, input [31:0] m, output reg slow_clock);
reg [31:0] COUNT = 0; 
initial begin
    COUNT = 0; 
    slow_clock = 0; 
end 
always @(posedge clk) begin
        COUNT <= (COUNT == m) ? 0 : COUNT+1; 
        slow_clock <= (COUNT == 0) ? ~slow_clock : slow_clock; 
    end
endmodule
