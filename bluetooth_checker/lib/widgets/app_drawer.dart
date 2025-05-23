import 'package:flutter/material.dart';
import '../main.dart';

class AppDrawer extends StatelessWidget {
  final Function(DrawerSection) onSectionSelected;

  const AppDrawer({super.key, required this.onSectionSelected});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade700, Colors.indigo.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                "Bluetooth Checker",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.home,
            text: "Home",
            onTap: () => onSectionSelected(DrawerSection.home),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.bluetooth,
            text: "Bluetooth Checker",
            onTap: () => onSectionSelected(DrawerSection.bluetoothChecker),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.bluetooth_connected,
            text: "Bluetooth Connector",
            onTap: () => onSectionSelected(DrawerSection.bluetoothConnector),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.qr_code,
            text: "QR Code",
            onTap: () => onSectionSelected(DrawerSection.QRcode),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.indigo),
      title: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      hoverColor: Colors.indigo.shade50,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
