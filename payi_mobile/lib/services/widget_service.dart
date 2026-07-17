import 'package:home_widget/home_widget.dart';
import 'package:flutter/foundation.dart';

class WidgetService {
  static const String _groupId = 'group.com.example.payi_mobile';
  static const String _androidWidgetName = 'WalletWidgetProvider';

  static Future<void> updateWidgetData({
    required String balance,
    required String currency,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('wallet_balance', balance);
      await HomeWidget.saveWidgetData<String>('wallet_currency', currency);
      
      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
      );
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }

  static Future<void> initialize() async {
    HomeWidget.setAppGroupId(_groupId);
  }
}
