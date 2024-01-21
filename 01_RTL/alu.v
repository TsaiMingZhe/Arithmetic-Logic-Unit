//`include "./FP_add.v"
//`include "./FX_add_sub.v"
//`include "./Signed_mult.v"
//`include "./GELU.v"
//`include "./CLZ.v"
module alu #(
    parameter INT_W  = 6,
    parameter FRAC_W = 10,
    parameter INST_W = 4,
    parameter DATA_W = INT_W + FRAC_W
    )(
    input                     i_clk,
    input                     i_rst_n,
    input signed [DATA_W-1:0] i_data_a,
    input signed [DATA_W-1:0] i_data_b,
    input        [INST_W-1:0] i_inst,
    output                    o_valid,
    output                    o_busy,
    output       [DATA_W-1:0] o_data
    );
////////////////////////parameter
    parameter fx_add    = 4'h0;
    parameter fx_sub    = 4'h1;
    parameter mult      = 4'h2;
    parameter mac       = 4'h3;
    parameter gelu      = 4'h4;
    parameter clz       = 4'h5;
    parameter lrcw      = 4'h6;
    parameter lfsr      = 4'h7;
    parameter fp_add    = 4'h8;
    parameter fp_sub    = 4'h9;
    parameter idle      = 3'h0;
    parameter getdata   = 3'h1;
    parameter compute1  = 3'h2;
    parameter compute2  = 3'h3;
    parameter check     = 3'h4;
///////////////////////reg & wire
    wire    [DATA_W-1:0]    o_fx_add, o_fp_add, o_fx_sub, o_fp_sub;
    wire    [DATA_W-1:0]    o_mult, o_mac, mac_over, o_gelu, o_lrcw, o_clz, o_lfsr;
    wire                    finish_flag;
    wire    [3:0]           cpop;
    wire    [2:0]           s_mac;
    reg     [DATA_W-1:0]    o_data_w, o_data_r;
    reg                     o_valid_w, o_valid_r, o_busy_w, o_busy_r;
    reg     [2:0]           state, next_state ;
    reg     [DATA_W-1:0]    mac_r, lrcw_r, lfsr_r;
    reg     [3:0]           count, count_r;
    assign o_data = o_data_r;
    assign o_busy = o_busy_r;
    assign o_valid = o_valid_r;
    assign finish_flag = ~(| count_r);
    assign o_mac = o_mult + mac_r;
    assign s_mac = {o_mult[15], mac_r[15], o_mac[15]};
    assign mac_over = (s_mac == 3'b110) ? 16'h8000 :
                      (s_mac == 3'b001) ? 16'h7fff : o_mac;
    assign cpop = (i_data_a[0] + i_data_a[1]) + (i_data_a[2] + i_data_a[3])
                + (i_data_a[4] + i_data_a[5]) + (i_data_a[6] + i_data_a[7])
                + (i_data_a[8] + i_data_a[9]) + (i_data_a[10] + i_data_a[11])
                + (i_data_a[12] + i_data_a[13]) + (i_data_a[14] + i_data_a[15]);
    assign o_lrcw = {lrcw_r[14:0], ~lrcw_r[15]} ;
    assign o_lfsr = {lfsr_r[14:0], (lfsr_r[15] ^ lfsr_r[13] ^ lfsr_r[12] ^ lfsr_r[10])};
    FX_add_sub add_sub(.data_1(i_data_a), .data_2(i_data_b), .o_add(o_fx_add), .o_sub(o_fx_sub));
    FP_add add1(.data_1(i_data_a), .data_2(i_data_b), .o_data(o_fp_add));
    FP_add sub1(.data_1(i_data_a), .data_2({~i_data_b[15], i_data_b[14:0]}), .o_data(o_fp_sub));
    Signed_mult m1(.data_1(i_data_a), .data_2(i_data_b), .o_data(o_mult));
    GELU g(.i_data(i_data_a), .o_data(o_gelu));
    CLZ c(.i_data(i_data_a), .o_data(o_clz));
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            o_data_r <= 0;
            o_busy_r <= 1;
            o_valid_r <= 0;
            state <= idle;
            mac_r <= 0;
            count_r <= 0;
            lrcw_r <= 0;
            lfsr_r <= 0;
        end else begin
            o_data_r <= o_data_w;
            o_busy_r <= o_busy_w;
            o_valid_r <= o_valid_w;
            state <= next_state;
            mac_r <= (o_valid) ? o_data : mac_r;
            count_r <= count;
            lrcw_r <= (state == compute1) ? i_data_b : 
                      (state == compute2) ? o_lrcw : lrcw_r;
            lfsr_r <= (state == compute1) ? i_data_a :
                      (state == compute2) ? o_lfsr : lfsr_r;
        end
    end
    always @(*) begin
        if(state == compute1)begin
            case (i_inst)
                fx_add  : o_data_w = o_fx_add;
                fx_sub  : o_data_w = o_fx_sub;
                mult    : o_data_w = o_mult;
                mac     : o_data_w = mac_over;
                gelu    : o_data_w = o_gelu;
                clz     : o_data_w = o_clz;
                fp_add  : o_data_w = o_fp_add;
                fp_sub  : o_data_w = o_fp_sub;
                default : o_data_w = o_data_r; //lrcw && lfsr
            endcase
        end else if(state == compute2)begin
            case (i_inst)
                lrcw    : o_data_w = (finish_flag) ? lrcw_r : o_data_r;
                lfsr    : o_data_w = (finish_flag) ? lfsr_r : o_data_r;
                default: o_data_w = o_data_r;
            endcase
        end else o_data_w = o_data_r;
    end 
    always @(*) begin
        case (state)
            idle : begin
                count = 1'b0;
                o_busy_w = 1'b0;
                o_valid_w = 1'b0;
                next_state = getdata;
            end
            getdata : begin
                count = 1'b0;
                o_busy_w = 1'b1;
                o_valid_w = 1'b0;
                next_state = compute1;
            end
            compute1 : begin
                count = (i_inst == lrcw) ? cpop : 
                        (i_inst == lfsr) ? i_data_b[3:0] : 1'b0;
                o_busy_w = 1'b1;
                o_valid_w = (& i_inst[2:1]) ? 1'b0 : 1'b1;
                next_state = (& i_inst[2:1]) ? compute2 : check;
            end
            compute2 : begin
                count = (finish_flag) ? count_r : count_r - 1'b1;
                o_busy_w = 1'b1;
                o_valid_w = (finish_flag) ? 1'b1 : 1'b0;
                next_state = (finish_flag) ? check : compute2;
            end
            check : begin
                count = 1'b0;
                o_busy_w = 1'b1;
                o_valid_w = 1'b0;
                next_state = idle;
            end
            default: begin
                count = 1'b0;
                o_busy_w = o_busy_r;
                o_valid_w = o_valid_r;
                next_state = state;                
            end
        endcase
    end
endmodule