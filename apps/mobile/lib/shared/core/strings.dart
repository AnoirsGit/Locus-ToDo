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
}
