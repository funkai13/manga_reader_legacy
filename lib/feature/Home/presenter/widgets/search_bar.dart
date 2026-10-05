import 'package:manga_reader/core/widgets/file_thumbnail.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';

import 'package:manga_reader/feature/Reader/presenter/screens/comic_viewer_screen.dart';

SliverToBoxAdapter buildSearchBar(
  BuildContext context,
  List<ComicEntity> comics,
  bool isDark,
  double scale,
  SearchController searchController,
  FocusNode searchFocusNode,
  bool isTablet,
) {
  final double kSearchBarBaseHeight = isTablet ? 80.0 : 56.0;
  final barHeight = kSearchBarBaseHeight * scale;

  final bgColor = isDark ? const Color(0xFF252542) : const Color(0xFFFFFFFF);
  final borderColor = isDark ? const Color(0xFFF0E6D3) : const Color(0xFF1A1A2E);
  final textColor = isDark ? const Color(0xFFF0E6D3) : const Color(0xFF1A1A2E);

  return SliverToBoxAdapter(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w * scale),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h * scale, top: 16.h * scale),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: borderColor, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              blurRadius: 0,
              offset: Offset(4, 4),
            ),
          ],
        ),
        child: SearchAnchor(
          isFullScreen: false,
          shrinkWrap: true,
          searchController: searchController,
          headerHeight: barHeight,
          viewPadding: EdgeInsets.zero,
          viewSide: BorderSide(color: borderColor, width: 3),
          viewBackgroundColor: bgColor,
          viewShape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          viewConstraints: BoxConstraints(
            maxHeight: 300.h * scale,
          ),
          builder: (BuildContext context, SearchController controller) {
            return SearchBar(
              focusNode: searchFocusNode,
              autoFocus: false,
              controller: controller,
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16.w * scale),
              ),
              constraints: BoxConstraints(minHeight: barHeight),
              onTap: controller.openView,
              onChanged: (_) => controller.openView(),
              onTapOutside: (_) {
                FocusScope.of(context).unfocus();
              },
              leading: Icon(
                Icons.search,
                color: textColor,
                size: 24.sp * scale,
              ),
              hintText: 'BUSCAR EN TU BIBLIOTECA',
              textStyle: WidgetStatePropertyAll(
                GoogleFonts.spaceGrotesk(
                  color: textColor,
                  fontSize: 14.sp * scale,
                  fontWeight: FontWeight.bold,
                ),
              ),
              hintStyle: WidgetStatePropertyAll(
                GoogleFonts.spaceGrotesk(
                  color: textColor.withValues(alpha: 0.5),
                  fontSize: 14.sp * scale,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: WidgetStatePropertyAll(bgColor),
              shape: const WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide.none,
                ),
              ),
              elevation: const WidgetStatePropertyAll(0),
            );
          },
          suggestionsBuilder: (BuildContext context, SearchController controller) {
            final inputRaw = controller.text;
            final input = inputRaw.toLowerCase().trim();

            if (input.isEmpty) {
              return const Iterable<Widget>.empty();
            }

            final results = comics
                .where(
                  (comic) => comic.title.toLowerCase().contains(input),
                )
                .take(20)
                .toList();

            if (results.isEmpty) {
              return [
                Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: borderColor, width: 2)),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.search_off, color: textColor),
                    title: Text(
                      'Sin resultados',
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: textColor),
                    ),
                    subtitle: Text(
                      'No se encontró ningún cómic con "$inputRaw"',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(color: textColor.withValues(alpha: 0.7)),
                    ),
                    onTap: () {
                      controller.closeView('');
                      controller.clear();
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),
              ];
            }

            return results.map((comic) {
              return Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderColor, width: 2)),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w * scale,
                    vertical: 8.h * scale,
                  ),
                  leading: _buildComicThumbnail(comic, isDark, scale, borderColor),
                  title: _buildHighlightedTitle(
                    comic.title,
                    inputRaw,
                    isDark,
                    scale,
                    textColor,
                  ),
                  subtitle: Text(
                    comic.isCompleted
                        ? 'COMPLETADO'
                        : comic.isReading
                            ? 'EN PROGRESO'
                            : (comic.currentReadPage == 0 ? 'SIN LEER' : 'LEÍDO'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10.sp * scale,
                      fontWeight: FontWeight.w900,
                      color: textColor.withValues(alpha: 0.6),
                    ),
                  ),
                  onTap: () async {
                    controller.closeView(comic.title);
                    FocusScope.of(context).unfocus();

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ComicViewerScreen(comic: comic),
                      ),
                    );

                    if (!context.mounted) return;

                    controller.text = '';
                    FocusScope.of(context).unfocus();
                  },
                ),
              );
            });
          },
        ),
      ),
    ),
  );
}

Widget _buildComicThumbnail(ComicEntity comic, bool isDark, double scale, Color borderColor) {
  final width = 36.w * scale;
  final height = 52.h * scale;

  if (comic.picture.isNotEmpty) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 2),
      ),
      child: FileThumbnail(
        comic.picture,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _fallbackThumb(isDark, width, height, scale, borderColor),
      ),
    );
  }

  return _fallbackThumb(isDark, width, height, scale, borderColor);
}

Widget _fallbackThumb(bool isDark, double width, double height, double scale, Color borderColor) {
  final bgColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFFF8E7);
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      border: Border.all(color: borderColor, width: 2),
      color: bgColor,
    ),
    child: Icon(
      Icons.book,
      size: 18.sp * scale,
      color: borderColor.withValues(alpha: 0.4),
    ),
  );
}

Widget _buildHighlightedTitle(
  String title,
  String query,
  bool isDark,
  double scale,
  Color baseColor,
) {
  final highlightColor = isDark ? const Color(0xFFFFE156) : const Color(0xFFFF6B9D);

  if (query.isEmpty) {
    return Text(
      title.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 14.sp * scale,
        fontWeight: FontWeight.bold,
        color: baseColor,
      ),
    );
  }

  final lowerTitle = title.toLowerCase();
  final lowerQuery = query.toLowerCase();
  final matchIndex = lowerTitle.indexOf(lowerQuery);

  if (matchIndex == -1) {
    return Text(
      title.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 14.sp * scale,
        fontWeight: FontWeight.bold,
        color: baseColor,
      ),
    );
  }

  final beforeMatch = title.substring(0, matchIndex);
  final matchText = title.substring(matchIndex, matchIndex + query.length);
  final afterMatch = title.substring(matchIndex + query.length);

  return Text.rich(
    TextSpan(
      children: [
        TextSpan(text: beforeMatch.toUpperCase()),
        TextSpan(
          text: matchText.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            color: isDark ? Colors.black : Colors.white,
            backgroundColor: highlightColor,
            fontWeight: FontWeight.w900,
          ),
        ),
        TextSpan(text: afterMatch.toUpperCase()),
      ],
      style: GoogleFonts.spaceGrotesk(
        fontSize: 14.sp * scale,
        color: baseColor,
        fontWeight: FontWeight.bold,
      ),
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}
