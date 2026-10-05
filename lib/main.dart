import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/core/theme/theme.dart';
import 'package:manga_reader/core/theme/typography.dart';
import 'package:manga_reader/core/utils/constants.dart';
import 'package:manga_reader/feature/Home/presenter/screen/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ImageCacheConfig.configure();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Manga Reader',
          theme: AppTheme.lightTheme(context),
          darkTheme: AppTheme.darkTheme(context),
          home: _showSplash ? const SplashScreen() : const HomeScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.backgroundColor : AppColorsLight.backgroundColor;
    final inkColor = isDark ? AppColorsDark.textColor : AppColorsLight.textColor;
    final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
    final shadowColor = isDark ? NeoColors.darkShadow : NeoColors.hardShadowColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: NeoColors.terracotta,
                borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                border: Border.all(color: borderColor, width: NeoConstants.borderWidth),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    offset: NeoConstants.shadowOffset,
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_stories,
                size: 52,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'TOMOS',
              style: AppTypography.heading(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: inkColor,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? AppColorsDark.surfaceDeep : AppColorsLight.surfaceColor,
                border: Border.all(color: borderColor, width: 1.5),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                'PAPER & INK // 漫画リーダー',
                style: AppTypography.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: inkColor,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
