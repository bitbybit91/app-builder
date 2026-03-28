import 'package:flutter/material.dart';
import 'package:capitalmonero_app/config/app_theme.dart';
import 'package:capitalmonero_app/config/constants.dart';

class CryptoIcon extends StatelessWidget {
  final String crypto;
  final double size;

  const CryptoIcon({
    super.key,
    required this.crypto,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final isBtc = crypto.toUpperCase() == CryptoCurrencies.btc;
    final label = isBtc ? '₿' : 'ɱ';
    final color = isBtc ? Colors.orange : AppColors.moneroOrange;

    return CircleAvatar(
      radius: size,
      backgroundColor: color,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
