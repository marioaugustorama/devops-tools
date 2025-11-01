SHELL := /bin/bash

# Image coordinates
IMAGE ?= marioaugustorama/devops-tools
TAG ?= $(shell cat version)

# Build args
APT_MIRROR ?= http://archive.ubuntu.com/ubuntu
APT_SECURITY_MIRROR ?= http://security.ubuntu.com/ubuntu

# Docker build options
BUILD_OPTS ?= --network=host

.PHONY: help build push tag-latest run bump-patch bump-minor bump-major version

help:
	@echo "Targets:"
	@echo "  build          Build image $(IMAGE):$(TAG) (host network by default)"
	@echo "  push           Push image $(IMAGE):$(TAG)"
	@echo "  tag-latest     Tag $(IMAGE):$(TAG) as latest and push"
	@echo "  run            Run using run.sh with IMAGE/TAG"
	@echo "  bump-<x>       Bump version file: patch|minor|major"
	@echo "  version        Print current version"
	@echo "Variables: IMAGE, TAG, APT_MIRROR, APT_SECURITY_MIRROR, BUILD_OPTS"

build:
	docker build $(BUILD_OPTS) \
	  --build-arg APT_MIRROR=$(APT_MIRROR) \
	  --build-arg APT_SECURITY_MIRROR=$(APT_SECURITY_MIRROR) \
	  -t $(IMAGE):$(TAG) .

push:
	docker push $(IMAGE):$(TAG)

tag-latest:
	docker tag $(IMAGE):$(TAG) $(IMAGE):latest
	docker push $(IMAGE):latest

run:
	DEVOPS_IMAGE=$(IMAGE) DEVOPS_TAG=$(TAG) ./run.sh

bump-patch:
	./scripts/version.sh bump patch --stage || true

bump-minor:
	./scripts/version.sh bump minor --stage || true

bump-major:
	./scripts/version.sh bump major --stage || true

version:
	@./scripts/version.sh show

