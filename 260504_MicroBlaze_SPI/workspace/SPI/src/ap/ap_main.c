#include "xil_printf.h"

#include "ap_main.h"
#include "../HAL/TMR/TMR.h"
//#include "../common/common.h"
#include "interrupt.h"
#include "../driver/Button/Button.h"
#include "../driver/LED/LED.h"
#include "../driver/SW/SW.h"
#include "../driver/SPI_D/SPI_D.h"
#include "../HAL/SPI/SPI.h"

hBtn_t hbtnSend;
uint8_t Master_Data = 0;
uint8_t Slave_Data = 0;

void ap_init() {
	LED_Init();
	SW_Init();
	Button_Init(&hbtnSend, GPIOA, GPIO_PIN_5);
	SPI_SetCR(SPI, 64, 0, 0);
	//인터럽트에 대한 시스템 설정
	SetupInterruptSystem();

	//TMR0는 인터럽트는 안하고 카운트만 하도록
	//1mhz -> 1us 간격으로 count 증가, 인터럽트 발생 안됨
	//인터럽트 스탑을 사용했기 때문
	TMR_SetPSC(TMR0, 100 - 1);
	TMR_SetARR(TMR0, 0xffffffff);
	//ARR이 최대값까지 가고 자동으로 overflow 발생해서 0으로 떨어짐
	//제한 없이 끝까지 가겠다는 의미
	//이걸로 delay_ms 대체 사용
	TMR_StopIntr(TMR0);
	TMR_StartTimer(TMR0);

	//1khz->1ms 간격으로 인터럽트 발생
	TMR_SetPSC(TMR1, 100 - 1);
	TMR_SetARR(TMR1, 1000 - 1);
	TMR_StartIntr(TMR1);
	TMR_StartTimer(TMR1);

	//100hz -> 10ms 간격으로 인터럽트 발생
	TMR_SetPSC(TMR2, 100 - 1);
	TMR_SetARR(TMR2, 10000 - 1);
	TMR_StartIntr(TMR2);
	TMR_StartTimer(TMR2);

}

void ap_excute() {
	while (1) {
		Master_Data = SW_ReadData(GPIOB);

		if (Button_GetState(&hbtnSend) == ACT_PUSHED) {
			xil_printf("1. Button Clicked!\n"); // 버튼이 잘 눌리는지 확인
			Slave_Data = SPI_Transfer(SPI, Master_Data);

			xil_printf("2. SPI Transfer Done!\n"); // 통신 함수를 무사히 빠져나왔는지 확인
			LED_WriteData(LED_PORT, Slave_Data);
			xil_printf("3. SPI LED_WriteData Done!\n");
		}

	}
}
