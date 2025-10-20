
//lower LUT (36) CANNOT DO imaginary numbers
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: quadratic_solver with synthesizable square root
// Fixed-iteration square root - no while loops
//////////////////////////////////////////////////////////////////////////////////

module quadratic_solver(
    input clk_6p25M,
    input reset,
    input signed [10:0] coeff_a,
    input signed [10:0] coeff_b,
    input signed [10:0] coeff_c,
    input [12:0] pixel_index,
    output reg [15:0] pixel_data
);

    localparam WIDTH  = 96;
    localparam HEIGHT = 64;

    // Pixel coordinates
    reg [6:0] x_pos;
    reg [5:0] y_pos;
    always @(*) begin
        x_pos = pixel_index % WIDTH;
        y_pos = pixel_index / WIDTH;
    end

    // Colors
    localparam COLOR_BG     = 16'h0000;
    localparam COLOR_RESULT = 16'h07FF;
    localparam COLOR_ERROR  = 16'hF800;

    // Computation signals
    reg signed [31:0] b_squared, four_ac, discriminant;
    reg [31:0] sqrt_disc;
    reg signed [31:0] x1, x2;
    reg signed [11:0] denom;
    reg [1:0] solution_type;

    // Fixed-iteration square root (non-restoring algorithm)
    // 16 iterations for 32-bit input
    function [15:0] sqrt_fixed;
        input [31:0] value;
        reg [31:0] a, b;
        reg [31:0] test;
        integer i;
        begin
            a = value;
            b = 0;
            
            // Unrolled 16 iterations (sufficient for 32-bit)
            for (i = 15; i >= 0; i = i - 1) begin
                test = (b << 1) | (1 << i);
                if (a >= test << i) begin
                    a = a - (test << i);
                    b = b | (1 << i);
                end
            end
            sqrt_fixed = b[15:0];
        end
    endfunction

    // Core computation - pipelined
    reg signed [31:0] b_squared_next, four_ac_next, discriminant_next;
    reg [31:0] sqrt_disc_next;
    reg signed [31:0] x1_next, x2_next;
    
    always @(posedge clk_6p25M) begin
        if (reset) begin
            b_squared <= 0;
            four_ac <= 0;
            discriminant <= 0;
            sqrt_disc <= 0;
            x1 <= 0;
            x2 <= 0;
            denom <= 1;
            solution_type <= 0;
        end else begin
            // Stage 1: Calculate discriminant components
            b_squared <= $signed(coeff_b) * $signed(coeff_b);
            four_ac <= ($signed(coeff_a) <<< 2) * $signed(coeff_c);  // 4*a*c
            denom <= coeff_a <<< 1;  // 2*a
            
            // Stage 2: Calculate discriminant
            discriminant <= b_squared - four_ac;
            
            // Stage 3: Determine solution type and calculate sqrt
            if ($signed(coeff_a) == 11'd0) begin
                solution_type <= 0;
                sqrt_disc <= 0;
            end else if ($signed(discriminant) < 0) begin
                solution_type <= 0;
                sqrt_disc <= 0;
            end else begin
                sqrt_disc <= sqrt_fixed(discriminant[31:0]);
                if (discriminant == 0)
                    solution_type <= 1;
                else
                    solution_type <= 2;
            end
            
            // Stage 4: Calculate roots
            if (solution_type != 0) begin
                x1 <= ($signed({1'b0, sqrt_disc}) - $signed(coeff_b)) / $signed(denom);
                x2 <= (-$signed({1'b0, sqrt_disc}) - $signed(coeff_b)) / $signed(denom);
            end else begin
                x1 <= 0;
                x2 <= 0;
            end
        end
    end

    // Character ROM
    function [4:0] get_char_row;
        input [7:0] char;
        input [2:0] row;
        begin
            case (char)
                "0": case(row)0:get_char_row=5'b01110;1:get_char_row=5'b10001;2:get_char_row=5'b10001;3:get_char_row=5'b10001;4:get_char_row=5'b10001;5:get_char_row=5'b10001;6:get_char_row=5'b01110;default:get_char_row=5'b00000;endcase
                "1": case(row)0:get_char_row=5'b00100;1:get_char_row=5'b01100;2:get_char_row=5'b00100;3:get_char_row=5'b00100;4:get_char_row=5'b00100;5:get_char_row=5'b00100;6:get_char_row=5'b01110;default:get_char_row=5'b00000;endcase
                "2": case(row)0:get_char_row=5'b01110;1:get_char_row=5'b10001;2:get_char_row=5'b00001;3:get_char_row=5'b00010;4:get_char_row=5'b00100;5:get_char_row=5'b01000;6:get_char_row=5'b11111;default:get_char_row=5'b00000;endcase
                "3": case(row)0:get_char_row=5'b11110;1:get_char_row=5'b00001;2:get_char_row=5'b00001;3:get_char_row=5'b01110;4:get_char_row=5'b00001;5:get_char_row=5'b00001;6:get_char_row=5'b11110;default:get_char_row=5'b00000;endcase
                "4": case(row)0:get_char_row=5'b00010;1:get_char_row=5'b00110;2:get_char_row=5'b01010;3:get_char_row=5'b10010;4:get_char_row=5'b11111;5:get_char_row=5'b00010;6:get_char_row=5'b00010;default:get_char_row=5'b00000;endcase
                "5": case(row)0:get_char_row=5'b11111;1:get_char_row=5'b10000;2:get_char_row=5'b11110;3:get_char_row=5'b00001;4:get_char_row=5'b00001;5:get_char_row=5'b10001;6:get_char_row=5'b01110;default:get_char_row=5'b00000;endcase
                "6": case(row)0:get_char_row=5'b01110;1:get_char_row=5'b10001;2:get_char_row=5'b10000;3:get_char_row=5'b11110;4:get_char_row=5'b10001;5:get_char_row=5'b10001;6:get_char_row=5'b01110;default:get_char_row=5'b00000;endcase
                "7": case(row)0:get_char_row=5'b11111;1:get_char_row=5'b00001;2:get_char_row=5'b00010;3:get_char_row=5'b00100;4:get_char_row=5'b01000;5:get_char_row=5'b01000;6:get_char_row=5'b01000;default:get_char_row=5'b00000;endcase
                "8": case(row)0:get_char_row=5'b01110;1:get_char_row=5'b10001;2:get_char_row=5'b10001;3:get_char_row=5'b01110;4:get_char_row=5'b10001;5:get_char_row=5'b10001;6:get_char_row=5'b01110;default:get_char_row=5'b00000;endcase
                "9": case(row)0:get_char_row=5'b01110;1:get_char_row=5'b10001;2:get_char_row=5'b10001;3:get_char_row=5'b01111;4:get_char_row=5'b00001;5:get_char_row=5'b00010;6:get_char_row=5'b01100;default:get_char_row=5'b00000;endcase
                "x": case(row)0:get_char_row=5'b00000;1:get_char_row=5'b00000;2:get_char_row=5'b10001;3:get_char_row=5'b01010;4:get_char_row=5'b00100;5:get_char_row=5'b01010;6:get_char_row=5'b10001;default:get_char_row=5'b00000;endcase
                "=": case(row)0:get_char_row=5'b00000;1:get_char_row=5'b00000;2:get_char_row=5'b11111;3:get_char_row=5'b00000;4:get_char_row=5'b11111;5:get_char_row=5'b00000;6:get_char_row=5'b00000;default:get_char_row=5'b00000;endcase
                "-": case(row)0:get_char_row=5'b00000;1:get_char_row=5'b00000;2:get_char_row=5'b00000;3:get_char_row=5'b11111;4:get_char_row=5'b00000;5:get_char_row=5'b00000;6:get_char_row=5'b00000;default:get_char_row=5'b00000;endcase
                "I": case(row)0:get_char_row=5'b01110;1:get_char_row=5'b00100;2:get_char_row=5'b00100;3:get_char_row=5'b00100;4:get_char_row=5'b00100;5:get_char_row=5'b00100;6:get_char_row=5'b01110;default:get_char_row=5'b00000;endcase
                "m": case(row)0:get_char_row=5'b00000;1:get_char_row=5'b00000;2:get_char_row=5'b11010;3:get_char_row=5'b10101;4:get_char_row=5'b10101;5:get_char_row=5'b10001;6:get_char_row=5'b10001;default:get_char_row=5'b00000;endcase
                "a": case(row)0:get_char_row=5'b00000;1:get_char_row=5'b00000;2:get_char_row=5'b01110;3:get_char_row=5'b00001;4:get_char_row=5'b01111;5:get_char_row=5'b10001;6:get_char_row=5'b01111;default:get_char_row=5'b00000;endcase
                "g": case(row)0:get_char_row=5'b00000;1:get_char_row=5'b00000;2:get_char_row=5'b01111;3:get_char_row=5'b10001;4:get_char_row=5'b01111;5:get_char_row=5'b00001;6:get_char_row=5'b01110;default:get_char_row=5'b00000;endcase
                "i": case(row)0:get_char_row=5'b00100;1:get_char_row=5'b00000;2:get_char_row=5'b01100;3:get_char_row=5'b00100;4:get_char_row=5'b00100;5:get_char_row=5'b00100;6:get_char_row=5'b01110;default:get_char_row=5'b00000;endcase
                "n": case(row)0:get_char_row=5'b00000;1:get_char_row=5'b00000;2:get_char_row=5'b10110;3:get_char_row=5'b11001;4:get_char_row=5'b10001;5:get_char_row=5'b10001;6:get_char_row=5'b10001;default:get_char_row=5'b00000;endcase
                "r": case(row)0:get_char_row=5'b00000;1:get_char_row=5'b00000;2:get_char_row=5'b10110;3:get_char_row=5'b11001;4:get_char_row=5'b10000;5:get_char_row=5'b10000;6:get_char_row=5'b10000;default:get_char_row=5'b00000;endcase
                "y": case(row)0:get_char_row=5'b00000;1:get_char_row=5'b00000;2:get_char_row=5'b10001;3:get_char_row=5'b10001;4:get_char_row=5'b01111;5:get_char_row=5'b00001;6:get_char_row=5'b01110;default:get_char_row=5'b00000;endcase
                " ": get_char_row=5'b00000;
                default: get_char_row=5'b00000;
            endcase
        end
    endfunction

    // Rendering
    reg is_text_pixel;
    reg [7:0] current_char;
    reg [2:0] char_row, char_col;
    reg [4:0] char_row_data;
    reg signed [31:0] abs_x1, abs_x2;
    reg [9:0] hunds1, tens1, ones1, hunds2, tens2, ones2;

    always @(*) begin
        pixel_data = COLOR_BG;
        is_text_pixel = 0;
        current_char = " ";
        char_row = 0;
        char_col = 0;

        // Calculate absolute values and digits
        abs_x1 = (x1[31]) ? -x1 : x1;
        abs_x2 = (x2[31]) ? -x2 : x2;
        
        hunds1 = (abs_x1 / 100) % 10;
        tens1 = (abs_x1 / 10) % 10;
        ones1 = abs_x1 % 10;
        hunds2 = (abs_x2 / 100) % 10;
        tens2 = (abs_x2 / 10) % 10;
        ones2 = abs_x2 % 10;

        // Display based on solution type
        if (solution_type == 0) begin
            // Show "Imaginary"
            if (y_pos >= 28 && y_pos <= 34) begin
                char_row = y_pos - 28;
                if      (x_pos >= 18 && x_pos < 23) begin current_char = "I"; char_col = x_pos - 18; end
                else if (x_pos >= 23 && x_pos < 28) begin current_char = "m"; char_col = x_pos - 23; end
                else if (x_pos >= 28 && x_pos < 33) begin current_char = "a"; char_col = x_pos - 28; end
                else if (x_pos >= 33 && x_pos < 38) begin current_char = "g"; char_col = x_pos - 33; end
                else if (x_pos >= 38 && x_pos < 43) begin current_char = "i"; char_col = x_pos - 38; end
                else if (x_pos >= 43 && x_pos < 48) begin current_char = "n"; char_col = x_pos - 43; end
                else if (x_pos >= 48 && x_pos < 53) begin current_char = "a"; char_col = x_pos - 48; end
                else if (x_pos >= 53 && x_pos < 58) begin current_char = "r"; char_col = x_pos - 53; end
                else if (x_pos >= 58 && x_pos < 63) begin current_char = "y"; char_col = x_pos - 58; end
                char_row_data = get_char_row(current_char, char_row);
                if (char_col < 5 && char_row_data[4-char_col]) is_text_pixel = 1;
            end
        end else begin
            // Show x1
            if (y_pos >= 24 && y_pos <= 30) begin
                char_row = y_pos - 24;
                if      (x_pos >= 10 && x_pos < 15) begin current_char = "x"; char_col = x_pos - 10; end
                else if (x_pos >= 15 && x_pos < 20) begin current_char = "1"; char_col = x_pos - 15; end
                else if (x_pos >= 20 && x_pos < 25) begin current_char = "="; char_col = x_pos - 20; end
                else if (x_pos >= 26 && x_pos < 31 && x1[31]) begin current_char = "-"; char_col = x_pos - 26; end
                else if (x_pos >= 31 && x_pos < 36 && hunds1 != 0) begin current_char = hunds1[7:0] + "0"; char_col = x_pos - 31; end
                else if (x_pos >= 36 && x_pos < 41 && (tens1 != 0 || hunds1 != 0)) begin current_char = tens1[7:0] + "0"; char_col = x_pos - 36; end
                else if (x_pos >= 41 && x_pos < 46) begin current_char = ones1[7:0] + "0"; char_col = x_pos - 41; end
                char_row_data = get_char_row(current_char, char_row);
                if (char_col < 5 && char_row_data[4-char_col]) is_text_pixel = 1;
            end
            
            // Show x2 if two roots
            if (solution_type == 2 && y_pos >= 36 && y_pos <= 42) begin
                char_row = y_pos - 36;
                if      (x_pos >= 10 && x_pos < 15) begin current_char = "x"; char_col = x_pos - 10; end
                else if (x_pos >= 15 && x_pos < 20) begin current_char = "2"; char_col = x_pos - 15; end
                else if (x_pos >= 20 && x_pos < 25) begin current_char = "="; char_col = x_pos - 20; end
                else if (x_pos >= 26 && x_pos < 31 && x2[31]) begin current_char = "-"; char_col = x_pos - 26; end
                else if (x_pos >= 31 && x_pos < 36 && hunds2 != 0) begin current_char = hunds2[7:0] + "0"; char_col = x_pos - 31; end
                else if (x_pos >= 36 && x_pos < 41 && (tens2 != 0 || hunds2 != 0)) begin current_char = tens2[7:0] + "0"; char_col = x_pos - 36; end
                else if (x_pos >= 41 && x_pos < 46) begin current_char = ones2[7:0] + "0"; char_col = x_pos - 41; end
                char_row_data = get_char_row(current_char, char_row);
                if (char_col < 5 && char_row_data[4-char_col]) is_text_pixel = 1;
            end
        end

        if (is_text_pixel) begin
            pixel_data = (solution_type == 0) ? COLOR_ERROR : COLOR_RESULT;
        end
    end

endmodule






////high LUT (70 percent) Can do most things well
//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Module: quadratic_solver with decimal and imaginary support
//// Shows results as: x1=2.5 or x1=2.3+1.5i
////////////////////////////////////////////////////////////////////////////////////

//module quadratic_solver(
//    input clk_6p25M,
//    input reset,
//    input signed [10:0] coeff_a,
//    input signed [10:0] coeff_b,
//    input signed [10:0] coeff_c,
//    input [12:0] pixel_index,
//    output reg [15:0] pixel_data
//);

//    localparam WIDTH  = 96;
//    localparam HEIGHT = 64;

//    reg [6:0] x_pos;
//    reg [5:0] y_pos;
//    always @(*) begin
//        x_pos = pixel_index % WIDTH;
//        y_pos = pixel_index / WIDTH;
//    end

//    // Colors
//    localparam COLOR_BG     = 16'h0000;
//    localparam COLOR_RESULT = 16'h07FF;
//    localparam COLOR_IMAG   = 16'hF81F;  // Magenta for imaginary

//    // Computation signals
//    reg signed [31:0] b_squared, four_ac, discriminant;
//    reg [31:0] sqrt_disc;
//    reg signed [31:0] real_part;      // For both real and imaginary cases
//    reg signed [31:0] imag_part;      // Imaginary coefficient
//    reg signed [31:0] x1, x2;         // Real solutions
//    reg signed [11:0] denom;
//    reg is_imaginary;

//    // Fixed-iteration square root
//    function [15:0] sqrt_fixed;
//        input [31:0] value;
//        reg [31:0] a, b;
//        reg [31:0] test;
//        integer i;
//        begin
//            a = value;
//            b = 0;
//            for (i = 15; i >= 0; i = i - 1) begin
//                test = (b << 1) | (1 << i);
//                if (a >= test << i) begin
//                    a = a - (test << i);
//                    b = b | (1 << i);
//                end
//            end
//            sqrt_fixed = b[15:0];
//        end
//    endfunction

//    // Core computation
//    always @(posedge clk_6p25M) begin
//        if (reset) begin
//            b_squared <= 0;
//            four_ac <= 0;
//            discriminant <= 0;
//            sqrt_disc <= 0;
//            x1 <= 0;
//            x2 <= 0;
//            real_part <= 0;
//            imag_part <= 0;
//            denom <= 1;
//            is_imaginary <= 0;
//        end else begin
//            // Calculate discriminant
//            b_squared <= $signed(coeff_b) * $signed(coeff_b);
//            four_ac <= ($signed(coeff_a) <<< 2) * $signed(coeff_c);
//            discriminant <= b_squared - four_ac;
//            denom <= coeff_a <<< 1;  // 2a
            
//            if ($signed(coeff_a) == 11'd0) begin
//                is_imaginary <= 0;
//                x1 <= 0;
//                x2 <= 0;
//            end else if ($signed(discriminant) < 0) begin
//                // Imaginary: x = -b/(2a) ± i*sqrt(|disc|)/(2a)
//                is_imaginary <= 1;
//                // Scale by 100 for decimal precision: sqrt(|disc|*100) gives sqrt*10
//                sqrt_disc <= sqrt_fixed((-discriminant) * 100);
                
//                // Real part: -b*10/(2a) for 1 decimal display
//                real_part <= (-$signed(coeff_b) * 10) / $signed(denom);
                
//                // Imaginary coefficient: sqrt(|disc|*100)/(2a) already scaled
//                imag_part <= $signed({1'b0, sqrt_disc}) / $signed(denom);
//            end else begin
//                // Real solutions
//                is_imaginary <= 0;
//                // Scale discriminant by 100: sqrt(disc*100) = sqrt(disc)*10
//                sqrt_disc <= sqrt_fixed(discriminant[31:0] * 100);
                
//                // Formula: x*10 = (-b*10 ± sqrt(disc*100)) / 2a
//                x1 <= (($signed({1'b0, sqrt_disc}) - ($signed(coeff_b) * 10))) / $signed(denom);
//                x2 <= ((-$signed({1'b0, sqrt_disc}) - ($signed(coeff_b) * 10))) / $signed(denom);
//            end
//        end
//    end

//    // Character ROM
//    function [4:0] get_char_row;
//        input [7:0] char;
//        input [2:0] row;
//        begin
//            case (char)
//                "0": case(row)0:get_char_row=5'b01110;1:get_char_row=5'b10001;2:get_char_row=5'b10001;3:get_char_row=5'b10001;4:get_char_row=5'b10001;5:get_char_row=5'b10001;6:get_char_row=5'b01110;default:get_char_row=5'b00000;endcase
//                "1": case(row)0:get_char_row=5'b00100;1:get_char_row=5'b01100;2:get_char_row=5'b00100;3:get_char_row=5'b00100;4:get_char_row=5'b00100;5:get_char_row=5'b00100;6:get_char_row=5'b01110;default:get_char_row=5'b00000;endcase
//                "2": case(row)0:get_char_row=5'b01110;1:get_char_row=5'b10001;2:get_char_row=5'b00001;3:get_char_row=5'b00010;4:get_char_row=5'b00100;5:get_char_row=5'b01000;6:get_char_row=5'b11111;default:get_char_row=5'b00000;endcase
//                "3": case(row)0:get_char_row=5'b11110;1:get_char_row=5'b00001;2:get_char_row=5'b00001;3:get_char_row=5'b01110;4:get_char_row=5'b00001;5:get_char_row=5'b00001;6:get_char_row=5'b11110;default:get_char_row=5'b00000;endcase
//                "4": case(row)0:get_char_row=5'b00010;1:get_char_row=5'b00110;2:get_char_row=5'b01010;3:get_char_row=5'b10010;4:get_char_row=5'b11111;5:get_char_row=5'b00010;6:get_char_row=5'b00010;default:get_char_row=5'b00000;endcase
//                "5": case(row)0:get_char_row=5'b11111;1:get_char_row=5'b10000;2:get_char_row=5'b11110;3:get_char_row=5'b00001;4:get_char_row=5'b00001;5:get_char_row=5'b10001;6:get_char_row=5'b01110;default:get_char_row=5'b00000;endcase
//                "6": case(row)0:get_char_row=5'b01110;1:get_char_row=5'b10001;2:get_char_row=5'b10000;3:get_char_row=5'b11110;4:get_char_row=5'b10001;5:get_char_row=5'b10001;6:get_char_row=5'b01110;default:get_char_row=5'b00000;endcase
//                "7": case(row)0:get_char_row=5'b11111;1:get_char_row=5'b00001;2:get_char_row=5'b00010;3:get_char_row=5'b00100;4:get_char_row=5'b01000;5:get_char_row=5'b01000;6:get_char_row=5'b01000;default:get_char_row=5'b00000;endcase
//                "8": case(row)0:get_char_row=5'b01110;1:get_char_row=5'b10001;2:get_char_row=5'b10001;3:get_char_row=5'b01110;4:get_char_row=5'b10001;5:get_char_row=5'b10001;6:get_char_row=5'b01110;default:get_char_row=5'b00000;endcase
//                "9": case(row)0:get_char_row=5'b01110;1:get_char_row=5'b10001;2:get_char_row=5'b10001;3:get_char_row=5'b01111;4:get_char_row=5'b00001;5:get_char_row=5'b00010;6:get_char_row=5'b01100;default:get_char_row=5'b00000;endcase
//                "x": case(row)0:get_char_row=5'b00000;1:get_char_row=5'b00000;2:get_char_row=5'b10001;3:get_char_row=5'b01010;4:get_char_row=5'b00100;5:get_char_row=5'b01010;6:get_char_row=5'b10001;default:get_char_row=5'b00000;endcase
//                "=": case(row)0:get_char_row=5'b00000;1:get_char_row=5'b00000;2:get_char_row=5'b11111;3:get_char_row=5'b00000;4:get_char_row=5'b11111;5:get_char_row=5'b00000;6:get_char_row=5'b00000;default:get_char_row=5'b00000;endcase
//                "-": case(row)0:get_char_row=5'b00000;1:get_char_row=5'b00000;2:get_char_row=5'b00000;3:get_char_row=5'b11111;4:get_char_row=5'b00000;5:get_char_row=5'b00000;6:get_char_row=5'b00000;default:get_char_row=5'b00000;endcase
//                "+": case(row)0:get_char_row=5'b00000;1:get_char_row=5'b00100;2:get_char_row=5'b00100;3:get_char_row=5'b11111;4:get_char_row=5'b00100;5:get_char_row=5'b00100;6:get_char_row=5'b00000;default:get_char_row=5'b00000;endcase
//                ".": case(row)0:get_char_row=5'b00000;1:get_char_row=5'b00000;2:get_char_row=5'b00000;3:get_char_row=5'b00000;4:get_char_row=5'b00000;5:get_char_row=5'b01100;6:get_char_row=5'b01100;default:get_char_row=5'b00000;endcase
//                "i": case(row)0:get_char_row=5'b00100;1:get_char_row=5'b00000;2:get_char_row=5'b01100;3:get_char_row=5'b00100;4:get_char_row=5'b00100;5:get_char_row=5'b00100;6:get_char_row=5'b01110;default:get_char_row=5'b00000;endcase
//                " ": get_char_row=5'b00000;
//                default: get_char_row=5'b00000;
//            endcase
//        end
//    endfunction

//    // Rendering
//    reg is_text_pixel;
//    reg [7:0] current_char;
//    reg [2:0] char_row, char_col;
//    reg [4:0] char_row_data;
//    reg signed [31:0] abs_val;
//    reg [9:0] tens, ones, dec;

//    // Helper to extract digits with decimal
//    task extract_digits;
//        input signed [31:0] value;
//        output [9:0] tens_out, ones_out, dec_out;
//        reg signed [31:0] abs_temp;
//        begin
//            abs_temp = (value[31]) ? -value : value;
//            tens_out = (abs_temp / 100) % 10;
//            ones_out = (abs_temp / 10) % 10;
//            dec_out = abs_temp % 10;
//        end
//    endtask

//    always @(*) begin
//        pixel_data = COLOR_BG;
//        is_text_pixel = 0;
//        current_char = " ";
//        char_row = 0;
//        char_col = 0;

//        if (is_imaginary) begin
//            // Display: x = a.b ± c.d i
//            // Line 1: x1 = real+imag i
//            if (y_pos >= 20 && y_pos <= 26) begin
//                char_row = y_pos - 20;
//                extract_digits(real_part, tens, ones, dec);
                
//                if      (x_pos >= 8 && x_pos < 13)  begin current_char = "x"; char_col = x_pos - 8; end
//                else if (x_pos >= 13 && x_pos < 18) begin current_char = "1"; char_col = x_pos - 13; end
//                else if (x_pos >= 18 && x_pos < 23) begin current_char = "="; char_col = x_pos - 18; end
//                else if (x_pos >= 23 && x_pos < 28 && real_part[31]) begin current_char = "-"; char_col = x_pos - 23; end
//                else if (x_pos >= 28 && x_pos < 33 && tens != 0) begin current_char = tens[7:0] + "0"; char_col = x_pos - 28; end
//                else if (x_pos >= 33 && x_pos < 38) begin current_char = ones[7:0] + "0"; char_col = x_pos - 33; end
//                else if (x_pos >= 38 && x_pos < 43) begin current_char = "."; char_col = x_pos - 38; end
//                else if (x_pos >= 43 && x_pos < 48) begin current_char = dec[7:0] + "0"; char_col = x_pos - 43; end
//                else if (x_pos >= 48 && x_pos < 53) begin current_char = "+"; char_col = x_pos - 48; end
                
//                char_row_data = get_char_row(current_char, char_row);
//                if (char_col < 5 && char_row_data[4-char_col]) is_text_pixel = 1;
//            end
            
//            // Imaginary part on same line
//            if (y_pos >= 20 && y_pos <= 26) begin
//                char_row = y_pos - 20;
//                extract_digits(imag_part, tens, ones, dec);
                
//                if      (x_pos >= 53 && x_pos < 58 && tens != 0) begin current_char = tens[7:0] + "0"; char_col = x_pos - 53; end
//                else if (x_pos >= 58 && x_pos < 63) begin current_char = ones[7:0] + "0"; char_col = x_pos - 58; end
//                else if (x_pos >= 63 && x_pos < 68) begin current_char = "."; char_col = x_pos - 63; end
//                else if (x_pos >= 68 && x_pos < 73) begin current_char = dec[7:0] + "0"; char_col = x_pos - 68; end
//                else if (x_pos >= 73 && x_pos < 78) begin current_char = "i"; char_col = x_pos - 73; end
                
//                char_row_data = get_char_row(current_char, char_row);
//                if (char_col < 5 && char_row_data[4-char_col]) is_text_pixel = 1;
//            end
            
//            // Line 2: x2 = real-imag i
//            if (y_pos >= 34 && y_pos <= 40) begin
//                char_row = y_pos - 34;
//                extract_digits(real_part, tens, ones, dec);
                
//                if      (x_pos >= 8 && x_pos < 13)  begin current_char = "x"; char_col = x_pos - 8; end
//                else if (x_pos >= 13 && x_pos < 18) begin current_char = "2"; char_col = x_pos - 13; end
//                else if (x_pos >= 18 && x_pos < 23) begin current_char = "="; char_col = x_pos - 18; end
//                else if (x_pos >= 23 && x_pos < 28 && real_part[31]) begin current_char = "-"; char_col = x_pos - 23; end
//                else if (x_pos >= 28 && x_pos < 33 && tens != 0) begin current_char = tens[7:0] + "0"; char_col = x_pos - 28; end
//                else if (x_pos >= 33 && x_pos < 38) begin current_char = ones[7:0] + "0"; char_col = x_pos - 33; end
//                else if (x_pos >= 38 && x_pos < 43) begin current_char = "."; char_col = x_pos - 38; end
//                else if (x_pos >= 43 && x_pos < 48) begin current_char = dec[7:0] + "0"; char_col = x_pos - 43; end
//                else if (x_pos >= 48 && x_pos < 53) begin current_char = "-"; char_col = x_pos - 48; end
                
//                char_row_data = get_char_row(current_char, char_row);
//                if (char_col < 5 && char_row_data[4-char_col]) is_text_pixel = 1;
//            end
            
//            if (y_pos >= 34 && y_pos <= 40) begin
//                char_row = y_pos - 34;
//                extract_digits(imag_part, tens, ones, dec);
                
//                if      (x_pos >= 53 && x_pos < 58 && tens != 0) begin current_char = tens[7:0] + "0"; char_col = x_pos - 53; end
//                else if (x_pos >= 58 && x_pos < 63) begin current_char = ones[7:0] + "0"; char_col = x_pos - 58; end
//                else if (x_pos >= 63 && x_pos < 68) begin current_char = "."; char_col = x_pos - 63; end
//                else if (x_pos >= 68 && x_pos < 73) begin current_char = dec[7:0] + "0"; char_col = x_pos - 68; end
//                else if (x_pos >= 73 && x_pos < 78) begin current_char = "i"; char_col = x_pos - 73; end
                
//                char_row_data = get_char_row(current_char, char_row);
//                if (char_col < 5 && char_row_data[4-char_col]) is_text_pixel = 1;
//            end
            
//            if (is_text_pixel) pixel_data = COLOR_IMAG;
            
//        end else begin
//            // Real solutions with decimals
//            // x1 = a.b
//            if (y_pos >= 24 && y_pos <= 30) begin
//                char_row = y_pos - 24;
//                extract_digits(x1, tens, ones, dec);
                
//                if      (x_pos >= 18 && x_pos < 23) begin current_char = "x"; char_col = x_pos - 18; end
//                else if (x_pos >= 23 && x_pos < 28) begin current_char = "1"; char_col = x_pos - 23; end
//                else if (x_pos >= 28 && x_pos < 33) begin current_char = "="; char_col = x_pos - 28; end
//                else if (x_pos >= 33 && x_pos < 38 && x1[31]) begin current_char = "-"; char_col = x_pos - 33; end
//                else if (x_pos >= 38 && x_pos < 43 && tens != 0) begin current_char = tens[7:0] + "0"; char_col = x_pos - 38; end
//                else if (x_pos >= 43 && x_pos < 48) begin current_char = ones[7:0] + "0"; char_col = x_pos - 43; end
//                else if (x_pos >= 48 && x_pos < 53) begin current_char = "."; char_col = x_pos - 48; end
//                else if (x_pos >= 53 && x_pos < 58) begin current_char = dec[7:0] + "0"; char_col = x_pos - 53; end
                
//                char_row_data = get_char_row(current_char, char_row);
//                if (char_col < 5 && char_row_data[4-char_col]) is_text_pixel = 1;
//            end
            
//            // x2 = c.d
//            if (y_pos >= 38 && y_pos <= 44) begin
//                char_row = y_pos - 38;
//                extract_digits(x2, tens, ones, dec);
                
//                if      (x_pos >= 18 && x_pos < 23) begin current_char = "x"; char_col = x_pos - 18; end
//                else if (x_pos >= 23 && x_pos < 28) begin current_char = "2"; char_col = x_pos - 23; end
//                else if (x_pos >= 28 && x_pos < 33) begin current_char = "="; char_col = x_pos - 28; end
//                else if (x_pos >= 33 && x_pos < 38 && x2[31]) begin current_char = "-"; char_col = x_pos - 33; end
//                else if (x_pos >= 38 && x_pos < 43 && tens != 0) begin current_char = tens[7:0] + "0"; char_col = x_pos - 38; end
//                else if (x_pos >= 43 && x_pos < 48) begin current_char = ones[7:0] + "0"; char_col = x_pos - 43; end
//                else if (x_pos >= 48 && x_pos < 53) begin current_char = "."; char_col = x_pos - 48; end
//                else if (x_pos >= 53 && x_pos < 58) begin current_char = dec[7:0] + "0"; char_col = x_pos - 53; end
                
//                char_row_data = get_char_row(current_char, char_row);
//                if (char_col < 5 && char_row_data[4-char_col]) is_text_pixel = 1;
//            end
            
//            if (is_text_pixel) pixel_data = COLOR_RESULT;
//        end
//    end

//endmodule



//1 d.p

//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Module: quadratic_solver - Integer results with imaginary support
//// Shows: x1=2+3i or x1=5 (whole numbers only)
////////////////////////////////////////////////////////////////////////////////////

//module quadratic_solver(
//    input clk_6p25M,
//    input reset,
//    input signed [10:0] coeff_a,
//    input signed [10:0] coeff_b,
//    input signed [10:0] coeff_c,
//    input [12:0] pixel_index,
//    output reg [15:0] pixel_data
//);

//    localparam WIDTH  = 96;
//    localparam HEIGHT = 64;

//    reg [6:0] x_pos;
//    reg [5:0] y_pos;
//    always @(*) begin
//        x_pos = pixel_index % WIDTH;
//        y_pos = pixel_index / WIDTH;
//    end

//    // Colors
//    localparam COLOR_BG     = 16'h0000;
//    localparam COLOR_RESULT = 16'h07FF;
//    localparam COLOR_IMAG   = 16'hF81F;  // Magenta for imaginary

//    // Computation signals
//    reg signed [31:0] b_squared, four_ac, discriminant;
//    reg [31:0] sqrt_disc;
//    reg signed [31:0] real_part;      // Real part for imaginary solutions
//    reg signed [31:0] imag_part;      // Imaginary coefficient
//    reg signed [31:0] x1, x2;         // Real solutions
//    reg signed [11:0] denom;
//    reg is_imaginary;

//    // Fixed-iteration square root
//    function [15:0] sqrt_fixed;
//        input [31:0] value;
//        reg [31:0] a, b;
//        reg [31:0] test;
//        integer i;
//        begin
//            a = value;
//            b = 0;
//            for (i = 15; i >= 0; i = i - 1) begin
//                test = (b << 1) | (1 << i);
//                if (a >= test << i) begin
//                    a = a - (test << i);
//                    b = b | (1 << i);
//                end
//            end
//            sqrt_fixed = b[15:0];
//        end
//    endfunction

//    // Core computation
//    always @(posedge clk_6p25M) begin
//        if (reset) begin
//            b_squared <= 0;
//            four_ac <= 0;
//            discriminant <= 0;
//            sqrt_disc <= 0;
//            x1 <= 0;
//            x2 <= 0;
//            real_part <= 0;
//            imag_part <= 0;
//            denom <= 1;
//            is_imaginary <= 0;
//        end else begin
//            // Calculate discriminant
//            b_squared <= $signed(coeff_b) * $signed(coeff_b);
//            four_ac <= ($signed(coeff_a) <<< 2) * $signed(coeff_c);
//            discriminant <= b_squared - four_ac;
//            denom <= coeff_a <<< 1;  // 2a
            
//            if ($signed(coeff_a) == 11'd0) begin
//                is_imaginary <= 0;
//                x1 <= 0;
//                x2 <= 0;
//            end else if ($signed(discriminant) < 0) begin
//                // Imaginary: x = -b/(2a) ± i*sqrt(|disc|)/(2a)
//                is_imaginary <= 1;
//                sqrt_disc <= sqrt_fixed(-discriminant);  // sqrt of |disc|
                
//                // Real part: -b/(2a)
//                real_part <= -$signed(coeff_b) / $signed(denom);
                
//                // Imaginary coefficient: sqrt(|disc|)/(2a)
//                imag_part <= $signed({1'b0, sqrt_disc}) / $signed(denom);
//            end else begin
//                // Real solutions
//                is_imaginary <= 0;
//                sqrt_disc <= sqrt_fixed(discriminant[31:0]);
                
//                // x = (-b ± sqrt(disc)) / 2a
//                x1 <= ($signed({1'b0, sqrt_disc}) - $signed(coeff_b)) / $signed(denom);
//                x2 <= (-$signed({1'b0, sqrt_disc}) - $signed(coeff_b)) / $signed(denom);
//            end
//        end
//    end

//    // Character ROM
//    function [4:0] get_char_row;
//        input [7:0] char;
//        input [2:0] row;
//        begin
//            case (char)
//                "0": case(row)0:get_char_row=5'b01110;1:get_char_row=5'b10001;2:get_char_row=5'b10001;3:get_char_row=5'b10001;4:get_char_row=5'b10001;5:get_char_row=5'b10001;6:get_char_row=5'b01110;default:get_char_row=5'b00000;endcase
//                "1": case(row)0:get_char_row=5'b00100;1:get_char_row=5'b01100;2:get_char_row=5'b00100;3:get_char_row=5'b00100;4:get_char_row=5'b00100;5:get_char_row=5'b00100;6:get_char_row=5'b01110;default:get_char_row=5'b00000;endcase
//                "2": case(row)0:get_char_row=5'b01110;1:get_char_row=5'b10001;2:get_char_row=5'b00001;3:get_char_row=5'b00010;4:get_char_row=5'b00100;5:get_char_row=5'b01000;6:get_char_row=5'b11111;default:get_char_row=5'b00000;endcase
//                "3": case(row)0:get_char_row=5'b11110;1:get_char_row=5'b00001;2:get_char_row=5'b00001;3:get_char_row=5'b01110;4:get_char_row=5'b00001;5:get_char_row=5'b00001;6:get_char_row=5'b11110;default:get_char_row=5'b00000;endcase
//                "4": case(row)0:get_char_row=5'b00010;1:get_char_row=5'b00110;2:get_char_row=5'b01010;3:get_char_row=5'b10010;4:get_char_row=5'b11111;5:get_char_row=5'b00010;6:get_char_row=5'b00010;default:get_char_row=5'b00000;endcase
//                "5": case(row)0:get_char_row=5'b11111;1:get_char_row=5'b10000;2:get_char_row=5'b11110;3:get_char_row=5'b00001;4:get_char_row=5'b00001;5:get_char_row=5'b10001;6:get_char_row=5'b01110;default:get_char_row=5'b00000;endcase
//                "6": case(row)0:get_char_row=5'b01110;1:get_char_row=5'b10001;2:get_char_row=5'b10000;3:get_char_row=5'b11110;4:get_char_row=5'b10001;5:get_char_row=5'b10001;6:get_char_row=5'b01110;default:get_char_row=5'b00000;endcase
//                "7": case(row)0:get_char_row=5'b11111;1:get_char_row=5'b00001;2:get_char_row=5'b00010;3:get_char_row=5'b00100;4:get_char_row=5'b01000;5:get_char_row=5'b01000;6:get_char_row=5'b01000;default:get_char_row=5'b00000;endcase
//                "8": case(row)0:get_char_row=5'b01110;1:get_char_row=5'b10001;2:get_char_row=5'b10001;3:get_char_row=5'b01110;4:get_char_row=5'b10001;5:get_char_row=5'b10001;6:get_char_row=5'b01110;default:get_char_row=5'b00000;endcase
//                "9": case(row)0:get_char_row=5'b01110;1:get_char_row=5'b10001;2:get_char_row=5'b10001;3:get_char_row=5'b01111;4:get_char_row=5'b00001;5:get_char_row=5'b00010;6:get_char_row=5'b01100;default:get_char_row=5'b00000;endcase
//                "x": case(row)0:get_char_row=5'b00000;1:get_char_row=5'b00000;2:get_char_row=5'b10001;3:get_char_row=5'b01010;4:get_char_row=5'b00100;5:get_char_row=5'b01010;6:get_char_row=5'b10001;default:get_char_row=5'b00000;endcase
//                "=": case(row)0:get_char_row=5'b00000;1:get_char_row=5'b00000;2:get_char_row=5'b11111;3:get_char_row=5'b00000;4:get_char_row=5'b11111;5:get_char_row=5'b00000;6:get_char_row=5'b00000;default:get_char_row=5'b00000;endcase
//                "-": case(row)0:get_char_row=5'b00000;1:get_char_row=5'b00000;2:get_char_row=5'b00000;3:get_char_row=5'b11111;4:get_char_row=5'b00000;5:get_char_row=5'b00000;6:get_char_row=5'b00000;default:get_char_row=5'b00000;endcase
//                "+": case(row)0:get_char_row=5'b00000;1:get_char_row=5'b00100;2:get_char_row=5'b00100;3:get_char_row=5'b11111;4:get_char_row=5'b00100;5:get_char_row=5'b00100;6:get_char_row=5'b00000;default:get_char_row=5'b00000;endcase
//                "i": case(row)0:get_char_row=5'b00100;1:get_char_row=5'b00000;2:get_char_row=5'b01100;3:get_char_row=5'b00100;4:get_char_row=5'b00100;5:get_char_row=5'b00100;6:get_char_row=5'b01110;default:get_char_row=5'b00000;endcase
//                " ": get_char_row=5'b00000;
//                default: get_char_row=5'b00000;
//            endcase
//        end
//    endfunction

//    // Rendering
//    reg is_text_pixel;
//    reg [7:0] current_char;
//    reg [2:0] char_row, char_col;
//    reg [4:0] char_row_data;
//    reg signed [31:0] abs_val;
//    reg [9:0] hunds, tens, ones;

//    // Extract digits for integer display
//    task extract_digits;
//        input signed [31:0] value;
//        output [9:0] hunds_out, tens_out, ones_out;
//        reg signed [31:0] abs_temp;
//        begin
//            abs_temp = (value[31]) ? -value : value;
//            hunds_out = (abs_temp / 100) % 10;
//            tens_out = (abs_temp / 10) % 10;
//            ones_out = abs_temp % 10;
//        end
//    endtask

//    always @(*) begin
//        pixel_data = COLOR_BG;
//        is_text_pixel = 0;
//        current_char = " ";
//        char_row = 0;
//        char_col = 0;

//        if (is_imaginary) begin
//            // Display: x1 = a+bi, x2 = a-bi
            
//            // Line 1: x1 = real + imag i
//            if (y_pos >= 20 && y_pos <= 26) begin
//                char_row = y_pos - 20;
//                extract_digits(real_part, hunds, tens, ones);
                
//                if      (x_pos >= 8 && x_pos < 13)  begin current_char = "x"; char_col = x_pos - 8; end
//                else if (x_pos >= 13 && x_pos < 18) begin current_char = "1"; char_col = x_pos - 13; end
//                else if (x_pos >= 18 && x_pos < 23) begin current_char = "="; char_col = x_pos - 18; end
//                else if (x_pos >= 23 && x_pos < 28 && real_part[31]) begin current_char = "-"; char_col = x_pos - 23; end
//                else if (x_pos >= 28 && x_pos < 33 && hunds != 0) begin current_char = hunds[7:0] + "0"; char_col = x_pos - 28; end
//                else if (x_pos >= 33 && x_pos < 38 && (tens != 0 || hunds != 0)) begin current_char = tens[7:0] + "0"; char_col = x_pos - 33; end
//                else if (x_pos >= 38 && x_pos < 43) begin current_char = ones[7:0] + "0"; char_col = x_pos - 38; end
//                else if (x_pos >= 43 && x_pos < 48) begin current_char = "+"; char_col = x_pos - 43; end
                
//                char_row_data = get_char_row(current_char, char_row);
//                if (char_col < 5 && char_row_data[4-char_col]) is_text_pixel = 1;
//            end
            
//            // Imaginary part on same line
//            if (y_pos >= 20 && y_pos <= 26) begin
//                char_row = y_pos - 20;
//                extract_digits(imag_part, hunds, tens, ones);
                
//                if      (x_pos >= 48 && x_pos < 53 && hunds != 0) begin current_char = hunds[7:0] + "0"; char_col = x_pos - 48; end
//                else if (x_pos >= 53 && x_pos < 58 && (tens != 0 || hunds != 0)) begin current_char = tens[7:0] + "0"; char_col = x_pos - 53; end
//                else if (x_pos >= 58 && x_pos < 63) begin current_char = ones[7:0] + "0"; char_col = x_pos - 58; end
//                else if (x_pos >= 63 && x_pos < 68) begin current_char = "i"; char_col = x_pos - 63; end
                
//                char_row_data = get_char_row(current_char, char_row);
//                if (char_col < 5 && char_row_data[4-char_col]) is_text_pixel = 1;
//            end
            
//            // Line 2: x2 = real - imag i
//            if (y_pos >= 34 && y_pos <= 40) begin
//                char_row = y_pos - 34;
//                extract_digits(real_part, hunds, tens, ones);
                
//                if      (x_pos >= 8 && x_pos < 13)  begin current_char = "x"; char_col = x_pos - 8; end
//                else if (x_pos >= 13 && x_pos < 18) begin current_char = "2"; char_col = x_pos - 13; end
//                else if (x_pos >= 18 && x_pos < 23) begin current_char = "="; char_col = x_pos - 18; end
//                else if (x_pos >= 23 && x_pos < 28 && real_part[31]) begin current_char = "-"; char_col = x_pos - 23; end
//                else if (x_pos >= 28 && x_pos < 33 && hunds != 0) begin current_char = hunds[7:0] + "0"; char_col = x_pos - 28; end
//                else if (x_pos >= 33 && x_pos < 38 && (tens != 0 || hunds != 0)) begin current_char = tens[7:0] + "0"; char_col = x_pos - 33; end
//                else if (x_pos >= 38 && x_pos < 43) begin current_char = ones[7:0] + "0"; char_col = x_pos - 38; end
//                else if (x_pos >= 43 && x_pos < 48) begin current_char = "-"; char_col = x_pos - 43; end
                
//                char_row_data = get_char_row(current_char, char_row);
//                if (char_col < 5 && char_row_data[4-char_col]) is_text_pixel = 1;
//            end
            
//            if (y_pos >= 34 && y_pos <= 40) begin
//                char_row = y_pos - 34;
//                extract_digits(imag_part, hunds, tens, ones);
                
//                if      (x_pos >= 48 && x_pos < 53 && hunds != 0) begin current_char = hunds[7:0] + "0"; char_col = x_pos - 48; end
//                else if (x_pos >= 53 && x_pos < 58 && (tens != 0 || hunds != 0)) begin current_char = tens[7:0] + "0"; char_col = x_pos - 53; end
//                else if (x_pos >= 58 && x_pos < 63) begin current_char = ones[7:0] + "0"; char_col = x_pos - 58; end
//                else if (x_pos >= 63 && x_pos < 68) begin current_char = "i"; char_col = x_pos - 63; end
                
//                char_row_data = get_char_row(current_char, char_row);
//                if (char_col < 5 && char_row_data[4-char_col]) is_text_pixel = 1;
//            end
            
//            if (is_text_pixel) pixel_data = COLOR_IMAG;
            
//        end else begin
//            // Real solutions (integers only)
            
//            // x1
//            if (y_pos >= 24 && y_pos <= 30) begin
//                char_row = y_pos - 24;
//                extract_digits(x1, hunds, tens, ones);
                
//                if      (x_pos >= 18 && x_pos < 23) begin current_char = "x"; char_col = x_pos - 18; end
//                else if (x_pos >= 23 && x_pos < 28) begin current_char = "1"; char_col = x_pos - 23; end
//                else if (x_pos >= 28 && x_pos < 33) begin current_char = "="; char_col = x_pos - 28; end
//                else if (x_pos >= 33 && x_pos < 38 && x1[31]) begin current_char = "-"; char_col = x_pos - 33; end
//                else if (x_pos >= 38 && x_pos < 43 && hunds != 0) begin current_char = hunds[7:0] + "0"; char_col = x_pos - 38; end
//                else if (x_pos >= 43 && x_pos < 48 && (tens != 0 || hunds != 0)) begin current_char = tens[7:0] + "0"; char_col = x_pos - 43; end
//                else if (x_pos >= 48 && x_pos < 53) begin current_char = ones[7:0] + "0"; char_col = x_pos - 48; end
                
//                char_row_data = get_char_row(current_char, char_row);
//                if (char_col < 5 && char_row_data[4-char_col]) is_text_pixel = 1;
//            end
            
//            // x2
//            if (y_pos >= 38 && y_pos <= 44) begin
//                char_row = y_pos - 38;
//                extract_digits(x2, hunds, tens, ones);
                
//                if      (x_pos >= 18 && x_pos < 23) begin current_char = "x"; char_col = x_pos - 18; end
//                else if (x_pos >= 23 && x_pos < 28) begin current_char = "2"; char_col = x_pos - 23; end
//                else if (x_pos >= 28 && x_pos < 33) begin current_char = "="; char_col = x_pos - 28; end
//                else if (x_pos >= 33 && x_pos < 38 && x2[31]) begin current_char = "-"; char_col = x_pos - 33; end
//                else if (x_pos >= 38 && x_pos < 43 && hunds != 0) begin current_char = hunds[7:0] + "0"; char_col = x_pos - 38; end
//                else if (x_pos >= 43 && x_pos < 48 && (tens != 0 || hunds != 0)) begin current_char = tens[7:0] + "0"; char_col = x_pos - 43; end
//                else if (x_pos >= 48 && x_pos < 53) begin current_char = ones[7:0] + "0"; char_col = x_pos - 48; end
                
//                char_row_data = get_char_row(current_char, char_row);
//                if (char_col < 5 && char_row_data[4-char_col]) is_text_pixel = 1;
//            end
            
//            if (is_text_pixel) pixel_data = COLOR_RESULT;
//        end
//    end

//endmodule



