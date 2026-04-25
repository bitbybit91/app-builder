import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrView extends StatelessWidget {
  final String data;
  final double size;

  const QrView({
    super.key,
    required this.data,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 24,
      height: size + 24,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: size,
        gapless: true,
        backgroundColor: Colors.white,
        errorStateBuilder: (context, error) => SizedBox(
          width: size,
          height: size,
          child: const Center(
            child: Icon(Icons.error_outline, color: Colors.red, size: 40),
          ),
        ),
      ),
    );
  }
}
