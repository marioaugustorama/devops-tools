IMAGE_NAME = marioaugustorama/devops-tools
VERSION := $(shell cat version)
LATEST_TAG = latest

USER_ID := $(shell id -u)
GROUP_ID := $(shell id -g)

run:
	@if [ ! -d "home" ]; then \
			mkdir -p home; \
	fi

	@docker run -it --tty --rm \
		-u $(id -u ):$(id -g) \
		-v "$(PWD)/home:/tools" \
		-v "$(PWD)/backup:/backup" \
		-e LOCAL_USER_ID=$(id -u) \
		-e LOCAL_GROUP_ID=$(id -g) \
		$(IMAGE_NAME):$(VERSION) bash

clean:
	@docker rmi $(IMAGE_NAME):$(VERSION)


build:
	@docker build --no-cache \
		--build-arg VERSION="$(VERSION)" \
		--build-arg USER_ID="$(USER_ID)" \
		--build-arg GROUP_ID="$(GROUP_ID)" \
		--build-arg BUILD_DATE="$(shell date -u +'%Y-%m-%dT%H:%M:%SZ')" \
		-t $(IMAGE_NAME):$(VERSION) .

tag-latest:
	@docker tag $(IMAGE_NAME):$(VERSION) $(IMAGE_NAME):$(LATEST_TAG)

push: tag-latest
	@docker push $(IMAGE_NAME):$(VERSION)
	@docker push $(IMAGE_NAME):$(LATEST_TAG)

.PHONY: run clean build tag-latest push
