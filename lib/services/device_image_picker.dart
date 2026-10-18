import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class DeviceImagePicker {
  const DeviceImagePicker();

  Future<Uint8List?> pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    return image?.readAsBytes();
  }
}
