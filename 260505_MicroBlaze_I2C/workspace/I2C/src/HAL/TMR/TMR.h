/*
 * TMR.h
 *
 *  Created on: 2026. 4. 29.
 *      Author: kccistc
 */

#ifndef SRC_HAL_TMR_TMR_H_
#define SRC_HAL_TMR_TMR_H_

#include <stdint.h>

#include "xparameters.h"

typedef struct {
    volatile uint32_t CR;
    volatile uint32_t PSC;
    volatile uint32_t ARR;
    volatile uint32_t CNT;
} TMR_Typedef_t;

#define TMR0_BASEADDR XPAR_TMR_0_S00_AXI_BASEADDR


#define TMR0 ((TMR_Typedef_t*)(TMR0_BASEADDR))

#define TMR_ENABLE_BIT 0
#define TMR_CLEAR_BIT 1
#define TMR_INTR_BIT 2

void TMR_SetPSC(TMR_Typedef_t* TMRx, uint32_t psc);
void TMR_SetARR(TMR_Typedef_t* TMRx, uint32_t arr);
void TMR_StartIntr(TMR_Typedef_t* TMRx);
void TMR_StopIntr(TMR_Typedef_t* TMRx);
void TMR_StartTimer(TMR_Typedef_t* TMRx);
void TMR_StopTimer(TMR_Typedef_t* TMRx);
void TMR_ClearTimer(TMR_Typedef_t* TMRx);
uint32_t TMR_GetCNT(TMR_Typedef_t* TMRx);

#endif /* SRC_HAL_TMR_TMR_H_ */
