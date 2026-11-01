/* 001 - give_module_state_static
 *
 * `S` Give module state static storage duration when it must outlive the stack frame. — *Done when:* a module keeps its state at file scope and no pointer to it escapes before it is initialised.
 *
 * Result: PASS / GAP   (one line on why)
 */
#include <assert.h>
#include <stdint.h>
#include <stdio.h>

int main(void)
{
    /* TODO: your solution, and the asserts that prove "Done when". */
    assert(0 && "item not solved yet");
    return 0;
}
