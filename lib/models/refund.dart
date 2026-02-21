class Refund {
  final String id;
  final String paymentId;
  final String bookingId;
  final double amount;
  final String reason; // 'cancelled_by_renter', 'rejected_by_owner', 'other'
  final String status; // 'Pending', 'Processed'
  final DateTime createdAt;
  final DateTime? processedAt;

  const Refund({
    required this.id,
    required this.paymentId,
    required this.bookingId,
    required this.amount,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.processedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'paymentId': paymentId,
      'bookingId': bookingId,
      'amount': amount,
      'reason': reason,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
    };
  }

  factory Refund.fromMap(Map<String, dynamic> map) {
    return Refund(
      id: map['id'] as String,
      paymentId: map['paymentId'] as String,
      bookingId: map['bookingId'] as String,
      amount: (map['amount'] as num).toDouble(),
      reason: map['reason'] as String,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      processedAt: map['processedAt'] == null
          ? null
          : DateTime.parse(map['processedAt'] as String),
    );
  }

  Refund copyWith({
    String? status,
    DateTime? processedAt,
  }) {
    return Refund(
      id: id,
      paymentId: paymentId,
      bookingId: bookingId,
      amount: amount,
      reason: reason,
      status: status ?? this.status,
      createdAt: createdAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }
}
