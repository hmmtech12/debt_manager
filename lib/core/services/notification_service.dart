/// Reminders save to the local database (see DebtRepository.addReminder)
/// but do not trigger an actual OS push notification in this build.
///
/// `flutter_local_notifications` was deliberately removed: it requires
/// Android's "core library desugaring" build setting, and on newer
/// Android Gradle Plugin toolchains that requirement conflicts with the
/// plugin's own generated build files in ways that aren't reliably
/// fixable without pinning very specific, fast-moving toolchain
/// versions — a bad trade-off for a "nice to have" reminder ping. Every
/// method below is a safe no-op so calling code (main.dart, Settings,
/// Debt Details) needs no changes; re-adding real notifications later
/// is a self-contained change confined to this file.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  bool get isSupported => false;

  Future<void> init() async {}

  Future<bool> requestPermission() async => false;

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {}

  Future<void> cancel(int id) async {}

  Future<void> cancelAll() async {}
}