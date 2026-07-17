class Wallet {
  final String userEmail;
  final Map<String, double> balances;
  final DateTime updatedAtUtc;

  Wallet({
    required this.userEmail,
    required this.balances,
    required this.updatedAtUtc,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    Map<String, double> balMap = {};
    if (json['balances'] != null) {
      json['balances'].forEach((key, value) {
        balMap[key] = (value as num).toDouble();
      });
    }
    return Wallet(
      userEmail: json['userEmail'] ?? '',
      balances: balMap,
      updatedAtUtc: json['updatedAtUtc'] != null
          ? DateTime.parse(json['updatedAtUtc'])
          : DateTime.now(),
    );
  }
}

class Transaction {
  final String reference;
  final String userEmail;
  final String direction;
  final String counterpartyName;
  final String country;
  final String method;
  final double amount;
  final String currency;
  final String status;
  final DateTime createdAtUtc;

  Transaction({
    required this.reference,
    required this.userEmail,
    required this.direction,
    required this.counterpartyName,
    required this.country,
    required this.method,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAtUtc,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      reference: json['reference'] ?? '',
      userEmail: json['userEmail'] ?? '',
      direction: json['direction'] ?? 'Send',
      counterpartyName: json['counterpartyName'] ?? 'Unknown',
      country: json['country'] ?? '',
      method: json['method'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'USD',
      status: json['status'] ?? 'Unknown',
      createdAtUtc: json['createdAtUtc'] != null
          ? DateTime.parse(json['createdAtUtc'])
          : DateTime.now(),
    );
  }
}
