import 'package:flutter/material.dart';
import '../main.dart';

class AppDrawer extends StatelessWidget {
  final Function(DrawerSection) onSectionSelected;

  const AppDrawer({super.key, required this.onSectionSelected});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              "Menu",
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Home"),
            onTap: () => onSectionSelected(DrawerSection.home),
          ),
          ListTile(
            leading: const Icon(Icons.bluetooth),
            title: const Text("Bluetooth Checker"),
            onTap: () => onSectionSelected(DrawerSection.bluetoothChecker),
          ),
          ListTile(
            leading: const Icon(Icons.bluetooth_connected),
            title: const Text("Bluetooth Connector"),
            onTap: () => onSectionSelected(DrawerSection.bluetoothConnector),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code),
            title: const Text("QR Code"),
            onTap: () => onSectionSelected(DrawerSection.QRcode),
          ),
        ],
      ),
    );
  }
}
