# Makefile for devcontainer image management

IMAGE_NAME ?= lunarengine-devcontainer
TAG ?= latest
DOCKERFILE ?= Dockerfile
CONTEXT ?= .



# Set default container engine (can override with DOCKER=podman)
DOCKER ?= docker

.PHONY: default help container-image-build container-image-sign run-container run-cmake-native run-cmake-container setup-deps-in-container

default: help

help:
	@echo "### lunarengine Makefile"
	@echo "Vars"
	@echo "  DOCKER=docker"
	@echo "  DOCKER=podman"
	@echo ""
	@echo "  make build-in-container DOCKER=podman"
	@echo ""
	@echo "Available tasks"
	@echo ""
	@echo "  make build"
	@echo "  make build-in-container"
	@echo ""
	@echo "  make container-image-build	- Build the devcontainer image from Dockerfile"
	@echo "  make container-image-sign	- Sign the tagged image (docker trust sign)"
	@echo "  make container-run			- Run the container interactively with workspace mounted"
	@echo "  make container-run-cmake   - Run cmake inside the container (using $(DOCKER))"
	@echo "  make run-container		    - Run the container interactively with workspace mounted"
	@echo "  make run-cmake-container   - Run cmake inside the container (using $(DOCKER))"
	@echo "  make run-cmake-native	    - Run cmake natively on host without containers"
	@echo "  make help				    - Show this help message"
	@echo "  make setup-deps-in-container - Run dependency setup script (build.sh dependencies) inside the container"

# Run dependency setup script inside the container
setup-deps-in-container:
	$(DOCKER) run --rm -it \
		-v $(CURDIR):/workspace \
		--name $(IMAGE_NAME)-setup-deps \
		$(IMAGE_NAME):$(TAG) bash -c 'cd librebox && ./build.sh dependencies'


# Run cmake natively on host
run-cmake-native:
	cmake -S librebox -B librebox/build


container-image-build:
	$(DOCKER) build -f $(DOCKERFILE) -t $(IMAGE_NAME):$(TAG) $(CONTEXT)

container-image-sign:
	$(DOCKER) trust sign $(IMAGE_NAME):$(TAG)

container-run: run-container

DOCKER=podman
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
	$(DOCKER_OPTS)

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

#-v $(CURDIR):/workspace \

run-container:
	$(DOCKER) run --rm -it \
		${DOCKER_RUN_OPTS} \
		--name ${IMAGE_NAME}-container \
		${IMAGE_NAME}:${TAG} ${DOCKER_CMD}

# Run cmake inside the container
run-cmake-container:
	$(DOCKER) run --rm -it \
		${DOCKER_BUILD_OPTS} \
		--name $(IMAGE_NAME)-cmake \
		$(IMAGE_NAME):$(TAG) \
		/workspace/librebox/build.sh all
		@#cmake -S /workspace/librebox -B /workspace/librebox/build

build-in-container:
	$(MAKE) container-image-build
	$(MAKE) run-cmake-container

build-dependencies:
	./librebox/build.sh dependencies

build-engine:
	./librebox/build.sh engine

build:
	$(MAKE) run-cmake-native

run-lunarengine:
	./librebox/dist/LunarApp

run: run-lunarengine

# TODO: tests
test:
	./librebox/dist/LunarApp