# 🚀 Bun + NestJS — ECS Fargate Simulation

Boilerplate production-ready: **Bun** runtime + **NestJS** framework + **MikroORM** (PostgreSQL) + deploy simulando **ECS Fargate** via Docker Compose com network isolation, resource limits e health checks.

## Stack

| Camada          | Tecnologia                          |
|-----------------|-------------------------------------|
| Runtime         | Bun 1.1                             |
| Framework       | NestJS 10                           |
| ORM             | MikroORM 6 (PostgreSQL driver)      |
| Docs            | Swagger / OpenAPI 3                 |
| Containerização | Docker multi-stage (oven/bun)       |
| Infra local     | Docker Compose (simula ECS Fargate) |

## Quick Start

### 1. Dev local (sem Docker)

```bash
cp .env.example .env
bun install

# Suba um Postgres local ou use o compose
docker compose -f docker-compose.fargate.yml up postgres -d

bun run schema:update
bun run start:dev
```

Swagger UI: http://localhost:3000/api/docs

### 2. Deploy Fargate Simulado (recomendado)

```bash
# Deploy completo — build, network, health check
bash infra/deploy-fargate-local.sh

# Teardown
bash infra/teardown.sh
```

O script simula o fluxo de um deploy ECS Fargate real:
1. **Build** da imagem Docker (equivale ao ECR push)
2. **Task Definition** com CPU/Memory limits
3. **Network** isolada (equivale ao awsvpc mode)
4. **Service** com desired count e restart policy
5. **Health Check** aguardando a app responder

### 3. Docker Compose direto

```bash
docker compose -f docker-compose.fargate.yml up --build
```

## Estrutura

```
├── src/
│   ├── config/
│   │   └── mikro-orm.config.ts    # Config MikroORM (entities explícitas)
│   ├── health/
│   │   ├── health.module.ts
│   │   └── health.controller.ts   # GET /health (DB check) + GET /health/live
│   ├── tasks/
│   │   ├── dto/
│   │   │   ├── create-task.dto.ts
│   │   │   └── update-task.dto.ts
│   │   ├── entities/
│   │   │   └── task.entity.ts     # UUID, enum status, timestamps
│   │   ├── tasks.module.ts
│   │   ├── tasks.controller.ts    # CRUD completo
│   │   └── tasks.service.ts       # EntityManager pattern
│   ├── app.module.ts
│   └── main.ts
├── infra/
│   ├── deploy-fargate-local.sh    # Deploy simulando ECS Fargate
│   └── teardown.sh                # Cleanup completo
├── docker-compose.fargate.yml     # Compose com Fargate simulation
├── Dockerfile                     # Multi-stage com oven/bun
└── .env.example
```

## Endpoints

| Method   | Path           | Descrição              |
|----------|----------------|------------------------|
| `GET`    | `/health`      | Health check (DB ping) |
| `GET`    | `/health/live` | Liveness probe         |
| `POST`   | `/tasks`       | Criar task             |
| `GET`    | `/tasks`       | Listar tasks           |
| `GET`    | `/tasks/:id`   | Buscar task por ID     |
| `PUT`    | `/tasks/:id`   | Atualizar task         |
| `DELETE` | `/tasks/:id`   | Remover task           |

## O que simula do ECS Fargate

| Aspecto ECS Fargate           | Simulado | Como                                                        |
|-------------------------------|----------|-------------------------------------------------------------|
| awsvpc network mode           | ✅       | Duas bridge networks (`public` + `data` internal)           |
| Resource limits (CPU/Mem)     | ✅       | `deploy.resources.limits` — 0.25 vCPU / 512MB              |
| Container health check        | ✅       | Docker healthcheck com mesmos parâmetros do ECS             |
| Service restart on failure    | ✅       | `restart: always` simula desired count = 1                  |
| Read-only rootfs              | ✅       | `read_only: true` + tmpfs, como Fargate faz                 |
| Scaling (desired count)       | ✅       | `docker compose up --scale app=N`                           |
| Private subnet (DB)           | ✅       | Network `data` com `internal: true`                         |
| CloudWatch Logs               | Parcial  | `json-file` driver com tags ECS-like                        |
| IAM task role                 | ❌       | Não aplicável local                                         |
| Service discovery             | ❌       | Precisaria Consul/CoreDNS                                   |
| ALB + target group            | ❌       | Precisaria Nginx/Traefik na frente                          |

## Comandos úteis

```bash
# Logs (simula CloudWatch)
docker compose -f docker-compose.fargate.yml logs app -f

# Restart task (simula ECS StopTask)
docker compose -f docker-compose.fargate.yml restart app

# Scale (simula desired count)
docker compose -f docker-compose.fargate.yml up -d --scale app=2

# Resource usage (simula CloudWatch Metrics)
docker stats fargate-task-app fargate-db

# Teardown completo
bash infra/teardown.sh
```

## Trade-offs & Decisões

- **Bun como runtime, NestJS CLI pra build**: O `nest build` usa tsc. Bun roda o output JS, mas o bundler do Bun ainda não lida bem com `emitDecoratorMetadata` do NestJS. Trade-off aceitável — build é dev-time, runtime é Bun puro.
- **MikroORM com entities explícitas**: Glob patterns (`dist/**/*.entity.js`) quebram dentro de containers por diferença de working directory. Import direto das classes é mais confiável e recomendado pelo MikroORM pra produção.
- **MikroORM vs Prisma**: Unit of Work pattern nativo, melhor fit pra DDD. Prisma é mais simples mas menos flexível pra domínios ricos.
- **Docker Compose ao invés de LocalStack ECS**: ECS e ECR são features Pro do LocalStack. O Compose com resource limits, network isolation e health checks cobre ~80% do comportamento real do Fargate pra desenvolvimento local.
- **`host.docker.internal` no DB_HOST**: Permite comunicação entre containers. Em produção real seria um RDS endpoint.
- **`read_only: true` + tmpfs**: Simula o ephemeral storage do Fargate. Força a app a não depender de escrita no filesystem.
