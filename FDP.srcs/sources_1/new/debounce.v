`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 09/29/2025 10:14:38 PM
// Design Name:
// Module Name:   debounce
// Project Name:
// Target Devices:
// Tool Versions:
// Description:   A robust, millisecond-based debouncer that generates a
//                fixed-width output pulse. Provided by user.
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module debounce(
    input clk,          // 100 MHz system clock
    input pb_1,         // raw pushbutton
    output reg pb_out   // clean pulse output (~5 ms)
);

    // --- Parameters ---
    localparam integer SAMPLE_COUNT = 100_000; // 100 MHz / 100k = 1 ms tick
    localparam integer DEBOUNCE_MS  = 200;      // 200 ms lockout
    localparam integer PULSE_MS     = 5;        // 5 ms output pulse

    // --- Signals ---
    reg [16:0] sample_counter = 0;  // counts to 100_000
    reg tick_1ms = 0;               // 1 ms enable pulse

    reg pb_sync_0, pb_sync_1;        // synchronize input
    reg pb_state = 0;               // stable debounced state
    reg [7:0] debounce_counter = 0; // counts ms during debounce
    reg [7:0] pulse_counter = 0;    // counts ms for output pulse

    // --- Generate 1 ms tick ---
    always @(posedge clk) begin
        if (sample_counter >= SAMPLE_COUNT-1) begin
            sample_counter <= 0;
            tick_1ms <= 1;
        end else begin
            sample_counter <= sample_counter + 1;
            tick_1ms <= 0;
        end
    end

    // --- Synchronize pushbutton to clk domain ---
    always @(posedge clk) begin
        pb_sync_0 <= pb_1;
        pb_sync_1 <= pb_sync_0;
    end

    // --- Debounce Logic ---
    always @(posedge clk) begin
        if (tick_1ms) begin
            // Default output
            if (pulse_counter > 0)
                pb_out <= 1;
            else
                pb_out <= 0;

            // Decrease counters
            if (debounce_counter > 0)
                debounce_counter <= debounce_counter - 1;
            if (pulse_counter > 0)
                pulse_counter <= pulse_counter - 1;

            // Detect new press
            if (debounce_counter == 0 && pb_sync_1 & ~pb_state) begin
                pb_state <= 1;                 // mark button as pressed
                debounce_counter <= DEBOUNCE_MS; // lockout for 200 ms
                pulse_counter <= PULSE_MS;       // generate 5 ms pulse
            end else if (~pb_sync_1 & pb_state) begin
                pb_state <= 0; // button released
            end
        end
    end

endmodule
