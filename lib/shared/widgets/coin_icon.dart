import 'package:flutter/material.dart';

class CoinIcon extends StatelessWidget {
  final String coinType;
  final double size;

  const CoinIcon({super.key, required this.coinType, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: coinType == 'XMR' ? Colors.orange : Colors.amber,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          coinType == 'XMR' ? 'ɱ' : '₿',
          style: TextStyle(color: Colors.white, fontSize: size * 0.6, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
