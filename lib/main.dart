import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/gesture_recognition_service.dart';
import 'services/database_service.dart';
import 'services/chat_service.dart';
import 'services/speech_service.dart';
import 'services/theme_service.dart';
import 'services/localization_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize services
  await GestureRecognitionService.instance.initialize();
  await DatabaseService.instance.initialize();
  await LocalizationService.instance.initialize();
  
  runApp(const JodoApp());
}

class JodoApp extends StatelessWidget {
  const JodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => LocalizationService.instance),
        ChangeNotifierProvider(create: (_) => ChatService()),
      ],
      child: Consumer2<ThemeService, LocalizationService>(
        builder: (context, themeService, localizationService, child) {
          return MaterialApp(
            title: 'Jodo - Sign Language Bridge',
            debugShowCheckedModeBanner: false,
            theme: themeService.lightTheme,
            darkTheme: themeService.darkTheme,
            themeMode: themeService.themeMode,
            locale: localizationService.currentLocale,
            supportedLocales: localizationService.supportedLocales,
            home: Consumer<AuthService>(
              builder: (context, authService, _) {
                if (authService.isInitializing) {
                  return const SplashScreen();
                }
                
                if (authService.currentUser == null) {
                  return const AuthGate();
                } else {
                  return const MainScreen();
                }
              },
            ),
          );
        },
      ),
    );
  }
}

// Constants
class AppConstants {
  static const Color kPrimaryBlue = Color(0xFF2C64C6);
  static const Color kPurpleDark = Color(0xFF4A148C);
  static const Color kPurpleLight = Color(0xFF7C4DFF);
  static const Color kGreenAccent = Color(0xFF4CAF50);
  static const Color kFeaturedGold = Color(0xFFFFC107);
  static const Color kBackgroundGrey = Color(0xFFF5F7FA);
  static const Color kTextDark = Color(0xFF333333);
  static const Color kTextLight = Color(0xFF757575);
  
  // Gesture labels
  static const List<String> gestureLabels = [
    'thumbs_up',
    'peace',
    'okay',
    'stop',
    'fist',
    'open_palm',
    'point_up',
    'point_down',
    'wave',
    'clap'
  ];
  
  // XP Points
  static const int xpPerSign = 10;
  static const int xpPerLesson = 50;
  static const int xpPerStreak = 5;
}