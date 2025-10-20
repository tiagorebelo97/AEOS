.PHONY: build run clean help

CONTAINER_NAME=aeos
IMAGE_TAG=latest

help: ## Show this help message
	@echo "AEOS Container Management"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

build: ## Build the container image
	@echo "Building container image..."
	podman build -t $(CONTAINER_NAME):$(IMAGE_TAG) -f Containerfile .
	@echo "Build complete! Image: $(CONTAINER_NAME):$(IMAGE_TAG)"

run: ## Run the container interactively
	@echo "Starting container..."
	podman run -it --rm --name $(CONTAINER_NAME) $(CONTAINER_NAME):$(IMAGE_TAG)

run-detached: ## Run the container in detached mode
	@echo "Starting container in background..."
	podman run -d --name $(CONTAINER_NAME) $(CONTAINER_NAME):$(IMAGE_TAG)

stop: ## Stop the running container
	@echo "Stopping container..."
	podman stop $(CONTAINER_NAME) || true

clean: ## Remove container and image
	@echo "Cleaning up..."
	podman stop $(CONTAINER_NAME) 2>/dev/null || true
	podman rm $(CONTAINER_NAME) 2>/dev/null || true
	podman rmi $(CONTAINER_NAME):$(IMAGE_TAG) 2>/dev/null || true
	@echo "Cleanup complete!"

logs: ## Show container logs
	podman logs $(CONTAINER_NAME)

shell: ## Open a shell in the running container
	podman exec -it $(CONTAINER_NAME) /bin/bash

ps: ## List running containers
	podman ps

images: ## List container images
	podman images | grep $(CONTAINER_NAME) || echo "No $(CONTAINER_NAME) images found"
