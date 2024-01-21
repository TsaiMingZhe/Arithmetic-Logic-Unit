module FX_add_sub (input [15:0] data_1, input [15:0] data_2, output [15:0] o_add, output [15:0] o_sub);
    wire [15:0] add, sub, data_2_2s;
    wire [2:0]  s_add, s_sub;
    assign data_2_2s = ~data_2 + 1'b1;
    assign add = data_1 + data_2;
    assign sub = data_1 + data_2_2s;
    assign s_add = {data_1[15], data_2[15], add[15]};
    assign s_sub = {data_1[15], data_2_2s[15], sub[15]};
    assign o_add = (s_add == 3'b110) ? 16'h8000 : (s_add == 3'b001) ? 16'h7fff : add;
    assign o_sub = (s_sub == 3'b110) ? 16'h8000 : (s_sub == 3'b001) ? 16'h7fff : sub;
endmodule