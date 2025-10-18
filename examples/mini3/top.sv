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

    // Requires 2 buffers to avoid modifying the matrix being displayed directly
    logic buffer_select = 1'b0;
    logic [7:0] buffer0 [0:63];
    logic [7:0] buffer1 [0:63];

    logic [23:0] shift_reg = 24'd0;
    logic load_sreg;
    logic transmit_pixel;
    logic shift;
    logic ws2812b_out;

    logic next_frame;
    logic next_frame_prev = 1'b0;
    
    // State machine for sequential processing
    logic computing = 1'b0;
    logic [5:0] compute_idx = 6'd0;
    
    assign address = pixel;

    // Initialize both buffers for cur frame and next frame
    initial begin
        $readmemh("spiral/red.txt", buffer0);
        $readmemh("spiral/red.txt", buffer1);
    end

    always_ff @(posedge clk) begin
        red_data <= buffer_select ? buffer1[address] : buffer0[address];
    end
    
    // Sequential computation - one cell per clock cycle
    always_ff @(posedge clk) begin
        next_frame_prev <= next_frame;
        
        // Start computing on rising edge of next_frame
        if (next_frame && !next_frame_prev && !computing) begin
            computing <= 1'b1;
            compute_idx <= 6'd0;
        end
        // Continue computing
        else if (computing) begin
            integer i, j, cnt;
            i = compute_idx / 8;
            j = compute_idx % 8;
            cnt = 0;
            
            if (buffer_select) begin
                // Read from buffer1, write to buffer0
                // Cardinal neighbors
                if (buffer1[i*8 + ((j+1) % 8)] != 8'd0) cnt = cnt + 1;
                if (buffer1[i*8 + ((j+7) % 8)] != 8'd0) cnt = cnt + 1;
                if (buffer1[((i+1) % 8) * 8 + j] != 8'd0) cnt = cnt + 1;
                if (buffer1[((i+7) % 8) * 8 + j] != 8'd0) cnt = cnt + 1;
                // Diagonal neighbors
                if (buffer1[((i+7) % 8) * 8 + ((j+7) % 8)] != 8'd0) cnt = cnt + 1;
                if (buffer1[((i+7) % 8) * 8 + ((j+1) % 8)] != 8'd0) cnt = cnt + 1;
                if (buffer1[((i+1) % 8) * 8 + ((j+7) % 8)] != 8'd0) cnt = cnt + 1;
                if (buffer1[((i+1) % 8) * 8 + ((j+1) % 8)] != 8'd0) cnt = cnt + 1;

                if (cnt <= 1 || cnt >= 4)
                    buffer0[compute_idx] <= 8'd0;
                else if (cnt == 2)
                    buffer0[compute_idx] <= buffer1[compute_idx];
                else // cnt == 3
                    buffer0[compute_idx] <= 8'd255;
            end
            else begin
                // Read from buffer0, write to buffer1
                // Cardinal neighbors
                if (buffer0[i*8 + ((j+1) % 8)] != 8'd0) cnt = cnt + 1;
                if (buffer0[i*8 + ((j+7) % 8)] != 8'd0) cnt = cnt + 1;
                if (buffer0[((i+1) % 8) * 8 + j] != 8'd0) cnt = cnt + 1;
                if (buffer0[((i+7) % 8) * 8 + j] != 8'd0) cnt = cnt + 1;
                // Diagonal neighbors
                if (buffer0[((i+7) % 8) * 8 + ((j+7) % 8)] != 8'd0) cnt = cnt + 1;
                if (buffer0[((i+7) % 8) * 8 + ((j+1) % 8)] != 8'd0) cnt = cnt + 1;
                if (buffer0[((i+1) % 8) * 8 + ((j+7) % 8)] != 8'd0) cnt = cnt + 1;
                if (buffer0[((i+1) % 8) * 8 + ((j+1) % 8)] != 8'd0) cnt = cnt + 1;

                if (cnt <= 1 || cnt >= 4)
                    buffer1[compute_idx] <= 8'd0;
                else if (cnt == 2)
                    buffer1[compute_idx] <= buffer0[compute_idx];
                else // cnt == 3
                    buffer1[compute_idx] <= 8'd255;
            end
            
            // Move to next cell or finish
            if (compute_idx == 6'd63) begin
                computing <= 1'b0;
                buffer_select <= ~buffer_select;
            end
            else begin
                compute_idx <= compute_idx + 6'd1;
            end
        end
    end

    // Instance the WS2812B output driver
    ws2812b u4 (
        .clk            (clk), 
        .serial_in      (shift_reg[23]), 
        .transmit       (transmit_pixel), 
        .ws2812b_out    (ws2812b_out), 
        .shift          (shift)
    );

    // Instance the controller
    controller u5 (
        .clk            (clk), 
        .load_sreg      (load_sreg), 
        .transmit_pixel (transmit_pixel), 
        .pixel          (pixel), 
        .next_frame     (next_frame)
    );

    // Load shift register with pixel data
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