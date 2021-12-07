
import 'dart:async';

import 'package:flutter/services.dart';

class ViewerModel {
  static const MethodChannel _channel = MethodChannel('viewer_model');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
