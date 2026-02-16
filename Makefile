.PHONY: help build up down restart logs ps prune \
        backend-shell backend-migrations backend-migrate backend-makemigrations \
        backend-createsuperuser backend-collectstatic backend-test \
        frontend-shell frontend-build frontend-lint \
        db-shell db-backup db-restore \
        logs-backend logs-frontend logs-nginx logs-db

# Colors for help
GREEN := \033[0;32m
YELLOW := \033[0;33m
CYAN := \033[0;36m
RED := \033[0;31m
RESET := \033[0m

help: ## Show this help message
	@echo "$(CYAN)Available commands:$(RESET)"
	@echo "$(YELLOW)┌────────────────────────────────────────────┐"
	@echo "│  Django + Next.js Docker Commands          │"
	@echo "└────────────────────────────────────────────┘$(RESET)"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-30s$(RESET) %s\n", $$1, $$2}'

# ────────────────────────────────────────────────────────────
# 🐳 DOCKER COMPOSE V2 COMMANDS
# ────────────────────────────────────────────────────────────

build: ## Build all Docker images
	docker compose build

build-no-cache: ## Build all Docker images without cache
	docker compose build --no-cache

up: ## Start all services in detached mode
	docker compose up -d

up-verbose: ## Start all services with logs visible
	docker compose up

down: ## Stop and remove all containers
	docker compose down

down-volumes: ## Stop and remove all containers including volumes
	docker compose down -v

down-remove-orphans: ## Stop and remove all containers including orphans
	docker compose down --remove-orphans

restart: down up ## Restart all services

ps: ## Show running containers
	docker compose ps

ps-all: ## Show all containers (including stopped)
	docker compose ps -a

logs: ## Show logs from all services
	docker compose logs -f

logs-tail: ## Show last 100 lines of logs
	docker compose logs --tail=100 -f

prune: ## Remove all unused containers, networks, and images
	docker system prune -f

# ────────────────────────────────────────────────────────────
# 🐍 BACKEND (DJANGO) COMMANDS
# ────────────────────────────────────────────────────────────

backend-shell: ## Open Django Python shell
	docker compose exec backend python manage.py shell

backend-shell-plus: ## Open Django shell_plus (if django-extensions installed)
	docker compose exec backend python manage.py shell_plus

backend-bash: ## Open bash shell in backend container
	docker compose exec backend bash

backend-migrations: ## Show pending migrations
	docker compose exec backend python manage.py showmigrations

backend-makemigrations: ## Create new migrations
	docker compose exec backend python manage.py makemigrations

backend-makemigrations-app: ## Create migrations for specific app (usage: make backend-makemigrations-app app=myapp)
	docker compose exec backend python manage.py makemigrations $(app)

backend-migrate: ## Apply all migrations
	docker compose exec backend python manage.py migrate

backend-migrate-app: ## Apply migrations for specific app (usage: make backend-migrate-app app=myapp)
	docker compose exec backend python manage.py migrate $(app)

backend-migrate-fake: ## Fake apply migrations
	docker compose exec backend python manage.py migrate --fake

backend-createsuperuser: ## Create a Django superuser
	docker compose exec backend python manage.py createsuperuser

backend-collectstatic: ## Collect static files
	docker compose exec backend python manage.py collectstatic --noinput

backend-test: ## Run all Django tests
	docker compose exec backend python manage.py test

backend-test-app: ## Run tests for specific app (usage: make backend-test-app app=myapp)
	docker compose exec backend python manage.py test $(app)

backend-test-keep: ## Run tests and keep test database
	docker compose exec backend python manage.py test --keepdb

backend-test-coverage: ## Run tests with coverage report
	docker compose exec backend sh -c "coverage run manage.py test && coverage report"

backend-django-check: ## Run Django system checks
	docker compose exec backend python manage.py check

backend-show-urls: ## Show all URL patterns
	docker compose exec backend python manage.py show_urls

backend-reset-db: ## Reset database (WARNING: drops all data!)
	@echo "$(RED)This will drop all data! Are you sure? [y/N]$(RESET)" && read ans && [ $${ans:-N} = y ]
	docker compose exec backend python manage.py reset_db
	docker compose exec backend python manage.py migrate

backend-load-fixtures: ## Load fixtures (usage: make backend-load-fixtures fixture=myfixture.json)
	docker compose exec backend python manage.py loaddata $(fixture)

backend-dump-data: ## Dump data to fixture (usage: make backend-dump-data app=myapp > myapp.json)
	docker compose exec backend python manage.py dumpdata $(app)

backend-requirements: ## Freeze and update requirements.txt
	docker compose exec backend pip freeze > backend/requirements.txt

backend-install-package: ## Install a Python package (usage: make backend-install-package package=requests)
	docker compose exec backend pip install $(package)
	@echo "$(GREEN)Don't forget to update requirements.txt with: make backend-requirements$(RESET)"

backend-startapp: ## Create new Django app (usage: make backend-startapp app=myapp)
	docker compose exec backend python manage.py startapp $(app)

# ────────────────────────────────────────────────────────────
# ⚛️ FRONTEND (NEXT.JS) COMMANDS
# ────────────────────────────────────────────────────────────

frontend-shell: ## Open bash shell in frontend container
	docker compose exec frontend sh

frontend-build: ## Build Next.js app for production
	docker compose exec frontend npm run build

frontend-lint: ## Run ESLint
	docker compose exec frontend npm run lint

frontend-lint-fix: ## Run ESLint with auto-fix
	docker compose exec frontend npm run lint -- --fix

frontend-test: ## Run frontend tests (if configured)
	docker compose exec frontend npm test

frontend-add-package: ## Add an npm package (usage: make frontend-add-package package=axios)
	docker compose exec frontend npm install $(package)

frontend-add-dev-package: ## Add a dev npm package (usage: make frontend-add-dev-package package=@types/node)
	docker compose exec frontend npm install -D $(package)

frontend-remove-package: ## Remove an npm package (usage: make frontend-remove-package package=axios)
	docker compose exec frontend npm uninstall $(package)

frontend-update-packages: ## Update all npm packages
	docker compose exec frontend npm update

frontend-type-check: ## Run TypeScript type checking
	docker compose exec frontend npx tsc --noEmit

frontend-clean: ## Clean Next.js cache
	docker compose exec frontend rm -rf .next
	docker compose exec frontend rm -rf node_modules/.cache

frontend-dev: ## Start Next.js in development mode (if not already running)
	docker compose exec frontend npm run dev

# ────────────────────────────────────────────────────────────
# 🗄️ DATABASE COMMANDS
# ────────────────────────────────────────────────────────────

db-shell: ## Open PostgreSQL shell
	docker compose exec db psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}

db-list-dbs: ## List all databases
	docker compose exec db psql -U ${POSTGRES_USER} -c "\l"

db-list-tables: ## List all tables in current database
	docker compose exec db psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "\dt"

db-desc-table: ## Describe table (usage: make db-desc-table table=auth_user)
	docker compose exec db psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "\d $(table)"

db-backup: ## Backup database to file
	@mkdir -p backups
	docker compose exec db pg_dump -U ${POSTGRES_USER} ${POSTGRES_DB} > backups/backup_$$(date +%Y%m%d_%H%M%S).sql
	@echo "$(GREEN)Database backed up to backups/backup_$$(date +%Y%m%d_%H%M%S).sql$(RESET)"

db-backup-compressed: ## Backup database with compression
	@mkdir -p backups
	docker compose exec db pg_dump -U ${POSTGRES_USER} ${POSTGRES_DB} | gzip > backups/backup_$$(date +%Y%m%d_%H%M%S).sql.gz
	@echo "$(GREEN)Database backed up to backups/backup_$$(date +%Y%m%d_%H%M%S).sql.gz$(RESET)"

db-restore: ## Restore database from backup (usage: make db-restore file=backups/backup_20240101_120000.sql)
	@if [ -f $(file) ]; then \
		echo "$(YELLOW)Restoring database from $(file)...$(RESET)"; \
		cat $(file) | docker compose exec -T db psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}; \
		echo "$(GREEN)Database restored successfully!$(RESET)"; \
	else \
		echo "$(RED)File $(file) not found!$(RESET)"; \
		exit 1; \
	fi

db-restore-compressed: ## Restore from compressed backup (usage: make db-restore-compressed file=backup.sql.gz)
	@if [ -f $(file) ]; then \
		echo "$(YELLOW)Restoring database from $(file)...$(RESET)"; \
		gunzip -c $(file) | docker compose exec -T db psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}; \
		echo "$(GREEN)Database restored successfully!$(RESET)"; \
	else \
		echo "$(RED)File $(file) not found!$(RESET)"; \
		exit 1; \
	fi

db-reset: ## Reset database (drop and recreate) - WARNING: deletes all data!
	@echo "$(RED)This will delete all data! Are you sure? [y/N]$(RESET)" && read ans && [ $${ans:-N} = y ]
	docker compose exec db psql -U ${POSTGRES_USER} -c "DROP DATABASE IF EXISTS ${POSTGRES_DB};"
	docker compose exec db psql -U ${POSTGRES_USER} -c "CREATE DATABASE ${POSTGRES_DB};"
	@echo "$(GREEN)Database reset. Run migrations with: make backend-migrate$(RESET)"

# ────────────────────────────────────────────────────────────
# 📋 LOGS COMMANDS
# ────────────────────────────────────────────────────────────

logs-backend: ## Show backend logs only
	docker compose logs -f backend

logs-frontend: ## Show frontend logs only
	docker compose logs -f frontend

logs-nginx: ## Show nginx logs only
	docker compose logs -f nginx

logs-db: ## Show database logs only
	docker compose logs -f db

# ────────────────────────────────────────────────────────────
# 🚀 DEVELOPMENT WORKFLOW COMMANDS
# ────────────────────────────────────────────────────────────

dev: ## Start development environment
	@echo "$(CYAN)Starting development environment...$(RESET)"
	docker compose up -d
	@echo "$(GREEN)✓ Development environment started$(RESET)"
	@echo "$(YELLOW)  • Frontend: http://localhost$(RESET)"
	@echo "$(YELLOW)  • Backend API: http://localhost/api/$(RESET)"
	@echo "$(YELLOW)  • Django Admin: http://localhost/admin/$(RESET)"
	@echo "$(YELLOW)  • PostgreSQL: localhost:5432$(RESET)"
	@echo "$(YELLOW)  • View logs: make logs$(RESET)"

dev-clean: down prune dev ## Clean rebuild and start development environment

init: ## Initialize project (first time setup)
	@echo "$(CYAN)Initializing project...$(RESET)"
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "$(GREEN)✓ Created .env file from .env.example$(RESET)"; \
	else \
		echo "$(YELLOW}✓ .env file already exists$(RESET)"; \
	fi
	docker compose build
	docker compose up -d
	@echo "$(YELLOW)Waiting for database to be ready...$(RESET)"
	@sleep 5
	docker compose exec backend python manage.py migrate
	@echo "$(GREEN)✓ Project initialized successfully!$(RESET)"
	@echo "$(YELLOW)Run 'make backend-createsuperuser' to create an admin user$(RESET)"

reset: ## Reset everything (WARNING: deletes all data!)
	@echo "$(RED)This will delete all data! Are you sure? [y/N]$(RESET)" && read ans && [ $${ans:-N} = y ]
	docker compose down -v
	docker compose up -d
	docker compose exec backend python manage.py migrate

# ────────────────────────────────────────────────────────────
# 🧹 UTILITY COMMANDS
# ────────────────────────────────────────────────────────────

status: ## Show status of all services
	@echo "$(CYAN)Docker Containers:$(RESET)"
	docker compose ps
	@echo ""
	@echo "$(CYAN)Resource Usage:$(RESET)"
	docker stats --no-stream

stats: ## Show live resource usage
	docker stats

images: ## List all Docker images
	docker compose images

top: ## Show running processes in containers
	docker compose top

clean: ## Clean up everything (containers, volumes, images)
	@echo "$(RED)This will remove all containers, volumes, and images! Are you sure? [y/N]$(RESET)" && read ans && [ $${ans:-N} = y ]
	docker compose down -v --rmi all --remove-orphans

# ────────────────────────────────────────────────────────────
# ⚡ SHORTCUTS
# ────────────────────────────────────────────────────────────

migrations: backend-makemigrations ## Shortcut for makemigrations
migrate: backend-migrate ## Shortcut for migrate
shell: backend-shell ## Shortcut for Django shell
superuser: backend-createsuperuser ## Shortcut for createsuperuser
test: backend-test ## Shortcut for running tests
dc: ## Run any docker compose command (usage: make dc "ps -a")
	docker compose $(cmd)

# ────────────────────────────────────────────────────────────
# 📦 PRODUCTION COMMANDS (if you have docker-compose.prod.yml)
# ────────────────────────────────────────────────────────────

prod-build: ## Build for production
	docker compose -f docker-compose.prod.yml build

prod-up: ## Start production services
	docker compose -f docker-compose.prod.yml up -d

prod-down: ## Stop production services
	docker compose -f docker-compose.prod.yml down

prod-logs: ## View production logs
	docker compose -f docker-compose.prod.yml logs -f