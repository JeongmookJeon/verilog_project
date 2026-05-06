
#ifndef SRC_AP_DISPSERVICE_DISPSERVICE_H_
#define SRC_AP_DISPSERVICE_DISPSERVICE_H_

enum {DISP_TIME_CLOCK, DISP_UP_COUNTER};
enum {DISP_TIME_HHMM, DISP_TIME_SSMS};

#include "../../driver/FND/FND.h"
#include "../../driver/LED/LED.h"

void Disp_SetMode(int mode);
void Disp_SetTimeMode(int mode);
void Disp_Init();


void Disp_UpCounter(uint16_t num);
void Disp_TimeClock(uint16_t num);
void Disp_ISR_Execute();
void Disp_ShiftLed(int mode);

#endif /* SRC_AP_DISPSERVICE_DISPSERVICE_H_ */
