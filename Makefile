# Makefile for devcontainer image management

IMAGE_NAME ?= lunarengine-devcontainer
TAG ?= latest
DOCKERFILE ?= Dockerfile
CONTEXT ?= .



# Set default container engine (can override with DOCKER=podman)
DOCKER ?= docker


.PHONY: \
  default help help-test help-test-list \
  build build-in-container build-native build-engine build-engine-no-clean build-dependencies \
  container-image-build container-image-sign container-run container-run-build container-run-build-all container-run-build-dependencies container-run-build-engine container-run-cmake \
  run run-lunarengine \
  test test-all test-debug test-list-tests test-app

default: help

help:
	@echo "### lunarengine Makefile"
	@echo "## Variables and Usage"
	@echo "  DOCKER=docker  # (default)"
	@echo "  DOCKER=podman"
	@echo "  make build-in-container DOCKER=podman   # Use podman for container builds"
	@echo ""
	@echo "## Build, Test, and Run Tasks with and without containers"
	@echo "  make build                   # Build 'build.sh'     (in container)"
	@echo "  make build-in-container      # Build 'build.sh all' (in container)"
	@echo "  make build-all               # Build 'build.sh all' (native)"
	@echo "  make build-dependencies      # Build 'build.sh dependencies' only (native)"
	@echo "  make build-engine            # Build 'build.sh engine' only (native)"
	@echo "  make build-cmake-native      # Build 'cmake' (native)"
	@echo ""
	@echo "  make container-image-build   # Build devcontainer image from Dockerfile ['docker build']"
	@echo "  make container-image-sign    # Sign the tagged image ['docker trust sign']"
	@echo ""
	@echo "  make container-run           # Run /bin/bash      (in container)"
	@echo "  make container-run-build     # Run 'build.sh'     (in container)"
	@echo "  make container-run-build-all # Run 'build.sh all' (in container)"
	@echo "  make container-run-build-dependencies # Run 'build.sh dependencies' (in container)"
	@echo "  make container-run-build-engine       # Run 'build.sh engine' (in container)"
	@echo "  make container-run-cmake     # Run cmake in container (using $(DOCKER))"
	@echo "  make run-container           # Run /bin/bash      (in container)
	@echo ""
	@echo "  make run                    # Run the main LunarEngine app"
	@echo "  make run-in-container       # Run the main LunarEngine app (container)"
	@echo "  make run-container           # Run /bin/bash      (in container)
	@echo ""
	@echo "  make test                   # Run all tests (default: test-all)"
	@echo "  make test-all               # Run all tests with gtest"
	@echo "  make test-debug             # Run tests with debug options"
	@echo "  make test-list-tests        # List all available tests"
	@echo ""
	@echo "## Help tasks"
	@echo "  make help                   # Show this help message"
	@echo "  make help-test              # Show test help and options"
	@echo ""


container-run-build-all:
	# Run `build.sh all` inside the container
	# (Note that this will be deleted if DOCKER_RM=--rm as is the default)
	$(DOCKER) run ${DOCKER_RM} -it \
		$(DOCKER_RUN_OPTS) \
		--name $(IMAGE_NAME)-setup-deps \
		$(IMAGE_NAME):$(TAG) bash -c 'cd librebox && ./build.sh all'

container-run-build-dependencies:
	# Run `build.sh dependencies` inside the container
	# (Note that this will be deleted if DOCKER_RM=--rm as is the default)
	$(DOCKER) run ${DOCKER_RM} -it \
		$(DOCKER_RUN_OPTS) \
		--name $(IMAGE_NAME)-build-dependencies \
		$(IMAGE_NAME):$(TAG) bash -c 'cd librebox && ./build.sh dependencies'

container-run-build-engine:
	# Run `build.sh engine` inside the container
	# (Note that this will be deleted if DOCKER_RM=--rm as is the default)
	$(DOCKER) run ${DOCKER_RM} -it \
		$(DOCKER_RUN_OPTS) \
		--name $(IMAGE_NAME)-build-engine \
		$(IMAGE_NAME):$(TAG) bash -c 'cd librebox && ./build.sh engine'

container-run-build-engine-no-clean:
	# Run `build.sh engine --no-clean` inside the container
	# (Note that this will be deleted if DOCKER_RM=--rm as is the default)
	$(DOCKER) run ${DOCKER_RM} -it \
		$(DOCKER_RUN_OPTS) \
		--name $(IMAGE_NAME)-build-engine-no-clean \
		$(IMAGE_NAME):$(TAG) bash -c 'cd librebox && ./build.sh engine --no-clean'


# Run cmake natively on host
build-cmake:
	cmake -S librebox -B librebox/build

build-native: build-cmake


container-image-build:
	$(DOCKER) build -f $(DOCKERFILE) -t $(IMAGE_NAME):$(TAG) $(CONTEXT)

container-image-sign:
	$(DOCKER) trust sign $(IMAGE_NAME):$(TAG)

container-run: run-container

#DOCKER=docker
#DOCKER=docker
#DOCKER=nerdctl

# Set this to "" to not remove container instances after running
DOCKER_RM ?= --rm

## For a system with one GPU:
# DOCKER_GPU_DEVICES= \
#		--device /dev/dri/card0 \
#		--device /dev/dri/renderD129  # 128?  ls -al /dev/dri

## For a system with two GPUs:
DOCKER_GPU_DEVICES= \
		--device /dev/dri/card0 \
		--device /dev/dri/renderD129 \
		--device /dev/dri/card1 \
		--device /dev/dri/renderD128

DOCKER_GPU_OPTS= \
		--device nvidia.com/gpu=all \
		--gpus=all \
		--hooks-dir=/etc/containers/oci/hooks.d/

DOCKER_SECURITY_OPT_LABEL=label=disable
#DOCKER_SECURITY_OPT_LABEL=label=type:container_runtime_t

#DOCKER_LOG_LEVEL=trace
DOCKER_LOG_LEVEL=debug
DOCKER_LOG_LEVEL=info

#DOCKER_USER=root
#DOCKER_USER=appuser
DOCKER_USER=ubuntu
DOCKER_HOME_USER=/home/${DOCKER_USER}
DOCKER_CMD=bash --login
DOCKER_OPTS=

DOCKER_VOLUMES_subuids=-v /etc/subuids -v /etc/subgids

ifeq (${HISTFILE},)
DOCKER_HOST_BASH_HISTORY=${HOME}/.bash_history
else
DOCKER_HOST_BASH_HISTORY=${HISTFILE}
endif
DOCKER_VOLUMES_bashhistory=-v ${DOCKER_HOST_BASH_HISTORY}:${DOCKER_HOME_USER}/.bash_history

#DOCKER_VOLUMES_dotenv=-v ${PWD}/.env.devcontainer.sh:/.env:rw 

#DOCKER_VOLUMES_workspace=-v ${CURDIR}/..:/workspace 

#WORKSPACES_SRC?=../
WORKSPACES_SRC ?= ${CURDIR}
DOCKER_VOLUMES_workspaces=-v ${WORKSPACES_SRC}:/workspace

#DOCKER_VOLUMES_vinegar_versions=-v ${PWD}/.local_share_vinegar_versions:${DOCKER_HOME_USER}/.local/share/vinegar/versions
#DOCKER_VOLUMES_vinegar=-v ${PWD}/.local_share_vinegar:/${DOCKER_HOME_USER}/.local/share/vinegar

DOCKER_VOLUMES=${DOCKER_VOLUMES_workspaces} ${DOCKER_VOLUMES_dotenv} ${DOCKER_VOLUMES_bashhistory} ${DOCKER_VOLUMES_subuids} ${DOCKER_VOLUMES_vinegar}

PODMAN_USERNS_OPTS=keep-id
PODMAN_ROOTLESS_OPTS=--userns=${PODMAN_USERNS_OPTS}

DOCKER_BUILD_OPTS= \
	--user="${DOCKER_USER}" \
	--security-opt="${DOCKER_SECURITY_OPT_LABEL}" \
	${PODMAN_ROOTLESS_OPTS} \
	${DOCKER_VOLUMES} \
	${DOCKER_OPTS}

DOCKER_RUN_OPTS= \
	--user="${DOCKER_USER}" \
	--security-opt="${DOCKER_SECURITY_OPT_LABEL}" \
	${PODMAN_ROOTLESS_OPTS} \
	--net=host \
	--ipc=host \
	--log-level="${DOCKER_LOG_LEVEL}" \
	${DOCKER_GPU_OPTS} \
	-e DISPLAY \
	-e HOME="${DOCKER_HOME_USER}" \
	${DOCKER_GPU_DEVICES} \
	${DOCKER_VOLUMES} \
	-v ${XAUTHORITY}:/root/.Xauthority:ro \
	-v ${XAUTHORITY}:${DOCKER_HOME_USER}/.Xauthority:ro \
	-v ${XAUTHORITY}:${XAUTHORITY}:ro \
	$(DOCKER_OPTS) 


run-container:
	$(DOCKER) run ${DOCKER_RM} -it \
		${DOCKER_RUN_OPTS} \
		--name ${IMAGE_NAME}-container \
		${IMAGE_NAME}:${TAG} ${DOCKER_CMD}

# Run cmake inside the container
#cmake -S /workspace/librebox -B /workspace/librebox/build

build-in-container:
	$(MAKE) container-image-build
	$(MAKE) container-run-build-all

container-run-build: build-in-container


container-run-test:
	$(MAKE) run-container DOCKER_CMD="make test-all"

test-in-container: container-run-test


build-all:
	./librebox/build.sh all

build-dependencies:
	./librebox/build.sh dependencies

build-engine:
	./librebox/build.sh engine

build-engine-no-clean:
	./librebox/build.sh engine --no-clean


# default build task:
build:
	$(MAKE) build-in-container


APP_BIN_NAME ?= LunarApp
APP_BIN_PATH ?= ./librebox/dist/${APP_BIN_NAME}

run-lunarengine:
	${APP_BIN_PATH}

run: run-lunarengine


run-container-app:
	$(DOCKER) run ${DOCKER_RM} -it \
		${DOCKER_RUN_OPTS} \
		--name ${IMAGE_NAME}-container \
		${IMAGE_NAME}:${TAG} ${APP_BIN_PATH}

run-in-container: run-container-app

# TODO: add more tests
test-app:
	${APP_BIN_PATH} --version
	${APP_BIN_PATH} --path ./examples/helloworld.lua
	${APP_BIN_PATH}
	${APP_BIN_PATH} --help
	${APP_BIN_PATH} --version


## tests with gtest/ctest googletest

TEST_BIN_NAME ?= lunarengine_tests
TEST_BIN ?= ./librebox/build/tests/${TEST_BIN_NAME}

GTEST_OPTIONS1=--gtest_brief=0 --gtest_output=json:testresults.json
#GTEST_OPTIONS2 ?= --gtest_break_on_failure
GTEST_OPTIONS2 ?= --gtest_throw_on_failure


help-test:
	@echo -e "\n## Test help\n"
	${TEST_BIN} --help
	@echo "make test-list-tasks"
	${TEST_BIN} --gtest_list_tests
	@echo ''

test: test-all

test-all:
	@echo "## Starting TEST RUN ..."
	@echo ""
	${TEST_BIN} ${GTEST_OPTIONS1}
	@echo ""
	@echo "## TEST RUN COMPLETE"
	@echo ""

test-debug:
	@echo "## Starting TEST RUN ..."
	@echo ""
	${TEST_BIN} ${GTEST_OPTIONS1} ${GTEST_OPTIONS2}
	@echo ""
	@echo "## TEST RUN COMPLETE"
	@echo ""

# `ctest` is the googletest test runner
# which is an option instead of ${TEST_BIN_NAME}

# CMAKE_BUILD_TYPE ?= Release
# test-ctest:
# 	ctest --output-on-failure --build-config "${CMAKE_BUILD_TYPE}"

test-list-tests:
	${TEST_BIN} --gtest_list_tests