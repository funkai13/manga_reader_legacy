import 'package:manga_reader/core/widgets/file_thumbnail.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';

import '../screen/comic_viewer_screen.dart';

SliverToBoxAdapter buildSearchBar(
  BuildContext context,
  List<ComicEntity> comics,
  bool isDark,
  double scale,
  SearchController searchController,
  FocusNode searchFocusNode,
  bool isTablet,
) {
  // Minimum height only: the bar may grow with the text scale so the hint is
  // never clipped (a fixed 50px bar cut "Buscar en tu biblioteca" on phones).
  final double kSearchBarBaseHeight = isTablet ? 100.0 : 50.0;
  final barHeight = kSearchBarBaseHeight * scale;

  return SliverToBoxAdapter(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w * scale),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h * scale, top: 16.h * scale),
        decoration: BoxDecoration(
          color: isDark ? AppColorsDark.cardColor : AppColorsLight.cardColor,
          borderRadius: BorderRadius.circular(16.r * scale),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10 * scale,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SearchAnchor(
          isFullScreen: false,
          shrinkWrap: true,
          searchController: searchController,
          headerHeight: barHeight,
          viewPadding: EdgeInsets.zero,
          viewSide: BorderSide.none,
          viewBackgroundColor:
              isDark ? AppColorsDark.cardColor : AppColorsLight.cardColor,
          viewShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r * scale),
          ),
          viewConstraints: BoxConstraints(
            maxHeight: 250.h * scale,
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
                color: isDark
                    ? AppColorsDark.textColor.withValues(alpha: 0.6)
                    : AppColorsLight.textColor.withValues(alpha: 0.6),
                size: 20.sp * scale,
              ),
              hintText: 'Buscar en tu biblioteca',
              hintStyle: WidgetStatePropertyAll(
                TextStyle(
                  color: isDark
                      ? AppColorsDark.textColor.withValues(alpha: 0.4)
                      : AppColorsLight.textColor.withValues(alpha: 0.4),
                  fontSize: 12.sp * scale,
                ),
              ),
              backgroundColor: WidgetStatePropertyAll(
                isDark ? AppColorsDark.cardColor : AppColorsLight.cardColor,
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r * scale),
                  side: BorderSide.none,
                ),
              ),
            );
          },
          suggestionsBuilder:
              (BuildContext context, SearchController controller) {
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
                ListTile(
                  leading: const Icon(Icons.search_off),
                  title: const Text('Sin resultados'),
                  subtitle: Text(
                    'No se encontró ningún cómic con "$inputRaw"',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    controller.closeView('');
                    controller.clear();
                    FocusScope.of(context).unfocus();
                  },
                ),
              ];
            }

            return results.map((comic) {
              return ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w * scale,
                  vertical: 4.h * scale,
                ),
                leading: _buildComicThumbnail(comic, isDark, scale),
                title: _buildHighlightedTitle(
                  comic.title,
                  inputRaw,
                  isDark,
                  scale,
                ),
                subtitle: Text(
                  comic.isCompleted
                      ? 'Completado'
                      : comic.isReading
                          ? 'En progreso'
                          : (comic.currentReadPage == 0 ? 'Sin leer' : 'Leído'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.sp * scale),
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
              );
            });
          },
        ),
      ),
    ),
  );
}

Widget _buildComicThumbnail(ComicEntity comic, bool isDark, double scale) {
  final width = 36.w * scale;
  final height = 52.h * scale;

  if (comic.picture.isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r * scale),
      child: FileThumbnail(
        comic.picture,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _fallbackThumb(isDark, width, height, scale),
      ),
    );
  }

  return _fallbackThumb(isDark, width, height, scale);
}

Widget _fallbackThumb(bool isDark, double width, double height, double scale) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8.r * scale),
      color: isDark ? AppColorsDark.cardColor : AppColorsLight.cardColor,
    ),
    child: Icon(
      Icons.book,
      size: 18.sp * scale,
      color: isDark
          ? AppColorsDark.textColor.withValues(alpha: 0.4)
          : AppColorsLight.textColor.withValues(alpha: 0.4),
    ),
  );
}

/// Texto del título con highlight azul en lo que coincide con la búsqueda
Widget _buildHighlightedTitle(
  String title,
  String query,
  bool isDark,
  double scale,
) {
  if (query.isEmpty) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 13.sp * scale),
    );
  }

  final lowerTitle = title.toLowerCase();
  final lowerQuery = query.toLowerCase();
  final matchIndex = lowerTitle.indexOf(lowerQuery);

  if (matchIndex == -1) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 13.sp * scale),
    );
  }

  final beforeMatch = title.substring(0, matchIndex);
  final matchText = title.substring(matchIndex, matchIndex + query.length);
  final afterMatch = title.substring(matchIndex + query.length);

  final baseColor = isDark ? AppColorsDark.textColor : AppColorsLight.textColor;
  final highlightColor =
      isDark ? AppColorsDark.accentColor : AppColorsLight.accentColor;

  return Text.rich(
    TextSpan(
      children: [
        TextSpan(text: beforeMatch),
        TextSpan(
          text: matchText,
          style: TextStyle(
            color: highlightColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextSpan(text: afterMatch),
      ],
      style: TextStyle(
        fontSize: 13.sp * scale,
        color: baseColor,
      ),
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}
