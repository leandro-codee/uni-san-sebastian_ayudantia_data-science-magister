# =============================================================================
# Makefile para Entorno Data Science
# =============================================================================

# Variables de configuración
DOCKER_REGISTRY = gcr.io/tu-proyecto-id
PROJECT_NAME = datascience-env
APP_VERSION ?= v1.0.0

# Nombres de imágenes
API_IMAGE = $(PROJECT_NAME)-api
JUPYTER_IMAGE = $(PROJECT_NAME)-jupyter

# Tags para GCP
API_TAG = $(DOCKER_REGISTRY)/$(API_IMAGE):$(APP_VERSION)
API_TAG_LATEST = $(DOCKER_REGISTRY)/$(API_IMAGE):latest

# Configuración de puertos
API_PORT = 4000
JUPYTER_PORT = 8888
POSTGRES_PORT = 5432
QDRANT_PORT = 6333
N8N_PORT = 5678

# Colores para output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
BLUE = \033[0;34m
NC = \033[0m # No Color

# =============================================================================
# COMANDOS PRINCIPALES
# =============================================================================

.PHONY: help
help: ## Mostrar esta ayuda
	@echo "$(GREEN)🔬 Data Science Environment - Comandos disponibles:$(NC)"
	@echo "$(BLUE)Versión actual: $(APP_VERSION)$(NC)"
	@echo ""
	@echo "$(YELLOW)📋 DESARROLLO LOCAL:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)🌐 URLs de acceso (cuando esté funcionando):$(NC)"
	@echo "  • Jupyter Lab:     http://localhost:$(JUPYTER_PORT) (token: datascience123)"
	@echo "  • API Flask:       http://localhost:$(API_PORT)"
	@echo "  • PostgreSQL:      localhost:$(POSTGRES_PORT) (postgres/postgres)"
	@echo "  • Qdrant:          http://localhost:$(QDRANT_PORT)/dashboard"
	@echo "  • n8n:             http://localhost:$(N8N_PORT) (admin/n8npassword123)"
	@echo "  • Adminer:         http://localhost:8081"

# =============================================================================
# DESARROLLO LOCAL
# =============================================================================

.PHONY: setup
setup: ## Configurar entorno inicial
	@echo "$(GREEN)🛠️  Configurando entorno inicial...$(NC)"
	@mkdir -p notebooks data scripts api init_db
	@touch api/app.py api/requirements.txt
	@if [ ! -f .env ]; then \
		echo "# Variables de entorno para desarrollo" > .env; \
		echo "POSTGRES_DB=datascience" >> .env; \
		echo "POSTGRES_USER=dsuser" >> .env; \
		echo "POSTGRES_PASSWORD=dspassword123" >> .env; \
		echo "$(GREEN)Archivo .env creado$(NC)"; \
	fi
	@echo "$(GREEN)✅ Setup completado$(NC)"

.PHONY: up
up: ## Levantar todos los servicios
	@echo "$(GREEN)🚀 Iniciando servicios...$(NC)"
	@docker-compose up -d
	@echo "$(GREEN)✅ Servicios iniciados$(NC)"
	@echo "$(YELLOW)Esperando que los servicios estén listos...$(NC)"
	@sleep 10
	@make status

.PHONY: down
down: ## Detener todos los servicios
	@echo "$(GREEN)🛑 Deteniendo servicios...$(NC)"
	@docker-compose down
	@echo "$(GREEN)✅ Servicios detenidos$(NC)"

.PHONY: restart
restart: down up ## Reiniciar todos los servicios

.PHONY: status
status: ## Verificar estado de servicios
	@echo "$(GREEN)📊 Estado de servicios:$(NC)"
	@docker-compose ps

.PHONY: logs
logs: ## Ver logs de todos los servicios
	@echo "$(GREEN)📝 Logs de servicios (Ctrl+C para salir):$(NC)"
	@docker-compose logs -f

.PHONY: logs-api
logs-api: ## Ver logs solo de la API
	@docker-compose logs -f python-api

.PHONY: logs-jupyter
logs-jupyter: ## Ver logs solo de Jupyter
	@docker-compose logs -f jupyter

.PHONY: logs-postgres
logs-postgres: ## Ver logs solo de PostgreSQL
	@docker-compose logs -f postgres

# =============================================================================
# CONSTRUCCIÓN DE IMÁGENES
# =============================================================================

.PHONY: build
build: ## Construir todas las imágenes
	@echo "$(GREEN)🔨 Construyendo imágenes...$(NC)"
	@docker-compose build
	@echo "$(GREEN)✅ Imágenes construidas$(NC)"

.PHONY: build-api
build-api: ## Construir solo imagen de API
	@echo "$(GREEN)🔨 Construyendo imagen de API...$(NC)"
	@docker-compose build python-api

.PHONY: build-jupyter
build-jupyter: ## Construir solo imagen de Jupyter
	@echo "$(GREEN)🔨 Construyendo imagen de Jupyter...$(NC)"
	@docker-compose build jupyter

# =============================================================================
# TESTING LOCAL
# =============================================================================

.PHONY: test
test: ## Probar conectividad de servicios
	@echo "$(GREEN)🧪 Probando conectividad...$(NC)"
	@echo "$(YELLOW)Testing PostgreSQL...$(NC)"
	@docker-compose exec -T postgres pg_isready -U postgres -d datascience && echo "$(GREEN)✅ PostgreSQL OK$(NC)" || echo "$(RED)❌ PostgreSQL FAIL$(NC)"
	@echo "$(YELLOW)Testing Qdrant...$(NC)"
	@curl -s http://localhost:$(QDRANT_PORT)/collections >/dev/null && echo "$(GREEN)✅ Qdrant OK$(NC)" || echo "$(RED)❌ Qdrant FAIL$(NC)"
	@echo "$(YELLOW)Testing API...$(NC)"
	@curl -s http://localhost:$(API_PORT)/health >/dev/null && echo "$(GREEN)✅ API OK$(NC)" || echo "$(RED)❌ API FAIL$(NC)"
	@echo "$(YELLOW)Testing Jupyter...$(NC)"
	@curl -s http://localhost:$(JUPYTER_PORT) >/dev/null && echo "$(GREEN)✅ Jupyter OK$(NC)" || echo "$(RED)❌ Jupyter FAIL$(NC)"

.PHONY: test-api
test-api: ## Probar API específicamente
	@echo "$(GREEN)🧪 Probando API...$(NC)"
	@curl -X GET http://localhost:$(API_PORT)/health || echo "$(RED)❌ API no responde$(NC)"

# =============================================================================
# GOOGLE CLOUD PLATFORM
# =============================================================================

.PHONY: setup-gcp
setup-gcp: ## Configurar variables para GCP
	@echo "$(GREEN)⚙️  Configurando GCP...$(NC)"
	@read -p "Ingresa tu PROJECT_ID de Google Cloud: " project_id; \
	sed -i "s/tu-proyecto-id/$$project_id/g" Makefile
	@echo "$(GREEN)✅ PROJECT_ID configurado$(NC)"

.PHONY: build-gcp
build-gcp: ## Construir imagen para GCP
	@echo "$(GREEN)🔨 Construyendo imagen para GCP...$(NC)"
	@docker build -f Dockerfile.api -t $(API_TAG) .
	@docker tag $(API_TAG) $(API_TAG_LATEST)
	@echo "$(GREEN)✅ Imagen construida: $(API_TAG)$(NC)"

.PHONY: push-gcp
push-gcp: ## Subir imagen a GCP Container Registry
	@echo "$(GREEN)☁️  Subiendo imagen a GCP...$(NC)"
	@docker push $(API_TAG)
	@docker push $(API_TAG_LATEST)
	@echo "$(GREEN)✅ Imagen subida a GCP$(NC)"

.PHONY: deploy-gcp
deploy-gcp: build-gcp push-gcp ## Build y push completo a GCP
	@echo "$(GREEN)✅ Despliegue a GCP completado$(NC)"
	@echo "$(BLUE)Siguiente paso: Ir a Cloud Run y desplegar $(API_TAG)$(NC)"

# =============================================================================
# UTILIDADES
# =============================================================================

.PHONY: shell-api
shell-api: ## Abrir shell en contenedor de API
	@docker-compose exec python-api /bin/bash

.PHONY: shell-jupyter
shell-jupyter: ## Abrir shell en contenedor de Jupyter
	@docker-compose exec jupyter /bin/bash

.PHONY: shell-postgres
shell-postgres: ## Conectar a PostgreSQL
	@docker-compose exec postgres psql -U postgres -d datascience

.PHONY: backup-db
backup-db: ## Crear backup de PostgreSQL
	@echo "$(GREEN)💾 Creando backup de base de datos...$(NC)"
	@mkdir -p backups
	@docker-compose exec postgres pg_dump -U postgres datascience > backups/backup_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "$(GREEN)✅ Backup creado en carpeta backups/$(NC)"

.PHONY: clean
clean: ## Limpiar contenedores e imágenes
	@echo "$(GREEN)🧹 Limpiando...$(NC)"
	@docker-compose down -v
	@docker system prune -f
	@echo "$(GREEN)✅ Limpieza completada$(NC)"

.PHONY: clean-all
clean-all: ## Limpiar todo (⚠️  incluye volúmenes)
	@echo "$(RED)⚠️  PELIGRO: Esto eliminará TODOS los datos$(NC)"
	@read -p "¿Estás seguro? (escriba 'yes' para continuar): " confirm && [ "$$confirm" = "yes" ] || exit 1
	@docker-compose down -v
	@docker system prune -a -f --volumes
	@echo "$(GREEN)✅ Limpieza completa realizada$(NC)"

# =============================================================================
# VERSIONADO
# =============================================================================

.PHONY: version
version: ## Mostrar versión actual
	@echo "$(BLUE)📦 Versión actual: $(APP_VERSION)$(NC)"

.PHONY: bump-version
bump-version: ## Actualizar versión (ej: make bump-version VERSION=v1.0.1)
	@if [ -z "$(VERSION)" ]; then \
		echo "$(RED)❌ Error: Especifica VERSION=v1.x.x$(NC)"; \
		echo "$(YELLOW)Ejemplo: make bump-version VERSION=v1.0.1$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)📦 Actualizando versión a $(VERSION)...$(NC)"
	@sed -i 's/APP_VERSION ?= v[0-9]\+\.[0-9]\+\.[0-9]\+/APP_VERSION ?= $(VERSION)/' Makefile
	@echo "$(GREEN)✅ Versión actualizada a $(VERSION)$(NC)"

# =============================================================================
# INFORMACIÓN
# =============================================================================

.PHONY: info
info: ## Mostrar información del entorno
	@echo "$(BLUE)📋 Información del entorno:$(NC)"
	@echo ""
	@echo "$(YELLOW)🐳 Docker:$(NC)"
	@docker --version 2>/dev/null || echo "$(RED)❌ Docker no instalado$(NC)"
	@docker-compose --version 2>/dev/null || echo "$(RED)❌ Docker Compose no instalado$(NC)"
	@echo ""
	@echo "$(YELLOW)📁 Estructura del proyecto:$(NC)"
	@echo "  • notebooks/     - Jupyter notebooks"
	@echo "  • data/          - Datos y archivos"
	@echo "  • scripts/       - Scripts de Python"
	@echo "  • api/           - Código de la API Flask"
	@echo "  • init_db/       - Scripts de inicialización de DB"
	@echo ""
	@echo "$(YELLOW)🔧 Comandos principales:$(NC)"
	@echo "  • make up        - Iniciar servicios"
	@echo "  • make down      - Detener servicios"
	@echo "  • make status    - Ver estado"
	@echo "  • make test      - Probar conectividad"
	@echo "  • make logs      - Ver logs"

.PHONY: urls
urls: ## Mostrar URLs de acceso
	@echo "$(GREEN)🌐 URLs de acceso:$(NC)"
	@echo "  • Jupyter Lab:     http://localhost:$(JUPYTER_PORT) (token: datascience123)"
	@echo "  • API Flask:       http://localhost:$(API_PORT)"
	@echo "  • Qdrant Dashboard: http://localhost:$(QDRANT_PORT)/dashboard"
	@echo "  • n8n:             http://localhost:$(N8N_PORT) (admin/n8npassword123)"
	@echo "  • Adminer:         http://localhost:8081"
	@echo ""
	@echo "$(BLUE)📊 Conexión PostgreSQL:$(NC)"
	@echo "  • Host: localhost:$(POSTGRES_PORT)"
	@echo "  • Database: datascience"
	@echo "  • User: postgres"
	@echo "  • Password: postgres"

# =============================================================================
# ALIASES COMUNES
# =============================================================================

.PHONY: start
start: up ## Alias para 'up'

.PHONY: stop
stop: down ## Alias para 'down'