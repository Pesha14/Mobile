import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothCheckerTab extends StatefulWidget {
  const BluetoothCheckerTab({super.key});

  @override
  State<BluetoothCheckerTab> createState() => _BluetoothCheckerTabState();
}

class _BluetoothCheckerTabState extends State<BluetoothCheckerTab> {
  String bluetoothStatus = "Checking Bluetooth...";

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _listenToBluetoothState();
  }

  Future<void> _requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.location.request();
  }

  void _listenToBluetoothState() {
    FlutterBluePlus.adapterState.listen((state) {
      setState(() {
        bluetoothStatus =
            state == BluetoothAdapterState.on
                ? "Bluetooth is ON"
                : "Bluetooth is OFF";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            bluetoothStatus == "Bluetooth is ON"
                ? Icons.bluetooth
                : Icons.bluetooth_disabled,
            color:
                bluetoothStatus == "Bluetooth is ON" ? Colors.blue : Colors.red,
            size: 100,
          ),
          const SizedBox(height: 20),
          Text(bluetoothStatus, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _listenToBluetoothState,
            child: const Text("Refresh"),
          ),
        ],
      ),
    );
  }
}
