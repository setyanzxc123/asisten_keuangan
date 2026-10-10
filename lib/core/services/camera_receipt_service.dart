import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class CameraReceiptService {
  ImagePicker? _picker;

  CameraReceiptService({ImagePicker? picker}) {
    if (picker != null) {
      _picker = picker;
    }
  }

  ImagePicker _resolvePicker() {
    _picker ??= ImagePicker();
    return _picker!;
  }

  Future<String?> captureReceiptFromCamera({
    double maxWidth = 1600,
    int imageQuality = 85,
  }) async {
    try {
      final picker = _resolvePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth,
        imageQuality: imageQuality,
      );
      return photo?.path;
    } catch (_) {
      return null;
    }
  }

  Future<String?> pickReceiptFromGallery({
    double maxWidth = 1600,
    int imageQuality = 85,
  }) async {
    try {
      final picker = _resolvePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        imageQuality: imageQuality,
      );
      return image?.path;
    } catch (_) {
      return null;
    }
  }
}

final cameraReceiptServiceProvider = Provider<CameraReceiptService>((ref) {
  return CameraReceiptService();
});
