//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Module: Top_Student
//// Description: Top module for OLED math game with timer
////////////////////////////////////////////////////////////////////////////////////

//module Top_Student (
//    input clk, 
//    input btnC_raw,
//    input btnU_raw,
//    input btnD_raw,
//    input btnL_raw,
//    input btnR_raw,
//    input [15:0] sw,
//    inout PS2Clk,
//    inout PS2Data,
//    output reg [6:0] seg, 
//    output reg [3:0] an,  
//    output [15:0] led,
//    output [7:0] JB 
//);

//    //================================================================
//    // Clock Generation
//    //================================================================
//    wire clk_6p25M;
//    wire clk_anode_switch;
    
//    flexible_clock clk_6p25M_gen (
//        .clk(clk), 
//        .m(32'd7),
//        .slow_clock(clk_6p25M)
//    );
    
//    flexible_clock clk_anode_gen (
//        .clk(clk),
//        .m(32'd100_000),
//        .slow_clock(clk_anode_switch)
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
//    wire [4:0] timer_count;
    
//    game_state game_logic (
//        .clk(clk),
//        .reset(btn_up),
//        .btn_start(btn_center),
//        .btn_correct(btn_left),
//        .btn_wrong(btn_right),
//        .state(game_state),
//        .score(score),
//        .mistakes(mistakes),
//        .question_num(question_num),
//        .operand1(operand1),
//        .operand2(operand2),
//        .result(result),
//        .operation(operation),
//        .timer_count(timer_count)
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
//        .timer_count(timer_count),
//        .pixel_data(pixel_data)
//    );
    
//    Oled_Display oled_driver (
//        .clk(clk_6p25M),
//        .reset(btn_up),
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
//    // LED Feedback Logic
//    //================================================================
//    reg [15:0] led_feedback = 16'b0;
//    reg [3:0] prev_score = 4'd0;
//    reg [3:0] prev_question = 4'd0;
//    reg [1:0] prev_game_state = 2'b00;
    
//    reg [23:0] flash_counter = 24'd0;
//    reg flash_active = 1'b0;
//    localparam FLASH_DURATION = 24'd15_000_000;
    
//    always @(posedge clk) begin
//        if (btn_up) begin
//            led_feedback    <= 16'b0;
//            prev_score      <= 4'd0;
//            prev_question   <= 4'd0;
//            prev_game_state <= 2'b00;
//            flash_active    <= 1'b0;
//            flash_counter   <= 24'd0;
//        end else begin
//            if (game_state != prev_game_state) begin
//                prev_game_state <= game_state;
//                if (game_state == 2'b00) begin
//                    prev_score    <= 4'd0;
//                    led_feedback  <= 16'b0;
//                    flash_active  <= 1'b0;
//                    flash_counter <= 24'd0;
//                end
//            end
    
//            if (question_num != prev_question) begin
//                led_feedback  <= 16'b0;
//                flash_active  <= 1'b0;
//                flash_counter <= 24'd0;
//                prev_question <= question_num;
//            end
//            else if (score > prev_score) begin
//                led_feedback  <= 16'hFFFF;
//                flash_active  <= 1'b1;
//                flash_counter <= 24'd0;
//                prev_score    <= score;
//            end
//            else if (flash_active) begin
//                if (flash_counter >= FLASH_DURATION - 1) begin
//                    led_feedback  <= 16'b0;
//                    flash_active  <= 1'b0;
//                    flash_counter <= 24'd0;
//                end else begin
//                    flash_counter <= flash_counter + 1;
//                end
//            end
//        end
//    end
    
//    assign led = led_feedback;
    
//    //================================================================
//    // 7-Segment Display - Shows Timer during game, Score at end
//    //================================================================
//    localparam HOME = 2'b00;
//    localparam PLAYING = 2'b01;
//    localparam GAME_OVER = 2'b10;
//    localparam CORRECT_PAUSE = 2'b11;
    
//    wire [3:0] timer_tens = timer_count / 10;
//    wire [3:0] timer_ones = timer_count % 10;
    
//    reg [1:0] anode_counter = 2'b00;
    
//    always @(posedge clk_anode_switch) begin
//        if (btn_up) begin
//            anode_counter <= 2'b00;
//        end else begin
//            anode_counter <= anode_counter + 1;
//        end
//    end
    
//    reg [3:0] current_digit;
    
//    always @(*) begin
//        if (game_state == PLAYING || game_state == CORRECT_PAUSE) begin
//            // Show timer (2 digits)
//            case (anode_counter)
//                2'b00: begin
//                    an = 4'b1110;  // Rightmost digit (ones)
//                    current_digit = timer_ones;
//                end
//                2'b01: begin
//                    an = 4'b1101;  // Tens digit
//                    current_digit = timer_tens;
//                end
//                2'b10: begin
//                    an = 4'b1011;
//                    current_digit = 4'd10;  // Blank
//                end
//                2'b11: begin
//                    an = 4'b0111;
//                    current_digit = 4'd10;  // Blank
//                end
//            endcase
//        end else begin
//            // Show score (single digit)
//            an = 4'b1110;  // Rightmost digit only
//            current_digit = score;
//        end
        
//        // 7-segment decoder
//        case (current_digit)
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
//            default: seg = 7'b1111111;  // Blank
//        endcase
//    end

//endmodule



`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: Top_Student
// Description: Top module for OLED math game with timer
//////////////////////////////////////////////////////////////////////////////////

module Top_Student (
    input clk, 
    input btnC_raw,
    input btnU_raw,
    input btnD_raw,
    input btnL_raw,
    input btnR_raw,
    input [15:0] sw,
    inout PS2Clk,
    inout PS2Data,
    output reg [6:0] seg, 
    output reg [3:0] an,  
    output [15:0] led,
    output [7:0] JB 
);

    //================================================================
    // Clock Generation
    //================================================================
    wire clk_6p25M;
    wire clk_anode_switch;
    
    flexible_clock clk_6p25M_gen (
        .clk(clk), 
        .m(32'd7),
        .slow_clock(clk_6p25M)
    );
    
    flexible_clock clk_anode_gen (
        .clk(clk),
        .m(32'd100_000),
        .slow_clock(clk_anode_switch)
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
    wire [4:0] timer_count;
    
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
        .operation(operation),
        .timer_count(timer_count)
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
        .timer_count(timer_count),
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
    
    //================================================================
    // LED Feedback Logic
    //================================================================
    reg [15:0] led_feedback = 16'b0;
    reg [3:0] prev_score = 4'd0;
    reg [3:0] prev_question = 4'd0;
    reg [1:0] prev_game_state = 2'b00;
    
    reg [23:0] flash_counter = 24'd0;
    reg flash_active = 1'b0;
    localparam FLASH_DURATION = 24'd15_000_000;
    
    always @(posedge clk) begin
        if (btn_up) begin
            led_feedback    <= 16'b0;
            prev_score      <= 4'd0;
            prev_question   <= 4'd0;
            prev_game_state <= 2'b00;
            flash_active    <= 1'b0;
            flash_counter   <= 24'd0;
        end else begin
            if (game_state != prev_game_state) begin
                prev_game_state <= game_state;
                if (game_state == 2'b00) begin
                    prev_score    <= 4'd0;
                    led_feedback  <= 16'b0;
                    flash_active  <= 1'b0;
                    flash_counter <= 24'd0;
                end
            end
    
            if (question_num != prev_question) begin
                led_feedback  <= 16'b0;
                flash_active  <= 1'b0;
                flash_counter <= 24'd0;
                prev_question <= question_num;
            end
            else if (score > prev_score) begin
                led_feedback  <= 16'hFFFF;
                flash_active  <= 1'b1;
                flash_counter <= 24'd0;
                prev_score    <= score;
            end
            else if (flash_active) begin
                if (flash_counter >= FLASH_DURATION - 1) begin
                    led_feedback  <= 16'b0;
                    flash_active  <= 1'b0;
                    flash_counter <= 24'd0;
                end else begin
                    flash_counter <= flash_counter + 1;
                end
            end
        end
    end
    
    assign led = led_feedback;
    
    //================================================================
    // 7-Segment Display - Shows Timer during game, Score at end
    //================================================================
    localparam HOME = 2'b00;
    localparam PLAYING = 2'b01;
    localparam GAME_OVER = 2'b10;
    localparam CORRECT_PAUSE = 2'b11;
    
    wire [3:0] timer_tens = timer_count / 10;
    wire [3:0] timer_ones = timer_count % 10;
    wire [3:0] score_tens = score / 10;
    wire [3:0] score_ones = score % 10;
    
    reg [1:0] anode_counter = 2'b00;
    
    always @(posedge clk_anode_switch) begin
        if (btn_up) begin
            anode_counter <= 2'b00;
        end else begin
            anode_counter <= anode_counter + 1;
        end
    end
    
    reg [3:0] current_digit;
    
    always @(*) begin
        if (game_state == PLAYING || game_state == CORRECT_PAUSE) begin
            // Show timer (2 digits)
            case (anode_counter)
                2'b00: begin
                    an = 4'b1110;  // Rightmost digit (ones)
                    current_digit = timer_ones;
                end
                2'b01: begin
                    an = 4'b1101;  // Tens digit
                    current_digit = (timer_count >= 10) ? timer_tens : 4'd10;  // Blank if less than 10
                end
                2'b10: begin
                    an = 4'b1011;
                    current_digit = 4'd10;  // Blank
                end
                2'b11: begin
                    an = 4'b0111;
                    current_digit = 4'd10;  // Blank
                end
            endcase
        end else begin
            // Show score (2 digits for HOME and GAME_OVER)
            case (anode_counter)
                2'b00: begin
                    an = 4'b1110;  // Rightmost digit (ones)
                    current_digit = score_ones;
                end
                2'b01: begin
                    an = 4'b1101;  // Tens digit
                    current_digit = (score >= 10) ? score_tens : 4'd10;  // Blank if less than 10
                end
                2'b10: begin
                    an = 4'b1011;
                    current_digit = 4'd10;  // Blank
                end
                2'b11: begin
                    an = 4'b0111;
                    current_digit = 4'd10;  // Blank
                end
            endcase
        end
        
        // 7-segment decoder
        case (current_digit)
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
            default: seg = 7'b1111111;  // Blank
        endcase
    end

endmodule