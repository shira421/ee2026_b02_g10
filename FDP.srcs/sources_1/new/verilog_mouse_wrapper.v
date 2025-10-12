

/*
 * Module: MouseCtl_Verilog_Wrapper
 * Description: Wrapper for the external VHDL module MouseCtl.vhd to 
 * simplify instantiation in the Verilog top module.
 */
module MouseCtl_Verilog_Wrapper(
    input clk,
    input rst,
    output [11:0] xpos,
    output [11:0] ypos,
    output [3:0] zpos,
    output left, middle, right,
    output new_event,
    
    // PS/2 bus signals (connected to I/O)
    inout ps2_clk,
    inout ps2_data
);

    // Placeholder inputs for VHDL component generics/configuration
    // Setting max X/Y limits (OLED is 96x64, max X=95, max Y=63). 
    // Using simple defaults or large values here, relying on paint.v to scale.
    wire [11:0] value_in = 12'd95; 
    wire setx_in = 1'b0;
    wire sety_in = 1'b0;
    wire setmax_x_in = 1'b0;
    wire setmax_y_in = 1'b0;
    
    // Instantiate the VHDL component directly (Assumes MouseCtl.vhd is available)
    MouseCtl i_mouse_ctl (
        .clk(clk),
        .rst(rst),
        .xpos(xpos),
        .ypos(ypos),
        .zpos(zpos),
        .left(left),
        .middle(middle),
        .right(right),
        .new_event(new_event),
        .value(value_in),
        .setx(setx_in),
        .sety(sety_in),
        .setmax_x(setmax_x_in),
        .setmax_y(setmax_y_in),
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data)
    );

endmodule