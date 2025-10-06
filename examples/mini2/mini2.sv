`include "pwm.sv"

module top(
	input logic clk,
	output logic RGB_R,
	output logic RGB_G,
	output logic RGB_B
);
	// CLK frequency is 12MHz, so 6,000,000 cycles is 0.5s
	parameter ONE_SEC_INTERVAL = 12000000; // 1s
	parameter COLOR_CHANGE_INTERVAL = ONE_SEC_INTERVAL/6;     // color changing interval, 1/6 of a full second
    parameter PWM_INTERVAL = 1200;          // CLK frequency is 12MHz, so 1,200 cycles is 100us
	parameter INC_DEC_MAX = 255; // incrementing/decrementing up to a full color scale (0-255)
    parameter INC_DEC_VAL = PWM_INTERVAL / INC_DEC_MAX; // how much to inc/dec evenly every interval on the pwm value
	parameter INC_DEC_INTERVAL = COLOR_CHANGE_INTERVAL / INC_DEC_MAX; // how long would the inc/dec take to evenly update the pwm in one color cycle (1/6 of a second)
	parameter COLOR_CYCLE = 6; // 6 color sections

	// Define state variable values
    localparam PWM_INC = 1'b0;
    localparam PWM_DEC = 1'b1;

	// Declare state variables
    logic current_state = PWM_INC;
    logic next_state;
	
	// Declare variables for timing state transitions
    logic [$clog2(COLOR_CHANGE_INTERVAL) - 1:0] count = 0;
    logic [$clog2(PWM_INTERVAL) - 1:0] pwm_value = 0;
	logic [$clog2(COLOR_CYCLE) - 1:0] color_counter = 0;
	// Counter for INC_DEC_INTERVAL
	logic [$clog2(INC_DEC_INTERVAL)-1:0] inc_dec_count = 0;

    logic time_to_transition = 1'b0;

	initial begin
        pwm_value = 0;
    end

	// Register the next state of the FSM
    always_ff @(posedge time_to_transition)
        current_state <= next_state;

	// Compute the next state of the FSM
    always_comb begin
        next_state = 1'bx;
        case (current_state)
            PWM_INC:
                next_state = PWM_DEC;
            PWM_DEC:
                next_state = PWM_INC;
        endcase
    end

	// Implement counter for transitioning from one color to the next one
    always_ff @(posedge clk) begin
        if (count == COLOR_CHANGE_INTERVAL - 1) begin
            count <= 0;
            time_to_transition <= 1'b1;
			if (color_counter == COLOR_CYCLE-1) begin
				color_counter <= 0;
			end
			else begin
				color_counter <= color_counter + 1;
			end
        end
        else begin
            count <= count + 1;
            time_to_transition <= 1'b0;
        end
    end

	always_ff @(posedge clk) begin
		if (inc_dec_count == INC_DEC_INTERVAL - 1) begin
			inc_dec_count <= 0;
			case (current_state)
				PWM_INC:
					pwm_value <= pwm_value + INC_DEC_VAL;
				PWM_DEC:
					pwm_value <= pwm_value - INC_DEC_VAL;
			endcase
		end else begin
			inc_dec_count <= inc_dec_count + 1;
		end
	end

	// input the fading pwm_value and outputing the raw pwm_out for R or G or B
	logic pwm_out;
	pwm #(
		.PWM_INTERVAL (PWM_INTERVAL)
	) u1 (
		.clk (clk),
		.pwm_value (pwm_value),
		.pwm_out (pwm_out)
	);

	// PWM values for each color channel
	logic pwm_out_r, pwm_out_g, pwm_out_b;
	initial begin
		// initialize r to 1
		pwm_out_r = 1;
		pwm_out_g = 0;
		pwm_out_b = 0;
	end

	// Assign PWM values based on color_counter state
	always_comb begin
		case (color_counter)
			0: begin // Red up
				pwm_out_r = 1;
				pwm_out_g = pwm_out;
				pwm_out_b = 0;
			end
			1: begin // Yellow
				pwm_out_r = pwm_out;
				pwm_out_g = 1;
				pwm_out_b = 0;
			end
			2: begin // Green up, Red down
				pwm_out_r = 0;
				pwm_out_g = 1;
				pwm_out_b = pwm_out;
			end
			3: begin // Green max, Blue up
				pwm_out_r = 0;
				pwm_out_g = pwm_out;
				pwm_out_b = 1;
			end
			4: begin // Cyan (Green down, Blue up)
				pwm_out_r = pwm_out;
				pwm_out_g = 0;
				pwm_out_b = 1;
			end
			5: begin // Blue down
				pwm_out_r = 1;
				pwm_out_g = 0;
				pwm_out_b = pwm_out;
			end
			default: begin
				pwm_out_r = 0;
				pwm_out_g = 0;
				pwm_out_b = 0;
			end
		endcase
	end

	// account for active low design for the LED
	assign RGB_R = ~pwm_out_r;
	assign RGB_G = ~pwm_out_g;
	assign RGB_B = ~pwm_out_b;

endmodule