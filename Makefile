# docker building 
NAME   := devops-sig-8
TAG    := $$(git log -1 --pretty=%H)
IMG    := ${NAME}:${TAG}
LATEST := ${NAME}:latest

# kubernetes
K8S_DIR = ./k8s
K8S_VER = 1.12.7

.PHONY: all

all: hadolint login test build push

hadolint:
	@hadolint Dockerfile
	@echo hadolint ok

test: hadolint
	@echo docker build -t ${IMG} .
	@echo docker tag ${IMG} ${LATEST}

build:
	@docker build -t ${IMG} .
	@docker tag ${IMG} ${LATEST}
	@docker tag ${IMG} ${DOCKER_USER}/${IMG}

push:
	@docker push ${DOCKER_USER}/${NAME}

login:
	test -n "$$DOCKER_USER"
	test -n "$$DOCKER_PASS"
	@echo "docker user: $$DOCKER_USER"
	@docker login --username "$$DOCKER_USER" --password "$$DOCKER_PASS"

# test yaml files with kubeval
kubeval: $(K8S_DIR)/*
	@echo Running kubeval for version $(K8S_VER)
	@kubeval --kubernetes-version $(K8S_VER) --strict $^
	@echo kubeval looks ok, but notice that kubectl apply should be tested either way.

# deploy on current kubectl context
k8s:
	kubectl apply -f $(K8S_DIR)
# small helpers to test during apachebench
k8s_scale_1:
	kubectl scale --replicas=1 deployment/devops-sig-8-depl
k8s_scale_2:
	kubectl scale --replicas=2 deployment/devops-sig-8-depl

# apachebench
# short, to see if the service works
ab_short:
	kubectl run -i --rm --restart=Never --image=mocoso/apachebench apachebench -- bash -c "ab -n 10 -c 10 http://devops-sig-8/time"
# long to see if there are properly running rolling deployments
ab_long:
	kubectl run -i --rm --restart=Never --image=mocoso/apachebench apachebench -- bash -c "ab -n 100000 -c 10 http://devops-sig-8/time"

