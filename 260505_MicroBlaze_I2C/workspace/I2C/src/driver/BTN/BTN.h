
#ifndef SRC_DRIVER_BTN_BTN_H_
#define SRC_DRIVER_BTN_BTN_H_

#include "../../HAL/GPIO/GPIO.h"
#include "../../common/common.h"

typedef enum {
    RELEASED = 0,
    PUSHED
} button_state_t;

typedef enum {
    NO_ACT = 0,
    ACT_RELEASED,
    ACT_PUSHED
} button_act_t;

typedef struct {
    GPIO_Typedef_t* GPIOx;
    uint32_t GPIO_Pin;
    button_state_t prevState;

    button_state_t lastRawState;
    uint32_t lastDebounceTime;
} hBtn_t;

void Button_Init(hBtn_t* hbtn, GPIO_Typedef_t* GPIOx, uint32_t GPIO_Pin);
button_act_t Button_GetState(hBtn_t* hbtn);

#endif /* SRC_DRIVER_BTN_BTN_H_ */
