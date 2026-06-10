import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // Dark mode gradient: 80% black to 20% amber, diagonal from top-left to bottom-right
  Gradient get darkModeGradient {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.black87,
        Colors.black87.withValues(alpha: 0.98),
        Color.lerp(Colors.black87, Colors.amber, 0.15)!,
        Color.lerp(Colors.black87, Colors.amber, 0.20)!,
      ],
      stops: const [0.0, 0.6, 0.8, 1.0],
    );
  }

  // Dark grey color for boxes (not too dark)
  Color get darkGreyBoxColor => const Color(0xFF2A2A2A);

  // Dark grey border color
  Color get darkGreyBorder => const Color(0xFF3A3A3A);

  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.black87,
      primaryColor: Colors.black87,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.amber,
        brightness: Brightness.dark,
      ),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: Colors.white70,
        displayColor: Colors.white,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkGreyBoxColor,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(color: Colors.white70),
      ),
    );
  }
}

// Global theme provider instance
final themeProvider = ThemeProvider();


// --- GLOBAL THEME CONSTANTS 🚀 ---



const kAppBarColor = Colors.black87;
const kAppBarIconColor = Colors.amber;
const kAppBarLogoColor = Colors.white;
const kTextColorOnBlack = Colors.white;

Color gpBrownText(BuildContext context, {Color darkColor = Colors.white70}) {
  return themeProvider.isDarkMode ? darkColor : Colors.brown;
}
