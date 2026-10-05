import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../feature/Reader/presenter/screens/comic_viewer_screen.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../home/home_screen.dart';
import '../library/collections_screen.dart';
import '../profile/profile_screen.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    CollectionsScreen(),
    SizedBox.shrink(), // Index 2 triggers viewer navigation directly
    ProfileScreen(),
  ];

  void _onTabSelected(int index) {
    if (index == 2) {
      // Visor Tab: open the currently active comic in the reader
      final active = ref.read(homeViewModelProvider).activeComic;
      if (active != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ComicViewerScreen(comic: active.toEntity()),
          ),
        ).then((_) {
          ref.read(homeViewModelProvider.notifier).loadComics();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecciona un cómic de la biblioteca para abrir el visor.'),
            backgroundColor: NeoColors.terracotta,
          ),
        );
      }
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColorsDark.surfaceColor : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColorsDark.borderColor : NeoColors.ink,
              width: 2.0,
            ),
          ),
          boxShadow: const [
            BoxShadow(
              color: NeoColors.ink,
              offset: Offset(0, -1),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.book_outlined, Icons.book, 'BIBLIOTECA', isDark),
              _buildNavItem(1, Icons.collections_bookmark_outlined, Icons.collections_bookmark, 'COLECCIONES', isDark),
              _buildNavItem(2, Icons.chrome_reader_mode_outlined, Icons.chrome_reader_mode, 'VISOR', isDark),
              _buildNavItem(3, Icons.person_outline, Icons.person, 'PERFIL', isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData iconOutline,
    IconData iconFilled,
    String label,
    bool isDark,
  ) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? NeoColors.terracotta
        : (isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary);

    return InkWell(
      onTap: () => _onTabSelected(index),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? iconFilled : iconOutline,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTypography.mono(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
