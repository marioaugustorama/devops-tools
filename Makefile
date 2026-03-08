SHELL := /bin/bash

# Load optional environment defaults
-include .env

# Image coordinates
IMAGE ?= marioaugustorama/devops-tools
TAG ?= $(shell cat version)

# Build args
APT_MIRROR ?= http://archive.ubuntu.com/ubuntu
APT_SECURITY_MIRROR ?= http://security.ubuntu.com/ubuntu
STRICT_CHECKSUM ?= 1

# Docker build options
BUILD_OPTS ?= --network=host

# Export variables to recipes
export IMAGE TAG APT_MIRROR APT_SECURITY_MIRROR BUILD_OPTS

.PHONY: help build push tag-latest run compose-up compose-up-vpn compose-shell compose-down bump-patch bump-minor bump-major version

help:
	@echo "Targets:"
	@echo "  build          Build image $(IMAGE):$(TAG) (host network by default)"
	@echo "  push           Push image $(IMAGE):$(TAG)"
	@echo "  tag-latest     Tag $(IMAGE):$(TAG) as latest and push"
	@echo "  run            Run using run.sh with IMAGE/TAG"
	@echo "  compose-up     Start conventional daemon mode via docker compose"
	@echo "  compose-up-vpn Start daemon mode with VPN capabilities (NET_ADMIN + /dev/net/tun)"
	@echo "  compose-shell  Open shell in compose daemon container"
	@echo "  compose-down   Stop/remove compose daemon container"
	@echo "  bump-<x>       Bump version file: patch|minor|major"
	@echo "  version        Print current version"
	@echo "  clean          Clean last builds"
	@echo "Variables: IMAGE, TAG, APT_MIRROR, APT_SECURITY_MIRROR, BUILD_OPTS"
	@echo "Examples:"
	@echo "  make build TAG=v1.17.0"
	@echo "  make build TAG=v1.17.0 APT_MIRROR=http://br.archive.ubuntu.com/ubuntu"
	@echo "  make push TAG=v1.17.0"


build:
	docker build $(BUILD_OPTS) \
	  --build-arg APT_MIRROR=$(APT_MIRROR) \
	  --build-arg APT_SECURITY_MIRROR=$(APT_SECURITY_MIRROR) \
	  --build-arg STRICT_CHECKSUM=$(STRICT_CHECKSUM) \
	  -t $(IMAGE):$(TAG) .

push:
	docker push $(IMAGE):$(TAG)

tag-latest:
	docker tag $(IMAGE):$(TAG) $(IMAGE):latest
	docker push $(IMAGE):latest

run:
	DEVOPS_IMAGE=$(IMAGE) DEVOPS_TAG=$(TAG) ./run.sh

compose-up:
	LOCAL_USER_ID=$$(id -u) LOCAL_GROUP_ID=$$(id -g) DOCKER_GID=$$(stat -c %g /var/run/docker.sock 2>/dev/null || echo 0) DEVOPS_IMAGE=$(IMAGE) DEVOPS_TAG=$(TAG) APP_VERSION=$(TAG) docker compose up -d

compose-up-vpn:
	LOCAL_USER_ID=$$(id -u) LOCAL_GROUP_ID=$$(id -g) DOCKER_GID=$$(stat -c %g /var/run/docker.sock 2>/dev/null || echo 0) DEVOPS_IMAGE=$(IMAGE) DEVOPS_TAG=$(TAG) APP_VERSION=$(TAG) docker compose -f compose.yaml -f compose.vpn.yaml up -d

compose-shell:
	docker compose exec devops-tools bash

compose-down:
	docker compose down

# Convenience target for Brazil mirror
.PHONY: build-br
build-br:
	$(MAKE) build APT_MIRROR=http://br.archive.ubuntu.com/ubuntu

.PHONY: build-insecure
build-insecure:
	$(MAKE) build STRICT_CHECKSUM=0

bump-patch:
	./scripts/version.sh bump patch --stage || true

bump-minor:
	./scripts/version.sh bump minor --stage || true

bump-major:
	./scripts/version.sh bump major --stage || true

version:
	@./scripts/version.sh show

clean: 
	docker system prune
