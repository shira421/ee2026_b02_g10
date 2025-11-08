`timescale 1ns / 1ps

module maths_game (
    input clk,
    input clk_6p25M,        // 6.25MHz clock input (from calling_module)
    input btnCD,
    input btnUD,
    input btnDD,
    input btnLD,
    input btnRD,
    output reg [6:0] seg, 
    output reg [3:0] an,  
    output [15:0] led,
    // OLED interface signals
    input [12:0] pixel_index,
    output [15:0] oled_data
);

    //================================================================
    // Clock Generation - Only need anode switch clock now
    //================================================================
    wire clk_anode_switch;
    
    flexible_clock clk_anode_gen (
        .clk(clk),
        .m(32'd100_000),
        .slow_clock(clk_anode_switch)
    );
    
    //================================================================
    // Game State Logic
    //================================================================
    wire [1:0] game_state;
    wire [9:0] score;
    wire [3:0] mistakes, question_num;
    wire [7:0] operand1, operand2, result;
    wire [1:0] operation;
    wire [4:0] timer_count;
    
    game_state game_logic (
        .clk(clk),
        .reset(btnUD),
        .btn_start(btnCD),
        .btn_correct(btnLD),
        .btn_wrong(btnRD),
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
    // Game Display Logic (generates pixel data)
    // Uses the 6.25MHz clock from input
    //================================================================
    game_display display (
        .clk_6p25M(clk_6p25M),      // Use input clock
        .pixel_index(pixel_index),
        .game_state(game_state),
        .score(score),
        .mistakes(mistakes),
        .question_num(question_num),
        .operand1(operand1),
        .operand2(operand2),
        .result(result),
        .operation(operation),
        .timer_count(timer_count),
        .pixel_data(oled_data)
    );
    
    //================================================================
    // LED Feedback Logic
    //================================================================
    reg [15:0] led_feedback = 16'b0;
    reg [9:0] prev_score = 10'd0;
    reg [3:0] prev_question = 4'd0;
    reg [1:0] prev_game_state = 2'b00;
    
    reg [23:0] flash_counter = 24'd0;
    reg flash_active = 1'b0;
    localparam FLASH_DURATION = 24'd15_000_000;
    
    always @(posedge clk) begin
        if (btnUD) begin
            led_feedback    <= 16'b0;
            prev_score      <= 10'd0;
            prev_question   <= 4'd0;
            prev_game_state <= 2'b00;
            flash_active    <= 1'b0;
            flash_counter   <= 24'd0;
        end else begin
            if (game_state != prev_game_state) begin
                prev_game_state <= game_state;
                if (game_state == 2'b00) begin
                    prev_score    <= 10'd0;
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
    wire [3:0] score_hundreds = score / 100;
    wire [3:0] score_tens = (score % 100) / 10;
    wire [3:0] score_ones = score % 10;
    
    reg [1:0] anode_counter = 2'b00;
    
    always @(posedge clk_anode_switch) begin
        if (btnUD) begin
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
            // Show score (up to 3 digits for HOME and GAME_OVER)
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
                    an = 4'b1011;  // Hundreds digit
                    current_digit = (score >= 100) ? score_hundreds : 4'd10;  // Blank if less than 100
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
