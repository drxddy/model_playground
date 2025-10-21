import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:okara_chat/screens/chat_screen.dart';
import 'package:okara_chat/utils/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _bootstrap(() {
    runApp(const ProviderScope(child: MyApp()));
  });
}

Future<void> _bootstrap(void Function() runner) async {

  try {
    setStatusBarColor();
    setPreferredOrientation();
    setNavigationBarTheme(Color(0xFF2286D4), true);
    setTransparentStatus();
  } catch (err) {
    print('Error occurred while setting up the app: $err');
  } finally {
    runner();
  }
}

void setTransparentStatus() {
  const SystemUiOverlayStyle(statusBarColor: Colors.transparent);
}

void setNavigationBarTheme(Color color, bool isDark) {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      systemNavigationBarColor: color,
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
    ),
  );
}

void setPreferredOrientation() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

void setStatusBarColor() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      statusBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarColor: Colors.black.withOpacity(0.002),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Okara Playground',
      theme: AppTheme.themeData,
      home: const ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
