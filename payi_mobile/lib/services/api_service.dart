import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  // Using the host machine's local IP address instead of localhost
  // since the physical Android phone runs on its own interface.
  static const String baseUrl = 'http://192.168.1.158:5088/api';

  // Hydrated dynamically by Clerk Webview on Startup
  static String currentAuthEmail = '';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'X-User-Email': currentAuthEmail,
    // Add clerk token here later 'Authorization': 'Bearer ...'
  };

  /// Fetch the current user's wallet
  Future<Wallet> fetchWallet() async {
    final response = await http.get(
      Uri.parse('$baseUrl/payments/wallet'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Wallet.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load wallet: ${response.statusCode}');
    }
  }

  /// Fetch the current user's transaction history
  Future<List<Transaction>> fetchTransactions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/payments/transactions'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<Transaction>.from(
        l.map((model) => Transaction.fromJson(model)),
      );
    } else {
      throw Exception('Failed to load transactions: ${response.statusCode}');
    }
  }

  /// Send Money API
  Future<Transaction> sendMoney({
    required double amount,
    required String currency,
    required String counterpartyEmail,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/send'),
      headers: _headers,
      body: jsonEncode({
        'amount': amount,
        'currency': currency,
        'counterpartyEmail': counterpartyEmail,
        'country': 'Global',
        'paymentMethod': 'Payi Transfer',
      }),
    );

    if (response.statusCode == 200) {
      return Transaction.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to send money: ${response.body}');
    }
  }
}
