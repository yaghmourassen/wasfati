import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'view/auth_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const WasfatyApp());
}

class WasfatyApp extends StatelessWidget {
  const WasfatyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthView(),
    );
  }
}
