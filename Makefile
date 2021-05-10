PROJECT := sketchings
ENVIRONMENT ?= development
REPO := fast-playground_sketchings
DOCKER_NETWORK := $(PROJECT)_default
DOCKER_RUN := docker run --rm -t -e ENVIRONMENT=$(ENVIRONMENT) --user $(shell id -u):$(shell id -g) -v `pwd`:/sketchings --network $(DOCKER_NETWORK) $(DOCKER_ARGS) $(REPO):development
DOCKER_COMPOSE_UP := CURRENT_USER=$(shell id -u):$(shell id -g) docker-compose up -d

_echo_docker_run:
	@echo $(DOCKER_RUN)

build:
	@COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker-compose build sketchings

clean:
	@docker-compose down -v
	@rm -rf __pycache__ cov_html
	@find . -name '*.pyc' -exec rm {} \;

console: create_network
	@$(shell make run DOCKER_ARGS="$(DOCKER_ARGS) -i") ipython $(IPYTHON_ARGS)

create_network:
	@docker network create sketchings_default 1>/dev/null 2>&1 || exit 0

deps:
	@DOCKER_BUILDKIT=1 docker build \
		--target dev_deps \
		--cache-from $(REPO):development \
		--build-arg BUILDKIT_INLINE_CACHE=1 \
		-t $(REPO):build .
	@docker run --rm -v `pwd`:/sketchings $(REPO):build pipenv lock
	@docker rmi $(REPO):build

down:
	@docker-compose down

format: create_network
	@$(DOCKER_RUN) black -t py37 src $(BLACK_ARGS)
# 	@$(DOCKER_RUN) black -t py37 tests $(BLACK_ARGS)
	@$(DOCKER_RUN) isort .

lint: create_network
	@$(DOCKER_RUN) flake8 src --statistics
# 	@$(DOCKER_RUN) flake8 tests --statistics
	@$(DOCKER_RUN) bandit -r src
	@$(DOCKER_RUN) isort --check-only .

logs:
	@docker-compose logs -f

# TODO:	@make initdb initdb_test migrate migrate_test
new: up_db
	@sleep 3 # wait for postgres
	@$(DOCKER_COMPOSE_UP) sketchings

psql:
	@docker-compose exec --user=postgres postgres psql

redeps: deps build up

run:
	@make _echo_docker_run DOCKER_ARGS="$(DOCKER_ARGS) -i"

test: up_db
	@echo running: mypy "$(MYPY_ARGS)"
	@$(DOCKER_RUN) mypy $(MYPY_ARGS)
	@echo running: pytest "$(TEST_ARGS)"
	@$(DOCKER_RUN) pytest $(TEST_ARGS)

# constructs MYPY_ARGS based on what python files git thinks are relevant
unit_test:
	@make test TEST_ARGS="$(TEST_ARGS)" \
	MYPY_ARGS="$(shell git status --porcelain | awk '/[AM\?].*py/ {print $$2}' | paste -s -d' ' -)"

up:
	@$(DOCKER_COMPOSE_UP)

up_db:
	@$(DOCKER_COMPOSE_UP) postgres
