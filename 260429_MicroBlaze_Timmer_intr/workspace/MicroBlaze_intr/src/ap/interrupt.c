#include "interrupt.h"

XIntc IntrController;

// 1khz > 1msec interrupt service routine
void TMR1_ISR(void *CallbackRef) {
	millis_inc();
	Disp_ISR_Execute();
	//UpCounter_DispLoop();
}

// 10msec interrupt service routine
void TMR2_ISR(void *CallbackRef) {
	TimeClock_IncTime();
}


void TMR0_Init()
{
	// 1Mhz > 1usec increase count , no interrupt
	TMR_SetPSC(TMR0, 100 - 1);
	TMR_SetARR(TMR0, 0xffffffff);
	TMR_StopIntr(TMR0);
	TMR_StartTimer(TMR0);
}

void TMR1_Init()
{
	// 1khz > 1msec interrupt
	TMR_SetPSC(TMR1, 100 - 1);
	TMR_SetARR(TMR1, 1000 - 1);
	TMR_StartIntr(TMR1);
	TMR_StartTimer(TMR1);
}

void TMR2_Init()
{
	// 100hz > 10msec interrupt
	TMR_SetPSC(TMR2, 100 - 1);
	TMR_SetARR(TMR2, 10000 - 1);
	TMR_StartIntr(TMR2);
	TMR_StartTimer(TMR2);
}

int SetupInterruptSystem() {
	int status;

	// 1. initialize interrupt controller
	status = XIntc_Initialize(&IntrController, INTC_DEV_ID);
	if (status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	// 2-1. connect TMR1_ISR function with Intc
	status = XIntc_Connect(&IntrController, TMR1_DEV_ID,
			(XInterruptHandler) TMR1_ISR, (void *) 0);
	if (status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	// 2-2. connect TMR2_ISR function with Intc
	status = XIntc_Connect(&IntrController, TMR2_DEV_ID,
			(XInterruptHandler) TMR2_ISR, (void *) 0);
	if (status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	// 3. start interrupt controller(HW MODE)
	status = XIntc_Start(&IntrController, XIN_REAL_MODE);
	if (status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	// 4. activate each interrupt channel
	XIntc_Enable(&IntrController, TMR1_DEV_ID);
	XIntc_Enable(&IntrController, TMR2_DEV_ID);

	// 5. Initialize and activate Exception of MicroBlaze
	Xil_ExceptionInit();
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
			(Xil_ExceptionHandler) XIntc_InterruptHandler, &IntrController);
	Xil_ExceptionEnable();

	return XST_SUCCESS;
}
