#include "Watch.h"
#include <stdint.h>

Watch_state_t w_state = { 0, 0, 0, 0 };

void Watch_Init() {
	FND_Init();
	w_state.hour = 0;
	w_state.min = 0;
	w_state.sec = 0;
	w_state.msec = 0;
}

void Watch_Execute() {
	// 시계 무한 LOOP
	Watch_DispLoop();
	Watch_Run();
}

void Watch_DispLoop() {
	FND_DispDigit();
}

void Watch_Run() {
	static uint32_t Watch_Counter = 0;

	// 10ms(0.01초)마다 한 번씩 아래 로직을 실행
	if (millis() - Watch_Counter < 10) {
		return;
	}
	Watch_Counter = millis();

	w_state.msec++;                  // 10ms마다 msec 1 증가

	if (w_state.msec >= 100) {       // 10ms * 100 = 1000ms (1초)
		w_state.msec = 0;
		w_state.sec++;               // msec가 꽉 차면 sec 1 증가

		if (w_state.sec >= 60) {     // 60초가 되면
			w_state.sec = 0;
			w_state.min++;           // sec가 꽉 차면 min 1 증가

			if (w_state.min >= 60) { // 60분이 되면
				w_state.min = 0;
				w_state.hour++;      // min이 꽉 차면 hour 1 증가

				if (w_state.hour >= 24) { // 24시간이 되면 0시로 초기화
					w_state.hour = 0;
				}
			}
		}
		printf("%02d:%02d:%02d\r\n", w_state.hour, w_state.min, w_state.sec);
	}

	// 분(min) 값을 백의 자리와 천의 자리로 올리고, 초(sec)를 더해 4자리 숫자로 만듦.
	uint16_t FND_data = (w_state.min * 100) + w_state.sec;
	FND_SetNum(FND_data);

	// 0~99까지 반복되는 msec 값을 활용하여 0.5초(50) 단위로 점멸을 제어
	if (w_state.msec < 50) {
		FND_DP_ON();   // 0 ~ 49 구간: 점 켜기
	} else {
		FND_DP_OFF(); // 50 ~ 99 구간: 점 끄기
	}
}
