# Root: runs `check` in every level. Each level decides what check means
# (host levels: build and run every item; board levels: build every item).
LEVELS := $(wildcard levels/*/)

check:
	@for d in $(LEVELS); do echo "== $$d"; $(MAKE) --no-print-directory -C $$d check || exit 1; done

doctor:
	@tools/doctor.sh $(LEVEL)

progress:
	@tools/progress.sh

.PHONY: check doctor progress
