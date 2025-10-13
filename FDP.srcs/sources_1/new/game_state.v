`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: game_state
// Description: Math game state machine and question logic for OLED
//////////////////////////////////////////////////////////////////////////////////

module game_state(
    input clk,
    input reset,
    input btn_start,      // Center button - start/next
    input btn_correct,    // Left button - correct answer
    input btn_wrong,      // Right button - wrong answer
    output reg [1:0] state,
    output reg [3:0] score,
    output reg [3:0] mistakes,
    output reg [3:0] question_num,
    output reg [7:0] operand1,
    output reg [7:0] operand2,
    output reg [7:0] result,
    output reg [1:0] operation
);

    // States
    localparam HOME = 2'b00;
    localparam PLAYING = 2'b01;
    localparam GAME_OVER = 2'b10;
    
    // Operations
    localparam OP_ADD = 2'b00;
    localparam OP_SUB = 2'b01;
    localparam OP_DIV = 2'b10;

    // Edge detection
    reg btn_start_prev, btn_correct_prev, btn_wrong_prev;
    wire btn_start_edge = btn_start && !btn_start_prev;
    wire btn_correct_edge = btn_correct && !btn_correct_prev;
    wire btn_wrong_edge = btn_wrong && !btn_wrong_prev;

    // Question bank (10 questions)
    reg [7:0] questions [0:39];
    
    initial begin
        // Q0: 14 / 7 = 2
        questions[0] = 8'd14; questions[1] = 8'd7; questions[2] = 8'd2; questions[3] = OP_DIV;
        // Q1: 5 + 8 = 13
        questions[4] = 8'd5; questions[5] = 8'd8; questions[6] = 8'd13; questions[7] = OP_ADD;
        // Q2: 15 - 6 = 9
        questions[8] = 8'd15; questions[9] = 8'd6; questions[10] = 8'd9; questions[11] = OP_SUB;
        // Q3: 18 / 3 = 6
        questions[12] = 8'd18; questions[13] = 8'd3; questions[14] = 8'd6; questions[15] = OP_DIV;
        // Q4: 7 + 9 = 16
        questions[16] = 8'd7; questions[17] = 8'd9; questions[18] = 8'd16; questions[19] = OP_ADD;
        // Q5: 20 - 8 = 12
        questions[20] = 8'd20; questions[21] = 8'd8; questions[22] = 8'd12; questions[23] = OP_SUB;
        // Q6: 24 / 4 = 6
        questions[24] = 8'd24; questions[25] = 8'd4; questions[26] = 8'd6; questions[27] = OP_DIV;
        // Q7: 12 + 15 = 27
        questions[28] = 8'd12; questions[29] = 8'd15; questions[30] = 8'd27; questions[31] = OP_ADD;
        // Q8: 30 - 12 = 18
        questions[32] = 8'd30; questions[33] = 8'd12; questions[34] = 8'd18; questions[35] = OP_SUB;
        // Q9: 35 / 5 = 7
        questions[36] = 8'd35; questions[37] = 8'd5; questions[38] = 8'd7; questions[39] = OP_DIV;
    end

    task load_question;
        input [3:0] qnum;
        begin
            operand1 = questions[qnum * 4];
            operand2 = questions[qnum * 4 + 1];
            result = questions[qnum * 4 + 2];
            operation = questions[qnum * 4 + 3][1:0];
        end
    endtask

    always @(posedge clk) begin
        if (reset) begin
            state <= HOME;
            score <= 0;
            mistakes <= 0;
            question_num <= 0;
            operand1 <= 0;
            operand2 <= 0;
            result <= 0;
            operation <= 0;
            btn_start_prev <= 0;
            btn_correct_prev <= 0;
            btn_wrong_prev <= 0;
        end else begin
            btn_start_prev <= btn_start;
            btn_correct_prev <= btn_correct;
            btn_wrong_prev <= btn_wrong;
            
            case (state)
                HOME: begin
                    if (btn_start_edge) begin
                        state <= PLAYING;
                        score <= 0;
                        mistakes <= 0;
                        question_num <= 0;
                        load_question(0);
                    end
                end
                
                PLAYING: begin
                    if (btn_correct_edge) begin
                        score <= score + 1;
                        if (question_num == 9 || mistakes >= 3) begin
                            state <= GAME_OVER;
                        end else begin
                            question_num <= question_num + 1;
                            load_question(question_num + 1);
                        end
                    end else if (btn_wrong_edge) begin
                        mistakes <= mistakes + 1;
                        if (mistakes >= 2) begin
                            state <= GAME_OVER;
                        end else if (question_num == 9) begin
                            state <= GAME_OVER;
                        end else begin
                            question_num <= question_num + 1;
                            load_question(question_num + 1);
                        end
                    end
                end
                
                GAME_OVER: begin
                    if (btn_start_edge) begin
                        state <= HOME;
                        score <= 0;
                        mistakes <= 0;
                        question_num <= 0;
                    end
                end
            endcase
        end
    end

endmodule