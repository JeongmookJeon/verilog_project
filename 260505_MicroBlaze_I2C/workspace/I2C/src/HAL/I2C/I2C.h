/*
 * I2C.h
 *
 *  Created on: 2026. 5. 4.
 *      Author: Eunsu Choi
 */

#ifndef SRC_HAL_I2C_I2C_H_
#define SRC_HAL_I2C_I2C_H_

#include <stdint.h>
#include "xil_io.h"

typedef struct {
    volatile uint32_t CONTROL; // cmd_start, cmd_write, cmd_read, cmd_stop, ack_in
    volatile uint32_t TX_DATA;
    volatile uint32_t RX_DATA;
    volatile uint32_t STATUS;  // busy, done_real, ack_out
} I2C_Typedef_t;

#define I2C_BASE_ADDR 0x44A20000
#define I2C0 ((I2C_Typedef_t*)I2C_BASE_ADDR)

#define I2C_CMD_START 0x01
#define I2C_CMD_WRITE 0x02
#define I2C_CMD_READ  0x04
#define I2C_CMD_STOP  0x08
#define I2C_ACK_IN    0x10

#define I2C_STS_BUSY  0x01
#define I2C_STS_DONE  0x02
#define I2C_STS_ACK   0x04

void I2C_Start();
void I2C_Stop();
uint8_t I2C_Write(uint8_t data);
uint8_t I2C_Read(uint8_t ack);

#endif /* SRC_HAL_I2C_I2C_H_ */
