import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../models/payment.dart';
import '../../utils/date_utils.dart';
import '../../utils/extensions.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final Payment payment;

  const PaymentSuccessScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 84, color: AppColors.success),
                  const SizedBox(height: 14),
                  const Text(
                    'Payment Success',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Amount: ${payment.amount.toUsd()}', textAlign: TextAlign.center),
                  Text('Method: ${payment.method}', textAlign: TextAlign.center),
                  Text(
                    'Date: ${AppDateUtils.pretty(payment.createdAt)}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
