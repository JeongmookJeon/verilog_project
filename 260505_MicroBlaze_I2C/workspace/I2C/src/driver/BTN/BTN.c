#include "BTN.h"

void Button_Init(hBtn_t* hbtn, GPIO_Typedef_t* GPIOx, uint32_t GPIO_Pin) {
    GPIO_SetMode(GPIOx, GPIO_Pin, INPUT);

    hbtn->GPIOx = GPIOx;
    hbtn->GPIO_Pin = GPIO_Pin;
    hbtn->prevState = RELEASED;
    hbtn->lastRawState = RELEASED;
    hbtn->lastDebounceTime = 0;
}

button_act_t Button_GetState(hBtn_t* hbtn) {
    button_state_t curState = GPIO_ReadPin(hbtn->GPIOx, hbtn->GPIO_Pin);

    if (curState != hbtn->lastRawState) {
        hbtn->lastDebounceTime = millis();
    }

    hbtn->lastRawState = curState;

    if ((millis() - hbtn->lastDebounceTime) > 20) {

        if (curState != hbtn->prevState) {
            hbtn->prevState = curState;

            if (curState == PUSHED) {
                return ACT_PUSHED;
            } else if (curState == RELEASED) {
                return ACT_RELEASED;
            }
        }
    }
    return NO_ACT;
}
