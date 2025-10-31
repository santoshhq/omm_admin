import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({Key? key}) : super(key: key);

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = true;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    // Allow going back to visitor management page
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan QR Code',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF455A64),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.camera_rear, color: Colors.white),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (!_isScanning) return;

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                setState(() => _isScanning = false);

                final String code = barcodes.first.rawValue!;
                debugPrint('QR Code scanned: $code');

                // Return the scanned code to the previous page
                Navigator.of(context).pop(code);
              }
            },
          ),
          // Overlay with scan area
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: const Color(0xFF455A64),
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: MediaQuery.of(context).size.width * 0.8,
              ),
            ),
          ),
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Text(
                    'Scan Visitor QR Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Position the QR code within the frame to scan',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
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

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 2.0,
    this.borderRadius = 0,
    this.borderLength = 20,
    required this.cutOutSize,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path();
    path.fillType = PathFillType.evenOdd;
    path.addRect(rect);

    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );

    path.addRRect(
      RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
    );

    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );

    canvas.drawRect(rect, backgroundPaint);

    // Draw the cut-out area (transparent)
    canvas.drawRRect(
      RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
      Paint()..blendMode = BlendMode.clear,
    );

    // Draw border corners
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.square;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left + borderRadius, cutOutRect.top)
        ..lineTo(cutOutRect.left + borderRadius + borderLength, cutOutRect.top)
        ..moveTo(cutOutRect.left, cutOutRect.top + borderRadius)
        ..lineTo(cutOutRect.left, cutOutRect.top + borderRadius + borderLength),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.right - borderRadius - borderLength, cutOutRect.top)
        ..lineTo(cutOutRect.right - borderRadius, cutOutRect.top)
        ..moveTo(cutOutRect.right, cutOutRect.top + borderRadius)
        ..lineTo(
          cutOutRect.right,
          cutOutRect.top + borderRadius + borderLength,
        ),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left + borderRadius, cutOutRect.bottom)
        ..lineTo(
          cutOutRect.left + borderRadius + borderLength,
          cutOutRect.bottom,
        )
        ..moveTo(
          cutOutRect.left,
          cutOutRect.bottom - borderRadius - borderLength,
        )
        ..lineTo(cutOutRect.left, cutOutRect.bottom - borderRadius),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(
          cutOutRect.right - borderRadius - borderLength,
          cutOutRect.bottom,
        )
        ..lineTo(cutOutRect.right - borderRadius, cutOutRect.bottom)
        ..moveTo(
          cutOutRect.right,
          cutOutRect.bottom - borderRadius - borderLength,
        )
        ..lineTo(cutOutRect.right, cutOutRect.bottom - borderRadius),
      cornerPaint,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QrScannerOverlayShape &&
          runtimeType == other.runtimeType &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          borderRadius == other.borderRadius &&
          borderLength == other.borderLength &&
          cutOutSize == other.cutOutSize;

  @override
  int get hashCode =>
      borderColor.hashCode ^
      borderWidth.hashCode ^
      borderRadius.hashCode ^
      borderLength.hashCode ^
      cutOutSize.hashCode;

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      borderRadius: borderRadius * t,
      borderLength: borderLength * t,
      cutOutSize: cutOutSize * t,
    );
  }

  @override
  String toString() =>
      'QrScannerOverlayShape(borderColor: $borderColor, borderWidth: $borderWidth, borderRadius: $borderRadius, borderLength: $borderLength, cutOutSize: $cutOutSize)';
}
