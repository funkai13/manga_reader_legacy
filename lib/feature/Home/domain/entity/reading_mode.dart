/// How a comic's pages are laid out in the reader. Persisted in the comic's
/// `comicType` column ('Manga', 'Comic', 'Webtoon'; null means auto = comic).
enum ReadingMode {
  rightToLeft('Manga', 'Manga', 'Derecha a izquierda'),
  leftToRight('Comic', 'Cómic', 'Izquierda a derecha'),
  vertical('Webtoon', 'Webtoon', 'Scroll vertical continuo');

  const ReadingMode(this.comicType, this.label, this.description);

  final String comicType;
  final String label;
  final String description;

  bool get isPaged => this != vertical;

  static ReadingMode fromComicType(String? comicType) => values.firstWhere(
        (mode) => mode.comicType == comicType,
        orElse: () => leftToRight,
      );
}
