/// Whether `flutter_contacts` has a real implementation on this platform.
/// It only supports Android/iOS — no web, no desktop. Picked at compile
/// time via the same conditional-import pattern used for file export and
/// the database factory.
export 'contacts_support_stub.dart'
    if (dart.library.io) 'contacts_support_io.dart'
    if (dart.library.html) 'contacts_support_web.dart';
