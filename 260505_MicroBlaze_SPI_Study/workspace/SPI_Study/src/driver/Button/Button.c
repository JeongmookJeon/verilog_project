#include "Button.h"

#include "../../HAL/GPIO/GPIO.h"
#include "../../common/common.h"

typedef enum {
   RELEASED = 0,
   PUSHED
}button_state_t;

typedef enum {
	NO_ACT = 0,
   ACT_RELEASED,
   ACT_PUSHED
}button_act_t;

typedef struct {
	GPIO_Typedef_t * GPIOx;
	uint32_t GPIO_Pin;
	button_state_t prevState;
}hBtn_t;

void Button_Init(hBtn_t*hbtn, GPIO_Typedef_t * GPIOx, uint32_t GPIO_Pin)
{
	// 받아온 핀만 골라서 INPUT으로 설정합니다.
	    GPIO_SetMode(GPIOx, GPIO_Pin, INPUT);

	    // 하드코딩을 지우고, 넘겨받은 구조체 포인터(hbtn)에 직접 값을 세팅합니다.
	    hbtn->GPIOx = GPIOx;
	    hbtn->GPIO_Pin = GPIO_Pin;
	    hbtn->prevState = RELEASED;

}
