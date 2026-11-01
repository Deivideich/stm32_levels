/* 004 - Read and write a field without touching its neighbours
 *
 * Card : docs/items/004.md   (read it first)
 * Notes: notes/004.md        Run: make 004      then: make 004 OPT=-O2   and   make 004 SAN=1
 *
 * The tests below are the specification. Your job is to fix 004_fields.h, not the tests.
 */
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include "004_fields.h"

#define F_LO_POS   0u
#define F_LO_MSK   0x0000000Fu
#define F_MID_POS  4u
#define F_MID_MSK  0x00000FF0u
#define F_HI_POS   24u
#define F_HI_MSK   0xFF000000u

static void test_get(void)
{
    uint32_t reg = 0x12345678u;
    assert(FIELD_GET(reg, F_LO_MSK,  F_LO_POS)  == 0x8u);
    assert(FIELD_GET(reg, F_MID_MSK, F_MID_POS) == 0x67u);
    assert(FIELD_GET(reg, F_HI_MSK,  F_HI_POS)  == 0x12u);
}

static void test_set_on_zero(void)
{
    uint32_t reg = 0u;
    FIELD_SET(reg, F_MID_MSK, F_MID_POS, 0x5Au);
    assert(reg == 0x000005A0u);
}

static void test_set_over_existing_value(void)
{
    uint32_t reg = 0xFFFFFFFFu;
    FIELD_SET(reg, F_MID_MSK, F_MID_POS, 0x12u);
    assert(reg == 0xFFFFF12Fu && "setting a field must replace the old value, not merge with it");
}

static void test_neighbours_untouched(void)
{
    static const uint32_t patterns[] = { 0x00000000u, 0xFFFFFFFFu, 0xA5A5A5A5u, 0x5A5A5A5Au };
    for (unsigned i = 0u; i < sizeof patterns / sizeof patterns[0]; i++) {
        uint32_t reg = patterns[i];
        FIELD_SET(reg, F_MID_MSK, F_MID_POS, 0xFFu);
        assert((reg & ~F_MID_MSK) == (patterns[i] & ~F_MID_MSK) && "bits outside the field changed");
        reg = patterns[i];
        FIELD_SET(reg, F_MID_MSK, F_MID_POS, 0x00u);
        assert((reg & ~F_MID_MSK) == (patterns[i] & ~F_MID_MSK) && "bits outside the field changed");
    }
}

static void test_value_too_wide(void)
{
    uint32_t reg = 0u;
    FIELD_SET(reg, F_LO_MSK, F_LO_POS, 0x1Fu);   /* 5 bits into a 4-bit field */
    assert(reg == 0x0000000Fu && "an oversized value must not leak into the next field");
}

static void test_every_value_every_pattern(void)
{
    static const uint32_t patterns[] = { 0x00000000u, 0xFFFFFFFFu };
    for (unsigned p = 0u; p < 2u; p++) {
        for (uint32_t v = 0u; v <= 0xFFu; v++) {
            uint32_t reg = patterns[p];
            FIELD_SET(reg, F_HI_MSK, F_HI_POS, v);
            assert(FIELD_GET(reg, F_HI_MSK, F_HI_POS) == v);
            assert((reg & ~F_HI_MSK) == (patterns[p] & ~F_HI_MSK));
        }
    }
}

int main(void)
{
    test_get();
    test_set_on_zero();
    test_set_over_existing_value();
    test_neighbours_untouched();
    test_value_too_wide();
    test_every_value_every_pattern();
    puts("004: all tests passed");
    return 0;
}
