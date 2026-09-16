// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

/// Triggers a standard browser download for [bytes] named [fileName].
/// There's no native "share sheet" on the web, so [shareText] is
/// accepted for API parity with file_saver_io.dart but unused here.
Future<String> saveAndShareBytes({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
  String? shareText,
}) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
  anchor.remove();
  return 'Downloaded';
}
