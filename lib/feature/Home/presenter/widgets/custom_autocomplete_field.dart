import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    
    final textColor = isDark ? const Color(0xFFF0E6D3) : const Color(0xFF1A1A2E);
    final borderColor = isDark ? const Color(0xFFF0E6D3) : const Color(0xFF1A1A2E);
    final bgColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFFF8E7);
    final accentColor = isDark ? const Color(0xFFFFE156) : const Color(0xFFFF6B9D);

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
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16 * scale,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              labelText: widget.label,
              labelStyle: GoogleFonts.spaceGrotesk(color: textColor.withValues(alpha: 0.7), fontWeight: FontWeight.bold),
              prefixIcon: icon != null
                  ? Icon(
                      icon,
                      color: textColor,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: borderColor, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: borderColor, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(
                  color: accentColor,
                  width: 3,
                ),
              ),
              filled: true,
              fillColor: bgColor,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 16 * scale, vertical: 18 * scale),
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
                  color: bgColor,
                  border: Border.all(color: borderColor, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(4, 4),
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
                              ? Border(bottom: BorderSide(color: borderColor, width: 2))
                              : null,
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          option,
                          style: GoogleFonts.spaceGrotesk(
                            color: textColor,
                            fontWeight: FontWeight.bold,
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
