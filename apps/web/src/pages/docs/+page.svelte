<script lang="ts">
  import { onMount } from 'svelte'
  import { i18n } from '$shared/lib/i18n'

  onMount(() => {
    const saved = localStorage.getItem('lang')
    if (saved === 'ru' || saved === 'en') i18n.locale = saved
  })

  const ru = {
    title: 'Как работает Locus',
    subtitle: 'Полная документация по логике задач, статусам и планировщику.',
    nav: { overview: 'Обзор', horizons: 'Горизонты', lifecycle: 'Жизненный цикл', recurring: 'Повторяющиеся', views: 'Виды', planned: 'Планируется' },
    openApp: 'Открыть приложение →',

    overview: {
      h: 'Обзор',
      p1: 'Locus организует работу вокруг <strong>четырёх временных горизонтов</strong>: год, месяц, неделя и день. Каждая задача принадлежит ровно одному горизонту — он называется <em>уровнем</em>. Уровень определяет длительность активного периода и когда планировщик её обработает.',
      p2: 'Главная идея: амбициозные цели сверху (год), разбитые на месячные вехи, еженедельные результаты и ежедневные действия снизу. Вид «Сегодня» показывает все четыре горизонта сразу, чтобы всегда видеть полный контекст.',
      callout: '<strong>Ключевой принцип:</strong> задачи не удаляются при провале — они архивируются с записью результата. Это даёт честную долгосрочную статистику.',
    },

    horizons: {
      h: 'Временные горизонты',
      day: {
        period: 'Период: 1 день',
        desc: 'Задачи на конкретный день. Отображаются в виде «Сегодня» и в дневной колонке вида «Неделя». Можно указать время. Пропущенные задачи дня архивируются напрямую без фазы просрочки.',
        f1: 'Необязательное запланированное время',
        f2: 'Видны в «Сегодня» и «Неделя»',
        f3: 'Могут повторяться ежедневно',
      },
      week: {
        period: 'Период: пн → вс',
        desc: 'Задачи на неделю. Неделя всегда начинается в понедельник. Пропущенные задачи получают 7-дневное окно просрочки.',
        f1: 'Необязательный целевой день (пн–вс)',
        f2: 'Необязательное время',
        f3: 'Могут повторяться еженедельно',
      },
      month: {
        period: 'Период: 1-е → последнее число',
        desc: 'Месячные цели. Отображаются в виде «Месяц» и как контекст в «Сегодня». Пропущенные задачи получают 30-дневное окно просрочки.',
        f1: 'Без времени или целевой даты',
        f2: 'Могут повторяться ежемесячно',
      },
      year: {
        period: 'Период: 1 янв → 31 дек',
        desc: 'Годовые цели. Можно указать дедлайн-месяц — мягкий ориентир внутри года.',
        f1: 'Необязательный месяц дедлайна',
        f2: 'Могут повторяться ежегодно',
      },
    },

    lifecycle: {
      h: 'Жизненный цикл задачи',
      p: 'У каждой задачи есть <strong>период</strong> — запись в БД, отслеживающая статус в конкретном временном окне. Планировщик запускается периодически и автоматически продвигает статусы.',
      todo: { title: 'Todo', desc: 'Активна, ещё не выполнена. Чекбокс не отмечен. Можно свободно переключать.' },
      done: { title: 'Done', desc: 'Чекбокс отмечен в течение периода. По окончании планировщик архивирует как <em>вовремя</em>. Снятие отметки возвращает в todo.' },
      overdue: { title: 'Overdue (просрочено)', desc: 'Период закончился, задача не выполнена. Создаётся штрафной период той же длительности. Можно ещё выполнить — тогда заархивируется как <em>с опозданием</em>.' },
      backlog: { title: 'Backlog', desc: 'Задача не выполнена и в штрафной период. Живёт в бэклоге без активного периода. Отсюда можно <strong>Перепланировать</strong> — выбрать новый период. Старый архивируется как провал.' },
      archived: {
        title: 'Archived', desc: 'Финальный статус. Результат выводится из <code>done_at</code>:',
        outcomes: ['<em>Вовремя</em> — выполнено в рамках исходного периода', '<em>С опозданием</em> — выполнено в штрафной период', '<em>Провал</em> — <code>done_at</code> = null, никогда не выполнено'],
        note: 'Архивированные задачи нельзя удалить — это исторические записи.',
      },
      callout: '<strong>Правило удаления:</strong> задача может быть жёстко удалена только если у неё <em>нет архивных периодов</em>.',
    },

    recurring: {
      h: 'Повторяющиеся задачи',
      p: 'Включите <strong>Повторяющуюся</strong> при создании или редактировании задачи. Планировщик обрабатывает их автоматически, не перемещая через просрочку/бэклог.',
      th: ['Уровень', 'Настройка', 'Что происходит по окончании периода'],
      rows: [
        ['День', 'Без дополнительных настроек', 'Текущий период архивируется; создаётся новый todo на завтра'],
        ['Неделя', 'День недели (по умолчанию: пн)', 'Текущий период архивируется; новый todo создаётся на следующую неделю'],
        ['Месяц', 'День месяца (напр., 1-е)', 'Текущий период архивируется; новый todo создаётся на следующий месяц'],
        ['Год', '—', 'Текущий период архивируется; новый todo создаётся на следующий год'],
      ],
      p2: 'Повторяющиеся задачи отслеживаются в статистике как <strong>Постоянство %</strong> (как часто выполнялись), тогда как разовые задачи показывают <strong>Выполнение %</strong>.',
    },

    views: {
      h: 'Виды',
      items: [
        { title: 'Сегодня', desc: 'Центр управления. Дневные задачи на сегодня плюс задачи недели / месяца / года как контекст.' },
        { title: 'Неделя', desc: '7 колонок (пн–вс). Дневные задачи в своей колонке. Задачи недели показаны ниже.' },
        { title: 'Месяц', desc: 'Все активные задачи месячного уровня.' },
        { title: 'Год', desc: 'Все активные годовые задачи. Показывает чип с месяцем дедлайна.' },
        { title: 'Бэклог', desc: 'Задачи, пропустившие штрафной период. Используйте «Перепланировать» для нового периода.' },
        { title: 'Архив', desc: 'Только для чтения. История всех завершённых / проваленных периодов.' },
      ],
    },

    planned: {
      h: 'Планируется',
      p: 'Подтверждённые пункты дорожной карты — ещё не готовы.',
      items: [
        {
          tag: 'Мобильное', title: 'Офлайн-режим + умная синхронизация',
          p: 'Мобильное приложение будет хранить все задачи локально (SQLite через Drift), работая без интернета. Записи идут в локальную БД мгновенно, затем ставятся в очередь для фоновой синхронизации. При конфликте побеждает сервер.',
          bullets: ['Мгновенная реакция UI — никаких спиннеров', 'Очередь переживает перезапуск приложения', 'Фоновое слияние при подключении'],
        },
        {
          tag: 'Мобильное', title: 'Уведомления перед дедлайном',
          p: 'Для задач с запланированным временем локальное уведомление срабатывает за X минут (по умолчанию 30). Отменяется автоматически при отметке выполнено.',
          bullets: ['Только для задач с <code>scheduled_time</code>', 'Отменяется при отметке', 'Настраиваемое время опережения'],
        },
        {
          tag: 'Мобильное', title: 'Вечерное сводное уведомление',
          p: 'Ежедневное уведомление в настраиваемое время (по умолчанию 20:00) показывает количество незавершённых задач на сегодня. Пропускается, если всё выполнено.',
          bullets: ['Настраиваемое время (по умолчанию 20:00)', 'Считает todo + overdue задачи дня', 'Тихий режим, если ничего не осталось'],
        },
        {
          tag: 'Все платформы', title: 'Подзадачи',
          p: 'Задачи могут содержать подзадачи — чеклист мелких шагов. Подзадачи не имеют независимого статуса и не обрабатываются планировщиком — они наследуют период родителя.',
          bullets: [],
        },
        {
          tag: 'Все платформы', title: 'Повторяющиеся: несколько дней в неделю',
          p: 'Повторяющиеся недельные задачи будут поддерживать выбор нескольких дней (напр., пн + ср + пт), до 6. Сейчас ограничено одним днём.',
          bullets: [],
        },
      ],
    },
  }

  const en = {
    title: 'How Locus works',
    subtitle: 'Complete reference for task logic, statuses, and scheduler behavior.',
    nav: { overview: 'Overview', horizons: 'Time horizons', lifecycle: 'Task lifecycle', recurring: 'Recurring', views: 'Views', planned: 'Planned' },
    openApp: 'Open app →',

    overview: {
      h: 'Overview',
      p1: 'Locus organises your work around <strong>four time horizons</strong>: year, month, week, and day. Each task belongs to exactly one horizon (its <em>level</em>). A task\'s level determines how long its active period lasts and when the scheduler processes it.',
      p2: 'The central idea: ambitious goals at the top (year), broken into monthly milestones, weekly deliverables, and daily actions at the bottom. The Today view shows all four horizons at once so you always see the full context.',
      callout: '<strong>Key principle:</strong> tasks are not deleted when they fail — they are archived with an outcome record. This gives you honest long-term stats instead of a clean slate.',
    },

    horizons: {
      h: 'Time horizons',
      day: {
        period: 'Period: 1 day',
        desc: 'Single-day tasks. Appear in the Today view and the Day column of the Week view. Can have a scheduled time. Missed day tasks are archived directly — no overdue step.',
        f1: 'Optional scheduled time',
        f2: 'Visible in Today + Week views',
        f3: 'Can recur daily',
      },
      week: {
        period: 'Period: Mon → Sun',
        desc: 'Weekly tasks. A week always starts on Monday. Missed week tasks get a 7-day overdue window.',
        f1: 'Optional target day (Mon–Sun)',
        f2: 'Optional scheduled time',
        f3: 'Can recur weekly',
      },
      month: {
        period: 'Period: 1st → last day',
        desc: 'Monthly goals. Shown in the Month view and as context in Today. Missed month tasks get a 30-day overdue window.',
        f1: 'No time or target date',
        f2: 'Can recur monthly',
      },
      year: {
        period: 'Period: Jan 1 → Dec 31',
        desc: 'Annual objectives. You can set a deadline month — a soft target within the year.',
        f1: 'Optional deadline month',
        f2: 'Can recur yearly',
      },
    },

    lifecycle: {
      h: 'Task lifecycle',
      p: 'Every task has a <strong>period</strong> — a DB record that tracks the task\'s status within a specific time window. The scheduler runs periodically and advances statuses automatically.',
      todo: { title: 'Todo', desc: 'Active, not yet done. The checkbox is unchecked. You can toggle it done and back freely.' },
      done: { title: 'Done', desc: 'Checkbox checked within the period. At period end, the scheduler archives it as <em>on-time</em>. Unchecking reverts to todo.' },
      overdue: { title: 'Overdue', desc: 'The period expired with the task incomplete. A penalty period of the same duration is created. You still have a chance to complete it — archiving it as <em>late</em>.' },
      backlog: { title: 'Backlog', desc: 'Task was not completed during overdue. It sits in the Backlog with no active period. From here you can <strong>Replan</strong> it — pick a new period. The failed period is archived as a failure.' },
      archived: {
        title: 'Archived', desc: 'Terminal state. The outcome is derived from <code>done_at</code>:',
        outcomes: ['<em>On time</em> — done within the original period', '<em>Late</em> — done during the overdue window', '<em>Failed</em> — <code>done_at</code> is null (never completed)'],
        note: 'Archived tasks cannot be deleted — they are historical records.',
      },
      callout: '<strong>Hard delete rule:</strong> a task can only be deleted if it has <em>no archived periods</em>.',
    },

    recurring: {
      h: 'Recurring tasks',
      p: 'Enable <strong>Recurring</strong> when creating or editing a task. Recurring tasks behave differently — the scheduler handles them automatically without moving them through overdue/backlog.',
      th: ['Level', 'Config', 'What happens at period end'],
      rows: [
        ['Day', 'No extra config', 'Current period archived; new todo period created for tomorrow'],
        ['Week', 'Day of week (default: Monday)', 'Current period archived; new todo created for next week'],
        ['Month', 'Day of month (e.g. 1st)', 'Current period archived; new todo created for next month'],
        ['Year', '—', 'Current period archived; new todo created for next year'],
      ],
      p2: 'Recurring tasks are tracked in stats as <strong>Consistency %</strong> (how often you completed them), whereas one-off tasks show <strong>Completion %</strong>.',
    },

    views: {
      h: 'Views',
      items: [
        { title: 'Today', desc: 'Your command centre. Day tasks for today plus week / month / year tasks as context.' },
        { title: 'Week', desc: '7-column layout (Mon–Sun). Day tasks in their column. Week tasks shown below.' },
        { title: 'Month', desc: 'All active month-level tasks.' },
        { title: 'Year', desc: 'All active year-level tasks. Shows deadline month chip.' },
        { title: 'Backlog', desc: 'Tasks that missed their overdue window. Use Replan to assign a new period.' },
        { title: 'Archive', desc: 'Read-only history of all completed / failed periods.' },
      ],
    },

    planned: {
      h: 'Planned features',
      p: 'These are confirmed roadmap items — not yet shipped.',
      items: [
        {
          tag: 'Mobile', title: 'Offline mode + smart sync',
          p: 'The mobile app will store all tasks locally (SQLite via Drift) so it works without internet. Writes go to the local database immediately, then queue for background sync. On conflict, the server wins.',
          bullets: ['Instant UI response — no spinner on toggle', 'Persistent outbox survives app restarts', 'Background merge on reconnect'],
        },
        {
          tag: 'Mobile', title: 'Pre-deadline notifications',
          p: 'For tasks with a scheduled time, a local notification fires X minutes before (default 30 min). Cancelled automatically if you mark the task done first.',
          bullets: ['Only for tasks with <code>scheduled_time</code>', 'Cancelled on toggle-done', 'Configurable lead time'],
        },
        {
          tag: 'Mobile', title: 'Evening summary notification',
          p: 'A daily notification at a user-chosen time (default 20:00) shows the count of pending tasks for today. Skipped automatically if all tasks are done.',
          bullets: ['Configurable time (default 20:00)', 'Counts todo + overdue day tasks', 'Silent if nothing is pending'],
        },
        {
          tag: 'All platforms', title: 'Subtasks',
          p: 'Tasks can contain subtasks. Subtasks have no independent status and do not get their own scheduler lifecycle — they inherit the parent period.',
          bullets: [],
        },
        {
          tag: 'All platforms', title: 'Recurring: multiple days per week',
          p: 'Recurring week tasks will support selecting multiple days (e.g. Mon + Wed + Fri), up to 6. Currently limited to one day per week.',
          bullets: [],
        },
      ],
    },
  }

  const t = $derived(i18n.locale === 'ru' ? ru : en)

  const levelKeys = ['day', 'week', 'month', 'year'] as const
  const levelLabels: Record<string, string> = { day: 'Day', week: 'Week', month: 'Month', year: 'Year' }
</script>

<svelte:head>
  <title>Locus — {t.title}</title>
</svelte:head>

<div class="docs-page">

  <!-- Nav -->
  <nav class="docs-nav">
    <a href="/" class="docs-brand">
      <span class="docs-brand-name">Locus</span>
      <span class="docs-brand-dot"></span>
    </a>
    <div class="docs-nav-links">
      <a href="#overview">{t.nav.overview}</a>
      <a href="#horizons">{t.nav.horizons}</a>
      <a href="#lifecycle">{t.nav.lifecycle}</a>
      <a href="#recurring">{t.nav.recurring}</a>
      <a href="#views">{t.nav.views}</a>
      <a href="#planned">{t.nav.planned}</a>
    </div>
    <div class="docs-nav-right">
      <button
        class="docs-lang-toggle"
        onclick={() => { i18n.locale = i18n.locale === 'ru' ? 'en' : 'ru' }}
      >{i18n.locale === 'ru' ? 'EN' : 'RU'}</button>
      <a href="/today" class="docs-cta">{t.openApp}</a>
    </div>
  </nav>

  <main class="docs-main">

    <!-- Hero -->
    <section class="docs-hero">
      <div class="docs-hero-eyebrow">{i18n.locale === 'ru' ? 'Документация' : 'Documentation'}</div>
      <h1 class="docs-hero-title">{@html i18n.locale === 'ru' ? 'Как работает <em>Locus</em>' : 'How <em>Locus</em> works'}</h1>
      <p class="docs-hero-sub">{t.subtitle}</p>
    </section>

    <!-- Overview -->
    <section class="docs-section" id="overview">
      <h2 class="docs-h2">{t.overview.h}</h2>
      <p>{@html t.overview.p1}</p>
      <p>{@html t.overview.p2}</p>
      <div class="docs-callout docs-callout-info">{@html t.overview.callout}</div>
    </section>

    <!-- Time horizons -->
    <section class="docs-section" id="horizons">
      <h2 class="docs-h2">{t.horizons.h}</h2>

      <div class="docs-horizon-grid">
        {#each levelKeys as lk}
          {@const card = t.horizons[lk]}
          <div class="docs-horizon-card docs-horizon-{lk}">
            <div class="docs-horizon-badge">{levelLabels[lk]}</div>
            <div class="docs-horizon-period">{card.period}</div>
            <p class="docs-horizon-desc">{card.desc}</p>
            <ul class="docs-horizon-features">
              <li>{card.f1}</li>
              <li>{card.f2}</li>
              {#if 'f3' in card}<li>{card.f3}</li>{/if}
            </ul>
          </div>
        {/each}
      </div>
    </section>

    <!-- Lifecycle -->
    <section class="docs-section" id="lifecycle">
      <h2 class="docs-h2">{t.lifecycle.h}</h2>
      <p>{@html t.lifecycle.p}</p>

      <div class="docs-flow">
        <div class="docs-flow-step docs-flow-todo">
          <div class="docs-flow-icon">●</div>
          <div>
            <strong>{t.lifecycle.todo.title}</strong>
            <p>{@html t.lifecycle.todo.desc}</p>
          </div>
        </div>
        <div class="docs-flow-arrow">↓</div>
        <div class="docs-flow-step docs-flow-done">
          <div class="docs-flow-icon">✓</div>
          <div>
            <strong>{t.lifecycle.done.title}</strong>
            <p>{@html t.lifecycle.done.desc}</p>
          </div>
        </div>
        <div class="docs-flow-arrow">↓ ({i18n.locale === 'ru' ? 'если период закончился невыполненным' : 'if period ends undone'})</div>
        <div class="docs-flow-step docs-flow-overdue">
          <div class="docs-flow-icon">!</div>
          <div>
            <strong>{t.lifecycle.overdue.title}</strong>
            <p>{@html t.lifecycle.overdue.desc}</p>
          </div>
        </div>
        <div class="docs-flow-arrow">↓ ({i18n.locale === 'ru' ? 'если штрафной период тоже истёк' : 'if overdue period ends undone'})</div>
        <div class="docs-flow-step docs-flow-backlog">
          <div class="docs-flow-icon">⋯</div>
          <div>
            <strong>{t.lifecycle.backlog.title}</strong>
            <p>{@html t.lifecycle.backlog.desc}</p>
          </div>
        </div>
        <div class="docs-flow-arrow">↓ ({i18n.locale === 'ru' ? 'по окончании периода' : 'at period end'})</div>
        <div class="docs-flow-step docs-flow-archived">
          <div class="docs-flow-icon">▣</div>
          <div>
            <strong>{t.lifecycle.archived.title}</strong>
            <p>{@html t.lifecycle.archived.desc}</p>
            <ul>
              {#each t.lifecycle.archived.outcomes as o}
                <li>{@html o}</li>
              {/each}
            </ul>
            <p>{t.lifecycle.archived.note}</p>
          </div>
        </div>
      </div>

      <div class="docs-callout docs-callout-warn">{@html t.lifecycle.callout}</div>
    </section>

    <!-- Recurring -->
    <section class="docs-section" id="recurring">
      <h2 class="docs-h2">{t.recurring.h}</h2>
      <p>{@html t.recurring.p}</p>

      <div class="docs-table-wrap">
        <table class="docs-table">
          <thead>
            <tr>{#each t.recurring.th as th}<th>{th}</th>{/each}</tr>
          </thead>
          <tbody>
            {#each t.recurring.rows as [level, config, result], i}
              <tr>
                <td><span class="docs-level-badge docs-level-{levelKeys[i]}">{level}</span></td>
                <td>{config}</td>
                <td>{result}</td>
              </tr>
            {/each}
          </tbody>
        </table>
      </div>

      <p>{@html t.recurring.p2}</p>
    </section>

    <!-- Views -->
    <section class="docs-section" id="views">
      <h2 class="docs-h2">{t.views.h}</h2>
      <div class="docs-views-grid">
        {#each t.views.items as item}
          <div class="docs-view-card">
            <div class="docs-view-title">{item.title}</div>
            <p>{item.desc}</p>
          </div>
        {/each}
      </div>
    </section>

    <!-- Planned -->
    <section class="docs-section" id="planned">
      <h2 class="docs-h2">{t.planned.h}</h2>
      <p>{t.planned.p}</p>

      <div class="docs-planned-list">
        {#each t.planned.items as item}
          <div class="docs-planned-item">
            <div class="docs-planned-header">
              <span class="docs-planned-tag">{item.tag}</span>
              <span class="docs-planned-title">{item.title}</span>
            </div>
            <p>{@html item.p}</p>
            {#if item.bullets.length > 0}
              <ul>{#each item.bullets as b}<li>{@html b}</li>{/each}</ul>
            {/if}
          </div>
        {/each}
      </div>
    </section>

    <!-- Footer -->
    <footer class="docs-footer">
      <span>Locus — {i18n.locale === 'ru' ? 'для фокуса' : 'built for focus'}</span>
      <a href="/today">{t.openApp}</a>
    </footer>

  </main>
</div>

<style>
  /* ── Layout ── */
  .docs-page {
    font-family: var(--font-sans);
    color: var(--color-text);
    min-height: 100vh;
  }

  /* ── Nav ── */
  .docs-nav {
    display: flex; align-items: center; gap: 24px;
    padding: 0 40px; height: 56px;
    border-bottom: 1px solid var(--color-border);
    background: var(--color-card);
    position: sticky; top: 0; z-index: 10;
  }
  .docs-brand { display: flex; align-items: baseline; gap: 5px; text-decoration: none; }
  .docs-brand-name {
    font-family: var(--font-display); font-style: italic; font-size: 20px;
    font-weight: 500; color: var(--color-text-strong); letter-spacing: -0.02em;
  }
  .docs-brand-dot {
    width: 5px; height: 5px; border-radius: 50%;
    background: var(--color-year); flex-shrink: 0; margin-bottom: 2px;
  }
  .docs-nav-links {
    display: flex; gap: 4px; flex: 1;
  }
  .docs-nav-links a {
    padding: 4px 10px; border-radius: var(--r-sm);
    font-size: 13px; color: var(--color-text-2); text-decoration: none;
    transition: color 80ms, background 80ms;
  }
  .docs-nav-links a:hover { color: var(--color-text); background: var(--color-surface); }
  .docs-nav-right { display: flex; align-items: center; gap: 8px; }
  .docs-lang-toggle {
    font-size: 11px; font-weight: 600; font-family: var(--font-mono);
    letter-spacing: 0.08em; color: var(--color-muted);
    background: none; border: 1px solid var(--color-border);
    border-radius: var(--r-sm); padding: 4px 9px; cursor: pointer;
    transition: color 80ms, border-color 80ms;
  }
  .docs-lang-toggle:hover { color: var(--color-text); border-color: var(--color-border-2); }
  .docs-cta {
    font-size: 13px; font-weight: 500; color: var(--color-brand);
    text-decoration: none; white-space: nowrap;
    padding: 5px 12px; border: 1px solid var(--color-brand);
    border-radius: var(--r-sm); transition: background 80ms;
  }
  .docs-cta:hover { background: var(--color-brand-soft); }

  @media (max-width: 640px) {
    .docs-nav { padding: 0 16px; gap: 12px; }
    .docs-nav-links { display: none; }
  }

  /* ── Main ── */
  .docs-main { max-width: 820px; margin: 0 auto; padding: 0 40px 80px; }
  @media (max-width: 640px) { .docs-main { padding: 0 16px 60px; } }

  /* ── Hero ── */
  .docs-hero {
    padding: 64px 0 48px;
    border-bottom: 1px solid var(--color-border);
    margin-bottom: 56px;
  }
  .docs-hero-eyebrow {
    font-family: var(--font-mono); font-size: 11px; font-weight: 600;
    text-transform: uppercase; letter-spacing: 0.14em; color: var(--color-muted);
    margin-bottom: 12px;
  }
  .docs-hero-title {
    font-family: var(--font-display); font-size: 48px; font-weight: 400;
    letter-spacing: -0.025em; line-height: 1.05; color: var(--color-text-strong);
    margin: 0 0 16px;
  }
  :global(.docs-hero-title em) { font-style: italic; }
  .docs-hero-sub {
    font-size: 16px; line-height: 1.65; color: var(--color-text-2);
    max-width: 560px; margin: 0;
  }

  /* ── Sections ── */
  .docs-section { margin-bottom: 72px; }
  .docs-h2 {
    font-family: var(--font-display); font-size: 28px; font-weight: 400;
    letter-spacing: -0.015em; color: var(--color-text-strong);
    margin: 0 0 20px; padding-bottom: 12px;
    border-bottom: 1px solid var(--color-border);
  }
  .docs-section p {
    font-size: 14px; line-height: 1.7; color: var(--color-text-2); margin: 0 0 14px;
  }
  :global(.docs-section strong) { color: var(--color-text-strong); }
  :global(.docs-section em) { color: var(--color-text); }
  .docs-section ul {
    padding-left: 20px; margin: 8px 0 14px;
    font-size: 13.5px; line-height: 1.65; color: var(--color-text-2);
  }
  .docs-section li { margin-bottom: 4px; }
  :global(.docs-section code) {
    font-family: var(--font-mono); font-size: 12px;
    background: var(--color-surface-2); padding: 1px 5px; border-radius: 3px;
    color: var(--color-text);
  }

  /* ── Callout ── */
  .docs-callout {
    border-left: 3px solid; border-radius: 0 var(--r-md) var(--r-md) 0;
    padding: 12px 16px; margin: 20px 0;
    font-size: 13.5px; line-height: 1.6;
  }
  .docs-callout-info {
    border-color: var(--color-brand); background: var(--color-brand-soft);
    color: var(--color-text-2);
  }
  .docs-callout-warn {
    border-color: var(--color-warning); background: var(--color-warning-tint);
    color: var(--color-warning-ink);
  }
  :global(.docs-callout strong) { color: inherit; }

  /* ── Horizon cards ── */
  .docs-horizon-grid {
    display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-top: 24px;
  }
  @media (max-width: 640px) { .docs-horizon-grid { grid-template-columns: 1fr; } }

  .docs-horizon-card {
    border: 1px solid var(--color-border); border-radius: var(--r-lg);
    padding: 20px; background: var(--color-card);
    border-top: 3px solid;
  }
  .docs-horizon-day   { border-top-color: var(--color-day); }
  .docs-horizon-week  { border-top-color: var(--color-week); }
  .docs-horizon-month { border-top-color: var(--color-month); }
  .docs-horizon-year  { border-top-color: var(--color-year); }

  .docs-horizon-badge {
    font-family: var(--font-mono); font-size: 10px; font-weight: 700;
    text-transform: uppercase; letter-spacing: 0.1em;
    margin-bottom: 2px;
  }
  .docs-horizon-day   .docs-horizon-badge { color: var(--color-day); }
  .docs-horizon-week  .docs-horizon-badge { color: var(--color-week); }
  .docs-horizon-month .docs-horizon-badge { color: var(--color-month); }
  .docs-horizon-year  .docs-horizon-badge { color: var(--color-year); }

  .docs-horizon-period {
    font-family: var(--font-mono); font-size: 11px; color: var(--color-muted);
    margin-bottom: 10px;
  }
  .docs-horizon-desc { font-size: 13px; line-height: 1.6; color: var(--color-text-2); margin: 0 0 10px; }
  .docs-horizon-features {
    padding-left: 16px; margin: 0;
    font-size: 12.5px; line-height: 1.55; color: var(--color-muted);
  }
  .docs-horizon-features li { margin-bottom: 3px; }

  /* ── Flow ── */
  .docs-flow { display: flex; flex-direction: column; gap: 0; margin-top: 24px; }
  .docs-flow-step {
    display: flex; gap: 16px; align-items: flex-start;
    padding: 16px 20px; border: 1px solid var(--color-border);
    border-radius: var(--r-md); background: var(--color-card);
  }
  .docs-flow-step p { font-size: 13px; line-height: 1.6; color: var(--color-text-2); margin: 4px 0 0; }
  .docs-flow-step ul { font-size: 13px; color: var(--color-text-2); margin: 6px 0 0; }
  .docs-flow-step strong { font-size: 14px; color: var(--color-text-strong); font-weight: 600; }

  .docs-flow-icon {
    width: 28px; height: 28px; border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    font-size: 13px; font-weight: 700; flex-shrink: 0; margin-top: 1px;
  }
  .docs-flow-todo    { border-left: 3px solid var(--color-border-2); }
  .docs-flow-done    { border-left: 3px solid var(--color-success); }
  .docs-flow-overdue { border-left: 3px solid var(--color-warning); }
  .docs-flow-backlog { border-left: 3px solid var(--color-muted-2); }
  .docs-flow-archived { border-left: 3px solid var(--color-muted); }

  .docs-flow-todo    .docs-flow-icon { background: var(--color-surface); color: var(--color-muted); }
  .docs-flow-done    .docs-flow-icon { background: var(--color-week-tint); color: var(--color-success); }
  .docs-flow-overdue .docs-flow-icon { background: var(--color-warning-tint); color: var(--color-warning); }
  .docs-flow-backlog .docs-flow-icon { background: var(--color-surface-2); color: var(--color-muted); }
  .docs-flow-archived .docs-flow-icon { background: var(--color-surface); color: var(--color-muted-2); }

  .docs-flow-arrow {
    font-family: var(--font-mono); font-size: 11px; color: var(--color-muted-2);
    padding: 4px 20px; letter-spacing: 0.04em;
  }

  /* ── Table ── */
  .docs-table-wrap { overflow-x: auto; margin: 20px 0; }
  .docs-table {
    width: 100%; border-collapse: collapse;
    font-size: 13px; color: var(--color-text-2);
  }
  .docs-table th {
    text-align: left; padding: 8px 14px;
    font-family: var(--font-mono); font-size: 10.5px; font-weight: 600;
    text-transform: uppercase; letter-spacing: 0.08em; color: var(--color-muted);
    border-bottom: 2px solid var(--color-border);
  }
  .docs-table td {
    padding: 10px 14px; border-bottom: 1px solid var(--color-border);
    vertical-align: top; line-height: 1.5;
  }
  .docs-table tr:last-child td { border-bottom: none; }
  .docs-table tr:hover td { background: var(--color-surface); }

  .docs-level-badge {
    font-family: var(--font-mono); font-size: 10px; font-weight: 700;
    text-transform: uppercase; letter-spacing: 0.06em;
    padding: 2px 7px; border-radius: 3px; white-space: nowrap;
  }
  .docs-level-day   { background: var(--color-day-tint);   color: var(--color-day); }
  .docs-level-week  { background: var(--color-week-tint);  color: var(--color-week); }
  .docs-level-month { background: var(--color-month-tint); color: var(--color-month); }
  .docs-level-year  { background: var(--color-year-tint);  color: var(--color-year); }

  /* ── Views grid ── */
  .docs-views-grid { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 12px; margin-top: 20px; }
  @media (max-width: 640px) { .docs-views-grid { grid-template-columns: 1fr; } }

  .docs-view-card {
    padding: 16px; border: 1px solid var(--color-border);
    border-radius: var(--r-md); background: var(--color-card);
  }
  .docs-view-title {
    font-weight: 600; font-size: 13.5px; color: var(--color-text-strong);
    margin-bottom: 6px;
  }
  .docs-view-card p { font-size: 12.5px; line-height: 1.6; color: var(--color-text-2); margin: 0; }

  /* ── Planned features ── */
  .docs-planned-list { display: flex; flex-direction: column; gap: 12px; margin-top: 20px; }

  .docs-planned-item {
    border: 1px solid var(--color-border); border-radius: var(--r-md);
    padding: 18px 20px; background: var(--color-card);
  }
  .docs-planned-header {
    display: flex; align-items: center; gap: 10px; margin-bottom: 10px;
  }
  .docs-planned-tag {
    font-family: var(--font-mono); font-size: 9.5px; font-weight: 700;
    text-transform: uppercase; letter-spacing: 0.1em;
    padding: 2px 7px; border-radius: 3px;
    background: var(--color-surface-2); color: var(--color-muted);
  }
  .docs-planned-title {
    font-size: 14px; font-weight: 600; color: var(--color-text-strong);
  }
  .docs-planned-item p {
    font-size: 13px; line-height: 1.65; color: var(--color-text-2); margin: 0 0 8px;
  }
  .docs-planned-item ul {
    padding-left: 18px; margin: 0;
    font-size: 12.5px; line-height: 1.6; color: var(--color-muted);
  }
  .docs-planned-item li { margin-bottom: 3px; }

  /* ── Footer ── */
  .docs-footer {
    display: flex; align-items: center; justify-content: space-between;
    padding: 24px 0; border-top: 1px solid var(--color-border);
    font-size: 12.5px; color: var(--color-muted); margin-top: 24px;
  }
  .docs-footer a { color: var(--color-brand); text-decoration: none; }
  .docs-footer a:hover { text-decoration: underline; }
</style>
