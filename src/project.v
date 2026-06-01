`default_nettype none

module tt_um_1bit_cnn (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // Serial pixel input
    wire pixel_in;
    wire data_valid;

    assign pixel_in  = ui_in[0];
    assign data_valid = ui_in[1];

    // Programmable threshold
    wire [2:0] threshold;
    assign threshold = ui_in[4:2];

    // 3x3 sliding window
    reg [2:0] row0;
    reg [2:0] row1;
    reg [2:0] row2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            row0 <= 3'b000;
            row1 <= 3'b000;
            row2 <= 3'b000;
        end
        else if (ena && data_valid) begin
            row0 <= {row0[1:0], pixel_in};
            row1 <= {row1[1:0], row0[2]};
            row2 <= {row2[1:0], row1[2]};
        end
    end

    // Fixed XNOR kernel
    wire m0,m1,m2,m3,m4,m5,m6,m7,m8;

    assign m0 = ~(row0[0] ^ 1'b0);
    assign m1 = ~(row0[1] ^ 1'b1);
    assign m2 = ~(row0[2] ^ 1'b0);

    assign m3 = ~(row1[0] ^ 1'b1);
    assign m4 = ~(row1[1] ^ 1'b1);
    assign m5 = ~(row1[2] ^ 1'b1);

    assign m6 = ~(row2[0] ^ 1'b0);
    assign m7 = ~(row2[1] ^ 1'b1);
    assign m8 = ~(row2[2] ^ 1'b0);

    // Match accumulation
    wire [3:0] match_sum;

    assign match_sum =
        m0 + m1 + m2 +
        m3 + m4 + m5 +
        m6 + m7 + m8;

    // CNN output register
    reg conv_output;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            conv_output <= 1'b0;
        else if (ena) begin
            if (match_sum >= threshold)
                conv_output <= 1'b1;
            else
                conv_output <= 1'b0;
        end
    end

    // Outputs
    assign uo_out[0] = conv_output;
    assign uo_out[1] = (match_sum >= threshold);
    assign uo_out[7:2] = 6'b000000;

    assign uio_out = 8'b00000000;
    assign uio_oe  = 8'b00000000;

endmodule

`default_nettype wire
