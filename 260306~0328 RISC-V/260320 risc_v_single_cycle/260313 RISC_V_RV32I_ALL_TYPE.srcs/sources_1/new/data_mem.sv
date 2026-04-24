module data_mem (
    input               clk,
    input               rst,
    input               dwe,
    input        [ 2:0] i_funct3,
    input        [31:0] daddr,
    input        [31:0] dwdata,
    output logic [31:0] drdata
);

    // word address (1024 words = 4KB memory)
    // 팁: [0:1024]는 1025개이므로, 정확히 1024개를 위해 [0:1023]으로 수정했습니다.
    logic [31:0] dmem[0:255];  // 32bit를 저장하니까  word단위로 저장한다. 
    /*  initial begin
        for (int i = 0; i < 256; i++) begin
            dmem[i] = 32'h0;
        end
    end*/

    // 1. S-Type (Store: 메모리에 쓰기)
    always_ff @(posedge clk) begin
        if (dwe) begin
            case (i_funct3)
                3'b010: begin  // SW (Store Word): 32비트 전체 덮어쓰기
                    dmem[daddr[31:2]] <= dwdata;
                end

                3'b001: begin  // SH (Store Half-word): 16비트 덮어쓰기
                    if (daddr[1]) dmem[daddr[31:2]][31:16] <= dwdata[15:0];
                    else dmem[daddr[31:2]][15:0] <= dwdata[15:0];
                end

                3'b000: begin  // SB (Store Byte): 8비트 덮어쓰기
                    case (daddr[1:0])
                        2'b00: dmem[daddr[31:2]][7:0] <= dwdata[7:0];
                        2'b01: dmem[daddr[31:2]][15:8] <= dwdata[7:0];
                        2'b10: dmem[daddr[31:2]][23:16] <= dwdata[7:0];
                        2'b11: dmem[daddr[31:2]][31:24] <= dwdata[7:0];
                    endcase
                end

            endcase
        end
    end


    always_comb begin
        drdata = 32'd0;  // Latch 방지를 위한 초기화

        case (i_funct3)
            3'b000: begin  // LB (Load Byte) - 부호 확장 (Sign Extension)
                case (daddr[1:0])
                    2'b00:
                    drdata = {
                        {24{dmem[daddr[31:2]][7]}}, dmem[daddr[31:2]][7:0]
                    };
                    2'b01:
                    drdata = {
                        {24{dmem[daddr[31:2]][15]}}, dmem[daddr[31:2]][15:8]
                    };
                    2'b10:
                    drdata = {
                        {24{dmem[daddr[31:2]][23]}}, dmem[daddr[31:2]][23:16]
                    };
                    2'b11:
                    drdata = {
                        {24{dmem[daddr[31:2]][31]}}, dmem[daddr[31:2]][31:24]
                    };
                endcase
            end

            3'b001: begin  // LH (Load Half-word) - 부호 확장 (Sign Extension)
                if (daddr[1])
                    drdata = {
                        {16{dmem[daddr[31:2]][31]}}, dmem[daddr[31:2]][31:16]
                    };
                else
                    drdata = {
                        {16{dmem[daddr[31:2]][15]}}, dmem[daddr[31:2]][15:0]
                    };
            end

            3'b010: begin  // LW (Load Word) - 원본 그대로 출력
                drdata = dmem[daddr[31:2]];
            end

            3'b100: begin  // LBU (Load Byte Unsigned) - 0으로 확장 (Zero Extension)
                case (daddr[1:0])
                    2'b00: drdata = {24'd0, dmem[daddr[31:2]][7:0]};
                    2'b01: drdata = {24'd0, dmem[daddr[31:2]][15:8]};
                    2'b10: drdata = {24'd0, dmem[daddr[31:2]][23:16]};
                    2'b11: drdata = {24'd0, dmem[daddr[31:2]][31:24]};
                endcase
            end

            3'b101: begin  // LHU (Load Half-word Unsigned) - 0으로 확장 (Zero Extension)
                if (daddr[1]) drdata = {16'd0, dmem[daddr[31:2]][31:16]};
                else drdata = {16'd0, dmem[daddr[31:2]][15:0]};
            end

            default: drdata = 32'd0;
        endcase
    end
endmodule
