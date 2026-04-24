`timescale 1ns / 1ps

module spi_top (
    input  logic       clk,
    input  logic       reset,

    // Master Control & Data Interface
    input  logic       cpol,             // 클럭 극성 설정
    input  logic       cpha,             // 클럭 위상 설정
    input  logic [7:0] clk_div,          // 분주비 설정
    input  logic [7:0] master_tx_data,   // 마스터 송신 데이터
    input  logic       master_start,     // 마스터 통신 시작 신호
    output logic [7:0] master_rx_data,   // 마스터 수신 데이터
    output logic       master_done,      // 마스터 통신 완료 신호
    output logic       master_busy,      // 마스터 동작 상태 플래그

    // Slave Control & Data Interface
    input  logic [7:0] slave_tx_data,    // 슬레이브 송신 데이터
    output logic [7:0] slave_rx_data,    // 슬레이브 수신 데이터
    output logic       slave_done        // 슬레이브 통신 완료 신호
);

    // 내부 연결을 위한 SPI 버스 신호 선언
    logic w_sclk;
    logic w_mosi;
    logic w_miso;
    logic w_cs_n;

    // SPI Master 인스턴스화
    spi_master u_spi_master (
        .clk     (clk),
        .reset   (reset),
        .cpol    (cpol),
        .cpha    (cpha),
        .clk_div (clk_div),
        .tx_data (master_tx_data),       // 마스터 제어 포트 연결
        .start   (master_start),
        .rx_data (master_rx_data),
        .done    (master_done),
        .busy    (master_busy),
        .sclk    (w_sclk),             // 마스터 출력 SCLK
        .mosi    (w_mosi),             // 마스터 출력 MOSI
        .miso    (w_miso),             // 마스터 입력 MISO
        .cs_n    (w_cs_n)              // 마스터 출력 CS_N
    );

    // SPI Slave 인스턴스화
    spi_slave u_spi_slave (
        .clk     (clk),
        .reset   (reset),
        .tx_data (slave_tx_data),        // 슬레이브 제어 포트 연결
        .rx_data (slave_rx_data),
        .done    (slave_done),
        .sclk    (w_sclk),             // 슬레이브 입력 SCLK
        .mosi    (w_mosi),             // 슬레이브 입력 MOSI
        .miso    (w_miso),             // 슬레이브 출력 MISO
        .cs_n    (w_cs_n)              // 슬레이브 입력 CS_N
    );

endmodule