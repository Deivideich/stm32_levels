/* 001 - Where does a variable live, and for how long?
 *
 * Card : docs/items/001.md   (read it first)
 * Notes: notes/001.md        Run: make 001      then also: make 001 SAN=1
 */
#include <stdint.h>
#include <stdio.h>

static uint32_t *saved;

static void keep(uint32_t **where, uint32_t *what)
{
    *where = what;
}

static void remember_local(void)
{
    uint32_t local = 42u;
    keep(&saved, &local);
}

static uint32_t count_local(void)
{
    uint32_t n = 0u;
    n++;
    return n;
}

static uint32_t count_static(void)
{
    static uint32_t n = 0u;
    n++;
    return n;
}

/* Same shape as remember_local(): one local, one call to keep(). Where does its local land? */
static uint32_t *other;

static void reuse_stack(void)
{
    uint32_t mine = 7u;
    keep(&other, &mine);
}

int main(void)
{
    /* PART A - before you run anything, write your prediction next to each line. */
    uint32_t l1 = count_local(); //n = 1 during function execution, it gets removed from the stack once the function ends
    uint32_t l2 = count_local(); //n = 1 
    uint32_t l3 = count_local(); //n = 1
    printf("count_local : %u %u %u\n", (unsigned)l1, (unsigned)l2, (unsigned)l3);   /* predicted: 1, 1, 1 */

    uint32_t s1 = count_static(); //n = 1
    uint32_t s2 = count_static(); //n = 2
    uint32_t s3 = count_static();// n = 3
    printf("count_static: %u %u %u\n", (unsigned)s1, (unsigned)s2, (unsigned)s3);   /* predicted: 1,2,3 */

    /* PART B - a pointer to something that no longer exists. Predict, then run. */
    remember_local(); // 
    printf("*saved right after return: %u\n", (unsigned)*saved);                    /* predicted: 42 */
    reuse_stack();
    printf("*saved after reuse_stack(): %u\n", (unsigned)*saved);                    /* predicted: 7 */

    return 0;
}
