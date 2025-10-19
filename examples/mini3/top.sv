`include "memory.sv"
`include "ws2812b.sv"
`include "controller.sv"
`include "gol.sv"

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
    logic [2:0] neighbor_idx = 3'd0; // 8 neighbors total

    gol #(
        .INIT_FILE  ("spiral/red.txt")
    ) u1 (
        .clk        (clk),
        .address    (pixel),
        .computing  (computing),
        .compute_idx(compute_idx),
        .buffer_select(buffer_select),
        .neighbor_idx(neighbor_idx),
        .data       (red_data)
    );

    // gol #(
    //     .INIT_FILE ("spiral/green.txt")
    // ) u2 (
    //     .clk        (clk),
    //     .address    (pixel),
    //     .computing  (computing),
    //     .compute_idx(compute_idx),
    //     .buffer_select(buffer_select),
    //     .data       (green_data)
    // );

    // gol #(
    //     .INIT_FILE ("spiral/blue.txt")
    // ) u3 (
    //     .clk        (clk),
    //     .address    (pixel),
    //     .computing  (computing),
    //     .compute_idx(compute_idx),
    //     .buffer_select(buffer_select),
    //     .data       (blue_data)
    // );

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

    // Sequential computation - one cell per clock cycle
    // This will take 64 clock cycles to finish computing the next frame
    // which is enough because the IDLE cycles are long enough > 64
    always_ff @(posedge clk) begin
        next_frame_prev <= next_frame;
        // Start computing on rising edge of next_frame
        // runs only once for initializing the computing counter
        if (next_frame && !next_frame_prev && !computing) begin
            computing <= 1'b1;
            compute_idx <= 6'd0;
            neighbor_idx <= 3'd0;
        end
        else if (computing) begin
            if (neighbor_idx == 3'd7) begin
                // After processing the 8th neighbor
                if (compute_idx == 6'd63) begin
                    // Finished processing all cells
                    computing <= 1'b0;
                    neighbor_idx <= 3'd0;
                    // flip the buffer to switch the whole display
                    buffer_select <= ~buffer_select;
                end else begin
                    // Move to next cell
                    neighbor_idx <= 3'd0;
                    compute_idx <= compute_idx + 6'd1;
                end
            end else begin
                // Move to next neighbor
                neighbor_idx <= neighbor_idx + 3'd1;
            end
        end
    end

    // Load shift register with pixel data
    always_ff @(posedge clk) begin
        if (load_sreg) begin
            shift_reg <= { green_data, red_data, blue_data };
            // shift_reg <= { 8'd0, red_data, 8'd0 };
        end
        else if (shift) begin
            shift_reg <= { shift_reg[22:0], 1'b0 };
        end
    end

    assign _48b = ws2812b_out;
    assign _45a = ~ws2812b_out;

endmodule