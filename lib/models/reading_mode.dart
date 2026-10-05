enum ReadingMode {
  leftToRight('Cómic (I → D)', 'comic'),
  rightToLeft('Manga (D → I)', 'manga'),
  vertical('Webtoon (Vertical)', 'webtoon');

  final String label;
  final String code;

  const ReadingMode(this.label, this.code);

  static ReadingMode fromCode(String? code) {
    if (code == null) return ReadingMode.rightToLeft;
    for (final mode in ReadingMode.values) {
      if (mode.code == code) return mode;
    }
    return ReadingMode.rightToLeft;
  }
}
