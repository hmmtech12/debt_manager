/// Picks the right file-saving implementation at compile time:
/// - web builds get `file_saver_web.dart` (browser download via a Blob)
/// - every other platform gets `file_saver_io.dart` (writes to disk,
///   then opens the native share sheet)
///
/// Both implementations expose the same `saveAndShareBytes` function, so
/// `export_service.dart` never needs to know which one it's calling.
export 'file_saver_stub.dart'
    if (dart.library.io) 'file_saver_io.dart'
    if (dart.library.html) 'file_saver_web.dart';
