import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class WalletProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  Wallet? wallet;
  List<Transaction>? transactions;

  // Mock Profile Data
  String profileName = "Musa Mutindi";
  String profileEmail = "mutindimusa04@gmail.com";

  bool isLoading = false;
  String? error;

  Future<void> fetchData() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final Future<Wallet> walletFuture = _apiService.fetchWallet();
      final Future<List<Transaction>> txFuture = _apiService
          .fetchTransactions();

      final results = await Future.wait([walletFuture, txFuture]);

      wallet = results[0] as Wallet;
      transactions = results[1] as List<Transaction>;
    } catch (e) {
      // Bypassing error for prototyping: Hydrate with MOCK DATA if API fails
      debugPrint("API Fetch failed, using mock data: $e");
      _loadMockData();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _loadMockData() {
    wallet = Wallet(
      userEmail: profileEmail,
      balances: {'USD': 450.00, 'KES': 1500.00, 'NGN': 25000.00},
      updatedAtUtc: DateTime.now(),
    );

    transactions = [
      Transaction(
        reference: "TX123",
        userEmail: profileEmail,
        direction: "Receive",
        counterpartyName: "Sarah Jenkins",
        country: "USA",
        method: "Bank Transfer",
        amount: 250.00,
        currency: "USD",
        status: "Completed",
        createdAtUtc: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Transaction(
        reference: "TX124",
        userEmail: profileEmail,
        direction: "Send",
        counterpartyName: "Mike Ross",
        country: "Kenya",
        method: "M-Pesa",
        amount: 120.0,
        currency: "USD",
        status: "Completed",
        createdAtUtc: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Transaction(
        reference: "TX125",
        userEmail: profileEmail,
        direction: "Receive",
        counterpartyName: "Emma Wood",
        country: "Nigeria",
        method: "Payi Wallet",
        amount: 50.0,
        currency: "USD",
        status: "Completed",
        createdAtUtc: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  // Helper to format currency values safely
  String get formattedTotalUsd {
    if (wallet == null) return '\$0.00';
    final usd = wallet!.balances['USD'] ?? 0.0;
    return '\$${usd.toStringAsFixed(2)}';
  }
}
