.PHONY: build build-sol test test-sol lint \
	lint-sol code-size-check solhint style-check spell-check warnings-check \
	prettier

### Build ###

build:
	make build-sol

build-sol:
	forge build

### Test ###

test:
	make test-sol

test-sol:
	forge test -vv

### Lint ###

lint:
	make lint-sol

lint-sol:
	make solhint && make style-check && make spell-check && make warnings-check && make code-size-check

code-size-check:
	FOUNDRY_PROFILE=production forge build && python3 python/contract_size.py out

solhint:
	npx solhint -f table 'contracts/src/**/*.sol'

spell-check:
	npx cspell ./**/**/**.sol --gitignore

style-check:
	npx prettier --check .

warnings-check:
	FOUNDRY_PROFILE=production forge build --deny-warnings --force

### Prettier ###

prettier:
	npx prettier --write .
