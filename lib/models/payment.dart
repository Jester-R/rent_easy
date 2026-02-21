class Payment {
  final String id;
  final String propertyId;
  final String userId;
  final double amount;
  final String method;
  final String status; // 'Success' or 'Failed'
  final String refundStatus; // 'None', 'Pending', 'Processed'
  final double refundedAmount; // Amount refunded
  final DateTime createdAt;
  final DateTime? refundedAt;

  const Payment({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.amount,
    required this.method,
    required this.status,
    this.refundStatus = 'None',
    this.refundedAmount = 0.0,
    required this.createdAt,
    this.refundedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'propertyId': propertyId,
      'userId': userId,
      'amount': amount,
      'method': method,
      'status': status,
      'refundStatus': refundStatus,
      'refundedAmount': refundedAmount,
      'createdAt': createdAt.toIso8601String(),
      'refundedAt': refundedAt?.toIso8601String(),
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String,
      propertyId: map['propertyId'] as String,
      userId: map['userId'] as String,
      amount: (map['amount'] as num).toDouble(),
      method: map['method'] as String,
      status: map['status'] as String,
      refundStatus: map['refundStatus'] as String? ?? 'None',
      refundedAmount: (map['refundedAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      refundedAt: map['refundedAt'] == null
          ? null
          : DateTime.parse(map['refundedAt'] as String),
    );
  }

  Payment copyWith({
    String? refundStatus,
    double? refundedAmount,
    DateTime? refundedAt,
  }) {
    return Payment(
      id: id,
      propertyId: propertyId,
      userId: userId,
      amount: amount,
      method: method,
      status: status,
      refundStatus: refundStatus ?? this.refundStatus,
      refundedAmount: refundedAmount ?? this.refundedAmount,
      createdAt: createdAt,
      refundedAt: refundedAt ?? this.refundedAt,
    );
  }
}
