`timescale 1ns / 1ps

module APB_FND (
    // BUS Global signal
    input               PCLK,
    input               PRESET,
    // APB Interface signal
    input        [31:0] PADDR,
    input        [31:0] PWDATA,
    input               PWRITE,
    input               PENABLE,
    input               PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    output logic [ 3:0] fnd_digit,
    output logic [ 7:0] fnd_data
);

    localparam [11:0] FND_ADDR = 12'h000;
    logic [15:0] FND_REG;
    assign PREADY = (PENABLE & PSEL) ? 1'b1 : 1'b0;
    assign PRDATA = (PADDR[11:0] == FND_ADDR) ? {16'h0000, FND_REG} : 32'hxxxx_xxxx;


    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            FND_REG <= 16'h0000;
        end else begin
            if (PREADY) begin
                if (PWRITE) begin
                    case (PADDR[11:0])
                        FND_ADDR: FND_REG <= PWDATA[15:0];  // GPIO CTL REG
                    endcase
                end
            end
        end
    end

    fnd_controller U_FND_CONTROLLER (
        .clk(PCLK),
        .reset(PRESET),
        .fnd_in_data(FND_REG),
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
    );
endmodule

