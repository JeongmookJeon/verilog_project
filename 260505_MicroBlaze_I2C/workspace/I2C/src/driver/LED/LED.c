/*
 * LED.c
 *
 *  Created on: 2026. 4. 30.
 *      Author: kccistc
 */

#include "LED.h"

#include <stdint.h>

#include "../../HAL/GPIO/GPIO.h"

void LED_Init(hLed_t* hled, GPIO_Typedef_t* GPIOx, uint32_t GPIO_Pin) {
    GPIO_SetMode(GPIOx, GPIO_Pin, OUTPUT);
    GPIO_WritePin(GPIOx, GPIO_Pin, OFF);

    hled->GPIOx = GPIOx;
    hled->GPIO_Pin = GPIO_Pin;
    hled->OnOff = OFF;
}

void LED_On(hLed_t* hled) {
    GPIO_WritePin(hled->GPIOx, hled->GPIO_Pin, ON);
    hled->OnOff = ON;
}

void LED_Off(hLed_t* hled) {
    GPIO_WritePin(hled->GPIOx, hled->GPIO_Pin, OFF);
    hled->OnOff = OFF;
}
