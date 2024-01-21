module CLZ (input [15:0] i_data, output [15:0] o_data);
    wire [3:0] MSB;
    wire [7:0] x8;
    wire [3:0] x4;
    wire [1:0] x2;
    assign MSB[3] = | i_data[15:8];
    assign x8 = (MSB[3]) ? i_data[15:8] : i_data[7:0];
    assign MSB[2] = | x8[7:4];
    assign x4 = (MSB[2]) ? x8[7:4] : x8[3:0];
    assign MSB[1] = | x4[3:2];
    assign x2 = (MSB[1]) ? x4[3:2] : x4[1:0];
    assign MSB[0] = x2[1];
    assign o_data = 4'd15 - MSB;
endmodule