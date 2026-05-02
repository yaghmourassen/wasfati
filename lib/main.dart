import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'generated/l10n/app_localizations.dart';
import 'controller/setting_controller.dart';
import 'controller/shopping_plan_controller.dart';
import 'view/auth_view.dart';
import 'services/user_role_service.dart';
import 'core/user_session.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Firebase init
  await Firebase.initializeApp();

  // 📢 AdMob init (IMPORTANT)
  await MobileAds.instance.initialize();

  // 👤 Load user role
  await UserRoleService().loadUserRole();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsController()),
        ChangeNotifierProvider(create: (_) => ShoppingPlanController()),
      ],
      child: const WasfatyApp(),
    ),
  );
}

class WasfatyApp extends StatelessWidget {
  const WasfatyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, controller, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          // 🌍 Language
          locale: controller.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('ar'),
          ],

          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // 🎨 Theme
          theme: ThemeData(
            useMaterial3: false,

            brightness: Brightness.light,

            primarySwatch: Colors.green,

            scaffoldBackgroundColor: const Color(0xFFF4FBF5),

            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.green,
              elevation: 0,
              foregroundColor: Colors.white,
            ),

            cardColor: Colors.white,

            dividerColor: Colors.black12,

            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.black87),
              bodyLarge: TextStyle(color: Colors.black),
            ),

            iconTheme: const IconThemeData(
              color: Colors.green,
            ),

            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          ),

          darkTheme: ThemeData(
            useMaterial3: false,
            brightness: Brightness.dark,

            primarySwatch: Colors.green,

            scaffoldBackgroundColor: const Color(0xFF121212),

            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              elevation: 0,
            ),

            cardColor: const Color(0xFF1E1E1E),

            dividerColor: Colors.white12,

            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.white70),
              bodyLarge: TextStyle(color: Colors.white),
            ),
          ),

          themeMode: controller.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,

          // 🚀 Start page
          home: const AuthView(),
        );
      },
    );
  }
}