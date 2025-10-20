
//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Company: 
//// Engineer: 
//// 
//// Create Date: 10/11/2025 04:19:39 PM
//// Design Name: 
//// Module Name: graphing_calculator_top
//// Project Name: 
//// Target Devices: 
//// Tool Versions: 
//// Description: 
//// 
//// Dependencies: 
//// 
//// Revision:
//// Revision 0.01 - File Created
//// Additional Comments:
//// 
////////////////////////////////////////////////////////////////////////////////////

//module graphing_calculator_top (
//    input wire clk,
//    input wire reset,
//    input wire btnC, //buttons come in debounced already
//    input wire btnL,
//    input wire btnR,
//    input wire btnU,
//    input wire btnD,
//    input wire main_menu_switch, // External switch for main menu
//    input wire [12:0] pixel_index_1, pixel_index_2,
    
    
//    // Outputs to screens
//    output reg [15:0] screen1_data,
//    output reg [15:0] screen2_data,
    
//    //FSM DEBUGGING
//    output wire [2:0] fsm_state_debug,
//    output wire cursor_pos_debug,
//    output wire [1:0] graph1_type_debug,
//    output wire [1:0] graph2_type_debug,
//    output wire [1:0] row_pos_debug,
//    output wire [1:0] col_pos_debug,
//    output wire [7:0] temp_coeff_debug,
//    output wire [1:0] digit_count_debug,
//    output wire all_inputs_confirmed_debug,
//    output wire [7:0] g1_cos_coeff_a_debug, 
//    output wire [7:0] g1_sin_coeff_a_debug,
//    output wire [7:0] g2_cos_coeff_a_debug, 
//    output wire [7:0] g2_sin_coeff_a_debug,
//    output wire [7:0] g1_poly_coeff_a_debug, g1_poly_coeff_b_debug, g1_poly_coeff_c_debug,
//    output wire [7:0] g2_poly_coeff_a_debug, g2_poly_coeff_b_debug, g2_poly_coeff_c_debug,
//    output wire [1:0] current_graph_slot_debug,
//    output wire [3:0] current_coeff_pos_debug
//);
//    //parameter declarations
//    localparam STATE_MAIN_MENU = 3'b000;
//    localparam STATE_GRAPH_MENU = 3'b001;
//    localparam STATE_INPUT = 3'b010;
//    localparam STATE_GRAPHING = 3'b011;
    
//    //debugging lines
//    assign fsm_state_debug = state;
//    assign cursor_pos_debug = cursor_pos;
//    assign graph1_type_debug = graph1_type;
//    assign graph2_type_debug = graph2_type;
//    assign row_pos_debug = row_pos;
//    assign col_pos_debug = col_pos;
//    assign temp_coeff_debug = temp_coeff;
//    assign digit_count_debug = digit_count;
//    assign all_inputs_confirmed_debug = all_inputs_confirmed;
//    assign g1_cos_coeff_a_debug = g1_cos_coeff_a;
//    assign g1_sin_coeff_a_debug = g1_sin_coeff_a;
//    assign g2_cos_coeff_a_debug = g2_cos_coeff_a;
//    assign g2_sin_coeff_a_debug = g2_sin_coeff_a;
//    assign g1_poly_coeff_a_debug= g1_poly_coeff_a;
//    assign g1_poly_coeff_b_debug = g1_poly_coeff_b;
//    assign g1_poly_coeff_c_debug = g1_poly_coeff_c;
//    assign g2_poly_coeff_a_debug = g2_poly_coeff_a;
//    assign g2_poly_coeff_b_debug = g2_poly_coeff_b;
//    assign g2_poly_coeff_c_debug = g2_poly_coeff_c;
//    assign current_graph_slot_debug = current_graph_slot;
//    assign current_coeff_pos_debug = current_coeff_pos;
    
//    //button controls----------------------------------------//
//    // Wires for state-gated buttons
//    wire btnU_main, btnD_main, btnL_main, btnR_main, btnC_main;
//    wire btnU_menu, btnD_menu, btnL_menu, btnR_menu, btnC_menu;
//    wire btnU_input, btnD_input, btnL_input, btnR_input, btnC_input;
    
//    // Use assign statements to conditionally activate the wires
//    assign btnU_main = (state == STATE_MAIN_MENU) ? btnU : 1'b0;
//    assign btnD_main = (state == STATE_MAIN_MENU) ? btnD : 1'b0;
//    assign btnL_main = (state == STATE_MAIN_MENU) ? btnL : 1'b0;
//    assign btnR_main = (state == STATE_MAIN_MENU) ? btnR : 1'b0;
//    assign btnC_main = (state == STATE_MAIN_MENU) ? btnC : 1'b0;
    
//    assign btnU_menu = (state == STATE_GRAPH_MENU) ? btnU : 1'b0;
//    assign btnD_menu = (state == STATE_GRAPH_MENU) ? btnD : 1'b0;
//    assign btnL_menu = (state == STATE_GRAPH_MENU) ? btnL : 1'b0;
//    assign btnR_menu = (state == STATE_GRAPH_MENU) ? btnR : 1'b0;
//    assign btnC_menu = (state == STATE_GRAPH_MENU) ? btnC : 1'b0;
    
//    assign btnU_input = (state == STATE_INPUT) ? btnU : 1'b0;
//    assign btnD_input = (state == STATE_INPUT) ? btnD : 1'b0;
//    assign btnL_input = (state == STATE_INPUT) ? btnL : 1'b0;
//    assign btnR_input = (state == STATE_INPUT) ? btnR : 1'b0;
//    assign btnC_input = (state == STATE_INPUT) ? btnC : 1'b0;
    
//    //-------------------------------------------------------//
//    // STATE_MAIN_MENU helper function, cursor_pos tells us
//    // where we are for the display helper function later
//    //
//    //-------------------------------------------------------//
//    // Wires for communication with the menu logic module
//    reg [2:0] state_prev;
//    wire menu_state_entry;
//    assign menu_state_entry = (state == STATE_GRAPH_MENU) && (state_prev != STATE_GRAPH_MENU);
    
//    always @(posedge clk or posedge reset) begin
//        if (reset)
//            state_prev <= STATE_MAIN_MENU;
//        else
//            state_prev <= state;
//    end
        
//    wire cursor_pos; //0 for graph 1, 1 for graph 2
//    wire [1:0] graph1_type; //00 for polynomial, 01 for cosine, 10 for sine
//    wire [1:0] graph2_type; //same as the above
//    wire menu_confirmed; //flag when the btnC button is pressed to indicate to move on to the next
//    // UPDATED: Instantiate the menu logic module
//    menu_logic_module menu_logic_inst (
//         .clk(clk),
//         .reset(reset),
//         .state_entry(menu_state_entry),
//         .btnC_debounced(btnC_menu),
//         .btnL_debounced(btnL_menu),
//         .btnR_debounced(btnR_menu),
//         .btnU_debounced(btnU_menu),
//         .btnD_debounced(btnD_menu),
//         .cursor_pos(cursor_pos),
//         .graph1_type(graph1_type),
//         .graph2_type(graph2_type),
//         .menu_confirmed(menu_confirmed)
//     );
     
//     //-------------------------------------------------------//
//     // keypad logic module
//     // takes in the buttons inputs
//     // first 3 outputs are funneled to the equation_input_module
//     //-------------------------------------------------------// 
//     wire [3:0] keypad_input;
//     wire enter_pressed, backspace_pressed, digit_pressed;
//     wire [1:0] row_pos, col_pos;
     
     
//     keypad_logic_module keypad_inst (
//         .clk(clk),
//         .reset(reset),
//         .btnU_debounced(btnU_input),
//         .btnD_debounced(btnD_input),
//         .btnL_debounced(btnL_input),
//         .btnR_debounced(btnR_input),
//         .btnC_debounced(btnC_input),
//         .enable(keypad_enable),
         
//         .selected_key(keypad_input),
//         .enter_pressed(enter_pressed),
//         .backspace_pressed(backspace_pressed),
//         .digit_pressed(digit_pressed),
         
//         .row_pos(row_pos),
//         .col_pos(col_pos)
//     );
     
//     //-------------------------------------------------------//
//     //  equation input module, most importantly it takes in
//     // the inputs to the graph type and then outputs the coefficients
//     // of the graph type
//     //-------------------------------------------------------//
//     wire all_inputs_confirmed;
//     wire [1:0] current_graph_slot;
//     wire [3:0] current_coeff_pos;
     
//     wire [7:0] temp_coeff;
//     wire [1:0] digit_count;
     
//     wire [7:0] g1_poly_coeff_a, g1_poly_coeff_b, g1_poly_coeff_c;
//     wire [7:0] g1_cos_coeff_a, g1_sin_coeff_a;
//     wire [7:0] g2_poly_coeff_a, g2_poly_coeff_b, g2_poly_coeff_c;
//     wire [7:0] g2_cos_coeff_a, g2_sin_coeff_a;
     
//     equation_input_module equation_input_inst (
//         .clk(clk),
//         .reset(reset),
//         .graph1_type(graph1_type),
//         .graph2_type(graph2_type),
//         .keypad_input(keypad_input),
//         .keypad_enter_pressed(enter_pressed),
//         .keypad_backspace_pressed(backspace_pressed),
//         .keypad_digit_pressed(digit_pressed),
         
//         .all_inputs_confirmed(all_inputs_confirmed),
//         .current_graph_slot(current_graph_slot),
//         .current_coeff_pos(current_coeff_pos),
//         .temp_coeff(temp_coeff),
//         .digit_count(digit_count),
//         .g1_poly_coeff_a(g1_poly_coeff_a),
//         .g1_poly_coeff_b(g1_poly_coeff_b),
//         .g1_poly_coeff_c(g1_poly_coeff_c),
//         .g1_cos_coeff_a(g1_cos_coeff_a),
//         .g1_sin_coeff_a(g1_sin_coeff_a),
//         .g2_poly_coeff_a(g2_poly_coeff_a),
//         .g2_poly_coeff_b(g2_poly_coeff_b),
//         .g2_poly_coeff_c(g2_poly_coeff_c),
//         .g2_cos_coeff_a(g2_cos_coeff_a),
//         .g2_sin_coeff_a(g2_sin_coeff_a)
//     );
     
//    //keypad bounce protection, the reg is declared
//    reg keypad_enable;
//    // Sequential logic: Control keypad enable
//    always @(posedge clk or posedge reset) begin
//        if (reset) begin
//            keypad_enable <= 1'b0;
//        end else begin
//            case (state)
//                STATE_INPUT: begin
//                    keypad_enable <= 1'b1;
//                end
                
//                default: begin
//                    keypad_enable <= 1'b0;
//                end
//            endcase
//        end
//    end
    
//    // Internal wires and registers
//    reg [2:0] state, next_state; // FSM state registers
    
//    // Sequential logic: Update current state
//    always @(posedge clk or posedge reset) begin
//        if (reset) begin
//            state <= STATE_MAIN_MENU;
//        end else begin
//            state <= next_state;
//        end
//    end
    
//    // Combinational logic: Determine next state
//    always @(*) begin
//        // Default: stay in current state
//        next_state = state;
        
//        case (state)
//            STATE_MAIN_MENU: begin
//                if (btnU_main || btnD_main || btnL_main || btnR_main || btnC_main) begin
//                    next_state = STATE_GRAPH_MENU;
//                end
//            end
            
//            STATE_GRAPH_MENU: begin
//                // Handle btnU/btnD for menu navigation
//                // Handle btnL/btnR for selection
//                // Transition to input states on menu confirmation
//                if (menu_confirmed) begin
//                    next_state = STATE_INPUT;
//                end
//            end
            
//            STATE_INPUT: begin
//                // Handle keypad input logic
//                // Handle enter key to move between coefficients
//                // Transition to STATE_GRAPHING on final enter key press
//                if (all_inputs_confirmed) begin
//                    next_state = STATE_GRAPHING;
//                end
//            end
            
//            STATE_GRAPHING: begin
//                // Logic to display graph on Screen 2
//                // Transition back to STATE_GRAPH_MENU on btnC_debounced
//                //for now its set to 
//                if (btnD) begin
//                    next_state = STATE_GRAPH_MENU;
//                end
//            end
            
//            default: begin
//                next_state = STATE_MAIN_MENU;
//            end
//        endcase
//    end

//    // Module connections and data flow
//    // Connect output from input modules to the graphing module
//    // Connect output from video drivers to the screen outputs
    
//    //stage 1 set of screen ------------------------//
//    wire [15:0] state_main_menu_1;
//    ti85_display_module ti85_display_inst(
//            .freq625m(clk),
//            .pixel_index(pixel_index_1),  //
//            .pixel_data(state_main_menu_1)
//    );
//    wire [15:0] state_main_menu_2;
//    pixel_output_generator pixel_output_generator_inst(
//        .freq625m(clk),
//        .pixel_index(pixel_index_2),
//        .pixel_data(state_main_menu_2)
//    );
    
//    //stage 2 set of screen selection of the graph type ---//
//    wire [15:0] state_graph_menu_1;
//    pixel_output_state_graph_menu pixel_output_state_graph_menu_inst(
//        .freq625m(clk),
//        .cursor_pos(cursor_pos),      // 0 for row 1, 1 for row 2
//        .graph1_type(graph1_type),    // 00=polynomial, 01=cosine, 10=sine
//        .graph2_type(graph2_type),    // 00=polynomial, 01=cosine, 10=sine
//        .pixel_index(pixel_index_1),
//        .pixel_data(state_graph_menu_1)
//    );
    
//    wire [15:0] state_graph_menu_2;
//    confirmation_screen confirmation_screen_inst(
//        .freq625m(clk),
//        .pixel_index(pixel_index_1),
//        .pixel_data(state_graph_menu_2)
//    );
    
//    //stage 3 set of screens ---------------------------------//
//    wire [15:0] state_input_menu_1;
//    equation_display equation_display_inst(
//        .clk(clk),
//        .pixel_index(pixel_index_1),
//        .graph1_type(graph1_type),
//        .graph2_type(graph2_type),
        
//        .g1_poly_coeff_a(g1_poly_coeff_a), .g1_poly_coeff_b(g1_poly_coeff_b), .g1_poly_coeff_c(g1_poly_coeff_c),
//        .g1_cos_coeff_a(g1_cos_coeff_a), .g1_sin_coeff_a(g1_sin_coeff_a),
        
//        .g2_poly_coeff_a(g2_poly_coeff_a), .g2_poly_coeff_b(g2_poly_coeff_b), .g2_poly_coeff_c(g2_poly_coeff_c),
//        .g2_cos_coeff_a(g2_cos_coeff_a), .g2_sin_coeff_a(g2_sin_coeff_a),
        
//        .temp_coeff(temp_coeff), .digit_count(digit_count),
//        .current_graph_slot(current_graph_slot), .current_coeff_pos(current_coeff_pos),
        
//        .pixel_color(state_input_menu_1)
//    );
    
//    wire [15:0] state_input_menu_2;
//    keypad_screen keypad_screen_inst(
//        .freq625m(clk),
//        .row_pos(row_pos),        // Cursor row position (0-3)
//        .col_pos(col_pos),        // Cursor column position (0-2)
//        .pixel_index(pixel_index_2),
//        .pixel_data(state_input_menu_2)
//    );
    
//    //stage 4 set of screens - GRAPHING-------------------------------------//
//    wire [15:0] state_graphing_menu_1;
//    graph_plotter graph_display_1(
//        .clk(clk),
//        .reset(reset),
//        .pixel_index(pixel_index_1),
        
//        // Graph types
//        .graph1_type(graph1_type),
//        .graph2_type(graph2_type),
        
//        // Graph 1 coefficients
//        .g1_poly_coeff_a(g1_poly_coeff_a),
//        .g1_poly_coeff_b(g1_poly_coeff_b),
//        .g1_poly_coeff_c(g1_poly_coeff_c),
//        .g1_cos_coeff_a(g1_cos_coeff_a),
//        .g1_sin_coeff_a(g1_sin_coeff_a),
        
//        // Graph 2 coefficients
//        .g2_poly_coeff_a(g2_poly_coeff_a),
//        .g2_poly_coeff_b(g2_poly_coeff_b),
//        .g2_poly_coeff_c(g2_poly_coeff_c),
//        .g2_cos_coeff_a(g2_cos_coeff_a),
//        .g2_sin_coeff_a(g2_sin_coeff_a),
        
//        .pixel_data(state_graphing_menu_1)
//    );
    
//    wire [15:0] state_graphing_menu_2;
//    graph_plotter graph_display_2(
//        .clk(clk),
//        .reset(reset),
//        .pixel_index(pixel_index_2),
        
//        // Graph types
//        .graph1_type(graph1_type),
//        .graph2_type(graph2_type),
        
//        // Graph 1 coefficients
//        .g1_poly_coeff_a(g1_poly_coeff_a),
//        .g1_poly_coeff_b(g1_poly_coeff_b),
//        .g1_poly_coeff_c(g1_poly_coeff_c),
//        .g1_cos_coeff_a(g1_cos_coeff_a),
//        .g1_sin_coeff_a(g1_sin_coeff_a),
        
//        // Graph 2 coefficients
//        .g2_poly_coeff_a(g2_poly_coeff_a),
//        .g2_poly_coeff_b(g2_poly_coeff_b),
//        .g2_poly_coeff_c(g2_poly_coeff_c),
//        .g2_cos_coeff_a(g2_cos_coeff_a),
//        .g2_sin_coeff_a(g2_sin_coeff_a),
        
//        .pixel_data(state_graphing_menu_2)
//    );
    
//    //============================================================//
//    // MUX Display Output Based on FSM State
//    //============================================================//
//    always @(*) begin
//        case (state)
//            STATE_MAIN_MENU: begin
//                screen1_data = state_main_menu_1;
//                screen2_data = state_main_menu_2;
//            end
            
//            STATE_GRAPH_MENU: begin
//                screen1_data = state_graph_menu_1;
//                screen2_data = state_graph_menu_2;
//            end
            
//            STATE_INPUT: begin
//                screen1_data = state_input_menu_1;
//                screen2_data = state_input_menu_2;
//            end
            
//            STATE_GRAPHING: begin
//                screen1_data = state_graphing_menu_1;
//                screen2_data = state_graphing_menu_2;
//            end
//        endcase
//    end

//endmodule

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
    output reg [15:0] screen2_data,
    
    //FSM DEBUGGING
    output wire [2:0] fsm_state_debug,
    output wire cursor_pos_debug,
    output wire [1:0] graph1_type_debug,
    output wire [1:0] graph2_type_debug,
    output wire [1:0] row_pos_debug,
    output wire [1:0] col_pos_debug,
    output wire [7:0] temp_coeff_debug,
    output wire [1:0] digit_count_debug,
    output wire all_inputs_confirmed_debug,
    output wire [7:0] g1_cos_coeff_a_debug, 
    output wire [7:0] g1_sin_coeff_a_debug,
    output wire [7:0] g2_cos_coeff_a_debug, 
    output wire [7:0] g2_sin_coeff_a_debug,
    output wire [7:0] g1_poly_coeff_a_debug, g1_poly_coeff_b_debug, g1_poly_coeff_c_debug,
    output wire [7:0] g2_poly_coeff_a_debug, g2_poly_coeff_b_debug, g2_poly_coeff_c_debug,
    output wire [1:0] current_graph_slot_debug,
    output wire [3:0] current_coeff_pos_debug
);
    //parameter declarations
    localparam STATE_MAIN_MENU = 3'b000;
    localparam STATE_GRAPH_MENU = 3'b001;
    localparam STATE_INPUT = 3'b010;
    localparam STATE_GRAPHING = 3'b011;
    
    //debugging lines
    assign fsm_state_debug = state;
    assign cursor_pos_debug = cursor_pos;
    assign graph1_type_debug = graph1_type;
    assign graph2_type_debug = graph2_type;
    assign row_pos_debug = row_pos;
    assign col_pos_debug = col_pos;
    assign temp_coeff_debug = temp_coeff;
    assign digit_count_debug = digit_count;
    assign all_inputs_confirmed_debug = all_inputs_confirmed;
    assign g1_cos_coeff_a_debug = g1_cos_coeff_a;
    assign g1_sin_coeff_a_debug = g1_sin_coeff_a;
    assign g2_cos_coeff_a_debug = g2_cos_coeff_a;
    assign g2_sin_coeff_a_debug = g2_sin_coeff_a;
    assign g1_poly_coeff_a_debug= g1_poly_coeff_a;
    assign g1_poly_coeff_b_debug = g1_poly_coeff_b;
    assign g1_poly_coeff_c_debug = g1_poly_coeff_c;
    assign g2_poly_coeff_a_debug = g2_poly_coeff_a;
    assign g2_poly_coeff_b_debug = g2_poly_coeff_b;
    assign g2_poly_coeff_c_debug = g2_poly_coeff_c;
    assign current_graph_slot_debug = current_graph_slot;
    assign current_coeff_pos_debug = current_coeff_pos;
    
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
     wire is_negative;  // NEW: Wire for negative flag
     
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
        .is_negative(is_negative),  // NEW: Pass to display
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