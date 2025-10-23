`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: sin_q14_lut_64
// Description: Quarter-wave sine lookup table (Q1.14 format).
// Index 0..63 covers 0..?/2.
//////////////////////////////////////////////////////////////////////////////////
module sin_q14_lut_64(
    input  wire [5:0] idx,
    output reg  signed [15:0] val_q14
);
    always @* begin
        case (idx)
        6'd0:  val_q14 = 16'sd0;
        6'd1:  val_q14 = 16'sd408;
        6'd2:  val_q14 = 16'sd817;
        6'd3:  val_q14 = 16'sd1224;
        6'd4:  val_q14 = 16'sd1631;
        6'd5:  val_q14 = 16'sd2037;
        6'd6:  val_q14 = 16'sd2442;
        6'd7:  val_q14 = 16'sd2845;
        6'd8:  val_q14 = 16'sd3246;
        6'd9:  val_q14 = 16'sd3646;
        6'd10: val_q14 = 16'sd4043;
        6'd11: val_q14 = 16'sd4437;
        6'd12: val_q14 = 16'sd4829;
        6'd13: val_q14 = 16'sd5218;
        6'd14: val_q14 = 16'sd5604;
        6'd15: val_q14 = 16'sd5986;
        6'd16: val_q14 = 16'sd6365;
        6'd17: val_q14 = 16'sd6740;
        6'd18: val_q14 = 16'sd7111;
        6'd19: val_q14 = 16'sd7477;
        6'd20: val_q14 = 16'sd7839;
        6'd21: val_q14 = 16'sd8196;
        6'd22: val_q14 = 16'sd8548;
        6'd23: val_q14 = 16'sd8895;
        6'd24: val_q14 = 16'sd9237;
        6'd25: val_q14 = 16'sd9572;
        6'd26: val_q14 = 16'sd9902;
        6'd27: val_q14 = 16'sd10225;
        6'd28: val_q14 = 16'sd10542;
        6'd29: val_q14 = 16'sd10852;
        6'd30: val_q14 = 16'sd11156;
        6'd31: val_q14 = 16'sd11452;
        6'd32: val_q14 = 16'sd11741;
        6'd33: val_q14 = 16'sd12022;
        6'd34: val_q14 = 16'sd12296;
        6'd35: val_q14 = 16'sd12561;
        6'd36: val_q14 = 16'sd12818;
        6'd37: val_q14 = 16'sd13066;
        6'd38: val_q14 = 16'sd13306;
        6'd39: val_q14 = 16'sd13536;
        6'd40: val_q14 = 16'sd13757;
        6'd41: val_q14 = 16'sd13969;
        6'd42: val_q14 = 16'sd14171;
        6'd43: val_q14 = 16'sd14363;
        6'd44: val_q14 = 16'sd14546;
        6'd45: val_q14 = 16'sd14718;
        6'd46: val_q14 = 16'sd14880;
        6'd47: val_q14 = 16'sd15032;
        6'd48: val_q14 = 16'sd15173;
        6'd49: val_q14 = 16'sd15304;
        6'd50: val_q14 = 16'sd15424;
        6'd51: val_q14 = 16'sd15534;
        6'd52: val_q14 = 16'sd15633;
        6'd53: val_q14 = 16'sd15721;
        6'd54: val_q14 = 16'sd15798;
        6'd55: val_q14 = 16'sd15864;
        6'd56: val_q14 = 16'sd15919;
        6'd57: val_q14 = 16'sd15963;
        6'd58: val_q14 = 16'sd15996;
        6'd59: val_q14 = 16'sd16017;
        6'd60: val_q14 = 16'sd16028;
        6'd61: val_q14 = 16'sd16027;
        6'd62: val_q14 = 16'sd16015;
        6'd63: val_q14 = 16'sd15992;
        endcase
    end
endmodule
