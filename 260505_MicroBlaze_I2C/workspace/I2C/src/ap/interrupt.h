/*
 * interrupt.h
 *
 *  Created on: 2026. 4. 29.
 *      Author: kccistc
 */

#ifndef SRC_AP_INTERRUPT_H_
#define SRC_AP_INTERRUPT_H_

#include "../common/common.h"
#include "TimeClock/TimeClock.h"
#include "UpCounter/UpCounter.h"
#include "xil_exception.h"
#include "xintc.h"
#include "xparameters.h"

#define INTC_DEV_ID XPAR_INTC_0_DEVICE_ID
#define TMR0_DEV_ID XPAR_TMR_0_DEVICE_ID

void TMR0_ISR(void* CallbackRef);
int SetUpInterruptSystem();

#endif /* SRC_AP_INTERRUPT_H_ */
