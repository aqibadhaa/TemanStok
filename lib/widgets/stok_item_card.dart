import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_theme.dart';

class StokItemCard extends StatelessWidget {
  final String name;
  final int stock;
  final int maxStock;
  final String status;
  final Timestamp lastUpdated;
  final VoidCallback? onTap;

  const StokItemCard({
    super.key,
    required this.name,
    required this.stock,
    required this.maxStock,
    required this.status,
    required this.lastUpdated,
    this.onTap,
  });

  String _formatTime(Timestamp ts) {
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.isNegative) return 'Baru saja';
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }

  @override
  Widget build(BuildContext context) {
    // Left border color sesuai status
    final Color borderColor = status == 'kritis'
        ? AppTheme.statusKritis
        : status == 'rendah'
            ? AppTheme.statusRendah
            : AppTheme.statusAman;

    final double progress = maxStock > 0 ? (stock / maxStock).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.cardGap),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left border (thick indicator line)
              Container(
                width: 6,
                color: borderColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Product Name & Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: AppTheme.body.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Badge status
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: borderColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: borderColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Subtitle last updated
                      Text(
                        'Terakhir: ${_formatTime(lastUpdated)}',
                        style: AppTheme.caption,
                      ),
                      const SizedBox(height: 12),
                      // Progress bar label
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Stok: $stock / $maxStock pcs',
                            style: AppTheme.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: AppTheme.caption.copyWith(
                              fontWeight: FontWeight.bold,
                              color: borderColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Progress bar indicator
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(borderColor),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 6,
                      ),
                    ],
                  ),
                ),
              ),
              if (onTap != null)
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                  onPressed: onTap,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
