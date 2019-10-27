###
# Traefik

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

traefik: check-traefik-env
	docker-compose \
		-f docs/traefik.yml \
		-f docs/traefik.dev.yml \
	config > docker-stack.yml

deploy-traefik: check-traefik-env
	docker-compose \
		-f docs/traefik.yml \
		-f docs/traefik.deploy.yml \
	config > docker-stack.yml
	docker stack deploy -c docker-stack.yml $(TRAEFIK_STACKNAME)


###
# Portainer & Swarmpit

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

orchestrator: check-orchestrator-env
	docker-compose \
		-f docs/portainer.yml \
		-f docs/swarmpit.yml \
		-f docs/portainer.dev.yml \
		-f docs/swarmpit.dev.yml \
	config > docker-stack.yml

deploy-orchestrator: check-orchestrator-env
	docker-compose \
		-f docs/portainer.yml \
		-f docs/swarmpit.yml \
		-f docs/portainer.deploy.yml \
		-f docs/swarmpit.deploy.yml \
	config > docker-stack.yml
	docker stack deploy -c docker-stack.yml $(ORCHESTRATOR_STACKNAME)


###
# Operational commands

ps:
	# A lightly formatted version of docker ps
	docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}} ago'

check-stack:
ifeq ($(wildcard docker-stack.yml),)
	@echo "docker-stack.yml file is missing"
	@echo ">> use \033[1mmake \033[32mtraefik\033[37m|\033[32morchestrator\033[0m"
	@exit 1
endif

pull: check-stack
	docker network create $(TRAEFIK_PUBLIC_NETWORK) || true
	docker-compose -f docker-stack.yml pull

# shortcut to build docker-stack for both traefik and orchestrators
build: check-traefik-env check-orchestrator-env
	docker-compose \
		-f docs/traefik.yml \
		-f docs/traefik.dev.yml \
		-f docs/portainer.yml \
		-f docs/swarmpit.yml \
		-f docs/portainer.dev.yml \
		-f docs/swarmpit.dev.yml \
	config > docker-stack.yml
	@echo "\033[35mdocker-stack.yml\033[0m built for both \033[32mtraefik\033[37m and \033[32morchestrators\033[0m"

up: check-stack
	docker-compose -f docker-stack.yml up -d $(services)

down: check-stack
	docker-compose -f docker-stack.yml down

stop: check-stack
	docker-compose -f docker-stack.yml stop $(services)

logs: check-stack
	docker-compose -f docker-stack.yml logs --tail 10 -f $(services)
