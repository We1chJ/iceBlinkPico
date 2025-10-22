module gol#(
    parameter INIT_FILE = ""
)(
    input logic clk, 
    input logic [5:0] address,
    input logic computing,
    input logic [5:0] compute_idx,
    input logic buffer_select,
    input logic [2:0] neighbor_idx,
    output logic [7:0] data
);

    // Single-bit cells instead of 8-bit
    logic buffer0 [0:63];
    logic buffer1 [0:63];

    // Initialize both buffers for cur frame and next frame
    initial if(INIT_FILE) begin
        $readmemh(INIT_FILE, buffer0);
        $readmemh(INIT_FILE, buffer1);
    end

    // Accumulator for alive neighbors
    logic [3:0] cnt = 4'd0;
    logic current_cell;

    // storing row and col index
    logic [2:0] i;
    logic [2:0] j;
    // final count of neighbors
    logic [2:0] final_count;

    // index to check for neighbor
    logic [5:0] check_idx;
    // flag to see if the cell being checked is 1 or 0
    logic is_alive;

    // counting all neighbors in one cycle would exceed FPGA resources
    // therefore we will the neighbor in each clock cycle
    // overall for one color, this would take 64 * 8 clock cycles
    always_ff @(posedge clk) begin
        if (computing) begin
            i = compute_idx[5:3];
            j = compute_idx[2:0];
            
            // Determine which neighbor to check
            unique case (neighbor_idx)
                3'd0: check_idx = i*8 + ((j+1) % 8);                    // right
                3'd1: check_idx = i*8 + ((j+7) % 8);                    // left
                3'd2: check_idx = ((i+1) % 8) * 8 + j;                  // down
                3'd3: check_idx = ((i+7) % 8) * 8 + j;                  // up
                3'd4: check_idx = ((i+7) % 8) * 8 + ((j+7) % 8);       // up-left
                3'd5: check_idx = ((i+7) % 8) * 8 + ((j+1) % 8);       // up-right
                3'd6: check_idx = ((i+1) % 8) * 8 + ((j+7) % 8);       // down-left
                3'd7: check_idx = ((i+1) % 8) * 8 + ((j+1) % 8);       // down-right
            endcase
            
            if (buffer_select) begin
                // Read from buffer1, write to buffer0
                is_alive = buffer1[check_idx];
                
                if (neighbor_idx == 3'd0) begin
                    // First neighbor - reset count and save current cell
                    cnt <= is_alive ? 4'd1 : 4'd0;
                    current_cell <= buffer1[compute_idx];
                end
                else if (neighbor_idx == 3'd7) begin
                    // Last neighbor - add to count first, THEN apply rules
                    final_count = cnt + (is_alive ? 4'd1 : 4'd0);
                    
                    if (final_count <= 4'd1 || final_count >= 4'd4)
                        buffer0[compute_idx] <= 1'b0;
                    else if (final_count == 4'd2)
                        buffer0[compute_idx] <= current_cell;
                    else // final_count == 3
                        buffer0[compute_idx] <= 1'b1;
                end
                else begin
                    // Middle neighbors - accumulate
                    cnt <= cnt + (is_alive ? 4'd1 : 4'd0);
                end
            end
            else begin
                // Read from buffer0, write to buffer1
                is_alive = buffer0[check_idx];
                
                if (neighbor_idx == 3'd0) begin
                    cnt <= is_alive ? 4'd1 : 4'd0;
                    current_cell <= buffer0[compute_idx];
                end
                else if (neighbor_idx == 3'd7) begin
                    final_count = cnt + (is_alive ? 4'd1 : 4'd0);
                    
                    if (final_count <= 4'd1 || final_count >= 4'd4)
                        buffer1[compute_idx] <= 1'b0;
                    else if (final_count == 4'd2)
                        buffer1[compute_idx] <= current_cell;
                    else // final_count == 3
                        buffer1[compute_idx] <= 1'b1;
                end
                else begin
                    cnt <= cnt + (is_alive ? 4'd1 : 4'd0);
                end
            end
        end
    end

    // always output the data (convert 1-bit to 8-bit for display)
    always_ff @(posedge clk) begin
        data <= (buffer_select ? buffer1[address] : buffer0[address]) ? 8'd255 : 8'd0;
    end
endmodule