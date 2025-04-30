class Habit {
  final int id;
  final String name;
  final bool isCompleted;
  final String date;
  final String? notificationTime;

  Habit({
    required this.id,
    required this.name,
    required this.isCompleted,
    required this.date,
    this.notificationTime,
  });

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as int,
      name: map['name'] as String,
      isCompleted: (map['completed'] as int) == 1,
      date: map['date'] as String,
      notificationTime: map['notification_time'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'completed': isCompleted ? 1 : 0,
      'date': date,
      'notification_time': notificationTime,
    };
  }
}
