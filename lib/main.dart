import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'controller/setting_controller.dart';
import 'view/auth_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsController(),
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

          // ================= THEME SYSTEM =================
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF4FBF5),
            colorScheme: ColorScheme.light(
              primary: Colors.green,
            ),
          ),

          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0F1B12),
            colorScheme: ColorScheme.dark(
              primary: Colors.green,
            ),
          ),

          themeMode: controller.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,

          // ================= START APP =================
          home: const AuthView(),
        );
      },
    );
  }
}