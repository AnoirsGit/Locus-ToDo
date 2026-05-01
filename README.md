# Цикл — Todo-система с автодисциплиной

> Таск-менеджер, который сам следит за дисциплиной.

Цикл — это система планирования задач на трёх временных горизонтах (неделя / месяц / год), где автоматика сама решает судьбу каждой задачи: выполнена → уходит в архив, просрочена → улетает в бэклог как неудача.

---

## Монорепозиторий

```
LocusToDo/
├── apps/
│   ├── web/        # SvelteKit 5 — веб-приложение
│   ├── api/        # Node.js + Fastify + PostgreSQL + Redis — бэкенд
│   └── mobile/     # Flutter — мобильное приложение
├── packages/
│   └── shared/     # Общие TypeScript-типы
└── docs/           # Документация
```

## Технологии

| Слой    | Стек                                      |
|---------|-------------------------------------------|
| Web     | SvelteKit 5, TypeScript, Vite             |
| API     | Node.js, Fastify 5, PostgreSQL, Redis     |
| Mobile  | Flutter 3, Riverpod, go_router            |
| Shared  | TypeScript types (workspace package)      |
| Infra   | pnpm workspaces, Docker Compose           |

## Быстрый старт

```bash
# Установить зависимости
pnpm install

# Запустить всё (web + api)
pnpm dev

# Только фронтенд
pnpm dev:web

# Только API
pnpm dev:api
```

### Переменные окружения (API)

```bash
cp apps/api/.env.example apps/api/.env
# Заполнить DATABASE_URL, REDIS_URL, JWT_SECRET
```

---

## Ключевые концепции

### Три уровня задач

- **Week** — оперативные задачи на неделю
- **Month** — среднесрочные цели на месяц
- **Year** — глобальные ориентиры на год

### Жизненный цикл

```
todo → done → [delay] → archived   (Путь А: выполнено)
todo → [deadline] → backlog(failed) (Путь Б: провал)
```

### Умное отображение

Задачи «старших» уровней всегда видны в «младших» видах.  
В виде «День» — видишь задачи дня, ниже — недели, месяца, года.

---

## Техническое задание

Полное ТЗ: [TECHNICAL-SPEC.md](./TECHNICAL-SPEC.md)

---

*Последнее обновление: 2026-05-01*
