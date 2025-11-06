//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Company: 
//// Engineer: 
//// 
//// Create Date: 10/21/2025 11:18:12 PM
//// Design Name: 
//// Module Name: project_top
//// Project Name: 
//// Target Devices: 
//// Tool Versions: 
//// Description: Modified to include dual OLED calculator in S1_basic state
////              Uses dual_oled_calculator_pixel for resource optimization
////              Shares parent's OLED displays instead of instantiating separate ones
//// 
//// Dependencies: 
//// 
//// Revision:
//// Revision 0.01 - File Created
//// Additional Comments:
//// 
////////////////////////////////////////////////////////////////////////////////////

//module project_top(
//    input clk, btnC, btnL, btnR, btnU, btnD, 
//    input [15:0] sw,
    
//    output reg [15:0] led,
//    output reg [3:0] an,
//    output reg [7:0] seg,
//    output [7:0] JB, JA
//    );
    
//    //clock functions
//    wire freq625m, freq_200hz;
//    freq_625m c0(clk, freq625m);
//    freq_divider #(200, 20) c1(clk, freq_200hz);
    
//    //debouncer function
//    wire btnCD, btnUD, btnLD, btnRD, btnDD;
//    debouncer_parent b0(
//        clk, btnC, btnU, btnL, btnR, btnD,
//        btnCD, btnUD, btnLD, btnRD, btnDD
//    );
    
//    //paramters
//    parameter S0_home = 2'b00, S1_basic = 2'b01, S2_graph = 2'b10, S3_game = 2'b11;
//    reg [1:0] state, next_state;
    
//    //gate the following buttons and switches 
//    //basic modules gated buttons
//    wire btnCD_basic, btnUD_basic, btnLD_basic, btnRD_basic, btnDD_basic;
//    //graphing module gated buttons
//    wire btnCD_graph, btnUD_graph, btnLD_graph, btnRD_graph, btnDD_graph;
//    wire reset_switch_graph, negative_switch_graph;
//    //game module gated buttons
//    wire btnCD_game, btnUD_game, btnLD_game, btnRD_game, btnDD_game;
    
//    // Gate buttons for basic calculator module
//    assign btnCD_basic = (state == S1_basic) ? btnCD : 1'b0;
//    assign btnUD_basic = (state == S1_basic) ? btnUD : 1'b0;
//    assign btnLD_basic = (state == S1_basic) ? btnLD : 1'b0;
//    assign btnRD_basic = (state == S1_basic) ? btnRD : 1'b0;
//    assign btnDD_basic = (state == S1_basic) ? btnDD : 1'b0;
    
//    // Gate buttons for graphing module
//    assign btnCD_graph = (state == S2_graph) ? btnCD : 1'b0;
//    assign btnUD_graph = (state == S2_graph) ? btnUD : 1'b0;
//    assign btnLD_graph = (state == S2_graph) ? btnLD : 1'b0;
//    assign btnRD_graph = (state == S2_graph) ? btnRD : 1'b0;
//    assign btnDD_graph = (state == S2_graph) ? btnDD : 1'b0;
    
//    // Gate switches for graphing module
//    assign reset_switch_graph = (state == S2_graph) ? sw[0] : 1'b0;
//    assign negative_switch_graph = (state == S2_graph) ? sw[10] : 1'b0;
    
//    // Gate buttons for game module
//    assign btnCD_game = (state == S3_game) ? btnCD : 1'b0;
//    assign btnUD_game = (state == S3_game) ? btnUD : 1'b0;
//    assign btnLD_game = (state == S3_game) ? btnLD : 1'b0;
//    assign btnRD_game = (state == S3_game) ? btnRD : 1'b0;
//    assign btnDD_game = (state == S3_game) ? btnDD : 1'b0;
    
//    //instantiate the home screen module
//    wire [15:0] screen_2_home;
//    home_screen f0(
//        pixel_index_2,
//        screen_2_home
//        );
//    //instantiate the startup anode and segment functions needed
//    //the counter and the clk
//    wire [1:0] ctr_out;
//    counter #(4, 2) ctr0(freq_200hz, 0, ctr_out);
    
//    wire [3:0] an_home;
//    wire [7:0] seg_home;
//    ti_85_anode ti_85_anode_inst(
//        ctr_out,
//        an_home,
//        seg_home    
//        );
    
//    //instantiate the dual OLED calculator module (basic calculator)
//    // Using pre-debounced signals from debouncer_parent
//    // Outputs pixel data to share parent's OLED displays (resource saving)
//    wire [15:0] screen_1_basic, screen_2_basic;
//    dual_oled_calculator_pixel f_calc(
//        .clk(clk),
//        .slow_clk(freq625m),
//        .btnC(btnCD_basic),
//        .btnU(btnUD_basic),
//        .btnD(btnDD_basic),
//        .btnL(btnLD_basic),
//        .btnR(btnRD_basic),
//        .pixel_index_a(pixel_index_1),  // Connect to g1's pixel_index
//        .pixel_index_b(pixel_index_2),  // Connect to g0's pixel_index
//        .pixel_data_a(screen_1_basic),  // Output screen (flipped)
//        .pixel_data_b(screen_2_basic)   // Input screen (normal)
//    );
    
//    //instantiate the graphing calculator module
//    wire [15:0] screen_1_graph, screen_2_graph;
//    graphing_calculator_top f1(
//        clk,
//        reset_switch_graph,
//        btnCD_graph, btnLD_graph, btnRD_graph, btnUD_graph, btnDD_graph,
//        negative_switch_graph,
//        pixel_index_1, pixel_index_2,
//        screen_1_graph, screen_2_graph);
    
//    //instantiate the maths game module
//    wire [6:0] seg_game;
//    wire [3:0] an_game;
//    wire [15:0] led_game;
//    wire [15:0] screen_2_game;
//    maths_game f2(
//            clk, freq625m,
//            btnCD_game, btnUD_game, btnDD_game, btnLD_game, btnRD_game,
//            seg_game, an_game, led_game,
//            pixel_index_2,
//            screen_2_game
//        );
        
//    //graphical modules
//    reg [15:0] screen_1_data, screen_2_data;
//    wire [12:0] pixel_index_1, pixel_index_2;
//    wire frame_begin_1, sending_pixels_1, sample_pixel_1;
//    wire frame_begin_2, sending_pixels_2, sample_pixel_2;
    
//    // OLED driver signals (used for all modes)
//    wire cs_g0, sdin_g0, sclk_g0, d_cn_g0, resn_g0, vccen_g0, pmoden_g0;
//    wire cs_g1, sdin_g1, sclk_g1, d_cn_g1, resn_g1, vccen_g1, pmoden_g1;
    
//    // OLED Display 0 - JB (pixel_index_2, screen_2_data)
//    // Normal orientation for calculator input screen
//    oled_display #(
//        .FLIP_SCREEN(0)
//    ) g0(
//        .clk(freq625m), 
//        .reset(1'b0), 
//        .frame_begin(frame_begin_1), 
//        .sending_pixels(sending_pixels_1), 
//        .sample_pixel(sample_pixel_1),
//        .pixel_index(pixel_index_2), 
//        .pixel_data(screen_2_data),
//        .cs(cs_g0), 
//        .sdin(sdin_g0), 
//        .sclk(sclk_g0), 
//        .d_cn(d_cn_g0), 
//        .resn(resn_g0), 
//        .vccen(vccen_g0), 
//        .pmoden(pmoden_g0)
//    );
    
//    // OLED Display 1 - JA (pixel_index_1, screen_1_data)
//    // Flipped 180° for calculator output screen
//    oled_display #(
//        .FLIP_SCREEN(1)
//    ) g1(
//        .clk(freq625m), 
//        .reset(1'b0), 
//        .frame_begin(frame_begin_2), 
//        .sending_pixels(sending_pixels_2), 
//        .sample_pixel(sample_pixel_2),
//        .pixel_index(pixel_index_1), 
//        .pixel_data(screen_1_data),
//        .cs(cs_g1), 
//        .sdin(sdin_g1), 
//        .sclk(sclk_g1), 
//        .d_cn(d_cn_g1), 
//        .resn(resn_g1), 
//        .vccen(vccen_g1), 
//        .pmoden(pmoden_g1)
//    );
    
//    //FSM for the modules to multiplex
//    initial begin
//        state = S0_home;
//    end
    
//    //sw[3:1] for mode selection: 000=home, 001=basic calc, 010=graph, 100=game
//    always@(*) begin
//        case(sw[3:1])
//            3'b000 : next_state = S0_home;
//            3'b001 : next_state = S1_basic;
//            3'b010 : next_state = S2_graph;
//            3'b100 : next_state = S3_game;
//            default : next_state = S0_home;
//        endcase
//    end
    
//    // Multiplex outputs based on state
//    always@(*) begin
//        case(state)
//            S0_home : begin 
//                screen_2_data = screen_2_home; 
//                screen_1_data = 16'b0;
//                an = an_home; 
//                seg = seg_home;
//                led = 16'b0;
//            end
            
//            S1_basic : begin 
//                // Calculator shares the OLED displays
//                screen_1_data = screen_1_basic;  // Output screen (flipped)
//                screen_2_data = screen_2_basic;  // Input screen (normal)
//                an = 4'b1111; 
//                seg = 8'b11111111;
//                led = 16'b0;
//            end
            
//            S2_graph : begin 
//                screen_1_data = screen_1_graph; 
//                screen_2_data = screen_2_graph; 
//                an = 4'b1111; 
//                seg = 8'b11111111;
//                led = 16'b0;
//            end
            
//            S3_game : begin 
//                seg = {1'b1, seg_game}; 
//                an = an_game; 
//                led = led_game; 
//                screen_1_data = 16'b0000000000000000; 
//                screen_2_data = screen_2_game;
//            end
            
//            default : begin
//                screen_2_data = screen_2_home; 
//                screen_1_data = 16'b0;
//                an = 4'b1111; 
//                seg = 8'b11111111;
//                led = 16'b0;
//            end
//        endcase
//    end
    
//    // JA and JB outputs (same for all states now - using shared OLED drivers)
//    assign JA = {pmoden_g1, vccen_g1, resn_g1, d_cn_g1, sclk_g1, 1'b0, sdin_g1, cs_g1};
//    assign JB = {pmoden_g0, vccen_g0, resn_g0, d_cn_g0, sclk_g0, 1'b0, sdin_g0, cs_g0};
    
//    always@(posedge clk) begin
//        state <= next_state;
//    end
    
//endmodule

//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// MODIFIED: Game module commented out to save LUTs for graphing calculator
////////////////////////////////////////////////////////////////////////////////////

//module project_top(
//    input clk, btnC, btnL, btnR, btnU, btnD, 
//    input [15:0] sw,
    
//    output reg [15:0] led,
//    output reg [3:0] an,
//    output reg [7:0] seg,
//    output [7:0] JB, JA
//    );
    
//    //clock functions
//    wire freq625m, freq_200hz;
//    freq_625m c0(clk, freq625m);
//    freq_divider #(200, 20) c1(clk, freq_200hz);
    
//    //debouncer function
//    wire btnCD, btnUD, btnLD, btnRD, btnDD;
//    debouncer_parent b0(
//        clk, btnC, btnU, btnL, btnR, btnD,
//        btnCD, btnUD, btnLD, btnRD, btnDD
//    );
    
//    //parameters - GAME DISABLED, using only 2 states
//    parameter S0_home = 2'b00, S1_basic = 2'b01, S2_graph = 2'b10; //, S3_game = 2'b11;
//    reg [1:0] state, next_state;
    
//    //gate the following buttons and switches 
//    //basic modules gated buttons
//    wire btnCD_basic, btnUD_basic, btnLD_basic, btnRD_basic, btnDD_basic;
//    //graphing module gated buttons
//    wire btnCD_graph, btnUD_graph, btnLD_graph, btnRD_graph, btnDD_graph;
//    wire reset_switch_graph, negative_switch_graph;
//    //game module gated buttons - COMMENTED OUT
//    //wire btnCD_game, btnUD_game, btnLD_game, btnRD_game, btnDD_game;
    
//    // Gate buttons for basic calculator module
//    assign btnCD_basic = (state == S1_basic) ? btnCD : 1'b0;
//    assign btnUD_basic = (state == S1_basic) ? btnUD : 1'b0;
//    assign btnLD_basic = (state == S1_basic) ? btnLD : 1'b0;
//    assign btnRD_basic = (state == S1_basic) ? btnRD : 1'b0;
//    assign btnDD_basic = (state == S1_basic) ? btnDD : 1'b0;
    
//    // Gate buttons for graphing module
//    assign btnCD_graph = (state == S2_graph) ? btnCD : 1'b0;
//    assign btnUD_graph = (state == S2_graph) ? btnUD : 1'b0;
//    assign btnLD_graph = (state == S2_graph) ? btnLD : 1'b0;
//    assign btnRD_graph = (state == S2_graph) ? btnRD : 1'b0;
//    assign btnDD_graph = (state == S2_graph) ? btnDD : 1'b0;
    
//    // Gate switches for graphing module
//    assign reset_switch_graph = (state == S2_graph) ? sw[0] : 1'b0;
//    assign negative_switch_graph = (state == S2_graph) ? sw[10] : 1'b0;
    
//    // Gate buttons for game module - COMMENTED OUT
//    //assign btnCD_game = (state == S3_game) ? btnCD : 1'b0;
//    //assign btnUD_game = (state == S3_game) ? btnUD : 1'b0;
//    //assign btnLD_game = (state == S3_game) ? btnLD : 1'b0;
//    //assign btnRD_game = (state == S3_game) ? btnRD : 1'b0;
//    //assign btnDD_game = (state == S3_game) ? btnDD : 1'b0;
    
//    //instantiate the home screen module
//    wire [15:0] screen_2_home;
//    home_screen f0(
//        pixel_index_2,
//        screen_2_home
//        );
//    //instantiate the startup anode and segment functions needed
//    //the counter and the clk
//    wire [1:0] ctr_out;
//    counter #(4, 2) ctr0(freq_200hz, 0, ctr_out);
    
//    wire [3:0] an_home;
//    wire [7:0] seg_home;
//    ti_85_anode ti_85_anode_inst(
//        ctr_out,
//        an_home,
//        seg_home    
//        );
    
//    //instantiate the dual OLED calculator module (basic calculator)
//    wire [15:0] screen_1_basic, screen_2_basic;
//    dual_oled_calculator_pixel f_calc(
//        .clk(clk),
//        .slow_clk(freq625m),
//        .btnC(btnCD_basic),
//        .btnU(btnUD_basic),
//        .btnD(btnDD_basic),
//        .btnL(btnLD_basic),
//        .btnR(btnRD_basic),
//        .pixel_index_a(pixel_index_1),
//        .pixel_index_b(pixel_index_2),
//        .pixel_data_a(screen_1_basic),
//        .pixel_data_b(screen_2_basic)
//    );
    
//    //instantiate the graphing calculator module
//    wire [15:0] screen_1_graph, screen_2_graph;
//    graphing_calculator_top f1(
//        clk,
//        reset_switch_graph,
//        btnCD_graph, btnLD_graph, btnRD_graph, btnUD_graph, btnDD_graph,
//        negative_switch_graph,
//        pixel_index_1, pixel_index_2,
//        screen_1_graph, screen_2_graph);
    
//    //GAME MODULE COMMENTED OUT TO SAVE LUTS
//    //wire [6:0] seg_game;
//    //wire [3:0] an_game;
//    //wire [15:0] led_game;
//    //wire [15:0] screen_2_game;
//    //maths_game f2(
//    //        clk, freq625m,
//    //        btnCD_game, btnUD_game, btnDD_game, btnLD_game, btnRD_game,
//    //        seg_game, an_game, led_game,
//    //        pixel_index_2,
//    //        screen_2_game
//    //    );
        
//    //graphical modules
//    reg [15:0] screen_1_data, screen_2_data;
//    wire [12:0] pixel_index_1, pixel_index_2;
//    wire frame_begin_1, sending_pixels_1, sample_pixel_1;
//    wire frame_begin_2, sending_pixels_2, sample_pixel_2;
    
//    // OLED driver signals (used for all modes)
//    wire cs_g0, sdin_g0, sclk_g0, d_cn_g0, resn_g0, vccen_g0, pmoden_g0;
//    wire cs_g1, sdin_g1, sclk_g1, d_cn_g1, resn_g1, vccen_g1, pmoden_g1;
    
//    // OLED Display 0 - JB (pixel_index_2, screen_2_data)
//    oled_display #(
//        .FLIP_SCREEN(0)
//    ) g0(
//        .clk(freq625m), 
//        .reset(1'b0), 
//        .frame_begin(frame_begin_1), 
//        .sending_pixels(sending_pixels_1), 
//        .sample_pixel(sample_pixel_1),
//        .pixel_index(pixel_index_2), 
//        .pixel_data(screen_2_data),
//        .cs(cs_g0), 
//        .sdin(sdin_g0), 
//        .sclk(sclk_g0), 
//        .d_cn(d_cn_g0), 
//        .resn(resn_g0), 
//        .vccen(vccen_g0), 
//        .pmoden(pmoden_g0)
//    );
    
//    // OLED Display 1 - JA (pixel_index_1, screen_1_data)
//    oled_display #(
//        .FLIP_SCREEN(1)
//    ) g1(
//        .clk(freq625m), 
//        .reset(1'b0), 
//        .frame_begin(frame_begin_2), 
//        .sending_pixels(sending_pixels_2), 
//        .sample_pixel(sample_pixel_2),
//        .pixel_index(pixel_index_1), 
//        .pixel_data(screen_1_data),
//        .cs(cs_g1), 
//        .sdin(sdin_g1), 
//        .sclk(sclk_g1), 
//        .d_cn(d_cn_g1), 
//        .resn(resn_g1), 
//        .vccen(vccen_g1), 
//        .pmoden(pmoden_g1)
//    );
    
//    //FSM for the modules to multiplex
//    initial begin
//        state = S0_home;
//    end
    
//    //sw[3:1] for mode selection: 000=home, 001=basic calc, 010=graph (GAME DISABLED)
//    always@(*) begin
//        case(sw[3:1])
//            3'b000 : next_state = S0_home;
//            3'b001 : next_state = S1_basic;
//            3'b010 : next_state = S2_graph;
//            //3'b100 : next_state = S3_game;  // COMMENTED OUT
//            default : next_state = S0_home;
//        endcase
//    end
    
//    // Multiplex outputs based on state
//    always@(*) begin
//        case(state)
//            S0_home : begin 
//                screen_2_data = screen_2_home; 
//                screen_1_data = 16'b0;
//                an = an_home; 
//                seg = seg_home;
//                led = 16'b0;
//            end
            
//            S1_basic : begin 
//                screen_1_data = screen_1_basic;
//                screen_2_data = screen_2_basic;
//                an = 4'b1111; 
//                seg = 8'b11111111;
//                led = 16'b0;
//            end
            
//            S2_graph : begin 
//                screen_1_data = screen_1_graph; 
//                screen_2_data = screen_2_graph; 
//                an = 4'b1111; 
//                seg = 8'b11111111;
//                led = 16'b0;
//            end
            
//            // GAME STATE COMMENTED OUT
//            //S3_game : begin 
//            //    seg = {1'b1, seg_game}; 
//            //    an = an_game; 
//            //    led = led_game; 
//            //    screen_1_data = 16'b0000000000000000; 
//            //    screen_2_data = screen_2_game;
//            //end
            
//            default : begin
//                screen_2_data = screen_2_home; 
//                screen_1_data = 16'b0;
//                an = 4'b1111; 
//                seg = 8'b11111111;
//                led = 16'b0;
//            end
//        endcase
//    end
    
//    // JA and JB outputs (same for all states now - using shared OLED drivers)
//    assign JA = {pmoden_g1, vccen_g1, resn_g1, d_cn_g1, sclk_g1, 1'b0, sdin_g1, cs_g1};
//    assign JB = {pmoden_g0, vccen_g0, resn_g0, d_cn_g0, sclk_g0, 1'b0, sdin_g0, cs_g0};
    
//    always@(posedge clk) begin
//        state <= next_state;
//    end
    
//endmodule


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// RESTORED: Game module re-enabled
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
    wire freq625m, freq_200hz;
    freq_625m c0(clk, freq625m);
    freq_divider #(200, 20) c1(clk, freq_200hz);
    
    //debouncer function
    wire btnCD, btnUD, btnLD, btnRD, btnDD;
    debouncer_parent b0(
        clk, btnC, btnU, btnL, btnR, btnD,
        btnCD, btnUD, btnLD, btnRD, btnDD
    );
    
    //parameters - ALL STATES ENABLED
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
    assign reset_switch_graph = (state == S2_graph) ? sw[0] : 1'b0;
    assign negative_switch_graph = (state == S2_graph) ? sw[10] : 1'b0;
    
    // Gate buttons for game module
    assign btnCD_game = (state == S3_game) ? btnCD : 1'b0;
    assign btnUD_game = (state == S3_game) ? btnUD : 1'b0;
    assign btnLD_game = (state == S3_game) ? btnLD : 1'b0;
    assign btnRD_game = (state == S3_game) ? btnRD : 1'b0;
    assign btnDD_game = (state == S3_game) ? btnDD : 1'b0;
    
    //instantiate the home screen module
    wire [15:0] screen_2_home;
    home_screen f0(
        pixel_index_2,
        screen_2_home
        );
    //instantiate the startup anode and segment functions needed
    //the counter and the clk
    wire [1:0] ctr_out;
    counter #(4, 2) ctr0(freq_200hz, 0, ctr_out);
    
    wire [3:0] an_home;
    wire [7:0] seg_home;
    ti_85_anode ti_85_anode_inst(
        ctr_out,
        an_home,
        seg_home    
        );
    
    //instantiate the dual OLED calculator module (basic calculator)
    wire [15:0] screen_1_basic, screen_2_basic;
    dual_oled_calculator_pixel f_calc(
        .clk(clk),
        .slow_clk(freq625m),
        .btnC(btnCD_basic),
        .btnU(btnUD_basic),
        .btnD(btnDD_basic),
        .btnL(btnLD_basic),
        .btnR(btnRD_basic),
        .pixel_index_a(pixel_index_1),
        .pixel_index_b(pixel_index_2),
        .pixel_data_a(screen_1_basic),
        .pixel_data_b(screen_2_basic)
    );
    
    //instantiate the graphing calculator module
    wire [15:0] screen_1_graph, screen_2_graph;
    graphing_calculator_top f1(
        clk,
        reset_switch_graph,
        btnCD_graph, btnLD_graph, btnRD_graph, btnUD_graph, btnDD_graph,
        negative_switch_graph,
        pixel_index_1, pixel_index_2,
        screen_1_graph, screen_2_graph);
    
    //instantiate the maths game module
    wire [6:0] seg_game;
    wire [3:0] an_game;
    wire [15:0] led_game;
    wire [15:0] screen_2_game;
    maths_game f2(
            clk, freq625m,
            btnCD_game, btnUD_game, btnDD_game, btnLD_game, btnRD_game,
            seg_game, an_game, led_game,
            pixel_index_2,
            screen_2_game
        );
        
    //graphical modules
    reg [15:0] screen_1_data, screen_2_data;
    wire [12:0] pixel_index_1, pixel_index_2;
    wire frame_begin_1, sending_pixels_1, sample_pixel_1;
    wire frame_begin_2, sending_pixels_2, sample_pixel_2;
    
    // OLED driver signals (used for all modes)
    wire cs_g0, sdin_g0, sclk_g0, d_cn_g0, resn_g0, vccen_g0, pmoden_g0;
    wire cs_g1, sdin_g1, sclk_g1, d_cn_g1, resn_g1, vccen_g1, pmoden_g1;
    
    // OLED Display 0 - JB (pixel_index_2, screen_2_data)
    oled_display #(
        .FLIP_SCREEN(0)
    ) g0(
        .clk(freq625m), 
        .reset(1'b0), 
        .frame_begin(frame_begin_1), 
        .sending_pixels(sending_pixels_1), 
        .sample_pixel(sample_pixel_1),
        .pixel_index(pixel_index_2), 
        .pixel_data(screen_2_data),
        .cs(cs_g0), 
        .sdin(sdin_g0), 
        .sclk(sclk_g0), 
        .d_cn(d_cn_g0), 
        .resn(resn_g0), 
        .vccen(vccen_g0), 
        .pmoden(pmoden_g0)
    );
    
    // OLED Display 1 - JA (pixel_index_1, screen_1_data)
    oled_display #(
        .FLIP_SCREEN(1)
    ) g1(
        .clk(freq625m), 
        .reset(1'b0), 
        .frame_begin(frame_begin_2), 
        .sending_pixels(sending_pixels_2), 
        .sample_pixel(sample_pixel_2),
        .pixel_index(pixel_index_1), 
        .pixel_data(screen_1_data),
        .cs(cs_g1), 
        .sdin(sdin_g1), 
        .sclk(sclk_g1), 
        .d_cn(d_cn_g1), 
        .resn(resn_g1), 
        .vccen(vccen_g1), 
        .pmoden(pmoden_g1)
    );
    
    //FSM for the modules to multiplex
    initial begin
        state = S0_home;
    end
    
    //sw[3:1] for mode selection: 000=home, 001=basic calc, 010=graph, 100=game
    always@(*) begin
        case(sw[3:1])
            3'b000 : next_state = S0_home;
            3'b001 : next_state = S1_basic;
            3'b010 : next_state = S2_graph;
            3'b100 : next_state = S3_game;
            default : next_state = S0_home;
        endcase
    end
    
    // Multiplex outputs based on state
    always@(*) begin
        case(state)
            S0_home : begin 
                screen_2_data = screen_2_home; 
                screen_1_data = 16'b0;
                an = an_home; 
                seg = seg_home;
                led = 16'b0;
            end
            
            S1_basic : begin 
                screen_1_data = screen_1_basic;
                screen_2_data = screen_2_basic;
                an = 4'b1111; 
                seg = 8'b11111111;
                led = 16'b0;
            end
            
            S2_graph : begin 
                screen_1_data = screen_1_graph; 
                screen_2_data = screen_2_graph; 
                an = 4'b1111; 
                seg = 8'b11111111;
                led = 16'b0;
            end
            
            S3_game : begin 
                seg = {1'b1, seg_game}; 
                an = an_game; 
                led = led_game; 
                screen_1_data = 16'b0000000000000000; 
                screen_2_data = screen_2_game;
            end
            
            default : begin
                screen_2_data = screen_2_home; 
                screen_1_data = 16'b0;
                an = 4'b1111; 
                seg = 8'b11111111;
                led = 16'b0;
            end
        endcase
    end
    
    // JA and JB outputs (same for all states now - using shared OLED drivers)
    assign JA = {pmoden_g1, vccen_g1, resn_g1, d_cn_g1, sclk_g1, 1'b0, sdin_g1, cs_g1};
    assign JB = {pmoden_g0, vccen_g0, resn_g0, d_cn_g0, sclk_g0, 1'b0, sdin_g0, cs_g0};
    
    always@(posedge clk) begin
        state <= next_state;
    end
    
endmodule