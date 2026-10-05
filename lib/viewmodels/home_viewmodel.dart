import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comic.dart';
import '../services/comic_repository.dart';

final comicRepositoryProvider = Provider<ComicRepository>((ref) {
  return ComicRepository();
});

class HomeState {
  final List<Comic> allComics;
  final Comic? activeComic;
  final String activeFilter;
  final bool isGridView;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  const HomeState({
    this.allComics = const [],
    this.activeComic,
    this.activeFilter = 'all',
    this.isGridView = true,
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
  });

  int get allCount => allComics.length;
  int get cbzCount => allComics.where((c) => c.fileExtension == 'CBZ').length;
  int get cbrCount => allComics.where((c) => c.fileExtension == 'CBR').length;
  int get readingCount => allComics.where((c) => c.isReading && !c.isCompleted).length;
  int get completedCount => allComics.where((c) => c.isCompleted).length;

  List<Comic> get filteredComics {
    var list = allComics;

    // Apply category filter
    switch (activeFilter) {
      case 'cbz':
        list = list.where((c) => c.fileExtension == 'CBZ').toList();
        break;
      case 'cbr':
        list = list.where((c) => c.fileExtension == 'CBR').toList();
        break;
      case 'reading':
        list = list.where((c) => c.isReading && !c.isCompleted).toList();
        break;
      case 'completed':
        list = list.where((c) => c.isCompleted).toList();
        break;
      case 'all':
      default:
        break;
    }

    // Apply search filter
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      list = list.where((c) {
        final title = c.title.toLowerCase();
        final author = c.author?.toLowerCase() ?? '';
        final genre = c.genre?.toLowerCase() ?? '';
        return title.contains(q) || author.contains(q) || genre.contains(q);
      }).toList();
    }

    return list;
  }

  HomeState copyWith({
    List<Comic>? allComics,
    Comic? Function()? activeComic,
    String? activeFilter,
    bool? isGridView,
    String? searchQuery,
    bool? isLoading,
    String? Function()? errorMessage,
  }) {
    return HomeState(
      allComics: allComics ?? this.allComics,
      activeComic: activeComic != null ? activeComic() : this.activeComic,
      activeFilter: activeFilter ?? this.activeFilter,
      isGridView: isGridView ?? this.isGridView,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class HomeViewModel extends Notifier<HomeState> {
  ComicRepository get _repository => ref.read(comicRepositoryProvider);

  @override
  HomeState build() {
    Future.microtask(() => loadComics());
    return const HomeState(isLoading: true);
  }

  Future<void> loadComics() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final comics = await _repository.getAllComics();
      // Determine active comic: either explicitly marked currentReading,
      // or the comic with the most recent lastOpened that has progress
      Comic? active;
      final readingComics = comics.where((c) => c.isReading).toList();
      if (readingComics.isNotEmpty) {
        active = readingComics.first;
      } else {
        final withProgress = comics.where((c) => c.currentPage > 0).toList();
        if (withProgress.isNotEmpty) {
          active = withProgress.first;
        } else if (comics.isNotEmpty) {
          active = comics.first;
        }
      }

      state = state.copyWith(
        allComics: comics,
        activeComic: () => active,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => 'Error al cargar los cómics: $e',
      );
    }
  }

  Future<Comic?> importComic(String filePath) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final imported = await _repository.importComic(filePath);
      await loadComics();
      return imported;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
      return null;
    }
  }

  Future<void> deleteComic(Comic comic) async {
    try {
      await _repository.deleteComic(comic);
      await loadComics();
    } catch (e) {
      state = state.copyWith(errorMessage: () => 'Error al eliminar: $e');
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(activeFilter: filter);
  }

  void setGridView(bool isGrid) {
    state = state.copyWith(isGridView: isGrid);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> setActive(Comic comic) async {
    if (comic.id != null) {
      await _repository.setActiveReading(comic.id!);
      await loadComics();
    }
  }
}

final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeState>(() {
  return HomeViewModel();
});
