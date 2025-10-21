`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/12/2025 12:49:00 PM
// Design Name: 
// Module Name: menu_logic_module
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

module menu_logic_module (
    input wire clk,
    input wire reset,
    input wire state_entry,  // Signal when entering STATE_GRAPH_MENU
    
    // Debounced button inputs
    input wire btnC_debounced,
    input wire btnL_debounced,
    input wire btnR_debounced,
    input wire btnU_debounced,
    input wire btnD_debounced,
    
    // Outputs to the main FSM and display module
    output reg cursor_pos,
    output reg [1:0] graph1_type,
    output reg [1:0] graph2_type,
    output reg menu_confirmed
);
    
    // Graph type parameters for clarity
    localparam POLYNOMIAL = 2'b00;
    localparam COSINE     = 2'b01;
    localparam SINE       = 2'b10;
    
    // Edge detection registers - store previous button states
    reg btnC_prev, btnL_prev, btnR_prev, btnU_prev, btnD_prev;
    
    // Rising edge detection wires
    wire btnC_edge = btnC_debounced && !btnC_prev;
    wire btnL_edge = btnL_debounced && !btnL_prev;
    wire btnR_edge = btnR_debounced && !btnR_prev;
    wire btnU_edge = btnU_debounced && !btnU_prev;
    wire btnD_edge = btnD_debounced && !btnD_prev;
    
    // Sequential logic for the menu
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cursor_pos <= 1'b0;                // Start on Graph 1
            graph1_type <= POLYNOMIAL;         // Start with Polynomial
            graph2_type <= POLYNOMIAL;         // Start with Polynomial
            menu_confirmed <= 1'b0;
            btnC_prev <= 1'b0;
            btnL_prev <= 1'b0;
            btnR_prev <= 1'b0;
            btnU_prev <= 1'b0;
            btnD_prev <= 1'b0;
        end else begin
            // Default: menu_confirmed is low (only pulses for one cycle)
            menu_confirmed <= 1'b0;
            
            // When entering the menu, initialize button states to prevent false edges
            if (state_entry) begin
                btnC_prev <= btnC_debounced;
                btnL_prev <= btnL_debounced;
                btnR_prev <= btnR_debounced;
                btnU_prev <= btnU_debounced;
                btnD_prev <= btnD_debounced;
            end
            
            // Button logic - only process if not entering state
            if (!state_entry) begin
                // Up/Down: Toggle between rows with wrap-around
                if (btnU_edge || btnD_edge) begin
                    cursor_pos <= ~cursor_pos;  // Toggle: 0?1 or 1?0
                end
                
                // Right: Cycle forward through graph types for current row
                if (btnR_edge) begin
                    if (cursor_pos == 1'b0) begin
                        // Modify Graph 1 type: Polynomial ? Cosine ? Sine ? Polynomial
                        case (graph1_type)
                            POLYNOMIAL: graph1_type <= COSINE;
                            COSINE:     graph1_type <= SINE;
                            SINE:       graph1_type <= POLYNOMIAL;
                            default:    graph1_type <= POLYNOMIAL;
                        endcase
                    end else begin
                        // Modify Graph 2 type: Polynomial ? Cosine ? Sine ? Polynomial
                        case (graph2_type)
                            POLYNOMIAL: graph2_type <= COSINE;
                            COSINE:     graph2_type <= SINE;
                            SINE:       graph2_type <= POLYNOMIAL;
                            default:    graph2_type <= POLYNOMIAL;
                        endcase
                    end
                end
                
                // Left: Cycle backward through graph types for current row
                if (btnL_edge) begin
                    if (cursor_pos == 1'b0) begin
                        // Modify Graph 1 type: Polynomial ? Sine ? Cosine ? Polynomial
                        case (graph1_type)
                            POLYNOMIAL: graph1_type <= SINE;
                            SINE:       graph1_type <= COSINE;
                            COSINE:     graph1_type <= POLYNOMIAL;
                            default:    graph1_type <= POLYNOMIAL;
                        endcase
                    end else begin
                        // Modify Graph 2 type: Polynomial ? Sine ? Cosine ? Polynomial
                        case (graph2_type)
                            POLYNOMIAL: graph2_type <= SINE;
                            SINE:       graph2_type <= COSINE;
                            COSINE:     graph2_type <= POLYNOMIAL;
                            default:    graph2_type <= POLYNOMIAL;
                        endcase
                    end
                end
                
                // Center: Confirm selection and signal to move to next state
                if (btnC_edge) begin
                    menu_confirmed <= 1'b1;  // Pulse high for ONE cycle
                end
                
                // Update previous button states for next cycle's edge detection
                btnC_prev <= btnC_debounced;
                btnL_prev <= btnL_debounced;
                btnR_prev <= btnR_debounced;
                btnU_prev <= btnU_debounced;
                btnD_prev <= btnD_debounced;
            end
        end
    end
endmodule