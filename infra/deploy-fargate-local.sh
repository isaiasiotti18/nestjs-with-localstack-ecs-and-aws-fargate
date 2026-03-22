#!/usr/bin/env bash
# ================================================================
#  deploy-fargate-local.sh
#  Simula deploy ECS Fargate via Docker Compose
#  Mesma experiência de um deploy real: build → register → deploy
# ================================================================
set -euo pipefail

COMPOSE_FILE="docker-compose.fargate.yml"
IMAGE_NAME="bun-nestjs-app"
IMAGE_TAG="latest"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${CYAN}[INFO]${NC}  $1"; }
ok()   { echo -e "${GREEN}[OK]${NC}    $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $1"; }
fail() { echo -e "${RED}[FAIL]${NC}  $1"; exit 1; }

header() {
  echo ""
  echo -e "${CYAN}──────────────────────────────────────────────────${NC}"
  echo -e "${CYAN}  $1${NC}"
  echo -e "${CYAN}──────────────────────────────────────────────────${NC}"
}

# ── Pré-checks ──────────────────────────────────────────────────
command -v docker  >/dev/null 2>&1 || fail "docker não encontrado"

# ── 1. Build (simula ECR push) ──────────────────────────────────
header "1/5 — Build da imagem (simula ECR push)"
log "Building ${IMAGE_NAME}:${IMAGE_TAG}..."
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .
ok "Imagem pronta: ${IMAGE_NAME}:${IMAGE_TAG}"

# ── 2. Task Definition (mostra config equivalente) ──────────────
header "2/5 — Task Definition"
log "Configuração equivalente ao ECS:"
echo "  Family:   bun-nestjs-task"
echo "  CPU:      256 (0.25 vCPU)"
echo "  Memory:   512 MB"
echo "  Network:  awsvpc (bridge isolado)"
echo "  Image:    ${IMAGE_NAME}:${IMAGE_TAG}"
ok "Task Definition registrada"

# ── 3. Network (compose gerencia automaticamente) ──────────────
header "3/5 — Network (simula awsvpc + security groups)"
log "Networks serão criadas pelo Docker Compose:"
echo "  public  → fargate-public (172.28.0.0/16) — acesso externo"
echo "  data    → fargate-data (internal) — sem acesso externo"
ok "Network config pronta"

# ── 4. Deploy (simula ECS CreateService) ────────────────────────
header "4/5 — Deploy Service (desired count: 1)"
log "Subindo infraestrutura..."
docker compose -f "$COMPOSE_FILE" up -d --build --remove-orphans
ok "Service deployado"

# ── 5. Health Check (simula ECS health check) ──────────────────
header "5/5 — Aguardando Health Check"
MAX_RETRIES=20
RETRY=0
log "Esperando /health/live responder..."

while [ $RETRY -lt $MAX_RETRIES ]; do
  if curl -sf http://localhost:3000/health/live &>/dev/null; then
    ok "Health check passou!"
    echo ""
    break
  fi
  RETRY=$((RETRY + 1))
  echo -n "."
  sleep 2
done

if [ $RETRY -eq $MAX_RETRIES ]; then
  warn "Health check não respondeu em $((MAX_RETRIES * 2))s"
  warn "Verificando logs..."
  docker compose -f "$COMPOSE_FILE" logs app --tail=20
  echo ""
  fail "Container pode estar com problema. Verifique os logs acima."
fi

# ── Resumo ──────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Deploy concluído com sucesso!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""

# Status dos containers
docker compose -f "$COMPOSE_FILE" ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo -e "${CYAN}Endpoints:${NC}"
echo "  API:      http://localhost:3000"
echo "  Swagger:  http://localhost:3000/api/docs"
echo "  Health:   http://localhost:3000/health"
echo "  Live:     http://localhost:3000/health/live"
echo ""
echo -e "${CYAN}Comandos:${NC}"
echo "  # Logs (simula CloudWatch):"
echo "  docker compose -f ${COMPOSE_FILE} logs app -f"
echo ""
echo "  # Restart task (simula ECS stop task):"
echo "  docker compose -f ${COMPOSE_FILE} restart app"
echo ""
echo "  # Scale (simula desired count):"
echo "  docker compose -f ${COMPOSE_FILE} up -d --scale app=2"
echo ""
echo "  # Resource usage (simula CloudWatch metrics):"
echo "  docker stats fargate-task-app fargate-db"
echo ""
echo "  # Teardown:"
echo "  bash infra/teardown.sh"
