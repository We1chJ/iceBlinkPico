module top(
	input logic clk,
	output logic RGB_R,
	output logic RGB_G,
	output logic RGB_B
);
	// CLK frequency is 12MHz, so 6,000,000 cycles is 0.5s
	parameter ONE_SEC_INTERVAL = 12000000; // 1s
    parameter COLOR_CHANGE_INTERVAL = ONE_SEC_INTERVAL / 6;
	logic [$clog2(COLOR_CHANGE_INTERVAL)-1:0] time_counter = 0;
    logic [3:0] color_counter = 0; // 3 bits enough to cover 6 colors

    always_comb begin
        case (color_counter)
            0: begin RGB_R = 1; RGB_G = 0; RGB_B = 0; end // Red
            1: begin RGB_R = 0; RGB_G = 1; RGB_B = 0; end // Green
            2: begin RGB_R = 0; RGB_G = 0; RGB_B = 1; end // Blue
            3: begin RGB_R = 1; RGB_G = 1; RGB_B = 0; end // Yellow
            4: begin RGB_R = 0; RGB_G = 1; RGB_B = 1; end // Cyan
            5: begin RGB_R = 1; RGB_G = 0; RGB_B = 1; end // Magenta
            default: begin RGB_R = 0; RGB_G = 0; RGB_B = 0; end
        endcase
    end

	always_ff @(posedge clk) begin
		if (time_counter == COLOR_CHANGE_INTERVAL - 1) begin
			time_counter <= 0;
            color_counter <= (color_counter + 1)%6;
	    end 
		else begin
			time_counter <= time_counter + 1;
		end
	end

endmodule