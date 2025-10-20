`timescale 1ns / 1ps

module graphing_calculator_top (
    input wire clk,
    input wire reset,
    input wire btnC,
    input wire btnL,
    input wire btnR,
    input wire btnU,
    input wire btnD,
    input wire main_menu_switch,
    input wire negative_sign,  // NEW: Connected to sw[10]
    input wire [12:0] pixel_index_1, pixel_index_2,
    
    // Outputs to screens
    output reg [15:0] screen1_data,
    output reg [15:0] screen2_data
);
    //parameter declarations
    localparam STATE_MAIN_MENU = 3'b000;
    localparam STATE_GRAPH_MENU = 3'b001;
    localparam STATE_INPUT = 3'b010;
    localparam STATE_GRAPHING = 3'b011;
    
    //button controls
    wire btnU_main, btnD_main, btnL_main, btnR_main, btnC_main;
    wire btnU_menu, btnD_menu, btnL_menu, btnR_menu, btnC_menu;
    wire btnU_input, btnD_input, btnL_input, btnR_input, btnC_input;
    
    assign btnU_main = (state == STATE_MAIN_MENU) ? btnU : 1'b0;
    assign btnD_main = (state == STATE_MAIN_MENU) ? btnD : 1'b0;
    assign btnL_main = (state == STATE_MAIN_MENU) ? btnL : 1'b0;
    assign btnR_main = (state == STATE_MAIN_MENU) ? btnR : 1'b0;
    assign btnC_main = (state == STATE_MAIN_MENU) ? btnC : 1'b0;
    
    assign btnU_menu = (state == STATE_GRAPH_MENU) ? btnU : 1'b0;
    assign btnD_menu = (state == STATE_GRAPH_MENU) ? btnD : 1'b0;
    assign btnL_menu = (state == STATE_GRAPH_MENU) ? btnL : 1'b0;
    assign btnR_menu = (state == STATE_GRAPH_MENU) ? btnR : 1'b0;
    assign btnC_menu = (state == STATE_GRAPH_MENU) ? btnC : 1'b0;
    
    assign btnU_input = (state == STATE_INPUT) ? btnU : 1'b0;
    assign btnD_input = (state == STATE_INPUT) ? btnD : 1'b0;
    assign btnL_input = (state == STATE_INPUT) ? btnL : 1'b0;
    assign btnR_input = (state == STATE_INPUT) ? btnR : 1'b0;
    assign btnC_input = (state == STATE_INPUT) ? btnC : 1'b0;
    
    // Menu state entry detection
    reg [2:0] state_prev;
    wire menu_state_entry;
    assign menu_state_entry = (state == STATE_GRAPH_MENU) && (state_prev != STATE_GRAPH_MENU);
    
    always @(posedge clk or posedge reset) begin
        if (reset)
            state_prev <= STATE_MAIN_MENU;
        else
            state_prev <= state;
    end
        
    wire cursor_pos;
    wire [1:0] graph1_type;
    wire [1:0] graph2_type;
    wire menu_confirmed;
    
    menu_logic_module menu_logic_inst (
         .clk(clk),
         .reset(reset),
         .state_entry(menu_state_entry),
         .btnC_debounced(btnC_menu),
         .btnL_debounced(btnL_menu),
         .btnR_debounced(btnR_menu),
         .btnU_debounced(btnU_menu),
         .btnD_debounced(btnD_menu),
         .cursor_pos(cursor_pos),
         .graph1_type(graph1_type),
         .graph2_type(graph2_type),
         .menu_confirmed(menu_confirmed)
     );
     
     // Keypad logic module
     wire [3:0] keypad_input;
     wire enter_pressed, backspace_pressed, digit_pressed;
     wire [1:0] row_pos, col_pos;
     
     keypad_logic_module keypad_inst (
         .clk(clk),
         .reset(reset),
         .btnU_debounced(btnU_input),
         .btnD_debounced(btnD_input),
         .btnL_debounced(btnL_input),
         .btnR_debounced(btnR_input),
         .btnC_debounced(btnC_input),
         .enable(keypad_enable),
         
         .selected_key(keypad_input),
         .enter_pressed(enter_pressed),
         .backspace_pressed(backspace_pressed),
         .digit_pressed(digit_pressed),
         
         .row_pos(row_pos),
         .col_pos(col_pos)
     );
     
     // Equation input module
     wire all_inputs_confirmed;
     wire [1:0] current_graph_slot;
     wire [3:0] current_coeff_pos;
     
     wire [7:0] temp_coeff;
     wire [1:0] digit_count;
     wire is_negative;
     
     wire [7:0] g1_poly_coeff_a, g1_poly_coeff_b, g1_poly_coeff_c;
     wire [7:0] g1_cos_coeff_a, g1_sin_coeff_a;
     wire [7:0] g2_poly_coeff_a, g2_poly_coeff_b, g2_poly_coeff_c;
     wire [7:0] g2_cos_coeff_a, g2_sin_coeff_a;
     
     equation_input_module equation_input_inst (
         .clk(clk),
         .reset(reset),
         .graph1_type(graph1_type),
         .graph2_type(graph2_type),
         .keypad_input(keypad_input),
         .keypad_enter_pressed(enter_pressed),
         .keypad_backspace_pressed(backspace_pressed),
         .keypad_digit_pressed(digit_pressed),
         .negative_sign(negative_sign),  // NEW: Pass through
         
         .all_inputs_confirmed(all_inputs_confirmed),
         .current_graph_slot(current_graph_slot),
         .current_coeff_pos(current_coeff_pos),
         .temp_coeff(temp_coeff),
         .digit_count(digit_count),
         .is_negative(is_negative),  // NEW: Output
         .g1_poly_coeff_a(g1_poly_coeff_a),
         .g1_poly_coeff_b(g1_poly_coeff_b),
         .g1_poly_coeff_c(g1_poly_coeff_c),
         .g1_cos_coeff_a(g1_cos_coeff_a),
         .g1_sin_coeff_a(g1_sin_coeff_a),
         .g2_poly_coeff_a(g2_poly_coeff_a),
         .g2_poly_coeff_b(g2_poly_coeff_b),
         .g2_poly_coeff_c(g2_poly_coeff_c),
         .g2_cos_coeff_a(g2_cos_coeff_a),
         .g2_sin_coeff_a(g2_sin_coeff_a)
     );
     
    // Keypad bounce protection
    reg keypad_enable;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            keypad_enable <= 1'b0;
        end else begin
            case (state)
                STATE_INPUT: begin
                    keypad_enable <= 1'b1;
                end
                default: begin
                    keypad_enable <= 1'b0;
                end
            endcase
        end
    end
    
    // FSM state registers
    reg [2:0] state, next_state;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= STATE_MAIN_MENU;
        end else begin
            state <= next_state;
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            STATE_MAIN_MENU: begin
                if (btnU_main || btnD_main || btnL_main || btnR_main || btnC_main) begin
                    next_state = STATE_GRAPH_MENU;
                end
            end
            
            STATE_GRAPH_MENU: begin
                if (menu_confirmed) begin
                    next_state = STATE_INPUT;
                end
            end
            
            STATE_INPUT: begin
                if (all_inputs_confirmed) begin
                    next_state = STATE_GRAPHING;
                end
            end
            
            STATE_GRAPHING: begin
                if (btnD) begin
                    next_state = STATE_GRAPH_MENU;
                end
            end
            
            default: begin
                next_state = STATE_MAIN_MENU;
            end
        endcase
    end
    
    //------------------------------------------------//
    //attached below are the screen codes
    //------------------------------------------------//
    
    // Stage 1 screens
    wire [15:0] state_main_menu_1;
    ti85_display_module ti85_display_inst(
            .freq625m(clk),
            .pixel_index(pixel_index_1),
            .pixel_data(state_main_menu_1)
    );
    
    wire [15:0] state_main_menu_2;
    pixel_output_generator pixel_output_generator_inst(
        .freq625m(clk),
        .pixel_index(pixel_index_2),
        .pixel_data(state_main_menu_2)
    );
    
    // Stage 2 screens
    wire [15:0] state_graph_menu_1;
    pixel_output_state_graph_menu pixel_output_state_graph_menu_inst(
        .freq625m(clk),
        .cursor_pos(cursor_pos),
        .graph1_type(graph1_type),
        .graph2_type(graph2_type),
        .pixel_index(pixel_index_1),
        .pixel_data(state_graph_menu_1)
    );
    
    wire [15:0] state_graph_menu_2;
    confirmation_screen confirmation_screen_inst(
        .freq625m(clk),
        .pixel_index(pixel_index_1),
        .pixel_data(state_graph_menu_2)
    );
    
    // Stage 3 screens
    wire [15:0] state_input_menu_1;
    equation_display equation_display_inst(
        .clk(clk),
        .pixel_index(pixel_index_1),
        .graph1_type(graph1_type),
        .graph2_type(graph2_type),
        
        .g1_poly_coeff_a(g1_poly_coeff_a), 
        .g1_poly_coeff_b(g1_poly_coeff_b), 
        .g1_poly_coeff_c(g1_poly_coeff_c),
        .g1_cos_coeff_a(g1_cos_coeff_a), 
        .g1_sin_coeff_a(g1_sin_coeff_a),
        
        .g2_poly_coeff_a(g2_poly_coeff_a), 
        .g2_poly_coeff_b(g2_poly_coeff_b), 
        .g2_poly_coeff_c(g2_poly_coeff_c),
        .g2_cos_coeff_a(g2_cos_coeff_a), 
        .g2_sin_coeff_a(g2_sin_coeff_a),
        
        .temp_coeff(temp_coeff), 
        .digit_count(digit_count),
        .is_negative(is_negative),
        .current_graph_slot(current_graph_slot), 
        .current_coeff_pos(current_coeff_pos),
        
        .pixel_color(state_input_menu_1)
    );
    
    wire [15:0] state_input_menu_2;
    keypad_screen keypad_screen_inst(
        .freq625m(clk),
        .row_pos(row_pos),
        .col_pos(col_pos),
        .pixel_index(pixel_index_2),
        .pixel_data(state_input_menu_2)
    );
    
    // Stage 4 screens - GRAPHING
    wire [15:0] state_graphing_menu_1;
    graph_plotter graph_display_1(
        .clk(clk),
        .reset(reset),
        .pixel_index(pixel_index_1),
        
        .graph1_type(graph1_type),
        .graph2_type(graph2_type),
        
        .g1_poly_coeff_a(g1_poly_coeff_a),
        .g1_poly_coeff_b(g1_poly_coeff_b),
        .g1_poly_coeff_c(g1_poly_coeff_c),
        .g1_cos_coeff_a(g1_cos_coeff_a),
        .g1_sin_coeff_a(g1_sin_coeff_a),
        
        .g2_poly_coeff_a(g2_poly_coeff_a),
        .g2_poly_coeff_b(g2_poly_coeff_b),
        .g2_poly_coeff_c(g2_poly_coeff_c),
        .g2_cos_coeff_a(g2_cos_coeff_a),
        .g2_sin_coeff_a(g2_sin_coeff_a),
        
        .pixel_data(state_graphing_menu_1)
    );
    
    wire [15:0] state_graphing_menu_2;
    graph_plotter graph_display_2(
        .clk(clk),
        .reset(reset),
        .pixel_index(pixel_index_2),
        
        .graph1_type(graph1_type),
        .graph2_type(graph2_type),
        
        .g1_poly_coeff_a(g1_poly_coeff_a),
        .g1_poly_coeff_b(g1_poly_coeff_b),
        .g1_poly_coeff_c(g1_poly_coeff_c),
        .g1_cos_coeff_a(g1_cos_coeff_a),
        .g1_sin_coeff_a(g1_sin_coeff_a),
        
        .g2_poly_coeff_a(g2_poly_coeff_a),
        .g2_poly_coeff_b(g2_poly_coeff_b),
        .g2_poly_coeff_c(g2_poly_coeff_c),
        .g2_cos_coeff_a(g2_cos_coeff_a),
        .g2_sin_coeff_a(g2_sin_coeff_a),
        
        .pixel_data(state_graphing_menu_2)
    );
    
    // MUX Display Output Based on FSM State
    always @(*) begin
        case (state)
            STATE_MAIN_MENU: begin
                screen1_data = state_main_menu_1;
                screen2_data = state_main_menu_2;
            end
            
            STATE_GRAPH_MENU: begin
                screen1_data = state_graph_menu_1;
                screen2_data = state_graph_menu_2;
            end
            
            STATE_INPUT: begin
                screen1_data = state_input_menu_1;
                screen2_data = state_input_menu_2;
            end
            
            STATE_GRAPHING: begin
                screen1_data = state_graphing_menu_1;
                screen2_data = state_graphing_menu_2;
            end
        endcase
    end

endmodule