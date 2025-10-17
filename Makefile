NAME 	= Inception

DOCKER = docker
RUN = $(DOCKER) run
COMPOSE = docker-compose

# ╔══════════════════════════════════════════════════════════════════════════╗ #  
#                               SOURCES                                        #
# ╚══════════════════════════════════════════════════════════════════════════╝ # 

MANDATORY_PATH = -f ./src/mandatory.yml
BONUS_PATH = -f ./src/bonus.yml # PARA BORRAR

# ╔══════════════════════════════════════════════════════════════════════════╗ #  
#                               COLORS                                         #
# ╚══════════════════════════════════════════════════════════════════════════╝ #  

RED=\033[0;31m
CYAN=\033[0;36m
GREEN=\033[0;32m
YELLOW=\033[0;33m
WHITE=\033[0;97m
BLUE=\033[0;34m
NC=\033[0m # No color

# ╔══════════════════════════════════════════════════════════════════════════╗ #  
#                               RULES                                          #
# ╚══════════════════════════════════════════════════════════════════════════╝ # 

up: setup
	@$(COMPOSE) $(MANDATORY_PATH) up --build -d

bonus: clean
	@$(COMPOSE) $(MANDATORY_PATH) $(BONUS_PATH) up --build -d

setup:
	@if [ ! -f ./src/.env ]; then \
		cp ~/.env ./src;	\
	fi
it: setup
	@$(DOCKER) exec -it $(ID) sh

clean: setup images
	@echo
	@$(COMPOSE) $(MANDATORY_PATH) down
	@$(COMPOSE) $(BONUS_PATH) down
	@printf "$(RED)Removing images above$(NC)\n"
	@$(DOCKER) container prune -f && $(DOCKER) image prune -a -f
	@printf "$(GREEN) $@ COMPLETE! $(NC)\n"

fclean: setup clean
	@echo
	@echo "Starting full clean"
	@$(DOCKER) system prune -a
	@echo
	@printf "$(GREEN)COMPLETE! $(NC)\n"

logs: setup
	@$(DOCKER) $@ -f $(ID)

ps: setup
	@$(DOCKER) $@ -a

images: setup
	@$(DOCKER) $@

re: fclean up

.PHONY: up bonus setup it clean down logs ps images re
