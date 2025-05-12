//import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;

class QRcodeTab extends StatefulWidget {
  const QRcodeTab({super.key});

  @override
  State<QRcodeTab> createState() => _QRcodeTabState();
}

class _QRcodeTabState extends State<QRcodeTab> {
  String qrData = 'https://example.com';
  final TextEditingController _controller = TextEditingController();
  final GlobalKey globalKey = GlobalKey();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generateQR() {
    if (_controller.text.trim().isNotEmpty) {
      setState(() {
        qrData = _controller.text.trim();
      });
    }
  }

  Future<void> _shareQRCode() async {
    try {
      // Capture widget to image
      RenderRepaintBoundary boundary =
          globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      final pngBytes = byteData!.buffer.asUint8List();

      // Save to temporary file (required for sharing)
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/qr_code.png').create();
      await file.writeAsBytes(pngBytes);

      // Share the image file
      await Share.shareXFiles([XFile(file.path)], text: 'Here is my QR code!');
    } catch (e) {
      debugPrint('Error sharing QR: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error sharing QR code")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate QR Code')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RepaintBoundary(
              key: globalKey,
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Enter text or URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _generateQR,
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Generate'),
                ),
                ElevatedButton.icon(
                  onPressed: _shareQRCode,
                  icon: const Icon(Icons.share),
                  label: const Text('Share QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
