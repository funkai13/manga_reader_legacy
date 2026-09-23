import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:manga_reader/feature/Home/domain/provider/comic_provider.dart';
import 'package:manga_reader/feature/Library/domain/providers/library_provider.dart';

import 'mocks.dart';

/// Disables Riverpod 3 automatic retry so errors surface immediately.
Duration? noRetry(int retryCount, Object error) => null;

ProviderContainer createContainer({
  MockComicRepository? comicRepository,
  MockLibraryRepository? libraryRepository,
  List<Override> overrides = const [],
}) {
  return ProviderContainer.test(
    retry: noRetry,
    overrides: [
      if (comicRepository != null)
        comicRepositoryProvider.overrideWithValue(comicRepository),
      if (libraryRepository != null)
        libraryRepositoryProvider.overrideWithValue(libraryRepository),
      ...overrides,
    ],
  );
}

/// Records every value emitted by [provider] (including the initial one).
List<T> recordStates<T>(ProviderContainer container, ProviderListenable<T> provider) {
  final states = <T>[];
  container.listen<T>(provider, (_, next) => states.add(next),
      fireImmediately: true);
  return states;
}
