#include "GPIO.h"

//핀의 방향 설정
void GPIO_SetMode(GPIO_Typedef_t* GPIOx, uint32_t GPIO_PIN, int GPIO_Dir)
{
	if(GPIO_Dir == OUTPUT) {
		GPIOx->CR |= GPIO_PIN;
	} else {
		GPIOx->CR &= ~(GPIO_PIN);
	}

}
//특정 핀에 전기 신호를 보내서 조작
void GPIO_WritePin(GPIO_Typedef_t *GPIOx, uint32_t GPIO_PIN, int level)
{
	if (level == SET) {
		GPIOx->ODR |= GPIO_PIN;
	} else {
		GPIOx->ODR &= ~GPIO_PIN;
	}
}
//특정 핀의 상태 읽어 오기
uint32_t GPIO_ReadPin(GPIO_Typedef_t *GPIOx, uint32_t GPIO_PIN)
{
	//괄호 안이 0이면 거짓
	//0이 아닌 것은 모두 참
	return (GPIOx->IDR & GPIO_PIN) ? 1 : 0;
}
//포트 전체 한 번에 제어
void GPIO_WritePort(GPIO_Typedef_t *GPIOx, int data)
{
	GPIOx->ODR = data;
}
//포트 전체 한 번에 제어
uint32_t GPIO_ReadPort(GPIO_Typedef_t *GPIOx)
{
	return(GPIOx->IDR);
}
