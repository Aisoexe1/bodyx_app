import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Owns where progress-photo image files live on disk, separate from
/// [PersistenceService] (which only stores the small JSON metadata list —
/// id/date/fileName — via SharedPreferences). Mirrors the singleton-service
/// pattern used by NotificationService/HealthService.
class ProgressPhotoStorage {
  ProgressPhotoStorage._();
  static final ProgressPhotoStorage instance = ProgressPhotoStorage._();

  Future<Directory> _photosDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/progress_photos');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// The resolved on-device directory path, for callers (gallery/compare
  /// screens) that need to build many `File`s from filenames without an
  /// async round-trip per photo.
  Future<String> photosDirPath() async => (await _photosDir()).path;

  /// Copies a picked image into permanent on-device storage and returns
  /// just the filename (not the full path — see [ProgressPhoto]).
  Future<String> save(XFile picked, DateTime date) async {
    final dir = await _photosDir();
    final fileName = 'progress_${date.millisecondsSinceEpoch}.jpg';
    await File(picked.path).copy('${dir.path}/$fileName');
    return fileName;
  }

  Future<File> resolve(String fileName) async {
    final dir = await _photosDir();
    return File('${dir.path}/$fileName');
  }

  Future<void> delete(String fileName) async {
    final file = await resolve(fileName);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Removes every stored progress-photo file — used for account deletion.
  Future<void> deleteAll() async {
    final dir = await _photosDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
