# mk/host.mk - levels that run on the PC (Levels 1 and 2). No board needed.
#
#   make 001            build and run item 001 (the NNN_*.c files of the level)
#   make 001 OPT=-O2    change the optimisation level (default -O0)
#   make 001 SAN=1      enable sanitizers (UBSan + ASan)
#   make list           list the items of the level
#   make check          run every item of the level
#
# An item is one or more NNN_*.c files with their own main(). It PASSES when
# main() returns 0 (use assert). Warnings are errors: -Werror is part of the exercise.

CC   ?= gcc
OPT  ?= -O0
SAN  ?= 0

WARN   := -Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion -Wshadow -Werror
CFLAGS := -std=c11 $(OPT) -g3 $(WARN) -I.
ifeq ($(SAN),1)
CFLAGS += -fsanitize=undefined,address -fno-omit-frame-pointer
endif

# Rebuild when the flags change (OPT=..., SAN=1), not only when a source changes.
FLAGS_STAMP := build/.flags
$(shell mkdir -p build; echo '$(CC) $(CFLAGS)' | cmp -s - $(FLAGS_STAMP) 2>/dev/null || echo '$(CC) $(CFLAGS)' > $(FLAGS_STAMP))

ITEM_SRCS := $(sort $(wildcard [0-9][0-9][0-9]_*.c))
IDS       := $(sort $(foreach f,$(ITEM_SRCS),$(firstword $(subst _, ,$(f)))))

define ITEM_RULE
build/$(1): $(wildcard $(1)_*.c $(1)_*.h) $(FLAGS_STAMP) | build
	$$(CC) $$(CFLAGS) $$(filter %.c,$$^) -o $$@
$(1): build/$(1)
	@./build/$(1) && echo "[$(1)] OK"
endef
$(foreach i,$(IDS),$(eval $(call ITEM_RULE,$(i))))

build:
	@mkdir -p build

check: $(IDS)
list:
	@printf '%s\n' $(IDS)
clean:
	rm -rf build

.PHONY: check list clean $(IDS)
