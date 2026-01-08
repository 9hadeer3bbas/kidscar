import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;

/// Utility class for creating modern custom markers for maps
class MarkerUtils {
  static BitmapDescriptor? _pickupMarker;
  static BitmapDescriptor? _dropoffMarker;
  static BitmapDescriptor? _driverMarker;
  static BitmapDescriptor? _kidMarker;

  /// Initialize all marker icons (call this once at app startup)
  static Future<void> initializeMarkers() async {
    _pickupMarker = await _createCustomMarker(
      icon: Icons.location_on,
      color: Colors.green,
      size: 120,
    );
    _dropoffMarker = await _createCustomMarker(
      icon: Icons.flag,
      color: Colors.red,
      size: 120,
    );
    _driverMarker = await _createCustomMarker(
      icon: Icons.directions_car,
      color: Colors.blue,
      size: 120,
    );
    _kidMarker = await _createCustomMarker(
      icon: Icons.child_care,
      color: Colors.orange,
      size: 100,
    );
  }

  /// Creates a custom marker icon with a colored circle and icon
  static Future<BitmapDescriptor> _createCustomMarker({
    required IconData icon,
    required Color color,
    required double size,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = color;

    // Draw outer shadow circle
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 2, shadowPaint);

    // Draw main circle
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 8, paint);

    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 8, borderPaint);

    // Draw icon
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size * 0.4,
          fontFamily: icon.fontFamily,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2 - size * 0.05,
      ),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  /// Gets the pickup marker icon
  static BitmapDescriptor getPickupMarker() {
    return _pickupMarker ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  }

  /// Gets the dropoff marker icon
  static BitmapDescriptor getDropoffMarker() {
    return _dropoffMarker ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  }

  /// Gets the driver marker icon
  static BitmapDescriptor getDriverMarker() {
    return _driverMarker ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
  }

  /// Gets the kid marker icon
  static BitmapDescriptor getKidMarker() {
    return _kidMarker ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
  }

  /// Creates a safety event marker with custom color
  static Future<BitmapDescriptor> createSafetyEventMarker({
    required Color color,
  }) async {
    return _createCustomMarker(icon: Icons.warning, color: color, size: 100);
  }
}
