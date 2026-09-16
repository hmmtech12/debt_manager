import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Saves [bytes] to disk, then hands the file off appropriately per
/// platform. Returns a short, human-readable description of where the
/// file ended up, so the calling screen can show it to the person.
///
/// - **Mobile** (Android/iOS): saved to the app's documents folder, then
///   the native share sheet opens (Files/Drive/email/etc).
/// - **Desktop** (Windows/Linux/macOS): saved to the app's own documents
///   folder (NOT the shared Downloads folder — on managed/corporate
///   Windows accounts, Downloads is often redirected or permission-
///   restricted, which throws a native "Access is denied" dialog outside
///   Flutter's control). The app's own documents directory is always
///   writable by the current user, and the exact path is shown to the
///   person afterward so they can navigate there themselves — nothing is
///   auto-opened, so there's no OS dialog that could surprise them.
Future<String> saveAndShareBytes({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
  String? shareText,
}) async {
  final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  if (isDesktop) {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes);
    return 'Saved to ${file.path}';
  }

  // Mobile: the native share sheet is the expected, reliable experience.
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes);

  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)], text: shareText),
  );
  return 'Shared';
}
