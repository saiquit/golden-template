# Variables
COMPOSE = docker compose
BACKEND_SVC = backend
FRONTEND_SVC = frontend

.PHONY: help up down restart build logs shell-backend shell-frontend migrate superuser clean

help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

## --- DOCKER OPERATIONS ---

up: ## Start all containers in background
	$(COMPOSE) up -d

down: ## Stop all containers
	$(COMPOSE) down

restart: ## Restart all containers
	$(COMPOSE) restart

build: ## Rebuild all containers
	$(COMPOSE) build

ps: ## View running containers
	$(COMPOSE) ps

logs: ## View logs from all containers (follow)
	$(COMPOSE) logs -f

## --- BACKEND (DJANGO) ---

migrate: ## Run Django database migrations
	$(COMPOSE) exec $(BACKEND_SVC) python manage.py migrate

makemigrations: ## Create new Django migrations
	$(COMPOSE) exec $(BACKEND_SVC) python manage.py makemigrations

superuser: ## Create a Django superuser
	$(COMPOSE) exec $(BACKEND_SVC) python manage.py createsuperuser

shell-backend: ## Enter the Django container's shell
	$(COMPOSE) exec $(BACKEND_SVC) /bin/bash

test-backend: ## Run Django tests
	$(COMPOSE) exec $(BACKEND_SVC) python manage.py test

collectstatic: ## Collect Django static files
	$(COMPOSE) exec $(BACKEND_SVC) python manage.py collectstatic --noinput

## --- FRONTEND (NEXT.JS) ---

shell-frontend: ## Enter the Next.js container's shell
	$(COMPOSE) exec $(FRONTEND_SVC) sh

install-frontend: ## Install new npm packages (example: make install-frontend pkg=axios)
	$(COMPOSE) exec $(FRONTEND_SVC) npm install $(pkg)

## --- CLEANUP ---

clean: ## Remove containers, volumes, and cached files
	$(COMPOSE) down -v
	sudo find . -name "__pycache__" -type d -exec rm -rf {} +
	sudo rm -rf frontend/.next
	@echo "✨ Project cleaned"

## --- BACKEND (DJANGO) ---

migrate: ## Run Django database migrations
	$(COMPOSE) exec $(BACKEND_SVC) python manage.py migrate

makemigrations: ## Create new Django migrations
	$(COMPOSE) exec $(BACKEND_SVC) python manage.py makemigrations

superuser: ## Create a Django superuser
	$(COMPOSE) exec $(BACKEND_SVC) python manage.py createsuperuser

# Usage: make startapp name=products
startapp: ## Create a new Django app (usage: make startapp name=app_name)
	$(COMPOSE) exec $(BACKEND_SVC) python manage.py startapp $(name)
	@echo "App '$(name)' created. Don't forget to add it to INSTALLED_APPS in settings.py!"

shell: ## Open Django Python shell (iPython if installed)
	$(COMPOSE) exec $(BACKEND_SVC) python manage.py shell

dbshell: ## Open direct database shell (Postgres)
	$(COMPOSE) exec $(BACKEND_SVC) python manage.py dbshell

showmigrations: ## List all migrations and their status
	$(COMPOSE) exec $(BACKEND_SVC) python manage.py showmigrations

urls: ## Show all registered URLs (requires django-extensions)
	$(COMPOSE) exec $(BACKEND_SVC) python manage.py show_urls

collectstatic: ## Collect static files to STATIC_ROOT
	$(COMPOSE) exec $(BACKEND_SVC) python manage.py collectstatic --noinput

test: ## Run all Django tests
	$(COMPOSE) exec $(BACKEND_SVC) python manage.py test

# Usage: make pip-install pkg=django-rest-framework
pip-install: ## Install a python package (usage: make pip-install pkg=package_name)
	$(COMPOSE) exec $(BACKEND_SVC) pip install $(pkg)
	$(COMPOSE) exec $(BACKEND_SVC) pip freeze > requirements.txt
	@echo "$(pkg) installed and added to requirements.txt"

## --- DB OPERATIONS ---

db-status: ## Check if the Postgres database is ready
	$(COMPOSE) exec db pg_isready -U postgres