//////////////////////////////////////////////////////////////////////////////////
// Engineer:      (Modified for resource sharing)
// Create Date:   10/11/2025
// Module Name:   dual_oled_calculator_pixel
// Description:
//
// Modified version that outputs pixel data instead of driving OLEDs directly.
// This allows sharing of parent's OLED display drivers to save resources.
//
//////////////////////////////////////////////////////////////////////////////////
module dual_oled_calculator_pixel(
    input clk,          // System clock (100 MHz)
    input slow_clk,     // Slow clock for timing (6.25 MHz)
    input btnC, btnU, btnD, btnL, btnR,  // Already debounced

    // Pixel data outputs (connect to parent's OLED drivers)
    input [12:0] pixel_index_a,    // From parent's OLED driver A
    input [12:0] pixel_index_b,    // From parent's OLED driver B
    output [15:0] pixel_data_a,    // To parent's OLED driver A (output screen)
    output [15:0] pixel_data_b     // To parent's OLED driver B (input screen)
);

    //================================================================
    // Reset Logic
    //================================================================
    reg [15:0] reset_counter = 16'hFFFF;
    wire power_on_reset = |reset_counter;

    always @(posedge clk) begin
        if (power_on_reset) begin
            reset_counter <= reset_counter - 1;
        end
    end

    wire manual_reset_req;
    wire master_reset = power_on_reset || manual_reset_req;

    //================================================================
    // Core FSM and Renderer Instantiations
    //================================================================
    wire [2:0]  current_state;
    wire [16:0] num1, num2;
    wire [19:0] result;
    wire [1:0]  op_code, op_selection;
    wire [3:0]  numpad_selection;

    calculator_fsm fsm (
        .clk(slow_clk), 
        .reset(master_reset),
        .btnC(btnC), .btnU(btnU), .btnD(btnD), .btnL(btnL), .btnR(btnR),
        .manual_reset_req(manual_reset_req), 
        .current_state(current_state),
        .num1_out(num1), 
        .num2_out(num2), 
        .result_out(result),
        .op_code_out(op_code), 
        .op_selection_out(op_selection),
        .numpad_selection_out(numpad_selection)
    );

    // Output screen renderer (Screen A)
    output_screen_renderer renderer_a (
        .pixel_index(pixel_index_a), 
        .state(current_state),
        .num1(num1), 
        .num2(num2), 
        .result(result), 
        .op_code(op_code),
        .pixel_data(pixel_data_a)
    );

    // Input screen renderer (Screen B)
    input_screen_renderer renderer_b (
        .pixel_index(pixel_index_b), 
        .state(current_state),
        .op_selection(op_selection), 
        .numpad_selection(numpad_selection),
        .pixel_data(pixel_data_b)
    );

endmodule