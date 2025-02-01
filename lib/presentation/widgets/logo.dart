import 'package:flutter/material.dart';

class Logo extends StatelessWidget {
  const Logo({super.key, this.width = null});
  final double? width;
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Image.asset(
      'assets/appbar_logo.png',
      width: width??w * 0.6,
    );
  }
}
