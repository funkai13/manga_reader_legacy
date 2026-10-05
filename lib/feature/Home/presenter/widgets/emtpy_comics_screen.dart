import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/core/theme/typography.dart';
import 'package:manga_reader/core/utils/constants.dart';
import 'package:manga_reader/core/widgets/neo_button.dart';

class EmptyComicsScreen extends StatefulWidget {
  final VoidCallback onAddComic;

  const EmptyComicsScreen({
    super.key,
    required this.onAddComic,
  });

  @override
  State<EmptyComicsScreen> createState() => _EmptyComicsScreenState();
}

class _EmptyComicsScreenState extends State<EmptyComicsScreen> {
  double _opacity = 0;
  double _scale = 0.9;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      setState(() {
        _opacity = 1;
        _scale = 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.backgroundColor : AppColorsLight.backgroundColor;
    final textColor = isDark ? AppColorsDark.textColor : AppColorsLight.textColor;
    final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
    final shadowColor = isDark ? NeoColors.darkShadow : NeoColors.hardShadowColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          opacity: _opacity,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            scale: _scale,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: AppColorsLight.terracotta,
                      borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                      border: Border.all(color: borderColor, width: NeoConstants.borderWidth),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          offset: const Offset(4, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      size: 72.sp,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 28.h),
                  Text(
                    'SIN COMICS AÚN',
                    style: AppTypography.heading(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Agrega tu primer comic para comenzar.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body(
                      fontSize: 14.sp,
                      color: isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 32.h),
                  NeoButton(
                    text: 'AGREGAR COMIC',
                    icon: Icons.add,
                    backgroundColor: AppColorsLight.terracotta,
                    foregroundColor: Colors.white,
                    onPressed: widget.onAddComic,
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
                    fontSize: 14.sp,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
