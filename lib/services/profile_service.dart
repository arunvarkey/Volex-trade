import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../core/app_logger.dart';

/// Manages user profile operations, primarily profile image handling.
///
/// Handles:
/// *   Image picking (Camera/Gallery).
/// *   Image compression (using [FlutterImageCompress]).
/// *   Local state management for profile UI.
class ProfileService extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();

  File? _profileImage;
  File? get profileImage => _profileImage;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  /// Picks an image from the specified [source], compresses it, and updates local state.
  ///
  /// *   Resizes to max 1024x1024.
  /// *   Compresses to JPEG (70% quality).
  ///
  /// Returns the processed [File] or `null` if cancelled/failed.
  Future<File?> pickAndProcessImage(ImageSource source) async {
    try {
      _isProcessing = true;
      notifyListeners();

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        _isProcessing = false;
        notifyListeners();
        return null;
      }

      final File imageFile = File(pickedFile.path);
      final compressedFile = await _compressImage(imageFile);

      if (compressedFile != null) {
        _profileImage = compressedFile;
      }

      _isProcessing = false;
      notifyListeners();
      return _profileImage;
    } catch (e) {
      AppLogger.error('ProfileService Error', e);
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }

  Future<File?> _compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = p.join(tempDir.path,
        "compressed_${DateTime.now().millisecondsSinceEpoch}.jpg");

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70,
      format: CompressFormat.jpeg,
    );

    if (result == null) return null;
    return File(result.path);
  }

  void clearImage() {
    _profileImage = null;
    notifyListeners();
  }
}
