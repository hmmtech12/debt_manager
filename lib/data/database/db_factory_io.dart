import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// On Android/iOS, the standard `sqflite` plugin registers its own
/// database factory automatically — nothing to do here. On desktop
/// (Windows/Linux/macOS) there's no such plugin, so we swap in
/// `sqflite_common_ffi`, which runs SQLite through native FFI bindings
/// instead. Either way, the rest of the app calls the same `openDatabase`
/// API afterwards without knowing which one is active.
Future<void> initDatabaseFactory() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
