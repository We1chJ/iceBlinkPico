`include "pwm.sv"

module top(
	input logic clk,
	output logic RGB_R,
	output logic RGB_G,
	output logic RGB_B
);
	// CLK frequency is 12MHz, so 6,000,000 cycles is 0.5s
	parameter ONE_SEC_INTERVAL = 12000000; // 1s
	parameter PWM_INTERVAL = 1200;       // CLK frequency is 12MHz, so 1,200 cycles is 100us
	logic [$clog2(ONE_SEC_INTERVAL)-1:0] time_counter = 0;
	
	logic pwm_out_r;
	logic pwm_out_g;
	logic pwm_out_b;
	
	logic [31:0] pwm_value_r = PWM_INTERVAL;
	logic [31:0] pwm_value_g = 0;
	logic [31:0] pwm_value_b = 0;

	// Red PWM instance
	pwm #(
		.PWM_INTERVAL (PWM_INTERVAL)
	) u1 (
		.clk (clk),
		.pwm_value (pwm_value_r),
		.pwm_out (pwm_out_r)
	);

	// Green PWM instance
	pwm #(
		.PWM_INTERVAL (PWM_INTERVAL)
	) u2 (
		.clk (clk),
		.pwm_value (pwm_value_g),
		.pwm_out (pwm_out_g)
	);

	// Blue PWM instance
	pwm #(
		.PWM_INTERVAL (PWM_INTERVAL)
	) u3 (
		.clk (clk),
		.pwm_value (pwm_value_b),
		.pwm_out (pwm_out_b)
	);


	logic [31:0] hue;    // 32 bits enough for (360 * ONE_SEC_INTERVAL)
	logic [7:0] R, G, B;

	// combinational part: compute hue -> x -> R,G,B
	always_comb begin
		hue = (360 * time_counter) / ONE_SEC_INTERVAL;
        
        // HSV to RGB conversion with fixed Saturation=100%, Value=100%
        if (hue < 60) begin
            // Red to Yellow transition (0-60°)
            R = 8'd255;
            G = (hue * 255) / 60;
            B = 8'd0;
        end else if (hue < 120) begin
            // Yellow to Green transition (60-120°)
            R = ((120 - hue) * 255) / 60;
            G = 8'd255;
            B = 8'd0;
        end else if (hue < 180) begin
            // Green to Cyan transition (120-180°)
            R = 8'd0;
            G = 8'd255;
            B = ((hue - 120) * 255) / 60;
        end else if (hue < 240) begin
            // Cyan to Blue transition (180-240°)
            R = 8'd0;
            G = ((240 - hue) * 255) / 60;
            B = 8'd255;
        end else if (hue < 300) begin
            // Blue to Magenta transition (240-300°)
            R = ((hue - 240) * 255) / 60;
            G = 8'd0;
            B = 8'd255;
        end else begin
            // Magenta to Red transition (300-360°)
            R = 8'd255;
            G = 8'd0;
            B = ((360 - hue) * 255) / 60;
        end

		pwm_value_r = (R * PWM_INTERVAL) / 255;
		pwm_value_g = (G * PWM_INTERVAL) / 255;
		pwm_value_b = (B * PWM_INTERVAL) / 255;
	end

	// sequential part: update time counter and output PWM
	always_ff @(posedge clk) begin
		if (time_counter == ONE_SEC_INTERVAL - 1) begin
			time_counter <= 0;
	    end 
		else begin
			time_counter <= time_counter + 1;
		end
	end

	
	assign RGB_R = ~pwm_out_r;
	assign RGB_G = ~pwm_out_g;
	assign RGB_B = ~pwm_out_b;

endmodule