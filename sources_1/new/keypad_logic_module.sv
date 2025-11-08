`timescale 1ns / 1ps

module keypad_logic_module (
    input wire clk,
    input wire reset,
    
    // Debounced button inputs
    input wire btnU_debounced,
    input wire btnD_debounced,
    input wire btnL_debounced,
    input wire btnR_debounced,
    input wire btnC_debounced,
    input wire enable,
    
    // Outputs
    output reg [3:0] selected_key,      // 0-9, 10 for backspace, 11 for enter
    output reg enter_pressed,
    output reg backspace_pressed,
    output reg digit_pressed,
    
    // Outputs for the cursor position
    output reg [1:0] row_pos,
    output reg [1:0] col_pos
);
    // Edge detection registers
    reg btnU_prev, btnD_prev, btnL_prev, btnR_prev, btnC_prev;
    reg first_btnC_release_seen;
    
    // Edge signals (pulse for one clock cycle on rising edge)
    wire btnU_edge = btnU_debounced && !btnU_prev;
    wire btnD_edge = btnD_debounced && !btnD_prev;
    wire btnL_edge = btnL_debounced && !btnL_prev;
    wire btnR_edge = btnR_debounced && !btnR_prev;
    wire btnC_edge = btnC_debounced && !btnC_prev;
    
    // NEW: Only allow btnC_edge when we've seen the first release AND enable is high
    wire btnC_edge_filtered = btnC_edge && first_btnC_release_seen && enable;
    
    // A 4x3 matrix representing the keypad layout
    // Row 0: 1 2 3
    // Row 1: 4 5 6
    // Row 2: 7 8 9
    // Row 3: < 0 >
    localparam logic [3:0] keypad_matrix [0:3][0:2] = '{
        '{4'd1, 4'd2, 4'd3},
        '{4'd4, 4'd5, 4'd6},
        '{4'd7, 4'd8, 4'd9},
        '{4'd10, 4'd0, 4'd11}
    };
    
    // --- Sequential Logic ---
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            row_pos <= 2'b00;
            col_pos <= 2'b00;
            enter_pressed <= 1'b0;
            backspace_pressed <= 1'b0;
            digit_pressed <= 1'b0;
            selected_key <= 4'd0;
            btnU_prev <= 1'b0;
            btnD_prev <= 1'b0;
            btnL_prev <= 1'b0;
            btnR_prev <= 1'b0;
            btnC_prev <= 1'b0;
            first_btnC_release_seen <= 1'b0;
        end else begin
            // Update previous button states for edge detection
            btnU_prev <= btnU_debounced;
            btnD_prev <= btnD_debounced;
            btnL_prev <= btnL_debounced;
            btnR_prev <= btnR_debounced;
            btnC_prev <= btnC_debounced;
            
            // NEW: Track when enable goes high and wait for btnC to be released
            if (!enable) begin
                // When disabled, reset the flag
                first_btnC_release_seen <= 1'b0;
            end else if (enable && !btnC_debounced) begin
                // Once enabled, wait for btnC to be released (low)
                first_btnC_release_seen <= 1'b1;
            end
            
            // Keypad navigation logic using edge signals
            if (btnU_edge) begin
                row_pos <= (row_pos == 2'd0) ? 2'd3 : row_pos - 1;
            end else if (btnD_edge) begin
                row_pos <= (row_pos == 2'd3) ? 2'd0 : row_pos + 1;
            end else if (btnL_edge) begin
                col_pos <= (col_pos == 2'd0) ? 2'd2 : col_pos - 1;
            end else if (btnR_edge) begin
                col_pos <= (col_pos == 2'd2) ? 2'd0 : col_pos + 1;
            end
            
            // Key selection logic - use filtered edge
            if (btnC_edge_filtered) begin
                selected_key <= keypad_matrix[row_pos][col_pos];
                
                // Set the press flags based on the selected key
                if (keypad_matrix[row_pos][col_pos] == 4'd11) begin
                    enter_pressed <= 1'b1;
                    backspace_pressed <= 1'b0;
                    digit_pressed <= 1'b0;
                end else if (keypad_matrix[row_pos][col_pos] == 4'd10) begin
                    enter_pressed <= 1'b0;
                    backspace_pressed <= 1'b1;
                    digit_pressed <= 1'b0;
                end else begin
                    // It's a digit (0-9)
                    enter_pressed <= 1'b0;
                    backspace_pressed <= 1'b0;
                    digit_pressed <= 1'b1;
                end
            end else begin
                // Reset all flags when btnC is not pressed
                enter_pressed <= 1'b0;
                backspace_pressed <= 1'b0;
                digit_pressed <= 1'b0;
            end
        end
    end
endmodule
