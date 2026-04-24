`timescale 1ns / 1ps

module APB_Master (
    // Bus Global signal
    input PCLK,
    input PRESETn,

    // SoC Internal signal with CPU
    input  [31:0] Addr,   // from cpu
    input  [31:0] Wdata,  // from cpu
    input         WREQ,   // from cpu, Write request, signal cpu : dwe
    input         RREQ,   // from cpu, Read request,  signal cpu : dre
    // output        SlvERR, // 이건 옵션이라서 빼겠다.
    output [31:0] Rdata,
    output        Ready,

    // APB Interface signal
    output logic [31:0] PADDR,    // need register
    output logic [31:0] PWDATA,   // need register
    output logic        PENABLE,
    output logic        PWRITE,
    output logic        PSEL0,    // RAM 
    output logic        PSEL1,    // GPO 
    output logic        PSEL2,    // GPI 
    output logic        PSEL3,    // GPIO
    output logic        PSEL4,    // FND 
    output logic        PSEL5,    // UART
    input        [31:0] PRDATA0,  // from RAM 
    input        [31:0] PRDATA1,  // from GPO 
    input        [31:0] PRDATA2,  // from GPI 
    input        [31:0] PRDATA3,  // from GPIO
    input        [31:0] PRDATA4,  // from FND 
    input        [31:0] PRDATA5,  // from UART
    input               PREADY0,  // from RAM 
    input               PREADY1,  // from GPO 
    input               PREADY2,  // from GPI 
    input               PREADY3,  // from GPIO
    input               PREADY4,  // from FND 
    input               PREADY5   // from UART
);

    typedef enum {
        IDLE,
        SETUP,
        ACCESS
    } apb_state_e;

    apb_state_e c_state, n_state;
    logic [31:0] PADDR_next, PWDATA_next;
    logic decode_en, PWRITE_next;

    always_ff @(posedge PCLK, negedge PRESETn) begin
        if (!PRESETn) begin  // negative edge reset
            c_state <= IDLE;
            PADDR <= 32'd0;
            PWDATA <= 32'd0;
            PWRITE_next <= 1'b0;
        end else begin
            c_state <= n_state;
            PADDR   <= PADDR_next;
            PWDATA  <= PWDATA_next;
            PWRITE  <= PWRITE_next;
        end
    end

    // next
    always_comb begin
        decode_en   = 1'b0;
        PENABLE     = 1'b0;
        PWRITE      = 1'b0;  // 유지해야 해서 register 필요,
        PADDR_next  = PADDR;
        PWDATA_next = PWDATA;
        PWRITE_next = PWRITE;
        n_state     = c_state;
        case (c_state)
            IDLE: begin
                decode_en = 0;  // 'PSEL=0'을 의미.
                // 여기선 PENABLE 상관 없음.
                if (WREQ || RREQ) begin
                    PADDR_next  = Addr; // state 넘길 때 잡아채자. clk 바뀔 때 채면 잘못하면 다음 clk에 될 수 있기 때문.
                    PWDATA_next = Wdata;  // 얘도 잡아채는거.
                    if (WREQ) begin
                        PWRITE_next = 1'b1;
                    end else begin
                        PWRITE_next = 1'b0;
                    end
                    n_state = SETUP;
                end
            end
            SETUP: begin
                decode_en = 1;  // 'PSEL=1'을 의미.
                PENABLE   = 0;
                if (WREQ) begin
                    PWRITE = 1'b1;
                end else begin
                    PWRITE = 1'b0;
                end
                n_state = ACCESS;
            end
            ACCESS: begin
                decode_en = 1;
                PENABLE   = 1;
                //if (PREADY0|PREADY1|PREADY2|PREADY3|PREADY4|PREADY5) begin
                if (Ready) begin  // mux에서 나온 Ready.
                    n_state = IDLE; // 계속 request가 오는 경우 SETUP으로 돌아가는게 있는데 필요하면 넣어라. 우린 안할거다.
                end
            end
        endcase
    end

    addr_decoder U_ADDR_DECODER(
        .en(decode_en),
        .addr(addr),
        .psel0(PSEL0),
        .psel1(PSEL1),
        .psel2(PSEL2),
        .psel3(PSEL3),
        .psel4(PSEL4),
        .psel5(PSEL5)
    );

    apb_mux U_APB_MUX (
        .sel    (addr),
        .PRDATA0(PRDATA0),
        .PRDATA1(PRDATA1),
        .PRDATA2(PRDATA2),
        .PRDATA3(PRDATA3),
        .PRDATA4(PRDATA4),
        .PRDATA5(PRDATA5),
        .PREADY0(PREADY0),
        .PREADY1(PREADY1),
        .PREADY2(PREADY2),
        .PREADY3(PREADY3),
        .PREADY4(PREADY4),
        .PREADY5(PREADY5),
        .Rdata  (Rdata),
        .Ready  (Ready)
    );


endmodule



module addr_decoder (
    input               en,
    input        [31:0] addr,
    output logic        psel0,
    output logic        psel1,
    output logic        psel2,
    output logic        psel3,
    output logic        psel4,
    output logic        psel5
);

    always_comb begin
        psel0 = 1'b0;  // idel : 0
        psel1 = 1'b0;  // idel : 0
        psel2 = 1'b0;  // idel : 0
        psel3 = 1'b0;  // idel : 0
        psel4 = 1'b0;  // idel : 0
        psel5 = 1'b0;  // idel : 0
        if (en) begin
            case (addr[31:28])  // instead of casex
                4'h1: psel0 = 1'b1;
                4'h2: begin //합성기가 불필요하면 날릴거니까 여기선 확장을 고려해 bit를 많이 포함해서 보자.
                    case (addr[15:12])
                        4'h0: psel1 = 1'b1;
                        4'h1: psel2 = 1'b1;
                        4'h2: psel3 = 1'b1;
                        4'h3: psel4 = 1'b1;
                        4'h4: psel5 = 1'b1;
                    endcase
                end
                //casex 구문 사용할 때 32'h1xxx_xxxx; // 입력 addr에 x가 포함되면 이걸 don't care 취급해버림. 그래서 진짜 x인지 아닌지 확인 못해서 에러를 뱉어내지 않음. 그래서 헷갈릴 수 있다.
                // 이렇게 쓰기 싫으면 bit를 잘라서 쓰면 됨. 그럼 case문 사용가능. 4'h1 이렇게 쓸 수 있음.
            endcase
        end
    end

endmodule


module apb_mux (
    input        [31:0] sel,
    input        [31:0] PRDATA0,
    input        [31:0] PRDATA1,
    input        [31:0] PRDATA2,
    input        [31:0] PRDATA3,
    input        [31:0] PRDATA4,
    input        [31:0] PRDATA5,
    input               PREADY0,
    input               PREADY1,
    input               PREADY2,
    input               PREADY3,
    input               PREADY4,
    input               PREADY5,
    output logic [31:0] Rdata,
    output logic        Ready
);

    always_comb begin
        Rdata = 32'h0000_0000;  // idel : 0
        Ready = 1'b0;

        case (sel[31:28])  // instead of casex
            4'h1: begin
                Rdata = PRDATA0;
                Ready = PREADY0;
            end
            4'h2: begin
                case (sel[15:12])
                    4'h0: begin
                        Rdata = PRDATA1;
                        Ready = PREADY1;
                    end
                    4'h1: begin
                        Rdata = PRDATA2;
                        Ready = PREADY2;
                    end
                    4'h2: begin
                        Rdata = PRDATA3;
                        Ready = PREADY3;
                    end
                    4'h3: begin
                        Rdata = PRDATA4;
                        Ready = PREADY4;
                    end
                    4'h4: begin
                        Rdata = PRDATA5;
                        Ready = PREADY5;
                    end
                endcase
            end
        endcase
    end
endmodule
