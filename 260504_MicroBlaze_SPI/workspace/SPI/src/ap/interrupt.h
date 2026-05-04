/*
 * interrupt.h
 *
 *  Created on: 2026. 4. 29.
 *      Author: kccistc
 */

#ifndef SRC_AP_INTERRUPT_H_
#define SRC_AP_INTERRUPT_H_

#include "xparameters.h"
#include "xintc.h"
#include "xil_exception.h"
#include "../common/common.h"

#define INTC_DEV_ID XPAR_INTC_0_DEVICE_ID
#define TMR1_DEV_ID XPAR_TMR_1_DEVICE_ID
#define TMR2_DEV_ID XPAR_TMR_2_DEVICE_ID

void TMR1_ISR(void *CallbackRef);
void TMR2_ISR(void *CallbackRef);
int SetupInterruptSystem();

#endif /* SRC_AP_INTERRUPT_H_ */
