`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: Top_Student
// Description: Top module for OLED math game
//////////////////////////////////////////////////////////////////////////////////

module Top_Student (
    input clk, 
    input btnC_raw,    // Center - Start/Next
    input btnU_raw,    // Up (unused)
    input btnD_raw,    // Down (unused) 
    input btnL_raw,    // Left - Correct answer
    input btnR_raw,    // Right - Wrong answer
    input [15:0] sw,
    inout PS2Clk,
    inout PS2Data,
    output reg [6:0] seg, 
    output [3:0] an,  
    output [15:0] led,
    output [7:0] JB 
);

    //================================================================
    // Clock Generation
    //================================================================
    wire clk_6p25M;
    
    flexible_clock clk_6p25M_gen (
        .clk(clk), 
        .m(32'd7),
        .slow_clock(clk_6p25M)
    );
    
    //================================================================
    // Button Debouncing
    //================================================================
    wire btn_center, btn_left, btn_right, btn_up, btn_down;
    
    debounce deb_C (.clk(clk), .pb_1(btnC_raw), .pb_out(btn_center));
    debounce deb_L (.clk(clk), .pb_1(btnL_raw), .pb_out(btn_left));
    debounce deb_R (.clk(clk), .pb_1(btnR_raw), .pb_out(btn_right));
    debounce deb_U (.clk(clk), .pb_1(btnU_raw), .pb_out(btn_up));
    debounce deb_D (.clk(clk), .pb_1(btnD_raw), .pb_out(btn_down));

    //================================================================
    // Game State Logic
    //================================================================
    wire [1:0] game_state;
    wire [3:0] score, mistakes, question_num;
    wire [7:0] operand1, operand2, result;
    wire [1:0] operation;
    
game_state game_logic (
        .clk(clk),
        .reset(btn_up),          // ? CHANGED: Use UP button for reset
        .btn_start(btn_center),  // Center button starts/continues game
        .btn_correct(btn_left),
        .btn_wrong(btn_right),
        .state(game_state),
        .score(score),
        .mistakes(mistakes),
        .question_num(question_num),
        .operand1(operand1),
        .operand2(operand2),
        .result(result),
        .operation(operation)
    );

    //================================================================
    // OLED Display
    //================================================================
    wire [12:0] oled_pixel_index;
    wire [15:0] pixel_data;
    wire oled_cs, oled_sdin, oled_sclk, oled_dc, oled_resn, oled_vccen, oled_pmoden;
    
    game_display display (
        .clk_6p25M(clk_6p25M),
        .pixel_index(oled_pixel_index),
        .game_state(game_state),
        .score(score),
        .mistakes(mistakes),
        .question_num(question_num),
        .operand1(operand1),
        .operand2(operand2),
        .result(result),
        .operation(operation),
        .pixel_data(pixel_data)
    );
    
Oled_Display oled_driver (
        .clk(clk_6p25M),
        .reset(btn_up),          // ? CHANGED: Use UP button for reset
        .pixel_index(oled_pixel_index),
        .pixel_data(pixel_data),
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
    // OLED Pin Mapping (JB Pmod)
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
    assign led[1:0] = game_state;
    assign led[5:2] = score;
    assign led[9:6] = mistakes;
    assign led[13:10] = question_num;
    assign led[15:14] = 2'b00;
    
    //================================================================
    // 7-Segment Display (Shows Score)
    //================================================================
    assign an = 4'b1110;  // Only rightmost digit
    
    always @(*) begin
        case (score)
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            default: seg = 7'b1111111;
        endcase
    end

endmodule