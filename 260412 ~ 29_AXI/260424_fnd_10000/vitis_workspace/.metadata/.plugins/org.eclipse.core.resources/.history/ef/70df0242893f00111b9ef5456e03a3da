#include <stdint.h>
#include "xparameters.h"
#include "sleep.h"

#define FND_DATA  (*(volatile uint32_t *)(XPAR_FND_0_S00_AXI_BASEADDR + 0x00))
#define FND_DIGIT (*(volatile uint32_t *)(XPAR_FND_0_S00_AXI_BASEADDR + 0x08))

#define GPIOA_CR  (*(volatile uint32_t *)(XPAR_GPIO_0_S00_AXI_BASEADDR + 0x00))
#define GPIOA_IDR (*(volatile uint32_t *)(XPAR_GPIO_0_S00_AXI_BASEADDR + 0x04))

const uint8_t fnd_pattern[10] = {
    0xC0,
    0xF9,
    0xA4,
    0xB0,
    0x99,
    0x92,
    0x82,
    0xF8,
    0x80,
    0x90
};

int main()
{

    GPIOA_CR = 0x00;

    int count = 0;
    int is_running = 0;
    int tick = 0;

    while(1)
    {
        uint32_t btns = GPIOA_IDR;

        if (btns & (1 << 0)) {
            is_running = 1;
        }
        if (btns & (1 << 1)) {
            is_running = 0;
        }
        if (btns & (1 << 2)) {
            count = 0;
        }

        int thousands = (count / 1000) % 10;
        int hundreds  = (count / 100) % 10;
        int tens      = (count / 10) % 10;
        int ones      = count % 10;

        FND_DIGIT = 0b0111;
        FND_DATA  = fnd_pattern[thousands];
        usleep(4000);

        FND_DIGIT = 0b1011;
        FND_DATA  = fnd_pattern[hundreds];
        usleep(4000);

        FND_DIGIT = 0b1101;
        FND_DATA  = fnd_pattern[tens];
        usleep(4000);

        FND_DIGIT = 0b1110;
        FND_DATA  = fnd_pattern[ones];
        usleep(4000);

        if (is_running == 1) {
            tick++;

            if (tick >= 1) {
                tick = 0;
                count++;

                if (count > 9999) {
                    count = 0;
                }
            }
        }
    }

    return 0;
}


