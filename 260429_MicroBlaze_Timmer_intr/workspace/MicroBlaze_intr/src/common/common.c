#include "common.h"

uint32_t millis_tick = 0;

uint32_t millis() {
	return millis_tick;
}

void millis_inc() {
	millis_tick++;
}

void delay_ms(uint32_t msec) {
	delay_us(msec * 1000);
}

void delay_us(uint32_t usec) {
	uint32_t prevtimer = TMR_GetCNT(TMR0);
	while (TMR_GetCNT(TMR0) - prevtimer < usec);
}
