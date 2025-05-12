import 'dart:convert';

//import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'dart:convert';

//import 'package:image/image.dart' as img;
//import 'package:qr_flutter/qr_flutter.dart';
//import 'dart:ui' as ui;
//import 'dart:typed_data';

class BluetoothConnectorTab extends StatefulWidget {
  const BluetoothConnectorTab({super.key});

  @override
  State<BluetoothConnectorTab> createState() => _BluetoothConnectorTabState();
}

class _BluetoothConnectorTabState extends State<BluetoothConnectorTab> {
  List<BluetoothDevice> connectedDevices = [];
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  bool autoConnect = false;
  Set<String> knownDeviceIds = {};
  // ignore: unused_field
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadAutoConnectState();
    _initBluetooth();
  }

  Future<void> _loadAutoConnectState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      autoConnect = prefs.getBool('autoConnect') ?? false;
      knownDeviceIds = prefs.getStringList('knownDevices')?.toSet() ?? {};
    });
  }

  // saving the connected devices
  Future<void> _saveKnownDevices() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('knownDevices', knownDeviceIds.toList());
  }

  Future<void> _toggleAutoConnect(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoConnect', value);
    setState(() {
      autoConnect = value;
    });
  }

  Future<void> _initBluetooth() async {
    await _requestPermissions();

    var adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      _showMessage("Bluetooth is off. Please turn it on.");
      return;
    }

    await _getConnectedDevices();
    _listenToScanResults();
    _startScan();
  }

  // for permissions
  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses =
        await [
          Permission.bluetooth,
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.locationWhenInUse,
        ].request();

    if (statuses.values.any((status) => status.isDenied)) {
      _showMessage("Please grant all permissions for Bluetooth to work.");
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _getConnectedDevices() async {
    try {
      List<BluetoothDevice> devices = FlutterBluePlus.connectedDevices;
      setState(() {
        connectedDevices = devices;
      });
    } catch (e) {
      _showMessage("Failed to get connected devices: $e");
    }
  }

  void _listenToScanResults() {
    FlutterBluePlus.scanResults.listen((results) async {
      setState(() {
        scanResults = results;
      });

      if (autoConnect) {
        for (var result in results) {
          if (knownDeviceIds.contains(result.device.id.toString())) {
            _connectToDevice(result.device, autoTriggered: true);
          }
        }
      }
    });
  }

  void _startScan() async {
    try {
      setState(() {
        isScanning = true;
        scanResults.clear();
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      setState(() {
        isScanning = false;
      });
    } catch (e) {
      _showMessage("Failed to start scanning: $e");
    }
  }

  Future<void> _connectToDevice(
    BluetoothDevice device, {
    bool autoTriggered = false,
  }) async {
    if (!autoTriggered) {
      final confirmed = await _showPairingDialog(device);
      if (!confirmed) return;
    }

    _showLoadingDialog("Connecting to ${device.name}...");
    try {
      await FlutterBluePlus.stopScan();
      await device.connect(timeout: const Duration(seconds: 15));
      knownDeviceIds.add(device.id.toString());
      await _saveKnownDevices();
      await _getConnectedDevices();
      Navigator.pop(context);
      _showMessage("Connected to ${device.name}");
    } catch (e) {
      Navigator.pop(context);
      _showMessage("Error connecting to ${device.name}: $e");
    }
  }

  Future<void> _disconnectDevice(BluetoothDevice device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Disconnect Device"),
            content: Text(
              "Are you sure you want to disconnect from ${device.name}?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Disconnect"),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      await device.disconnect();
      knownDeviceIds.remove(device.id.toString());
      await _saveKnownDevices();
      _showMessage("Disconnected from ${device.name}");
      await _getConnectedDevices();
    } catch (e) {
      _showMessage("Error disconnecting: $e");
    }
  }

  Future<bool> _showPairingDialog(BluetoothDevice device) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text("Pair Device"),
                content: Text(
                  "Do you want to pair with ${device.name.isNotEmpty ? device.name : device.id}?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Pair"),
                  ),
                ],
              ),
        ) ??
        false;
  }

  //Helper method to send message:
  Future<void> _sendReceiptToDevice(BluetoothDevice device) async {
    try {
      final now = DateTime.now();
      final formattedDate =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} "
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      // CPCL Receipt Template
      final cpcl = '''
! 0 200 200 750 1
CENTER
TEXT 4 0 0 30 Thank you for your purchase!
LINE 0 70 600 70 2

LEFT
TEXT 0 0 10 90 Item: Sample
TEXT 0 0 10 120 Qty: 1
TEXT 0 0 200 120 Price: 100

LINE 0 150 600 150 1

TEXT 0 0 10 170 Total: 100
TEXT 0 0 10 200 Payment: Cash
TEXT 0 0 10 230 Date: $formattedDate

LINE 0 260 600 260 1

CENTER
TEXT 0 0 0 280 Visit Again!
TEXT 0 0 0 310 Scan to view online:
BARCODE QR 150 340 M 2 U 6
MA,https://charming-valkyrie-c973ce.netlify.app/
ENDQR

FORM
PRINT
''';

      List<int> bytes = utf8.encode(cpcl.replaceAll('\n', '\r\n'));

      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            const chunkSize = 20;
            for (var i = 0; i < bytes.length; i += chunkSize) {
              final chunk = bytes.sublist(
                i,
                i + chunkSize > bytes.length ? bytes.length : i + chunkSize,
              );
              await characteristic.write(chunk, withoutResponse: true);
              await Future.delayed(const Duration(milliseconds: 20));
            }
            _showMessage("Receipt and QR Code sent to ${device.name}");
            return;
          }
        }
      }

      _showMessage("No writable characteristic found for ${device.name}");
    } catch (e) {
      _showMessage("Failed to send receipt: $e");
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Expanded(child: Text(message)),
              ],
            ),
          ),
    );
  }

  Widget _buildDeviceCard({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? action,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: action,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _getConnectedDevices();
        if (!isScanning) _startScan();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Nearby Devices",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              ElevatedButton.icon(
                onPressed: isScanning ? null : _startScan,
                icon: const Icon(Icons.search),
                label: Text(isScanning ? "Scanning..." : "Scan"),
              ),
            ],
          ),
          Row(
            children: [
              const Text("Auto-connect known devices"),
              const SizedBox(width: 8),
              Switch(value: autoConnect, onChanged: _toggleAutoConnect),
            ],
          ),
          const SizedBox(height: 10),
          if (scanResults.isEmpty)
            const Text("No devices found yet. Tap Scan to start."),
          ...scanResults.map(
            (r) => _buildDeviceCard(
              icon: Icons.bluetooth,
              title:
                  r.device.name.isNotEmpty
                      ? r.device.name
                      : r.device.id.toString(),
              subtitle: "Signal: ${r.rssi} dBm",
              action: ElevatedButton(
                onPressed: () => _connectToDevice(r.device),
                child: const Text("Connect"),
              ),
            ),
          ),
          const Divider(height: 30, thickness: 1),
          const Text(
            "Connected Devices",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          if (connectedDevices.isEmpty)
            const Text("No devices currently connected."),
          ...connectedDevices.map(
            (device) => _buildDeviceCard(
              icon: Icons.bluetooth_connected,
              title:
                  device.name.isNotEmpty ? device.name : device.id.toString(),
              action: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.receipt),
                    tooltip: "Send Receipt",
                    onPressed: () => _sendReceiptToDevice(device),
                  ),
                  IconButton(
                    icon: const Icon(Icons.link_off),
                    tooltip: "Disconnect",
                    onPressed: () => _disconnectDevice(device),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
