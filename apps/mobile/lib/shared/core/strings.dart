import 'dart:ui';

/// Minimal ru/en string table, mirroring the web `i18n` store approach.
/// Notes scope only — the app-wide localization sweep is a separate task.
class S {
  static bool get _ru =>
      PlatformDispatcher.instance.locale.languageCode == 'ru';

  // Page
  static String get notes => _ru ? 'Заметки' : 'Notes';
  static String get notesLoadError => _ru ? 'Ошибка загрузки заметок' : 'Failed to load notes';
  static String get retry => _ru ? 'Повторить' : 'Retry';
  static String get noNotes => _ru ? 'Нет заметок' : 'No notes yet';
  static String get add => _ru ? 'Добавить' : 'Add';
  static String get untitled => _ru ? 'Без названия' : 'Untitled';
  static String get emptyNote => _ru ? 'Пустая заметка' : 'Empty note';
  static String get outline => _ru ? 'Список' : 'List';
  static String get board => _ru ? 'Доска' : 'Board';

  // Selection bar
  static String selected(int n) => _ru ? '$n выбрано' : '$n selected';
  static String get confirmQ => _ru ? 'Подтвердить?' : 'Confirm?';

  // Actions sheet
  static String get openAsPage => _ru ? 'Открыть как страницу' : 'Open as page';
  static String get addChild => _ru ? 'Добавить вложенную' : 'Add child';
  static String get addBelow => _ru ? 'Добавить ниже' : 'Add sibling below';
  static String get turnInto => _ru ? 'Превратить в' : 'Turn into';
  static String get setUrl => _ru ? 'Изменить URL' : 'Set URL';
  static String get indent => _ru ? 'Сдвинуть вправо' : 'Indent';
  static String get outdent => _ru ? 'Сдвинуть влево' : 'Outdent';
  static String get moveUp => _ru ? 'Переместить вверх' : 'Move up';
  static String get moveDown => _ru ? 'Переместить вниз' : 'Move down';
  static String get moveTo => _ru ? 'Переместить в…' : 'Move to…';
  static String get root => _ru ? 'Корень' : 'Root';
  static String get search => _ru ? 'Поиск' : 'Search';
  static String get duplicate => _ru ? 'Дублировать' : 'Duplicate';
  static String get tags => _ru ? 'Теги' : 'Tags';
  static String get clearFilter => _ru ? 'Сбросить фильтр' : 'Clear filter';
  static String get delete => _ru ? 'Удалить' : 'Delete';
  static String get undo => _ru ? 'Отменить' : 'Undo';
  static String get noteDeleted => _ru ? 'Заметка удалена' : 'Note deleted';
  static String get cancel => _ru ? 'Отмена' : 'Cancel';
  static String get save => _ru ? 'Сохранить' : 'Save';
  static String get deleteNoteQ => _ru ? 'Удалить заметку?' : 'Delete note?';
  static String deleteSubtree(int n) =>
      _ru ? 'Будут удалены заметка и вложенные: $n шт.' : 'The note and $n nested notes will be deleted.';

  // Node types
  static String get typeText => _ru ? 'Текст' : 'Text';
  static String get typeHeading1 => _ru ? 'Заголовок 1' : 'Heading 1';
  static String get typeHeading2 => _ru ? 'Заголовок 2' : 'Heading 2';
  static String get typeBullet => _ru ? 'Пункт' : 'Bullet';
  static String get typeTodo => _ru ? 'Задача' : 'To-do';
  static String get typeImage => _ru ? 'Изображение' : 'Image';
  static String get typeLink => _ru ? 'Ссылка' : 'Link';

  // Board
  static String get addCard => _ru ? 'Карточка' : 'Add card';
  static String get addColumn => _ru ? 'Колонка' : 'Add column';
  static String get emptyCard => _ru ? 'Пусто' : 'Empty';
  static String nested(int n) => _ru ? 'вложенных: $n' : '$n nested';

  // Task archive outcome chip — mirrors web `outcome.*` dict keys
  static String get outcomeOnTime => _ru ? 'Выполнено вовремя' : 'Done on time';
  static String get outcomeLate => _ru ? 'Выполнено с опозданием' : 'Done late';
  static String get outcomeFailed => _ru ? 'Не выполнено' : 'Failed';

  // Task card date/period formatting — mirrors web `TaskCard.svelte`'s
  // `weekdayShort`/`monthShort` (index 0 = Sunday, 1-12 = Jan-Dec, index 0 unused).
  static const _weekdayShortRu = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
  static const _weekdayShortEn = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static String weekdayShort(int weekday0Sun) =>
      (_ru ? _weekdayShortRu : _weekdayShortEn)[weekday0Sun];

  static const _monthShortRu = [
    '', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
    'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
  ];
  static const _monthShortEn = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static String monthShort(int month1to12) =>
      (_ru ? _monthShortRu : _monthShortEn)[month1to12];

  static const _monthFullRu = [
    '', 'январь', 'февраль', 'март', 'апрель', 'май', 'июнь',
    'июль', 'август', 'сентябрь', 'октябрь', 'ноябрь', 'декабрь',
  ];
  static const _monthFullEn = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static String monthFull(int month1to12) =>
      (_ru ? _monthFullRu : _monthFullEn)[month1to12];

  // Recurring "on the Nth" (month-level) — mirrors web's `${dayOfMonth}-го` / `day ${n}`.
  static String dayOfMonthOrdinal(int day) => _ru ? '$day-го' : 'day $day';

  // Year-level deadline chip — mirrors web's `task.until`.
  static String until(String month) => _ru ? 'до $month' : 'until $month';

  static String get overdue => _ru ? 'просрочено' : 'overdue';
  static String get subtasks => _ru ? 'Подзадачи' : 'Subtasks';
  static String get subtaskUpdateFailed => _ru ? 'Не удалось обновить подзадачу' : 'Failed to update subtask';
  static String get subtaskAddFailed => _ru ? 'Не удалось добавить подзадачу' : 'Failed to add subtask';
  static String get addSubtask => _ru ? '+ добавить подзадачу' : '+ add subtask';
  static String get addSubtaskHint => _ru ? 'Добавить подзадачу...' : 'Add subtask...';

  // Bottom nav labels — mirrors web's `nav.*` i18n keys.
  static String get navView => _ru ? 'Просмотр' : 'View';
  static String get navStats => _ru ? 'Статистика' : 'Stats';
  static String get navSettings => _ru ? 'Настройки' : 'Settings';

  // Drawer nav — mirrors web `nav.*`/`Sidebar.svelte` wording.
  static String get navToday => _ru ? 'Сегодня' : 'Today';
  static String get navWeek => _ru ? 'Неделя' : 'Week';
  static String get navMonth => _ru ? 'Месяц' : 'Month';
  static String get navYear => _ru ? 'Год' : 'Year';
  static String get navBacklog => _ru ? 'Бэклог' : 'Backlog';
  static String get navArchive => _ru ? 'Архив' : 'Archive';
  static String get sectionHorizons => _ru ? 'ГОРИЗОНТЫ' : 'HORIZONS';
  static String get sectionRecords => _ru ? 'ЗАПИСИ' : 'RECORDS';
  static String get themeLight => _ru ? 'Светлая' : 'Light';
  static String get themeDark => _ru ? 'Тёмная' : 'Dark';

  // Outbox sync banner — ru needs genitive plural forms, en doesn't.
  static String syncPending(int count) {
    if (!_ru) return '$count change${count == 1 ? '' : 's'} pending sync';
    final word = count == 1 ? 'изменение ожидает' : 'изменений ожидают';
    return '$count $word синхронизации';
  }

  static String syncFailed(int count) {
    if (!_ru) return '$count change${count == 1 ? '' : 's'} not synced, retrying...';
    final word = count == 1 ? 'изменение' : 'изменений';
    return '$count $word не синхронизировано, повтор...';
  }

  // Backlog age chip ("3 days ago").
  static String get backlogToday => _ru ? 'сегодня' : 'today';
  static String backlogAge(int days) {
    if (_ru) {
      if (days == 1) return 'день назад';
      if (days < 30) return '$days дней назад';
      final months = (days / 30).floor();
      return '$months мес. назад';
    }
    if (days == 1) return '1 day ago';
    if (days < 30) return '$days days ago';
    final months = (days / 30).floor();
    return '$months mo. ago';
  }

  // Notes notifier mutation-failure toasts.
  static String get noteCreateFailed => _ru ? 'Не удалось создать заметку' : 'Failed to create note';
  static String get noteDuplicateFailed => _ru ? 'Не удалось дублировать заметку' : 'Failed to duplicate note';
  static String get noteDeleteFailed => _ru ? 'Не удалось удалить заметку' : 'Failed to delete note';
  static String get noteTagsSaveFailed => _ru ? 'Не удалось сохранить теги заметки' : 'Failed to save note tags';

  // Task notifier mutation-failure toasts.
  static String get taskCreateFailed => _ru ? 'Не удалось создать задачу' : 'Failed to create task';
  static String get taskSaveFailed => _ru ? 'Не удалось сохранить задачу' : 'Failed to save task';
  static String get taskDeleteArchivedError =>
      _ru ? 'Нельзя удалить: задача имеет архивные периоды' : "Can't delete: task has archived periods";
  static String get taskDeleteFailed => _ru ? 'Не удалось удалить задачу' : 'Failed to delete task';
  static String get taskTagsSaveFailed => _ru ? 'Не удалось сохранить теги задачи' : 'Failed to save task tags';

  // Tag filter bar / tag settings management.
  static String get reset => _ru ? 'Сбросить' : 'Reset';
  static String get tagCreateFailed => _ru ? 'Не удалось создать тег' : 'Failed to create tag';
  static String get tagDeleteFailed => _ru ? 'Не удалось удалить тег' : 'Failed to delete tag';

  // Task level badge (short uppercase chip on cards).
  static String get levelDayShort => _ru ? 'ДЕНЬ' : 'DAY';
  static String get levelWeekShort => _ru ? 'НЕД' : 'WK';
  static String get levelMonthShort => _ru ? 'МЕС' : 'MO';
  static String get levelYearShort => _ru ? 'ГОД' : 'YR';

  // Auth: profile / app title / login / register — mirrors web copy.
  static String get profileUpdateFailed => _ru ? 'Не удалось обновить профиль' : 'Failed to update profile';
  static String get appTitle => _ru ? 'Цикл' : 'Cycle';
  static String get welcomeBack => _ru ? 'С возвращением.' : 'Welcome back.';
  static String get loginToContinue => _ru ? 'Войдите, чтобы продолжить.' : 'Log in to continue.';
  static String get password => _ru ? 'Пароль' : 'Password';
  static String get login => _ru ? 'Войти' : 'Log in';
  static String get noAccountQ => _ru ? 'Нет аккаунта? ' : "Don't have an account? ";
  static String get register => _ru ? 'Зарегистрироваться' : 'Sign up';
  static String get taglineLine1 =>
      _ru ? 'Дисциплина — это не наказание.\nЭто тихая привилегия\n' : 'Discipline is not punishment.\nIt is a quiet privilege\n';
  static String get taglineLine2 => _ru ? 'выбирать то, что ты оставишь.' : 'to choose what you keep.';
  static String get copyrightTagline =>
      _ru ? '© 2026 — ИНСТРУМЕНТ САМОДИСЦИПЛИНЫ' : '© 2026 — A SELF-DISCIPLINE TOOL';
  static String get createAccount => _ru ? 'Создать аккаунт.' : 'Create an account.';
  static String get startDisciplinePath => _ru ? 'Начните путь к дисциплине.' : 'Start your path to discipline.';
  static String get name => _ru ? 'Имя' : 'Name';
  static String get yourNameHint => _ru ? 'Ваше имя' : 'Your name';
  static String get minPasswordHint => _ru ? 'Минимум 8 символов' : 'At least 8 characters';
  static String get alreadyHaveAccountQ => _ru ? 'Уже есть аккаунт? ' : 'Already have an account? ';

  // Auth error message mapping — mirrors `formatAuthError`'s status-code table.
  static String get errorInvalidCreds => _ru ? 'Неверный email или пароль' : 'Invalid email or password';
  static String get errorUserExists =>
      _ru ? 'Пользователь с таким email уже существует' : 'A user with this email already exists';
  static String get errorValidation =>
      _ru ? 'Проверьте правильность введённых данных' : 'Please check the data you entered';
  static String get errorNoConnection => _ru ? 'Нет соединения с сервером' : 'No connection to the server';
  static String get errorGeneric =>
      _ru ? 'Что-то пошло не так. Попробуйте ещё раз' : 'Something went wrong. Please try again';

  // Task form sheet: replan dialog + subtask mutation toasts.
  static String get replanQ => _ru ? 'Перепланировать?' : 'Replan?';
  static String replanBody(String periodStart) => _ru
      ? 'Задача будет перенесена в текущий период ($periodStart).'
      : 'The task will be moved to the current period ($periodStart).';
  static String get replanFailed => _ru ? 'Не удалось перепланировать задачу' : 'Failed to replan task';
  static String get move => _ru ? 'Перенести' : 'Move';
  static String get subtaskSaveFailed => _ru ? 'Не удалось сохранить подзадачу' : 'Failed to save subtask';
  static String get subtaskDeleteFailed => _ru ? 'Не удалось удалить подзадачу' : 'Failed to delete subtask';

  // Settings / stats page generic copy.
  static String get loadError => _ru ? 'Ошибка загрузки' : 'Failed to load';
  static String get recurringTasksHeading => _ru ? 'Повторяющиеся задачи' : 'Recurring tasks';
  static String get overviewSection => _ru ? 'ОБЗОР' : 'OVERVIEW';
  static String get statsHeading => _ru ? 'Статистика.' : 'Stats.';
  static String get consistencyHabits => _ru ? 'Постоянство (привычки)' : 'Consistency (habits)';
  static String get byWeeks => _ru ? 'По неделям' : 'By week';
  static String get byMonths => _ru ? 'По месяцам' : 'By month';
  static String get byYears => _ru ? 'По годам' : 'By year';
  static String overdueAbbr(int n) => _ru ? '$n просроч.' : '$n overdue';
  static String get now => _ru ? 'сейчас' : 'now';

  // Tasks/view-tab pages: titles, empty states, context section headings.
  static String get dayLabel => _ru ? 'День' : 'Day';
  static String get weekTasksTitle => _ru ? 'Задачи недели' : 'Week tasks';
  static String get monthTasksTitle => _ru ? 'Задачи месяца' : 'Month tasks';
  static String get yearTasksTitle => _ru ? 'Задачи года' : 'Year tasks';
  static String get weekGoalsContext => _ru ? 'Цели недели · контекст' : 'Week goals · context';
  static String get monthGoalsContext => _ru ? 'Цели месяца · контекст' : 'Month goals · context';
  static String get yearGoalsContext => _ru ? 'Цели года · контекст' : 'Year goals · context';
  static String get monthTasksContext => _ru ? 'Задачи месяца · контекст' : 'Month tasks · context';
  static String get yearTasksContext => _ru ? 'Задачи года · контекст' : 'Year tasks · context';

  // Recurring "day of month" indicator on the mini task card (e.g. "↻ 5-го" / "↻ on the 5th").
  static String recurDayOfMonth(int day) {
    if (_ru) return '$day-го';
    final suffix = (day % 10 == 1 && day % 100 != 11)
        ? 'st'
        : (day % 10 == 2 && day % 100 != 12)
            ? 'nd'
            : (day % 10 == 3 && day % 100 != 13)
                ? 'rd'
                : 'th';
    return 'on the $day$suffix';
  }
  static String errorPrefix(Object err) => _ru ? 'Ошибка: $err' : 'Error: $err';
  static String get noTasks => _ru ? 'Нет задач' : 'No tasks';
  static String get noTasksFiltered => _ru ? 'Нет задач по фильтру' : 'No tasks match the filter';
  static String get clearFilterTasks => _ru ? 'Очистить фильтр' : 'Clear filter';
  static String get addTaskToday => _ru ? '+ Добавить задачу на сегодня' : '+ Add task for today';
  static String get addTask => _ru ? 'Добавить задачу' : 'Add task';
  static String get doneUppercase => _ru ? 'ВЫПОЛНЕНО' : 'DONE';
  static String get penaltiesUppercase => _ru ? 'ШТРАФЫ' : 'PENALTIES';
  static String get horizonWeekLabel => _ru ? 'ГОРИЗОНТ · НЕДЕЛЯ' : 'HORIZON · WEEK';
  static String get horizonMonthLabel => _ru ? 'ГОРИЗОНТ · МЕСЯЦ' : 'HORIZON · MONTH';
  static String get horizonYearLabel => _ru ? 'ГОРИЗОНТ · ГОД' : 'HORIZON · YEAR';
  static String get weekDot => _ru ? 'Неделя.' : 'Week.';
  static String get monthDot => _ru ? 'Месяц.' : 'Month.';
  static String get yearDot => _ru ? 'Год.' : 'Year.';
  static String get byDays => _ru ? 'По дням' : 'By day';
  static String get todayComma => _ru ? 'Сегодня, ' : 'Today, ';

  // Mon-first short weekday names for the week-kanban column headers —
  // distinct from `weekdayShort` above, which is Sun-first (index 0 = Sunday).
  static const _weekdayShortMonRu = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  static const _weekdayShortMonEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static String weekdayShortMon(int weekday0Mon) =>
      (_ru ? _weekdayShortMonRu : _weekdayShortMonEn)[weekday0Mon];

  // Full weekday names (index 1 = Monday .. 7 = Sunday, matching
  // `DateTime.weekday`) and genitive-case month names, used by the
  // "today" header eyebrow ("Monday · 27 July 2026 · Week 30").
  static const _weekdayFullRu = [
    '', 'Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье',
  ];
  static const _weekdayFullEn = [
    '', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  static String weekdayFull(int weekday1Mon) => (_ru ? _weekdayFullRu : _weekdayFullEn)[weekday1Mon];

  static const _monthGenitiveRu = [
    '', 'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];
  static String monthGenitive(int month1to12) => _ru ? _monthGenitiveRu[month1to12] : _monthFullEn[month1to12];

  static String todayEyebrow(int weekday1Mon, int day, int month1to12, int year, int weekNum) {
    if (_ru) {
      return '${weekdayFull(weekday1Mon)} · $day ${monthGenitive(month1to12)} $year г. · Неделя $weekNum';
    }
    return '${weekdayFull(weekday1Mon)} · ${monthFull(month1to12)} $day, $year · Week $weekNum';
  }
}
