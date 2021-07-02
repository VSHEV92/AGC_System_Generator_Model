module agc(
    input  clk, ce, reset,
    input  enable,                      // '1' - включение регулировки усиления
    input  signed [11:0] data_in_i,     // синфазная часть входного сигнала sfix_12_9
    input  signed [11:0] data_in_q,     // квадратурная часть входного сигнала sfix_12_9 
    output signed [11:0] data_out_i,    // синфазная часть выходного сигнала sfix_12_9
    output signed [11:0] data_out_q,    // квадратурная часть выходного сигнала sfix_12_9 
    output reg [11:0] agc_gain          // коэффициент усиления АРУ ufix_12_10
);
    
    localparam [8:0] loop_gain = 9'h02;      // петлевой коэффициент усиления ufix_9_9
    localparam [11:0] ref_level = 12'h2D4;   // референсный уровень сигнала ufix_12_9

    reg [11:0] signal_level;                          // уровень сигнала ufix_12_9
    reg signed [21:0] data_gained_i, data_gained_q;   // сигнал после усиления sfix_22_19
    
    // вычисление уровня сигнала
    always @(posedge clk)
        if (reset)
            signal_level <= 12'h000;
        else
            signal_level <= (data_out_i[11] ? -data_out_i : data_out_i) + (data_out_q[11] ? -data_out_q : data_out_q); 
    
    // коэффициент усиления АРУ
    always @(posedge clk)
        if (reset | !enable)
            agc_gain <= 12'h400;  // при сбосе и выключеном режиме коэффициент усиления равен едининице
        else
            if (ref_level > signal_level)
                agc_gain <= agc_gain + loop_gain;
            else
                agc_gain <= agc_gain - loop_gain;
    
    // усиление входного сигнала
    always @(posedge clk) begin
        data_gained_i <= data_in_i * $signed({1'b0, agc_gain});
        data_gained_q <= data_in_q * $signed({1'b0, agc_gain}); 
    end

    // формирование выходных сигналов
    assign data_out_i = data_gained_i[21:10],
           data_out_q = data_gained_q[21:10];
    
endmodule