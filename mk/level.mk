BOARD ?= g431kb
ITEM  ?= $(firstword $(SRCS:.c=))

CC      := arm-none-eabi-gcc
OBJCOPY := arm-none-eabi-objcopy
SIZE    := arm-none-eabi-size

SRCS := $(wildcard *.c)

CFLAGS  := -mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16
CFLAGS  += -O0 -g3 -Wall -Wextra -Wconversion -Wsign-conversion -Werror
CFLAGS  += -ffunction-sections -fdata-sections -DSTM32G431xx
CFLAGS  += -I. -I../../board/$(BOARD)
CFLAGS  += -isystem ../../vendor/cmsis-device-g4/Include
CFLAGS  += -isystem ../../vendor/cmsis-core/Include

LDFLAGS := -T ../../board/$(BOARD)/linker.ld -nostartfiles -Wl,--gc-sections
LDFLAGS += -Wl,-Map=build/$(ITEM).map

LOCAL_OBJS := $(addprefix build/, $(SRCS:.c=.o))
OBJS       := $(LOCAL_OBJS) build/startup.o

all: build/$(ITEM).elf

build/%.o: %.c
	@mkdir -p build
	$(CC) $(CFLAGS) -c $< -o $@

build/startup.o: ../../board/$(BOARD)/startup.c
	@mkdir -p build
	$(CC) $(CFLAGS) -c $< -o $@

build/$(ITEM).elf: $(OBJS)
	$(CC) $(LDFLAGS) $^ -o $@
	$(OBJCOPY) -O binary $@ build/$(ITEM).bin
	$(SIZE) $@

flash: build/$(ITEM).elf
	openocd -f ../../tools/openocd.cfg -c "program build/$(ITEM).elf verify reset exit"

debug: build/$(ITEM).elf
	openocd -f ../../tools/openocd.cfg & sleep 1; \
	gdb-multiarch -x ../../tools/.gdbinit build/$(ITEM).elf; \
	killall openocd

clean:
	rm -rf build

.PHONY: all flash debug clean