class MyBluetoothDevice {
  final String name;
  final String id;
  final int? rssi;
  final bool isConnected;

  MyBluetoothDevice({
    required this.name,
    required this.id,
    this.rssi,
    this.isConnected = false,
  });
}
