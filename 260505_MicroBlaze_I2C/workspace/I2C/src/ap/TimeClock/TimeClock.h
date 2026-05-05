/*
 * TimeClock.h
 *
 *  Created on: 2026. 4. 30.
 *      Author: kccistc
 */

#ifndef SRC_AP_TIMECLOCK_TIMECLOCK_H_
#define SRC_AP_TIMECLOCK_TIMECLOCK_H_

#include <stdint.h>

#include "../../driver/FND/FND.h"

typedef struct {
    uint8_t hour;
    uint8_t min;
    uint8_t sec;
    uint8_t msec;
} timeClock_t;

void TimeClock_Init();
void TimeClock_SetTime(uint8_t hh, uint8_t mm, uint8_t ss, uint8_t ms);
void TimeClock_Excute();
void TimeClock_IncTime();
void TimeClock_DispTime();
void TimeClock_DispHourMin();
void TimeClock_DispSecMSec();

#endif /* SRC_AP_TIMECLOCK_TIMECLOCK_H_ */
