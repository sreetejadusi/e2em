// ignore_for_file: unnecessary_import

import 'dart:ui';

import 'package:flutter/material.dart';

InputBorder linedBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(8),
  borderSide: const BorderSide(color: Color(0xFF2a2a2a), width: 1.5),
);
InputBorder linedEnabledBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(8),
  borderSide: const BorderSide(color: Color(0xFF2a2a2a), width: 1.5),
);
InputBorder linedFocusedBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(8),
  borderSide: const BorderSide(color: Color(0xFF2a2a2a), width: 1.5),
);
InputBorder linedErrorBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(8),
  borderSide: const BorderSide(color: Colors.red, width: 1.5),
);
TextStyle linedLabelStyle =
    const TextStyle(color: Color(0xFF2a2a2a), fontWeight: FontWeight.w300);

///
InputBorder border = OutlineInputBorder(
  borderRadius: BorderRadius.circular(8),
  borderSide: const BorderSide(color: Colors.black, width: 1),
);
InputBorder enabledBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(8),
  borderSide: const BorderSide(color: Colors.black, width: 1),
);
InputBorder focusedBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(8),
  borderSide: const BorderSide(color: Colors.black, width: 1),
);
InputBorder errorBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(8),
  borderSide: const BorderSide(color: Colors.black, width: 1),
);
TextStyle labelStyle =
    TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w300);
