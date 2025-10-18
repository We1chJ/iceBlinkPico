`include "memory.sv"
`include "ws2812b.sv"
`include "controller.sv"

// led_matrix top level module

module top(
    input logic     clk, 
    input logic     SW, 
    input logic     BOOT, 
    output logic    _48b, 
    output logic    _45a
);

    logic [7:0] red_data;
    logic [7:0] green_data;
    logic [7:0] blue_data;

    logic [5:0] pixel;
    logic [5:0] address;

    // Double buffering
    logic buffer_select = 1'b0;
    logic [7:0] buffer0 [0:63];
    logic [7:0] buffer1 [0:63];

    logic [23:0] shift_reg = 24'd0;
    logic load_sreg;
    logic transmit_pixel;
    logic shift;
    logic ws2812b_out;

    logic next_frame;

    assign address = pixel;

    // Initialize both buffers
    initial begin
        $readmemh("spiral/red.txt", buffer0);
        $readmemh("spiral/red.txt", buffer1);
    end

    always_ff @(posedge clk) begin
        red_data <= buffer_select ? buffer1[address] : buffer0[address];
    end

    // Only computes the next frame on the rise edge!
    always_ff @(posedge next_frame) begin
        integer i;
        // Write next frame to the non-displayed buffer
        for (i = 0; i < 64; i++) begin
            if (buffer_select) begin
                // Currently displaying buffer1, so write to buffer0
                buffer0[i] <= buffer1[(i == 63) ? 0 : i + 1];
            end
            else begin
                // Currently displaying buffer0, so write to buffer1
                buffer1[i] <= buffer0[(i == 63) ? 0 : i + 1];
            end
        end
        // Atomic swap - flip which buffer is displayed
        buffer_select <= ~buffer_select;
    end

    ws2812b u4 (
        .clk            (clk), 
        .serial_in      (shift_reg[23]), 
        .transmit       (transmit_pixel), 
        .ws2812b_out    (ws2812b_out), 
        .shift          (shift)
    );

    controller u5 (
        .clk            (clk), 
        .load_sreg      (load_sreg), 
        .transmit_pixel (transmit_pixel), 
        .pixel          (pixel), 
        .next_frame     (next_frame)
    );

    always_ff @(posedge clk) begin
        if (load_sreg) begin
            shift_reg <= { 8'd0, red_data, 8'd0 };
        end
        else if (shift) begin
            shift_reg <= { shift_reg[22:0], 1'b0 };
        end
    end

    assign _48b = ws2812b_out;
    assign _45a = ~ws2812b_out;

endmodule