/*
 * SPI_D.c
 *
 *  Created on: 2026. 5. 4.
 *      Author: kccistc
 */

#include "SPI_D.h"
#include "../../HAL/SPI/SPI.h"

//HAL 단에 추가된 만능 함수
uint8_t SPI_Transfer(SPI_Typedef_t *SPIx, uint8_t tx_data) {

	uint8_t rx_val; // 받은 데이터를 잠시 저장할 변수

	SPI_SetTX(SPIx, tx_data);          // 1. 데이터 장전

	SPI_Start(SPIx, 1);                // 2. 통신 시작! (Start 버튼 꾹 누름)
	while (SPI_GetRX_Busy(SPIx) == 0);
	//while (SPI_GetRX_Done(SPIx) == 1); // 3. 하드웨어가 "다 보냈어!" 할 때까지 대기

	SPI_Start(SPIx, 0);                // 5. 다음 통신을 위해 Start 버튼 손 떼기 (초기화)
	while (SPI_GetRX_Busy(SPIx) == 1);

	rx_val = SPI_GetRX_Data(SPIx);     // 4. 통신 완료 깃발을 확인했으니, 수신된 데이터 꺼내기
	return rx_val;                     // 6. 꺼낸 데이터 반환

	//SPI_SetTX(SPIx, tx_data);          // 데이터 장전
	//SPI_Start(SPIx, 1);                // 시작 펄스 1
	//SPI_Start(SPIx, 0);                // 시작 펄스 0
	//while (SPI_GetRX_Done(SPIx) == 0); // 하드웨어 완료 대기
	//return SPI_GetRX_Data(SPIx);       // 받은 데이터 반환
}
