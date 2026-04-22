import 'package:image_picker/image_picker.dart';

class RobotCameraHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> captureImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      return image?.path;
    } catch (e) {
      print("Camera error: $e");
      return null;
    }
  }
}
