/// CSV import via a native file picker isn't available in this build —
/// see the Android-specific note below. Export (CSV/PDF) is unaffected;
/// only picking a file to import got removed.
///
/// `file_picker`'s Android build requirements conflicted with other
/// dependencies (`share_plus`) across every version tried — newer
/// versions needing a newer compileSdk broke compatibility with
/// share_plus, and the version that satisfied share_plus had a
/// compile-time API mismatch (`FilePicker.platform` not found). Rather
/// than keep chasing a moving target across three plugins in one
/// session, this is disabled cleanly with a clear message. Re-adding it
/// is a self-contained change confined to this file plus the Settings
/// screen's Import Data tile.
class ImportService {
  ImportService._();

  static Future<List<List<String>>?> pickAndParseCsv() async {
    throw UnsupportedError('CSV import isn\'t available in this build yet.');
  }
}