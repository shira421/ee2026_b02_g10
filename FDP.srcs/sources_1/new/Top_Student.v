
module Top_Student (input clk, input btnU,btnL,btnR,btnD, output [7:0] JB);
            
wire clk_6_25mhz, clk_25mhz , clk_move;
parameter m_6_25mhz = 7; 
parameter m_25mhz = 1; 
wire [15:0] oled_data; 
wire frame_begin, sending_pixels, sample_pixel; 
wire [12:0] pixel_index; 

wire signed [7:0] circle_x, circle_y;

//function calls


// --- Debounced button signals ---
wire btnU_clean, btnD_clean, btnL_clean, btnR_clean;

// Debounce each pushbutton
debounce dbU (.clk(clk), .pb_1(btnU), .pb_out(btnU_clean));
debounce dbD (.clk(clk), .pb_1(btnD), .pb_out(btnD_clean));
debounce dbL (.clk(clk), .pb_1(btnL), .pb_out(btnL_clean));
debounce dbR (.clk(clk), .pb_1(btnR), .pb_out(btnR_clean));

wire btnU_sync, btnD_sync, btnL_sync, btnR_sync;

sync_2ff syncU (.clk(clk_6_25mhz), .async_in(btnU_clean), .sync_out(btnU_sync));
sync_2ff syncD (.clk(clk_6_25mhz), .async_in(btnD_clean), .sync_out(btnD_sync));
sync_2ff syncL (.clk(clk_6_25mhz), .async_in(btnL_clean), .sync_out(btnL_sync));
sync_2ff syncR (.clk(clk_6_25mhz), .async_in(btnR_clean), .sync_out(btnR_sync));

flexible_clock clock_6_25_mhz(.clk(clk), .m(m_6_25mhz), .slow_clock(clk_6_25mhz));
flexible_clock clock_25mhz(.clk(clk), .m(m_25mhz), .slow_clock(clk_25mhz));
flexible_clock clock_move (.clk(clk), .m(32'd1249999), .slow_clock(clk_move)); //40 pixels per second, so 1/40seconds for one pixel

Oled_Display test1 (.clk(clk_25mhz),.reset(1'b0), .frame_begin(frame_begin), .sending_pixels(sending_pixels),
.sample_pixel(sample_pixel), .pixel_index(pixel_index), .pixel_data(oled_data), .cs(JB[0]), .sdin(JB[1]),
    .sclk(JB[3]), .d_cn(JB[4]), .resn(JB[5]), .vccen(JB[6]), .pmoden(JB[7]));
    
    wire [6:0] x = pixel_index % 96;
    wire [5:0] y = pixel_index / 96;
//hihihih
 CircleMover move(.clk(clk_6_25mhz), .move_tick(clk_move),
    .btnU(btnU_sync), .btnD(btnD_sync), .btnL(btnL_sync), .btnR(btnR_sync),
    .circle_x(circle_x), .circle_y(circle_y));

draw_shapes draw(.clk_6_25mhz(clk_6_25mhz), .circle_x(circle_x), .circle_y(circle_y), .x(x), .y(y), .pixel_index(pixel_index), .oled_data(oled_data));
endmodule


