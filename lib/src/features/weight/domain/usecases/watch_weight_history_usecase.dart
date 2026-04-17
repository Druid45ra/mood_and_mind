import 'package:mood_and_mind/src/features/weight/domain/entities/weight_entry.dart';
import 'package:mood_and_mind/src/features/weight/domain/repositories/weight_repository.dart';

class WatchWeightHistoryUseCase {
  const WatchWeightHistoryUseCase(this._repository);
  final WeightRepository _repository;

  Future<List<WeightEntry>> call() => _repository.getHistory();
}
