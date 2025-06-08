class TransactionModel {
  final String id;
  final String userId;
  final int amount;
  final String type;
  final DateTime timestamp;
  final String? description;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.timestamp,
    this.description,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: json['amount'] as int,
      type: json['type'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
    };
  }
} 