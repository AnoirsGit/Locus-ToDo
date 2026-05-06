enum TaskLevel {
  day,
  week,
  month,
  year;

  static TaskLevel fromString(String value) {
    return TaskLevel.values.firstWhere((e) => e.name == value);
  }
}

enum TaskStatus {
  todo,
  done,
  overdue,
  backlog,
  archived;

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere((e) => e.name == value);
  }
}

class RecurringConfig {
  final String id;
  final String taskId;
  final int? dayOfWeek;
  final int? dayOfMonth;
  final bool isActive;
  final DateTime createdAt;

  RecurringConfig({
    required this.id,
    required this.taskId,
    this.dayOfWeek,
    this.dayOfMonth,
    required this.isActive,
    required this.createdAt,
  });

  factory RecurringConfig.fromJson(Map<String, dynamic> json) {
    return RecurringConfig(
      id: json['id'],
      taskId: json['taskId'],
      dayOfWeek: json['dayOfWeek'],
      dayOfMonth: json['dayOfMonth'],
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class Task {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final TaskLevel level;
  final String? scheduledTime;
  final RecurringConfig? recurringConfig;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.level,
    this.scheduledTime,
    this.recurringConfig,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      description: json['description'],
      level: TaskLevel.fromString(json['level']),
      scheduledTime: json['scheduledTime'],
      recurringConfig: json['recurringConfig'] != null
          ? RecurringConfig.fromJson(json['recurringConfig'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class TaskPeriod {
  final String id;
  final String taskId;
  final String userId;
  final TaskLevel periodType;
  final DateTime periodStart;
  final DateTime periodEnd;
  final TaskStatus status;
  final String? targetDate;
  final int? deadlineMonth;
  final int sortOrder;
  final DateTime? doneAt;
  final DateTime? backlogAt;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskPeriod({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.periodType,
    required this.periodStart,
    required this.periodEnd,
    required this.status,
    this.targetDate,
    this.deadlineMonth,
    required this.sortOrder,
    this.doneAt,
    this.backlogAt,
    this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskPeriod.fromJson(Map<String, dynamic> json) {
    return TaskPeriod(
      id: json['id'],
      taskId: json['taskId'],
      userId: json['userId'],
      periodType: TaskLevel.fromString(json['periodType']),
      periodStart: DateTime.parse(json['periodStart']),
      periodEnd: DateTime.parse(json['periodEnd']),
      status: TaskStatus.fromString(json['status']),
      targetDate: json['targetDate'],
      deadlineMonth: json['deadlineMonth'],
      sortOrder: json['sortOrder'] ?? 0,
      doneAt: json['doneAt'] != null ? DateTime.parse(json['doneAt']) : null,
      backlogAt:
          json['backlogAt'] != null ? DateTime.parse(json['backlogAt']) : null,
      archivedAt:
          json['archivedAt'] != null ? DateTime.parse(json['archivedAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class TaskWithPeriod extends Task {
  final TaskPeriod period;

  TaskWithPeriod({
    required super.id,
    required super.userId,
    required super.title,
    super.description,
    required super.level,
    super.scheduledTime,
    super.recurringConfig,
    required super.createdAt,
    required super.updatedAt,
    required this.period,
  });

  factory TaskWithPeriod.fromJson(Map<String, dynamic> json) {
    return TaskWithPeriod(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      description: json['description'],
      level: TaskLevel.fromString(json['level']),
      scheduledTime: json['scheduledTime'],
      recurringConfig: json['recurringConfig'] != null
          ? RecurringConfig.fromJson(json['recurringConfig'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      period: TaskPeriod.fromJson(json['period']),
    );
  }
}
