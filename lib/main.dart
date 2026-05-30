import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // ✅ NEW
import 'package:flutter_localizations/flutter_localizations.dart'; // ✅ NEW
import 'l10n/app_localizations.dart'; // ✅ NEW
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'services/language_service.dart'; // ✅ NEW
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Notification setup
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.init();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final languageService = LanguageService();
  await languageService.loadLanguage();

  runApp(
    ChangeNotifierProvider.value(
      value: languageService,
      child: const HopeDropApp(),
    ),
  );
}

class HopeDropApp extends StatelessWidget {
  const HopeDropApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ NEW — Listen to language changes
    final languageService = Provider.of<LanguageService>(context);

    return MaterialApp(
      title: 'HopeDrop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // ✅ NEW — Language settings
      locale: languageService.currentLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('si'), // Sinhala
        Locale('ta'), // Tamil
      ],

      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          // Already logged in → go straight to Home
          if (snapshot.hasData && snapshot.data != null) {
            return const HomeScreen();
          }
          // Not logged in → Splash → Onboarding → Login
          return const SplashScreen();
        },
      ),
    );
  }
}
