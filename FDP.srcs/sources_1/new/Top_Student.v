`timescale 1ns / 1ps
module Top_Student (
    input clk,
    input btnC_raw,
    input btnU_raw,
    input btnD_raw,
    input btnL_raw,
    input btnR_raw,
    output [15:0] led,
    output [6:0] seg,
    output [3:0] an,
    output [7:0] JB
);

    wire clk_6p25M;
    wire reset_p, up_p, down_p, left_p, right_p;

    wire [12:0] oled_pixel_index;
    wire [15:0] menu_pixel_data;
    wire [15:0] linear_pixel_data;
    wire [15:0] final_pixel_data;

    wire oled_cs, oled_sdin, oled_sclk, oled_dc, oled_resn, oled_vccen, oled_pmoden;

    wire [2:0] selected_option;
    wire linear_back_to_menu;

    localparam STATE_MENU = 2'd0;
    localparam STATE_LINEAR_SYSTEM = 2'd1;

    reg [1:0] current_state;
    reg clear_menu_selection;

    always @(posedge clk) begin
        if (reset_p) begin
            current_state <= STATE_MENU;
            clear_menu_selection <= 0;
        end else begin
            clear_menu_selection <= 0;

            case (current_state)
                STATE_MENU: begin
                    if (selected_option == 1) begin
                        current_state <= STATE_LINEAR_SYSTEM;
                        clear_menu_selection <= 1;
                    end
                end
                STATE_LINEAR_SYSTEM: begin
                    if (linear_back_to_menu) begin
                         current_state <= STATE_MENU;
                    end
                end
                default: current_state <= STATE_MENU;
            endcase
        end
    end

    assign final_pixel_data = (current_state == STATE_LINEAR_SYSTEM) ? linear_pixel_data : menu_pixel_data;

    flexible_clock clk_6p25M_gen (
        .clk(clk),
        .m(32'd7),
        .slow_clock(clk_6p25M)
    );

    debounce deb_Reset ( .clk(clk), .pb_1(btnC_raw), .pb_out(reset_p) );
    debounce deb_Up    ( .clk(clk), .pb_1(btnU_raw), .pb_out(up_p)    );
    debounce deb_Down  ( .clk(clk), .pb_1(btnD_raw), .pb_out(down_p)  );
    debounce deb_Left  ( .clk(clk), .pb_1(btnL_raw), .pb_out(left_p)  );
    debounce deb_Right ( .clk(clk), .pb_1(btnR_raw), .pb_out(right_p) );

    equation_menu menu_inst (
        .clk_6p25M(clk_6p25M),
        .reset(reset_p),
        .btn_up(up_p),
        .btn_down(down_p),
        .btn_select(right_p),
        .pixel_index(oled_pixel_index),
        .clear_selection(clear_menu_selection),
        .pixel_data(menu_pixel_data),
        .selected_option(selected_option)
    );

    linear_input linear_inst (
        .clk(clk_6p25M),
        .reset(reset_p),
        .btn_up(up_p),
        .btn_down(down_p),
        .btn_left(left_p),
        .btn_right(right_p),
        .btn_confirm(down_p),
        .pixel_index(oled_pixel_index),
        .pixel_data(linear_pixel_data),
        .back_to_menu(linear_back_to_menu)
    );

    Oled_Display oled_inst (
        .clk(clk_6p25M),
        .reset(reset_p),
        .pixel_index(oled_pixel_index),
        .pixel_data(final_pixel_data),
        .frame_begin(),
        .sending_pixels(),
        .sample_pixel(),
        .cs(oled_cs),
        .sdin(oled_sdin),
        .sclk(oled_sclk),
        .d_cn(oled_dc),
        .resn(oled_resn),
        .vccen(oled_vccen),
        .pmoden(pmoden)
    );

    assign JB[0] = oled_cs;
    assign JB[1] = oled_sdin;
    assign JB[2] = 1'b0;
    assign JB[3] = oled_sclk;
    assign JB[4] = oled_dc;
    assign JB[5] = oled_resn;
    assign JB[6] = oled_vccen;
    assign JB[7] = oled_pmoden;

    assign an = 4'b1111;
    assign seg = 7'b1111111;

    assign led[1:0] = current_state;
    assign led[4:2] = selected_option;
    assign led[5] = linear_back_to_menu;
endmodule