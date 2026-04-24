module APB_Slave (
    input               PCLK,
    input               PRESETn,
    input        [31:0] PADDR,
    input        [31:0] PWDATA,
    input               PWRITE,
    input               PENABLE,
    input        [ 2:0] PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY
);

    typedef enum logic [1:0] {
        IDLE,
        SETUP,
        ACCESS
    } slave_state;
    slave_state c_state, n_state;

    always_ff @(posedge PCLK, negedge PRESETn) begin
        if (!PRESETn) begin
            c_state <= IDLE;
        end else begin
            c_state <= n_state;
        end
    end

    always_comb begin
        n_state = c_state;
        PREADY  = 1'b0;


        case (c_state)
            IDLE: begin
                if (PSEL & PENABLE) begin// 여기 수정?
                    n_state = SETUP;
                end
            end
            SETUP: begin

            end
        endcase
    end


data_ram U_DATA_RAM(
    .clk(),
    .dwe(),
    .daddr(),
    .data_in(),
    .data_out()
);

endmodule
