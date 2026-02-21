import 'package:flutter/foundation.dart';

import '../models/payment.dart';
import '../services/payment_service.dart';
import '../services/storage_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();
  final List<Payment> _payments = [];
  bool _isProcessing = false;

  bool get isProcessing => _isProcessing;
  List<Payment> get payments {
    _reloadFromStore();
    return List.unmodifiable(_payments);
  }

  Future<void> initialize() async {
    _reloadFromStore();
    notifyListeners();
  }

  List<Payment> userPayments(String userId) {
    _reloadFromStore();
    return _payments.where((p) => p.userId == userId).toList();
  }

  void _reloadFromStore() {
    final box = StorageService.instance.paymentStore;
    _payments
      ..clear()
      ..addAll(
        box.values.map(
          (e) => Payment.fromMap(Map<String, dynamic>.from(e.cast<String, dynamic>())),
        ),
      );
    _payments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<Payment> processPayment({
    required String propertyId,
    required String userId,
    required double amount,
    required String method,
  }) async {
    _isProcessing = true;
    notifyListeners();

    final success = await _paymentService.runMockPayment();
    final payment = Payment(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      propertyId: propertyId,
      userId: userId,
      amount: amount,
      method: method,
      status: success ? 'Success' : 'Failed',
      createdAt: DateTime.now(),
    );

    _payments.insert(0, payment);
    await StorageService.instance.paymentStore.put(payment.id, payment.toMap());

    _isProcessing = false;
    notifyListeners();

    return payment;
  }
}
