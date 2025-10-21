`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/30/2025 03:12:03 PM
// Design Name: 
// Module Name: colour_identifier
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


module colour_identifier(input freq625m, btnLD, btnCD, btnRD, output [2:0] b0, b1, b2, output num_state);

    parameter R = 3'b000, B = 3'b001, Y = 3'b010, G = 3'b011, W = 3'b100;
    reg [2:0] b0_state, b0_next_state, b1_state, b1_next_state, b2_state, b2_next_state;
    reg flag = 0;
    
    always@(posedge btnLD) begin
        case(b0_state)
            R : b0_next_state <= B;
            B : b0_next_state <= Y;
            Y : b0_next_state <= G;
            G : b0_next_state <= W;
            W : b0_next_state <= R;
            default : b0_next_state <= R;
        endcase
    end
        always@(posedge btnCD) begin
        case(b1_state)
            R : b1_next_state <= B;
            B : b1_next_state <= Y;
            Y : b1_next_state <= G;
            G : b1_next_state <= W;
            W : b1_next_state <= R;
            default : b1_next_state <= R;
        endcase
    end
        always@(posedge btnRD) begin
        case(b2_state)
            R : b2_next_state <= B;
            B : b2_next_state <= Y;
            Y : b2_next_state <= G;
            G : b2_next_state <= W;
            W : b2_next_state <= R;
            default : b2_next_state <= R;
        endcase
    end
    
    always@(posedge freq625m) begin
        if(!flag) begin
            b0_state <= R;
            b1_state <= G;
            b2_state <= B;
            flag <= 1;
        end
        else begin
            b0_state <= b0_next_state;
            b1_state <= b1_next_state;
            b2_state <= b2_next_state;
        end
    end
    
    assign b0 = b0_state;
    assign b1 = b1_state;
    assign b2 = b2_state;
    
    assign num_state = (b0_state == Y) && (b1_state == W) && (b2_state == Y);
endmodule
