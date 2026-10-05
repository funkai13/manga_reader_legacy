import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:manga_reader/feature/Home/presenter/controller/comic_controller.dart';

import '../../../../core/widgets/generic_grid.dart';
import 'comic_card.dart';

class ComicsGrid extends ConsumerWidget {
  const ComicsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> fetchComics() async {
      await ref.read(comicControllerProvider.notifier).getAllComics();
    }

    final asyncComics = ref.watch(comicControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF0E6D3) : const Color(0xFF1A1A2E);

    return asyncComics.when(
      data: (comics) => RefreshIndicator(
          onRefresh: () async {
            await fetchComics();
          },
          child: GenericGrid(
            items: comics,
            maxCrossAxisExtent: 200,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 260,
            itemBuilder: (comic) {
              return ComicCard(
                comic: comic,
                scale: 1.0,
              );
            },
          )),
      loading: () => Center(
        child: Container(
          width: 50.w,
          height: 50.w,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFFFFE156) : const Color(0xFF4ECDC4),
            border: Border.all(color: textColor, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.black,
              strokeWidth: 3,
            ),
          ),
        ),
      ),
      error: (error, _) => Center(
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: const Color(0xFFFF5252),
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
          ),
          child: Text(
            'ERROR:\n$error',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
