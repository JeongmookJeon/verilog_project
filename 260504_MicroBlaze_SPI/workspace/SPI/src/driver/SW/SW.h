/*
 * SW.h
 *
 *  Created on: 2026. 5. 4.
 *      Author: kccistc
 */

#ifndef SRC_DRIVER_SW_SW_H_
#define SRC_DRIVER_SW_SW_H_

#include <stdint.h>

#define SW_PIN_0 GPIO_PIN_0
#define SW_PIN_1 GPIO_PIN_1
#define SW_PIN_2 GPIO_PIN_2
#define SW_PIN_3 GPIO_PIN_3
#define SW_PIN_4 GPIO_PIN_4
#define SW_PIN_5 GPIO_PIN_5
#define SW_PIN_6 GPIO_PIN_6
#define SW_PIN_7 GPIO_PIN_7

#define ON 0
#define OFF 1

void SW_Init ();
uint8_t SW_ReadData ();

#endif /* SRC_DRIVER_SW_SW_H_ */
