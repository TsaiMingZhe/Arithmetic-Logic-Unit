module Signed_mult (input signed [15:0] data_1, input signed [15:0] data_2, output [15:0] o_data);
    wire signed [31:0] mult;
    wire G, R, S, GRS;
    wire [21:0] mult_round;
    assign mult = data_1 * data_2;
    assign {G, R, S} = {mult[10:9], | mult[8:0]};
    assign GRS = (R & S) | (G & R); 
    assign mult_round = mult[31:10] + GRS;
    assign o_data = (mult_round[21:15] == 7'h7f) ? mult_round[15:0] :
                    (mult_round[21:15] == 7'h00) ? mult_round[15:0] : 
                    {mult_round[21], {15{~mult_round[21]}}};
endmodule