import 'package:flutter/material.dart';
import 'pages/home_tab.dart';
import 'pages/bluetooth_checker_tab.dart';
import 'pages/bluetooth_connector_tab.dart';
import 'pages/QR_code.dart';
import 'widgets/app_drawer.dart';

void main() {
  runApp(const BluetoothCheckerApp());
}

class BluetoothCheckerApp extends StatelessWidget {
  const BluetoothCheckerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData.light();
    return MaterialApp(
      title: 'Bluetooth Checker App',
      theme: baseTheme.copyWith(
        colorScheme: baseTheme.colorScheme.copyWith(
          primary: Colors.indigo,
          secondary: Colors.indigoAccent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 4,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        textTheme: baseTheme.textTheme.copyWith(
          titleLarge: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.indigo,
          ),
          bodyMedium: const TextStyle(fontSize: 16, color: Colors.black87),
          titleMedium: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: Colors.indigo,
          unselectedLabelColor: Colors.black54,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(width: 3.0, color: Colors.indigo),
          ),
          labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          unselectedLabelStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

enum DrawerSection { home, bluetoothChecker, bluetoothConnector, QRcode }

class _MainPageState extends State<MainPage> {
  DrawerSection currentSection = DrawerSection.home;

  @override
  Widget build(BuildContext context) {
    Widget content;

    switch (currentSection) {
      case DrawerSection.home:
        content = const HomeTab();
        break;
      case DrawerSection.bluetoothChecker:
        content = const BluetoothCheckerTab();
        break;
      case DrawerSection.bluetoothConnector:
        content = const BluetoothConnectorTab();
        break;
      case DrawerSection.QRcode:
        content = const QRcodeTab();
        break;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Bluetooth Checker App')),
      drawer: AppDrawer(
        onSectionSelected: (section) {
          setState(() {
            currentSection = section;
          });
          Navigator.pop(context);
        },
      ),
      body: content,
    );
  }
}
