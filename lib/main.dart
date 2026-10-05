import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manga_reader/core/theme/theme.dart';
import 'package:manga_reader/core/utils/constants.dart';
import 'package:manga_reader/feature/Home/presenter/screen/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ImageCacheConfig.configure();
  runApp(
    ProviderScope(
      child: const MyApp(),
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
    Future.delayed(const Duration(seconds: 2), () {
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
          title: 'Manga/Comic Reader',
          theme: AppTheme.lightTheme(context).copyWith(
            textTheme: GoogleFonts.spaceGroteskTextTheme(
              AppTheme.lightTheme(context).textTheme,
            ),
          ),
          darkTheme: AppTheme.darkTheme(context).copyWith(
            textTheme: GoogleFonts.spaceGroteskTextTheme(
              AppTheme.darkTheme(context).textTheme,
            ),
          ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFFFE156), // Hot Yellow
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value * 2 * 3.14159,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B9D), // Hot Pink
                      border: Border.all(color: const Color(0xFF1A1A2E), width: 4),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF1A1A2E),
                          offset: Offset(6, 6),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: const Icon(
                      Icons.menu_book,
                      size: 64,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              'KOMIKU',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1A1A2E),
                letterSpacing: 4,
                shadows: const [
                  Shadow(
                    color: Colors.white,
                    offset: Offset(3, 3),
                  ),
                  Shadow(
                    color: Color(0xFF1A1A2E),
                    offset: Offset(5, 5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
