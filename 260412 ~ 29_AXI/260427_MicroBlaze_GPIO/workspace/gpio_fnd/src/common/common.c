#include "common.h"

uint32_t millis_tick=0;


uint32_t millis()
{
	return millis_tick;
}

void millis_inc()
{
	millis_tick++;
}
void delay_ms(uint32_t msec)
{
	usleep(msec*1000);
}

void delay_us(uint32_t usec)
{
	usleep(usec);
}
