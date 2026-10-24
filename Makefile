NAME = inception
COMPOSE_FILE = srcs/docker-compose.yml

RED="\033[0;31m"
GREEN="\033[0;32m"
MAGENTA="\033[0;35m"
PINK="\033[0;95m"
CYAN="\033[0;36m"
YELLOW="\033[0;33m"
NC="\033[0m"

all: build
	@echo $(GREEN)"Starting containers... 🚀"$(NC)
	@docker compose -f $(COMPOSE_FILE) up -d
	@docker compose -f $(COMPOSE_FILE) start

build: create_dirs
	@echo $(CYAN)"Building Docker images... 🏗️"$(NC)
	@docker compose -f $(COMPOSE_FILE) build

up-%:
	@echo $(CYAN)"Starting $* container... 🚀"$(NC)
	@docker compose -f $(COMPOSE_FILE) up $* -d

create_dirs:
	@echo $(GREEN)"Creating volumes... 🗃️"$(NC)
	@mkdir -p /home/$(USER)/data/wordpress
	@mkdir -p /home/$(USER)/data/mariadb

# restart:
# 	docker compose -f srcs/docker-compose.yml restart

# logs:
# 	docker compose -f srcs/docker-compose.yml logs

down:
	@echo $(RED)"Stopping and removing containers... 🛑"$(NC)
	@docker compose -f $(COMPOSE_FILE) down

clean: down
	@echo $(RED)"Cleaning up Docker resources... 🧹"$(NC)
	@docker system prune -a --volumes -f
	@rm -rf /home/$(USER)/data

re: clean all

.PHONY: all build down clean re create_dirs