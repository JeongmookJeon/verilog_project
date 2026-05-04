/*
 * Clock.c
 *
 *  Created on: 2026. 4. 30.
 *      Author: kccistc
 */

#include "Clock.h"

hBtn_t hBtnHMSMs;

FNDMode_State_t CurMode = SecMsec;
timeClock_t timeClock;

void TimeClock_Init() {
   TimeClock_SetTime(12, 0, 0, 0);
   Button_Init(&hBtnHMSMs, GPIOA, GPIO_PIN_6);
}

void TimeClock_SetTime(uint8_t hh, uint8_t mm, uint8_t ss, uint8_t ms) {
   timeClock.hour = hh;
   timeClock.min = mm;
   timeClock.sec = ss;
   timeClock.msec = ms;
}

void TimeClock_Excute() {
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

   if (Button_GetState(&hBtnHMSMs) == ACT_PUSHED) {
      if (CurMode == SecMsec) {
         CurMode = HourMin;
      } else {
         CurMode = SecMsec;
      }
   }
   if (CurMode == SecMsec) {
      TimeClock_DispSecMSec();
   } else if (CurMode == HourMin) {
      TimeClock_DispHourMin();
   }

   if (timeClock.msec < 50) {
      FND_SetDP(FND_DIGIT_100, ON);
   } else {
      FND_SetDP(FND_DIGIT_100, OFF);
   }

}

void TimeClock_DispHourMin() {
   uint16_t timeNum;

   timeNum = timeClock.hour * 100 + timeClock.min;

   FND_SetNum(timeNum);
}

void TimeClock_DispSecMSec() {
   uint16_t timeNum;

   timeNum = timeClock.sec * 100 + timeClock.msec;

   FND_SetNum(timeNum);

}

