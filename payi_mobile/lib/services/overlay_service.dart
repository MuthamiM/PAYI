import 'package:system_alert_window/system_alert_window.dart';

class OverlayService {
  static Future<void> requestPermissions() async {
    await SystemAlertWindow.requestPermissions(prefMode: SystemWindowPrefMode.OVERLAY);
  }

  static Future<void> showPaymentOverlay({
    required String title,
    required String amount,
    required String sender,
  }) async {
    await SystemAlertWindow.showSystemWindow(
      notificationTitle: title,
      notificationBody: "From: $sender\nAmount: $amount",
      prefMode: SystemWindowPrefMode.OVERLAY,
      gravity: SystemWindowGravity.TOP,
    );
  }

  static Future<void> closeOverlay() async {
    await SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
  }
}
