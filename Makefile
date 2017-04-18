# This file has been auto-generated.
# All changes will be lost, see Projectfile.
#
# Updated at 2017-04-18 15:20:56.803141

ENV ?= production
PYTHON ?= $(shell which python)
PYTHON_BASENAME ?= $(shell basename $(PYTHON))
PYTHON_REQUIREMENTS_FILE ?= requirements/$(ENV).txt
PYTHON_REQUIREMENTS_DEV_FILE ?= requirements/local.txt
QUICK ?= 
VIRTUAL_ENV ?= .virtualenv-$(PYTHON_BASENAME)
PIP ?= $(VIRTUAL_ENV)/bin/pip
PIP_INSTALL_OPTIONS ?= 
PYTEST ?= $(VIRTUAL_ENV)/bin/pytest
PYTEST_OPTIONS ?= --capture=no --cov=sandbox --cov-report html --reuse-db
SPHINX_OPTS ?= 
SPHINX_BUILD ?= $(VIRTUAL_ENV)/bin/sphinx-build
SPHINX_SOURCEDIR ?= docs
SPHINX_BUILDDIR ?= $(SPHINX_SOURCEDIR)/_build
YAPF ?= $(VIRTUAL_ENV)/bin/yapf
YAPF_OPTIONS ?= -rip
VERSION ?= $(shell git describe)
NPM ?= $(shell which yarn || which npm)
DJANGO_SETTINGS_MODULE ?= config.settings.$(ENV)
BUILD_DIR ?= .build
DOCKER_REGISTRY ?= 
DOCKER_USER ?= 
DOCKER_NAME ?= sandbox
DOCKER_IMAGE ?= $(DOCKER_USER)/$(DOCKER_NAME)
DOCKER ?= docker
DOCKER_PUSH ?= docker push
ROCKER ?= $(shell [ -x $(GOPATH)/bin/rocker ] && echo $(GOPATH)/bin/rocker || which rocker)
ROCKER_OPTIONS ?= 
ROCKER_DEPENDENCIES_HASH ?= $(word 1, $(shell md5sum ./setup.py ./package.json ./yarn.lock ./bower.json ./requirements/* | sort | md5sum))

.PHONY: $(SPHINX_SOURCEDIR) build clean format install install-dev lint run shell static test

run: build
	VERSION=$(ROCKER_DEPENDENCIES_HASH) docker-compose up

# Installs the local project dependencies.
install: $(VIRTUAL_ENV)
	if [ -z "$(QUICK)" ]; then \
	    $(PIP) install -U pip wheel $(PIP_INSTALL_OPTIONS) -r $(PYTHON_REQUIREMENTS_FILE) ; \
	    $(NPM) install --production ; \
	fi

# Installs the local project dependencies, including development-only libraries.
install-dev: $(VIRTUAL_ENV)
	if [ -z "$(QUICK)" ]; then \
	    $(PIP) install -U pip wheel $(PIP_INSTALL_OPTIONS) -r $(PYTHON_REQUIREMENTS_DEV_FILE) ; \
	    $(NPM) install ; \
	fi

# Cleans up the local mess.
clean:
	rm -rf build
	rm -rf dist

# Setup the local virtualenv, or use the one provided by the current environment.
$(VIRTUAL_ENV):
	virtualenv -p $(PYTHON) $(VIRTUAL_ENV)
	$(PIP) install -U pip wheel
	ln -fs $(VIRTUAL_ENV)/bin/activate activate-$(PYTHON_BASENAME)

lint: install-dev
	$(VIRTUAL_ENV)/bin/pylint --py3k sandbox -f html > pylint.html

test: install-dev
	$(PYTEST) $(PYTEST_OPTIONS) tests

$(SPHINX_SOURCEDIR): install-dev
	$(SPHINX_BUILD) -b html -D latex_paper_size=a4 $(SPHINX_OPTS) $(SPHINX_SOURCEDIR) $(SPHINX_BUILDDIR)/html

format: install-dev
	$(YAPF) $(YAPF_OPTIONS) .

# Generate all static assets needed for the application to run in production mode. In development mode, this is
# not required as the assets will be generated on the fly.
static: install-dev
	$(NPM) run build
	$(VIRTUAL_ENV)/bin/python manage.py collectstatic --noinput

# Build directory is a local clean clone of the repository used to generate docker images from a sane codebase.
$(BUILD_DIR):
	git clone . $(BUILD_DIR)
	(cd $(BUILD_DIR); git submodule update --init --recursive)

build:
	$(ROCKER) build -f config/docker/django/Rockerfile-dev -var Version=$(ROCKER_DEPENDENCIES_HASH) --attach $(ROCKER_OPTIONS) .

shell:
	VERSION=$(ROCKER_DEPENDENCIES_HASH) docker-compose run django bash
