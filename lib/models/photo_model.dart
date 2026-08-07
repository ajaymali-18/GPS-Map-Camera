import 'dart:io';

/// Represents a captured photo entity stored on device storage.
class PhotoModel {
  final File file;
  final DateTime modifiedAt;

  PhotoModel({
    required this.file,
    DateTime? modifiedAt,
  }) : modifiedAt = modifiedAt ?? file.lastModifiedSync();

  String get path => file.path;
}
