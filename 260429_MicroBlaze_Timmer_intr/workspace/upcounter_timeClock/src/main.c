#include "ap/ap_main.h"
#include "xparameters.h"

int main()
{
	//ap 초기화
	ap_init();

	while(1)
	{
		//ap 실행
		ap_excute();
	}

	return 0;
}
