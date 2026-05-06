#include "xil_printf.h"

#include "ap_main.h"
#include "../HAL/TMR/TMR.h"
#include "TimeClock/TimeClock.h"
#include "UpCounter/UpCounter.h"
#include "interrupt.h"
#include "../driver/Button/Button.h"
#include "../driver/LED/LED.h"
#include "DispService/DispService.h"

typedef enum {
	TIME_CLOCK,
	UP_COUNTER
} mode_state_t;

mode_state_t modeState = TIME_CLOCK;

hBtn_t hbtnMode;

void ap_init() {
	Button_Init(&hbtnMode, GPIOA, GPIO_PIN_5);

	UpCounter_Init();
	TimeClock_Init();
	SetupInterruptSystem();

	TMR0_Init();
	TMR1_Init();
	TMR2_Init();
}

void ap_execute()
{
	while (1)
	{
		switch (modeState) {
		case TIME_CLOCK:
			TimeClock_Execute();
			Disp_SetMode(DISP_TIME_CLOCK);
			if (Button_GetState(&hbtnMode) == ACT_RELEASED) {
				modeState = UP_COUNTER;
				FND_SetDP(FND_DIGIT_100,OFF);
			}
			break;

		case UP_COUNTER:
			UpCounter_Execute();
			Disp_SetMode(DISP_UP_COUNTER);
			if (Button_GetState(&hbtnMode) == ACT_RELEASED) {
				modeState = TIME_CLOCK;
			}
			break;
		}
	}
}














