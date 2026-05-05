/*
 * interrupt.c
 *
 *  Created on: 2026. 4. 29.
 *      Author: kccistc
 */

#include "interrupt.h"

#include "../driver/FND/FND.h"

XIntc IntrController;

// 1Khz -> 1msec interrupt service routine
void TMR0_ISR(void* CallbackRef) {
    millis_inc();
    //FND_DispDigit();
    TMR_ClearTimer(TMR0);
}

int SetUpInterruptSystem() {
    int status;
    // 1. interrupt controller reset
    status = XIntc_Initialize(&IntrController, INTC_DEV_ID);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }
    // 2-1. connect Intc wit
    //h TMR1_ISR function
    status = XIntc_Connect(&IntrController, TMR0_DEV_ID,
                           (XInterruptHandler)TMR0_ISR, (void*)0);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    // 3. Interrupt Controller start (Hardware Mode)
    status = XIntc_Start(&IntrController, XIN_REAL_MODE);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }
    // 4. active gakgak's interrupt channel
    XIntc_Enable(&IntrController, TMR0_DEV_ID);


    // 5. reset and actice MicroBlaze's Exception
    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
                                 (Xil_ExceptionHandler)XIntc_InterruptHandler, &IntrController);
    Xil_ExceptionEnable();

    return XST_SUCCESS;
}
