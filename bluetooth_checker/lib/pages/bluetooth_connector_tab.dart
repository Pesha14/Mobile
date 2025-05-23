import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart'
    as classic_bt;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BluetoothConnectorTab extends StatefulWidget {
  const BluetoothConnectorTab({super.key});

  @override
  State<BluetoothConnectorTab> createState() => _BluetoothConnectorTabState();
}

class _BluetoothConnectorTabState extends State<BluetoothConnectorTab>
    with SingleTickerProviderStateMixin {
  // BLE variables
  List<ble.BluetoothDevice> connectedDevices = [];
  List<ble.ScanResult> scanResults = [];
  bool isScanning = false;

  // Classic Bluetooth variables
  List<classic_bt.BluetoothDevice> classicConnectedDevices = [];
  List<classic_bt.BluetoothDiscoveryResult> classicScanResults = [];
  bool isClassicScanning = false;

  // Map to hold active BluetoothConnections for classic devices
  final Map<String, classic_bt.BluetoothConnection> classicConnections = {};

  bool autoConnect = false;
  Set<String> knownDeviceIds = {};
  final Map<String, TextEditingController> _controllers = {};

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadAutoConnectState();
    _initBluetooth();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAutoConnectState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      autoConnect = prefs.getBool('autoConnect') ?? false;
      knownDeviceIds = prefs.getStringList('knownDevices')?.toSet() ?? {};
    });
  }

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

    var adapterState = await ble.FlutterBluePlus.adapterState.first;
    if (adapterState != ble.BluetoothAdapterState.on) {
      _showMessage("Bluetooth is off. Please turn it on.");
      return;
    }

    await _getConnectedDevices();
    _listenToScanResults();
    _startScan();

    // Classic Bluetooth init
    await _getClassicConnectedDevices();
  }

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

  Future<void> _sendLabelToClassicDevice(
    classic_bt.BluetoothDevice device,
  ) async {
    final connection = classicConnections[device.address];
    if (connection == null) {
      _showMessage("Device not connected: ${device.name ?? device.address}");
      return;
    }

    try {
      final now = DateTime.now();
      final formattedDate =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final cpcl = '''
! 0 200 200 720 1
TEXT 4 0 20 40 *** PRODUCT LABEL ***
LINE 0 90 695 90 2

TEXT 0 2 20 100 Product: Premium Soap
TEXT 0 2 20 140 Price: KES 25.00
TEXT 0 2 20 180 Date: $formattedDate

TEXT 0 2 500 100 Scan to buy:
BARCODE QR 500 130 M 2 U 6
MA,https://www.kilimall.co.ke/flash-sales
ENDQR

FORM
PRINT
''';

      List<int> bytes = utf8.encode(cpcl.replaceAll('\n', '\r\n'));

      connection.output.add(Uint8List.fromList(bytes));
      await connection.output.allSent;

      _showMessage(
        "Label with QR Code sent to ${device.name ?? device.address}",
      );
    } catch (e) {
      _showMessage("Failed to send label: $e");
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // BLE methods
  Future<void> _getConnectedDevices() async {
    try {
      List<ble.BluetoothDevice> devices =
          await ble.FlutterBluePlus.connectedDevices;
      setState(() {
        connectedDevices = devices;
      });
    } catch (e) {
      _showMessage("Failed to get connected BLE devices: $e");
    }
  }

  void _listenToScanResults() {
    ble.FlutterBluePlus.scanResults.listen((results) async {
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

      await ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      setState(() {
        isScanning = false;
      });
    } catch (e) {
      _showMessage("Failed to start BLE scanning: $e");
    }
  }

  Future<void> _connectToDevice(
    ble.BluetoothDevice device, {
    bool autoTriggered = false,
  }) async {
    if (!autoTriggered) {
      final confirmed = await _showPairingDialog(
        device.name,
        device.id.toString(),
      );
      if (!confirmed) return;
    }

    _showLoadingDialog("Connecting to ${device.name}...");
    try {
      await ble.FlutterBluePlus.stopScan();
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

  Future<void> _disconnectDevice(ble.BluetoothDevice device) async {
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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

  Future<bool> _showPairingDialog(String name, String id) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text("Pair Device"),
                content: Text(
                  "Do you want to pair with ${name.isNotEmpty ? name : id}?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Pair"),
                  ),
                ],
              ),
        ) ??
        false;
  }

  // Helper method to send message to BLE device
  Future<void> _sendLabelToDevice(ble.BluetoothDevice device) async {
    try {
      final now = DateTime.now();
      final formattedDate =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final cpcl = '''
! 0 200 200 400 1
TEXT 4 0 10 30 *** PRODUCT LABEL ***
LINE 0 70 575 70 2

TEXT 0 2 10 90 Product: Premium Soap
TEXT 0 2 10 120 Price: KES 25.00
TEXT 0 2 10 150 Date: $formattedDate

TEXT 0 2 400 90 Scan to buy:
BARCODE QR 400 120 M 2 U 6
MA,https://www.kilimall.co.ke/flash-sales
ENDQR

FORM
PRINT
''';

      List<int> bytes = utf8.encode(cpcl.replaceAll('\n', '\r\n'));

      List<ble.BluetoothService> services = await device.discoverServices();
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
            _showMessage("Label with QR Code sent to ${device.name}");
            return;
          }
        }
      }

      _showMessage("No writable characteristic found for ${device.name}");
    } catch (e) {
      _showMessage("Failed to send label: $e");
    }
  }

  // Classic Bluetooth methods
  Future<void> _getClassicConnectedDevices() async {
    try {
      List<classic_bt.BluetoothDevice> devices =
          await classic_bt.FlutterBluetoothSerial.instance.getBondedDevices();
      setState(() {
        classicConnectedDevices = devices;
      });
    } catch (e) {
      _showMessage("Failed to get connected classic devices: $e");
    }
  }

  void _startClassicScan() {
    setState(() {
      isClassicScanning = true;
      classicScanResults.clear();
    });

    classic_bt.FlutterBluetoothSerial.instance
        .startDiscovery()
        .listen((r) {
          setState(() {
            if (!classicScanResults.any(
              (element) => element.device.address == r.device.address,
            )) {
              classicScanResults.add(r);
            }
          });

          if (autoConnect) {
            if (knownDeviceIds.contains(r.device.address)) {
              _connectToClassicDevice(r.device, autoTriggered: true);
            }
          }
        })
        .onDone(() {
          setState(() {
            isClassicScanning = false;
          });
        });
  }

  Future<void> _connectToClassicDevice(
    classic_bt.BluetoothDevice device, {
    bool autoTriggered = false,
  }) async {
    if (!autoTriggered) {
      final confirmed = await _showPairingDialog(
        device.name ?? '',
        device.address,
      );
      if (!confirmed) return;
    }

    _showLoadingDialog("Connecting to ${device.name ?? device.address}...");
    try {
      await classic_bt.FlutterBluetoothSerial.instance.cancelDiscovery();

      // Check if device is already bonded
      bool isBonded = false;
      List<classic_bt.BluetoothDevice> bondedDevices =
          await classic_bt.FlutterBluetoothSerial.instance.getBondedDevices();
      for (var bondedDevice in bondedDevices) {
        if (bondedDevice.address == device.address) {
          isBonded = true;
          break;
        }
      }

      if (!isBonded) {
        bool bonded =
            await classic_bt.FlutterBluetoothSerial.instance
                .bondDeviceAtAddress(device.address) ??
            false;
        if (!bonded) {
          _showMessage("Failed to bond with ${device.name ?? device.address}");
          Navigator.pop(context);
          return;
        }
        knownDeviceIds.add(device.address);
        await _saveKnownDevices();
      }

      await _getClassicConnectedDevices();

      // Establish BluetoothConnection and store it
      final connection = await classic_bt.BluetoothConnection.toAddress(
        device.address,
      );
      classicConnections[device.address] = connection;

      Navigator.pop(context);
      _showMessage("Connected to ${device.name ?? device.address}");
    } catch (e) {
      Navigator.pop(context);
      _showMessage("Error connecting to ${device.name ?? device.address}: $e");
    }
  }

  Future<void> _disconnectClassicDevice(
    classic_bt.BluetoothDevice device,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Disconnect Device"),
            content: Text(
              "Are you sure you want to disconnect from ${device.name ?? device.address}?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Disconnect"),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      bool unbonded =
          await classic_bt.FlutterBluetoothSerial.instance
              .removeDeviceBondWithAddress(device.address) ??
          false;
      if (unbonded) {
        knownDeviceIds.remove(device.address);
        await _saveKnownDevices();
        _showMessage("Disconnected from ${device.name ?? device.address}");
        await _getClassicConnectedDevices();
        // Close and remove the BluetoothConnection if exists
        if (classicConnections.containsKey(device.address)) {
          await classicConnections[device.address]?.close();
          classicConnections.remove(device.address);
        }
      } else {
        _showMessage(
          "Failed to disconnect from ${device.name ?? device.address}",
        );
      }
    } catch (e) {
      _showMessage("Error disconnecting: $e");
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
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: Icon(icon, color: Colors.indigo),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.indigo,
          ),
        ),
        subtitle:
            subtitle != null
                ? Text(
                  subtitle,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                )
                : null,
        trailing: action,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.shade100,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: "BLE Devices"),
              Tab(text: "Classic Devices"),
            ],
            labelColor: Colors.indigo,
            unselectedLabelColor: Colors.black54,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(width: 3.0, color: Colors.indigo),
            ),
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  await _getConnectedDevices();
                  if (!isScanning) _startScan();
                },
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Nearby BLE Devices",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.indigo,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: isScanning ? null : _startScan,
                          icon: const Icon(Icons.search),
                          label: Text(isScanning ? "Scanning..." : "Scan"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          "Auto-connect known devices",
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: autoConnect,
                          onChanged: _toggleAutoConnect,
                          activeColor: Colors.indigo,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (scanResults.isEmpty)
                      const Text(
                        "No BLE devices found yet. Tap Scan to start.",
                        style: TextStyle(fontSize: 16),
                      ),
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Connect"),
                        ),
                      ),
                    ),
                    const Divider(height: 40, thickness: 1),
                    const Text(
                      "Connected BLE Devices",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (connectedDevices.isEmpty)
                      const Text(
                        "No BLE devices currently connected.",
                        style: TextStyle(fontSize: 16),
                      ),
                    ...connectedDevices.map(
                      (device) => _buildDeviceCard(
                        icon: Icons.bluetooth_connected,
                        title:
                            device.name.isNotEmpty
                                ? device.name
                                : device.id.toString(),
                        action: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.receipt),
                              tooltip: "Send Receipt",
                              color: Colors.indigo,
                              onPressed: () => _sendLabelToDevice(device),
                            ),
                            IconButton(
                              icon: const Icon(Icons.link_off),
                              tooltip: "Disconnect",
                              color: Colors.redAccent,
                              onPressed: () => _disconnectDevice(device),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              RefreshIndicator(
                onRefresh: () async {
                  await _getClassicConnectedDevices();
                  if (!isClassicScanning) _startClassicScan();
                },
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Nearby Classic Bluetooth Devices",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.indigo,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed:
                              isClassicScanning ? null : _startClassicScan,
                          icon: const Icon(Icons.search),
                          label: Text(
                            isClassicScanning ? "Scanning..." : "Scan",
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          "Auto-connect known devices",
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: autoConnect,
                          onChanged: _toggleAutoConnect,
                          activeColor: Colors.indigo,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (classicScanResults.isEmpty)
                      const Text(
                        "No classic devices found yet. Tap Scan to start.",
                        style: TextStyle(fontSize: 16),
                      ),
                    ...classicScanResults.map(
                      (r) => _buildDeviceCard(
                        icon: Icons.bluetooth,
                        title: r.device.name ?? r.device.address,
                        subtitle: "Address: ${r.device.address}",
                        action: ElevatedButton(
                          onPressed: () => _connectToClassicDevice(r.device),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Connect"),
                        ),
                      ),
                    ),
                    const Divider(height: 40, thickness: 1),
                    const Text(
                      "Connected Classic Bluetooth Devices",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (classicConnectedDevices.isEmpty)
                      const Text(
                        "No classic devices currently connected.",
                        style: TextStyle(fontSize: 16),
                      ),
                    ...classicConnectedDevices.map(
                      (device) => _buildDeviceCard(
                        icon: Icons.bluetooth_connected,
                        title: device.name ?? device.address,
                        action: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.print),
                              tooltip: "Print Label",
                              color: Colors.indigo,
                              onPressed:
                                  () => _sendLabelToClassicDevice(device),
                            ),
                            IconButton(
                              icon: const Icon(Icons.link_off),
                              tooltip: "Disconnect",
                              color: Colors.redAccent,
                              onPressed: () => _disconnectClassicDevice(device),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
