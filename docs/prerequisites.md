# Prerequisites

What you need **before** starting each stretch. Check it with `make doctor LEVEL=<n>`.

## Today: Levels 1 and 2 (PC only, no board)

**Tools:** `gcc` (any version with C11), `make`, `git`, `nm` and `objdump` (binutils).
Optional: `clang` (Level 14) and `cppcheck` (Level 2).

**Self-check (5 min).** If you hesitate on two or more, read K&R chapters 1-5 first:
1. What is the difference between declaring and defining a variable or function?
2. What does `static` do at file scope, and what does it do inside a function?
3. What is a pointer, and what does `p + 1` mean depending on the type of `p`?
4. What is the difference between compiling (`gcc -c`) and linking, and what does `nm` show for a `.o`?
5. How do you read a compiler warning, and what does `-Werror` do about it?
6. What does `assert` do, and when does it disappear (`-DNDEBUG`)?

**Hardware:** none.

## Level 3 (ARM toolchain)

- `arm-none-eabi-gcc` (pin the version), `arm-none-eabi-objcopy`, `arm-none-eabi-size`, `openocd`, `gdb-multiarch` (or `arm-none-eabi-gdb`).
- ST-LINK udev rules or drivers, so `openocd` sees the board without `sudo`.
- NUCLEO-G431KB and a USB cable.
- CMSIS headers in `vendor/` (`cmsis-core`, `cmsis-device-g4`): headers only, never edited.
- Reading: RM0440 (memory map and boot), PM0214 (exception model), the G431KB datasheet.

## Phase 2 (pins, time, interrupts)

- 8-channel logic analyser with decoders (sigrok/PulseView or the vendor software).
- Multimeter, breadboard, an external LED with a resistor and an **external push button** (check whether your Nucleo-32 has a user button; it normally only has the reset button).
- Oscilloscope: optional (3 items, each with a fallback).

## Phase 3 (timers, analog, buses)

- Second NUCLEO-G431KB (pulse source and UART peer).
- 1 SPI sensor with a WHO_AM_I register and 1 I2C sensor; jumper wires; pull-up resistors.
- A potentiometer or a known resistive divider for the ADC.

## Phase 4 (DMA, core, CAN, power, boot)

- 2 CAN transceivers (3.3 V) and two 120 ohm terminators.
- µA meter with logging (for example a Nordic PPK2). Check whether your board has an IDD jumper (UM2397).

## Phases 5 and 6

- Phase 5: an RC plant (resistor and capacitor) for the PID.
- Phase 6 (optional): NUCLEO-H755ZI-Q.
