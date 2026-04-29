import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wasfati_fb/generated/l10n/app_localizations.dart';

import 'controller/setting_controller.dart';
import 'controller/shopping_plan_controller.dart';
import 'view/auth_view.dart';

import 'services/user_role_service.dart';
import 'core/user_session.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 🔥 LOAD USER ROLE AT START
  await UserRoleService().loadUserRole();

  // Debug (optional)
  print("ROLE = ${UserSession.role}");
  print("IS ADMIN = ${UserSession.isAdmin}");

  runApp(
    MultiProvider(
      providers: [

        ChangeNotifierProvider(
          create: (_) => SettingsController(),
        ),

        ChangeNotifierProvider(
          create: (_) => ShoppingPlanController(),
        ),
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

          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF4FBF5),
            colorScheme: const ColorScheme.light(primary: Colors.green),
          ),

          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0F1B12),
            colorScheme: const ColorScheme.dark(primary: Colors.green),
          ),

          themeMode: controller.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,

          home: const AuthView(),
        );
      },
    );
  }
}