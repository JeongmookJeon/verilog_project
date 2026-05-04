/*
 * TMR.h
 *
 *  Created on: 2026. 4. 29.
 *      Author: kccistc
 */

#ifndef SRC_HAL_TMR_TMR_H_
#define SRC_HAL_TMR_TMR_H_

#include "xparameters.h"
#include <stdint.h>

typedef struct {
	uint32_t CR;
	uint32_t PSC;
	uint32_t ARR;
	uint32_t CNT;
}TMR_Typedef_f;

#define TMR0_BASEADDR XPAR_TMR_0_S00_AXI_BASEADDR
#define TMR1_BASEADDR XPAR_TMR_1_S00_AXI_BASEADDR
#define TMR2_BASEADDR XPAR_TMR_2_S00_AXI_BASEADDR

#define TMR0 ((TMR_Typedef_f *)(TMR0_BASEADDR))
#define TMR1 ((TMR_Typedef_f *)(TMR1_BASEADDR))
#define TMR2 ((TMR_Typedef_f *)(TMR2_BASEADDR))

#define TMR_ENABLE_BIT 0
#define TMR_CLEAR_BIT 1
#define TMR_INTR_BIT 2

uint32_t TMR_GetCNT (TMR_Typedef_f *TMRx);
void TMR_SetPSC(TMR_Typedef_f *TMRx, uint32_t psc);
void TMR_SetARR(TMR_Typedef_f *TMRx, uint32_t arr);
void TMR_StartIntr(TMR_Typedef_f *TMRx);
void TMR_StopIntr(TMR_Typedef_f *TMRx);
void TMR_StartTimer(TMR_Typedef_f *TMRx);
void TMR_StopTimer(TMR_Typedef_f *TMRx);
void TMR_ClearTimer(TMR_Typedef_f *TMRx);


#endif /* SRC_HAL_TMR_TMR_H_ */
