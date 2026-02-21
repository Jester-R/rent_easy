import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/property_provider.dart';
import '../common/payment_record_detail_screen.dart';
import '../../utils/date_utils.dart';
import '../../utils/extensions.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthProvider, PaymentProvider, PropertyProvider>(
      builder: (context, auth, paymentProvider, propertyProvider, _) {
        final userId = auth.currentUserId ?? '';
        final payments = paymentProvider.userPayments(userId);

        if (payments.isEmpty) {
          return const Center(child: Text('No payment history yet'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: payments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, index) {
            final payment = payments[index];
            final matched = propertyProvider.properties
                .where((p) => p.id == payment.propertyId)
                .toList();
            final propertyTitle = matched.isEmpty ? null : matched.first.title;
            return Card(
              child: ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentRecordDetailScreen(
                      payment: payment,
                      propertyTitle: propertyTitle,
                    ),
                  ),
                ),
                title: Text(propertyTitle ?? 'Property ID: ${payment.propertyId}'),
                subtitle: Text(
                  '${payment.method} • ${AppDateUtils.pretty(payment.createdAt)}',
                ),
                leading: const Icon(Icons.receipt_long_outlined),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(payment.amount.toUsd()),
                    Text(
                      payment.refundStatus == 'Processed'
                          ? 'Refunded'
                          : payment.status,
                      style: TextStyle(
                        color: payment.refundStatus == 'Processed'
                            ? AppColors.primaryDark
                            : payment.status == 'Success'
                            ? AppColors.success
                            : AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
