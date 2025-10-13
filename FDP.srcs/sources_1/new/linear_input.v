`timescale 1ns / 1ps
module linear_input(
    input clk,
    input reset,
    input btn_up, btn_down, btn_left, btn_right, btn_confirm,
    input [12:0] pixel_index,
    output reg [15:0] pixel_data,
    output reg back_to_menu
);

    localparam WIDTH = 96;
    localparam HEIGHT = 64;
    reg [6:0] x_pos;
    reg [5:0] y_pos;
    reg [3:0] num_pressed;
    reg [7:0] current_char;
    reg [2:0] char_row;
    reg [4:0] char_data;
    reg [2:0] char_col_index;
    reg [15:0] final_color;
    always @(*) begin
        x_pos = pixel_index % WIDTH;
        y_pos = pixel_index / WIDTH;
    end

    localparam COLOR_BG = 16'h0000;
    localparam COLOR_TEXT = 16'hFFFF;
    localparam COLOR_BOX = 16'h18C3;
    localparam COLOR_BOX_ACTIVE = 16'h07E0;
    localparam COLOR_BORDER = 16'h7BEF;
    localparam COLOR_BUTTON = 16'h4208;
    localparam COLOR_BUTTON_ACTIVE = 16'hFD20;
    localparam COLOR_CLR_BUTTON = 16'hF800;
    localparam COLOR_KEYPAD_BG = 16'h2124;
    localparam COLOR_KEYPAD_HIGHLIGHT = 16'hFBE0;
    localparam COLOR_ERROR = 16'hF800;
    localparam COLOR_RESULT = 16'h07FF;

    localparam S_NAVIGATE = 0, S_KEYPAD = 1, S_SOLVER = 2;
    reg [1:0] state = S_NAVIGATE;

    reg [3:0] active_item = 1;
    reg [1:0] keypad_x = 0, keypad_y = 0;
    reg signed [10:0] a1=0, b1=0, c1=0, a2=0, b2=0, c2=0;
    reg [9:0] temp_val = 0;
    reg temp_sign = 0;
    reg [1:0] temp_digit_count = 0;

    wire [2:0] solution_type;
    wire signed [22:0] D_out, Dx_out, Dy_out;
    linear_solver solver_inst (
        .clk(clk), .reset(reset),
        .a1(a1), .b1(b1), .c1(c1),
        .a2(a2), .b2(b2), .c2(c2),
        .solution_type(solution_type), .D(D_out), .Dx(Dx_out), .Dy(Dy_out)
    );

    reg btn_left_prev, btn_right_prev, btn_confirm_prev, btn_up_prev, btn_down_prev;
    wire btn_left_edge = btn_left && !btn_left_prev;
    wire btn_right_edge = btn_right && !btn_right_prev;
    wire btn_confirm_edge = btn_confirm && !btn_confirm_prev;
    wire btn_up_edge = btn_up && !btn_up_prev;
    wire btn_down_edge = btn_down && !btn_down_prev;

    always @(posedge clk) begin
        btn_left_prev <= btn_left; btn_right_prev <= btn_right; btn_confirm_prev <= btn_confirm;
        btn_up_prev <= btn_up; btn_down_prev <= btn_down;
        back_to_menu <= 0;

        if (reset) begin
            state <= S_NAVIGATE; active_item <= 1;
            a1<=0; b1<=0; c1<=0; a2<=0; b2<=0; c2<=0;
        end else begin
            case(state)
                S_NAVIGATE: begin
                    if (btn_left_edge) active_item <= (active_item == 1) ? 8 : active_item - 1;
                    if (btn_right_edge) active_item <= (active_item == 8) ? 1 : active_item + 1;
                    if (btn_confirm_edge) begin
                        if (active_item <= 6) begin
                            state <= S_KEYPAD;
                            keypad_x <= 0; keypad_y <= 0;
                            case(active_item)
                                1: begin temp_val = a1 < 0 ? -a1:a1; temp_sign=a1[10]; temp_digit_count= a1==0 ? 0 : (a1<10&&a1>-10)?1:((a1<100&&a1>-100)?2:3); end
                                2: begin temp_val = b1 < 0 ? -b1:b1; temp_sign=b1[10]; temp_digit_count= b1==0 ? 0 : (b1<10&&b1>-10)?1:((b1<100&&b1>-100)?2:3); end
                                3: begin temp_val = c1 < 0 ? -c1:c1; temp_sign=c1[10]; temp_digit_count= c1==0 ? 0 : (c1<10&&c1>-10)?1:((c1<100&&c1>-100)?2:3); end
                                4: begin temp_val = a2 < 0 ? -a2:a2; temp_sign=a2[10]; temp_digit_count= a2==0 ? 0 : (a2<10&&a2>-10)?1:((a2<100&&a2>-100)?2:3); end
                                5: begin temp_val = b2 < 0 ? -b2:b2; temp_sign=b2[10]; temp_digit_count= b2==0 ? 0 : (b2<10&&b2>-10)?1:((b2<100&&b2>-100)?2:3); end
                                6: begin temp_val = c2 < 0 ? -c2:c2; temp_sign=c2[10]; temp_digit_count= c2==0 ? 0 : (c2<10&&c2>-10)?1:((c2<100&&c2>-100)?2:3); end
                            endcase
                        end else if (active_item == 7) {a1,b1,c1,a2,b2,c2} <= 0;
                        else if (active_item == 8) state <= S_SOLVER;
                    end
                end
                S_KEYPAD: begin
                    if(btn_up_edge) keypad_y <= (keypad_y == 0) ? 3 : keypad_y - 1;
                    if(btn_down_edge) keypad_y <= (keypad_y == 3) ? 0 : keypad_y + 1;
                    if(btn_left_edge) keypad_x <= (keypad_x == 0) ? 3 : keypad_x - 1;
                    if(btn_right_edge) keypad_x <= (keypad_x == 3) ? 0 : keypad_x + 1;
                    if(btn_confirm_edge) begin
                        num_pressed = 4'b0;
                        if (keypad_y < 3) num_pressed = keypad_y*3 + keypad_x + 1;
                        if ({keypad_y, keypad_x} == 4'b1101) num_pressed = 0;

                        if ((keypad_y < 3 && keypad_x < 3) || {keypad_y, keypad_x} == 4'b1101) begin
                            if (temp_digit_count < 3) begin
                                if (temp_val < 100) begin
                                    temp_val <= temp_val * 10 + num_pressed;
                                    temp_digit_count <= temp_digit_count + 1;
                                end
                            end
                        end else if ({keypad_y, keypad_x} == 4'b1100) begin
                            temp_sign <= ~temp_sign;
                        end else if ({keypad_y, keypad_x} == 4'b1011) begin
                            temp_val <= temp_val / 10;
                            if (temp_digit_count > 0) temp_digit_count <= temp_digit_count - 1;
                        end else if ({keypad_y, keypad_x} == 4'b1111) begin
                            case(active_item)
                                1: a1 <= temp_sign ? -$signed(temp_val) : $signed(temp_val);
                                2: b1 <= temp_sign ? -$signed(temp_val) : $signed(temp_val);
                                3: c1 <= temp_sign ? -$signed(temp_val) : $signed(temp_val);
                                4: a2 <= temp_sign ? -$signed(temp_val) : $signed(temp_val);
                                5: b2 <= temp_sign ? -$signed(temp_val) : $signed(temp_val);
                                6: c2 <= temp_sign ? -$signed(temp_val) : $signed(temp_val);
                            endcase
                            state <= S_NAVIGATE;
                        end else if ({keypad_y, keypad_x} == 4'b1110) begin
                            state <= S_NAVIGATE;
                        end
                    end
                end
                S_SOLVER: if (btn_left_edge) back_to_menu <= 1;
            endcase
        end
    end

    always @(*) begin

        final_color = COLOR_BG;
        current_char = " ";
        char_data = 5'b0;

        case(state)
        S_NAVIGATE, S_KEYPAD: begin
            if(y_pos>=12&&y_pos<24)begin if(x_pos>=4&&x_pos<34)final_color=COLOR_BOX;else if(x_pos>=36&&x_pos<66)final_color=COLOR_BOX;else if(x_pos>=68&&x_pos<98)final_color=COLOR_BOX;end
            if(y_pos>=36&&y_pos<48)begin if(x_pos>=4&&x_pos<34)final_color=COLOR_BOX;else if(x_pos>=36&&x_pos<66)final_color=COLOR_BOX;else if(x_pos>=68&&x_pos<98)final_color=COLOR_BOX;end
            if(y_pos>=52&&y_pos<62)begin if(x_pos>=10&&x_pos<40)final_color=COLOR_CLR_BUTTON;else if(x_pos>=56&&x_pos<86)final_color=COLOR_BUTTON;end
            if(y_pos==12||y_pos==23||y_pos==36||y_pos==47)begin if((x_pos>=4&&x_pos<34)||(x_pos>=36&&x_pos<66)||(x_pos>=68&&x_pos<98))final_color=COLOR_BORDER;end
            if(y_pos>12&&y_pos<23)begin if(x_pos==4||x_pos==33||x_pos==36||x_pos==65||x_pos==68||x_pos==97)final_color=COLOR_BORDER;end
            if(y_pos>36&&y_pos<48)begin if(x_pos==4||x_pos==33||x_pos==36||x_pos==65||x_pos==68||x_pos==97)final_color=COLOR_BORDER;end
            if(y_pos==52||y_pos==61)begin if((x_pos>=10&&x_pos<40)||(x_pos>=56&&x_pos<86))final_color=COLOR_BORDER;end
            if(y_pos>52&&y_pos<61)begin if(x_pos==10||x_pos==39||x_pos==56||x_pos==85)final_color=COLOR_BORDER;end
            if(active_item==1&&y_pos>=12&&y_pos<24&&x_pos>=4&&x_pos<34 && (x_pos==4||x_pos==33||y_pos==12||y_pos==23))final_color=COLOR_BOX_ACTIVE;
            if(active_item==2&&y_pos>=12&&y_pos<24&&x_pos>=36&&x_pos<66 && (x_pos==36||x_pos==65||y_pos==12||y_pos==23))final_color=COLOR_BOX_ACTIVE;
            if(active_item==3&&y_pos>=12&&y_pos<24&&x_pos>=68&&x_pos<98 && (x_pos==68||x_pos==97||y_pos==12||y_pos==23))final_color=COLOR_BOX_ACTIVE;
            if(active_item==4&&y_pos>=36&&y_pos<48&&x_pos>=4&&x_pos<34 && (x_pos==4||x_pos==33||y_pos==36||y_pos==47))final_color=COLOR_BOX_ACTIVE;
            if(active_item==5&&y_pos>=36&&y_pos<48&&x_pos>=36&&x_pos<66 && (x_pos==36||x_pos==65||y_pos==36||y_pos==47))final_color=COLOR_BOX_ACTIVE;
            if(active_item==6&&y_pos>=36&&y_pos<48&&x_pos>=68&&x_pos<98 && (x_pos==68||x_pos==97||y_pos==36||y_pos==47))final_color=COLOR_BOX_ACTIVE;
            if(active_item==7&&y_pos>=52&&y_pos<62&&x_pos>=10&&x_pos<40 && (x_pos==10||x_pos==39||y_pos==52||y_pos==61))final_color=COLOR_BUTTON_ACTIVE;
            if(active_item==8&&y_pos>=52&&y_pos<62&&x_pos>=56&&x_pos<86 && (x_pos==56||x_pos==85||y_pos==52||y_pos==61))final_color=COLOR_BUTTON_ACTIVE;

            if(state==S_KEYPAD)begin
                if(x_pos>=20&&x_pos<76&&y_pos>=10&&y_pos<54)final_color=COLOR_KEYPAD_BG;
                if(x_pos>=22+keypad_x*14&&x_pos<34+keypad_x*14&&y_pos>=12+keypad_y*10&&y_pos<20+keypad_y*10)final_color=COLOR_KEYPAD_HIGHLIGHT;
            end
            
            if (y_pos >= 2 && y_pos < 9) begin char_row = y_pos - 2; if(x_pos>=4&&x_pos<9)current_char="E";else if(x_pos>=10&&x_pos<15)current_char="q";else if(x_pos>=16&&x_pos<21)current_char="1";else if(x_pos>=22&&x_pos<27)current_char=":";else if(x_pos>=40&&x_pos<45)current_char="x";else if(x_pos>=48&&x_pos<53)current_char="+";else if(x_pos>=72&&x_pos<77)current_char="y";else if(x_pos>=80&&x_pos<85)current_char="="; end
            else if (y_pos >= 26 && y_pos < 33) begin char_row = y_pos - 26; if(x_pos>=4&&x_pos<9)current_char="E";else if(x_pos>=10&&x_pos<15)current_char="q";else if(x_pos>=16&&x_pos<21)current_char="2";else if(x_pos>=22&&x_pos<27)current_char=":";else if(x_pos>=40&&x_pos<45)current_char="x";else if(x_pos>=48&&x_pos<53)current_char="+";else if(x_pos>=72&&x_pos<77)current_char="y";else if(x_pos>=80&&x_pos<85)current_char="="; end
            else if (y_pos >= 54 && y_pos < 61) begin char_row = y_pos - 54; if(x_pos>=18&&x_pos<23)current_char="C";else if(x_pos>=24&&x_pos<29)current_char="L";else if(x_pos>=30&&x_pos<35)current_char="R";else if(x_pos>=60&&x_pos<65)current_char="S";else if(x_pos>=66&&x_pos<71)current_char="O";else if(x_pos>=72&&x_pos<77)current_char="L";else if(x_pos>=78&&x_pos<83)current_char="V";else if(x_pos>=84&&x_pos<89)current_char="E"; end
            
            if (state == S_KEYPAD) begin
                if (y_pos >= 13 && y_pos < 20) begin char_row = y_pos - 13; if(x_pos>=26&&x_pos<31)current_char="1";else if(x_pos>=40&&x_pos<45)current_char="2";else if(x_pos>=54&&x_pos<59)current_char="3";else if(x_pos>=68&&x_pos<73)current_char=" "; end
                else if (y_pos >= 23 && y_pos < 30) begin char_row = y_pos - 23; if(x_pos>=26&&x_pos<31)current_char="4";else if(x_pos>=40&&x_pos<45)current_char="5";else if(x_pos>=54&&x_pos<59)current_char="6";else if(x_pos>=68&&x_pos<73)current_char="<"; end
                else if (y_pos >= 33 && y_pos < 40) begin char_row = y_pos - 33; if(x_pos>=26&&x_pos<31)current_char="7";else if(x_pos>=40&&x_pos<45)current_char="8";else if(x_pos>=54&&x_pos<59)current_char="9";else if(x_pos>=68&&x_pos<73)current_char="B"; end
                else if (y_pos >= 43 && y_pos < 50) begin char_row = y_pos - 43; if(x_pos>=26&&x_pos<31)current_char="-";else if(x_pos>=40&&x_pos<45)current_char="0";else if(x_pos>=54&&x_pos<59)current_char="K";else if(x_pos>=68&&x_pos<73)current_char="C"; end
            end
        end
        S_SOLVER: begin
            if (y_pos >= 4 && y_pos < 11) begin char_row = y_pos - 4; if(x_pos>=20&&x_pos<25)current_char="S";else if(x_pos>=26&&x_pos<31)current_char="O";else if(x_pos>=32&&x_pos<37)current_char="L"; end
            else case(solution_type)
            0: begin
                if(y_pos>=20&&y_pos<27) begin char_row=y_pos-20; if(x_pos>=4&&x_pos<9)current_char="x"; else if(x_pos>=12&&x_pos<17)current_char="="; else if(x_pos>=48&&x_pos<53)current_char="/"; end
                else if(y_pos>=32&&y_pos<39) begin char_row=y_pos-32; if(x_pos>=4&&x_pos<9)current_char="y"; else if(x_pos>=12&&x_pos<17)current_char="="; else if(x_pos>=48&&x_pos<53)current_char="/"; end
            end
            1: begin if(y_pos>=24&&y_pos<31)begin char_row=y_pos-24; if(x_pos>=12&&x_pos<17)current_char="N"; else if(x_pos>=18&&x_pos<23)current_char="o"; else if(x_pos>=30&&x_pos<35)current_char="S"; else if(x_pos>=36&&x_pos<41)current_char="o"; end end
            2: begin if(y_pos>=24&&y_pos<31)begin char_row=y_pos-24; if(x_pos>=4&&x_pos<9)current_char="I"; else if(x_pos>=10&&x_pos<15)current_char="n"; else if(x_pos>=16&&x_pos<21)current_char="f"; end end
            endcase
            if(y_pos>=56&&y_pos<63) begin char_row=y_pos-56; if(x_pos>=4&&x_pos<9)current_char="<"; else if(x_pos>=16&&x_pos<21)current_char="B"; else if(x_pos>=22&&x_pos<27)current_char="a"; end
        end
        endcase

        char_col_index = x_pos % 6;
        case(current_char)
            "0":case(char_row)0:char_data=5'b01110;1:char_data=5'b10001;2:char_data=5'b10011;3:char_data=5'b10101;4:char_data=5'b11001;5:char_data=5'b10001;6:char_data=5'b01110;default:char_data=5'b0;endcase
            "1":case(char_row)0:char_data=5'b01100;1:char_data=5'b11100;2:char_data=5'b00100;3:char_data=5'b00100;4:char_data=5'b00100;5:char_data=5'b00100;6:char_data=5'b11111;default:char_data=5'b0;endcase
            "2":case(char_row)0:char_data=5'b01110;1:char_data=5'b10001;2:char_data=5'b00001;3:char_data=5'b00110;4:char_data=5'b01000;5:char_data=5'b10000;6:char_data=5'b11111;default:char_data=5'b0;endcase
            "3":case(char_row)0:char_data=5'b01110;1:char_data=5'b10001;2:char_data=5'b00001;3:char_data=5'b00110;4:char_data=5'b00001;5:char_data=5'b10001;6:char_data=5'b01110;default:char_data=5'b0;endcase
            "4":case(char_row)0:char_data=5'b00010;1:char_data=5'b00110;2:char_data=5'b01010;3:char_data=5'b10010;4:char_data=5'b11111;5:char_data=5'b00010;6:char_data=5'b00010;default:char_data=5'b0;endcase
            "5":case(char_row)0:char_data=5'b11111;1:char_data=5'b10000;2:char_data=5'b11110;3:char_data=5'b00001;4:char_data=5'b00001;5:char_data=5'b10001;6:char_data=5'b01110;default:char_data=5'b0;endcase
            "6":case(char_row)0:char_data=5'b01110;1:char_data=5'b10000;2:char_data=5'b11110;3:char_data=5'b10001;4:char_data=5'b10001;5:char_data=5'b10001;6:char_data=5'b01110;default:char_data=5'b0;endcase
            "7":case(char_row)0:char_data=5'b11111;1:char_data=5'b00001;2:char_data=5'b00010;3:char_data=5'b00100;4:char_data=5'b01000;5:char_data=5'b01000;6:char_data=5'b01000;default:char_data=5'b0;endcase
            "8":case(char_row)0:char_data=5'b01110;1:char_data=5'b10001;2:char_data=5'b10001;3:char_data=5'b01110;4:char_data=5'b10001;5:char_data=5'b10001;6:char_data=5'b01110;default:char_data=5'b0;endcase
            "9":case(char_row)0:char_data=5'b01110;1:char_data=5'b10001;2:char_data=5'b10001;3:char_data=5'b01111;4:char_data=5'b00001;5:char_data=5'b00001;6:char_data=5'b01110;default:char_data=5'b0;endcase
            "x":case(char_row)2:char_data=5'b10001;3:char_data=5'b01010;4:char_data=5'b00100;5:char_data=5'b01010;6:char_data=5'b10001;default:char_data=5'b0;endcase
            "y":case(char_row)2:char_data=5'b10001;3:char_data=5'b01010;4:char_data=5'b00100;5:char_data=5'b00100;6:char_data=5'b00100;default:char_data=5'b0;endcase
            "+":case(char_row)1:char_data=5'b00100;2:char_data=5'b00100;3:char_data=5'b11111;4:char_data=5'b00100;5:char_data=5'b00100;default:char_data=5'b0;endcase
            "-":case(char_row)3:char_data=5'b11111;default:char_data=5'b0;endcase
            "=":case(char_row)2:char_data=5'b11111;4:char_data=5'b11111;default:char_data=5'b0;endcase
            "/":case(char_row)1:char_data=5'b00010;2:char_data=5'b00100;3:char_data=5'b01000;4:char_data=5'b10000;default:char_data=5'b0;endcase
            "E":case(char_row)0:char_data=5'b11111;1:char_data=5'b10000;2:char_data=5'b10000;3:char_data=5'b11110;4:char_data=5'b10000;5:char_data=5'b10000;6:char_data=5'b11111;default:char_data=5'b0;endcase
            "q":case(char_row)2:char_data=5'b01110;3:char_data=5'b10001;4:char_data=5'b10001;5:char_data=5'b01111;6:char_data=5'b00001;default:char_data=5'b0;endcase
            ":":case(char_row)2:char_data=5'b01100;5:char_data=5'b01100;default:char_data=5'b0;endcase
            "C":case(char_row)0:char_data=5'b01110;1:char_data=5'b10001;2:char_data=5'b10000;3:char_data=5'b10000;4:char_data=5'b10000;5:char_data=5'b10001;6:char_data=5'b01110;default:char_data=5'b0;endcase
            "L":case(char_row)0:char_data=5'b10000;1:char_data=5'b10000;2:char_data=5'b10000;3:char_data=5'b10000;4:char_data=5'b10000;5:char_data=5'b10000;6:char_data=5'b11111;default:char_data=5'b0;endcase
            "R":case(char_row)0:char_data=5'b11110;1:char_data=5'b10001;2:char_data=5'b10001;3:char_data=5'b11110;4:char_data=5'b10100;5:char_data=5'b10010;6:char_data=5'b10001;default:char_data=5'b0;endcase
            "S":case(char_row)0:char_data=5'b01110;1:char_data=5'b10001;2:char_data=5'b10000;3:char_data=5'b01110;4:char_data=5'b00001;5:char_data=5'b10001;6:char_data=5'b01110;default:char_data=5'b0;endcase
            "O":case(char_row)0:char_data=5'b01110;1:char_data=5'b10001;2:char_data=5'b10001;3:char_data=5'b10001;4:char_data=5'b10001;5:char_data=5'b10001;6:char_data=5'b01110;default:char_data=5'b0;endcase
            "V":case(char_row)0:char_data=5'b10001;1:char_data=5'b10001;2:char_data=5'b10001;3:char_data=5'b10001;4:char_data=5'b01010;5:char_data=5'b00100;6:char_data=5'b0;default:char_data=5'b0;endcase
            "K":case(char_row)0:char_data=5'b10001;1:char_data=5'b10010;2:char_data=5'b10100;3:char_data=5'b11000;4:char_data=5'b10100;5:char_data=5'b10010;6:char_data=5'b10001;default:char_data=5'b0;endcase
            "<":case(char_row)1:char_data=5'b00100;2:char_data=5'b01000;3:char_data=5'b10000;4:char_data=5'b01000;5:char_data=5'b00100;default:char_data=5'b0;endcase
            "N":case(char_row)0:char_data=5'b10001;1:char_data=5'b11001;2:char_data=5'b10101;3:char_data=5'b10011;4:char_data=5'b10001;5:char_data=5'b10001;6:char_data=5'b10001;default:char_data=5'b0;endcase
            "o":case(char_row)2:char_data=5'b01110;3:char_data=5'b10001;4:char_data=5'b10001;5:char_data=5'b10001;6:char_data=5'b01110;default:char_data=5'b0;endcase
            "I":case(char_row)0:char_data=5'b11111;1:char_data=5'b00100;2:char_data=5'b00100;3:char_data=5'b00100;4:char_data=5'b00100;5:char_data=5'b00100;6:char_data=5'b11111;default:char_data=5'b0;endcase
            "n":case(char_row)2:char_data=5'b10110;3:char_data=5'b11001;4:char_data=5'b10001;5:char_data=5'b10001;6:char_data=5'b10001;default:char_data=5'b0;endcase
            "f":case(char_row)0:char_data=5'b01110;1:char_data=5'b10000;2:char_data=5'b10000;3:char_data=5'b11100;4:char_data=5'b10000;5:char_data=5'b10000;6:char_data=5'b10000;default:char_data=5'b0;endcase
            "B":case(char_row)0:char_data=5'b11110;1:char_data=5'b10001;2:char_data=5'b10001;3:char_data=5'b11110;4:char_data=5'b10001;5:char_data=5'b10001;6:char_data=5'b11110;default:char_data=5'b0;endcase
            "a":case(char_row)2:char_data=5'b01110;3:char_data=5'b00001;4:char_data=5'b01111;5:char_data=5'b10001;6:char_data=5'b01111;default:char_data=5'b0;endcase
            default: char_data = 5'b0;
        endcase

        if (current_char != " " && char_col_index < 5 && char_data[4 - char_col_index]) begin
            if (state == S_SOLVER && solution_type == 1) pixel_data = COLOR_ERROR;
            else if (state == S_SOLVER) pixel_data = COLOR_RESULT;
            else pixel_data = COLOR_TEXT;
        end else begin
            pixel_data = final_color;
        end
    end
endmodule