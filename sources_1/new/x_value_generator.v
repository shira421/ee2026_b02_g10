//`timescale 1ns / 1ps

//module x_value_generator #(
//    parameter integer MIN_X = -180,
//    parameter integer MAX_X = 179
//) (
//    input wire clk,
//    input wire reset,
//    output reg signed [9:0] x_val
//);
    
//    // Faster counter - change x_val every 64 clocks (was 1024)
//    // This gives us ~97,656 updates/sec at 6.25MHz
//    // Full cycle through 360 values = 271 times per second
//    reg [5:0] counter;  // Changed from [9:0] to [5:0] for faster updates
    
//    always @(posedge clk or posedge reset) begin
//        if (reset) begin
//            x_val <= MIN_X;
//            counter <= 6'd0;
//        end else begin
//            // Increment counter
//            counter <= counter + 1;
            
//            // Update x_val every 64 clocks (when counter wraps)
//            if (counter == 6'd63) begin
//                if (x_val == MAX_X)
//                    x_val <= MIN_X;
//                else
//                    x_val <= x_val + 1'sb1;
//            end
//        end
//    end
//endmodule

`timescale 1ns / 1ps

module x_value_generator #(
    parameter integer MIN_X = -180,
    parameter integer MAX_X = 179
) (
    input wire clk,
    input wire reset,
    output reg signed [9:0] x_val
);
    
    // Column-based approach: cycle through 0-95 columns
    // Each column represents a range of x-values
    reg [6:0] col_counter;  // 0 to 95
    reg [3:0] update_counter;  // Slow down updates
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            col_counter <= 7'd0;
            update_counter <= 4'd0;
            x_val <= MIN_X;
        end else begin
            update_counter <= update_counter + 1;
            
            // Update every 16 clocks
            if (update_counter == 4'd15) begin
                // Map column (0-95) to x_val (-180 to 179)
                // x_val = MIN_X + (col_counter * 360 / 96)
                // x_val = -180 + (col_counter * 3.75)
                x_val <= MIN_X + ((col_counter * 360) / 96);
                
                // Increment column
                if (col_counter == 7'd95)
                    col_counter <= 7'd0;
                else
                    col_counter <= col_counter + 1;
            end
        end
    end
endmodule