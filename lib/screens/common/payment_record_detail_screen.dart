import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../models/payment.dart';
import '../../utils/date_utils.dart';
import '../../utils/extensions.dart';

class PaymentRecordDetailScreen extends StatelessWidget {
  final Payment payment;
  final String? propertyTitle;

  const PaymentRecordDetailScreen({
    super.key,
    required this.payment,
    this.propertyTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Details')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              propertyTitle ?? 'Property ID: ${payment.propertyId}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          _statusPill(payment.status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _item('Payment ID', payment.id),
                      _item('Property ID', payment.propertyId),
                      _item('User ID', payment.userId),
                      _item('Amount', payment.amount.toUsd()),
                      _item('Method', payment.method),
                      _item('Status', payment.status),
                      _item('Refund Status', payment.refundStatus),
                      if (payment.refundStatus == 'Processed')
                        _item('Refunded Amount', payment.refundedAmount.toUsd()),
                      if (payment.refundedAt != null)
                        _item('Refunded At', AppDateUtils.pretty(payment.refundedAt!)),
                      _item('Created At', AppDateUtils.pretty(payment.createdAt)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _statusPill(String status) {
    final label = payment.refundStatus == 'Processed' ? 'Refunded' : status;
    final isSuccess = label == 'Success';
    final isRefunded = label == 'Refunded';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isRefunded
            ? const Color(0xFFE2E8F0)
            : isSuccess
                ? const Color(0xFFD8EFE6)
                : const Color(0xFFFBE4E4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isRefunded
              ? AppColors.primaryDark
              : isSuccess
                  ? AppColors.success
                  : AppColors.danger,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
