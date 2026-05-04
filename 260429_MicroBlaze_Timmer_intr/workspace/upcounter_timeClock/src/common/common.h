/*
 * common.h
 *
 *  Created on: 2026. 4. 28.
 *      Author: kccistc
 */

#ifndef SRC_COMMON_COMMON_H_
#define SRC_COMMON_COMMON_H_

#include <stdint.h>
#include "sleep.h"
#include "../HAL/TMR/TMR.h"

uint32_t millis();
void millis_inc();
void delay_ms(uint32_t msec);
void delay_us(uint32_t usec);

#endif /* SRC_COMMON_COMMON_H_ */
