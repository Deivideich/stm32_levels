#ifndef COUNTER_H
#define COUNTER_H

#include <stdint.h>

extern uint32_t total_calls;
uint32_t counter_next(void);

#endif
