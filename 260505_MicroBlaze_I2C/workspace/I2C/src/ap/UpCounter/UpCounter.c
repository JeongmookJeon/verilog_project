

#include "UpCounter.h"

static hBtn_t hBtnRunStop, hBtnClear;
static uint16_t counter = 0;

void UpCounter_Init() {
    FND_Init();
    Button_Init(&hBtnRunStop, GPIOA, GPIO_PIN_4);
    Button_Init(&hBtnClear, GPIOA, GPIO_PIN_7);

    counter = 0;
}

void UpCounter_Excute() {
    static upcounter_state_t upCounterState = STOP;

    switch (upCounterState) {
        case STOP:
            UpCounter_Stop();
            if (Button_GetState(&hBtnRunStop) == ACT_PUSHED) {
                upCounterState = RUN;
            } else if (Button_GetState(&hBtnClear) == ACT_PUSHED) {
                upCounterState = CLEAR;
            }
            break;
        case RUN:
            UpCounter_Run();
            if (Button_GetState(&hBtnRunStop) == ACT_PUSHED) {
                upCounterState = STOP;
            }
            break;
        case CLEAR:
            UpCounter_Clear();
            upCounterState = STOP;
            break;
        default:
            UpCounter_Stop();
            break;
    }
}

void UpCounter_Run() {
    static uint32_t prevTimeCounter = 0;
    if (millis() - prevTimeCounter < 100 - 1) {
        return;
    }
    prevTimeCounter = millis();
    FND_SetNum(counter++);
}

void UpCounter_Stop() {
    FND_SetNum(counter);
}

void UpCounter_Clear() {
    counter = 0;
    FND_SetNum(counter);
}
