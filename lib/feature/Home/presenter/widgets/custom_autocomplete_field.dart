import 'package:flutter/material.dart';
import 'package:manga_reader/core/theme/colors.dart';
import 'package:manga_reader/core/theme/typography.dart';
import 'package:manga_reader/core/utils/constants.dart';

class CustomAutocompleteField extends StatefulWidget {
  final String label;
  final Future<List<String>> Function() optionsBuilder;
  final void Function(String) onSelected;
  final TextEditingController controller;
  final IconData? icon;
  final double scale;
  final bool isDark;

  const CustomAutocompleteField({
    super.key,
    required this.label,
    required this.optionsBuilder,
    required this.onSelected,
    required this.controller,
    this.icon,
    this.scale = 1.0,
    this.isDark = false,
  });

  @override
  State<CustomAutocompleteField> createState() => _CustomAutocompleteFieldState();
}

class _CustomAutocompleteFieldState extends State<CustomAutocompleteField> {
  final _focusNode = FocusNode();
  late Future<List<String>> _options = widget.optionsBuilder();

  @override
  void didUpdateWidget(covariant CustomAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.optionsBuilder != widget.optionsBuilder) {
      _options = widget.optionsBuilder();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final isDark = widget.isDark;
    final icon = widget.icon;

    final textColor = isDark ? AppColorsDark.textColor : AppColorsLight.textColor;
    final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
    final bgColor = isDark ? AppColorsDark.surfaceDeep : AppColorsLight.surfaceColor;
    final indigoColor = isDark ? AppColorsDark.indigo : AppColorsLight.indigo;
    final shadowColor = isDark ? NeoColors.darkShadow : NeoColors.hardShadowColor;

    return LayoutBuilder(builder: (context, constraints) {
      return RawAutocomplete<String>(
        textEditingController: widget.controller,
        focusNode: _focusNode,
        optionsBuilder: (TextEditingValue textEditingValue) async {
          final query = textEditingValue.text.toLowerCase();
          if (query.isEmpty) {
            return const Iterable<String>.empty();
          }
          final options = await _options;
          return options.where((String option) => option.toLowerCase().contains(query));
        },
        onSelected: widget.onSelected,
        fieldViewBuilder: (
          BuildContext context,
          TextEditingController fieldTextEditingController,
          FocusNode fieldFocusNode,
          VoidCallback onFieldSubmitted,
        ) {
          return TextFormField(
            controller: fieldTextEditingController,
            focusNode: fieldFocusNode,
            style: AppTypography.heading(
              fontSize: 14 * scale,
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              labelText: widget.label,
              labelStyle: AppTypography.body(
                color: isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary,
                fontSize: 14 * scale,
              ),
              prefixIcon: icon != null
                  ? Icon(
                      icon,
                      color: isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary,
                      size: 20 * scale,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                borderSide: BorderSide(color: borderColor, width: NeoConstants.borderWidth),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                borderSide: BorderSide(color: borderColor, width: NeoConstants.borderWidth),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                borderSide: BorderSide(
                  color: indigoColor,
                  width: NeoConstants.borderWidth + 0.5,
                ),
              ),
              filled: true,
              fillColor: bgColor,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14 * scale,
                vertical: 14 * scale,
              ),
            ),
          );
        },
        optionsViewBuilder: (
          BuildContext context,
          AutocompleteOnSelected<String> onSelected,
          Iterable<String> options,
        ) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 0,
              color: Colors.transparent,
              child: Container(
                width: constraints.maxWidth,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColorsDark.surfaceColor : AppColorsLight.cardColor,
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
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final String option = options.elementAt(index);
                    return InkWell(
                      onTap: () {
                        onSelected(option);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: index < options.length - 1
                              ? Border(bottom: BorderSide(color: borderColor, width: 1.5))
                              : null,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Text(
                          option,
                          style: AppTypography.heading(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
