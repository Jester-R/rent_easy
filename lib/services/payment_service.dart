import 'dart:math';

class PaymentService {
  Future<bool> runMockPayment() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    return Random().nextInt(100) > 9;
  }
}
