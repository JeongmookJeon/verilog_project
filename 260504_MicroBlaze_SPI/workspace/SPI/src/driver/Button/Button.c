/*
 * Button.c
 *
 *  Created on: 2026. 4. 28.
 *      Author: kccistc
 */

#include "Button.h"


void Button_Init(hBtn_t*hbtn, GPIO_Typedef_t *GPIOx, uint32_t GPIO_Pin)
{
	// 받아온 핀만 골라서 INPUT으로 설정합니다.
	    GPIO_SetMode(GPIOx, GPIO_Pin, INPUT);

	    // 하드코딩을 지우고, 넘겨받은 구조체 포인터(hbtn)에 직접 값을 세팅합니다.
	    hbtn->GPIOx = GPIOx;
	    hbtn->GPIO_Pin = GPIO_Pin;
	    hbtn->prevState = RELEASED;

}

button_act_t Button_GetState(hBtn_t *hbtn)
{
   //static button_state_t prevState = RELEASED;
   button_state_t curState = GPIO_ReadPin(hbtn->GPIOx, hbtn->GPIO_Pin);
   if(hbtn->prevState == RELEASED && curState == PUSHED){
      delay_ms(1); //debounce
      hbtn->prevState = PUSHED;
      return ACT_PUSHED;
   }
   else if (hbtn->prevState == PUSHED && curState == RELEASED){
      delay_ms(1);
      hbtn->prevState = RELEASED;
      return ACT_RELEASED;
   }
   return NO_ACT;
}
