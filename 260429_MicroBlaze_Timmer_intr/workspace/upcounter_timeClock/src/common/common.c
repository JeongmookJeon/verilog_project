/*
 * common.c
 *
 *  Created on: 2026. 4. 28.
 *      Author: kccistc
 */
#include "common.h"

uint32_t millis_tick = 0;

uint32_t millis() {
	return millis_tick;
}

//1ms 간격마다 1씩 증가
void millis_inc() {
	millis_tick++;
}

void delay_ms(uint32_t msec)
{
	//usleep(msec*1000);
	delay_us(msec*1000);
}

//딜레이는 카운터 이용
void delay_us(uint32_t usec)
{
	uint32_t prevtimer = TMR_GetCNT(TMR0);

	while (TMR_GetCNT(TMR0) - prevtimer < usec);

	//usleep(usec);
}


