/*
 * Module: Top_Student
 * Description: Top module with equation menu and quadratic input screen
 */
`timescale 1ns / 1ps

module Equations_mode (
    input clk, 
    input btnC_raw,
    input btnU_raw, 
    input btnD_raw, 
    input btnL_raw, 
    input btnR_raw,
    input [15:0] sw,  // Switches for number input
    inout PS2Clk,
    inout PS2Data,
    output [6:0] seg, 
    output [3:0] an,  
    output [15:0] led,
    output [7:0] JB 
);

    //================================================================
    // Wire Declarations
    //================================================================
    
    wire clk_25M, clk_12p5M, clk_6p25M, slow_clk;
    wire reset_trigger_p, up_button_p, down_button_p, left_button_p, right_button_p;
    reg back_button_p;  // Assigned based on state
    wire [11:0] mouse_x_pos, mouse_y_pos; 
    wire mouse_left_click;
    wire mouse_middle_click, mouse_right_click;
    wire [3:0] mouse_z_pos;
    wire mouse_new_event; 
    
    wire [12:0] oled_pixel_index;
    wire [15:0] menu_pixel_data;
    wire [15:0] quadratic_pixel_data;
    wire [15:0] final_pixel_data;
    
    wire oled_cs, oled_sdin, oled_sclk, oled_dc, oled_resn, oled_vccen, oled_pmoden;
    
    wire [2:0] selected_option;
    wire [9:0] coeff_a, coeff_b, coeff_c;
    
    //================================================================
    // State Machine
    //================================================================
    
    localparam STATE_MENU = 2'd0;
    localparam STATE_QUADRATIC = 2'd3;
    
    reg [1:0] current_state;
    reg clear_menu_selection;
    reg select_button;  // Combined select button signal
    
    // Select button is UP in menu, but becomes LEFT (back) in other screens
    always @(*) begin
        if (current_state == STATE_MENU)
            select_button = up_button_p;  // UP selects in menu
        else
            select_button = 0;
        
        // Back button is LEFT button in quadratic screen
        if (current_state == STATE_QUADRATIC)
            back_button_p = left_button_p;  // LEFT goes back in quadratic
        else
            back_button_p = 0;
    end
    
    always @(posedge clk) begin
        if (reset_trigger_p) begin
            current_state <= STATE_MENU;
            clear_menu_selection <= 0;
        end else begin
            clear_menu_selection <= 0;  // Default: don't clear
            
            case (current_state)
                STATE_MENU: begin
                    if (selected_option == 3) begin
                        current_state <= STATE_QUADRATIC;
                        clear_menu_selection <= 1;  // Clear selection after transition
                    end
                end
                
                STATE_QUADRATIC: begin
                    if (back_button_p) begin
                        current_state <= STATE_MENU;
                    end
                end
                
                default: current_state <= STATE_MENU;
            endcase
        end
    end
    
    // Pixel data multiplexer
    assign final_pixel_data = (current_state == STATE_QUADRATIC) ? quadratic_pixel_data : menu_pixel_data;
    
    //================================================================
    // Clock Generation
    //================================================================
    
    flexible_clock clk_25M_gen (
        .clk(clk), 
        .m(32'd1),
        .slow_clock(clk_25M)
    );
    
    flexible_clock clk_12p5M_gen (
        .clk(clk), 
        .m(32'd3),
        .slow_clock(clk_12p5M)
    );
    
    flexible_clock clk_6p25M_gen (
        .clk(clk), 
        .m(32'd7),
        .slow_clock(clk_6p25M)
    );
    
    flexible_clock slow_clk_gen (
        .clk(clk), 
        .m(32'd49999999),
        .slow_clock(slow_clk)
    );
    
    //================================================================
    // Button Debouncing
    //================================================================
    
    debounce deb_C ( 
        .clk(clk), 
        .pb_1(btnC_raw), 
        .pb_out(reset_trigger_p) 
    );
    
    debounce deb_D ( 
        .clk(clk), 
        .pb_1(btnD_raw), 
        .pb_out(down_button_p) 
    );
    
    debounce deb_U ( 
        .clk(clk), 
        .pb_1(btnU_raw), 
        .pb_out(up_button_p) 
    );
    
    debounce deb_L ( 
        .clk(clk), 
        .pb_1(btnL_raw), 
        .pb_out(left_button_p) 
    );
    
    debounce deb_R ( 
        .clk(clk), 
        .pb_1(btnR_raw), 
        .pb_out(right_button_p) 
    );

    //================================================================
    // Mouse Controller
    //================================================================
    
    MouseCtl_Verilog_Wrapper mouse_inst (
        .clk(clk),
        .rst(reset_trigger_p), 
        .xpos(mouse_x_pos),
        .ypos(mouse_y_pos),
        .left(mouse_left_click),
        .middle(mouse_middle_click),
        .right(mouse_right_click),
        .new_event(mouse_new_event),
        .zpos(mouse_z_pos),
        .ps2_clk(PS2Clk),
        .ps2_data(PS2Data)
    );

    //================================================================
    // Equation Menu
    //================================================================
    
    equation_menu menu_inst (
        .clk_6p25M(clk_6p25M),
        .reset(reset_trigger_p),
        .btn_up(up_button_p),
        .btn_down(down_button_p),
        .btn_select(select_button),
        .pixel_index(oled_pixel_index),
        .clear_selection(clear_menu_selection),
        .pixel_data(menu_pixel_data),
        .selected_option(selected_option)
    );

    //================================================================
    // Quadratic Input Screen
    //================================================================
    
    quadratic_input quadratic_inst (
        .clk_6p25M(clk_6p25M),
        .clk_100M(clk),
        .reset(reset_trigger_p),
        .switches(sw[15:0]),
        .btn_left(left_button_p),
        .btn_right(right_button_p),
        .btn_select(down_button_p),  // DOWN button is select/activate
        .pixel_index(oled_pixel_index),
        .pixel_data(quadratic_pixel_data),
        .coeff_a(coeff_a),
        .coeff_b(coeff_b),
        .coeff_c(coeff_c)
    );
    
    //================================================================
    // OLED Driver
    //================================================================
    
    Oled_Display oled_inst (
        .clk(clk_6p25M),
        .reset(reset_trigger_p),
        .pixel_index(oled_pixel_index),
        .pixel_data(final_pixel_data),
        .frame_begin(), 
        .sending_pixels(),
        .sample_pixel(),
        .cs(oled_cs),
        .sdin(oled_sdin),
        .sclk(oled_sclk),
        .d_cn(oled_dc),
        .resn(oled_resn),
        .vccen(oled_vccen),
        .pmoden(oled_pmoden)
    );

    //================================================================
    // OLED Pin Mapping
    //================================================================
    
    assign JB[0] = oled_cs;
    assign JB[1] = oled_sdin;
    assign JB[2] = 1'b0;
    assign JB[3] = oled_sclk;
    assign JB[4] = oled_dc;
    assign JB[5] = oled_resn;
    assign JB[6] = oled_vccen;
    assign JB[7] = oled_pmoden;
    
    //================================================================
    // LED Debug Output
    //================================================================
    
    assign led[1:0] = current_state;      // Show current state
    assign led[4:2] = selected_option;    // Show selected menu option
    assign led[15:6] = coeff_a;           // Show coefficient a value
    
    //================================================================
    // 7-Segment Display
    //================================================================
    
    assign an = 4'b1110;
    assign seg = 7'b1111111;  // All off for now

endmodule