#include <stdint.h>

#include "../include/uart.h"
#include "../include/xprintf.h"
#include "../include/utils.h"


int main()
{
    uart_init();

    xprintf("hello world\n");

#ifdef SIMULATION
    /* Return so start.S can set x26=1 (sim done). UART TX already completed
     * because uart_putc waits for the TX busy bit. */
    set_test_pass();
    return 0;
#else
    while (1);
#endif
}
