/*
 * FND.c
 *
 *  Created on: 2026. 4. 28.
 *      Author: kccistc
 */

#include "FND.h"

uint16_t fndNumData = 0;
//DP 출력을 갖고 있는 데이터
uint16_t fndDpData = 0;

static int fnd_dp_state = OFF;

//변환
uint8_t fndFont[16] = { 0xc0, 0xf9, 0xa4, 0xb0, 0x99, 0x92, 0x82, 0xf8, 0x80,
		0x90, 0x88, 0x83, 0xc6, 0xa1, 0x86, 0x8e };

void FND_Init() {
	//GPIO에 대한 선언, GPIOA0, 1, 2, 3 COM 연결
	GPIO_SetMode(FND_COM_PORT,
	FND_COM_DIG_1 | FND_COM_DIG_2 | FND_COM_DIG_3 | FND_COM_DIG_4,
	OUTPUT);
	//GPIO에 대한 선언, GPIOB segment abcdefg,dp 연결
	GPIO_SetMode(FND_FONT_PORT,
			SEG_PIN_A | SEG_PIN_B | SEG_PIN_C | SEG_PIN_D | SEG_PIN_E
					| SEG_PIN_F | SEG_PIN_G | SEG_PIN_DP, OUTPUT);
}

void FND_SetComPort(GPIO_Typedef_t *FND_Port, uint32_t Seg_Pin, int OnOFF) {
	GPIO_WritePin(FND_Port, Seg_Pin, OnOFF);
}

void FND_Digit() {

	static uint8_t fndDigState = 0;
	fndDigState = (fndDigState + 1) % 4;

	switch (fndDigState) {
	case 0:
		FND_Digit_1();
		FND_DispDP(FND_DIGIT_1);
		break;
	case 1:
		FND_Digit_10();
		FND_DispDP(FND_DIGIT_10);
		break;
	case 2:
		FND_Digit_100();
		FND_DispDP(FND_DIGIT_100);
		break;
	case 3:
		FND_Digit_1000();
		FND_DispDP(FND_DIGIT_1000);
		break;
	default:
		FND_Digit_1();
		break;
	}
}

void FND_Digit_1() {

	// num의 자리수 분리
	uint8_t digitData1 = fndNumData % 10;
	FND_DispAllOff();
	GPIO_WritePort(FND_FONT_PORT, fndFont[digitData1]);
	FND_SetComPort(FND_COM_PORT, FND_COM_DIG_1, ON);
}

void FND_Digit_10() {
	// num의 자리수 분리
	uint8_t digitData10 = (fndNumData / 10) % 10;
	FND_DispAllOff();
	GPIO_WritePort(FND_FONT_PORT, fndFont[digitData10]);
	FND_SetComPort(FND_COM_PORT, FND_COM_DIG_2, ON);
}

void FND_Digit_100() {
	// num의 자리수 분리

	uint8_t digitData100 = fndNumData / 100 % 10;

	uint8_t fontData = fndFont[digitData100];

	if (fnd_dp_state == ON) {
		fontData &= ~SEG_PIN_DP;
	}

	FND_DispAllOff();
	GPIO_WritePort(FND_FONT_PORT, fontData);
	FND_SetComPort(FND_COM_PORT, FND_COM_DIG_3, ON);
}

void FND_Digit_1000() {
	// num의 자리수 분리
	uint8_t digitData1000 = (fndNumData / 1000) % 10;
	FND_DispAllOff();
	GPIO_WritePort(FND_FONT_PORT, fndFont[digitData1000]);
	FND_SetComPort(FND_COM_PORT, FND_COM_DIG_4, ON);
}

void FND_SetDP(uint8_t digit, uint8_t on_off) {
	if (digit == FND_DIGIT_1) {
		if (!on_off)
			fndDpData |= 1 << 0;
		else
			fndDpData &= ~(1 << 0);
	} else if (digit == FND_DIGIT_10) {
		if (!on_off)
			fndDpData |= 1 << 1;
		else
			fndDpData &= ~(1 << 1);
	} else if (digit == FND_DIGIT_100) {
		if (!on_off)
			fndDpData |= 1 << 2;
		else
			fndDpData &= ~(1 << 2);
	} else if (digit == FND_DIGIT_1000) {
		if (!on_off)
			fndDpData |= 1 << 3;
		else
			fndDpData &= ~(1 << 3);
	}

}

void FND_DispDP(uint8_t digit) {
	if (fndDpData & digit) {
		GPIO_WritePin(FND_FONT_PORT, SEG_PIN_DP, RESET);
	} else {
		GPIO_WritePin(FND_FONT_PORT, SEG_PIN_DP, SET);
	}
}

//실제로 많이 사용하게 될 부분
void FND_SetNum(uint16_t num) {
	fndNumData = num;
}
void FND_DispAllOn() {
	GPIO_WritePort(FND_FONT_PORT, 0x00);
	FND_SetComPort(FND_COM_PORT,
	FND_COM_DIG_1 | FND_COM_DIG_2 | FND_COM_DIG_3 | FND_COM_DIG_4, ON);
}
void FND_DispAllOff() {
	FND_SetComPort(FND_COM_PORT,
	FND_COM_DIG_1 | FND_COM_DIG_2 | FND_COM_DIG_3 | FND_COM_DIG_4, OFF);
	GPIO_WritePort(FND_FONT_PORT, 0xff);
	//fndDpData=0x00;
}

