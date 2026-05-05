
#ifndef SRC_AP_UPCOUNTER_UPCOUNTER_H_
#define SRC_AP_UPCOUNTER_UPCOUNTER_H_

#include "../../common/common.h"
#include "../../driver/BTN/BTN.h"
#include "../../driver/FND/FND.h"

typedef enum {
    STOP,
    RUN,
    CLEAR
} upcounter_state_t;

void UpCounter_Init();
void UpCounter_Excute();
void UpCounter_Run();
void UpCounter_Stop();
void UpCounter_Clear();

#endif /* SRC_AP_UPCOUNTER_UPCOUNTER_H_ */
