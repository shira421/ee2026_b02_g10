`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/21/2025 11:18:12 PM
// Design Name: 
// Module Name: project_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module project_top(
    input clk, btnC, btnL, btnR, btnU, btnD, 
    input [15:0] sw,
    
    output reg [15:0] led,
    output reg [3:0] an,
    output reg [7:0] seg,
    output [7:0] JB, JA
    );
    
    //clock functions
    wire freq625m;
    freq_625m c0(clk, freq625m);
    
    //debouncer function
    wire btnCD, btnUD, btnLD, btnRD, btnDD;
    debouncer_parent b0(
        clk, btnC, btnU, btnL, btnR, btnD,
        btnCD, btnUD, btnLD, btnRD, btnDD
    );
    
    //paramters
    parameter S0_home = 2'b00, S1_basic = 2'b01, S2_graph = 2'b10, S3_game = 2'b11;
    reg [1:0] state, next_state;
    
    //gate the following buttons and switches 
    //basic modules gated buttons
    wire btnCD_basic, btnUD_basic, btnLD_basic, btnRD_basic, btnDD_basic;
    //graphing module gated buttons
    wire btnCD_graph, btnUD_graph, btnLD_graph, btnRD_graph, btnDD_graph;
    wire reset_switch_graph, negative_switch_graph;
    //game module gated buttons
    wire btnCD_game, btnUD_game, btnLD_game, btnRD_game, btnDD_game;
    
    // Gate buttons for basic calculator module
    assign btnCD_basic = (state == S1_basic) ? btnCD : 1'b0;
    assign btnUD_basic = (state == S1_basic) ? btnUD : 1'b0;
    assign btnLD_basic = (state == S1_basic) ? btnLD : 1'b0;
    assign btnRD_basic = (state == S1_basic) ? btnRD : 1'b0;
    assign btnDD_basic = (state == S1_basic) ? btnDD : 1'b0;
    
    // Gate buttons for graphing module
    assign btnCD_graph = (state == S2_graph) ? btnCD : 1'b0;
    assign btnUD_graph = (state == S2_graph) ? btnUD : 1'b0;
    assign btnLD_graph = (state == S2_graph) ? btnLD : 1'b0;
    assign btnRD_graph = (state == S2_graph) ? btnRD : 1'b0;
    assign btnDD_graph = (state == S2_graph) ? btnDD : 1'b0;
    
    // Gate switches for graphing module
    assign reset_switch_graph = (state == S2_graph) ? sw[15] : 1'b0;
    assign negative_switch_graph = (state == S2_graph) ? sw[10] : 1'b0;
    
    // Gate buttons for game module
    assign btnCD_game = (state == S3_game) ? btnCD : 1'b0;
    assign btnUD_game = (state == S3_game) ? btnUD : 1'b0;
    assign btnLD_game = (state == S3_game) ? btnLD : 1'b0;
    assign btnRD_game = (state == S3_game) ? btnRD : 1'b0;
    assign btnDD_game = (state == S3_game) ? btnDD : 1'b0;
    
    //instantiate the three main modules
    wire [15:0] screen_2_home;
    home_screen f0(
        pixel_index_2,
        screen_2_home
        );
    
    wire [15:0] screen_1_graph, screen_2_graph; //these are later multiplexed below
    graphing_calculator_top f1(
        clk,
        reset_switch_graph,
        btnCD_graph, btnLD_graph, btnRD_graph, btnUD_graph, btnDD_graph,
        negative_switch_graph,
        pixel_index_1, pixel_index_2,
        screen_1_graph, screen_2_graph);
    
    wire [6:0] seg_game;
    wire [3:0] an_game;
    wire [15:0] led_game;
    wire [15:0] screen_2_game;
    maths_game f2(
            clk, freq625m, //inputs
            btnCD_game, btnUD_game, btnDD_game, btnLD_game, btnRD_game, //inputs
            seg_game, an_game, led_game, //outputs
            // OLED interface signals
            pixel_index_2, //input
            screen_2_game //output
        );
        
    //graphical modules
    reg [15:0] screen_1_data, screen_2_data;
    wire [12:0] pixel_index_1, pixel_index_2;
    wire frame_begin_1, sending_pixels_1, sample_pixel_1;
    wire frame_begin_2, sending_pixels_2, sample_pixel_2;
    
    oled_display g0(
        .clk(freq625m), 
        .reset(1'b0), 
        .frame_begin(frame_begin_1), 
        .sending_pixels(sending_pixels_1), 
        .sample_pixel(sample_pixel_1),
        .pixel_index(pixel_index_2), 
        .pixel_data(screen_2_data),
        .cs(JB[0]), 
        .sdin(JB[1]), 
        .sclk(JB[3]), 
        .d_cn(JB[4]), 
        .resn(JB[5]), 
        .vccen(JB[6]), 
        .pmoden(JB[7])
    );
    
    oled_display g1(
        .clk(freq625m), 
        .reset(1'b0), 
        .frame_begin(frame_begin_2), 
        .sending_pixels(sending_pixels_2), 
        .sample_pixel(sample_pixel_2),
        .pixel_index(pixel_index_1), 
        .pixel_data(screen_1_data),
        .cs(JA[0]), 
        .sdin(JA[1]), 
        .sclk(JA[3]), 
        .d_cn(JA[4]), 
        .resn(JA[5]), 
        .vccen(JA[6]), 
        .pmoden(JA[7])
    );
    
    //FSM for the modules to multiplex
    initial begin
        state = S0_home;
    end
    
    //sw0 for basic, sw1 for graph, sw2 for the game
    always@(*) begin
        case(sw[3:1])
            3'b000 : next_state = S0_home;
            3'b001 : next_state = S1_basic;
            3'b010 : next_state = S2_graph;
            3'b100 : next_state = S3_game;
            default : next_state = S0_home;
        endcase
    end
    
    always@(*) begin
        case(state)
            S0_home : begin screen_2_data = screen_2_home; an = 4'b1111; seg = 8'b11111111; end
            S1_basic : begin an = 4'b1111; seg = 8'b11111111; end //insert the output of the graphical module here
            S2_graph : begin screen_1_data = screen_1_graph; screen_2_data = screen_2_graph; an = 4'b1111; seg = 8'b11111111; end
            S3_game : begin seg = {1'b1, seg_game}; an = an_game; led = led_game; screen_1_data = 16'b0000000000000000; screen_2_data = screen_2_game; end
        endcase
    end
    
    always@(posedge clk) begin
        state <= next_state;
    end
    
endmodule
