class JournalEntry {
  final int id;
  final String mood;
  final int intensity;
  final String note;
  final String timestamp;

  JournalEntry({
    required this.id,
    required this.mood,
    required this.intensity,
    required this.note,
    required this.timestamp,
  });

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] as int,
      mood: map['mood'] as String,
      intensity: map['intensity'] as int,
      note: map['note'] as String,
      timestamp: map['timestamp'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mood': mood,
      'intensity': intensity,
      'note': note,
      'timestamp': timestamp,
    };
  }
}
