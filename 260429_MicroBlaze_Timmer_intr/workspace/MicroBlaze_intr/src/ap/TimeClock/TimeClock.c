#include "TimeClock.h"

timeClock_t timeClock;


timeState_t timeState = HOUR_MIN;
timeClock_t timeClock;

hBtn_t hbtnTimeMode;

void TimeClock_Init() {
	TimeClock_SetTime(12, 0, 0, 0);
	Button_Init(&hbtnTimeMode, GPIOA, GPIO_PIN_6);
}

void TimeClock_SetTime(uint8_t hh, uint8_t mm, uint8_t ss, uint8_t ms) {
	timeClock.hour = hh;
	timeClock.min = mm;
	timeClock.sec = ss;
	timeClock.msec = ms;
}

void TimeClock_Execute() {
	TimeClock_DispTime();
}

void TimeClock_IncTime() {

	if (timeClock.msec < 100 - 1) {
		timeClock.msec++;
		return;
	}
	timeClock.msec = 0;

	if (timeClock.sec < 60 - 1) {
		timeClock.sec++;
		return;
	}
	timeClock.sec = 0;

	if (timeClock.min < 60 - 1) {
		timeClock.min++;
		return;
	}
	timeClock.min = 0;

	if (timeClock.hour < 24 - 1) {
		timeClock.hour++;
		return;
	}
	timeClock.hour = 0;
}

void TimeClock_DispTime() {

	switch (timeState) {
	case HOUR_MIN:
		TimeClock_DispHourMin();
		if(Button_GetState(&hbtnTimeMode) == ACT_RELEASED){
			timeState = SEC_MSEC;
		}
		break;
	case SEC_MSEC:
		TimeClock_DispSecMSec();
		if(Button_GetState(&hbtnTimeMode) == ACT_RELEASED){
					timeState = HOUR_MIN;
		}
		break;
	}

	if (timeClock.msec < 50) {
		FND_SetDP(FND_DIGIT_100, ON);
	} else {
		FND_SetDP(FND_DIGIT_100, OFF);
	}
	static uint32_t prevShiftTime = 0;
	uint32_t curShiftTime;
	curShiftTime = millis();

	if (curShiftTime - prevShiftTime >= 99) {
		prevShiftTime = curShiftTime;
		Disp_ShiftLed(DISP_TIME_CLOCK);
	}

}

void TimeClock_DispHourMin() {
	uint16_t timeNum;

	timeNum = timeClock.hour * 100 + timeClock.min;

	//FND_SetNum(timeNum);
	Disp_TimeClock(timeNum);
	Disp_SetTimeMode(DISP_TIME_HHMM);
	//Disp_ShiftLed(DISP_TIME_CLOCK);
}

void TimeClock_DispSecMSec() {
	uint16_t timeNum;

	timeNum = timeClock.sec * 100 + timeClock.msec;

	//FND_SetNum(timeNum);
	Disp_TimeClock(timeNum);

	Disp_SetTimeMode(DISP_TIME_SSMS);
	//Disp_ShiftLed(DISP_TIME_CLOCK);
}

