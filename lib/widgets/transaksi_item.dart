import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_theme.dart';

class TransaksiItem extends StatelessWidget {
  final String item;
  final int qty;
  final String type;
  final Timestamp timestamp;

  const TransaksiItem({
    super.key,
    required this.item,
    required this.qty,
    required this.type,
    required this.timestamp,
  });

  String _formatTime(Timestamp timestamp) {
    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.isNegative) return 'baru saja';
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}j';
    return '${diff.inDays}h';
  }

  @override
  Widget build(BuildContext context) {
    final isMasuk = ['masuk', 'restok', 'restock'].contains(type.toLowerCase());

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.cardGap),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isMasuk ? const Color(0xFFE0F7F7) : const Color(0xFFFFEBEE),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMasuk ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
              color: isMasuk ? AppTheme.primary : AppTheme.statusKritis,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Product Name and Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item,
                  style: AppTheme.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(timestamp),
                  style: AppTheme.caption,
                ),
              ],
            ),
          ),
          // Qty Right
          Text(
            isMasuk ? '+$qty pcs' : '-$qty pcs',
            style: AppTheme.body.copyWith(
              color: isMasuk ? AppTheme.primary : AppTheme.statusKritis,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
