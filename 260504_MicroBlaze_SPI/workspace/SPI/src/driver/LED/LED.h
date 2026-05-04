/*
 * LED.h
 *
 *  Created on: 2026. 4. 30.
 *      Author: kccistc
 */

#ifndef SRC_DRIVER_LED_LED_H_
#define SRC_DRIVER_LED_LED_H_

#include <stdint.h>
#include "../../HAL/GPIO/GPIO.h"
#include "../../common/common.h"

#define LED_PORT GPIOC

#define LED_PIN_0 GPIO_PIN_0
#define LED_PIN_1 GPIO_PIN_1
#define LED_PIN_2 GPIO_PIN_2
#define LED_PIN_3 GPIO_PIN_3
#define LED_PIN_4 GPIO_PIN_4
#define LED_PIN_5 GPIO_PIN_5
#define LED_PIN_6 GPIO_PIN_6
#define LED_PIN_7 GPIO_PIN_7

#define ON 0
#define OFF 1

void LED_Init();
void LED_WriteData(GPIO_Typedef_t *LED_Port, uint8_t rx_data);

#endif /* SRC_DRIVER_LED_LED_H_ */
