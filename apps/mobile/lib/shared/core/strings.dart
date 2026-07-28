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
}
