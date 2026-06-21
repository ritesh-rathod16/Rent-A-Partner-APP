class Payment {
  final String id;
  final String userName;
  final String companionName;
  final double amount;
  final DateTime timestamp;
  final String status;
  final String razorpayId;

  Payment({
    required this.id,
    required this.userName,
    required this.companionName,
    required this.amount,
    required this.timestamp,
    required this.status,
    required this.razorpayId,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? '',
      userName: json['user_name'] ?? 'User',
      companionName: json['companion_name'] ?? 'Companion',
      amount: (json['amount'] ?? 0).toDouble(),
      timestamp: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'pending',
      razorpayId: json['payment_id'] ?? '',
    );
  }
}
