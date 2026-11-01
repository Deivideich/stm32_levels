#!/usr/bin/env bash
# bootstrap.sh - scaffolding for the stm32_levels guide (roadmap v4).
#
# Levels 1-2 run on the PC: no board, ARM toolchain or vendor/ needed yet.
#
# Usage, from the repo root with a clean git tree:
#     bash bootstrap.sh
#     git diff            # review what changed
#
# Safe to re-run: it rewrites the shared tooling and docs, and never touches
# your item files, notes or evidence.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -d .git ] || { echo "Run this from the repo root (no .git here)"; exit 1; }

mkdir -p docs mk tools levels

# Makefile recipe lines start with ">>" in this script and are turned into a TAB
# afterwards, so they survive copy/paste.
fixtabs() { sed -i 's/^>>/\t/' "$1"; }

# ---------------------------------------------------------------- .gitignore
cat > .gitignore <<'EOF'
build/
*.o
*.elf
*.bin
*.map
*.swp
.vscode/
.idea/
EOF

# ---------------------------------------------------------------- root Makefile
cat > Makefile <<'EOF'
# Root: runs `check` in every level. Each level decides what check means
# (host levels: build and run every item; board levels: build every item).
LEVELS := $(wildcard levels/*/)

check:
>>@for d in $(LEVELS); do echo "== $$d"; $(MAKE) --no-print-directory -C $$d check || exit 1; done

doctor:
>>@tools/doctor.sh $(LEVEL)

progress:
>>@tools/progress.sh

.PHONY: check doctor progress
EOF
fixtabs Makefile

# ---------------------------------------------------------------- mk/host.mk
cat > mk/host.mk <<'EOF'
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
>>$$(CC) $$(CFLAGS) $$(filter %.c,$$^) -o $$@
$(1): build/$(1)
>>@./build/$(1) && echo "[$(1)] OK"
endef
$(foreach i,$(IDS),$(eval $(call ITEM_RULE,$(i))))

build:
>>@mkdir -p build

check: $(IDS)
list:
>>@printf '%s\n' $(IDS)
clean:
>>rm -rf build

.PHONY: check list clean $(IDS)
EOF
fixtabs mk/host.mk

# ---------------------------------------------------------------- mk/target.mk
cat > mk/target.mk <<'EOF'
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

CPU      := -mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16
WARN     := -Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion -Wshadow -Werror
OPT      ?= -O2
LDSCRIPT := ../../board/g431kb/g431kb.ld
CFLAGS   := $(CPU) $(OPT) -g3 $(WARN) -I../../vendor -I../../board/g431kb -I.
LDFLAGS  := $(CPU) -T$(LDSCRIPT) -nostartfiles --specs=nano.specs

ITEM_SRCS := $(sort $(wildcard [0-9][0-9][0-9]_*.c))
IDS       := $(sort $(foreach f,$(ITEM_SRCS),$(firstword $(subst _, ,$(f)))))
GOALS     := $(filter-out check size clean list,$(MAKECMDGOALS))
ONE       := $(firstword $(GOALS))

define ITEM_RULE
build/$(1).elf: $(wildcard $(1)_*.c $(1)_*.h) $(LDSCRIPT) | build
>>$$(CC) $$(CFLAGS) $$(filter %.c,$$^) $$(LDFLAGS) -Wl,-Map=build/$(1).map -o $$@
build/$(1).bin: build/$(1).elf
>>$$(OBJCOPY) -O binary $$< $$@
$(1): build/$(1).bin
endef
$(foreach i,$(IDS),$(eval $(call ITEM_RULE,$(i))))

build:
>>@mkdir -p build

flash: $(ONE)
>>openocd -f ../../tools/openocd.cfg -c "program build/$(ONE).elf verify reset exit"
debug: $(ONE)
>>openocd -f ../../tools/openocd.cfg & sleep 1; gdb-multiarch -x ../../tools/.gdbinit build/$(ONE).elf
size: $(addsuffix .elf,$(addprefix build/,$(IDS)))
>>$(SIZE) $^
check: $(IDS)
list:
>>@printf '%s\n' $(IDS)
clean:
>>rm -rf build

.PHONY: check list clean size flash debug $(IDS)
EOF
fixtabs mk/target.mk

# ---------------------------------------------------------------- board tooling stubs
cat > tools/openocd.cfg <<'EOF'
# tools/openocd.cfg - TODO(036): review when you reach Level 3.
source [find interface/stlink.cfg]
source [find target/stm32g4x.cfg]
EOF

cat > tools/.gdbinit <<'EOF'
# tools/.gdbinit - TODO(036): review when you reach Level 3.
set pagination off
target extended-remote :3333
monitor reset halt
EOF

# ---------------------------------------------------------------- tools/new_level.sh
cat > tools/new_level.sh <<'EOF'
#!/usr/bin/env bash
# Create a level folder from the roadmap.   Run from the repo root:
#     tools/new_level.sh 1                 # -> levels/01_c_that_bites/
#     tools/new_level.sh 1 c_that_bites    # your own folder name
# It writes the level Makefile and a README with the prerequisite line and the item range.
set -euo pipefail
n="${1:?usage: new_level.sh LEVEL_NUMBER [folder_name]}"
[[ "$n" =~ ^[0-9]+$ ]] || { echo "level must be a number"; exit 1; }
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
road="$root/docs/roadmap.md"
[ -f "$road" ] || { echo "missing docs/roadmap.md"; exit 1; }

head_line="$(grep -m1 -E "^### Level ${n} " "$road" || true)"
[ -n "$head_line" ] || { echo "Level $n is not in the roadmap"; exit 1; }
title="${head_line#*— }"

name="${2:-}"
if [ -z "$name" ]; then
  name="$(echo "$title" | tr 'A-Z' 'a-z' | sed -E 's/[^a-z0-9]+/ /g' \
    | awk 'BEGIN{split("a an and the in of to from on for with",w," ");for(k in w)stop[w[k]]=1}
           {n=0;out="";for(i=1;i<=NF&&n<3;i++){if($i in stop)continue;out=out (n?"_":"") $i;n++}print out}')"
fi
dir="$root/levels/$(printf '%02d' "$n")_${name}"
existing="$(ls -d "$root"/levels/"$(printf '%02d' "$n")"_* 2>/dev/null | head -1 || true)"
[ -z "$existing" ] || { echo "already exists: ${existing#$root/}"; exit 0; }

# prerequisite line = the line right after the heading
prereq="$(awk -v h="$head_line" '$0==h{f=1;next} f&&NF{print;exit}' "$road")"
first="$(awk -v h="$head_line" '$0==h{f=1;next} f&&/^- \*\*[0-9]{3}\*\*/{match($0,/[0-9]{3}/);print substr($0,RSTART,3);exit}' "$road")"
last="$(awk -v h="$head_line" '$0==h{f=1;next} f&&/^(### |## )/{exit} f&&/^- \*\*[0-9]{3}\*\*/{match($0,/[0-9]{3}/);l=substr($0,RSTART,3)} END{print l}' "$road")"

mkdir -p "$dir"
if [ "$n" -le 2 ]; then mk=host.mk; else mk=target.mk; fi
echo "include ../../mk/$mk" > "$dir/Makefile"
cat > "$dir/README.md" <<EOT
# Level $n - $title

$prereq

Items ${first}-${last}. The statements and their "Done when" live in
[docs/roadmap.md](../../docs/roadmap.md).

Create an item skeleton with:

    ../../tools/new_item.sh ${first}
EOT
[ "$n" -le 2 ] || echo "note: mk/target.mk is added when you reach Level 3 (board builds)."
echo "created: ${dir#$root/}"
EOF
chmod +x tools/new_level.sh

# ---------------------------------------------------------------- tools/new_item.sh
cat > tools/new_item.sh <<'EOF'
#!/usr/bin/env bash
# Create an item. Run it FROM INSIDE the level folder:
#     cd levels/01_c_that_bites
#     ../../tools/new_item.sh 001
#
# If the item has a card (docs/items/NNN.md), its starter files are copied here and
# you are pointed to the card. Otherwise a plain skeleton is created, with the
# statement and its "Done when" copied from docs/roadmap.md into the header.
# Existing files are never overwritten.
set -euo pipefail
id="${1:?usage: new_item.sh NNN [slug_in_snake_case]}"
[[ "$id" =~ ^[0-9]{3}$ ]] || { echo "the id must have 3 digits"; exit 1; }

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
road="$root/docs/roadmap.md"
cards="$root/docs/items"

# ---------------------------------------------------------------- card-based item
if [ -d "$cards/$id" ]; then
  # an older plain skeleton for this item would clash with the starter (two main functions)
  for existing in ${id}_*.c; do
    [ -e "$existing" ] || continue
    if [ ! -e "$cards/$id/$existing" ]; then
      echo "ERROR: $existing is an old skeleton of item $id and would clash with the card's starter."
      echo "       If you have not started the item, remove it and retry:"
      echo "           git rm -f $existing notes/${id}.md   (or just rm)"
      exit 1
    fi
  done
  mkdir -p notes "evidence/$id"
  touch "evidence/$id/.gitkeep"
  for f in "$cards/$id"/*; do
    b="$(basename "$f")"
    if [ -e "$b" ]; then echo "kept (already exists): $b"
    else cp "$f" "$b"; echo "created: $b"; fi
  done
  if [ ! -e "notes/${id}.md" ]; then
    title="$(head -1 "$cards/$id.md" 2>/dev/null | sed 's/^# *//' || true)"
    cat > "notes/${id}.md" <<EOT
# ${title:-$id}

- Result: TODO (PASS or GAP)
- Evidence: evidence/${id}/

## Predictions (written before running)

## What I observed

## Answers to the card's questions

## What surprised me
EOT
    echo "created: notes/${id}.md"
  fi
  echo
  echo "Read the card first: docs/items/${id}.md"
  exit 0
fi

# ---------------------------------------------------------------- plain skeleton
mkdir -p notes "evidence/$id"
touch "evidence/$id/.gitkeep"

line=""
if [ -f "$road" ]; then
  line="$(grep -m1 "^- \*\*${id}\*\*" "$road" | sed -E 's/^- \*\*[0-9]+\*\* //; s#\*/#* /#g' || true)"
fi

slug="${2:-}"
if [ -z "$slug" ]; then
  [ -n "$line" ] || { echo "item $id is not in the roadmap; pass a slug"; exit 1; }
  slug="$(echo "$line" \
    | sed -E 's/^(`[A-Z]`( ◈)?|`L` \*\*Block:\*\*( ◈)?) //; s/ — \*Done when:\*.*$//' \
    | tr 'A-Z' 'a-z' | sed -E 's/[^a-z0-9]+/ /g' \
    | awk '{for(i=1;i<=4&&i<=NF;i++) printf "%s%s", $i, (i<4&&i<NF?"_":"")}')"
fi
[[ "$slug" =~ ^[a-z0-9_]+$ ]] || { echo "the slug uses lowercase letters, digits and _"; exit 1; }

if compgen -G "${id}_*.c" >/dev/null; then
  echo "item $id already has a file: $(ls ${id}_*.c | head -1)"; exit 1
fi
src="${id}_${slug}.c"

cat > "$src" <<EOT
/* ${id} - ${slug}
 *
 * ${line:-(paste the statement from docs/roadmap.md here)}
 *
 * Result: PASS / GAP   (one line on why)
 */
#include <assert.h>
#include <stdint.h>
#include <stdio.h>

int main(void)
{
    /* TODO: your solution, and the asserts that prove "Done when". */
    assert(0 && "item not solved yet");
    return 0;
}
EOT

if [ ! -e "notes/${id}.md" ]; then
  cat > "notes/${id}.md" <<EOT
# ${id} - ${slug}

- Result: TODO (PASS or GAP)
- Evidence: evidence/${id}/
- What surprised me:
EOT
fi
echo "created: $src  notes/${id}.md  evidence/${id}/"
EOF
chmod +x tools/new_item.sh

# ---------------------------------------------------------------- tools/progress.sh
cat > tools/progress.sh <<'EOF'
#!/usr/bin/env bash
# Progress per level, from docs/roadmap.md and the notes/NNN.md files.
# An item counts as done when its note has a line starting with "- Result: PASS",
# and as a gap when it starts with "- Result: GAP".
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
road="$root/docs/roadmap.md"
[ -f "$road" ] || { echo "missing docs/roadmap.md"; exit 1; }

declare -A pass gap
for f in "$root"/levels/*/notes/[0-9][0-9][0-9].md; do
  [ -e "$f" ] || continue
  id="$(basename "$f" .md)"
  if   grep -qE '^- Result: PASS' "$f"; then pass[$id]=1
  elif grep -qE '^- Result: GAP'  "$f"; then gap[$id]=1; fi
done

declare -A total done_ gaps title
order=(); lvl=""; next=""; all=0; ok=0
while IFS= read -r line; do
  if [[ $line =~ ^###\ Level\ ([0-9]+)\  ]]; then
    lvl="${BASH_REMATCH[1]}"; title[$lvl]="${line#*— }"; order+=("$lvl")
  elif [[ -n $lvl && $line =~ ^-\ \*\*([0-9]{3})\*\* ]]; then
    id="${BASH_REMATCH[1]}"
    total[$lvl]=$(( ${total[$lvl]:-0} + 1 )); all=$((all+1))
    if   [[ -n ${pass[$id]:-} ]]; then done_[$lvl]=$(( ${done_[$lvl]:-0} + 1 )); ok=$((ok+1))
    elif [[ -n ${gap[$id]:-}  ]]; then gaps[$lvl]=$(( ${gaps[$lvl]:-0} + 1 ))
    fi
    [[ -z $next && -z ${pass[$id]:-} ]] && next="$id"
  elif [[ $line =~ ^##\  ]]; then lvl=""
  fi
done < "$road"

printf '%-5s %-44s %9s %5s\n' Level Title Done Gaps
for l in "${order[@]}"; do
  printf '%-5s %-44.44s %4s/%-4s %5s\n' "$l" "${title[$l]}" "${done_[$l]:-0}" "${total[$l]}" "${gaps[$l]:-0}"
done
echo
printf 'Total: %d/%d items PASS (%d%%)\n' "$ok" "$all" $(( all ? ok*100/all : 0 ))
[ -n "$next" ] && { echo -n "Next: "; grep -m1 "^- \*\*${next}\*\*" "$road" | sed -E 's/^- \*\*([0-9]+)\*\* /\1 /' | cut -c1-110; }
exit 0
EOF
chmod +x tools/progress.sh

# ---------------------------------------------------------------- tools/doctor.sh
cat > tools/doctor.sh <<'EOF'
#!/usr/bin/env bash
# Check the tools you need up to a given level.
#     tools/doctor.sh        # level 1 (default)
#     tools/doctor.sh 3      # levels 1-3 (adds the ARM toolchain)
lvl="${1:-1}"; miss=0
need() { if command -v "$1" >/dev/null 2>&1; then printf '  ok        %s\n' "$1"
         else printf '  MISSING   %-22s %s\n' "$1" "${2:-}"; miss=1; fi; }
opt()  { if command -v "$1" >/dev/null 2>&1; then printf '  ok        %s\n' "$1"
         else printf '  optional  %-22s %s\n' "$1" "${2:-}"; fi; }

echo "Tools up to level $lvl"
need gcc "host compiler"
need make
need git
need nm "binutils"
need objdump "binutils"
opt  clang "used in Level 14 to compare against gcc"
opt  cppcheck "Level 2 (CI)"
if [ "$lvl" -ge 3 ]; then
  need arm-none-eabi-gcc "ARM toolchain (pin the version in the README)"
  need arm-none-eabi-objcopy
  need arm-none-eabi-size
  need openocd "flash and debug"
  if command -v gdb-multiarch >/dev/null 2>&1 || command -v arm-none-eabi-gdb >/dev/null 2>&1; then
    echo "  ok        gdb"
  else
    echo "  MISSING   gdb-multiarch or arm-none-eabi-gdb"; miss=1
  fi
fi
command -v gcc >/dev/null 2>&1 && echo "gcc: $(gcc --version | head -1)"
exit $miss
EOF
chmod +x tools/doctor.sh

# ---------------------------------------------------------------- docs/prerequisites.md
cat > docs/prerequisites.md <<'EOF'
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
EOF

# ---------------------------------------------------------------- README.md
cat > README.md <<'EOF'
# stm32_levels

Bottom-up STM32 bare-metal exercises. One item, one file, one commit.

This repo is a self-paced guide: a 266-item roadmap, the tooling to work through it, and
(on the author's branch) worked solutions. You can use it as a template for your own run.

- Roadmap (the index and acceptance tests): [docs/roadmap.md](docs/roadmap.md)
- Item cards (the exercises: why, experiment, questions, hints): [docs/items/](docs/items/README.md)
- What you need at each stage: [docs/prerequisites.md](docs/prerequisites.md)

## Rules

- `vendor/` is never edited.
- `board/` holds board facts, never logic.
- `lib/` only receives a module once a second level needs it. Blocks stay in their level until then.
- A level never includes `../other-level/x.h`.
- Every item leaves `notes/NNN.md` and, if it needs proof, `evidence/NNN/`.

## Layout

    levels/NN_name/      one folder per level
      Makefile           include ../../mk/host.mk   (levels 1-2, PC)
                         include ../../mk/target.mk (levels 3+, board)
      README.md          prerequisite line and item range for the level
      NNN_slug.c         one item = one file (+ NNN_*.h if needed)
      notes/NNN.md       "- Result: PASS" or "- Result: GAP", and what surprised you
      evidence/NNN/      captures, logs, map excerpts
    mk/                  shared makefiles
    tools/               doctor.sh, new_level.sh, new_item.sh, progress.sh, openocd.cfg, .gdbinit
    docs/                roadmap, prerequisites, items/ (cards + starter code), pin map, budgets
    board/               (from level 3) g431kb/ and host/ stubs
    lib/                 (later) promoted blocks: ringbuf, fsm, crc...
    vendor/              CMSIS headers, untouched

## Quick start (levels 1-2, PC only)

    make doctor                          # check your tools
    tools/new_level.sh 1                 # create levels/01_.../
    cd levels/01_*/
    ../../tools/new_item.sh 001          # starter files + notes (and a card, if the item has one)
    make 001                             # build and run item 001
    make 001 OPT=-O2 SAN=1               # other optimisation level / sanitizers
    make check                           # every item of the level
    cd ../.. && make progress            # how far along you are

An item passes when `make NNN` exits 0. Then write `- Result: PASS` in `notes/NNN.md`.

## Quick start (levels 3+, board)

    make 001          # build item 001 in the current level
    make 001 flash    # program the board
    make 001 debug    # gdb + openocd

## Using this as a template

Click **Use this template** on GitHub (or fork), then run the quick start above.
Keep your own solutions on your side: a solved item is a commit in your copy, not a change to the guide.
EOF

# ---------------------------------------------------------------- roadmap
[ -f docs/roadmap.md ] || echo "WARNING: docs/roadmap.md is missing"

# ---------------------------------------------------------------- level 1 + item 001
if [ -f docs/roadmap.md ]; then
  tools/new_level.sh 1 || true
  l1="$(ls -d levels/01_* 2>/dev/null | head -1 || true)"
  if [ -n "$l1" ] && ! ls "$l1"/001_*.c >/dev/null 2>&1; then
    ( cd "$l1" && ../../tools/new_item.sh 001 )
  fi
fi

echo
echo "Done. Next:"
echo "  make doctor"
echo "  cd levels/01_*/ && make 001      # fails until you solve it"
echo "  make progress                    # from the repo root"
