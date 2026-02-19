import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider para manejar el tema oscuro/claro
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'is_dark_mode';

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  /// Carga el tema guardado
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  /// Cambia entre tema oscuro y claro
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  /// Establece el tema directamente
  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode != value) {
      _isDarkMode = value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
      notifyListeners();
    }
  }

  /// Obtiene el ThemeData actual
  ThemeData get themeData => _isDarkMode ? _darkThemeData : _lightThemeData;

  /// Tema claro (getter público)
  ThemeData get lightTheme => _lightThemeData;

  /// Tema oscuro (getter público)
  ThemeData get darkTheme => _darkThemeData;

  // ── Colores de marca ──
  static const Color _brandBlue = Color(0xFF1976D2);
  static const Color _brandBlueDark = Color(0xFF90CAF9);

  /// Tema Claro
  static final ThemeData _lightThemeData = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: _brandBlue,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1976D2),
      onPrimary: Colors.white,
      secondary: Color(0xFF9C27B0),
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF1A237E),
      surfaceContainerHighest: Color(0xFFF0F0F5),
      outlineVariant: Color(0xFFE0E0E0),
      primaryContainer: Color(0xFFE3F2FD),
      onPrimaryContainer: Color(0xFF0D47A1),
      secondaryContainer: Color(0xFFF3E5F5),
      onSecondaryContainer: Color(0xFF4A148C),
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    cardColor: Colors.white,
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1976D2),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF1976D2),
      unselectedItemColor: Colors.grey,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF1976D2),
      foregroundColor: Colors.white,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFE3F2FD),
      selectedColor: const Color(0xFF1976D2),
      labelStyle: const TextStyle(
        color: Color(0xFF1565C0),
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide.none,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: Color(0xFF1A237E),
        fontWeight: FontWeight.w900,
      ),
      headlineMedium: TextStyle(
        color: Color(0xFF1A237E),
        fontWeight: FontWeight.w800,
      ),
      titleLarge: TextStyle(
        color: Color(0xFF1A237E),
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: Color(0xFF1A237E),
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: Color(0xFF1A237E)),
      bodyMedium: TextStyle(color: Color(0xFF37474F)),
      labelLarge: TextStyle(
        color: Color(0xFF546E7A),
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF0F0F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dividerColor: const Color(0xFFE0E0E0),
  );

  /// Tema Oscuro
  static final ThemeData _darkThemeData = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: _brandBlueDark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF90CAF9),
      onPrimary: Color(0xFF0D47A1),
      secondary: Color(0xFFCE93D8),
      onSecondary: Colors.black,
      surface: Color(0xFF1E1E2C),
      onSurface: Color(0xFFE8EAF6),
      surfaceContainerHighest: Color(0xFF2A2A3C),
      outlineVariant: Color(0xFF3A3A4C),
      primaryContainer: Color(0xFF1A3A5C),
      onPrimaryContainer: Color(0xFFBBDEFB),
      secondaryContainer: Color(0xFF3A2A4C),
      onSecondaryContainer: Color(0xFFE1BEE7),
    ),
    scaffoldBackgroundColor: const Color(0xFF121218),
    cardColor: const Color(0xFF1E1E2C),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E2C),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E2C),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E2C),
      selectedItemColor: Color(0xFF90CAF9),
      unselectedItemColor: Colors.grey,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF90CAF9),
      foregroundColor: Colors.black,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF1A3A5C),
      selectedColor: const Color(0xFF90CAF9),
      labelStyle: const TextStyle(
        color: Color(0xFFBBDEFB),
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      secondaryLabelStyle: const TextStyle(color: Color(0xFF0D47A1)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide.none,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: const Color(0xFF2A2A3C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1E1E2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: Color(0xFFE8EAF6),
        fontWeight: FontWeight.w900,
      ),
      headlineMedium: TextStyle(
        color: Color(0xFFE8EAF6),
        fontWeight: FontWeight.w800,
      ),
      titleLarge: TextStyle(
        color: Color(0xFFE8EAF6),
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: Color(0xFFE8EAF6),
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: Color(0xFFE8EAF6)),
      bodyMedium: TextStyle(color: Color(0xFFB0BEC5)),
      labelLarge: TextStyle(
        color: Color(0xFF90A4AE),
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A3C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF90CAF9), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: Color(0xFF90A4AE)),
      hintStyle: const TextStyle(color: Color(0xFF607D8B)),
    ),
    dividerColor: const Color(0xFF3A3A4C),
  );
}
