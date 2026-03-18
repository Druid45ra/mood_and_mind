import 'package:mood_and_mind/src/features/weight/domain/entities/weight_entry.dart';

class WeightEntryModel extends WeightEntry {
  const WeightEntryModel({required super.id, required super.weightKg, required super.recordedAt});

  factory WeightEntryModel.fromJson(Map<dynamic, dynamic> json) => WeightEntryModel(
        id: json['id'] as String,
        weightKg: (json['weightKg'] as num).toDouble(),
        recordedAt: DateTime.parse(json['recordedAt'] as String),
      );

  Map<String, dynamic> toJson() => {'id': id, 'weightKg': weightKg, 'recordedAt': recordedAt.toIso8601String()};

  factory WeightEntryModel.fromEntity(WeightEntry entry) => WeightEntryModel(id: entry.id, weightKg: entry.weightKg, recordedAt: entry.recordedAt);
}
