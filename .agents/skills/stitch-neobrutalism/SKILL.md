---
name: stitch-neobrutalism
description: Gu�a pr�ctica para implementar componentes con el sistema 'Paper & Ink' de Google Stitch.
---
# SKILL: STITCH NEOBRUTALISM DESIGN PLAYBOOK

> **Guía práctica para implementar componentes con el sistema "Paper & Ink" de Google Stitch.**

---

## 1. Tokens Centrales del Sistema de Diseño

### Paleta de Colores (`NeoColors`)
```dart
abstract class NeoColors {
  // Tinta & Bordes
  static const Color ink = Color(0xFF121316);         // Tinta negra editorial profunda
  static const Color darkBorder = Color(0xFF383B44);  // Líneas divisorias en modo oscuro
  static const Color darkShadow = Color(0xFF0D0E10);  // Sombra dura modo oscuro

  // Papel & Superficies (Modo Claro)
  static const Color paperWhite = Color(0xFFF5F3EC);   // Fondo base de papel pergamino
  static const Color surfaceWarm = Color(0xFFECEAE0);  // Superficie elevada 1
  static const Color surfaceDeep = Color(0xFFE2DFD2);  // Superficie anidada / contenedores

  // Acentos de Color
  static const Color terracotta = Color(0xFFD96B43);   // Acento principal cálido (Manga Ink)
  static const Color mutedIndigo = Color(0xFF3E54A3);  // Acento secundario (Tinta índigo)
}
```

### Tipografía Jerárquica (`AppTypography`)
1. **Titulares e Impacto:** `GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, letterSpacing: -0.5)`
2. **Badges, Contadores y Metadatos:** `GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700, letterSpacing: 0.5)`
3. **Cuerpo de Lectura y Notas:** `GoogleFonts.workSans(fontWeight: FontWeight.w400, letterSpacing: 0.1)`

---

## 2. Receta: Sombra Dura y Borde Neobrutalista

```dart
BoxDecoration neoDecoration({
  required Color backgroundColor,
  required Color borderColor,
  required Color shadowColor,
  bool hasShadow = true,
}) {
  return BoxDecoration(
    color: backgroundColor,
    borderRadius: BorderRadius.circular(4.0),
    border: Border.all(
      color: borderColor,
      width: 2.0,
    ),
    boxShadow: hasShadow
        ? [
            BoxShadow(
              color: shadowColor,
              offset: const Offset(2.5, 2.5),
              blurRadius: 0, // Cero desenfoque (Sombra dura)
              spreadRadius: 0,
            ),
          ]
        : null,
  );
}
```

---

## 3. Receta: Microinteracción de Depresión Táctil (+2px)

Al presionar un botón o tarjeta interactiva, el elemento se desplaza físicamente `+2px` en el eje X e Y, reduciendo su sombra dura a cero para dar una sensación táctil mecánica idéntica a una tecla física:

```dart
class NeoInteractiveButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const NeoInteractiveButton({super.key, required this.child, required this.onTap});

  @override
  State<NeoInteractiveButton> createState() => _NeoInteractiveButtonState();
}

class _NeoInteractiveButtonState extends State<NeoInteractiveButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Transform.translate(
        offset: _isPressed ? const Offset(2.0, 2.0) : Offset.zero,
        child: Container(
          decoration: neoDecoration(
            backgroundColor: NeoColors.terracotta,
            borderColor: NeoColors.ink,
            shadowColor: NeoColors.ink,
            hasShadow: !_isPressed, // La sombra desaparece al comprimirse
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: widget.child,
        ),
      ),
    );
  }
}
```
