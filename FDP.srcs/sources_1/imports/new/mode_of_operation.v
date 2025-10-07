`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/07/2025 03:29:14 PM
// Design Name: 
// Module Name: mode_of_operation
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


module mode_of_operation (
    input [1:0] mode_of_operation,
    input [16:0] num1, num2,
    output[19:0] num3);
    
    //take in the numbers and multiplex the outputs of the modules into the single output num3
    
    //wires for each of the function singal
    wire [19:0] output0, output1, output2, output3;
    
    add_function f0(num1, num2, output0);
    subtract_function f1(num1, num2, output1);
    divide_function f2(num1, num2, output2);
    multiply_function f3(num1, num2, output3);
    
     
endmodule