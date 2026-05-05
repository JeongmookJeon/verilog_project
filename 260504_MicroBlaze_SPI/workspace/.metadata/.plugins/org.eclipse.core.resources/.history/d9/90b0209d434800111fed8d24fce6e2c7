/*
 * LED.c
 *
 *  Created on: 2026. 4. 30.
 *      Author: kccistc
 */

#include "LED.h"

void LED_Init() {
	GPIO_SetMode(LED_PORT,
			LED_PIN_0 | LED_PIN_1 | LED_PIN_2 | LED_PIN_3 | LED_PIN_4
					| LED_PIN_5 | LED_PIN_6 | LED_PIN_7, OUTPUT);
}

//void LED_SetPort(GPIO_Typedef_t *LED_Port, uint32_t LED_Pin, int OnOff) {
//	GPIO_WritePin(LED_Port, LED_Pin, OnOff);
//}

void LED_WriteData(GPIO_Typedef_t *LED_Port, uint8_t rx_data) {
    GPIO_WritePort(LED_Port, (int)rx_data);
}
