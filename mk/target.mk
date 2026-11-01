# mk/target.mk - levels that run on the board (Level 3+).
#
#   make 001            build build/001.elf and build/001.bin
#   make 001 flash      program the board
#   make 001 debug      gdb + openocd
#   make size           size of every elf of the level
#   make check          build every item of the level
#
# TODO(021): pin the arm-none-eabi-gcc version in the level README and in CI.
# TODO(023): replace board/g431kb/g431kb.ld with your own linker script.
# TODO(036): review tools/openocd.cfg and tools/.gdbinit.

CROSS    ?= arm-none-eabi-
CC       := $(CROSS)gcc
OBJCOPY  := $(CROSS)objcopy
SIZE     := $(CROSS)size
GDB      ?= gdb-multiarch

CPU      := -mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16
WARN     := -Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion -Wshadow -Werror
OPT      ?= -O2
LDSCRIPT := ../../board/g431kb/g431kb.ld
CFLAGS   := $(CPU) $(OPT) -g3 $(WARN) -I../../vendor -I../../board/g431kb -I.
LDFLAGS  := $(CPU) -T$(LDSCRIPT) -nostartfiles --specs=nano.specs

ITEM_SRCS := $(sort $(wildcard [0-9][0-9][0-9]_*.c))
IDS       := $(sort $(foreach f,$(ITEM_SRCS),$(firstword $(subst _, ,$(f)))))
GOALS     := $(filter-out check size clean list flash debug,$(MAKECMDGOALS))
ONE       := $(firstword $(GOALS))

define ITEM_RULE
build/$(1).elf: $(wildcard $(1)_*.c $(1)_*.h) $(LDSCRIPT) | build
	$$(CC) $$(CFLAGS) $$(filter %.c,$$^) $$(LDFLAGS) -Wl,-Map=build/$(1).map -o $$@
build/$(1).bin: build/$(1).elf
	$$(OBJCOPY) -O binary $$< $$@
$(1): build/$(1).bin
endef
$(foreach i,$(IDS),$(eval $(call ITEM_RULE,$(i))))

build:
	@mkdir -p build

flash: $(ONE)
	@test -n "$(ONE)" || { echo "usage: make NNN flash"; exit 1; }
	openocd -f ../../tools/openocd.cfg -c "program build/$(ONE).elf verify reset exit"
debug: $(ONE)
	@test -n "$(ONE)" || { echo "usage: make NNN debug"; exit 1; }
	openocd -f ../../tools/openocd.cfg & OPENOCD_PID=$$!; \
	  $(GDB) -x ../../tools/.gdbinit build/$(ONE).elf; kill $$OPENOCD_PID
size: $(addsuffix .elf,$(addprefix build/,$(IDS)))
	$(SIZE) $^
check: $(IDS)
list:
	@printf '%s\n' $(IDS)
clean:
	rm -rf build

.PHONY: check list clean size flash debug $(IDS)
