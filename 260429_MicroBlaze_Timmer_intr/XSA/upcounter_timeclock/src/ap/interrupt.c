/*
 * sys.c
 *
 *  Created on: 2026. 4. 29.
 *      Author: kccistc
 */

#include "interrupt.h"

XIntc IntrController;

void TMR1_ISR(void *CallbackRef) {
	xil_printf("1sec TIMER 1 ISR!\n");
}

void TMR2_ISR(void *CallbackRef) {
	xil_printf("2sec            TIMER 2 ISR!\n");

}

int SetupInterruptSystem() {
	int status;
// 1. interrupt controller Init
	status = XIntc_Initialize(&IntrController, INTC_DEV_ID);
	if (status != XST_SUCCESS) {
		return XST_FAILURE;
	}

// 2-1. TMR1_ISR connect with Intc
	status = XIntc_Connect(&IntrController, TMR1_DEV_ID,
			(XInterruptHandler) TMR1_ISR, (void *) 0);
	if (status != XST_SUCCESS) {
		return XST_FAILURE;
	}

// 2-2. TMR2_ISR connect with Intc
	status = XIntc_Connect(&IntrController, TMR2_DEV_ID,
			(XInterruptHandler) TMR2_ISR, (void *) 0);
	if (status != XST_SUCCESS) {
		return XST_FAILURE;
	}

// 3. Interrupt Controller start(Hardware Mode)
	status = XIntc_Start(&IntrController, XIN_REAL_MODE);
	if (status != XST_SUCCESS) {
		return XST_FAILURE;
	}

// 4. each interrupt channel activate
	XIntc_Enable(&IntrController, TMR1_DEV_ID);
	XIntc_Enable(&IntrController, TMR2_DEV_ID);

// 5. MicroBlaze's Exception Init and activate (entire thing)

	Xil_ExceptionInit();
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
			(Xil_ExceptionHandler) XIntc_InterruptHandler, &IntrController);
	Xil_ExceptionEnable();
	return XST_SUCCESS;

}
