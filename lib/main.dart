import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // Import the new home screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Traffic Image App',
      theme: ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: Colors.white,
          onPrimary: Colors.black,       // Text/icons on primary
          secondary: Colors.white,
          onSecondary: Colors.black,     // Text/icons on secondary
          surface: Colors.white,
          onSurface: Colors.black,       // Text/icons on surface
          error: Colors.red,
          onError: Colors.white,
        ),
      ),
      home: const MyHomePage(title: 'Traffic Image App Home Page'),
    );
  }
}
