# arch/backend.md

> Load when: API, business logic, backend layers, auth, scheduler.

## Architecture: Hexagonal (Ports and Adapters)

```
apps/api/src/
├── domain/              # Core — business logic, no framework dependencies
│   ├── task/
│   │   ├── task.ts          # Entity + business rules (when to fail, when to archive)
│   │   └── task.port.ts     # Port: ITaskRepository (interface)
│   ├── user/
│   │   ├── user.ts
│   │   └── user.port.ts     # Port: IUserRepository
│   └── scheduler/
│       └── scheduler.port.ts # Port: IScheduler
│
├── application/         # Use Cases — orchestration, no infra dependencies
│   ├── task/
│   │   ├── create-task.usecase.ts
│   │   ├── complete-task.usecase.ts
│   │   ├── fail-overdue-tasks.usecase.ts
│   │   └── archive-done-tasks.usecase.ts
│   └── auth/
│       ├── register.usecase.ts
│       └── login.usecase.ts
│
├── infrastructure/      # Adapters — everything external: DB, Redis, HTTP
│   ├── db/
│   │   ├── client.ts             # postgres connection
│   │   ├── task.repository.ts    # Implements ITaskRepository
│   │   └── user.repository.ts    # Implements IUserRepository
│   ├── redis/
│   │   └── token.store.ts        # Refresh tokens
│   ├── scheduler/
│   │   └── interval.scheduler.ts # Implements IScheduler (setInterval, MVP)
│   └── http/
│       ├── plugins/              # Fastify plugins (jwt, cors, redis)
│       └── routes/               # Fastify routes → call use cases
│           ├── auth.routes.ts
│           └── tasks.routes.ts
│
└── server.ts            # Entry point — wires all adapters together
```

---

## Layer Rules

| Layer            | May depend on             | Must not depend on      |
|------------------|---------------------------|--------------------------|
| `domain`         | nothing external          | everything               |
| `application`    | `domain`                  | `infrastructure`, HTTP   |
| `infrastructure` | `domain`, `application`   | —                        |

Dependencies always point **inward** (toward domain).  
Use cases receive repositories via constructor injection (ports, not concretes).

---

## Authentication

**Status: not decided ⚠️**

| Option | Description | Pro | Con |
|--------|-------------|-----|-----|
| **A — Redis** | Access JWT (15 min) + Refresh UUID in Redis with TTL | Simple invalidation (`DEL key`) | Redis dependency |
| **B — PostgreSQL** | `sessions(id, user_id, token_hash, expires_at)` table | Audit log, revoke all sessions | Extra DB query on each refresh |

Redis key pattern: `refresh:{userId}:{tokenId}`

---

## API Contracts (draft)

- Prefix: `/api`
- Auth: `Authorization: Bearer <access_token>`
- Errors: `{ error: string, details?: unknown }`
- Dates: ISO 8601

```
POST   /api/auth/register
POST   /api/auth/login
GET    /api/auth/me

GET    /api/tasks          ?level=week|month|year  &status=todo|done|...
POST   /api/tasks
PATCH  /api/tasks/:id
DELETE /api/tasks/:id
```

---

## Decisions

| Date       | Decision                                     | Reason                                   |
|------------|----------------------------------------------|------------------------------------------|
| 2026-05-01 | Fastify 5                                    | Performance, TypeScript first-class      |
| 2026-05-01 | Scheduler inside API process (setInterval)   | MVP; separate worker in the future       |
| 2026-05-01 | JSONB for `recurring_config`                 | Flexibility without extra tables         |
| 2026-05-01 | Hexagonal Architecture                       | Isolate business logic from Fastify/pg   |
