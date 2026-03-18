import 'package:mood_and_mind/src/features/weight/domain/entities/weight_entry.dart';

abstract class WeightRepository {
  Future<void> addEntry(WeightEntry entry);
  Future<List<WeightEntry>> getHistory();
}
