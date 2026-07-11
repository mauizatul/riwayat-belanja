import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

SystemUiOverlayStyle overlayStyle(Color backgroundColor) {
  return ThemeData.estimateBrightnessForColor(backgroundColor) ==
          Brightness.dark
      ? SystemUiOverlayStyle.light
      : SystemUiOverlayStyle.dark;
}
