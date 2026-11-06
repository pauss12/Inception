NAME = inception
DATA_DIR = /home/pmendez-/data
COMPOSE_FILE = srcs/docker-compose.yml
DOMAIN = pmendez.42.fr
ENV_FILE = srcs/.env
SECRETS_DIR = secrets
SECRETS = db_password db_root_password wp_admin_password wp_user_password
# Hora de inicio de make (para mostrar cuánto tarda) y espera máxima de WordPress
START := $(shell date +%s)
WAIT_MAX = 300
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
	@$(MAKE) --no-print-directory wait START=$(START)

wait:
	@printf $(CYAN)"Waiting for WordPress to be ready..."$(NC)"\n"
	@begin=$$(date +%s); \
	while ! docker logs wordpress 2>&1 | grep -q "Arrancando PHP-FPM"; do \
		now=$$(date +%s); waited=$$((now - begin)); total=$$((now - $(START))); \
		if [ "$$(docker inspect -f '{{.RestartCount}}' wordpress)" -gt 0 ] || [ $$waited -ge $(WAIT_MAX) ]; then \
			printf "\n"$(RED)"WordPress failed to start after %dm%02ds. Last logs:"$(NC)"\n" $$((total / 60)) $$((total % 60)); \
			docker logs --tail 20 wordpress; \
			docker logs --tail 20 mariadb; \
			exit 1; \
		fi; \
		logs=$$(docker logs wordpress 2>&1); \
		if echo "$$logs" | grep -q "WordPress installed successfully"; then step="Creating users"; \
		elif echo "$$logs" | grep -q "wp-config.php"; then step="Installing WordPress"; \
		elif echo "$$logs" | grep -q "WordPress downloaded"; then step="Creating wp-config.php"; \
		elif echo "$$logs" | grep -q "MariaDB lista"; then step="Downloading WordPress"; \
		else step="Waiting for MariaDB"; fi; \
		left=$$(($(WAIT_MAX) - waited)); \
		printf "\r  [%02d:%02d] %-24s (timeout in %d:%02d)  " $$((total / 60)) $$((total % 60)) "$$step" $$((left / 60)) $$((left % 60)); \
		sleep 1; \
	done; \
	total=$$(($$(date +%s) - $(START))); \
	printf "\r%60s\r" ""; \
	printf $(GREEN)"Ready in %dm%02ds: https://$(DOMAIN)"$(NC)"\n" $$((total / 60)) $$((total % 60))

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