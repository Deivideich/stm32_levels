/* 003 - Bitfield or masks?
 *
 * Card : docs/items/003.md   (read it first)
 * Notes: notes/003.md        Run: make 003      then: make 003 OPT=-O2
 */
#include <assert.h>
#include <stdint.h>
#include <stdio.h>

/* Datasheet of a made-up peripheral. Register CTRL, 32 bits:
 *
 *   bit  0      EN      enable
 *   bits 3:1    MODE    0..7
 *   bits 7:4    PRESC   prescaler, 0..15
 *   bit  8      IRQ_EN  interrupt enable
 *   bits 31:9   reserved, write 0
 */
struct ctrl_bits {
    uint32_t en     : 1;
    uint32_t mode   : 3;
    uint32_t presc  : 4;
    uint32_t irq_en : 1;
    uint32_t        : 23;
};

union ctrl {
    struct ctrl_bits b;
    uint32_t raw;
};

/* PART B: describe the same fields with masks and shifts, straight from the datasheet above
 * (not from what you observed in part A). For example:
 *
 *     #define CTRL_EN_POS   0u
 *     #define CTRL_EN_MSK   (0x1u << CTRL_EN_POS)
 */

int main(void)
{
    /* PART A: predict the raw value (as hex) BEFORE you run. */
    union ctrl c = { .raw = 0u };
    c.b.mode  = 5u;
    c.b.presc = 9u;
    printf("sizeof = %zu, raw = 0x%08X\n", sizeof c, (unsigned)c.raw);   /* predicted: ? */

    /* PART C: for every combination of en, mode, presc, irq_en, build the register once with
     * the bitfield view and once with your masks, and assert that the two raw values are equal.
     * Then run it again with OPT=-O2. */
    assert(0 && "part C not written yet");
    return 0;
}
