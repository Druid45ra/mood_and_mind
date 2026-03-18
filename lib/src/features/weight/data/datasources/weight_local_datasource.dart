import 'package:hive/hive.dart';
import 'package:mood_and_mind/src/features/weight/data/models/weight_entry_model.dart';

abstract class WeightLocalDataSource {
  Future<void> addEntry(WeightEntryModel entry);
  Future<List<WeightEntryModel>> getHistory();
}

class HiveWeightLocalDataSource implements WeightLocalDataSource {
  HiveWeightLocalDataSource(this._box);
  final Box _box;

  List<Map<dynamic, dynamic>> _allRaw() => (_box.get('weights', defaultValue: <Map<dynamic, dynamic>>[]) as List).cast<Map<dynamic, dynamic>>();

  @override
  Future<void> addEntry(WeightEntryModel entry) async {
    final items = _allRaw()..add(entry.toJson());
    items.sort((a, b) => DateTime.parse(a['recordedAt'] as String).compareTo(DateTime.parse(b['recordedAt'] as String)));
    await _box.put('weights', items);
  }

  @override
  Future<List<WeightEntryModel>> getHistory() async => _allRaw().map(WeightEntryModel.fromJson).toList();
}
