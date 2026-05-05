#include "FND.h"

uint8_t fndDpData = 0;
uint16_t fndNumData = 0;

static const uint8_t fndFont[16] = {0xc0, 0xf9, 0xa4, 0xb0, 0x99, 0x92, 0x82, 0xf8, 0x80, 0x90, 0x88, 0x83, 0xc6, 0xa1, 0x86, 0x8e};

void FND_Init() {
    GPIO_SetMode(FND_COM_PORT, FND_COM_DIG_1 | FND_COM_DIG_2 | FND_COM_DIG_3 | FND_COM_DIG_4, OUTPUT);
    GPIO_SetMode(FND_FONT_PORT, SEG_PIN_A | SEG_PIN_B | SEG_PIN_C | SEG_PIN_D | SEG_PIN_E | SEG_PIN_F | SEG_PIN_G | SEG_PIN_DP, OUTPUT);
}

void FND_SetComPort(GPIO_Typedef_t* FND_Port, uint32_t Seg_Pin, int ONOFF) {
    GPIO_WritePin(FND_Port, Seg_Pin, ONOFF);
}

// [개선 2] 논리 최적화: FND_DIGIT_x 매크로의 비트 속성(0x01, 0x02, 0x04, 0x08)을 활용해 if-else 노가다를 단 5줄로 압축!
void FND_SetDp(uint8_t digit, uint8_t on_off) {
    if (on_off == ON) {
        fndDpData |= digit;  // 해당 자릿수 비트 켜기
    } else {
        fndDpData &= ~digit;  // 해당 자릿수 비트 끄기
    }
}
// [개선 3] 헬퍼 함수 도입 (핵심): 중복되던 로직을 하나로 묶고, DP 출력까지 한 번에 합성 (오버헤드 제거)
static void FND_Write_Digit(uint32_t com_pin, uint8_t num, uint8_t digit_mask) {
    uint8_t fontData = fndFont[num];

    // DP 상태가 켜져있다면, 폰트 데이터에 DP 비트를 미리 합성시킵니다.
    if (fndDpData & digit_mask) {
        fontData &= ~SEG_PIN_DP;  // 소수점 불 켜기 (Active Low)
    }

    FND_DispAllOff();                           // 잔상 제거
    GPIO_WritePort(FND_FONT_PORT, fontData);    // 폰트+소수점이 합쳐진 데이터를 한 방에 쏨!
    FND_SetComPort(FND_COM_PORT, com_pin, ON);  // 자릿수 전원 인가
}

void FND_DispDigit() {
    static uint8_t fndDigState = 0;
    fndDigState = (fndDigState + 1) % 4;

    switch (fndDigState) {
        case 0:
            FND_DispDigit_1();
            break;
        case 1:
            FND_DispDigit_10();
            break;
        case 2:
            FND_DispDigit_100();
            break;
        case 3:
            FND_DispDigit_1000();
            break;
        default:
            FND_DispDigit_1();
            break;
    }
}

void FND_DispDigit_1() {
    FND_Write_Digit(FND_COM_DIG_1, fndNumData % 10, FND_DIGIT_1);
}

void FND_DispDigit_10() {
    FND_Write_Digit(FND_COM_DIG_2, (fndNumData / 10) % 10, FND_DIGIT_10);
}

void FND_DispDigit_100() {
    FND_Write_Digit(FND_COM_DIG_3, (fndNumData / 100) % 10, FND_DIGIT_100);
}

void FND_DispDigit_1000() {
    FND_Write_Digit(FND_COM_DIG_4, (fndNumData / 1000) % 10, FND_DIGIT_1000);
}

void FND_SetNum(uint16_t num) {
    fndNumData = num;
}

void FND_DispAllOn() {
    GPIO_WritePort(FND_FONT_PORT, 0x00);
    FND_SetComPort(FND_COM_PORT, FND_COM_DIG_1 | FND_COM_DIG_2 | FND_COM_DIG_3 | FND_COM_DIG_4, ON);
}

void FND_DispAllOff() {
    FND_SetComPort(FND_COM_PORT, FND_COM_DIG_1 | FND_COM_DIG_2 | FND_COM_DIG_3 | FND_COM_DIG_4, OFF);
    GPIO_WritePort(FND_FONT_PORT, 0xff);
}