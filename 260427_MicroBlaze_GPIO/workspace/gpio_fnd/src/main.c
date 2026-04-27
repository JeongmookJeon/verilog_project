#include <stdint.h>
#include "xparameters.h"
#include "sleep.h"
#include "xil_printf.h"

typedef struct{
	uint32_t CR;
	uint32_t IDR;
	uint32_t ODR;
}GPIO_Typedef_t;


#define XPAR_GPIO8_0_S00_AXI_BASEADDR 0x44A00000
#define XPAR_GPIO8_1_S00_AXI_BASEADDR 0x44A10000

#define GPIOA_CR   (*(uint32_t*) (XPAR_GPIO8_0_S00_AXI_BASEADDR + 0x00))
#define GPIOA_IDR  (*(uint32_t*) (XPAR_GPIO8_0_S00_AXI_BASEADDR + 0x04))
#define GPIOA_ODR  (*(uint32_t*) (XPAR_GPIO8_0_S00_AXI_BASEADDR + 0x08))

#define GPIOB_CR   (*(uint32_t*) (XPAR_GPIO8_1_S00_AXI_BASEADDR + 0x00))
#define GPIOB_IDR  (*(uint32_t*) (XPAR_GPIO8_1_S00_AXI_BASEADDR + 0x04))
#define GPIOB_ODR  (*(uint32_t*) (XPAR_GPIO8_1_S00_AXI_BASEADDR + 0x08))


#define GPIOA ((GPIO_Typedef_t *)(XPAR_GPIO8_0_S00_AXI_BASEADDR))
#define GPIOB ((GPIO_Typedef_t *)(XPAR_GPIO8_1_S00_AXI_BASEADDR))


int main()
{
   //GPIOA_CR = 0x0f; //상위 4bit는 입력. 하위 4bit는 digit
   //GPIOB_CR = 0xff; //segment
	// -> 이것은 '*'붙인거랑 동일하다.
   GPIOA -> CR = 0x0f;
   GPIOB -> CR = 0xff;
   GPIO_SetMode(GPIOA, GPIO_PIN_0, OUTPUT);
   GPIO_SetMode(GPIOA, GPIO_PIN_1, OUTPUT);
   GPIO_SetMode(GPIOA, GPIO_PIN_2, OUTPUT);
   GPIO_SetMode(GPIOA, GPIO_PIN_3, OUTPUT);
   GPIO_SetMode(GPIOA, GPIO_PIN_4, INPUT);
   GPIO_SetMode(GPIOA, GPIO_PIN_5, INPUT);
   GPIO_SetMode(GPIOA, GPIO_PIN_6, INPUT);
   GPIO_SetMode(GPIOA, GPIO_PIN_7, INPUT);
   GPIO_SetMode(GPIOA, GPIO_PIN_0, INPUT);

   while(1)
   {
	   //GPIOB_ODR = 0x00; // segment 모두 선택
	   GPIOB -> ODR= 0x00;

	   GPIO_WritePin(GPIOA, GPIO_PIN_0, RESET);
	   GPIO_WritePin(GPIOA, GPIO_PIN_1, SET);

	   if(GPIO_ReadPin(GPIOA, GPIO_PIN_4)){
		   GPIOA -> ODR &= ~(1<<0);
		   GPIO_WritePin(GPIOA, GPIO_PIN_0, RESET);
	   }
	   	   else if((GPIOA_IDR  & (1<<5))){
	   		 GPIOA -> ODR &= ~(1<<1); // digit 모두 선택
	   	   }
	   	   else if((GPIOA_IDR  & (1<<6))){
	   		 GPIOA -> ODR &= ~(1<<2); // digit 모두 선택
	   	   }
	   	   else if((GPIOA_IDR  & (1<<7))){
	   		 GPIOA -> ODR &= ~(1<<3); // digit 모두 선택
	   	   }
	   	   else {
	   		 GPIOA -> ODR |= (0x0f); //하위 4bit를 1로 만들어주는 것.
	   	   }

   }

//	   if((GPIOA_IDR  & (1<<4))){
//		   GPIOA_ODR &= ~(1<<0); // digit 모두 선택
//	   }
//	   else if((GPIOA_IDR  & (1<<5))){
//		   GPIOA_ODR &= ~(1<<1); // digit 모두 선택
//   }
//	   else if((GPIOA_IDR  & (1<<6))){
//		   GPIOA_ODR &= ~(1<<2); // digit 모두 선택
//	   }
//	   else if((GPIOA_IDR  & (1<<7))){
//		   GPIOA_ODR &= ~(1<<3); // digit 모두 선택
//	   }
//	   else {
//		   GPIOA_ODR |= (0x0f);
//	   }
 //  }
   return 0;
}
