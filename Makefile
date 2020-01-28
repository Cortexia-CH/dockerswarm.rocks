###
# Usual suspects... docker management

ps:
	docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}} ago'

init: check-traefik-env check-orchestrator-env check-postgres-env

config: config-traefik config-orchestrator config-postgres

config-postgres: check-postgres-env
	docker-compose \
		-f docs/postgres.yml \
		-f docs/postgres.dev.yml \
	config > docker-stack-postgres.yml

config-traefik: check-traefik-env
	docker-compose \
		-f docs/traefik.yml \
		-f docs/traefik.dev.yml \
	config > docker-stack-traefik.yml

config-orchestrator: check-orchestrator-env
	docker-compose \
		-f docs/portainer.yml \
		-f docs/swarmpit.yml \
		-f docs/portainer.dev.yml \
		-f docs/swarmpit.dev.yml \
	config > docker-stack-orchestrator.yml

local-traefik: config-traefik
	rm docker-stack.yml && ln -s docker-stack-traefik.yml docker-stack.yml

local-postgres: config-postgres
	rm docker-stack.yml && ln -s docker-stack-postgres.yml docker-stack.yml

local-orchestrator: config-orchestrator
	rm docker-stack.yml && ln -s docker-stack-orchestrator.yml docker-stack.yml

pull: check-stack
	docker-compose -f docker-stack.yml pull $(services)

up: check-stack
	docker-compose -f docker-stack.yml up -d $(services)

down: check-stack
	docker-compose -f docker-stack.yml down

stop: check-stack
	docker-compose -f docker-stack.yml stop $(services)

logs: check-stack
	docker-compose -f docker-stack.yml logs --tail 10 -f $(services)

# no build

# no push

deploy: check-traefik-env check-orchestrator-env check-postgres-env
	docker-compose \
		-f docs/postgres.yml \
		-f docs/postgres.deploy.yml \
	config > docker-stack-postgres.yml
	docker stack deploy -c docker-stack-postgres.yml $(PG_STACKNAME)

	docker-compose \
		-f docs/traefik.yml \
		-f docs/traefik.deploy.yml \
	config > docker-stack-traefik.yml
	docker stack deploy -c docker-stack-traefik.yml $(TRAEFIK_STACKNAME)

	docker-compose \
		-f docs/portainer.yml \
		-f docs/swarmpit.yml \
		-f docs/portainer.deploy.yml \
		-f docs/swarmpit.deploy.yml \
	config > docker-stack-orchestrator.yml
	docker-auto-labels docker-stack-orchestrator.yml
	docker stack deploy -c docker-stack-orchestrator.yml $(ORCHESTRATOR_STACKNAME)
	

###
# Helpers for initialization

check-traefik-env:
ifeq ($(wildcard .traefik.env),)
	cp .sample.traefik.env .traefik.env
	@echo "Generated \033[32m.traefik.env\033[0m"
	@echo "  \033[31m  >> Check its default values\033[0m"
	@exit 1
else
include .traefik.env
export
endif

check-orchestrator-env:
ifeq ($(wildcard .orchestrator.env),)
	cp .sample.orchestrator.env .orchestrator.env
	@echo "Generated \033[32m.orchestrator.env\033[0m"
	@echo "  \033[31m>> Check its default values\033[0m"
	@exit 1
else
include .orchestrator.env
export
endif

check-postgres-env:
ifeq ($(wildcard .postgres.env),)
	cp .sample.postgres.env .postgres.env
	@echo "Generated \033[32m.postgres.env\033[0m"
	@echo "  \033[31m>> Check its default values\033[0m"
	@exit 1
else
include .postgres.env
export
endif

check-stack:
ifeq ($(wildcard docker-stack.yml),)
	@echo "docker-stack.yml file is missing"
	@echo ">> use \033[1mmake \033[32mtraefik\033[37m|\033[32morchestrator\033[0m"
	@exit 1
endif
