#!/usr/bin/env bash
# ================================================================
#  teardown.sh — Para e remove todos os recursos
# ================================================================
set -euo pipefail

COMPOSE_FILE="docker-compose.fargate.yml"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${CYAN}[INFO]${NC}  $1"; }
ok()   { echo -e "${GREEN}[OK]${NC}    $1"; }

log "Parando e removendo containers..."
docker compose -f "$COMPOSE_FILE" down -v --remove-orphans 2>/dev/null || true
ok "Containers removidos"

log "Removendo networks..."
docker network rm fargate-public 2>/dev/null || true
docker network rm fargate-data   2>/dev/null || true
ok "Networks removidas"

log "Removendo imagem..."
docker rmi bun-nestjs-app:latest 2>/dev/null || true
ok "Imagem removida"

echo ""
echo -e "${GREEN}Teardown completo.${NC}"
