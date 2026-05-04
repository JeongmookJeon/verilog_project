/*
 * SPI_D.h
 *
 *  Created on: 2026. 5. 4.
 *      Author: kccistc
 */

#ifndef SRC_DRIVER_SPI_D_SPI_D_H_
#define SRC_DRIVER_SPI_D_SPI_D_H_

#include <stdint.h>
#include "../../HAL/SPI/SPI.h"

uint8_t SPI_Transfer(SPI_Typedef_t *SPIx, uint8_t tx_data);

#endif /* SRC_DRIVER_SPI_D_SPI_D_H_ */
