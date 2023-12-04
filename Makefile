MIX_EXECUTABLE = mix

.PHONY: install
install:
	${MIX_EXECUTABLE} deps.get

.PHONY: test
test:
	${MIX_EXECUTABLE} test

.PHONY: docs
docs:
	${MIX_EXECUTABLE} docs

.PHONY: clean-docs
clean-docs:
	rm -rf ./docs

.PHONY: format
format:
	${MIX_EXECUTABLE} format

.PHONY: check-format
check-format:
	${MIX_EXECUTABLE} format --check-formatted
