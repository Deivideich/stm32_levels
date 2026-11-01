# stm32_levels

Bottom-up STM32 bare-metal exercises. One item, one file, one commit.

## Rules

- `vendor/` is never edited.
- `board/` holds board facts, never logic.
- `lib/` only receives a module once a second level needs it.
- A level never includes `../other-level/x.h`.

## Build

    make 001          # build item 001 in the current level
    make 001 flash    # program the board
    make 001 debug    # gdb + openocd