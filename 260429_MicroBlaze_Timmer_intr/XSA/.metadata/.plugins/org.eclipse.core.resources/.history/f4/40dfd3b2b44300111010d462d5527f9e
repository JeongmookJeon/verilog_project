#include "xil_printf.h"

#include "ap_main.h"
#include "../common/common.h"
#include "UpCounter/UpCounter.h"
#include "../HAL/TMR/TMR.h"
#include "interrupt.h"


void ap_init() {
   UpCounter_Init();
   SetupInterruptSystem();

   //TMR1->PSC = 100 - 1; // 1MHz의 tick 발생
   //TMR1->ARR = 1000000 - 1; // 1sec 마다 한 번씩 발생
   //TMR1->CR |= 1 << 2; //TMR_intr_en
   //TMR1->CR |= 1 << 0; //TMR_en

   TMR_SetPSC(TMR1, 100 - 1);
   TMR_SetARR(TMR1, 1000000 - 1);
   TMR_StartIntr(TMR1);
   TMR_StartTimer(TMR1);

   //TMR2->PSC = 100 - 1; // 1MHz의 tick 발생
   //TMR2->ARR = 2000000 - 1; // 2sec 마다 한 번씩 발생
   //TMR2->CR |= 1 << 2; //TMR_intr_en
   //TMR2->CR |= 1 << 0; //TMR_en

   TMR_SetPSC(TMR2, 100 - 1);
   TMR_SetARR(TMR2, 2000000 - 1);
   TMR_StartIntr(TMR2);
   TMR_StartTimer(TMR2);
}

void ap_excute() {
   while (1) {
      UpCounter_Excute();

      millis_inc();
      delay_ms(1);
   }
}
