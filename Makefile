# DoExam umbrella: builds the all-in-one binary (server + embedded frontend) from the
# pinned submodules. Linux release builds run in CI (.github/workflows/release.yml).
.PHONY: help submodules client build smoke docker docker-smoke clean

SERVER := apps/server
CLIENT := apps/client
WEBDIST := $(SERVER)/app/server/web/dist
OUT := out

# product version (tag of this repo) + the pinned server/client commits (semver build metadata)
TAG ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
SERVER_SHA := $(shell git -C $(SERVER) rev-parse --short HEAD 2>/dev/null)
CLIENT_SHA := $(shell git -C $(CLIENT) rev-parse --short HEAD 2>/dev/null)
VERSION ?= $(TAG)+server.$(SERVER_SHA).client.$(CLIENT_SHA)
GOOS ?= linux
GOARCH ?= $(shell go env GOARCH)
BIN := $(OUT)/doexam-$(GOOS)-$(GOARCH)

## help: list the targets
help:
	@grep -E '^## ' Makefile | sed 's/## //'

## submodules: check out the pinned server and client commits
submodules:
	git submodule update --init --recursive

## client: build the frontend (dist/all) and precompress it
client:
	cd $(CLIENT) && npm ci --no-audit --no-fund && APP_VERSION=$(TAG) npm run build
	node scripts/precompress.mjs $(CLIENT)/dist/all

## build: the all-in-one binary for GOOS/GOARCH (default linux/<host arch>) in out/
build: client
	find $(WEBDIST) -mindepth 1 ! -name .keep -exec rm -rf {} +
	cp -R $(CLIENT)/dist/all/. $(WEBDIST)/
	cd $(SERVER) && CGO_ENABLED=0 GOOS=$(GOOS) GOARCH=$(GOARCH) go build -trimpath \
		-ldflags "-s -w -X main.version=$(VERSION)" -o $(CURDIR)/$(BIN) ./app/server
	@echo "built $(BIN) ($(VERSION))"

## smoke: run the built binary against DATABASE_URL and check API + frontend
smoke:
	@test -n "$(DATABASE_URL)" || (echo "set DATABASE_URL" && exit 1)
	$(BIN) migrate up
	rm -rf $(OUT)/smoke-storage
	PORT=18080 METRICS_ADDR= STORAGE_DIR=$(OUT)/smoke-storage $(BIN) & echo $$! > $(OUT)/smoke.pid; \
	scripts/smoke.sh http://localhost:18080 aio; rc=$$?; kill $$(cat $(OUT)/smoke.pid); exit $$rc

## docker: build the all-in-one image (doexam:local)
docker:
	docker build -f deploy/Dockerfile.aio --build-arg VERSION=$(VERSION) --build-arg TAG=$(TAG) -t doexam:local .

## clean: remove build output and the copied frontend
clean:
	rm -rf $(OUT) $(CLIENT)/dist
	find $(WEBDIST) -mindepth 1 ! -name .keep -exec rm -rf {} +
