import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comic.dart';
import '../services/comic_repository.dart';
import 'home_viewmodel.dart';

class LibraryState {
  final List<Map<String, dynamic>> collections;
  final List<Map<String, dynamic>> authors;
  final List<Map<String, dynamic>> genres;
  final String activeTab; // 'collections', 'authors', 'genres'
  final bool isLoading;
  final String? errorMessage;

  const LibraryState({
    this.collections = const [],
    this.authors = const [],
    this.genres = const [],
    this.activeTab = 'collections',
    this.isLoading = false,
    this.errorMessage,
  });

  LibraryState copyWith({
    List<Map<String, dynamic>>? collections,
    List<Map<String, dynamic>>? authors,
    List<Map<String, dynamic>>? genres,
    String? activeTab,
    bool? isLoading,
    String? Function()? errorMessage,
  }) {
    return LibraryState(
      collections: collections ?? this.collections,
      authors: authors ?? this.authors,
      genres: genres ?? this.genres,
      activeTab: activeTab ?? this.activeTab,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class LibraryViewModel extends Notifier<LibraryState> {
  ComicRepository get _repository => ref.read(comicRepositoryProvider);

  @override
  LibraryState build() {
    Future.microtask(() => loadCategories());
    return const LibraryState(isLoading: true);
  }

  Future<void> loadCategories() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final cols = await _repository.getCollectionsWithCount();
      final auths = await _repository.getAuthorsWithCount();
      final gens = await _repository.getGenresWithCount();

      state = state.copyWith(
        collections: cols,
        authors: auths,
        genres: gens,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => 'Error al cargar colecciones: $e',
      );
    }
  }

  void setActiveTab(String tab) {
    state = state.copyWith(activeTab: tab);
  }

  Future<List<Comic>> getComicsForCollection(String collection) =>
      _repository.getComicsByCollection(collection);
}

final libraryViewModelProvider =
    NotifierProvider<LibraryViewModel, LibraryState>(() {
  return LibraryViewModel();
});
