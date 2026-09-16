import 'dart:typed_data';

Future<String> saveAndShareBytes({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
  String? shareText,
}) async {
  throw UnsupportedError('File export is not supported on this platform.');
}
