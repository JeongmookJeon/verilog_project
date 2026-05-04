

#ifndef SRC_HAL_GPIO_GPIO_H_
#define SRC_HAL_GPIO_GPIO_H_

#include <stdint.h>

//구조체 : 변수들을 하나로 묶은 것
typedef struct {
	uint32_t CR;
	uint32_t IDR;
	uint32_t ODR;
}GPIO_Typedef_t;

#define GPIOA_BASEADDR 0x44A00000
#define GPIOB_BASEADDR 0x44A10000

//GPIO_Typedef_t : 메모리 모양
#define GPIOA ((GPIO_Typedef_t *) (GPIOA_BASEADDR))
#define GPIOB ((GPIO_Typedef_t *) (GPIOB_BASEADDR))

#define GPIO_PIN_0 0x01 //0b00000001
#define GPIO_PIN_1 0x02 //0b00000010
#define GPIO_PIN_2 0x04 //0b00000100
#define GPIO_PIN_3 0x08 //0b00001000
#define GPIO_PIN_4 0x10 //0b00010000
#define GPIO_PIN_5 0x20 //0b00100000
#define GPIO_PIN_6 0x40 //0b01000000
#define GPIO_PIN_7 0x80 //0b10000000

#define INPUT 0
#define OUTPUT 1

#define RESET 0
#define SET 1

void GPIO_SetMode(GPIO_Typedef_t* GPIOx, uint32_t GPIO_PIN, int GPIO_Dir);
void GPIO_WritePin(GPIO_Typedef_t *GPIOx, uint32_t GPIO_PIN, int level);
uint32_t GPIO_ReadPin(GPIO_Typedef_t *GPIOx, uint32_t GPIO_PIN);
void GPIO_WritePort(GPIO_Typedef_t *GPIOx, int data);
uint32_t GPIO_ReadPort(GPIO_Typedef_t *GPIOx);


#endif /* SRC_HAL_GPIO_GPIO_H_ */
