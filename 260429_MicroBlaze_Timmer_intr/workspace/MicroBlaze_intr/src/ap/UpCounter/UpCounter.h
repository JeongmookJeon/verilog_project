
#ifndef SRC_AP_UPCOUNTER_UPCOUNTER_H_
#define SRC_AP_UPCOUNTER_UPCOUNTER_H_

#include "../../driver/FND/FND.h"
#include "../../driver/Button/Button.h"
#include "../../driver/LED/LED.h"
#include "../../common/common.h"
#include "../DispService/DispService.h"

typedef enum {
	STOP = 0,
	RUN,
	CLEAR
}upcounter_state_t;

void UpCounter_Init();
void UpCounter_Execute();
void UpCounter_DispLoop();
void UpCounter_Run();
void UpCounter_Stop();
void UpCounter_Clear();

#endif /* SRC_AP_UPCOUNTER_UPCOUNTER_H_ */
