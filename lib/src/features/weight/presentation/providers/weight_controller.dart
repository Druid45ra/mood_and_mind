import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mood_and_mind/src/core/di/service_locator.dart';
import 'package:mood_and_mind/src/features/weight/domain/entities/weight_entry.dart';
import 'package:mood_and_mind/src/features/weight/domain/usecases/add_weight_entry_usecase.dart';
import 'package:mood_and_mind/src/features/weight/domain/usecases/watch_weight_history_usecase.dart';

final weightHistoryProvider = FutureProvider.autoDispose<List<WeightEntry>>((ref) => sl<WatchWeightHistoryUseCase>()());

class WeightController {
  Future<void> addEntry(WeightEntry entry, WidgetRef ref) async {
    await sl<AddWeightEntryUseCase>()(entry);
    ref.invalidate(weightHistoryProvider);
  }
}

final weightControllerProvider = Provider((ref) => WeightController());
