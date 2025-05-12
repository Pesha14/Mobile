import 'package:flutter/material.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_connected,
              size: 100,
              color: Colors.blue.shade700,
            ),
            const SizedBox(height: 20),
            const Text(
              'Welcome to Bluetooth Connect',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Easily check Bluetooth status, discover nearby devices, and connect with them seamlessly.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: const Column(
                  children: [
                    Icon(Icons.info_outline, size: 40, color: Colors.blueGrey),
                    SizedBox(height: 10),
                    Text(
                      'To get started:\n\n'
                      '1. Use the "Bluetooth Checker" tab to verify Bluetooth and Location settings.\n'
                      '2. Explore and connect to available Bluetooth devices.\n'
                      '3. Use the "Bluetooth Connector" tab to manage connected devices.',
                      style: TextStyle(fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Tip: Ensure Bluetooth and Location permissions are enabled for full functionality.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to Bluetooth Checker tab (you can update this to your tab navigation logic)
                // Example:
                // DefaultTabController.of(context).animateTo(1);
              },
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('Get Started'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
