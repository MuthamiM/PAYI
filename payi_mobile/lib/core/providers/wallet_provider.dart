import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class WalletProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  Wallet? wallet;
  List<Transaction>? transactions;

  bool isLoading = false;
  String? error;

  String get profileEmail => ApiService.currentAuthEmail;
  String get profileName => ApiService.currentAuthEmail.split('@').first;

  // Settings state
  bool isDarkMode = true;
  bool biometricsEnabled = false;

  WalletProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      final file = File('${Directory.systemTemp.path}/payi_auth.json');
      if (await file.exists()) {
        final data = jsonDecode(await file.readAsString());
        biometricsEnabled = data['biometricsEnabled'] ?? false;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> fetchData() async {
    isLoading = true;
    error = null;
    notifyListeners();

    // Fetch wallet and transactions independently so one failure doesn't block the other
    try {
      wallet = await _apiService.fetchWallet();
    } catch (e) {
      debugPrint("Wallet fetch failed: $e");
    }

    try {
      transactions = await _apiService.fetchTransactions();
    } catch (e) {
      error = e.toString();
      debugPrint("Transactions fetch failed: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  // Helper to format currency values safely
  String get formattedTotalBalance {
    if (wallet == null || wallet!.balances.isEmpty) return '\$0.00';
    // Show the primary currency balance (first entry or USD if available)
    if (wallet!.balances.containsKey('USD') && wallet!.balances['USD']! > 0) {
      return '\$${wallet!.balances['USD']!.toStringAsFixed(2)}';
    }
    // Otherwise show the first non-zero balance
    for (final entry in wallet!.balances.entries) {
      if (entry.value > 0) {
        return '${entry.value.toStringAsFixed(2)} ${entry.key}';
      }
    }
    return '\$0.00';
  }

  /// Send Money
  Future<void> sendMoney(double amount, String currency, String destinationCountry, String recipientName, String recipientAccount, {double? latitude, double? longitude}) async {
    await _apiService.sendMoney(
      amount: amount, 
      currency: currency, 
      destinationCountry: destinationCountry, 
      recipientName: recipientName, 
      recipientAccount: recipientAccount,
      latitude: latitude,
      longitude: longitude,
    );
    await fetchData(); // Refresh data after transaction
  }

  /// Pay a bill, deducting from wallet
  Future<void> payBill(double amount, String currency, String billCategory, String accountNumber, {double? latitude, double? longitude}) async {
    await _apiService.payBill(amount: amount, currency: currency, utilityName: billCategory, accountNumber: accountNumber, latitude: latitude, longitude: longitude);
    await fetchData();
  }

  /// Bank transfer, deducting from wallet
  Future<void> bankTransfer(double amount, String currency, String bankName, String accountNumber, {double? latitude, double? longitude}) async {
    await _apiService.bankTransfer(amount: amount, currency: currency, bankName: bankName, accountNumber: accountNumber, latitude: latitude, longitude: longitude);
    await fetchData();
  }

  /// Top-up handled via Stripe in topup_screen, so we just need a refresh method
  Future<void> refreshAfterTopUp() async {
    await fetchData();
  }

  /// Toggle dark mode
  void toggleDarkMode(bool value) {
    isDarkMode = value;
    notifyListeners();
  }

  /// Toggle biometrics
  Future<void> toggleBiometrics(bool value) async {
    biometricsEnabled = value;
    notifyListeners();
    try {
      final file = File('${Directory.systemTemp.path}/payi_auth.json');
      Map<String, dynamic> data = {};
      if (await file.exists()) {
        final text = await file.readAsString();
        if (text.isNotEmpty) {
          data = jsonDecode(text);
        }
      }
      data['biometricsEnabled'] = value;
      await file.writeAsString(jsonEncode(data));
    } catch (_) {}
  }
}
