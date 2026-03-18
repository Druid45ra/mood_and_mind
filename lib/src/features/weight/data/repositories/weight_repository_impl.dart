import 'package:mood_and_mind/src/features/weight/data/datasources/weight_local_datasource.dart';
import 'package:mood_and_mind/src/features/weight/data/models/weight_entry_model.dart';
import 'package:mood_and_mind/src/features/weight/domain/entities/weight_entry.dart';
import 'package:mood_and_mind/src/features/weight/domain/repositories/weight_repository.dart';

class WeightRepositoryImpl implements WeightRepository {
  const WeightRepositoryImpl(this._dataSource);
  final WeightLocalDataSource _dataSource;

  @override
  Future<void> addEntry(WeightEntry entry) => _dataSource.addEntry(WeightEntryModel.fromEntity(entry));

  @override
  Future<List<WeightEntry>> getHistory() => _dataSource.getHistory();
}
