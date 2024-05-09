IMAGE_NAME = marioaugustorama/devops-tools:latest

run:
	@docker run -it --rm -v "./config/kube:/tools/.kube" $(IMAGE_NAME)

clean:
	@docker rmi marioaugustorama/devops-tools:latest

build:
	@docker build -t marioaugustorama/devops-tools:v1 .

.PHONY: run