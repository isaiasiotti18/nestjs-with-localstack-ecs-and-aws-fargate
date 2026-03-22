# 🚀 Bun + NestJS — ECS Fargate on LocalStack

Boilerplate production-ready: **Bun** runtime + **NestJS** framework + **MikroORM** (PostgreSQL) + deploy em **ECS Fargate** via **LocalStack**.

## Stack

| Camada          | Tecnologia                          |
|-----------------|-------------------------------------|
| Runtime         | Bun 1.1                             |
| Framework       | NestJS 10                           |
| ORM             | MikroORM 6 (PostgreSQL driver)      |
| Docs            | Swagger / OpenAPI 3                 |
| Containerização | Docker multi-stage (oven/bun)       |
| Infra local     | LocalStack (ECR, ECS, IAM, CW Logs)|

## Quick Start

### 1. Dev local (sem Docker)

```bash
cp .env.example .env
bun install
# Suba um Postgres local ou use o docker-compose
docker compose up postgres -d
bun run schema:update
bun run start:dev
```

Swagger UI: http://localhost:3000/api/docs

### 2. Docker Compose (app + banco + localstack)

```bash
docker compose up --build
```

### 3. Deploy ECS Fargate no LocalStack

```bash
# Pré-requisito
pip install awscli-local

# Suba o LocalStack
docker compose up localstack -d

# Deploy completo
chmod +x infra/deploy-localstack.sh
bash infra/deploy-localstack.sh

# Teardown
bash infra/teardown.sh
```

## Estrutura

```
src/
├── config/
│   └── mikro-orm.config.ts    # Configuração MikroORM
├── health/
│   ├── health.module.ts       
│   └── health.controller.ts   # GET /health (DB check) + GET /health/live
├── tasks/
│   ├── dto/
│   │   ├── create-task.dto.ts
│   │   └── update-task.dto.ts
│   ├── entities/
│   │   └── task.entity.ts     # Entity com UUID, enum status, timestamps
│   ├── tasks.module.ts
│   ├── tasks.controller.ts    # CRUD completo
│   └── tasks.service.ts       # EntityManager pattern
├── app.module.ts
└── main.ts
infra/
├── deploy-localstack.sh       # ECR + ECS + Fargate + IAM + Logs
└── teardown.sh                # Cleanup completo
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

## Trade-offs & Decisões

- **Bun como runtime, NestJS CLI pra build**: O `nest build` usa tsc. Bun roda o output JS perfeitamente, mas o bundler do Bun ainda não lida bem com decorators do NestJS. Trade-off aceitável — build é dev-time, runtime é Bun puro.
- **MikroORM vs Prisma**: MikroORM tem Unit of Work pattern nativo, melhor fit pra DDD. Prisma é mais simples mas é um query builder glorificado. Escolhi MikroORM pela capacidade de flush transacional.
- **Fargate 256 CPU / 512 MB**: Mínimo do Fargate. Suficiente pro boilerplate. Escale conforme necessidade.
- **`host.docker.internal` no DB_HOST da Task Definition**: Permite que o container Fargate do LocalStack acesse o Postgres rodando no host. Em produção real, seria um RDS endpoint.
