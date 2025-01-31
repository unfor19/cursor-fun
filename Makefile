#!make
.ONESHELL:
.EXPORT_ALL_VARIABLES:
.PHONY: all $(MAKECMDGOALS)


UNAME := $(shell uname)
BASH_PATH:=$(shell which bash)

# Global .env
ifneq ("$(wildcard ${CURDIR}/.env)","")
include ${CURDIR}/.env
endif

ROOT_DIR:=${CURDIR}/${PROJECT_NAME}

# Project .env overrides global .env
ifneq ("$(wildcard ${ROOT_DIR}/.env)","")
include ${ROOT_DIR}/.env
endif

VENV_DIR_PATH:=${ROOT_DIR}/.VENV

ifndef REQUIREMENTS_FILE_PATH
REQUIREMENTS_FILE_PATH:=${ROOT_DIR}/requirements.txt
endif

# --- OS Settings --- START ------------------------------------------------------------
# Windows
ifneq (,$(findstring NT, $(UNAME)))
_OS:=windows
VENV_BIN_ACTIVATE:=${VENV_DIR_PATH}/Scripts/activate.bat
endif
# macOS
ifneq (,$(findstring Darwin, $(UNAME)))
_OS:=macos
VENV_BIN_ACTIVATE:=${VENV_DIR_PATH}/bin/activate
endif

ifneq (,$(findstring Linux, $(UNAME)))
_OS:=linux
VENV_BIN_ACTIVATE:=${VENV_DIR_PATH}/bin/activate
endif
# --- OS Settings --- END --------------------------------------------------------------

SHELL:=${BASH_PATH}

# Automatically activate virtual environment if it exists
ifneq (,$(wildcard ${VENV_BIN_ACTIVATE}))
ifeq (${_OS},macos)
SHELL:=source ${VENV_BIN_ACTIVATE} && ${SHELL}
endif
ifeq (${_OS},windows)
SHELL:=${VENV_BIN_ACTIVATE} && ${SHELL}
endif
ifeq (${_OS},linux)
SHELL:=source ${VENV_BIN_ACTIVATE} && ${SHELL}
endif
endif

ifndef PACKAGE_VERSION
PACKAGE_VERSION:=99.99.99
endif

ifndef DOCKER_IMAGE_TAG
DOCKER_IMAGE_TAG:=${PROJECT_NAME}:${PACKAGE_VERSION}
endif

# Removes blank rows - fgrep -v fgrep
# Replace ":" with "" (nothing)
# Print a beautiful table with column
help: ## Print this menu
	@echo
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's~:.* #~~' | column -t -s'#'
	@echo
usage: help


# To validate env vars, add "validate-MY_ENV_VAR"
# as a prerequisite to the relevant target/step
validate-%:
	@if [[ -z '${${*}}' ]]; then \
		echo 'ERROR: Environment variable $* not set' && \
		exit 1 ; \
	fi

print-vars: ## Print env vars
	@echo "VENV_BIN_ACTIVATE=${VENV_BIN_ACTIVATE}"
	@echo "REQUIREMENTS_FILE_PATH=${REQUIREMENTS_FILE_PATH}"
	@echo "VENV_DIR_PATH=${VENV_DIR_PATH}"
	@echo "CI=${CI}"

# --- VENV --- START ------------------------------------------------------------
## 
##VENV
##----
prepare: ## Create a Python virtual environment with venv
	python -m venv ${VENV_DIR_PATH} && \
	python -m pip install -U pip wheel setuptools build twine && \
	ls ${VENV_DIR_PATH}

install: ## Install Python packages
## Provide PACKAGE_NAME=<package_name> to install a specific package
## Example: make venv-install PACKAGE_NAME=requests
	@cd ${ROOT_DIR} && \
	if [[ -f "${REQUIREMENTS_FILE_PATH}" ]]; then \
		echo "Installing packages from ${REQUIREMENTS_FILE_PATH}" && \
		ls ${REQUIREMENTS_FILE_PATH} && \
		pip install -r "${REQUIREMENTS_FILE_PATH}" ${PACKAGE_NAME} ; \
	elif [[ -n "${PACKAGE_NAME}" ]]; then \
		echo "Installing package ${PACKAGE_NAME}" ; \
		pip install -U ${PACKAGE_NAME} ; \
	else \
		echo "ERROR: No requirements.txt file found and no package name provided" ; \
		exit 1 ; \
	fi

install-edit: ## Install CLI in editable mode
	cd ${ROOT_DIR} && \
	pip install -e .

requirements-update: ## Update requirements.txt with current packages
	cd ${ROOT_DIR} && \
	pip freeze | grep -v '\-e' > ${REQUIREMENTS_FILE_PATH} && \
	cat ${REQUIREMENTS_FILE_PATH}

venv-freeze: ## List installed packages
	cd ${ROOT_DIR} && \
	pip freeze

run: ## Run the application
	@cd ${ROOT_DIR} && \
	if [[ -d ${ROOT_DIR}/${SUBDIR} ]]; then \
		echo "Running ${PYTHON_SCRIPT} in ${SUBDIR}" ; \
		cd ${ROOT_DIR}/${SUBDIR} && \
		python ${PYTHON_SCRIPT} ; \
	else \
		echo "Running ${PYTHON_SCRIPT} in ${ROOT_DIR}" ; \
		python ${PYTHON_SCRIPT} ; \
	fi

venv-test-unittests: ## Run unit tests
	cd ${ROOT_DIR} && \
	python -m unittest discover -s tests -p 'test_*.py'

venv-test: venv-test-unittests

venv-test-clean:
	rm -f ${ROOT_DIR}/tests/data/input/*.output.*

.venv-build: 
	cd ${ROOT_DIR} && \
	rm -rf dist && python -m build --no-isolation .

.venv-publish: 
	cd ${ROOT_DIR} && \
	twine upload dist/* 

.venv-validate-release-package:
	cd ${ROOT_DIR} && \
	twine check ${ROOT_DIR}/dist/*
# --- VENV --- END --------------------------------------------------------------


# --- Release --- START ------------------------------------------------------------
##
###Release
##---
validate-release-version: validate-PACKAGE_VERSION 
	cd ${ROOT_DIR} && \
	echo ${PACKAGE_VERSION} > version && \
	scripts/version_validation.sh ${PACKAGE_VERSION}

build: .venv-build ## Build the package

validate-release-package: .venv-validate-release-package ## Validate the package with twine

publish: .venv-publish ## Publish the package
# --- Release --- END --------------------------------------------------------------


# --- Docker --- START ------------------------------------------------------------
##
###Docker
##---
docker-build: ## Build the Docker image
	cd ${ROOT_DIR} && \
	docker build -t ${DOCKER_IMAGE_TAG} .

docker-run: ## Run the Docker container
	cd ${ROOT_DIR} && \
	docker run -t --network host --rm -e DRY_RUN -e GITHUB_TOKEN ${DOCKER_IMAGE_TAG}

# --- Wrapper --- START ------------------------------------------------------------
##
###Wrapper
##---

wrapper-run-test:
	cd ${ROOT_DIR} && \
	$(MAKE) -s venv-test

.wrapper-venv-build:
	cd ${ROOT_DIR} && \
	$(MAKE) -s validate-release-version && \
	$(MAKE) -s build && \
	$(MAKE) -s validate-release-package

wrapper-build: .wrapper-venv-build ## Build the package and verify it


# --- Azure --- START ------------------------------------------------------------
##
###Azure
##---
azure-login:
	azd auth login

azure-up:
	cd ${ROOT_DIR} && \
	azd up

azure-down:
	cd ${ROOT_DIR} && \
	azd down
# --- Azure --- END ------------------------------------------------------------
