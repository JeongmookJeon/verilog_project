/*
 * SPI.c
 *
 *  Created on: 2026. 5. 4.
 *      Author: kccistc
 */

#include "SPI.h"

void SPI_SetCR(SPI_Typedef_t *SPIx, uint8_t clk_div, uint8_t cpol, uint8_t cpha)
{
	SPIx->CR = clk_div | (cpol << 8) | (cpha << 9);
}

void SPI_Start(SPI_Typedef_t *SPIx, uint8_t start)
{
	if(start == 1) SPIx->CR |= (1 << 10);
	else if (start == 0) SPIx->CR &= ~(1 << 10);
}

void SPI_SetTX(SPI_Typedef_t *SPIx, uint8_t tx_data)
{
	SPIx->TX = tx_data;
}
uint8_t SPI_GetRX_Data(SPI_Typedef_t *SPIx)
{
	// 다른 상태 비트(8번, 9번)는 무시하고, 하위 8비트(0~7번)만
	// 0xFF 는 이진수로 0000_0000_0000_0000_0000_0000_1111_1111
	return (uint8_t)(SPIx->RX & 0xFF);
}
uint8_t SPI_GetRX_Busy(SPI_Typedef_t *SPIx)
{
	// RX 레지스터의 8번 비트가 1이면 참(1) 반환, 아니면 거짓(0) 반환
	if (SPIx->RX & (1 << 8)) return 1;
	else return 0;
}
uint8_t SPI_GetRX_Done(SPI_Typedef_t *SPIx)
{
	// RX 레지스터의 9번 비트가 1이면 참(1) 반환, 아니면 거짓(0) 반환
	if (SPIx->RX & (1 << 9)) return 1;
	else return 0;
}
