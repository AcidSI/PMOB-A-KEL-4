import 'dart:typed_data';

import 'device_image_picker_native.dart'
    if (dart.library.html) 'device_image_picker_web.dart'
    as platform;

class DeviceImagePicker {
  const DeviceImagePicker();

  Future<Uint8List?> pickImage() => platform.pickImage();
}
