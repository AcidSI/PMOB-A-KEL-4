import 'dart:typed_data';

import 'package:flutter/services.dart';

const _channel = MethodChannel('findit/device_image_picker');

Future<Uint8List?> pickImage() => _channel.invokeMethod<Uint8List>('pickImage');
