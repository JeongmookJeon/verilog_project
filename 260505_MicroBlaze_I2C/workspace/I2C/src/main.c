/*
 * main.c
 *
 *  Created on: 2026. 5. 3.
 *      Author: kccistc
 */


#include "ap/ap_main.h"
#include "xparameters.h"

int main()
{
	ap_init();

	while(1)
	{
		ap_main();
	}

   return 0;
}
