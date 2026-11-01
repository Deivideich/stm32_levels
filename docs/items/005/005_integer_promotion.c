/* 005 - What type is this expression, really?
 *
 * Card : docs/items/005.md   (read it first)
 * Notes: notes/005.md        Run: make 005      then also: make 005 SAN=1
 */
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define TYPE_NAME(x) _Generic((x),                                  \
    char: "char", signed char: "signed char", unsigned char: "unsigned char", \
    short: "short", unsigned short: "unsigned short",               \
    int: "int", unsigned int: "unsigned int",                       \
    long: "long", unsigned long: "unsigned long",                   \
    float: "float", double: "double", default: "other")

struct row {
    const char *expr;
    const char *guess;
    const char *actual;
};

#define ROW(e, guess) { #e, guess, TYPE_NAME(e) }

int main(void)
{
    uint8_t  a = 200u, b = 100u;
    uint16_t h = 65535u, k = 65535u;
    uint32_t w = 1u;
    int8_t   s = -1;

    /* PART A: replace every "?" with your guess BEFORE you run.
     * Use the names the table prints: "int", "unsigned int", "unsigned char", "float", ... */
    struct row rows[] = {
        ROW(a,                  "?"),
        ROW(a + b,              "?"),
        ROW(~a,                 "?"),
        ROW(-a,                 "?"),
        ROW(a << 1,             "?"),
        ROW(a & b,              "?"),
        ROW(h * k,              "?"),
        ROW(w + s,              "?"),
        ROW((uint8_t)(a + b),   "?"),
        ROW(a + 1.5f,           "?"),
    };

    unsigned wrong = 0u;
    for (unsigned i = 0u; i < sizeof rows / sizeof rows[0]; i++) {
        int ok = strcmp(rows[i].guess, rows[i].actual) == 0;
        wrong += ok ? 0u : 1u;
        printf("%-22s guess: %-14s actual: %-14s %s\n",
               rows[i].expr, rows[i].guess, rows[i].actual, ok ? "ok" : "MISMATCH");
    }

    /* PART B: now the values. Predict each one, then run (and run again with SAN=1). */
    int sum = a + b;
    uint8_t wrapped = (uint8_t)(a + b);
    volatile uint16_t vh = 65535u, vk = 65535u;
    int product = vh * vk;
    printf("\na + b            = %d\n", sum);                         /* predicted: ? */
    printf("(uint8_t)(a + b) = %u\n", (unsigned)wrapped);             /* predicted: ? */
    printf("vh * vk          = %d\n", product);                       /* predicted: ? */

    return wrong != 0u;
}
