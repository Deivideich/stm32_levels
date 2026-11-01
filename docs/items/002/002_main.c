/* 002 - Who can see what?
 *
 * Card : docs/items/002.md   (read it first)
 * Notes: notes/002.md        Run: make 002
 */
#include <stdio.h>
#include "002_counter.h"

int main(void)
{
    (void)counter_next();
    (void)counter_next();
    printf("calls: %u\n", (unsigned)total_calls);
    return 0;
}
