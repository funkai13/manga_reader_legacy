import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/core/theme/typography.dart';
import 'package:manga_reader/core/utils/constants.dart';
import 'package:manga_reader/core/widgets/file_thumbnail.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Reader/presenter/screens/comic_viewer_screen.dart';
import 'package:path/path.dart' as p;

SliverToBoxAdapter buildSearchBar(
  BuildContext context,
  List<ComicEntity> comics,
  bool isDark,
  double scale,
  SearchController searchController,
  FocusNode searchFocusNode,
  bool isTablet,
) {
  final double kSearchBarBaseHeight = isTablet ? (scale < 1.0 ? 80.0 : 72.0) : 52.0;
  final barHeight = kSearchBarBaseHeight * scale;

  final bgColor = isDark ? AppColorsDark.surfaceDeep : AppColorsLight.surfaceColor;
  final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
  final textColor = isDark ? AppColorsDark.textColor : AppColorsLight.textColor;
  final indigoColor = isDark ? AppColorsDark.indigo : AppColorsLight.indigo;
  final shadowColor = isDark ? NeoColors.darkShadow : NeoColors.hardShadowColor;

  return SliverToBoxAdapter(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w * scale),
      child: Container(
        margin: EdgeInsets.only(bottom: 14.h * scale, top: 10.h * scale),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          border: Border.all(
            color: searchFocusNode.hasFocus ? indigoColor : borderColor,
            width: NeoConstants.borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: searchFocusNode.hasFocus ? indigoColor.withValues(alpha: 0.6) : shadowColor,
              blurRadius: 0,
              offset: NeoConstants.shadowOffset,
            ),
          ],
        ),
        child: SearchAnchor(
          isFullScreen: false,
          shrinkWrap: true,
          searchController: searchController,
          headerHeight: barHeight,
          viewPadding: EdgeInsets.zero,
          viewSide: BorderSide(color: borderColor, width: NeoConstants.borderWidth),
          viewBackgroundColor: isDark ? AppColorsDark.surfaceColor : AppColorsLight.cardColor,
          viewShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          ),
          viewConstraints: BoxConstraints(
            maxHeight: 320.h * scale,
          ),
          builder: (BuildContext context, SearchController controller) {
            return SearchBar(
              focusNode: searchFocusNode,
              autoFocus: false,
              controller: controller,
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 14.w * scale),
              ),
              constraints: BoxConstraints(minHeight: barHeight),
              onTap: controller.openView,
              onChanged: (_) => controller.openView(),
              onTapOutside: (_) {
                FocusScope.of(context).unfocus();
              },
              leading: Icon(
                Icons.search,
                color: searchFocusNode.hasFocus ? indigoColor : textColor,
                size: 22.sp * scale,
              ),
              hintText: 'BUSCAR EN LA BIBLIOTECA...',
              textStyle: WidgetStatePropertyAll(
                AppTypography.heading(
                  color: textColor,
                  fontSize: 13.sp * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
              hintStyle: WidgetStatePropertyAll(
                AppTypography.mono(
                  color: isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary,
                  fontSize: 12.sp * scale,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
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
                  (comic) =>
                      comic.title.toLowerCase().contains(input) ||
                      (comic.author?.toLowerCase().contains(input) ?? false),
                )
                .take(20)
                .toList();

            if (results.isEmpty) {
              return [
                Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: borderColor, width: 1.5)),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.search_off, color: textColor),
                    title: Text(
                      'Sin resultados',
                      style: AppTypography.heading(
                        fontSize: 14.sp * scale,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      'No se encontró ningún cómic con "$inputRaw"',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        fontSize: 12.sp * scale,
                        color: isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary,
                      ),
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
                  border: Border(bottom: BorderSide(color: borderColor, width: 1.5)),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.w * scale,
                    vertical: 6.h * scale,
                  ),
                  leading: _buildComicThumbnail(comic, isDark, scale, borderColor),
                  title: _buildHighlightedTitle(
                    comic.title,
                    inputRaw,
                    isDark,
                    scale,
                    textColor,
                  ),
                  subtitle: Row(
                    children: [
                      if (_formatBadge(comic) != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: indigoColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            _formatBadge(comic)!,
                            style: AppTypography.mono(
                              fontSize: 9.sp * scale,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                      Text(
                        comic.isCompleted
                            ? 'LEÍDO'
                            : comic.isReading
                                ? 'EN PROGRESO'
                                : (comic.currentReadPage == 0 ? 'NUEVO' : 'PAUSADO'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.mono(
                          fontSize: 10.sp * scale,
                          fontWeight: FontWeight.w700,
                          color: comic.isReading
                              ? AppColorsLight.terracotta
                              : (isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary),
                        ),
                      ),
                    ],
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

String? _formatBadge(ComicEntity comic) {
  final ext = p.extension(comic.title).toLowerCase();
  if (ext == '.cbz') return 'CBZ';
  if (ext == '.cbr') return 'CBR';
  return null;
}

Widget _buildComicThumbnail(ComicEntity comic, bool isDark, double scale, Color borderColor) {
  final width = 36.w * scale;
  final height = 48.h * scale;

  if (comic.picture.isNotEmpty) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(1),
        child: FileThumbnail(
          comic.picture,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _fallbackThumb(isDark, width, height, scale, borderColor),
        ),
      ),
    );
  }

  return _fallbackThumb(isDark, width, height, scale, borderColor);
}

Widget _fallbackThumb(bool isDark, double width, double height, double scale, Color borderColor) {
  final bgColor = isDark ? AppColorsDark.surfaceDeep : AppColorsLight.surfaceDeep;
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(2),
      border: Border.all(color: borderColor, width: 1.5),
      color: bgColor,
    ),
    child: Icon(
      Icons.auto_stories,
      size: 16.sp * scale,
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
  final ext = p.extension(title).toLowerCase();
  final cleanTitle = (ext == '.cbz' || ext == '.cbr')
      ? p.basenameWithoutExtension(title)
      : title;

  if (query.isEmpty) {
    return Text(
      cleanTitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.heading(
        fontSize: 13.sp * scale,
        fontWeight: FontWeight.bold,
        color: baseColor,
      ),
    );
  }

  final lowerTitle = cleanTitle.toLowerCase();
  final lowerQuery = query.toLowerCase();
  final matchIndex = lowerTitle.indexOf(lowerQuery);

  if (matchIndex == -1) {
    return Text(
      cleanTitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.heading(
        fontSize: 13.sp * scale,
        fontWeight: FontWeight.bold,
        color: baseColor,
      ),
    );
  }

  final beforeMatch = cleanTitle.substring(0, matchIndex);
  final matchText = cleanTitle.substring(matchIndex, matchIndex + query.length);
  final afterMatch = cleanTitle.substring(matchIndex + query.length);

  return Text.rich(
    TextSpan(
      children: [
        TextSpan(text: beforeMatch),
        TextSpan(
          text: matchText,
          style: AppTypography.heading(
            fontSize: 13.sp * scale,
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ).copyWith(
            backgroundColor: AppColorsLight.terracotta,
          ),
        ),
        TextSpan(text: afterMatch),
      ],
      style: AppTypography.heading(
        fontSize: 13.sp * scale,
        color: baseColor,
        fontWeight: FontWeight.bold,
      ),
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}
