NAME = inception
DATA_DIR = /home/pmendez-/data
COMPOSE_FILE = srcs/docker-compose.yml
DOMAIN = pmendez.42.fr
ENV_FILE = srcs/.env
SECRETS_DIR = secrets
SECRETS = db_password db_root_password wp_admin_password wp_user_password
ENV_VARS = DOMAIN_NAME DB_NAME DB_USER WP_TITLE WP_ADMIN_USER WP_ADMIN_EMAIL WP_USER WP_USER_EMAIL

RED="\033[0;31m"
GREEN="\033[0;32m"
MAGENTA="\033[0;35m"
PINK="\033[0;95m"
CYAN="\033[0;36m"
YELLOW="\033[0;33m"
NC="\033[0m"

all: build
	@printf $(GREEN)"Starting containers... "$(NC)"\n"
	@docker compose -f $(COMPOSE_FILE) up -d
	@$(MAKE) --no-print-directory wait

wait:
	@printf $(CYAN)"Waiting for WordPress to be ready..."$(NC)"\n"
	@i=0; \
	while ! docker logs wordpress 2>&1 | grep -q "Arrancando PHP-FPM"; do \
		if [ "$$(docker inspect -f '{{.RestartCount}}' wordpress)" -gt 0 ] || [ $$i -ge 300 ]; then \
			printf $(RED)"WordPress failed to start. Last logs:"$(NC)"\n"; \
			docker logs --tail 20 wordpress; \
			docker logs --tail 20 mariadb; \
			exit 1; \
		fi; \
		printf "."; sleep 2; i=$$((i + 2)); \
	done; \
	echo ""
	@printf $(GREEN)"Ready: https://$(DOMAIN)"$(NC)"\n"

# Comprueba que .env tiene todas las variables y que ningún secret está vacío
# (se crean a mano, ver GUIDE.md paso 3)
check_config:
	@if [ ! -f $(ENV_FILE) ]; then \
		printf $(RED)"Configuration error: $(ENV_FILE) not found"$(NC)"\n"; printf "Create the configuration first (see GUIDE.md, step 3), then run make again.\n"; exit 1; \
	fi
	@for v in $(ENV_VARS); do \
		if ! grep -q "^$$v=." $(ENV_FILE); then \
			printf $(RED)"Configuration error: $$v is missing or empty in $(ENV_FILE)"$(NC)"\n"; printf "Create the configuration first (see GUIDE.md, step 3), then run make again.\n"; exit 1; \
		fi; \
	done
	@if grep -i -q '^WP_ADMIN_USER=.*admin' $(ENV_FILE); then \
		printf $(RED)"Configuration error: WP_ADMIN_USER must not contain 'admin'"$(NC)"\n"; printf "Create the configuration first (see GUIDE.md, step 3), then run make again.\n"; exit 1; \
	fi
	@for s in $(SECRETS); do \
		if [ ! -s $(SECRETS_DIR)/$$s.txt ]; then \
			printf $(RED)"Configuration error: $(SECRETS_DIR)/$$s.txt is missing or empty"$(NC)"\n"; printf "Create the configuration first (see GUIDE.md, step 3), then run make again.\n"; exit 1; \
		fi; \
	done
	@printf $(GREEN)"Configuration OK."$(NC)"\n"

build: check_config create_dirs
	@printf $(CYAN)"Building Docker images... "$(NC)"\n"
	@docker compose -f $(COMPOSE_FILE) build

up-%: check_config create_dirs
	@printf $(CYAN)"Starting $* container..."$(NC)"\n"
	@docker compose -f $(COMPOSE_FILE) up $* -d

create_dirs:
	@if [ ! -d $(DATA_DIR)/wordpress ] || [ ! -d $(DATA_DIR)/mariadb ]; then \
		printf $(YELLOW)"Data folder missing, removing old containers..."$(NC)"\n"; \
		docker compose -f $(COMPOSE_FILE) down; \
	fi
	@printf $(GREEN)"Creating volumes..."$(NC)"\n"
	@sudo mkdir -p $(DATA_DIR)/wordpress $(DATA_DIR)/mariadb
	@printf $(GREEN)"Volumes created."$(NC)"\n"

restart: create_dirs
	@printf $(YELLOW)"Restarting containers..."$(NC)"\n"
	@docker compose -f srcs/docker-compose.yml restart
	@printf $(YELLOW)"Showing logs..."$(NC)"\n"
	@docker compose -f srcs/docker-compose.yml logs

down:
	@printf $(RED)"Stopping and removing containers..."$(NC)"\n"
	@docker compose -f $(COMPOSE_FILE) down

clean: down
	@printf $(RED)"Cleaning up Docker resources..."$(NC)"\n"
	@docker system prune -a --volumes -f
	@sudo rm -rf $(DATA_DIR)

re: clean all

.PHONY: all build down clean re create_dirs restart wait check_config