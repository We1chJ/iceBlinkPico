// PWM generator to fade LED

module pwm #(
    parameter PWM_INTERVAL = 1200       // CLK frequency is 12MHz, so 1,200 cycles is 100us
)(
    input logic clk, 
    input logic [$clog2(PWM_INTERVAL) - 1:0] pwm_value, 
    output logic pwm_out
);

    // Declare PWM generator counter variable
    logic [$clog2(PWM_INTERVAL) - 1:0] pwm_count = 0;

    // Implement counter for timing transition in PWM output signal
    always_ff @(posedge clk) begin
        if (pwm_count == PWM_INTERVAL - 1) begin
            pwm_count <= 0;
        end
        else begin
            pwm_count <= pwm_count + 1;
        end
    end

    // Generate PWM output signal
    assign pwm_out = (pwm_count > pwm_value) ? 1'b0 : 1'b1;

endmodule
