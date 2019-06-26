# docker building 
NAME   := devops-sig-8
TAG    := $$(git log -1 --pretty=%H)
IMG    := ${NAME}:${TAG}
LATEST := ${NAME}:latest
NAME_WATCHER   := devops-sig-8-watcher
IMG_WATCHER    := ${NAME_WATCHER}:${TAG}
LATEST_WATCHER := ${NAME_WATCHER}:latest

# kubernetes
K8S_DIR = ./k8s
K8S_VER = 1.12.7

.PHONY: all

all: hadolint docker_login test build push

test: test_app test_watcher
build: build_app build_watcher
push: push_app push_watcher


hadolint: Dockerfile Dockerfile.inotify
	@hadolint $^
	@echo hadolint ok

# app specific
test_app: hadolint
	@echo docker build -t ${IMG} .
	@echo docker tag ${IMG} ${LATEST}

build_app: check_login_user
	@echo "Building App container"
	@docker build -t ${IMG} .
	@docker tag ${IMG} ${LATEST}
	@docker tag ${IMG} ${DOCKER_USER}/${IMG}
	@docker tag ${IMG} ${DOCKER_USER}/${LATEST}

push_app: check_login_user
	@echo "Pushing App container"
	@docker push ${DOCKER_USER}/${NAME}

# watcher specific
test_watcher: hadolint 
	@echo docker build -t ${NAME_WATCHER} -f Dockerfile.inotify .
	@echo docker tag ${NAME_WATCHER} ${LATEST_WATCHER}

build_watcher: check_login_user
	@echo "Building Watcher container"
	@docker build -t ${IMG_WATCHER} -f Dockerfile.inotify .
	@docker tag ${IMG_WATCHER} ${LATEST_WATCHER}
	@docker tag ${IMG_WATCHER} ${DOCKER_USER}/${IMG_WATCHER}
	@docker tag ${IMG_WATCHER} ${DOCKER_USER}/${LATEST_WATCHER}

push_watcher: check_login_user
	@echo "Pushing Watcher container"
	@docker push ${DOCKER_USER}/${NAME_WATCHER}

# dockerhub
check_login_user:
	@echo "Checking if env var DOCKER_USER is set..."
	test -n "$$DOCKER_USER"

# tries to log in to dockerhub
docker_login: check_login_user
	@echo "docker user: $$DOCKER_USER"
	@docker login --username "$$DOCKER_USER" --password "$$DOCKER_PASS"

# kubernetes
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

