import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

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
  double _scale = 0.8;

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
    final bgColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFFF8E7);
    final textColor = isDark ? const Color(0xFFF0E6D3) : const Color(0xFF1A1A2E);
    final borderColor = isDark ? const Color(0xFFF0E6D3) : const Color(0xFF1A1A2E);
    final accentColor = isDark ? const Color(0xFFFFE156) : const Color(0xFFFFE156);

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOut,
          opacity: _opacity,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            scale: _scale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ECDC4),
                    border: Border.all(color: borderColor, width: 4),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(6, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 90.sp,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 32.h),
                Text(
                  'SIN COMICS AÚN',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -1,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Agrega tu primer comic para comenzar.',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor.withValues(alpha: 0.8),
                  ),
                ),
                SizedBox(height: 40.h),
                GestureDetector(
                  onTap: widget.onAddComic,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 32.w,
                      vertical: 16.h,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor,
                      border: Border.all(color: borderColor, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(4, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.black, size: 24.sp),
                        SizedBox(width: 8.w),
                        Text(
                          'AGREGAR COMIC',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
