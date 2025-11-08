module calculator_fsm(
    input clk, // slow_clk (6.25MHz)
    input reset,
    input btnC, btnU, btnD, btnL, btnR,

    output reg manual_reset_req = 0,
    output reg [2:0] current_state = S_CHOOSE_OP,
    output reg [16:0] num1_out = 0,
    output reg [16:0] num2_out = 0,
    output reg [19:0] result_out = 0,
    output reg [1:0] op_code_out = 0,
    output reg [1:0] op_selection_out = 0,
    output reg [3:0] numpad_selection_out = 0
);
    // FSM State Definitions
    localparam S_CHOOSE_OP   = 3'd0;
    localparam S_INPUT_NUM1  = 3'd1;
    localparam S_INPUT_NUM2  = 3'd2;
    localparam S_SHOW_RESULT = 3'd3;

    // Internal number storage
    reg [16:0] current_num = 0;

    // Wires for arithmetic results
    wire [19:0] add_res, sub_res, mul_res, div_res;

    // Instantiate arithmetic units
    add_function      adder(.num_1(num1_out), .num_2(num2_out), .num_3(add_res));
    subtract_function subber(.num_1(num1_out), .num_2(num2_out), .num_3(sub_res));
    multiply_function multer(.num_1(num1_out), .num_2(num2_out), .num_3(mul_res));
    divide_function   divider(.num_1(num1_out), .num_2(num2_out), .num_3(div_res));

    // Edge Detection for Button Presses
    reg btnC_prev, btnU_prev, btnD_prev, btnL_prev, btnR_prev;
    wire btnC_rising_edge = btnC && !btnC_prev;
    wire btnU_rising_edge = btnU && !btnU_prev;
    wire btnD_rising_edge = btnD && !btnD_prev;
    wire btnL_rising_edge = btnL && !btnL_prev;
    wire btnR_rising_edge = btnR && !btnR_prev;

    always @(posedge clk) begin
        btnC_prev <= btnC; btnU_prev <= btnU; btnD_prev <= btnD; btnL_prev <= btnL; btnR_prev <= btnR;
    end

    // Numpad Mapping (REDESIGNED for calculator layout: 1-2-3 at top)
    function integer get_numpad_value;
        input [3:0] selection;
        case(selection)
            0: get_numpad_value = 1; 1: get_numpad_value = 2; 2: get_numpad_value = 3;
            3: get_numpad_value = 4; 4: get_numpad_value = 5; 5: get_numpad_value = 6;
            6: get_numpad_value = 7; 7: get_numpad_value = 8; 8: get_numpad_value = 9;
            10: get_numpad_value = 0; // selection 10 is 0
            default: get_numpad_value = -1;
        endcase
    endfunction

    // Main FSM Logic Block
    always @(posedge clk) begin : fsm_logic_block
        integer val;
        manual_reset_req <= 0; // Default to low

        if (reset) begin
            current_state <= S_CHOOSE_OP;
            num1_out <= 0;
            num2_out <= 0;
            result_out <= 0;
            op_code_out <= 0;
            op_selection_out <= 0;
            numpad_selection_out <= 0;
            current_num <= 0;
        end else begin
            case(current_state)
                S_CHOOSE_OP: begin
                    // ** FIXED WRAP-AROUND NAVIGATION **
                    if(btnR_rising_edge) op_selection_out <= {op_selection_out[1], ~op_selection_out[0]};
                    if(btnL_rising_edge) op_selection_out <= {op_selection_out[1], ~op_selection_out[0]};
                    if(btnD_rising_edge) op_selection_out <= {~op_selection_out[1], op_selection_out[0]};
                    if(btnU_rising_edge) op_selection_out <= {~op_selection_out[1], op_selection_out[0]};

                    if (btnC_rising_edge) begin
                        op_code_out <= op_selection_out;
                        current_state <= S_INPUT_NUM1;
                        numpad_selection_out <= 0; // Default to '1' on numpad (top-left)
                    end
                end

                S_INPUT_NUM1: begin
                    if(btnR_rising_edge) numpad_selection_out <= (numpad_selection_out % 3 == 2) ? numpad_selection_out - 2 : numpad_selection_out + 1;
                    if(btnL_rising_edge) numpad_selection_out <= (numpad_selection_out % 3 == 0) ? numpad_selection_out + 2 : numpad_selection_out - 1;
                    if(btnD_rising_edge) numpad_selection_out <= (numpad_selection_out >= 9) ? numpad_selection_out - 9 : numpad_selection_out + 3;
                    if(btnU_rising_edge) numpad_selection_out <= (numpad_selection_out <= 2) ? numpad_selection_out + 9 : numpad_selection_out - 3;

                    if (btnC_rising_edge) begin
                        val = get_numpad_value(numpad_selection_out);
                        if (val != -1) begin
                            if (current_num < 10000) current_num <= (current_num * 10) + val;
                        end else if (numpad_selection_out == 9) begin // Backspace
                            current_num <= current_num / 10;
                        end else if (numpad_selection_out == 11) begin // Enter
                            num1_out <= current_num;
                            current_num <= 0;
                            current_state <= S_INPUT_NUM2;
                        end
                    end
                    // ** FIXED: Assign current_num to num1_out OUTSIDE the 'if' block **
                    num1_out <= current_num;
                end

                S_INPUT_NUM2: begin
                    if(btnR_rising_edge) numpad_selection_out <= (numpad_selection_out % 3 == 2) ? numpad_selection_out - 2 : numpad_selection_out + 1;
                    if(btnL_rising_edge) numpad_selection_out <= (numpad_selection_out % 3 == 0) ? numpad_selection_out + 2 : numpad_selection_out - 1;
                    if(btnD_rising_edge) numpad_selection_out <= (numpad_selection_out >= 9) ? numpad_selection_out - 9 : numpad_selection_out + 3;
                    if(btnU_rising_edge) numpad_selection_out <= (numpad_selection_out <= 2) ? numpad_selection_out + 9 : numpad_selection_out - 3;

                    if (btnC_rising_edge) begin
                        val = get_numpad_value(numpad_selection_out);
                        if (val != -1) begin
                            if (current_num < 10000) current_num <= (current_num * 10) + val;
                        end else if (numpad_selection_out == 9) begin // Backspace
                            current_num <= current_num / 10;
                        end else if (numpad_selection_out == 11) begin // Enter
                            num2_out <= current_num;
                            case(op_code_out)
                                2'b00: result_out <= add_res;
                                2'b01: result_out <= sub_res;
                                2'b10: result_out <= mul_res;
                                2'b11: result_out <= div_res;
                            endcase
                            current_state <= S_SHOW_RESULT;
                        end
                    end
                     // ** FIXED: Assign current_num to num2_out OUTSIDE the 'if' block **
                    num2_out <= current_num;
                end

                S_SHOW_RESULT: begin
                    // ** FIXED: Reset now triggered correctly **
                    if (btnC_rising_edge) begin
                        manual_reset_req <= 1;
                    end
                end
            endcase
        end
    end

endmodule
