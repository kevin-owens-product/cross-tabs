# For start we are expecting `yarn` is installed globally

ROOT_PATH := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
NODE_ENV ?= development
TARGET_ENV ?= development
TEST_OPTIONS ?= ""
DEBUG_MODE ?= ""

.PHONY: all
all: yarn.lock

dev_env:
	@echo " - setup DEV env"
	$(eval include dev.env)
	$(eval export)

.PHONY: no_watch_mode
no_watch_mode:
	@echo " - no watch mode build"
	$(eval WATCH_MODE=false)

yarn.lock: node_modules package.json
	$(MAKE clean)
	yarn install --production=false

node_modules:
	mkdir -p $@

.PHONY: clean
clean:
	find . -name elm-stuff | xargs rm -rf

.PHONY: clean_all
clean_all: clean
	rm -fr node_modules

.SILENT: format_validate
.PHONY: format_validate
format_validate:
	echo "Run format validate"
	npx prettier -c .

.PHONY: check_unused_scss_files
check_unused_scss_files:
	@echo "Check unused SCSS files"
	@./bin/check_unused_scss_files.sh

# Tests

.SILENT: test_share
.PHONY: test_share
test_share:
	echo "Run _share tests"
	cd client/_share && TARGET_ENV=test && find . -name '*.elm' | grep "^./tests" | xargs npx elm-test-rs $(TEST_OPTIONS) && cd -

.SILENT: test_xb2
.PHONY: test_xb2
test_xb2:
	echo "Run crosstab-builder 2.0 tests"
	cd client/crosstab-builder/XB2 && TARGET_ENV=test && find . -name '*.elm' | grep "^./tests" | xargs npx elm-test-rs $(TEST_OPTIONS) && cd -

.SILENT: test_xb
.PHONY: test_xb
test_xb: test_xb2

# All tests running

.PHONY: test
test: override TEST_OPTIONS = ""
test: test_xb

# Coverage

.SILENT: cover_share
.PHONY: cover_share
cover_share:
	echo "Checking coverage of _share"
	cd client/_share && elm-coverage --open && cd -

.SILENT: cover_xb2
.PHONY: cover_xb2
cover_xb2:
	echo "Checking coverage of crosstab-builder 2.0"
	cd client/crosstab-builder/XB2 && elm-coverage --open && cd -

.SILENT: cover_xb
.PHONY: cover_xb
cover_xb: cover_xb2

.SILENT: cover_tv
.PHONY: cover_tv
cover_tv: cover_tv1 cover_tv2

# All coverage check running

.PHONY: cover
cover: override TEST_OPTIONS = ""
cover: cover_share cover_xb cover_tv

# Build end development

PORT ?= 3900

.PHONY: start
start:
	npx webpack serve --hot --port 3000 --host 0.0.0.0

.PHONY: p2_serve_build_files_server
p2_serve_build_files_server:
	mkdir -p build && cd build && npx http-server -p $(PORT) --cors -c-1 &

.PHONY: p2_serve_build_files_server_no_background
p2_serve_build_files_server_no_background:
	mkdir -p build && cd build && npx http-server -p $(PORT) --cors -c-1

.PHONY: start_crosstabs_for_P2
start_crosstabs_for_P2: dev_env p2_serve_build_files_server build_xb2

.PHONY: start_tvrf_for_P2
start_tvrf_for_P2: dev_env p2_serve_build_files_server build_tv2

.PHONY: start_for_P2
start_for_P2: dev_env no_watch_mode build_tv2 build_xb2 p2_serve_build_files_server_no_background

.PHONY: build
build:
	npx webpack --progress

.PHONY: build_xb2
build_xb2:
	npx webpack --progress --config client/crosstab-builder/XB2/webpack.config.js

.PHONY: build_for_p20
build_for_p20: build_xb2 build_tv2

.PHONY: format
format:
	npx prettier -w .

# Running elm-review without args can lead to false positives about unused stuff, which is in fact used in tests
# To fix that, we search for all committed elm files and pass them explicitly to elm-review via xargs
.PHONY: review
review:
	npx elm-review client/

.PHONY: review-watch
review-watch:
	npx elm-review client/ --watch

.PHONY: review-styles
review-styles:
	npx stylelint 'client/**/*.scss'

.PHONY: fix-styles
fix-styles:
	npx stylelint --fix 'client/**/*.scss'

.PHONY: icons
icons:
	npx elm make --optimize --output icons.html ./client/_share/src/Icons/Overview.elm

.PHONY: pr
pr: review review-styles format test
	type -p gh > /dev/null && gh pr create -w || true

.PHONY: lint
lint: ## Lints the project with elm-review, eslint and stylelint.
	@echo "\033[36mReviewing project...\033[0m"
	npx elm-review client/
	npx stylelint 'client/**/*.scss'
