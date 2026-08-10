import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'package:plant_care/services/auth_service.dart';
import 'package:plant_care/services/language_service.dart';
import 'package:plant_care/services/notification_service.dart';
import 'package:plant_care/services/onboarding_service.dart';
import 'package:plant_care/services/subscription_service.dart';
import 'package:plant_care/services/theme_service.dart';
import 'package:plant_care/l10n/app_localizations.dart';
import 'package:plant_care/theme/botanly_theme.dart';
import 'package:plant_care/router.dart';

/// Background message handler for FCM
/// Must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('🔔 Background message: ${message.notification?.title}');
}

void main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: "assets/.env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await ThemeService.initialize();
  await LanguageService.initialize();
  await SubscriptionService.initialize();
  await OnboardingService.initialize();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize services whenever auth state changes
  FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    if (user != null) {
      AuthService.refreshAuthCookie();
      await NotificationService().initialize();
      await NotificationService().ensureFCMTokenRegistered();
      await SubscriptionService.onLogin(user.uid);
      await LanguageService.syncFromFirestore();
      await OnboardingService.onLogin(user.uid);
      Future.delayed(const Duration(seconds: 5), () {
        NotificationService().ensureFCMTokenRegistered();
      });
    }
  });

  // Run services for already-logged-in user on cold start
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    await NotificationService().initialize();
    await NotificationService().ensureFCMTokenRegistered();
    await LanguageService.syncFromFirestore();
    Future.delayed(const Duration(seconds: 5), () {
      NotificationService().ensureFCMTokenRegistered();
    });
  }

  runApp(const MyApp());
}

/// How far the app follows the system text size.
///
/// iOS steps, as a multiple of the default: xLarge 1.12, xxLarge 1.24,
/// xxxLarge 1.35, then the accessibility sizes — AX1 1.62, AX3 1.90, AX5 2.35.
/// The line between "I'd like it bigger" and "I can't see" runs right after
/// xxxLarge, and this ceiling sits just under it: every ordinary setting works
/// as asked, only the AX modes are cut.
///
/// This is a deliberate trade, not a forgotten setting. At AX5 the screens
/// stopped being readable in a different way — the hint line ate half the
/// screen, card titles cut to "Переска…", tab labels to "Г…". A size nobody can
/// operate is not accessibility either. The honest fix is layouts that reflow
/// at any size; until they do, this is the floor of the damage.
///
/// The garden dial keeps its own, stricter cap: a circle cannot grow with the
/// type at all. See `_maxTextScale` in `widgets/garden_pulse.dart`.
const double kMaxTextScale = 1.3;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lightTheme = buildBotanlyTheme();

    final darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4CAF50),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F1115),
      useMaterial3: true,
      fontFamily: GoogleFonts.lato().fontFamily,
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Color(0xFF1A1E24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF161B22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2B3240)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2B3240)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
      ),
    );

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeModeNotifier,
      builder: (context, themeMode, _) => ValueListenableBuilder<Locale>(
        valueListenable: LanguageService.localeNotifier,
        builder: (context, locale, __) => MaterialApp.router(
          title: 'Plant Care',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          locale: locale,
          supportedLocales: const [
            Locale('de'),
            Locale('en'),
            Locale('es'),
            Locale('fr'),
            Locale('ru'),
            Locale('uk'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            maxScaleFactor: kMaxTextScale,
            child: child!,
          ),
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
