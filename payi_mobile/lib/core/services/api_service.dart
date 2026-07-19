import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  // Override at build time for production:
  //   flutter build apk --dart-define=PAYI_API_BASE_URL=http://YOUR-ALB-DNS.amazonaws.com/api
  // For local dev, defaults to localhost emulator address (10.0.2.2 = host on Android emulator)
  static const String baseUrl = String.fromEnvironment(
    'PAYI_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5088/api',
  );

  static String currentAuthEmail = '';
  static String currentAuthPhone = '';
  static String currentAuthCurrency = 'USD';
  static String currentAuthToken = '';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $currentAuthToken',
    'X-User-Email': currentAuthEmail,
    'X-User-Phone': currentAuthPhone,
    'X-User-Currency': currentAuthCurrency,
  };

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Login failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('ApiService login Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String name,
    required String phone,
    required String password,
    required String currency,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'name': name,
          'phoneNumber': phone,
          'country': currency,
          'password': password,
          'confirmPassword': password,
        }),
      ).timeout(const Duration(seconds: 20));
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Registration failed: ${response.body}');
    } catch (e) {
      debugPrint('ApiService register Error: $e');
      rethrow;
    }
  }

  Future<Wallet> fetchWallet() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/payments/wallet?userEmail=$currentAuthEmail'), headers: _headers)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        return Wallet.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to load wallet: ${response.statusCode}');
    } catch (e) {
      debugPrint('ApiService fetchWallet Error: $e');
      rethrow;
    }
  }

  Future<List<Transaction>> fetchTransactions() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/payments/transactions?userEmail=$currentAuthEmail'), headers: _headers)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        Iterable l = jsonDecode(response.body);
        return List<Transaction>.from(l.map((model) => Transaction.fromJson(model)));
      }
      throw Exception('Failed to load transactions: ${response.statusCode}');
    } catch (e) {
      debugPrint('ApiService fetchTransactions Error: $e');
      rethrow;
    }
  }

  Future<Transaction> sendMoney({
    required double amount,
    required String currency,
    required String destinationCountry,
    required String recipientName,
    required String recipientAccount,
    double? latitude,
    double? longitude,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/send'),
      headers: _headers,
      body: jsonEncode({
        'userEmail': currentAuthEmail,
        'amount': amount,
        'currency': currency,
        'destinationCountry': destinationCountry,
        'recipientName': recipientName,
        'recipientAccount': recipientAccount,
        'method': 'Payi Transfer',
        'latitude': latitude,
        'longitude': longitude,
      }),
    );
    if (response.statusCode == 200) {
      return Transaction.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to send money');
  }

  Future<Transaction> bankTransfer({
    required double amount,
    required String currency,
    required String bankName,
    required String accountNumber,
    double? latitude,
    double? longitude,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/send'),
      headers: _headers,
      body: jsonEncode({
        'userEmail': currentAuthEmail,
        'amount': amount,
        'currency': currency,
        'destinationCountry': 'Local',
        'recipientName': bankName,
        'recipientAccount': accountNumber,
        'method': 'Bank Transfer',
        'latitude': latitude,
        'longitude': longitude,
      }),
    );
    if (response.statusCode == 200) {
      return Transaction.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to transfer to bank');
  }

  Future<Transaction> payBill({
    required double amount,
    required String currency,
    required String utilityName,
    required String accountNumber,
    double? latitude,
    double? longitude,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/send'),
      headers: _headers,
      body: jsonEncode({
        'userEmail': currentAuthEmail,
        'amount': amount,
        'currency': currency,
        'destinationCountry': 'Local',
        'recipientName': utilityName,
        'recipientAccount': accountNumber,
        'method': 'Bill Payment',
        'latitude': latitude,
        'longitude': longitude,
      }),
    );
    if (response.statusCode == 200) {
      return Transaction.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to pay bill');
  }

  // --- Stripe Endpoints ---

  Future<String> getStripePublishableKey() async {
    final response = await http.get(Uri.parse('$baseUrl/payments/stripe/publishable-key'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['publishableKey'] as String;
    }
    throw Exception('Failed to get Stripe key');
  }

  Future<Map<String, dynamic>> createStripePaymentIntent({
    required double amount,
    required String currency,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/stripe/create-intent'),
      headers: _headers,
      body: jsonEncode({
        'userEmail': currentAuthEmail,
        'amount': amount,
        'currency': currency,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create PaymentIntent');
  }

  Future<Wallet> confirmStripePayment({
    required String paymentIntentId,
    required String currency,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/stripe/confirm'),
      headers: _headers,
      body: jsonEncode({
        'userEmail': currentAuthEmail,
        'paymentIntentId': paymentIntentId,
        'currency': currency,
      }),
    );
    if (response.statusCode == 200) {
      return Wallet.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to confirm payment');
  }

  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Reset password failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('ApiService resetPassword Error: $e');
      rethrow;
    }
  }

  Future<String> getKycStatus() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/kyc/status'), headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['kycStatus'] as String;
      }
      return 'Unverified';
    } catch (e) {
      debugPrint('ApiService getKycStatus Error: $e');
      return 'Unverified';
    }
  }

  Future<String> submitKyc(String faceImagePath, String idImagePath) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/kyc/submit'));
      // Don't use _headers here - it includes Content-Type: application/json which breaks multipart
      request.headers['X-User-Email'] = currentAuthEmail;
      request.headers['X-User-Phone'] = currentAuthPhone;
      request.headers['X-User-Currency'] = currentAuthCurrency;

      request.files.add(await http.MultipartFile.fromPath('faceDocument', faceImagePath));
      request.files.add(await http.MultipartFile.fromPath('idDocument', idImagePath));

      var streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['kycStatus'] as String;
      }
      throw Exception('KYC submission failed: ${response.body}');
    } catch (e) {
      debugPrint('ApiService submitKyc Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> checkSystemHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/system/health'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('ApiService checkSystemHealth Error: $e');
      return null;
    }
  }
}
