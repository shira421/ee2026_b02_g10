//////////////////////////////////////////////////////////////////////////////////
// Module: small_font_rom
// Description: 3x5 font ROM for smaller text (SW indicators and RESET)
//////////////////////////////////////////////////////////////////////////////////

module small_font_rom(
    input [7:0] char_code,
    output reg [14:0] font_data
);

    always @(*) begin
        case (char_code)
            // Numbers (3x5) - improved design
            "0": font_data = 15'b010_101_101_101_010;
            "1": font_data = 15'b010_110_010_010_111;
            "2": font_data = 15'b110_001_010_100_111;
            "3": font_data = 15'b110_001_010_001_110;
            
            // Letters (3x5) - improved design
            "A": font_data = 15'b010_101_111_101_101;
            "E": font_data = 15'b111_100_110_100_111;
            "G": font_data = 15'b011_100_101_101_011;
            "H": font_data = 15'b101_101_111_101_101;
            "M": font_data = 15'b101_111_111_101_101;
            "R": font_data = 15'b110_101_110_110_101;
            "S": font_data = 15'b011_100_010_001_110;
            "T": font_data = 15'b111_010_010_010_010;
            "W": font_data = 15'b101_101_111_111_101;
            
            // Space
            " ": font_data = 15'b000_000_000_000_000;
            
            default: font_data = 15'b000_000_000_000_000;
        endcase
    end

endmodule