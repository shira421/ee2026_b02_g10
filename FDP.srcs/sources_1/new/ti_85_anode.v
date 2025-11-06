`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/01/2025 11:57:45 AM
// Design Name: 
// Module Name: ti_85_anode
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ti_85_anode(
    input [1:0] ctr,
    output reg [3:0] an_state,
    output reg [7:0] seg_state    
    );
    
    always@(*) begin
        case(ctr)
            2'b00 : begin an_state = 4'b0111; seg_state = 8'b11111000; end
            2'b01 : begin an_state = 4'b1011; seg_state = 8'b11111001; end
            2'b10 : begin an_state = 4'b1101; seg_state = 8'b10000000; end
            2'b11 : begin an_state = 4'b1110; seg_state = 8'b10010010; end
        endcase
    end
endmodule

module counter #(
    parameter MOD = 4,
    parameter WIDTH = 2
)(
    input clk,
    input rst,
    output reg [WIDTH-1:0] ctr
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ctr <= {WIDTH{1'b0}};
        end
        else if (ctr == MOD - 1) begin
            ctr <= {WIDTH{1'b0}};
        end
        else begin
            ctr <= ctr + 1;
        end
    end

endmodule

module freq_divider #(
    parameter TARGET_FREQ = 1,      // Target frequency in Hz (default 1 Hz)
    parameter COUNTER_WIDTH = 26    // Counter width in bits (default supports down to 1.49 Hz)
)(
    input clk,           // 100 MHz input clock
    output reg slow_clk  // Divided clock output
);

    // Calculate the counter limit
    // For 100 MHz input and target frequency F:
    // Counter limit = (100,000,000 / (2 * F)) - 1
    localparam INPUT_FREQ = 100_000_000;
    localparam COUNTER_LIMIT = (INPUT_FREQ / (2 * TARGET_FREQ)) - 1;
    
    // Counter register
    reg [COUNTER_WIDTH-1:0] ctr;
    
    // Initialize registers
    initial begin
        slow_clk = 0;
        ctr = 0;
    end
    
    // Clock divider logic
    always @(posedge clk) begin
        if (ctr == COUNTER_LIMIT) begin
            slow_clk <= ~slow_clk;
            ctr <= 0;
        end else begin
            ctr <= ctr + 1;
        end
    end
endmodule