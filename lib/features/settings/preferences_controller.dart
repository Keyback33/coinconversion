import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../shared/app_failure.dart';
import 'user_preferences.dart';

class PreferencesState {
  const PreferencesState({
    required this.value,
    this.isLoading = true,
    this.saveFailed = false,
  });

  final UserPreferences value;
  final bool isLoading;
  final bool saveFailed;

  PreferencesState copyWith({
    UserPreferences? value,
    bool? isLoading,
    bool? saveFailed,
  }) {
    return PreferencesState(
      value: value ?? this.value,
      isLoading: isLoading ?? this.isLoading,
      saveFailed: saveFailed ?? this.saveFailed,
    );
  }
}

class PreferencesController extends Notifier<PreferencesState> {
  Future<void> _writeQueue = Future.value();
  bool _loaded = false;

  @override
  PreferencesState build() => PreferencesState(value: UserPreferences.defaults);

  Future<void> load() async {
    if (_loaded) {
      return;
    }
    _loaded = true;
    try {
      final value = await ref.read(preferencesStoreProvider).read();
      state = PreferencesState(value: value, isLoading: false);
    } on AppFailure {
      state = PreferencesState(
        value: UserPreferences.defaults,
        isLoading: false,
        saveFailed: true,
      );
    }
  }

  void update(UserPreferences value) {
    state = state.copyWith(value: value, saveFailed: false);
    _writeQueue = _writeQueue.then((_) async {
      try {
        await ref.read(preferencesStoreProvider).write(value);
      } on AppFailure {
        state = state.copyWith(saveFailed: true);
      }
    });
  }

  void addFavorite(String code) {
    if (state.value.favoriteCodes.contains(code)) {
      return;
    }
    update(
      state.value.copyWith(favoriteCodes: [...state.value.favoriteCodes, code]),
    );
  }

  void removeFavorite(String code) {
    update(
      state.value.copyWith(
        favoriteCodes: state.value.favoriteCodes
            .where((item) => item != code)
            .toList(),
      ),
    );
  }

  void reorderFavorite(int oldIndex, int newIndex) {
    final values = [...state.value.favoriteCodes];
    if (newIndex > oldIndex) {
      newIndex--;
    }
    final value = values.removeAt(oldIndex);
    values.insert(newIndex, value);
    update(state.value.copyWith(favoriteCodes: values));
  }

  void moveFavorite(int index, int offset) {
    final target = index + offset;
    if (target < 0 || target >= state.value.favoriteCodes.length) {
      return;
    }
    final values = [...state.value.favoriteCodes];
    final value = values.removeAt(index);
    values.insert(target, value);
    update(state.value.copyWith(favoriteCodes: values));
  }
}
