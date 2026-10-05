import 'package:xml/xml.dart';

class ComicInfoData {
  final String? title;
  final String? series;
  final String? volume;
  final String? number;
  final String? writer;
  final String? summary;
  final String? genre;
  final bool isRightToLeft;

  const ComicInfoData({
    this.title,
    this.series,
    this.volume,
    this.number,
    this.writer,
    this.summary,
    this.genre,
    this.isRightToLeft = true,
  });

  static ComicInfoData? parse(String xmlContent) {
    if (xmlContent.trim().isEmpty) return null;
    try {
      final document = XmlDocument.parse(xmlContent);
      final root = document.findElements('ComicInfo').firstOrNull ?? document.rootElement;

      String? getTag(String name) {
        final el = root.findElements(name).firstOrNull;
        final text = el?.innerText.trim();
        return (text != null && text.isNotEmpty) ? text : null;
      }

      final mangaTag = getTag('Manga')?.toLowerCase();
      final isRtl = mangaTag != null &&
          (mangaTag == 'yes' ||
              mangaTag == 'yesandrighttoleft' ||
              mangaTag == 'righttoleft');

      return ComicInfoData(
        title: getTag('Title'),
        series: getTag('Series'),
        volume: getTag('Volume') ?? getTag('Number'),
        number: getTag('Number'),
        writer: getTag('Writer') ?? getTag('Penciller'),
        summary: getTag('Summary') ?? getTag('Comments'),
        genre: getTag('Genre') ?? getTag('Tags'),
        isRightToLeft: isRtl,
      );
    } catch (_) {
      return null;
    }
  }
}
