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
	
	logic [$clog2(PWM_INTERVAL) - 1:0] pwm_value_r = PWM_INTERVAL;
	logic [$clog2(PWM_INTERVAL) - 1:0] pwm_value_g = 0;
	logic [$clog2(PWM_INTERVAL) - 1:0] pwm_value_b = 0;

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


	logic [$clog2(360)-1:0] hue;    // 0-360
	logic [$clog2(255)-1:0] R, G, B; // 0-255

	// combinational part: compute hue -> x -> R,G,B
	always_comb begin
		hue = (360 * time_counter) / ONE_SEC_INTERVAL;
        
        // HSV to RGB conversion with fixed full S and V
        if (hue < 60) begin
            R = 255;
            G = (hue * 255) / 60;
            B = 0;
        end else if (hue < 120) begin
            R = ((120 - hue) * 255) / 60;
            G = 255;
            B = 0;
        end else if (hue < 180) begin
            R = 0;
            G = 255;
            B = ((hue - 120) * 255) / 60;
        end else if (hue < 240) begin
            R = 0;
            G = ((240 - hue) * 255) / 60;
            B = 255;
        end else if (hue < 300) begin
            R = ((hue - 240) * 255) / 60;
            G = 0;
            B = 255;
        end else begin
            R = 255;
            G = 0;
            B = ((360 - hue) * 255) / 60;
        end

		// convert final RGB value into PWM value
		pwm_value_r = (R * PWM_INTERVAL) / 255;
		pwm_value_g = (G * PWM_INTERVAL) / 255;
		pwm_value_b = (B * PWM_INTERVAL) / 255;

		RGB_R = ~pwm_out_r;
		RGB_G = ~pwm_out_g;
		RGB_B = ~pwm_out_b;
	end

	// sequential part: update time counter whenever at positive edge
	always_ff @(posedge clk) begin
		if (time_counter == ONE_SEC_INTERVAL - 1) begin
			time_counter <= 0;
	    end 
		else begin
			time_counter <= time_counter + 1;
		end
	end

endmodule