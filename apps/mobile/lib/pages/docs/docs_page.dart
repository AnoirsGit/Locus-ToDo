import 'package:flutter/material.dart';
import '../../pages/app_shell.dart';
import '../../shared/theme/theme.dart';

class DocsPage extends StatelessWidget {
  const DocsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 120,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Locus', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, fontFamily: 'Inter', color: context.colorTextStrong)),
              const SizedBox(width: 5),
              Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: context.colorBrand)),
            ],
          ),
        ),
        title: Text('Документация', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: context.colorText)),
        actions: [
          IconButton(icon: const Icon(Icons.menu), onPressed: AppShell.openDrawer),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
        children: [
          // ── Hero ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ДОКУМЕНТАЦИЯ',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.1, color: context.colorMuted),
                ),
                const SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Как работает ',
                        style: TextStyle(fontSize: 28, fontFamily: 'Georgia', fontStyle: FontStyle.italic, fontWeight: FontWeight.w400, color: context.colorTextStrong, letterSpacing: -0.5),
                      ),
                      TextSpan(
                        text: 'Locus',
                        style: TextStyle(fontSize: 28, fontFamily: 'Georgia', fontStyle: FontStyle.italic, fontWeight: FontWeight.w400, color: context.colorBrand, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Полная документация по логике задач, статусам и планировщику.',
                  style: TextStyle(fontSize: 14, color: context.colorText2, height: 1.6),
                ),
              ],
            ),
          ),
          Divider(color: context.colorBorder),

          // ── Overview ──────────────────────────────────────────────────
          _Section(
            title: 'Обзор',
            children: [
              _Para(context, 'Locus организует работу вокруг четырёх временных горизонтов: год, месяц, неделя и день. Каждая задача принадлежит ровно одному горизонту — он называется уровнем. Уровень определяет длительность активного периода и когда планировщик её обработает.'),
              _Para(context, 'Главная идея: амбициозные цели сверху (год), разбитые на месячные вехи, еженедельные результаты и ежедневные действия снизу. Вид «Сегодня» показывает все четыре горизонта сразу, чтобы всегда видеть полный контекст.'),
              _Callout(
                context,
                'Ключевой принцип: задачи не удаляются при провале — они архивируются с записью результата. Это даёт честную долгосрочную статистику.',
                isWarning: false,
              ),
            ],
          ),

          // ── Horizons ──────────────────────────────────────────────────
          _Section(
            title: 'Временные горизонты',
            children: [
              _HorizonCard(
                context: context,
                level: _HLevel.day,
                period: 'Период: 1 день',
                desc: 'Задачи на конкретный день. Отображаются в виде «Сегодня» и в дневной колонке вида «Неделя». Можно указать время. Пропущенные задачи дня архивируются напрямую без фазы просрочки.',
                features: ['Необязательное запланированное время', 'Видны в «Сегодня» и «Неделя»', 'Могут повторяться ежедневно'],
              ),
              const SizedBox(height: 10),
              _HorizonCard(
                context: context,
                level: _HLevel.week,
                period: 'Период: пн → вс',
                desc: 'Задачи на неделю. Неделя всегда начинается в понедельник. Пропущенные задачи получают 7-дневное окно просрочки.',
                features: ['Необязательный целевой день (пн–вс)', 'Необязательное время', 'Могут повторяться еженедельно'],
              ),
              const SizedBox(height: 10),
              _HorizonCard(
                context: context,
                level: _HLevel.month,
                period: 'Период: 1-е → последнее число',
                desc: 'Месячные цели. Отображаются в виде «Месяц» и как контекст в «Сегодня». Пропущенные задачи получают 30-дневное окно просрочки.',
                features: ['Без времени или целевой даты', 'Могут повторяться ежемесячно'],
              ),
              const SizedBox(height: 10),
              _HorizonCard(
                context: context,
                level: _HLevel.year,
                period: 'Период: 1 янв → 31 дек',
                desc: 'Годовые цели. Можно указать дедлайн-месяц — мягкий ориентир внутри года.',
                features: ['Необязательный месяц дедлайна', 'Могут повторяться ежегодно'],
              ),
            ],
          ),

          // ── Lifecycle ─────────────────────────────────────────────────
          _Section(
            title: 'Жизненный цикл задачи',
            children: [
              _Para(context, 'У каждой задачи есть период — запись в БД, отслеживающая статус в конкретном временном окне. Планировщик запускается периодически и автоматически продвигает статусы.'),
              const SizedBox(height: 8),
              _FlowStep(context, icon: '●', color: null, borderColor: null, title: 'Todo', desc: 'Активна, ещё не выполнена. Чекбокс не отмечен. Можно свободно переключать.'),
              _FlowArrow(context, '↓'),
              _FlowStep(context, icon: '✓', colorKey: 'success', title: 'Done', desc: 'Чекбокс отмечен в течение периода. По окончании планировщик архивирует как вовремя. Снятие отметки возвращает в todo.'),
              _FlowArrow(context, '↓ если период закончился невыполненным'),
              _FlowStep(context, icon: '!', colorKey: 'warning', title: 'Overdue (просрочено)', desc: 'Период закончился, задача не выполнена. Создаётся штрафной период той же длительности. Можно ещё выполнить — тогда заархивируется как с опозданием.'),
              _FlowArrow(context, '↓ если штрафной период тоже истёк'),
              _FlowStep(context, icon: '⋯', colorKey: 'muted', title: 'Backlog', desc: 'Задача не выполнена и в штрафном периоде. Живёт в бэклоге без активного периода. Отсюда можно Перепланировать — выбрать новый период. Старый архивируется как провал.'),
              _FlowArrow(context, '↓ по окончании периода'),
              _FlowStep(context, icon: '▣', colorKey: 'muted2', title: 'Archived', desc: 'Финальный статус. Результат выводится из done_at:', extras: ['Вовремя — выполнено в рамках исходного периода', 'С опозданием — выполнено в штрафной период', 'Провал — done_at = null, никогда не выполнено']),
              const SizedBox(height: 8),
              _Callout(context, 'Правило удаления: задача может быть жёстко удалена только если у неё нет архивных периодов.', isWarning: true),
            ],
          ),

          // ── Recurring ─────────────────────────────────────────────────
          _Section(
            title: 'Повторяющиеся задачи',
            children: [
              _Para(context, 'Включите Повторяющуюся при создании или редактировании задачи. Планировщик обрабатывает их автоматически, не перемещая через просрочку/бэклог.'),
              const SizedBox(height: 12),
              _RecurringTable(context),
              const SizedBox(height: 8),
              _Para(context, 'Повторяющиеся задачи отслеживаются в статистике как Постоянство % (как часто выполнялись), тогда как разовые задачи показывают Выполнение %.'),
            ],
          ),

          // ── Views ─────────────────────────────────────────────────────
          _Section(
            title: 'Виды',
            children: [
              _ViewCard(context, title: 'Сегодня', desc: 'Центр управления. Дневные задачи на сегодня плюс задачи недели / месяца / года как контекст.'),
              _ViewCard(context, title: 'Неделя', desc: '7 колонок (пн–вс). Дневные задачи в своей колонке. Задачи недели показаны ниже.'),
              _ViewCard(context, title: 'Месяц', desc: 'Все активные задачи месячного уровня.'),
              _ViewCard(context, title: 'Год', desc: 'Все активные годовые задачи. Показывает чип с месяцем дедлайна.'),
              _ViewCard(context, title: 'Бэклог', desc: 'Задачи, пропустившие штрафной период. Используйте «Перепланировать» для нового периода.'),
              _ViewCard(context, title: 'Архив', desc: 'Только для чтения. История всех завершённых / проваленных периодов.'),
            ],
          ),

          // ── Planned ───────────────────────────────────────────────────
          _Section(
            title: 'Планируется',
            children: [
              _Para(context, 'Подтверждённые пункты дорожной карты — ещё не готовы.'),
              const SizedBox(height: 8),
              _PlannedItem(context, tag: 'Мобильное', title: 'Офлайн-режим + умная синхронизация', desc: 'Мобильное приложение будет хранить все задачи локально (SQLite через Drift), работая без интернета. Записи идут в локальную БД мгновенно, затем ставятся в очередь для фоновой синхронизации. При конфликте побеждает сервер.', bullets: ['Мгновенная реакция UI — никаких спиннеров', 'Очередь переживает перезапуск приложения', 'Фоновое слияние при подключении']),
              _PlannedItem(context, tag: 'Мобильное', title: 'Уведомления перед дедлайном', desc: 'Для задач с запланированным временем локальное уведомление срабатывает за X минут (по умолчанию 30). Отменяется автоматически при отметке выполнено.', bullets: ['Только для задач с scheduled_time', 'Отменяется при отметке', 'Настраиваемое время опережения']),
              _PlannedItem(context, tag: 'Мобильное', title: 'Вечернее сводное уведомление', desc: 'Ежедневное уведомление в настраиваемое время (по умолчанию 20:00) показывает количество незавершённых задач на сегодня. Пропускается, если всё выполнено.', bullets: ['Настраиваемое время (по умолчанию 20:00)', 'Считает todo + overdue задачи дня', 'Тихий режим, если ничего не осталось']),
              _PlannedItem(context, tag: 'Все платформы', title: 'Подзадачи', desc: 'Задачи могут содержать подзадачи — чеклист мелких шагов. Подзадачи не имеют независимого статуса и не обрабатываются планировщиком — они наследуют период родителя.', bullets: []),
              _PlannedItem(context, tag: 'Все платформы', title: 'Повторяющиеся: несколько дней в неделю', desc: 'Повторяющиеся недельные задачи будут поддерживать выбор нескольких дней (напр., пн + ср + пт), до 6. Сейчас ограничено одним днём.', bullets: []),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section ───────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Georgia',
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              color: context.colorTextStrong,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Divider(color: context.colorBorder),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

// ── Paragraph ─────────────────────────────────────────────────────────────────

Widget _Para(BuildContext context, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: TextStyle(fontSize: 14, color: context.colorText2, height: 1.65)),
    );

// ── Callout ───────────────────────────────────────────────────────────────────

class _Callout extends StatelessWidget {
  final BuildContext ctx;
  final String text;
  final bool isWarning;
  const _Callout(this.ctx, this.text, {required this.isWarning});

  @override
  Widget build(BuildContext context) {
    final color = isWarning ? ctx.colorWarning : ctx.colorBrand;
    final bg    = isWarning ? ctx.colorWarningTint : ctx.colorBrandSoft;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Text(text, style: TextStyle(fontSize: 13.5, color: ctx.colorText2, height: 1.6)),
    );
  }
}

// ── Horizon level enum (local) ─────────────────────────────────────────────────

enum _HLevel { day, week, month, year }

// ── Horizon card ──────────────────────────────────────────────────────────────

class _HorizonCard extends StatelessWidget {
  final BuildContext context;
  final _HLevel level;
  final String period;
  final String desc;
  final List<String> features;

  const _HorizonCard({
    required this.context, required this.level,
    required this.period, required this.desc, required this.features,
  });

  Color get _color => switch (level) {
    _HLevel.day   => context.colorDay,
    _HLevel.week  => context.colorWeek,
    _HLevel.month => context.colorMonth,
    _HLevel.year  => context.colorYear,
  };

  String get _label => switch (level) {
    _HLevel.day   => 'DAY',
    _HLevel.week  => 'WEEK',
    _HLevel.month => 'MONTH',
    _HLevel.year  => 'YEAR',
  };

  @override
  Widget build(BuildContext ctx) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.colorBorder),
        // Top accent matches web's border-top: 3px solid
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withAlpha(80)),
                ),
                child: Text(_label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.8, fontFamily: 'monospace')),
              ),
              const SizedBox(width: 10),
              Text(period, style: TextStyle(fontSize: 11, color: context.colorMuted, fontFamily: 'monospace')),
            ],
          ),
          const SizedBox(height: 10),
          Text(desc, style: TextStyle(fontSize: 13, color: context.colorText2, height: 1.6)),
          const SizedBox(height: 8),
          for (final f in features) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('· ', style: TextStyle(fontSize: 12, color: context.colorMuted)),
                Expanded(child: Text(f, style: TextStyle(fontSize: 12, color: context.colorMuted, height: 1.5))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Flow step ─────────────────────────────────────────────────────────────────

class _FlowStep extends StatelessWidget {
  final BuildContext ctx;
  final String icon;
  final String? colorKey;
  final Color? color;
  final Color? borderColor;
  final String title;
  final String desc;
  final List<String> extras;

  const _FlowStep(
    this.ctx, {
    required this.icon,
    this.colorKey,
    this.color,
    this.borderColor,
    required this.title,
    required this.desc,
    this.extras = const [],
  });

  Color _resolveColor() {
    if (color != null) return color!;
    return switch (colorKey) {
      'success' => ctx.colorSuccess,
      'warning' => ctx.colorWarning,
      'muted'   => ctx.colorMuted,
      'muted2'  => ctx.colorMuted2,
      _         => ctx.colorBorder2,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = _resolveColor();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ctx.colorCard,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: c, width: 3),
          top: BorderSide(color: ctx.colorBorder),
          right: BorderSide(color: ctx.colorBorder),
          bottom: BorderSide(color: ctx.colorBorder),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26, height: 26,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: c.withAlpha(30),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(icon, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ctx.colorTextStrong)),
                const SizedBox(height: 3),
                Text(desc, style: TextStyle(fontSize: 13, color: ctx.colorText2, height: 1.55)),
                for (final e in extras) ...[
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('· ', style: TextStyle(fontSize: 12, color: ctx.colorMuted)),
                      Expanded(child: Text(e, style: TextStyle(fontSize: 12, color: ctx.colorText2, height: 1.5))),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _FlowArrow(BuildContext context, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: Text(text, style: TextStyle(fontSize: 11, color: context.colorMuted2, fontFamily: 'monospace')),
    );

// ── Recurring table ───────────────────────────────────────────────────────────

class _RecurringTable extends StatelessWidget {
  final BuildContext ctx;
  const _RecurringTable(this.ctx);

  static const _rows = [
    ['День',  'Без дополнительных настроек',    'Текущий период архивируется; создаётся новый todo на завтра'],
    ['Неделя','День недели (по умолчанию: пн)',  'Текущий период архивируется; новый todo создаётся на следующую неделю'],
    ['Месяц', 'День месяца (напр., 1-е)',        'Текущий период архивируется; новый todo создаётся на следующий месяц'],
    ['Год',   '—',                               'Текущий период архивируется; новый todo создаётся на следующий год'],
  ];

  static const _levelColors = [AppColors.dayDark, AppColors.weekDark, AppColors.monthDark, AppColors.yearDark];
  static const _levelColorsLight = [AppColors.dayLight, AppColors.weekLight, AppColors.monthLight, AppColors.yearLight];

  @override
  Widget build(BuildContext context) {
    final colors = ctx.isDark ? _levelColors : _levelColorsLight;
    return Container(
      decoration: BoxDecoration(
        color: ctx.colorCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ctx.colorBorder),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: ctx.colorSurface2,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                SizedBox(width: 60, child: Text('УРОВЕНЬ', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: ctx.colorMuted))),
                SizedBox(width: 100, child: Text('НАСТРОЙКА', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: ctx.colorMuted))),
                Expanded(child: Text('ЧТО ПРОИСХОДИТ', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: ctx.colorMuted))),
              ],
            ),
          ),
          for (int i = 0; i < _rows.length; i++) ...[
            if (i > 0) Divider(color: ctx.colorBorder, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 60,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors[i].withAlpha(25),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: colors[i].withAlpha(80)),
                      ),
                      child: Text(_rows[i][0], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colors[i])),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(_rows[i][1], style: TextStyle(fontSize: 12, color: ctx.colorMuted, height: 1.5)),
                  ),
                  Expanded(
                    child: Text(_rows[i][2], style: TextStyle(fontSize: 12, color: ctx.colorText2, height: 1.5)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── View card ─────────────────────────────────────────────────────────────────

Widget _ViewCard(BuildContext context, {required String title, required String desc}) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colorBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: context.colorTextStrong)),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(fontSize: 12.5, color: context.colorText2, height: 1.6)),
        ],
      ),
    );

// ── Planned item ──────────────────────────────────────────────────────────────

Widget _PlannedItem(BuildContext context, {required String tag, required String title, required String desc, required List<String> bullets}) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colorBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: context.colorSurface2, borderRadius: BorderRadius.circular(4)),
                child: Text(tag, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: context.colorMuted, letterSpacing: 0.8, fontFamily: 'monospace')),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colorTextStrong))),
            ],
          ),
          const SizedBox(height: 8),
          Text(desc, style: TextStyle(fontSize: 13, color: context.colorText2, height: 1.6)),
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final b in bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('· ', style: TextStyle(fontSize: 12, color: context.colorMuted)),
                    Expanded(child: Text(b, style: TextStyle(fontSize: 12, color: context.colorMuted, height: 1.5))),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
