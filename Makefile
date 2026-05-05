BUILD_DIRS=build.*

all:

system:
	./scripts/image

release:
	./scripts/image release

image:
	./scripts/image mkimage

noobs:
	./scripts/image noobs

clean:
	rm -rf $(BUILD_DIRS)

distclean:
	rm -rf ./.ccache* ./$(BUILD_DIRS)

src-pkg:
	tar cvJf sources.tar.xz sources .stamps

world:
	DEVICE=RG351P ARCH=aarch64 ./scripts/build_distro
	DEVICE=RG351V ARCH=aarch64 ./scripts/build_distro
	DEVICE=RG351MP ARCH=aarch64 ./scripts/build_distro
	DEVICE=RG552 ARCH=aarch64 ./scripts/build_distro

RG351P:
	DEVICE=RG351P ARCH=aarch64 ./scripts/build_distro

RG351V:
	DEVICE=RG351V ARCH=aarch64 ./scripts/build_distro

RG351MP:
	DEVICE=RG351MP ARCH=aarch64 ./scripts/build_distro

RG552:
	DEVICE=RG552 ARCH=aarch64 ./scripts/build_distro

lib32:
	DEVICE=RG351P ARCH=arm scripts/clean build-lib32
	DEVICE=RG351V ARCH=arm scripts/clean build-lib32
	DEVICE=RG351MP ARCH=arm scripts/clean build-lib32
	DEVICE=RG552 ARCH=arm scripts/clean build-lib32
	DEVICE=RG351P ARCH=arm scripts/build build-lib32
	DEVICE=RG351V ARCH=arm scripts/build build-lib32
	DEVICE=RG351MP ARCH=arm scripts/build build-lib32
	DEVICE=RG552 ARCH=arm scripts/build build-lib32

update:
	DEVICE=RG552 ARCH=aarch64 ./scripts/update_packages

package:
	./scripts/build ${PACKAGE}

package-clean:
	./scripts/clean ${PACKAGE}

## Docker builds - overview
# docker-* commands just wire up docker to call the normal make command via docker
# For example: make docker-RG351V will use docker to call: make RG351V
# All variables are scoped to docker-* commands to prevent weird collisions/behavior with non-docker commands

docker-%: DOCKER_IMAGE := $(shell if [ -n "${DOCKER_IMAGE}" ]; then echo `echo ${DOCKER_IMAGE} | tr '[:upper:]' '[:lower:]'`; else echo "ghcr.io/amberelec/amberelec-build"; fi)

# DOCKER_WORK_DIR is the directory in the Docker image - it used to be /work
#   Anytime this directory changes, you must run `make clean` similarly to moving the AmberELEC directory
docker-%: DOCKER_WORK_DIR := $(shell if [ -n "${DOCKER_WORK_DIR}" ]; then echo ${DOCKER_WORK_DIR}; else echo $$(pwd); fi)

# DEVELOPER_SETTINGS is a file containing developer speicific settings.  This will be mounted into the container if it exists
docker-%: DEVELOPER_SETTINGS := $(shell if [ -f "${HOME}/developer_settings.conf" ]; then echo "-v \"${HOME}/developer_settings.conf:${HOME}/developer_settings.conf\""; else echo ""; fi)

# UID is the user ID of current user - ensures docker sets file permissions properly
docker-%: UID := $(shell id -u)

# GID is the main user group of current user - ensures docker sets file permissions properly
docker-%: GID := $(shell id -g)

# PWD is 'present working directory' and passes through the full path to current dir to docker (becomes 'work')
docker-%: PWD := $(shell pwd)

# Command to use (either `docker` or `podman`)
docker-%: DOCKER_CMD:= $(shell if which docker 2>/dev/null 1>/dev/null; then echo "docker"; elif which podman 2>/dev/null 1>/dev/null; then echo "podman"; fi)

# Podman requires some extra args (`--userns=keep-id` and `--security-opt=label=disable`).  Set those args if using podman
docker-%: PODMAN_ARGS:= $(shell if ! which docker 2>/dev/null 1>/dev/null && which podman 2> /dev/null 1> /dev/null; then echo "--userns=keep-id --security-opt=label=disable -v /proc/mounts:/etc/mtab"; fi)

# Use 'sudo' if docker ps doesn't work.  In theory, other things than missing sudo could cause this.  But sudo needed is a common issue and easy to fix.
docker-%: SUDO := $(shell if which docker 2> /dev/null 1> /dev/null && ! docker ps -q 2> /dev/null 1> /dev/null ; then echo "sudo"; fi)

# Launch docker as interactive if this is an interactive shell (allows ctrl-c for manual and running non-interactive - aka: build server)
docker-%: INTERACTIVE=$(shell [ -t 0 ] && echo "-it")

# By default pass through anything after `docker-` back into `make`
docker-%: COMMAND=make $*

# Get .env file ready, filtering macOS-specific vars that don't exist in the Linux container
docker-%: $(shell env | grep -Ev "^(TMPDIR|SHELL)=" | grep "=" > .env && printf "TMPDIR=/tmp\nSHELL=/bin/bash\n" >> .env)

# If the user issues a `make docker-shell` just start up bash as the shell to run commands
docker-shell: COMMAND=bash

# Command: builds docker image locally from Dockerfile
docker-image-build:
	$(SUDO) $(DOCKER_CMD) build . -t $(DOCKER_IMAGE)

# Command: pulls latest docker image from dockerhub.  This will *replace* locally built version.
docker-image-pull:
	$(SUDO) $(DOCKER_CMD) pull $(DOCKER_IMAGE)

# Command: pushes the latest Docker image to dockerhub.  This is *not* needed to build. It updates the latest build image in dockerhub for everyone.
# Only AmberELEC admins in dockerhub can do this.
#
# You must login with: docker login --username <username> and provide either a password or token (from user settings -> security in dockerhub) before this will work.
docker-image-push:
	$(SUDO) $(DOCKER_CMD) push $(DOCKER_IMAGE)

# Wire up docker to call equivalent make files using % to match and $* to pass the value matched by %
# A named Docker volume (amberelec-build-$*) is used for the build directory so that all build
# operations happen on Docker's native ext4 filesystem rather than the sshfs-mounted macOS volume.
# This avoids mkstemp permission errors, linker failures, and git operation failures on sshfs.
# BUILD_DIR=/build tells the AmberELEC build system to use this native volume for all build output.
# The volume persists between runs, enabling incremental/resumable builds.
docker-%:
	@$(SUDO) $(DOCKER_CMD) volume inspect amberelec-build-$* >/dev/null 2>&1 || \
	  ( $(SUDO) $(DOCKER_CMD) volume create amberelec-build-$* >/dev/null && \
	    $(SUDO) $(DOCKER_CMD) run --rm --user 0:0 -v amberelec-build-$*:/build $(DOCKER_IMAGE) chmod 777 /build )
	$(SUDO) $(DOCKER_CMD) run $(PODMAN_ARGS) $(INTERACTIVE) --init --env-file .env --rm --user $(UID):$(GID) $(DEVELOPER_SETTINGS) -v $(PWD):$(DOCKER_WORK_DIR) -v $(HOME)/.cache:$(HOME)/.cache -v amberelec-build-$*:/build -w $(DOCKER_WORK_DIR) $(DOCKER_IMAGE) bash -c 'umask 022 && export BUILD_DIR=/build && $(COMMAND)'

