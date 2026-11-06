NAME = inception
DATA_DIR = /home/pmendez-/data
COMPOSE_FILE = srcs/docker-compose.yml

RED="\033[0;31m"
GREEN="\033[0;32m"
MAGENTA="\033[0;35m"
PINK="\033[0;95m"
CYAN="\033[0;36m"
YELLOW="\033[0;33m"
NC="\033[0m"

all: build
	@echo -e $(GREEN)"Starting containers... "$(NC)
	@docker compose -f $(COMPOSE_FILE) up -d
	@docker compose -f $(COMPOSE_FILE) start

build: create_dirs
	@echo -e $(CYAN)"Building Docker images... "$(NC)
	@docker compose -f $(COMPOSE_FILE) build

up-%: create_dirs
	@echo -e $(CYAN)"Starting $* container..."$(NC)
	@docker compose -f $(COMPOSE_FILE) up $* -d

create_dirs:
	@if [ ! -d $(DATA_DIR)/wordpress ] || [ ! -d $(DATA_DIR)/mariadb ]; then \
		echo -e $(YELLOW)"Data folder missing, removing old containers..."$(NC); \
		docker compose -f $(COMPOSE_FILE) down; \
	fi
	@echo -e $(GREEN)"Creating volumes..."$(NC)
	@sudo mkdir -p $(DATA_DIR)/wordpress $(DATA_DIR)/mariadb
	@echo -e $(GREEN)"Volumes created."$(NC)

restart: create_dirs
	@echo -e $(YELLOW)"Restarting containers..."$(NC)
	@docker compose -f srcs/docker-compose.yml restart
	@echo -e $(YELLOW)"Showing logs..."$(NC)
	@docker compose -f srcs/docker-compose.yml logs

down:
	@echo -e $(RED)"Stopping and removing containers..."$(NC)
	@docker compose -f $(COMPOSE_FILE) down

clean: down
	@echo -e $(RED)"Cleaning up Docker resources..."$(NC)
	@docker system prune -a --volumes -f
	@sudo rm -rf $(DATA_DIR)

re: clean all

.PHONY: all build down clean re create_dirs restart