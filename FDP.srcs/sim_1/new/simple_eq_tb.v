`timescale 1ns / 1ps

module simple_eq_tb;

    // Inputs
    reg clk;
    reg reset;
    reg [1:0] graph1_type;
    reg [1:0] graph2_type;
    reg [3:0] keypad_input;
    reg keypad_enter_pressed;
    reg keypad_backspace_pressed;
    reg keypad_digit_pressed;
    
    // Outputs
    wire all_inputs_confirmed;
    wire [1:0] current_graph_slot;
    wire [3:0] current_coeff_pos;
    wire [7:0] temp_coeff;
    wire [1:0] digit_count;
    wire [7:0] g1_poly_coeff_a, g1_poly_coeff_b, g1_poly_coeff_c;
    wire [7:0] g1_cos_coeff_a;
    wire [7:0] g1_sin_coeff_a;
    wire [7:0] g2_poly_coeff_a, g2_poly_coeff_b, g2_poly_coeff_c;
    wire [7:0] g2_cos_coeff_a;
    wire [7:0] g2_sin_coeff_a;
    
    // Instantiate the Unit Under Test (UUT)
    equation_input_module uut (
        .clk(clk),
        .reset(reset),
        .graph1_type(graph1_type),
        .graph2_type(graph2_type),
        .keypad_input(keypad_input),
        .keypad_enter_pressed(keypad_enter_pressed),
        .keypad_backspace_pressed(keypad_backspace_pressed),
        .keypad_digit_pressed(keypad_digit_pressed),
        .all_inputs_confirmed(all_inputs_confirmed),
        .current_graph_slot(current_graph_slot),
        .current_coeff_pos(current_coeff_pos),
        .temp_coeff(temp_coeff),
        .digit_count(digit_count),
        .g1_poly_coeff_a(g1_poly_coeff_a),
        .g1_poly_coeff_b(g1_poly_coeff_b),
        .g1_poly_coeff_c(g1_poly_coeff_c),
        .g1_cos_coeff_a(g1_cos_coeff_a),
        .g1_sin_coeff_a(g1_sin_coeff_a),
        .g2_poly_coeff_a(g2_poly_coeff_a),
        .g2_poly_coeff_b(g2_poly_coeff_b),
        .g2_poly_coeff_c(g2_poly_coeff_c),
        .g2_cos_coeff_a(g2_cos_coeff_a),
        .g2_sin_coeff_a(g2_sin_coeff_a)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period = 100MHz
    end
    
    // Monitor state changes and edge detection
    always @(posedge clk) begin
        if (uut.keypad_enter_edge) begin
            $display("TIME=%0t: *** ENTER EDGE DETECTED *** state=%d, temp_coeff=%d", 
                     $time, uut.state, temp_coeff);
        end
    end
    
    // Test stimulus
    initial begin
        $display("\n=== Starting Simple Equation Input Test ===\n");
        
        // Initialize Inputs
        reset = 1;
        graph1_type = 2'b10; // Sine
        graph2_type = 2'b10; // Sine
        keypad_input = 0;
        keypad_enter_pressed = 0;
        keypad_backspace_pressed = 0;
        keypad_digit_pressed = 0;
        
        // Wait for reset
        #100;
        reset = 0;
        #50;
        
        $display("After reset:");
        $display("  state = %d (expected 0=IDLE)", uut.state);
        $display("  g1_sin_coeff_a = %h (expected FF)", g1_sin_coeff_a);
        $display("");
        
        // Wait for transition from IDLE to INPUT_G1_SINE
        #20;
        $display("After IDLE:");
        $display("  state = %d (expected 5=INPUT_G1_SINE)", uut.state);
        $display("  next_state = %d", uut.next_state);
        $display("");
        
        // Type digit '2'
        $display("--- Typing '2' ---");
        #20;
        keypad_input = 4'd2;
        keypad_digit_pressed = 1;
        #10; // Hold for 1 clock
        keypad_digit_pressed = 0;
        #30;
        $display("  temp_coeff = %d (expected 2)", temp_coeff);
        $display("  digit_count = %d (expected 1)", digit_count);
        $display("  state = %d", uut.state);
        $display("");
        
        // Type digit '5'
        $display("--- Typing '5' ---");
        #20;
        keypad_input = 4'd5;
        keypad_digit_pressed = 1;
        #10; // Hold for 1 clock
        keypad_digit_pressed = 0;
        #30;
        $display("  temp_coeff = %d (expected 25)", temp_coeff);
        $display("  digit_count = %d (expected 2)", digit_count);
        $display("  state = %d (expected 5=INPUT_G1_SINE)", uut.state);
        $display("");
        
        // Press ENTER
        $display("--- Pressing ENTER ---");
        $display("  BEFORE: state=%d, temp_coeff=%d, g1_sin_coeff_a=%h", 
                 uut.state, temp_coeff, g1_sin_coeff_a);
        $display("  keypad_enter_prev = %b", uut.keypad_enter_prev);
        #20;
        keypad_enter_pressed = 1;
        $display("  Enter pressed (signal high)");
        #10; // Hold for 1 clock cycle
        $display("  AT CLOCK EDGE: state=%d, keypad_enter_edge=%b", 
                 uut.state, uut.keypad_enter_edge);
        keypad_enter_pressed = 0;
        #30;
        $display("  AFTER: state=%d, temp_coeff=%d, g1_sin_coeff_a=%d", 
                 uut.state, temp_coeff, g1_sin_coeff_a);
        $display("");
        
        // Check result
        if (g1_sin_coeff_a == 8'd25) begin
            $display("*** TEST PASSED *** g1_sin_coeff_a = 25");
        end else begin
            $display("*** TEST FAILED *** g1_sin_coeff_a = %d (expected 25)", g1_sin_coeff_a);
            $display("  Final state = %d", uut.state);
            $display("  keypad_enter_prev = %b", uut.keypad_enter_prev);
        end
        
        $display("\n=== Now testing G2 Sine ===\n");
        $display("Current state = %d (expected 10=INPUT_G2_SINE)", uut.state);
        
        // Type '8' '8' for G2
        #20;
        keypad_input = 4'd8;
        keypad_digit_pressed = 1;
        #10;
        keypad_digit_pressed = 0;
        #20;
        
        keypad_input = 4'd8;
        keypad_digit_pressed = 1;
        #10;
        keypad_digit_pressed = 0;
        #30;
        
        $display("  temp_coeff = %d (expected 88)", temp_coeff);
        $display("  state = %d", uut.state);
        
        // Press enter for G2
        #20;
        keypad_enter_pressed = 1;
        #10;
        keypad_enter_pressed = 0;
        #30;
        
        $display("  AFTER ENTER: g2_sin_coeff_a = %d (expected 88)", g2_sin_coeff_a);
        $display("  state = %d (expected 11=CONFIRMED)", uut.state);
        
        if (g2_sin_coeff_a == 8'd88) begin
            $display("*** TEST PASSED *** g2_sin_coeff_a = 88");
        end else begin
            $display("*** TEST FAILED *** g2_sin_coeff_a = %d", g2_sin_coeff_a);
        end
        
        #100;
        $display("\n=== Test Complete ===\n");
        $finish;
    end
    
    // Watchdog timer
    initial begin
        #50000;
        $display("ERROR: Simulation timeout");
        $finish;
    end

endmodule
