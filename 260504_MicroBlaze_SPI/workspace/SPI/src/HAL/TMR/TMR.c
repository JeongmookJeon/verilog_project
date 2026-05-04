/*
 * TMR.c
 *
 *  Created on: 2026. 4. 29.
 *      Author: kccistc
 */

#include "TMR.h"

//카운트 값 읽는 것
uint32_t TMR_GetCNT (TMR_Typedef_t *TMRx)
{
	return TMRx->CNT;
}

void TMR_SetPSC(TMR_Typedef_t *TMRx, uint32_t psc)
{
	TMRx->PSC = psc;
}

void TMR_SetARR(TMR_Typedef_t *TMRx, uint32_t arr)
{
	TMRx->ARR = arr;
}
void TMR_StartIntr(TMR_Typedef_t *TMRx)
{
	TMRx->CR |= 1 << TMR_INTR_BIT;
}
void TMR_StopIntr(TMR_Typedef_t *TMRx)
{
	TMRx->CR &= ~(1 << TMR_INTR_BIT);
}
void TMR_StartTimer(TMR_Typedef_t *TMRx)
{
	TMRx->CR |= 1 << TMR_ENABLE_BIT;
}
void TMR_StopTimer(TMR_Typedef_t *TMRx)
{
	TMRx->CR &= ~(1 << TMR_ENABLE_BIT);
}
void TMR_ClearTimer(TMR_Typedef_t *TMRx)
{
	TMRx->CR |= 1 << TMR_CLEAR_BIT;
	TMRx->CR &= ~(1 << TMR_CLEAR_BIT);
}
