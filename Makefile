check:
	@for d in levels/*/; do $(MAKE) -C $$d || exit 1; done

.PHONY: check