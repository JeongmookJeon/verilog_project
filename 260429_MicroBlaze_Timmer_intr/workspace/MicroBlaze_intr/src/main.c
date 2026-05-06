#include "ap/ap_main.h"
//#include "xparameters.h"

int main()
{
	ap_init();

	while(1)
	{
		ap_execute();
	}

	return 0;
}
