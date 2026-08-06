// coverage:ignore-file

import 'dart:ui';

import 'package:flutter/foundation.dart';

@internal
final DEBUG_TRANSFORM_PAINT = Paint()
  ..color = Color(0xFF6F2DBD)
  ..style = .stroke
  ..strokeWidth = 0;

@internal
final DEBUG_COLLIDER_PAINT = Paint()
  ..color = Color(0xFFDC4D01)
  ..style = .stroke
  ..strokeWidth = 0;

@internal
final DEBUG_INPUT_PAINT = Paint()
  ..color = Color(0xFF1E90FF)
  ..style = .stroke
  ..strokeWidth = 0;
