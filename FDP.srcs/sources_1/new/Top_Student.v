`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
//
//  FILL IN THE FOLLOWING INFORMATION:
//  STUDENT A NAME: 
//  STUDENT B NAME:
//  STUDENT C NAME: 
//  STUDENT D NAME:  
//
//////////////////////////////////////////////////////////////////////////////////

module Top_Student(
    input clk,              
    input btnC,            
    input btnL, btnR, 
    input [12:0] pixel_index,
    output reg [15:0] pixel_data
);

    // Clock divider: 100 MHz -> 6.25 MHz (existing)
    wire clk6p25;
    clk_div_625kHz div_inst(
        .clk(clk),
        .reset(btnC),
        .clk_out(clk6p25)
    );

    // OLED wiring
//    wire oled_clk, oled_mosi, oled_dc, oled_res, oled_cs;
//    assign JB[0] = oled_cs; assign JB[1] = oled_mosi; assign JB[2] = 1'b0;
//    assign JB[3] = oled_clk; assign JB[4] = oled_dc; assign JB[5] = oled_res;
//    assign JB[6] = 1'b1; assign JB[7] = 1'b1;

//    // OLED driver
//    Oled_Display oled(
//        .clk(clk6p25),
//        .reset(btnC),
//        .frame_begin(),
//        .sending_pixels(),
//        .sample_pixel(),
//        .pixel_index(pixel_index),
//        .pixel_data(pixel_data),
//        .cs(oled_cs), .sdin(oled_mosi), .sclk(oled_clk),
//        .d_cn(oled_dc), .resn(oled_res),
//        .vccen(), .pmoden()
//    );

    // Pixel coordinates
    wire [6:0] row = pixel_index / 96;
    wire [6:0] col = pixel_index % 96;

    // Circle: top-left, radius 10
    wire inside_circle = ((row-12)*(row-12) + (col-12)*(col-12)) <= (5*5);

    // === Digit geometry & placement ===
    // Digit size: HEIGHT=45, WIDTH=25, spacing = 6
    localparam integer DIG_W = 25;
    localparam integer DIG_H = 45;
    localparam integer SPACING = 6;
    localparam integer LEFT_X0 = 20;
    localparam integer RIGHT_X0 = LEFT_X0 + DIG_W + SPACING;
    localparam integer DIG_Y0 = 32 - (DIG_H/2); // center vertically

    wire four_on, six_on;

    DigitRenderer dr4(
        .row(row), .col(col), .digit(4),
        .x0(LEFT_X0[6:0]), .y0(DIG_Y0[6:0]),
        .pixel_on(four_on)
    );

    DigitRenderer dr6(
        .row(row), .col(col), .digit(6),
        .x0(RIGHT_X0[6:0]), .y0(DIG_Y0[6:0]),
        .pixel_on(six_on)
    );

    wire btnL_pulse; // ~5 ms pulse on press
    wire btnR_pulse;
    debounce dbL(.clk(clk), .pb_1(btnL), .pb_out(btnL_pulse));
    debounce dbR(.clk(clk), .pb_1(btnR), .pb_out(btnR_pulse));

    // Fast synchronizer for immediate circle response
    reg btnL_sync0 = 1'b0, btnL_sync1 = 1'b0;
    reg btnR_sync0 = 1'b0, btnR_sync1 = 1'b0;

    // toggle state registers for digits (1 = visible)
    reg show_digit4 = 1'b1;
    reg show_digit6 = 1'b1;

    // previous pulses for edge detect
    reg prev_btnL_pulse = 1'b0;
    reg prev_btnR_pulse = 1'b0;

    always @(posedge clk or posedge btnC) begin
        if (btnC) begin
            // reset
            btnL_sync0 <= 1'b0; btnL_sync1 <= 1'b0;
            btnR_sync0 <= 1'b0; btnR_sync1 <= 1'b0;
            show_digit4 <= 1'b1; show_digit6 <= 1'b1;
            prev_btnL_pulse <= 1'b0; prev_btnR_pulse <= 1'b0;
        end else begin
            // two-flop synchronizers (fast)
            btnL_sync0 <= btnL; btnL_sync1 <= btnL_sync0;
            btnR_sync0 <= btnR; btnR_sync1 <= btnR_sync0;

            // toggle on rising edge of debounce pulse
            if (btnL_pulse && !prev_btnL_pulse) show_digit4 <= ~show_digit4;
            if (btnR_pulse && !prev_btnR_pulse) show_digit6 <= ~show_digit6;

            prev_btnL_pulse <= btnL_pulse;
            prev_btnR_pulse <= btnR_pulse;
        end
    end

    // Drawing logic: circle uses fast sync for immediate magenta, digits use toggles
    always @(*) begin
        if (inside_circle) begin
            if (btnL_sync1 || btnR_sync1)
                pixel_data = 16'hF81F;  // Magenta while button held
            else
                pixel_data = 16'hFFFF;  // White otherwise
        end
        else if (four_on && show_digit4) begin
            pixel_data = 16'hF800;      // Red "4"
        end
        else if (six_on && show_digit6) begin
            pixel_data = 16'h07E0;      // Green "6"
        end
        else begin
            pixel_data = 16'h0000;      // Black background
        end
    end

endmodule




