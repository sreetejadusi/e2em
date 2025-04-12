// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

// ignore: unused_import
import 'package:flutter/cupertino.dart';

Uint8List alpha_to_UInt8List(String string) {
  String as = string;
  List<int> codes = as.codeUnits;
  Uint8List data = Uint8List(codes.length);
  for (int i = 0; i < codes.length; i++) {
    data[i] = codes[i];
  }
  return data;
}
