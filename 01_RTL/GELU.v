module GELU (input signed [15:0] i_data, output [15:0] o_data);
    wire signed [31:0] x_2, x_0797;
    wire signed [47:0] x2_0044;
    wire signed [79:0] tanh_x;
    wire signed [16:0] tanh;
    wire signed [32:0] gelu_x;
    wire signed [15:0] gelu_round, tanh_round, x_round;
    wire        G[1:0], R[1:0], S[1:0], GRS[1:0];
    assign x_2 = i_data * i_data;
    assign x_0797 = i_data * $signed(16'h0331);                  //12Q20 
    assign x2_0044 = 48'h40000000 + x_2 * 16'h002e;             //18Q30
    assign tanh_x = x_0797 * x2_0044;
    assign tanh = (x_round > $signed(16'h0600)) ? 17'h00800 :                                // x >= 1.5
                  (x_round < $signed(16'hfa00)) ? 17'h1f800 :                                // x <= -1.5
                  (x_round > $signed(16'h0200)) ? {x_round[15], x_round} + 17'h00200 :            // x >= 0.5 (0.5x + 0.25)
                  (x_round < $signed(16'hfe00)) ? {x_round[15], x_round} + 17'h1fe00 : {x_round, 1'b0};   // x <= -0.5 else = x
    assign gelu_x = $signed({i_data[15], i_data}) * $signed(16'h0400 + tanh_round);    //6Q11 * 6Q10
    assign {G[0], R[0], S[0]} = {tanh_x[40:39], | tanh_x[38:0]};
    assign {G[1], R[1], S[1]} = {gelu_x[11:10], | gelu_x[9:0]};
    assign GRS[0] = (R[0] & S[0]) | (G[0] & R[0]);
    assign GRS[1] = (R[1] & S[1]) | (G[1] & R[1]);
    assign x_round = tanh_x[55:40] + GRS[0];
    assign tanh_round = tanh[16:1] + tanh[0];
    assign gelu_round = gelu_x[26:11] + GRS[1];
    assign o_data = gelu_round;
endmodule