.PHONY: help build up down logs clean restart status test

help: ## Show this help message
	@echo "AEOS Container Management"
	@echo "========================="
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

build: ## Build all container images
	docker-compose build

build-podman: ## Build with Podman
	podman-compose build

up: ## Start all containers
	docker-compose up -d

up-podman: ## Start with Podman
	./deploy-podman.sh

down: ## Stop all containers
	docker-compose down

down-podman: ## Stop Podman containers
	podman stop aeos-server aeos-lookup aeos-database || true
	podman rm aeos-server aeos-lookup aeos-database || true

logs: ## View container logs
	docker-compose logs -f

logs-podman: ## View Podman logs
	podman logs -f aeos-server

status: ## Check container status
	docker-compose ps

status-podman: ## Check Podman status
	podman ps -a --filter "name=aeos-"

restart: ## Restart all containers
	docker-compose restart

clean: ## Remove containers and volumes (WARNING: deletes data)
	docker-compose down -v
	docker system prune -f

clean-podman: ## Clean Podman containers and volumes
	podman stop aeos-server aeos-lookup aeos-database || true
	podman rm aeos-server aeos-lookup aeos-database || true
	podman volume rm aeos-db-data aeos-data aeos-logs || true
	podman network rm aeos-network || true

test: ## Run basic tests
	@echo "Testing AEOS deployment..."
	@echo "Checking if containers are running..."
	@docker-compose ps | grep -q "Up" && echo "✓ Containers are running" || echo "✗ Containers are not running"
	@echo "Checking database connection..."
	@docker exec aeos-database pg_isready -U aeos && echo "✓ Database is ready" || echo "✗ Database not ready"
	@echo "Checking web interface..."
	@curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200\|302" && echo "✓ Web interface responding" || echo "✗ Web interface not responding"

backup-db: ## Backup the database
	@mkdir -p backups
	docker exec aeos-database pg_dump -U aeos aeos > backups/aeos-backup-$$(date +%Y%m%d-%H%M%S).sql
	@echo "Database backed up to backups/"

restore-db: ## Restore database from backup (requires BACKUP_FILE variable)
	@if [ -z "$(BACKUP_FILE)" ]; then echo "Usage: make restore-db BACKUP_FILE=path/to/backup.sql"; exit 1; fi
	cat $(BACKUP_FILE) | docker exec -i aeos-database psql -U aeos aeos
	@echo "Database restored from $(BACKUP_FILE)"

shell-server: ## Open shell in application server
	docker exec -it aeos-server /bin/bash

shell-db: ## Open psql shell
	docker exec -it aeos-database psql -U aeos aeos

init-env: ## Initialize environment file
	@if [ ! -f .env ]; then cp .env.example .env && echo "Created .env file - please edit it!"; else echo ".env already exists"; fi
