/// Picks the right SQLite database-factory setup at compile time:
/// - web builds get `db_factory_web.dart` (sqflite_common_ffi_web)
/// - every other platform gets `db_factory_io.dart`, which sets up
///   `sqflite_common_ffi` on desktop (Windows/Linux/macOS) and leaves
///   Android/iOS alone, since the plain `sqflite` plugin already works
///   there without any extra setup.
export 'db_factory_stub.dart'
    if (dart.library.io) 'db_factory_io.dart'
    if (dart.library.html) 'db_factory_web.dart';
