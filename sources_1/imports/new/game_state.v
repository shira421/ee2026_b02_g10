`timescale 1ns / 1ps

module game_state(
    input clk,
    input reset,
    input btn_start,
    input btn_correct,
    input btn_wrong,
    output reg [1:0] state,
    output reg [9:0] score,
    output reg [3:0] mistakes,
    output reg [3:0] question_num,
    output reg [7:0] operand1,
    output reg [7:0] operand2,
    output reg [7:0] result,
    output reg [1:0] operation,
    output reg is_correct,
    output reg [4:0] timer_count
);

    // States
    localparam HOME = 2'b00;
    localparam PLAYING = 2'b01;
    localparam GAME_OVER = 2'b10;
    localparam CORRECT_PAUSE = 2'b11;

    // Operations
    localparam OP_ADD = 2'b00;
    localparam OP_SUB = 2'b01;
    localparam OP_DIV = 2'b10;
    localparam OP_MUL = 2'b11;

    // Edge detection
    reg btn_start_prev, btn_correct_prev, btn_wrong_prev;
    wire btn_start_edge = btn_start && !btn_start_prev;
    wire btn_correct_edge = btn_correct && !btn_correct_prev;
    wire btn_wrong_edge = btn_wrong && !btn_wrong_prev;

    // Question bank (100 questions with correct/incorrect answers)
    reg [7:0] questions [0:399];
    
initial begin
               questions[0] = 8'd64; questions[1] = 8'd8; questions[2] = 8'd8; questions[3] = 8'b00000110;
               questions[4] = 8'd56; questions[5] = 8'd7; questions[6] = 8'd9; questions[7] = 8'b00000010;
               questions[8] = 8'd24; questions[9] = 8'd4; questions[10] = 8'd6; questions[11] = 8'b00000110;
               questions[12] = 8'd35; questions[13] = 8'd5; questions[14] = 8'd6; questions[15] = 8'b00000010;
               questions[16] = 8'd48; questions[17] = 8'd6; questions[18] = 8'd8; questions[19] = 8'b00000110;
               questions[20] = 8'd63; questions[21] = 8'd7; questions[22] = 8'd8; questions[23] = 8'b00000010;
               questions[24] = 8'd72; questions[25] = 8'd8; questions[26] = 8'd9; questions[27] = 8'b00000110;
               questions[28] = 8'd81; questions[29] = 8'd9; questions[30] = 8'd8; questions[31] = 8'b00000010;
               questions[32] = 8'd32; questions[33] = 8'd4; questions[34] = 8'd8; questions[35] = 8'b00000110;
               questions[36] = 8'd45; questions[37] = 8'd5; questions[38] = 8'd8; questions[39] = 8'b00000010;
               
               questions[40] = 8'd5; questions[41] = 8'd8; questions[42] = 8'd20; questions[43] = 8'b00000000;
               questions[44] = 8'd7; questions[45] = 8'd9; questions[46] = 8'd21; questions[47] = 8'b00000100;
               questions[48] = 8'd62; questions[49] = 8'd65; questions[50] = 8'd27; questions[51] = 8'b00000100;
               questions[52] = 8'd6; questions[53] = 8'd7; questions[54] = 8'd20; questions[55] = 8'b00000000;
               questions[56] = 8'd8; questions[57] = 8'd9; questions[58] = 8'd20; questions[59] = 8'b00000100;
               questions[60] = 8'd61; questions[61] = 8'd64; questions[62] = 8'd25; questions[63] = 8'b00000100;
               questions[64] = 8'd63; questions[65] = 8'd68; questions[66] = 8'd31; questions[67] = 8'b00000100;
               questions[68] = 8'd66; questions[69] = 8'd69; questions[70] = 8'd36; questions[71] = 8'b00000000;
               questions[72] = 8'd21; questions[73] = 8'd23; questions[74] = 8'd44; questions[75] = 8'b00000100;
               questions[76] = 8'd25; questions[77] = 8'd28; questions[78] = 8'd54; questions[79] = 8'b00000000;
               questions[80] = 8'd3; questions[81] = 8'd4; questions[82] = 8'd7; questions[83] = 8'b00000100;
               questions[84] = 8'd9; questions[85] = 8'd6; questions[86] = 8'd20; questions[87] = 8'b00000000;
               questions[88] = 8'd64; questions[89] = 8'd61; questions[90] = 8'd25; questions[91] = 8'b00000100;
               questions[92] = 8'd67; questions[93] = 8'd63; questions[94] = 8'd29; questions[95] = 8'b00000000;
               questions[96] = 8'd22; questions[97] = 8'd69; questions[98] = 8'd91; questions[99] = 8'b00000100;
               questions[100] = 8'd26; questions[101] = 8'd24; questions[102] = 8'd51; questions[103] = 8'b00000000;
               questions[104] = 8'd31; questions[105] = 8'd29; questions[106] = 8'd60; questions[107] = 8'b00000100;
               questions[108] = 8'd35; questions[109] = 8'd33; questions[110] = 8'd69; questions[111] = 8'b00000000;
               questions[112] = 8'd38; questions[113] = 8'd37; questions[114] = 8'd75; questions[115] = 8'b00000100;
               questions[116] = 8'd42; questions[117] = 8'd41; questions[118] = 8'd84; questions[119] = 8'b00000000;
               
               questions[120] = 8'd75; questions[121] = 8'd6; questions[122] = 8'd69; questions[123] = 8'b00000101;
               questions[124] = 8'd80; questions[125] = 8'd8; questions[126] = 8'd71; questions[127] = 8'b00000001;
               questions[128] = 8'd30; questions[129] = 8'd22; questions[130] = 8'd8; questions[131] = 8'b00000101;
               questions[132] = 8'd25; questions[133] = 8'd20; questions[134] = 8'd6; questions[135] = 8'b00000001;
               questions[136] = 8'd85; questions[137] = 8'd25; questions[138] = 8'd60; questions[139] = 8'b00000101;
               questions[140] = 8'd90; questions[141] = 8'd28; questions[142] = 8'd63; questions[143] = 8'b00000001;
               questions[144] = 8'd50; questions[145] = 8'd22; questions[146] = 8'd28; questions[147] = 8'b00000101;
               questions[148] = 8'd45; questions[149] = 8'd29; questions[150] = 8'd21; questions[151] = 8'b00000001;
               questions[152] = 8'd55; questions[153] = 8'd27; questions[154] = 8'd28; questions[155] = 8'b00000101;
               questions[156] = 8'd60; questions[157] = 8'd32; questions[158] = 8'd29; questions[159] = 8'b00000001;
               questions[160] = 8'd78; questions[161] = 8'd7; questions[162] = 8'd71; questions[163] = 8'b00000101;
               questions[164] = 8'd82; questions[165] = 8'd9; questions[166] = 8'd74; questions[167] = 8'b00000001;
               questions[168] = 8'd88; questions[169] = 8'd21; questions[170] = 8'd67; questions[171] = 8'b00000101;
               questions[172] = 8'd93; questions[173] = 8'd24; questions[174] = 8'd68; questions[175] = 8'b00000001;
               questions[176] = 8'd98; questions[177] = 8'd26; questions[178] = 8'd72; questions[179] = 8'b00000101;
               questions[180] = 8'd92; questions[181] = 8'd29; questions[182] = 8'd64; questions[183] = 8'b00000001;
               questions[184] = 8'd48; questions[185] = 8'd21; questions[186] = 8'd27; questions[187] = 8'b00000101;
               questions[188] = 8'd52; questions[189] = 8'd24; questions[190] = 8'd29; questions[191] = 8'b00000001;
               questions[192] = 8'd58; questions[193] = 8'd29; questions[194] = 8'd29; questions[195] = 8'b00000101;
               questions[196] = 8'd63; questions[197] = 8'd31; questions[198] = 8'd33; questions[199] = 8'b00000001;
               
               questions[200] = 8'd81; questions[201] = 8'd20; questions[202] = 8'd61; questions[203] = 8'b00000101;
               questions[204] = 8'd86; questions[205] = 8'd20; questions[206] = 8'd65; questions[207] = 8'b00000001;
               questions[208] = 8'd91; questions[209] = 8'd23; questions[210] = 8'd68; questions[211] = 8'b00000101;
               questions[212] = 8'd96; questions[213] = 8'd25; questions[214] = 8'd72; questions[215] = 8'b00000001;
               questions[216] = 8'd41; questions[217] = 8'd27; questions[218] = 8'd20; questions[219] = 8'b00000001;
               questions[220] = 8'd46; questions[221] = 8'd30; questions[222] = 8'd21; questions[223] = 8'b00000001;
               questions[224] = 8'd51; questions[225] = 8'd23; questions[226] = 8'd28; questions[227] = 8'b00000101;
               questions[228] = 8'd56; questions[229] = 8'd26; questions[230] = 8'd31; questions[231] = 8'b00000001;
               questions[232] = 8'd61; questions[233] = 8'd28; questions[234] = 8'd33; questions[235] = 8'b00000101;
               questions[236] = 8'd65; questions[237] = 8'd30; questions[238] = 8'd36; questions[239] = 8'b00000001;
               questions[240] = 8'd4; questions[241] = 8'd5; questions[242] = 8'd9; questions[243] = 8'b00000100;
               questions[244] = 8'd70; questions[245] = 8'd8; questions[246] = 8'd79; questions[247] = 8'b00000000;
               questions[248] = 8'd75; questions[249] = 8'd22; questions[250] = 8'd97; questions[251] = 8'b00000100;
               questions[252] = 8'd79; questions[253] = 8'd26; questions[254] = 8'd06; questions[255] = 8'b00000000;
               questions[256] = 8'd23; questions[257] = 8'd21; questions[258] = 8'd44; questions[259] = 8'b00000100;
               questions[260] = 8'd27; questions[261] = 8'd25; questions[262] = 8'd53; questions[263] = 8'b00000000;
               questions[264] = 8'd32; questions[265] = 8'd30; questions[266] = 8'd62; questions[267] = 8'b00000100;
               questions[268] = 8'd36; questions[269] = 8'd34; questions[270] = 8'd71; questions[271] = 8'b00000000;
               questions[272] = 8'd40; questions[273] = 8'd39; questions[274] = 8'd79; questions[275] = 8'b00000100;
               questions[276] = 8'd45; questions[277] = 8'd43; questions[278] = 8'd89; questions[279] = 8'b00000000;
               
               questions[280] = 8'd27; questions[281] = 8'd3; questions[282] = 8'd9; questions[283] = 8'b00000110;
               questions[284] = 8'd6; questions[285] = 8'd7; questions[286] = 8'd42; questions[287] = 8'b00000111;
               questions[288] = 8'd70; questions[289] = 8'd35; questions[290] = 8'd36; questions[291] = 8'b00000001;
               questions[292] = 8'd8; questions[293] = 8'd8; questions[294] = 8'd64; questions[295] = 8'b00000111;
               questions[296] = 8'd47; questions[297] = 8'd46; questions[298] = 8'd93; questions[299] = 8'b00000100;
               questions[300] = 8'd75; questions[301] = 8'd38; questions[302] = 8'd36; questions[303] = 8'b00000001;
               questions[304] = 8'd9; questions[305] = 8'd6; questions[306] = 8'd54; questions[307] = 8'b00000111;
               questions[308] = 8'd49; questions[309] = 8'd48; questions[310] = 8'd98; questions[311] = 8'b00000000;
               questions[312] = 8'd7; questions[313] = 8'd8; questions[314] = 8'd56; questions[315] = 8'b00000111;
               questions[316] = 8'd9; questions[317] = 8'd9; questions[318] = 8'd80; questions[319] = 8'b00000011;
               questions[320] = 8'd6; questions[321] = 8'd9; questions[322] = 8'd54; questions[323] = 8'b00000111;
               questions[324] = 8'd54; questions[325] = 8'd9; questions[326] = 8'd7; questions[327] = 8'b00000010;
               questions[328] = 8'd48; questions[329] = 8'd8; questions[330] = 8'd6; questions[331] = 8'b00000110;
               questions[332] = 8'd63; questions[333] = 8'd9; questions[334] = 8'd8; questions[335] = 8'b00000010;
               questions[336] = 8'd8; questions[337] = 8'd7; questions[338] = 8'd56; questions[339] = 8'b00000111;
               questions[340] = 8'd72; questions[341] = 8'd8; questions[342] = 8'd8; questions[343] = 8'b00000010;
               questions[344] = 8'd49; questions[345] = 8'd7; questions[346] = 8'd7; questions[347] = 8'b00000110;
               questions[348] = 8'd9; questions[349] = 8'd8; questions[350] = 8'd73; questions[351] = 8'b00000011;
               questions[352] = 8'd56; questions[353] = 8'd8; questions[354] = 8'd7; questions[355] = 8'b00000110;
               questions[356] = 8'd45; questions[357] = 8'd9; questions[358] = 8'd4; questions[359] = 8'b00000010;
               questions[360] = 8'd8; questions[361] = 8'd9; questions[362] = 8'd72; questions[363] = 8'b00000111;
               questions[364] = 8'd64; questions[365] = 8'd8; questions[366] = 8'd9; questions[367] = 8'b00000010;
               questions[368] = 8'd7; questions[369] = 8'd9; questions[370] = 8'd63; questions[371] = 8'b00000111;
               questions[372] = 8'd42; questions[373] = 8'd6; questions[374] = 8'd8; questions[375] = 8'b00000010;
               questions[376] = 8'd36; questions[377] = 8'd9; questions[378] = 8'd4; questions[379] = 8'b00000110;
               questions[380] = 8'd6; questions[381] = 8'd8; questions[382] = 8'd49; questions[383] = 8'b00000011;
               questions[384] = 8'd81; questions[385] = 8'd9; questions[386] = 8'd9; questions[387] = 8'b00000110;
               questions[388] = 8'd8; questions[389] = 8'd6; questions[390] = 8'd47; questions[391] = 8'b00000011;
               questions[392] = 8'd35; questions[393] = 8'd7; questions[394] = 8'd5; questions[395] = 8'b00000110;
               questions[396] = 8'd9; questions[397] = 8'd7; questions[398] = 8'd62; questions[399] = 8'b00000011;
           end

    // LFSR for pseudo-random number generation
    reg [6:0] lfsr = 7'b1010101;
    wire feedback = lfsr[6] ^ lfsr[5];
    
    always @(posedge clk) begin
        if (reset) begin
            lfsr <= 7'b1010101;
        end else begin
            lfsr <= {lfsr[5:0], feedback};
        end
    end
    
    wire [6:0] random_q_index = (lfsr >= 100) ? (lfsr - 100) : lfsr;

    // Timer logic - 1 second clock divider
    reg [26:0] clk_divider;
    wire tick_1s = (clk_divider == 100_000_000 - 1);
    
    // Pause counter for correct answer pause
    reg [26:0] pause_counter;
    wire pause_done = (pause_counter >= 100_000_000 - 1); // 1 second pause
    
    // Cooldown to prevent double-triggers from rapid button presses
    reg [23:0] button_cooldown;
    wire buttons_ready = (button_cooldown == 0);

    task load_question;
        input [6:0] qnum;
        begin
            operand1 = questions[qnum * 4];
            operand2 = questions[qnum * 4 + 1];
            result = questions[qnum * 4 + 2];
            operation = questions[qnum * 4 + 3][1:0];
            is_correct = questions[qnum * 4 + 3][2];
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
            is_correct <= 0;
            btn_start_prev <= 0;
            btn_correct_prev <= 0;
            btn_wrong_prev <= 0;
            timer_count <= 15;
            clk_divider <= 0;
            pause_counter <= 0;
            button_cooldown <= 0;
        end else begin
            btn_start_prev <= btn_start;
            btn_correct_prev <= btn_correct;
            btn_wrong_prev <= btn_wrong;
            
            // Decrement button cooldown
            if (button_cooldown > 0) begin
                button_cooldown <= button_cooldown - 1;
            end
            
            case (state)
                HOME: begin
                    timer_count <= 15;
                    button_cooldown <= 0; // Reset cooldown
                    if (btn_start_edge) begin
                        state <= PLAYING;
                        score <= 0;
                        mistakes <= 0;
                        question_num <= 0;
                        load_question(random_q_index);
                        timer_count <= 15;
                        clk_divider <= 0;
                    end
                end
                
                PLAYING: begin
                    // Timer countdown
                    clk_divider <= clk_divider + 1;
                    if (tick_1s) begin
                        clk_divider <= 0;
                        if (timer_count > 0) begin
                            timer_count <= timer_count - 1;
                        end else begin
                            // Timer hit 0 - Game Over
                            state <= GAME_OVER;
                        end
                    end
                    
                    // Only process button presses if we're actually in PLAYING state
                    // This prevents rapid button presses from causing issues
                    if (btn_correct_edge && state == PLAYING && buttons_ready) begin
                        // User says answer is CORRECT
                        button_cooldown <= 20_000_000; // 200ms cooldown
                        if (is_correct) begin
                            // Answer IS correct - user is right!
                            score <= score + 1;
                            // Add 2 seconds if timer < 15 (capped at 15)
                            if (timer_count <= 13)
                                timer_count <= timer_count + 2;
                            else if (timer_count < 15)
                                timer_count <= 15;
                            state <= CORRECT_PAUSE;
                            pause_counter <= 0;
                        end else begin
                            // Answer is wrong but user said correct - mistake!
                            mistakes <= mistakes + 1;
                            // Subtract 3 seconds
                            if (timer_count >= 3)
                                timer_count <= timer_count - 3;
                            else
                                timer_count <= 0;
                            
                            if (timer_count <= 3) begin
                                state <= GAME_OVER;
                            end else begin
                                question_num <= question_num + 1;
                                load_question(random_q_index);
                            end
                        end
                    end else if (btn_wrong_edge && state == PLAYING && buttons_ready) begin
                        // User says answer is WRONG
                        button_cooldown <= 20_000_000; // 200ms cooldown
                        if (!is_correct) begin
                            // Answer IS wrong - user is right!
                            score <= score + 1;
                            // Add 2 seconds if timer < 15 (capped at 15)
                            if (timer_count <= 13)
                                timer_count <= timer_count + 2;
                            else if (timer_count < 15)
                                timer_count <= 15;
                            state <= CORRECT_PAUSE;
                            pause_counter <= 0;
                        end else begin
                            // Answer is correct but user said wrong - mistake!
                            mistakes <= mistakes + 1;
                            // Subtract 3 seconds
                            if (timer_count >= 3)
                                timer_count <= timer_count - 3;
                            else
                                timer_count <= 0;
                            
                            if (timer_count <= 3) begin
                                state <= GAME_OVER;
                            end else begin
                                question_num <= question_num + 1;
                                load_question(random_q_index);
                            end
                        end
                    end
                end
                
                CORRECT_PAUSE: begin
                    pause_counter <= pause_counter + 1;
                    button_cooldown <= 0; // Reset cooldown during pause
                    if (pause_done) begin
                        state <= PLAYING;
                        question_num <= question_num + 1;
                        load_question(random_q_index);
                        pause_counter <= 0;
                    end
                end
                
                GAME_OVER: begin
                    timer_count <= 0;
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
