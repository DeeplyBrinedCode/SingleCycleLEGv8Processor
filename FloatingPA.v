`timescale 1ns/1ps

module FloatingPA (
    input  wire        clk,
    input  wire        rst,    // synchronous active-high reset
    input  wire        start,  // pulse for one cycle to launch
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [31:0] result,
    output reg         done
);

    // ── FSM states ────────────────────────────────────────────────────────
    localparam [2:0]
        S_IDLE      = 3'd0,
        S_UNPACK    = 3'd1,
        S_ALIGN     = 3'd2,
        S_ADD_SUB   = 3'd3,
        S_NORMALIZE = 3'd4,
        S_ROUND     = 3'd5,
        S_PACK      = 3'd6,
        S_DONE      = 3'd7;

    reg [2:0] state;

    // ── Datapath registers ────────────────────────────────────────────────
    reg        sign_a, sign_b;
    reg [7:0]  exp_a,  exp_b;
    reg [23:0] mant_a, mant_b;   // 1 implicit + 23 fraction bits

    reg        res_sign;
    reg [7:0]  res_exp;
    reg [7:0]  exp_diff;

    // 25-bit aligned significands  [24]=headroom  [23]=implicit1  [22:0]=frac
    reg [24:0] sig_large, sig_small_aligned;

    // 26-bit sum  [25]=carry  [24]=implicit1  [23:2]=frac  [1]=guard  [0]=round
    reg [25:0] sum;
    reg        sticky;

    // Which operand was larger (needed to pick result sign on subtraction)
    reg        a_is_larger;

    // ── FSM + Datapath ────────────────────────────────────────────────────
    always @(posedge clk) begin
        if (rst) begin
            state              <= S_IDLE;
            done               <= 1'b0;
            result             <= 32'd0;
            sign_a             <= 1'b0; sign_b             <= 1'b0;
            exp_a              <= 8'd0; exp_b              <= 8'd0;
            mant_a             <= 24'd0; mant_b            <= 24'd0;
            res_sign           <= 1'b0; res_exp            <= 8'd0;
            exp_diff           <= 8'd0;
            sig_large          <= 25'd0;
            sig_small_aligned  <= 25'd0;
            sum                <= 26'd0;
            sticky             <= 1'b0;
            a_is_larger        <= 1'b0;
        end else begin
            done <= 1'b0;

            case (state)

                // ──────────────────────────────────────────────────────
                //  S_IDLE
                // ──────────────────────────────────────────────────────
                S_IDLE: begin
                    if (start) state <= S_UNPACK;
                end

                // ──────────────────────────────────────────────────────
                //  S_UNPACK
                //  Decompose IEEE-754 word; restore implicit leading 1.
                // ──────────────────────────────────────────────────────
                S_UNPACK: begin
                    sign_a <= a[31];
                    exp_a  <= a[30:23];
                    mant_a <= {1'b1, a[22:0]};   // 24-bit: implicit 1 + fraction

                    sign_b <= b[31];
                    exp_b  <= b[30:23];
                    mant_b <= {1'b1, b[22:0]};

                    state  <= S_ALIGN;
                end

                // ──────────────────────────────────────────────────────
                //  S_ALIGN  –  Small ALU
                //  1. Compare exponents.
                //  2. Right-shift smaller mantissa by |exp_a − exp_b|.
                //  3. Capture sticky from shifted-out bits.
                // ──────────────────────────────────────────────────────
                S_ALIGN: begin
                    if (exp_a >= exp_b) begin
                        a_is_larger       <= 1'b1;
                        res_exp           <= exp_a;
                        exp_diff          <= exp_a - exp_b;
                        sig_large         <= {1'b0, mant_a};
                        // right-shift mant_b; sticky = OR of all shifted-out bits
                        sig_small_aligned <= {1'b0, mant_b} >> (exp_a - exp_b);
                        sticky            <= (exp_a > exp_b) ?
                                            (|({1'b0, mant_b} << (9'd25 - (exp_a - exp_b)))) :
                                            1'b0;
                    end else begin
                        a_is_larger       <= 1'b0;
                        res_exp           <= exp_b;
                        exp_diff          <= exp_b - exp_a;
                        sig_large         <= {1'b0, mant_b};
                        sig_small_aligned <= {1'b0, mant_a} >> (exp_b - exp_a);
                        sticky            <= |({1'b0, mant_a} << (9'd25 - (exp_b - exp_a)));
                    end
                    state <= S_ADD_SUB;
                end

                // ──────────────────────────────────────────────────────
                //  S_ADD_SUB  –  Big ALU
                //  Shift operands left 2 (creates guard/round slots).
                //  Add or subtract based on effective sign.
                // ──────────────────────────────────────────────────────
                S_ADD_SUB: begin
                    // big26 = {0, sig_large, 00}   sml26 = {0, sig_small_aligned, 00}
                    if (sign_a == sign_b) begin
                        // Same effective sign → add magnitudes
                        sum      <= ({1'b0, sig_large} + {1'b0, sig_small_aligned}) << 1;
                        res_sign <= sign_a;
                    end else begin
                        // Different signs → subtract; take sign of larger magnitude
                        if (sig_large >= sig_small_aligned) begin
                            sum      <= ({1'b0, sig_large} - {1'b0, sig_small_aligned}) << 1;
                            res_sign <= a_is_larger ? sign_a : sign_b;
                        end else begin
                            sum      <= ({1'b0, sig_small_aligned} - {1'b0, sig_large}) << 1;
                            res_sign <= a_is_larger ? sign_b : sign_a;
                        end
                    end
                    state <= S_NORMALIZE;
                end

                // ──────────────────────────────────────────────────────
                //  S_NORMALIZE  –  Left/Right Shifter
                //  Target: sum[25]=0, sum[24]=1  (normal form 1.fraction)
                //  Iterates one shift per clock.
                // ──────────────────────────────────────────────────────
                S_NORMALIZE: begin
                    if (sum == 26'd0) begin
                        res_exp  <= 8'd0;
                        res_sign <= 1'b0;
                        state    <= S_ROUND;
                    end else if (sum[25]) begin
                        // Carry-out: right shift once, bump exponent
                        sticky  <= sticky | sum[0];
                        sum     <= sum >> 1;
                        res_exp <= res_exp + 8'd1;
                        state   <= S_ROUND;
                    end else if (!sum[24]) begin
                        // Leading zero: left-shift (iterate)
                        sum     <= sum << 1;
                        res_exp <= res_exp - 8'd1;
                        // stay in NORMALIZE
                    end else begin
                        // Normalised: sum[24] = 1
                        state <= S_ROUND;
                    end
                end

                // ──────────────────────────────────────────────────────
                //  S_ROUND  –  Round-to-Nearest-Even (IEEE default)
                //  After normalisation:
                //    sum[25]   = 0
                //    sum[24]   = implicit 1
                //    sum[23:2] = fraction bits (MSB first)
                //    sum[1]    = guard  (G)
                //    sum[0]    = round  (R)
                //    sticky    = sticky (S)
                //
                //  Round-up when:  G & (R | S | LSB)
                //  where LSB = sum[2] (lowest fraction bit)
                // ──────────────────────────────────────────────────────
                S_ROUND: begin
                    if ((sum != 26'd0) && sum[1] && (sum[0] | sticky | sum[2])) begin
                        sum <= sum + 26'd4;          // +1 ULP (at bit 2)
                        if ((sum + 26'd4) >> 25) begin  // post-round carry
                            sum     <= (sum + 26'd4) >> 1;
                            res_exp <= res_exp + 8'd1;
                        end
                    end
                    state <= S_PACK;
                end

                // ──────────────────────────────────────────────────────
                //  S_PACK
                //  sum[24] = implicit 1 (dropped per IEEE-754)
                //  sum[23:1] = 23 fraction bits (after rounding)
                // ──────────────────────────────────────────────────────
                S_PACK: begin
                    result <= {res_sign, res_exp, sum[23:1]};
                    state  <= S_DONE;
                end

                // ──────────────────────────────────────────────────────
                //  S_DONE
                // ──────────────────────────────────────────────────────
                S_DONE: begin
                    done  <= 1'b1;
                    state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule