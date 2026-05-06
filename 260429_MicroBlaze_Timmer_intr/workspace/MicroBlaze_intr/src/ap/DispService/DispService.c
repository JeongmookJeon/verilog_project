#include "DispService.h"

hLed hLedUpCounterMode;
hLed hLedTimeClockMode;
hLed hLedTimeMode_hhmm;
hLed hLedTimeMode_ssms;
hLed hLedShift;

void Disp_SetMode(int mode)
{
	if(mode == DISP_TIME_CLOCK) {
	LED_On(&hLedTimeClockMode);
	LED_Off(&hLedUpCounterMode);
	}
	else if(mode == DISP_UP_COUNTER){
	LED_Off(&hLedTimeClockMode);
	LED_On(&hLedUpCounterMode);
	}
}

void Disp_SetTimeMode(int mode)
{
	if(mode == DISP_TIME_HHMM){
		LED_On(&hLedTimeMode_hhmm);
		LED_Off(&hLedTimeMode_ssms);
	}
	else if(mode == DISP_TIME_SSMS){
		LED_Off(&hLedTimeMode_hhmm);
		LED_On(&hLedTimeMode_ssms);
	}
}

void Disp_Init()
{
	FND_Init();

	LED_Init(&hLedTimeClockMode, LED_MODE_TIME_CLOCK_PORT, LED_MODE_TIME_CLOCK_PIN);
	LED_Init(&hLedUpCounterMode, LED_MODE_UP_COUNTER_PORT, LED_MODE_UP_COUNTER_PIN);
	LED_Init(&hLedTimeMode_hhmm, LED_TIME_MODE_HH_MM_PORT, LED_TIME_MODE_HH_MM_PIN);
	LED_Init(&hLedTimeMode_ssms, LED_TIME_MODE_SS_MS_PORT, LED_TIME_MODE_SS_MS_PIN);
	LED_Init(&hLedShift, LED_TIME_MODE_SS_MS_PORT, GPIO_PIN_0);
	LED_Init(&hLedShift, LED_TIME_MODE_SS_MS_PORT, GPIO_PIN_1);
	LED_Init(&hLedShift, LED_TIME_MODE_SS_MS_PORT, GPIO_PIN_2);
	LED_Init(&hLedShift, LED_TIME_MODE_SS_MS_PORT, GPIO_PIN_3);

	Disp_SetMode(DISP_TIME_CLOCK);
	Disp_SetTimeMode(DISP_TIME_HHMM);
}

void Disp_SetShiftMode()
{

}

void Disp_TimeHHMM()
{

}

void Disp_TimeSSMS()
{

}

void Disp_UpCounter(uint16_t num)
{
	FND_SetNum(num);
}

void Disp_TimeClock(uint16_t num)
{
	FND_SetNum(num);
}

void Disp_ISR_Execute()
{
	FND_DispDigit();
}

void Disp_ShiftLed(int mode)
{
	static uint8_t ledShiftPosData = 1;
	uint8_t ledPortData;
	uint8_t ledOutData;

	if(mode == DISP_TIME_CLOCK){
		ledShiftPosData = (ledShiftPosData << 3) | (ledShiftPosData >> 1);
	}
	else if(mode == DISP_UP_COUNTER) {
		ledShiftPosData = (ledShiftPosData >> 3) | (ledShiftPosData << 1);
	}
	ledPortData = hLedShift.GPIOx->ODR;
	ledOutData = (ledPortData & 0xf0) | (ledShiftPosData & 0x0f);

	LED_WritePort(&hLedShift, ledOutData);
}




