/*
 * I2C.c
 *
 *  Created on: 2026. 5. 4.
 *      Author: Eunsu Choi
 */

#include "I2C.h"

void I2C_Start() {
    while (I2C0->STATUS & I2C_STS_BUSY);

    I2C0->CONTROL = I2C_CMD_START;

    while ((I2C0->STATUS & I2C_STS_DONE) == 0);
}

void I2C_Stop() {
    while (I2C0->STATUS & I2C_STS_BUSY);
    I2C0->CONTROL = I2C_CMD_STOP;
    while ((I2C0->STATUS & I2C_STS_DONE) == 0);
}

uint8_t I2C_Write(uint8_t data) {
    while (I2C0->STATUS & I2C_STS_BUSY);

    I2C0->TX_DATA = data;
    I2C0->CONTROL = I2C_CMD_WRITE;

    while ((I2C0->STATUS & I2C_STS_DONE) == 0);

    return (I2C0->STATUS & I2C_STS_ACK) ? 1 : 0;
}


uint8_t I2C_Read(uint8_t ack) {
    while (I2C0->STATUS & I2C_STS_BUSY);

    if (ack == 1) {
        I2C0->CONTROL = I2C_CMD_READ | I2C_ACK_IN;
    } else {
        I2C0->CONTROL = I2C_CMD_READ;
    }

    while ((I2C0->STATUS & I2C_STS_DONE) == 0);

    return (uint8_t)(I2C0->RX_DATA);
}
