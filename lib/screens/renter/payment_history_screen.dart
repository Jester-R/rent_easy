import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/property_provider.dart';
import '../common/payment_record_detail_screen.dart';
import '../../utils/date_utils.dart';
import '../../utils/extensions.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final String? selectedPaymentId;
  final VoidCallback? onSelectionConsumed;

  const PaymentHistoryScreen({
    super.key,
    this.selectedPaymentId,
    this.onSelectionConsumed,
  });

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  String? _focusedPaymentId;
  final Map<String, GlobalKey> _itemKeys = <String, GlobalKey>{};
  Timer? _focusBlinkTimer;
  bool _showFocusBorder = false;
  int _focusBlinkTick = 0;

  @override
  void initState() {
    super.initState();
    _focusedPaymentId = widget.selectedPaymentId;
    if (_focusedPaymentId != null) {
      _startFocusBlink();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onSelectionConsumed?.call();
      });
    }
  }

  @override
  void didUpdateWidget(covariant PaymentHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPaymentId != widget.selectedPaymentId &&
        widget.selectedPaymentId != null) {
      setState(() => _focusedPaymentId = widget.selectedPaymentId);
      _startFocusBlink();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onSelectionConsumed?.call();
      });
    }
  }

  @override
  void dispose() {
    _focusBlinkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthProvider, PaymentProvider, PropertyProvider>(
      builder: (context, auth, paymentProvider, propertyProvider, _) {
        final userId = auth.currentUserId ?? '';
        final payments = paymentProvider.userPayments(userId);

        if (payments.isEmpty) {
          return const Center(child: Text('No payment history yet'));
        }
        _ensureFocusedVisible();

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: payments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, index) {
            final payment = payments[index];
            final isFocused =
                payment.id == _focusedPaymentId && _showFocusBorder;
            final matched = propertyProvider.properties
                .where((p) => p.id == payment.propertyId)
                .toList();
            final propertyTitle = matched.isEmpty ? null : matched.first.title;
            return KeyedSubtree(
              key: _itemKeyFor(payment.id),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isFocused ? AppColors.primary : Colors.transparent,
                    width: isFocused ? 2 : 0,
                  ),
                ),
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
                  title: Text(
                    propertyTitle ?? 'Property ID: ${payment.propertyId}',
                  ),
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
              ),
            );
          },
        );
      },
    );
  }

  void _ensureFocusedVisible() {
    final focusedId = _focusedPaymentId;
    if (focusedId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _itemKeys[focusedId];
      final currentContext = key?.currentContext;
      if (currentContext == null) return;
      Scrollable.ensureVisible(
        currentContext,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: 0.2,
      );
    });
  }

  GlobalKey _itemKeyFor(String paymentId) {
    return _itemKeys.putIfAbsent(paymentId, GlobalKey.new);
  }

  void _startFocusBlink() {
    _focusBlinkTimer?.cancel();
    _focusBlinkTick = 0;
    if (!mounted) return;
    setState(() => _showFocusBorder = true);
    _focusBlinkTimer = Timer.periodic(const Duration(milliseconds: 180), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _focusBlinkTick += 1;
      if (_focusBlinkTick >= 6) {
        timer.cancel();
        setState(() {
          _showFocusBorder = false;
          _focusedPaymentId = null;
        });
        return;
      }
      setState(() => _showFocusBorder = !_showFocusBorder);
    });
  }
}
