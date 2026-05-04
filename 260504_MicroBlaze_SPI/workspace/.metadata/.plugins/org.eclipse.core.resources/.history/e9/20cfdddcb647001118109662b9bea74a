/*
 * SPI.h
 *
 *  Created on: 2026. 5. 4.
 *      Author: kccistc
 */

#ifndef SRC_HAL_SPI_SPI_H_
#define SRC_HAL_SPI_SPI_H_

#include <stdint.h>

#define SPI_BASEADDR 0x44A60000

typedef struct {
	uint32_t CR;
	uint32_t TX;
	uint32_t RX;
}SPI_Typedef_t;

#define SPI ((SPI_Typedef_t *) (SPI_BASEADDR))

void SPI_SetCR(SPI_Typedef_t *SPIx, uint8_t clk_div, uint8_t cpol, uint8_t cpha);
void SPI_Start(SPI_Typedef_t *SPIx, uint8_t start);
void SPI_SetTX(SPI_Typedef_t *SPIx, uint8_t tx_data);
uint8_t SPI_GetRX_Data(SPI_Typedef_t *SPIx);
uint8_t SPI_GetRX_Busy(SPI_Typedef_t *SPIx);
uint8_t SPI_GetRX_Done(SPI_Typedef_t *SPIx);

#endif /* SRC_HAL_SPI_SPI_H_ */

