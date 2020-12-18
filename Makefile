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


deploy-postgres: check-postgres-env
	docker-compose \
		-f docs/postgres.yml \
		-f docs/postgres.deploy.yml \
	config > docker-stack-postgres.yml
	docker-auto-labels docker-stack-postgres.yml
	docker stack deploy -c docker-stack-postgres.yml $(PG_STACKNAME)

deploy-traefik: check-traefik-env
	docker-compose \
		-f docs/traefik.yml \
		-f docs/traefik.deploy.yml \
	config > docker-stack-traefik.yml
	docker stack deploy -c docker-stack-traefik.yml $(TRAEFIK_STACKNAME)

deploy-orchestrator: check-orchestrator-env
	docker-compose \
		-f docs/portainer.yml \
		-f docs/swarmpit.yml \
		-f docs/portainer.deploy.yml \
		-f docs/swarmpit.deploy.yml \
	config > docker-stack-orchestrator.yml
	docker-auto-labels docker-stack-orchestrator.yml
	docker stack deploy -c docker-stack-orchestrator.yml $(ORCHESTRATOR_STACKNAME)
	

deploy-all: deploy-postgres deploy-traefik deploy-orchestrator

ip-tables: check-traefik-env
	# traefik TCP routing is limited:
	# - it cannot filter by domain -> different environments need different ports
	# - it cannot use middleware -> use of iptables

	# Therefore, this command is used to setup the firewall on the node manager, thanks to iptables rules
	# They block the traffick to DB containers, except for given IPs:
	# - infomaniak prod server
	# - hymexia network
	# - localhost (to be able to run from node)
	#
	#
	## MONGO DEV
	# clean existing rules
	sudo iptables -D DOCKER -d $(OLD_TRAEFIK_CONTAINER_IP)/32 ! -i docker_gwbridge -o docker_gwbridge -p tcp -m tcp --dport $(MONGO_PORT_DEV) -j ACCEPT || true
	sudo iptables -D DOCKER -d $(OLD_TRAEFIK_CONTAINER_IP)/32 ! -i docker_gwbridge -s 83.166.154.157 -o docker_gwbridge -p tcp -m tcp --dport $(MONGO_PORT_DEV) -j ACCEPT || true
	sudo iptables -D DOCKER -d $(OLD_TRAEFIK_CONTAINER_IP)/32 ! -i docker_gwbridge -s 46.140.105.162 -o docker_gwbridge -p tcp -m tcp --dport $(MONGO_PORT_DEV) -j ACCEPT || true
	sudo iptables -D DOCKER -d $(OLD_TRAEFIK_CONTAINER_IP)/32 ! -i docker_gwbridge -s 127.0.0.1 -o docker_gwbridge -p tcp -m tcp --dport $(MONGO_PORT_DEV) -j ACCEPT || true
	sudo iptables -D DOCKER -i eth0 -p tcp -m tcp --dport $(MONGO_PORT_DEV) -j DROP || true
	# restrict acces
	sudo iptables -A DOCKER -d $(TRAEFIK_CONTAINER_IP)/32 ! -i docker_gwbridge -s 83.166.154.157 -o docker_gwbridge -p tcp -m tcp --dport $(MONGO_PORT_DEV) -j ACCEPT
	sudo iptables -A DOCKER -d $(TRAEFIK_CONTAINER_IP)/32 ! -i docker_gwbridge -s 46.140.105.162 -o docker_gwbridge -p tcp -m tcp --dport $(MONGO_PORT_DEV) -j ACCEPT
	sudo iptables -A DOCKER -d $(TRAEFIK_CONTAINER_IP)/32 ! -i docker_gwbridge -s 127.0.0.1 -o docker_gwbridge -p tcp -m tcp --dport $(MONGO_PORT_DEV) -j ACCEPT
	sudo iptables -A DOCKER -i eth0 -p tcp -m tcp --dport $(MONGO_PORT_DEV) -j DROP

	## MONGO QA
	# clean existing rules
	sudo iptables -D DOCKER -d $(OLD_TRAEFIK_CONTAINER_IP)/32 ! -i docker_gwbridge -o docker_gwbridge -p tcp -m tcp --dport $(MONGO_PORT_QA) -j ACCEPT || true
	sudo iptables -D DOCKER -d $(OLD_TRAEFIK_CONTAINER_IP)/32 ! -i docker_gwbridge -s 83.166.154.157 -o docker_gwbridge -p tcp -m tcp --dport $(MONGO_PORT_QA) -j ACCEPT || true
	sudo iptables -D DOCKER -d $(OLD_TRAEFIK_CONTAINER_IP)/32 ! -i docker_gwbridge -s 46.140.105.162 -o docker_gwbridge -p tcp -m tcp --dport $(MONGO_PORT_QA) -j ACCEPT || true
	sudo iptables -D DOCKER -d $(OLD_TRAEFIK_CONTAINER_IP)/32 ! -i docker_gwbridge -s 127.0.0.1 -o docker_gwbridge -p tcp -m tcp --dport $(MONGO_PORT_QA) -j ACCEPT || true
	sudo iptables -D DOCKER -i eth0 -p tcp -m tcp --dport $(MONGO_PORT_QA) -j DROP || true
	# restrict acces
	sudo iptables -A DOCKER -d $(TRAEFIK_CONTAINER_IP)/32 ! -i docker_gwbridge -s 83.166.154.157 -o docker_gwbridge -p tcp -m tcp --dport $(MONGO_PORT_QA) -j ACCEPT
	sudo iptables -A DOCKER -d $(TRAEFIK_CONTAINER_IP)/32 ! -i docker_gwbridge -s 46.140.105.162 -o docker_gwbridge -p tcp -m tcp --dport $(MONGO_PORT_QA) -j ACCEPT
	sudo iptables -A DOCKER -d $(TRAEFIK_CONTAINER_IP)/32 ! -i docker_gwbridge -s 127.0.0.1 -o docker_gwbridge -p tcp -m tcp --dport $(MONGO_PORT_QA) -j ACCEPT
	sudo iptables -A DOCKER -i eth0 -p tcp -m tcp --dport $(MONGO_PORT_QA) -j DROP
	# Open access from anywhere
	# sudo iptables -A DOCKER -d $(TRAEFIK_CONTAINER_IP)/32 ! -i eth0 -p tcp -m tcp --dport $(MONGO_PORT_QA) -j ACCEPT

	## MONGO PROD
	# clean existing rules
	sudo iptables -D DOCKER -d $(OLD_TRAEFIK_CONTAINER_IP)/32 ! -i docker_gwbridge -o docker_gwbridge -p tcp -m tcp --dport $(MONGO_PORT_PROD) -j ACCEPT || true
	sudo iptables -D DOCKER -d $(OLD_TRAEFIK_CONTAINER_IP)/32 ! -i docker_gwbridge -s 83.166.154.157 -o docker_gwbridge -p tcp -m tcp --dport $(MONGO_PORT_PROD) -j ACCEPT || true
	sudo iptables -D DOCKER -d $(OLD_TRAEFIK_CONTAINER_IP)/32 ! -i docker_gwbridge -s 46.140.105.162 -o docker_gwbridge -p tcp -m tcp --dport $(MONGO_PORT_PROD) -j ACCEPT || true
	sudo iptables -D DOCKER -d $(OLD_TRAEFIK_CONTAINER_IP)/32 ! -i docker_gwbridge -s 127.0.0.1 -o docker_gwbridge -p tcp -m tcp --dport $(MONGO_PORT_PROD) -j ACCEPT || true
	sudo iptables -D DOCKER -i eth0 -p tcp -m tcp --dport $(MONGO_PORT_PROD) -j DROP || true
	# restrict acces
	sudo iptables -A DOCKER -d $(TRAEFIK_CONTAINER_IP)/32 ! -i docker_gwbridge -s 83.166.154.157 -o docker_gwbridge -p tcp -m tcp --dport $(MONGO_PORT_PROD) -j ACCEPT
	sudo iptables -A DOCKER -d $(TRAEFIK_CONTAINER_IP)/32 ! -i docker_gwbridge -s 46.140.105.162 -o docker_gwbridge -p tcp -m tcp --dport $(MONGO_PORT_PROD) -j ACCEPT
	sudo iptables -A DOCKER -d $(TRAEFIK_CONTAINER_IP)/32 ! -i docker_gwbridge -s 127.0.0.1 -o docker_gwbridge -p tcp -m tcp --dport $(MONGO_PORT_PROD) -j ACCEPT
	sudo iptables -A DOCKER -i eth0 -p tcp -m tcp --dport $(MONGO_PORT_PROD) -j DROP

	## MONGO EXTQA
	# clean existing rules
	sudo iptables -D DOCKER -d $(OLD_TRAEFIK_CONTAINER_IP)/32 ! -i docker_gwbridge -o docker_gwbridge -p tcp -m tcp --dport $(MONGO_PORT_EXTQA) -j ACCEPT || true
	sudo iptables -D DOCKER -d $(OLD_TRAEFIK_CONTAINER_IP)/32 ! -i docker_gwbridge -s 83.166.154.157 -o docker_gwbridge -p tcp -m tcp --dport $(MONGO_PORT_EXTQA) -j ACCEPT || true
	sudo iptables -D DOCKER -d $(OLD_TRAEFIK_CONTAINER_IP)/32 ! -i docker_gwbridge -s 46.140.105.162 -o docker_gwbridge -p tcp -m tcp --dport $(MONGO_PORT_EXTQA) -j ACCEPT || true
	sudo iptables -D DOCKER -d $(OLD_TRAEFIK_CONTAINER_IP)/32 ! -i docker_gwbridge -s 127.0.0.1 -o docker_gwbridge -p tcp -m tcp --dport $(MONGO_PORT_EXTQA) -j ACCEPT || true
	sudo iptables -D DOCKER -i eth0 -p tcp -m tcp --dport $(MONGO_PORT_EXTQA) -j DROP || true
	# restrict acces
	sudo iptables -A DOCKER -d $(TRAEFIK_CONTAINER_IP)/32 ! -i docker_gwbridge -s 83.166.154.157 -o docker_gwbridge -p tcp -m tcp --dport $(MONGO_PORT_EXTQA) -j ACCEPT
	sudo iptables -A DOCKER -d $(TRAEFIK_CONTAINER_IP)/32 ! -i docker_gwbridge -s 46.140.105.162 -o docker_gwbridge -p tcp -m tcp --dport $(MONGO_PORT_EXTQA) -j ACCEPT
	sudo iptables -A DOCKER -d $(TRAEFIK_CONTAINER_IP)/32 ! -i docker_gwbridge -s 127.0.0.1 -o docker_gwbridge -p tcp -m tcp --dport $(MONGO_PORT_EXTQA) -j ACCEPT
	sudo iptables -A DOCKER -i eth0 -p tcp -m tcp --dport $(MONGO_PORT_EXTQA) -j DROP

	# check result
	sudo iptables --list | grep -A 14 "Chain DOCKER ("


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
