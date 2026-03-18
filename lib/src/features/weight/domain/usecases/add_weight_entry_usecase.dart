import 'package:mood_and_mind/src/features/weight/domain/entities/weight_entry.dart';
import 'package:mood_and_mind/src/features/weight/domain/repositories/weight_repository.dart';

class AddWeightEntryUseCase {
  const AddWeightEntryUseCase(this._repository);
  final WeightRepository _repository;

  Future<void> call(WeightEntry entry) => _repository.addEntry(entry);
}
