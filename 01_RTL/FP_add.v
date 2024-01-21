module FP_add (input [15:0] data_1, input [15:0] data_2, output [15:0] o_data);
    wire a_s, b_s, o_s;    //{a_s, a_e, a_f} & {b_s, b_e, b_f}
    wire [4:0] a_e, b_e, o_e;
    wire [9:0] a_f, b_f, o_f;
    wire [22:0] ex_af, ex_bf, ex_af_2s, ex_bf_2s, exbf_shift;
    wire [22:0] ex_add, ex_add_2s, add_shift;
    wire [4:0] expon_shift, normal_shift, f1;
    wire G, R, S, GRS;
    assign {a_s, a_e, a_f} = (data_1[14:10] > data_2[14:10]) ? data_1 : data_2;
    assign {b_s, b_e, b_f} = (data_1[14:10] > data_2[14:10]) ? data_2 : data_1;
    assign expon_shift = a_e - b_e;
    //{sign, carry, hidden, a_f, 10bit} 1+1+1+10+10 bits
    assign ex_af = {3'b001, a_f, 10'b0};
    assign ex_bf = {3'b001, b_f, 10'b0};
    assign exbf_shift = ex_bf >> expon_shift;
    assign ex_af_2s = (a_s) ? ~ex_af + 1'b1 : ex_af;
    assign ex_bf_2s = (b_s) ? ~exbf_shift + 1'b1 : exbf_shift;
    assign ex_add = ex_af_2s + ex_bf_2s;
    assign ex_add_2s = (ex_add[22]) ? ~ex_add + 1'b1 : ex_add;
    MSB m1 (.i_data(ex_add_2s), .o_data(f1));//get MSB

    assign normal_shift = (ex_add_2s[21]) ? 1'b0 : 5'd20 - f1;
    assign add_shift = ex_add_2s << normal_shift;
    assign G = (ex_add_2s[21]) ? add_shift[11] : add_shift[10];
    assign R = (ex_add_2s[21]) ? add_shift[10] : add_shift[9];
    assign S = (ex_add_2s[21]) ? |add_shift[9:0] : |add_shift[8:0];
    assign GRS = (R & S) | (G & R);
    assign o_s = ex_add[22];
    assign o_e = a_e + ex_add_2s[21] - normal_shift;
    assign o_f = (ex_add_2s[21]) ? add_shift[20:11] + GRS : add_shift[19:10] + GRS;
    assign o_data = {o_s, o_e, o_f};
endmodule
module MSB (
    input [22:0] i_data,
    output [4:0] o_data
    );
    wire [15:0] x16;
    wire [7:0] x8;
    wire [3:0] x4;
    wire [1:0] x2;
    assign o_data[4] = | i_data[22:16];
    assign x16 = (o_data[4]) ? {11'b0, i_data[20:16]} : i_data[15:0];
    assign o_data[3] = | x16[15:8];
    assign x8 = (o_data[3]) ? x16[15:8] : x16[7:0];
    assign o_data[2] = | x8[7:4];
    assign x4 = (o_data[2]) ? x8[7:4] : x8[3:0];
    assign o_data[1] = | x4[3:2];
    assign x2 = (o_data[1]) ? x4[3:2] : x4[1:0];
    assign o_data[0] = x2[1];  
endmodule