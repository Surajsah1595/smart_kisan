import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'firebase_options.dart';       
import 'welcome_screen.dart';
import 'home_page.dart';
import 'user_registration.dart';
import 'localization_service.dart';
import 'notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('⚠️ Firebase initialization warning: $e');
  }

  await LocalizationService.loadLanguage();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState? of(BuildContext context) => context.findAncestorStateOfType<_MyAppState>();
  static GlobalKey<NavigatorState> get navigatorKey => _MyAppState.navigatorKey;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late LocalizationProvider _localizationProvider;
  ThemeMode _themeMode = ThemeMode.system;
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<User?>? _authSub;
  StreamSubscription? _notifSub;

  @override
  void initState() {
    super.initState();
    _localizationProvider = LocalizationProvider();
    _localizationProvider.addListener(() {
      setState(() {});
    });
    _loadThemePreference();
    _initializeNotifications();
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final theme = prefs.getString('ui_theme') ?? 'Auto Mode';
      print('📱 Loading theme from preferences: $theme');
      setState(() {
        _themeMode = _stringToThemeMode(theme);
      });
      print('✅ Theme loaded: $_themeMode');
    } catch (e) {
      print('❌ Error loading theme: $e');
    }
  }

  void _initializeNotifications() {
    // Listen for authentication state changes and attach notifications stream
    try {
      final auth = FirebaseAuth.instance;

      // If user is already signed in, attach immediately
      if (auth.currentUser != null) {
        _attachNotificationListener();
      }

      // React to future sign-ins/sign-outs
      _authSub = auth.authStateChanges().listen((user) {
        if (user != null) {
          _attachNotificationListener();
        } else {
          // user signed out - cancel notifications subscription
          _notifSub?.cancel();
          _notifSub = null;
        }
      });

      print('✓ Notifications initialization (auth watcher) set up');
    } catch (e) {
      print('❌ Error initializing notification auth watcher: $e');
    }
  }

  void _attachNotificationListener() {
    try {
      // guard against multiple attachments
      if (_notifSub != null) return;

      final service = NotificationService();
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      // Use the general notifications stream and filter locally by user id if available.
      _notifSub = service.getNotificationsStream().listen((snapshot) {
        // Filter to user-specific docs if uid present, otherwise use all docs
        final docs = uid.isNotEmpty
            ? snapshot.docs.where((d) {
                final data = d.data() as Map<String, dynamic>?;
                return data != null && (data['userId'] == uid || data['uid'] == uid);
              }).toList()
            : snapshot.docs;
        if (docs.isNotEmpty) {
          final latestData = docs.first.data() as Map<String, dynamic>?;
          if (latestData != null) {
            final title = latestData['title'] ?? 'Notification';
            final priority = (latestData['priority'] ?? 'normal').toString().toLowerCase();
            final isRead = latestData['isRead'] ?? false;
            if (!isRead && priority == 'high') {
              print('✅ New high-priority notification: $title');
              WidgetsBinding.instance.addPostFrameCallback((_) => _showNotificationSnackbar(title));
            }
          }
        }
      }, onError: (error) {
        print('❌ Notification stream error: $error');
      });
    } catch (e) {
      print('❌ Failed to attach notification listener: $e');
    }
  }

  void _showNotificationSnackbar(String title) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔔 $title'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void setTheme(String theme) {
    setState(() {
      _themeMode = _stringToThemeMode(theme);
    });
    // Persist selection
    SharedPreferences.getInstance().then((prefs) => prefs.setString('ui_theme', theme));
  }

  ThemeMode _stringToThemeMode(String theme) {
    switch (theme) {
      case 'Light Mode':
        return ThemeMode.light;
      case 'Dark Mode':
        return ThemeMode.dark;
      case 'Auto Mode':
      default:
        return ThemeMode.system;
    }
  }

  @override
  void dispose() {
    _localizationProvider.dispose();
    _authSub?.cancel();
    _notifSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Smart Kisan',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF008236),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF101727)),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF101727)),
          displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF101727)),
          headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF101727)),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF101727)),
          headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF495565)),
          titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF101727)),
          titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF495565)),
          titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF495565)),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFF354152)),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF495565)),
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFF495565)),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF008236)),
          labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF008236)),
          labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF008236)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFDCFCE7),
          elevation: 0,
          centerTitle: false,
        ),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        cardColor: Colors.white,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00A63D),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFF9FAFB)),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFF9FAFB)),
          displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFF9FAFB)),
          headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFFF9FAFB)),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFFF9FAFB)),
          headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFD1D5DC)),
          titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFFF9FAFB)),
          titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFD1D5DC)),
          titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFFD1D5DC)),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFFE5E7EB)),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFFD1D5DC)),
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFFD1D5DC)),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF00A63D)),
          labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF00A63D)),
          labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF00A63D)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
          elevation: 0,
          centerTitle: false,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1F1F1F),

      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomePage(
          isNewUser: false,
          userName: 'Farmer',
        ),
      },
    );
  }
}