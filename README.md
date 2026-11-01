# stm32_levels

Bottom-up STM32 bare-metal exercises. One item, one file, one commit.

This repo is a self-paced guide: a 266-item roadmap, the tooling to work through it, and
the worked solutions on `main`. `guide` is the clean template: no levels, no solutions.

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
> [!WARNING]
> `levels/` is not in `guide`: every level folder is derived from the roadmap by `tools/new_level.sh`.

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

Fork or clone this repo and run the quick start above. Keep your own solutions on your side:
a solved item is a commit in your copy, not a change to the guide.

`guide` carries no `levels/`: you create each level with `tools/new_level.sh` as you reach it.