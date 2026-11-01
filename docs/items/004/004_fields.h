#ifndef FIELDS_H
#define FIELDS_H

#include <stdint.h>

/* A field is described by its mask (already shifted into place) and its position. */

#define FIELD_GET(reg, msk, pos)       (((reg) & (msk)) >> (pos))

/* First attempt. The test file will tell you what is wrong with it. */
#define FIELD_SET(reg, msk, pos, val)  ((reg) |= ((val) << (pos)))

#endif
