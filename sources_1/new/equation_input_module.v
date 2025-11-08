`timescale 1ns / 1ps

module equation_input_module (
    input wire clk,
    input wire reset,
    
    // Graph types from menu selection
    input wire [1:0] graph1_type,
    input wire [1:0] graph2_type,
    
    // Keypad input signals
    input wire [3:0] keypad_input,
    input wire keypad_enter_pressed,
    input wire keypad_backspace_pressed,
    input wire keypad_digit_pressed,
    
    // NEW: Negative sign input
    input wire negative_sign,  // Connected to sw[10]
    
    // Outputs for the main FSM
    output reg all_inputs_confirmed,
    
    // Outputs for the display module (Screen 1)
    output reg [1:0] current_graph_slot,
    output reg [3:0] current_coeff_pos,
    
    output reg [7:0] temp_coeff,
    output reg [1:0] digit_count,
    output reg is_negative,  // NEW: Track if current input is negative
    
    // Outputs for Graph 1's coefficients
    output reg signed [7:0] g1_poly_coeff_a, g1_poly_coeff_b, g1_poly_coeff_c,
    output reg signed [7:0] g1_cos_coeff_a,
    output reg signed [7:0] g1_sin_coeff_a,
    
    // Outputs for Graph 2's coefficients
    output reg signed [7:0] g2_poly_coeff_a, g2_poly_coeff_b, g2_poly_coeff_c,
    output reg signed [7:0] g2_cos_coeff_a,
    output reg signed [7:0] g2_sin_coeff_a
);

    // Graph type constants
    localparam POLY = 2'b00;
    localparam COS  = 2'b01;
    localparam SIN  = 2'b10;
    
    // Graph slot constants
    localparam GRAPH1 = 2'b00;
    localparam GRAPH2 = 2'b01;
    
    // Internal counter for coefficient position within current graph
    reg [1:0] coeff_index;
    
    // DECLARE final_coeff HERE - at module level, NOT inside always block
    reg signed [7:0] final_coeff;
    
    // Function to determine number of coefficients needed for a graph type
    function [1:0] get_num_coeffs;
        input [1:0] graph_type;
        begin
            case (graph_type)
                POLY: get_num_coeffs = 2'd3;  // a, b, c
                COS:  get_num_coeffs = 2'd1;  // a only
                SIN:  get_num_coeffs = 2'd1;  // a only
                default: get_num_coeffs = 2'd0;
            endcase
        end
    endfunction
    
    // Determine total number of coefficients needed
    wire [2:0] total_coeffs_needed;
    assign total_coeffs_needed = get_num_coeffs(graph1_type) + get_num_coeffs(graph2_type);
    
    // Counter to track total number of coefficients entered
    reg [2:0] total_coeffs_entered;
    localparam NOT_SET = 8'h7F;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all outputs
            temp_coeff <= 8'b0;
            digit_count <= 2'b0;
            is_negative <= 1'b0;
            current_graph_slot <= GRAPH1;
            current_coeff_pos <= 4'b0;
            coeff_index <= 2'b0;
            total_coeffs_entered <= 3'b0;
            all_inputs_confirmed <= 1'b0;
            final_coeff <= 8'b0;
            
            // Initialize all coefficients to NOT_SET
            g1_poly_coeff_a <= NOT_SET;
            g1_poly_coeff_b <= NOT_SET;
            g1_poly_coeff_c <= NOT_SET;
            g1_cos_coeff_a <= NOT_SET;
            g1_sin_coeff_a <= NOT_SET;
            
            g2_poly_coeff_a <= NOT_SET;
            g2_poly_coeff_b <= NOT_SET;
            g2_poly_coeff_c <= NOT_SET;
            g2_cos_coeff_a <= NOT_SET;
            g2_sin_coeff_a <= NOT_SET;
        end else begin
            
            // Handle digit input - LIMIT TO SINGLE DIGIT (0-9)
            if (keypad_digit_pressed) begin
                // Only allow single digit entry (0-9)
                if (digit_count == 2'd0 && keypad_input <= 4'd9) begin
                    temp_coeff <= keypad_input;  // Store as positive initially
                    digit_count <= 2'd1;
                    is_negative <= negative_sign;  // Capture negative sign state
                end
                // Ignore if already have a digit or if input > 9
            end
            
            // Handle backspace
            if (keypad_backspace_pressed) begin
                if (digit_count > 2'd0) begin
                    temp_coeff <= 8'd0;
                    digit_count <= 2'd0;
                    is_negative <= 1'b0;
                end
            end
            
            // Handle enter - store coefficient and move to next
            if (keypad_enter_pressed && !all_inputs_confirmed && digit_count > 2'd0) begin
                // Convert to signed value if negative
                // CRITICAL FIX: Use BLOCKING assignment (=) not non-blocking (<=)
                if (is_negative)
                    final_coeff = -$signed(temp_coeff);
                else
                    final_coeff = $signed(temp_coeff);
                
                // Store coefficient based on current graph slot and coefficient index
                
                // Graph 1 Polynomial
                if (current_graph_slot == GRAPH1 && graph1_type == POLY && coeff_index == 2'd0) begin
                    g1_poly_coeff_a <= final_coeff;
                end else if (current_graph_slot == GRAPH1 && graph1_type == POLY && coeff_index == 2'd1) begin
                    g1_poly_coeff_b <= final_coeff;
                end else if (current_graph_slot == GRAPH1 && graph1_type == POLY && coeff_index == 2'd2) begin
                    g1_poly_coeff_c <= final_coeff;
                end
                // Graph 1 Cosine
                else if (current_graph_slot == GRAPH1 && graph1_type == COS && coeff_index == 2'd0) begin
                    g1_cos_coeff_a <= final_coeff;
                end
                // Graph 1 Sine
                else if (current_graph_slot == GRAPH1 && graph1_type == SIN && coeff_index == 2'd0) begin
                    g1_sin_coeff_a <= final_coeff;
                end
                // Graph 2 Polynomial
                else if (current_graph_slot == GRAPH2 && graph2_type == POLY && coeff_index == 2'd0) begin
                    g2_poly_coeff_a <= final_coeff;
                end else if (current_graph_slot == GRAPH2 && graph2_type == POLY && coeff_index == 2'd1) begin
                    g2_poly_coeff_b <= final_coeff;
                end else if (current_graph_slot == GRAPH2 && graph2_type == POLY && coeff_index == 2'd2) begin
                    g2_poly_coeff_c <= final_coeff;
                end
                // Graph 2 Cosine
                else if (current_graph_slot == GRAPH2 && graph2_type == COS && coeff_index == 2'd0) begin
                    g2_cos_coeff_a <= final_coeff;
                end
                // Graph 2 Sine
                else if (current_graph_slot == GRAPH2 && graph2_type == SIN && coeff_index == 2'd0) begin
                    g2_sin_coeff_a <= final_coeff;
                end
                
                // Clear temp_coeff and digit_count for next input
                temp_coeff <= 8'd0;
                digit_count <= 2'd0;
                is_negative <= 1'b0;
                
                // Increment total coefficients entered
                total_coeffs_entered <= total_coeffs_entered + 1;
                
                // Move to next coefficient position
                coeff_index <= coeff_index + 1;
                current_coeff_pos <= current_coeff_pos + 1;
                
                // Check if all inputs are now confirmed
                if (current_coeff_pos + 1 == total_coeffs_needed) begin
                    all_inputs_confirmed <= 1'b1;
                end
                
                // Check if we need to move to next graph
                if (current_graph_slot == GRAPH1) begin
                    if (coeff_index >= (get_num_coeffs(graph1_type) - 1)) begin
                        // Move to Graph 2
                        current_graph_slot <= GRAPH2;
                        coeff_index <= 2'd0;
                    end
                end
            end
        end
    end
endmodule
