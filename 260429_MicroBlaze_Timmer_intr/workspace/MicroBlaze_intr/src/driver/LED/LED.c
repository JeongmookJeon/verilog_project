#include "LED.h"

void LED_Init(hLed *hled, GPIO_Typedef_t *GPIOx, uint32_t GPIO_Pin)
{
	hled->GPIOx = GPIOx;
	hled->GPIO_Pin = GPIO_Pin;
	GPIO_SetMode(hled->GPIOx, hled->GPIO_Pin, OUTPUT);
}

void LED_On(hLed *hled)
{
	GPIO_WritePin(hled->GPIOx, hled->GPIO_Pin, SET);
}


void LED_Off(hLed *hled)
{
	GPIO_WritePin(hled->GPIOx, hled->GPIO_Pin, RESET);
}

void LED_Toggle(hLed *hled)
{
	GPIO_TogglePin(hled->GPIOx, hled->GPIO_Pin);
}


void LED_WritePort(hLed *hled, uint8_t data)
{
	GPIO_WritePort(hled->GPIOx, data);
}

uint8_t LED_ReadPort(hLed *hled)
{
	return (uint8_t)GPIO_ReadPort(hled->GPIOx);
}
