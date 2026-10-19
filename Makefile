PYTHON ?= python3

.PHONY: test

test:
	$(PYTHON) tools/verify.py
