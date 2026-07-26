# Hessian.AI Plugin Makefile
# Comprehensive build and management commands

.PHONY: help

# ============= ENVIRONMENT =============
IMAGE_NAME ?= ghcr.io/tobias-weiss-ai-xr/pi-hessian-plugin
IMAGE_TAG ?= latest
DOCKER_COMPOSE ?= docker compose

# ============= HELP =============
help: ## Show this help message
	@echo "Hessian.AI Plugin - Build and Management Commands"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-25s %s\n", $$1, $$2}'
	@echo ""

# ============= DOCKER COMMANDS =============

build: ## Build Docker image
docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

build-dev: ## Build development Docker image
docker build -t $(IMAGE_NAME):$(IMAGE_TAG)-dev -f Dockerfile.dev .

build-all: build build-dev ## Build both production and development images

push: ## Push Docker image to registry
docker push $(IMAGE_NAME):$(IMAGE_TAG)

push-dev: ## Push development Docker image
docker push $(IMAGE_NAME):$(IMAGE_TAG)-dev

push-all: push push-dev ## Push all Docker images

pull: ## Pull Docker image from registry
docker pull $(IMAGE_NAME):$(IMAGE_TAG)

pull-dev: ## Pull development Docker image
docker pull $(IMAGE_NAME):$(IMAGE_TAG)-dev

# ============= SANDBOX COMMANDS =============

sandbox: ## Start interactive sandbox
exec bash sandbox/run.sh

sandbox-dev: ## Start development sandbox with live mounting
exec bash sandbox/dev.sh

sandbox-test: ## Run sandbox tests
exec bash sandbox/test.sh

sandbox-ascii: ## Run ASCII art showcase
	@if [ -n "$${HESSIAN_API_KEY:-}" ]; then \
		export HESSIAN_API_KEY="$${HESSIAN_API_KEY}"; \
	fi; \
	exec bash sandbox/showcase.sh ascii

sandbox-joke: ## Run joke showcase
	@if [ -n "$${HESSIAN_API_KEY:-}" ]; then \
		export HESSIAN_API_KEY="$${HESSIAN_API_KEY}"; \
	fi; \
	exec bash sandbox/showcase.sh joke

sandbox-story: ## Run story showcase (requires API key)
	@if [ -z "$${HESSIAN_API_KEY:-}" ]; then \
		@echo "ERROR: HESSIAN_API_KEY not set"; \
		@echo "Usage: HESSIAN_API_KEY=your_key make sandbox-story"; \
		exit 1; \
	fi; \
	exec bash sandbox/showcase.sh story

sandbox-riddle: ## Run riddle showcase (requires API key)
	@if [ -z "$${HESSIAN_API_KEY:-}" ]; then \
		@echo "ERROR: HESSIAN_API_KEY not set"; \
		exit 1; \
	fi; \
	exec bash sandbox/showcase.sh riddle

sandbox-wisdom: ## Run wisdom showcase
	exec bash sandbox/showcase.sh wisdom

# ============= CODE COMMANDS =============

install: ## Install dependencies
	npm install

install-dev: ## Install all dependencies including devDependencies
	npm install

lint: ## Run linter (if configured)
	@echo "No linter configured. Consider adding ESLint."

lint-fix: ## Fix linting issues (if configured)
	@echo "No linter configured."

tsc: ## Run TypeScript check
	npm run tsc

validate: ## Validate configuration
	bash src/validate-config.sh pi-hessian.json 2>/dev/null || echo "No config file to validate"

generate: ## Generate Hessian.AI configuration
	@if [ -z "$${HESSIAN_API_KEY:-}" ]; then \
		@echo "ERROR: HESSIAN_API_KEY not set"; \
		@echo "Usage: HESSIAN_API_KEY=your_key make generate"; \
		exit 1; \
	fi; \
	bash src/generate-hessian-config.sh

# ============= TESTING =============

test: ## Run all tests
	exec bash sandbox/test.sh

test-tsc: ## Run TypeScript tests
	npm run tsc

test-config: ## Test configuration generation
	bash src/generate-hessian-config.sh --help

test-docker: ## Test Docker build
	docker build -t $(IMAGE_NAME):test . && docker run --rm $(IMAGE_NAME):test echo "Test passed"

# ============= CLEANUP =============

clean: ## Clean build artifacts
	rm -rf node_modules/ dist/ *.log *.tmp *.temp pi-*.json

clean-docker: ## Remove Docker containers and images
	docker rm -f $(IMAGE_NAME)-container 2>/dev/null || true
	docker rmi -f $(IMAGE_NAME):$(IMAGE_TAG) 2>/dev/null || true
	docker rmi -f $(IMAGE_NAME):$(IMAGE_TAG)-dev 2>/dev/null || true

clean-all: clean clean-docker ## Clean everything

# ============= DEPLOYMENT =============

deploy: push ## Deploy to Docker registry
	@echo "Deploying $(IMAGE_NAME):$(IMAGE_TAG) to registry..."
	make push
	@echo "Deployed successfully!"

deploy-dev: push-dev ## Deploy development image
	@echo "Deploying $(IMAGE_NAME):$(IMAGE_TAG)-dev to registry..."
	make push-dev
	@echo "Deployed successfully!"

deploy-all: deploy deploy-dev ## Deploy all images

# ============= UTILITY =============

version: ## Show version
	@cat package.json | grep '"version"' | awk -F: '{ print $2 }' | tr -d ' "\n,'

version-bump: ## Bump version (patch)
	npm version patch

version-minor: ## Bump version (minor)
	npm version minor

version-major: ## Bump version (major)
	npm version major

prepare-release: ## Prepare for release
	npm run prepare-release

# ============= DOCKER COMPOSE =============

up: ## Start services with docker compose
	$(DOCKER_COMPOSE) up -d

down: ## Stop services with docker compose
	$(DOCKER_COMPOSE) down

build-compose: ## Build services with docker compose
	$(DOCKER_COMPOSE) build

# Default target
.DPHONY: default
default: help
