import 'package:flutter/material.dart';

class AppBrandMark extends StatelessWidget {
  const AppBrandMark({this.size = 36, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Marca CoinConversion',
      child: Image.asset(
        'assets/branding/coinconversion-mark.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
