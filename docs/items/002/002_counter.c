#include "002_counter.h"

uint32_t total_calls;                    /* (A) */
static uint32_t private_calls;           /* (B) */

static uint32_t bump_private(void)       /* (C) */
{
    return ++private_calls;
}

uint32_t counter_next(void)              /* (D) */
{
    static uint32_t last;                /* (E) */

    total_calls++;
    last = bump_private();
    return last;
}
