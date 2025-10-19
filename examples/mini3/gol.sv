module gol#(
    parameter INIT_FILE = ""
)(
    input logic clk, 
    input logic [5:0] address,
    input logic computing,
    input logic [5:0] compute_idx,
    input logic buffer_select,
    output logic [7:0] data
);

    // Requires 2 buffers to avoid modifying the matrix being displayed directly
    logic [7:0] buffer0 [0:63];
    logic [7:0] buffer1 [0:63];

    // Initialize both buffers for cur frame and next frame
    initial if(INIT_FILE) begin
        $readmemh(INIT_FILE, buffer0);
        $readmemh(INIT_FILE, buffer1);
    end

    always_ff @(posedge clk) begin
        if (computing) begin
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
                if (buffer0[i*8 + ((j+1) % 8)] != 8'd0) cnt = cnt + 1;
                if (buffer0[i*8 + ((j+7) % 8)] != 8'd0) cnt = cnt + 1;
                if (buffer0[((i+1) % 8) * 8 + j] != 8'd0) cnt = cnt + 1;
                if (buffer0[((i+7) % 8) * 8 + j] != 8'd0) cnt = cnt + 1;
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
        end
    end

    // always output the data 
    always_ff @(posedge clk) begin
        data <= buffer_select ? buffer1[address] : buffer0[address];
    end
endmodule