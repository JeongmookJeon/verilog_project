#include "ap_main.h"
#include "../driver/BTN/BTN.h"
#include "../driver/LED/LED.h"
#include "../HAL/I2C/I2C.h"
#include "interrupt.h"
#include "sleep.h"

hBtn_t btn_up;
hLed_t leds[8];
uint8_t up_count = 0;

#define SLAVE_ADDR_WRITE 0x24
#define SLAVE_ADDR_READ  0x25

void ap_init() {
    Button_Init(&btn_up, GPIOA, GPIO_PIN_0);
    for(int i=0; i<8; i++) {
        LED_Init(&leds[i], GPIOB, (1 << i));
    }

    SetUpInterruptSystem();
    TMR_SetPSC(TMR0, 0);
    TMR_SetARR(TMR0, 99999);
    TMR_StartIntr(TMR0);
    TMR_StartTimer(TMR0);
}

void ap_main() {
    ap_init();

    while(1) {

        if (Button_GetState(&btn_up) == ACT_PUSHED) {
            up_count++;

            I2C_Start();
            I2C_Write(SLAVE_ADDR_WRITE);
            I2C_Write(up_count);
            I2C_Stop();
        }

        I2C_Start();

        if (I2C_Write(SLAVE_ADDR_READ) == 0) {
            uint8_t slave_sw = I2C_Read(1);
            I2C_Stop();

            for(int i=0; i<8; i++) {
                if((slave_sw >> i) & 0x01) LED_On(&leds[i]);
                else LED_Off(&leds[i]);
            }
        } else {
            I2C_Stop();
        }

        usleep(10000);
    }
}
