#include "SPI.h"

// SPI 초기화 설정 함수
void SPI_Init(SPI_Typedef_t *SPIx, uint8_t clk_div, uint8_t cpol, uint8_t cpha) {
	uint32_t cr_val = 0;

	cr_val |= (clk_div & 0xFF);                   // clk_div 설정 [7:0]
	cr_val |= (cpol & 0x01) << SPI_CR_CPOL_BIT;   // CPOL 설정 [8]
	cr_val |= (cpha & 0x01) << SPI_CR_CPHA_BIT;   // CPHA 설정 [9]

	// START 비트는 0으로 둔 상태로 CR 레지스터에 쓰기
	SPIx->CR = cr_val;
}

// SPI 데이터 송수신 함수 (Master 기준)
uint8_t SPI_TransmitReceive(SPI_Typedef_t *SPIx, uint8_t txData) {
	// 1. 송신할 데이터를 TX_DATA 레지스터에 쓰기
	SPIx->TX_DATA = txData;

	// 2. CR 레지스터의 START 비트를 1로 설정하여 통신 시작
	SPIx->CR |= (1 << SPI_CR_START_BIT);

	// 3. START 비트를 다시 0으로 클리어 (하드웨어 로직에 따라 펄스로 작동해야 함)
	// 주의: Verilog 구현상 start 신호가 유지되면 오작동할 수 있으므로 즉시 내립니다.
	SPIx->CR &= ~(1 << SPI_CR_START_BIT);

	// 4. 하드웨어의 통신이 완료될 때까지(done 플래그가 1이 될 때까지) 대기 (Polling)
	// (SPI_v1_0_S00_AXI.v의 slv_reg2 [9]번 비트 확인)
	while (!(SPIx->SR_RX & (1 << SPI_SR_DONE_BIT)))
		;

	// 5. 완료 후 수신된 데이터([7:0])를 읽어서 반환
	return (uint8_t) (SPIx->SR_RX & 0xFF);
}
