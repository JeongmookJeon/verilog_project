
#ifndef SRC_DRIVER_LED_LED_H_
#define SRC_DRIVER_LED_LED_H_

#include "../../HAL/GPIO/GPIO.h"

#define LED_MODE_UP_COUNTER_PORT  GPIOC
#define LED_MODE_UP_COUNTER_PIN   GPIO_PIN_7
#define LED_MODE_TIME_CLOCK_PORT  GPIOC
#define LED_MODE_TIME_CLOCK_PIN   GPIO_PIN_6
#define LED_TIME_MODE_HH_MM_PORT  GPIOC
#define LED_TIME_MODE_HH_MM_PIN	  GPIO_PIN_5
#define LED_TIME_MODE_SS_MS_PORT  GPIOC
#define LED_TIME_MODE_SS_MS_PIN	  GPIO_PIN_4

typedef struct {
	GPIO_Typedef_t *GPIOx;
	uint32_t GPIO_Pin;
}hLed;

void LED_Init(hLed *hled, GPIO_Typedef_t *GPIOX, uint32_t GPIO_Pin);
void LED_On(hLed *hled);
void LED_Off(hLed *hled);
void LED_Toggle(hLed *hled);
void LED_WritePort(hLed *hled, uint8_t data);
uint8_t LED_ReadPort(hLed *hled);

#endif /* SRC_DRIVER_LED_LED_H_ */
