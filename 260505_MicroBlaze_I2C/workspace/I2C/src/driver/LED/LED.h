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

typedef enum {
    ON = 1,
    OFF = 0
} led_state_t;

typedef struct {
    GPIO_Typedef_t* GPIOx;
    uint32_t GPIO_Pin;
    led_state_t OnOff;
} hLed_t;

#define LED_PIN_0 GPIO_PIN_0
#define LED_PIN_1 GPIO_PIN_1
#define LED_PIN_2 GPIO_PIN_2
#define LED_PIN_3 GPIO_PIN_3
#define LED_PIN_4 GPIO_PIN_4
#define LED_PIN_5 GPIO_PIN_5
#define LED_PIN_6 GPIO_PIN_6
#define LED_PIN_7 GPIO_PIN_7

void LED_Init(hLed_t* hled, GPIO_Typedef_t* GPIOx, uint32_t GPIO_Pin);
void LED_On(hLed_t* hled);
void LED_Off(hLed_t* hled);

#endif /* SRC_DRIVER_LED_LED_H_ */
