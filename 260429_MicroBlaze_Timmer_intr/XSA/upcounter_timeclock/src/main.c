#include "ap/ap_main.h"
#include "xparameters.h"

int main()
{
    ap_init();

    while (1)
    {
        ap_excute();
    }
    return 0;
}


//main함수의 목적은 초기화와 실행이 목적이다.
