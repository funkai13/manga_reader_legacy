import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/constants.dart';

class ComicSearchBar extends StatefulWidget {
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const ComicSearchBar({
    super.key,
    required this.query,
    required this.onChanged,
    this.onClear,
  });

  @override
  State<ComicSearchBar> createState() => _ComicSearchBarState();
}

class _ComicSearchBarState extends State<ComicSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant ComicSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query && _controller.text != widget.query) {
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColorsDark.borderColor : NeoColors.ink;
    final cardBg = isDark ? AppColorsDark.surfaceColor : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
        border: Border.all(color: borderColor, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: isDark ? NeoColors.darkShadow : NeoColors.hardShadowColor,
            offset: const Offset(2.5, 2.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        style: AppTypography.heading(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColorsDark.textColor : NeoColors.ink,
        ),
        decoration: InputDecoration(
          hintText: 'Buscar título, autor, género...',
          hintStyle: AppTypography.body(
            fontSize: 13,
            color: isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: isDark ? AppColorsDark.textSecondary : NeoColors.ink,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                    widget.onClear?.call();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
