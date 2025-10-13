//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Module: Top_Student
//// Description: Top module for OLED math game
////////////////////////////////////////////////////////////////////////////////////

//module Top_Student (
//    input clk, 
//    input btnC_raw,    // Center - Start/Next
//    input btnU_raw,    // Up (unused)
//    input btnD_raw,    // Down (unused) 
//    input btnL_raw,    // Left - Correct answer
//    input btnR_raw,    // Right - Wrong answer
//    input [15:0] sw,
//    inout PS2Clk,
//    inout PS2Data,
//    output reg [6:0] seg, 
//    output [3:0] an,  
//    output [15:0] led,
//    output [7:0] JB 
//);

//    //================================================================
//    // Clock Generation
//    //================================================================
//    wire clk_6p25M;
    
//    flexible_clock clk_6p25M_gen (
//        .clk(clk), 
//        .m(32'd7),
//        .slow_clock(clk_6p25M)
//    );
    
//    //================================================================
//    // Button Debouncing
//    //================================================================
//    wire btn_center, btn_left, btn_right, btn_up, btn_down;
    
//    debounce deb_C (.clk(clk), .pb_1(btnC_raw), .pb_out(btn_center));
//    debounce deb_L (.clk(clk), .pb_1(btnL_raw), .pb_out(btn_left));
//    debounce deb_R (.clk(clk), .pb_1(btnR_raw), .pb_out(btn_right));
//    debounce deb_U (.clk(clk), .pb_1(btnU_raw), .pb_out(btn_up));
//    debounce deb_D (.clk(clk), .pb_1(btnD_raw), .pb_out(btn_down));

//    //================================================================
//    // Game State Logic
//    //================================================================
//    wire [1:0] game_state;
//    wire [3:0] score, mistakes, question_num;
//    wire [7:0] operand1, operand2, result;
//    wire [1:0] operation;
    
//game_state game_logic (
//        .clk(clk),
//        .reset(btn_up),          // ? CHANGED: Use UP button for reset
//        .btn_start(btn_center),  // Center button starts/continues game
//        .btn_correct(btn_left),
//        .btn_wrong(btn_right),
//        .state(game_state),
//        .score(score),
//        .mistakes(mistakes),
//        .question_num(question_num),
//        .operand1(operand1),
//        .operand2(operand2),
//        .result(result),
//        .operation(operation)
//    );

//    //================================================================
//    // OLED Display
//    //================================================================
//    wire [12:0] oled_pixel_index;
//    wire [15:0] pixel_data;
//    wire oled_cs, oled_sdin, oled_sclk, oled_dc, oled_resn, oled_vccen, oled_pmoden;
    
//    game_display display (
//        .clk_6p25M(clk_6p25M),
//        .pixel_index(oled_pixel_index),
//        .game_state(game_state),
//        .score(score),
//        .mistakes(mistakes),
//        .question_num(question_num),
//        .operand1(operand1),
//        .operand2(operand2),
//        .result(result),
//        .operation(operation),
//        .pixel_data(pixel_data)
//    );
    
//Oled_Display oled_driver (
//        .clk(clk_6p25M),
//        .reset(btn_up),          // ? CHANGED: Use UP button for reset
//        .pixel_index(oled_pixel_index),
//        .pixel_data(pixel_data),
//        .frame_begin(), 
//        .sending_pixels(),
//        .sample_pixel(),
//        .cs(oled_cs),
//        .sdin(oled_sdin),
//        .sclk(oled_sclk),
//        .d_cn(oled_dc),
//        .resn(oled_resn),
//        .vccen(oled_vccen),
//        .pmoden(oled_pmoden)
//    );

//    //================================================================
//    // OLED Pin Mapping (JB Pmod)
//    //================================================================
//    assign JB[0] = oled_cs;
//    assign JB[1] = oled_sdin;
//    assign JB[2] = 1'b0;
//    assign JB[3] = oled_sclk;
//    assign JB[4] = oled_dc;
//    assign JB[5] = oled_resn;
//    assign JB[6] = oled_vccen;
//    assign JB[7] = oled_pmoden;
    
//    //================================================================
//    // LED Feedback Logic (Responsive & Visible)
//    //================================================================
//    reg [15:0] led_feedback = 16'b0;
//    reg [3:0] prev_score = 4'd0;
//    reg [3:0] prev_question = 4'd0;
//    reg [23:0] led_timer = 0;  // for short visible blink

//    always @(posedge clk) begin
//        if (btn_up) begin
//            // Reset everything
//            led_feedback <= 16'b0;
//            prev_score <= 4'd0;
//            prev_question <= 4'd0;
//            led_timer <= 0;
//        end else begin
//            // Detect new question ? turn LEDs off
//            if (question_num != prev_question) begin
//                led_feedback <= 16'b0;
//                led_timer <= 0;
//                prev_question <= question_num;
//            end
//            // Detect score increase ? correct answer
//            else if (score > prev_score) begin
//                led_feedback <= 16'hFFFF;  // turn ON all LEDs
//                led_timer <= 24'd6_000_000; // ~0.1s blink at 100MHz
//                prev_score <= score;
//            end
//            // Count down the LED timer (keep LEDs on briefly)
//            else if (led_timer > 0) begin
//                led_timer <= led_timer - 1;
//                if (led_timer == 1)
//                    led_feedback <= 16'b0;  // turn off when timer expires
//            end
//        end
//    end

//    //================================================================
//    // LED Output Assignment
//    //================================================================
//    assign led = led_feedback;
//    //================================================================
//    // 7-Segment Display (Shows Score)
//    //================================================================
//    assign an = 4'b1110;  // Only rightmost digit
    
//    always @(*) begin
//        case (score)
//            4'd0: seg = 7'b1000000;
//            4'd1: seg = 7'b1111001;
//            4'd2: seg = 7'b0100100;
//            4'd3: seg = 7'b0110000;
//            4'd4: seg = 7'b0011001;
//            4'd5: seg = 7'b0010010;
//            4'd6: seg = 7'b0000010;
//            4'd7: seg = 7'b1111000;
//            4'd8: seg = 7'b0000000;
//            4'd9: seg = 7'b0010000;
//            default: seg = 7'b1111111;
//        endcase
//    end

//endmodule

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
    wire clk_led_flash;  // Clock for LED flash timing
    
    flexible_clock clk_6p25M_gen (
        .clk(clk), 
        .m(32'd7),
        .slow_clock(clk_6p25M)
    );
    
    // Generate ~6.67Hz clock for LED flash (0.15s period)
    // 100MHz / 15_000_000 = 6.67Hz (0.15s period)
    flexible_clock clk_led_gen (
        .clk(clk),
        .m(32'd15_000_000),
        .slow_clock(clk_led_flash)
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
        .reset(btn_up),
        .btn_start(btn_center),
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
        .reset(btn_up),
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
    
//    //================================================================
//    // LED Feedback Logic (Responsive & Visible)
//    //================================================================
//    reg [15:0] led_feedback = 16'b0;
//    reg [3:0] prev_score = 4'd0;
//    reg [3:0] prev_question = 4'd0;
//    reg [1:0] prev_game_state = 2'b00;
//    reg flash_active = 1'b0;

//    always @(posedge clk_led_flash) begin
//        if (btn_up) begin
//            // Reset everything
//            led_feedback <= 16'b0;
//            prev_score <= 4'd0;
//            prev_question <= 4'd0;
//            prev_game_state <= 2'b00;
//            flash_active <= 1'b0;
//        end else begin
//            // Detect game state change to HOME - reset prev_score
//            if (game_state != prev_game_state) begin
//                prev_game_state <= game_state;
//                if (game_state == 2'b00) begin  // HOME state
//                    prev_score <= 4'd0;
//                    led_feedback <= 16'b0;
//                    flash_active <= 1'b0;
//                end
//            end
            
//            // Detect new question - turn LEDs off
//            if (question_num != prev_question) begin
//                led_feedback <= 16'b0;
//                flash_active <= 1'b0;
//                prev_question <= question_num;
//            end
//            // Detect score increase - correct answer
//            else if (score > prev_score) begin
//                led_feedback <= 16'hFFFF;  // turn ON all LEDs
//                flash_active <= 1'b1;      // start flash
//                prev_score <= score;
//            end
//            // Turn off LEDs after one clock cycle (0.15s)
//            else if (flash_active) begin
//                led_feedback <= 16'b0;
//                flash_active <= 1'b0;
//            end
//        end
//    end

//    //================================================================
//    // LED Output Assignment
//    //================================================================
//    assign led = led_feedback;



//================================================================
// LED Feedback Logic (Instant Flash with 0.15s Duration)
//================================================================
reg [15:0] led_feedback = 16'b0;
reg [3:0] prev_score = 4'd0;
reg [3:0] prev_question = 4'd0;
reg [1:0] prev_game_state = 2'b00;

// Timer for 0.15s flash duration
reg [23:0] flash_counter = 24'd0;
reg flash_active = 1'b0;
localparam FLASH_DURATION = 24'd15_000_000; // 0.15s at 100MHz

always @(posedge clk) begin
    if (btn_up) begin
        led_feedback    <= 16'b0;
        prev_score      <= 4'd0;
        prev_question   <= 4'd0;
        prev_game_state <= 2'b00;
        flash_active    <= 1'b0;
        flash_counter   <= 24'd0;
    end else begin
        // Detect game state change ? reset when returning to HOME
        if (game_state != prev_game_state) begin
            prev_game_state <= game_state;
            if (game_state == 2'b00) begin
                prev_score    <= 4'd0;
                led_feedback  <= 16'b0;
                flash_active  <= 1'b0;
                flash_counter <= 24'd0;
            end
        end

        // Detect new question ? turn LEDs off
        if (question_num != prev_question) begin
            led_feedback  <= 16'b0;
            flash_active  <= 1'b0;
            flash_counter <= 24'd0;
            prev_question <= question_num;
        end
        // Detect score increase ? correct answer (INSTANT flash start)
        else if (score > prev_score) begin
            led_feedback  <= 16'hFFFF;  // Turn ON instantly
            flash_active  <= 1'b1;
            flash_counter <= 24'd0;     // Reset timer
            prev_score    <= score;
        end
        // Handle flash timing
        else if (flash_active) begin
            if (flash_counter >= FLASH_DURATION - 1) begin
                // Timer expired - turn off LEDs
                led_feedback  <= 16'b0;
                flash_active  <= 1'b0;
                flash_counter <= 24'd0;
            end else begin
                // Keep counting
                flash_counter <= flash_counter + 1;
            end
        end
    end
end

//================================================================
// LED Output Assignment
//================================================================
assign led = led_feedback;

    
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
