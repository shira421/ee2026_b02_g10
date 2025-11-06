`timescale 1ns / 1ps

module debouncer_parent(
    input clk, btnC, btnU, btnL, btnR, btnD,
    output btnCD, btnUD, btnLD, btnRD, btnDD
    );
    
    debounce d0(clk, btnC, btnCD);
    debounce d1(clk, btnU, btnUD);
    debounce d2(clk, btnL, btnLD);
    debounce d3(clk, btnR, btnRD);
    debounce d4(clk, btnD, btnDD);
endmodule
