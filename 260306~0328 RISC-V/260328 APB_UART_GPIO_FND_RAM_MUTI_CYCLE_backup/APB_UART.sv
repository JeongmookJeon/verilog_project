`timescale 1ns / 1ps

module APB_UART (
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

    // External Ports
    input               uart_rx,
    output logic        uart_tx
);
    // 1. 레지스터 주소 mapping
    localparam [11:0] UART_CTL_ADDR    = 12'h000; // 제어 (Tx_start)
    localparam [11:0] UART_BAUD_ADDR   = 12'h004; // 통신 속도 (00:9600, 01:19200, 10:115200)
    localparam [11:0] UART_STATUS_ADDR = 12'h008; // 상태 (Rx_done, Tx_busy)
    localparam [11:0] UART_TX_ADDR     = 12'h00C; // 보낼 데이터
    localparam [11:0] UART_RX_ADDR     = 12'h010; // 받은 데이터

    // 2. 내부 레지스터 및 와이어 선언
    logic [31:0] ctl_reg;       // 0번 비트: Tx_start
    logic [31:0] baud_reg;      // 1:0 비트: Baud rate 선택
    logic [7:0]  tx_data_reg;   // 송신 데이터 저장
    logic        rx_done_flag;  // 수신 완료 깃발 (CPU가 읽을 때까지 유지)

    // uart_top 연결될 선
    logic [7:0] rx_data_wire;
    logic       rx_done_wire;   // 알맹이에서 나오는 1클럭짜리 짧은 펄스
    logic       tx_busy_wire;

    assign PREADY = (PENABLE & PSEL) ? 1'b1 : 1'b0;

    // 3. 쓰기 (Write) 로직 + 플래그 제어
    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            ctl_reg      <= 32'd0;
            baud_reg     <= 32'd0;
            tx_data_reg  <= 8'd0;
            rx_done_flag <= 1'b0;
        end else begin
            //   TX가 시작되어 바빠지면, ctl_reg의 Tx_start 비트를 자동으로 0으로 내림 (무한 전송 방지)
            if (tx_busy_wire && ctl_reg[0]) begin
                ctl_reg[0] <= 1'b0;
            end

            //   Rx_done 펄스가 튀면 깃발을 들고(1), CPU가 RX_ADDR을 읽어가면 깃발을 내림(0)
            if (rx_done_wire) begin
                rx_done_flag <= 1'b1; 
            end else if (PREADY && !PWRITE && (PADDR[11:0] == UART_RX_ADDR)) begin
                rx_done_flag <= 1'b0; // CPU가 읽어갔으니 플래그 클리어!
            end

            // 마스터가 값을 쓸 때
            if (PREADY & PWRITE) begin
                case (PADDR[11:0])
                    UART_CTL_ADDR:  ctl_reg     <= PWDATA;      // Tx_start 등 제어
                    UART_BAUD_ADDR: baud_reg    <= PWDATA;      // Baudrate 세팅
                    UART_TX_ADDR:   tx_data_reg <= PWDATA[7:0]; // 송신 데이터 8비트
                endcase
            end
        end
    end

    // 4. 읽기 (Read) Mux 로직
    assign PRDATA = (PADDR[11:0] == UART_CTL_ADDR)    ? ctl_reg :
                    (PADDR[11:0] == UART_BAUD_ADDR)   ? baud_reg :
                    (PADDR[11:0] == UART_STATUS_ADDR) ? {30'd0, rx_done_flag, tx_busy_wire} : // 1번 비트: rx_done, 0번 비트: tx_busy
                    (PADDR[11:0] == UART_RX_ADDR)     ? {24'd0, rx_data_wire} :
                    32'hxxxx_xxxx;

    // 5. 알맹이(UART_TOP) 조립
    uart_top U_UART_TOP (
        .clk        (PCLK),
        .rst        (PRESET),
        .baud_sel   (baud_reg[1:0]), //  추가: 통신 속도 선택
        .i_tx_data  (tx_data_reg),
        .i_tx_start (ctl_reg[0]),    //  CTL 레지스터의 0번 비트가 Start를 트리거
        .uart_rx    (uart_rx),
        .rx_data    (rx_data_wire),
        .rx_done    (rx_done_wire),
        .uart_tx    (uart_tx),
        .o_tx_busy  (tx_busy_wire)
    );

endmodule