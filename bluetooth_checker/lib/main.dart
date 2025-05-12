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
    return MaterialApp(
      title: 'Bluetooth Checker App',
      theme: ThemeData(primarySwatch: Colors.blue),
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
