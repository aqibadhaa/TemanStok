import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class WeeklyInsightCard extends StatelessWidget {
  final String dateRange;
  final List<Map<String, dynamic>> topProducts;
  final int criticalCount;

  const WeeklyInsightCard({
    super.key,
    required this.dateRange,
    required this.topProducts,
    required this.criticalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: AppTheme.primary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Insight Minggu Ini',
                      style: AppTheme.headingMedium.copyWith(fontSize: 16),
                    ),
                    Text(
                      dateRange,
                      style: AppTheme.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Top 3 Products Row
          Row(
            children: List.generate(topProducts.length, (index) {
              final product = topProducts[index];
              final double iconSize = index == 0 ? 20 : (index == 1 ? 18 : 16);
              final double opacity = index == 0 ? 1.0 : (index == 1 ? 0.7 : 0.4);

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index == topProducts.length - 1 ? 0 : 8,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE0F7F7), Color(0xFFB2DFDB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        color: AppTheme.primary.withValues(alpha: opacity),
                        size: iconSize,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product['name'] ?? '',
                        style: AppTheme.body.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${product['qty']} pc',
                        style: AppTheme.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          if (criticalCount > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.statusKritis.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.statusKritis, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$criticalCount produk perlu perhatian segera!',
                      style: AppTheme.body.copyWith(
                        color: AppTheme.statusKritis,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class RencanaKulaanCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final VoidCallback onDetailTap;

  const RencanaKulaanCard({
    super.key,
    required this.items,
    required this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    final limitedItems = items.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_cart_rounded, color: AppTheme.primaryLight, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rencana Kulaan',
                      style: AppTheme.headingMedium.copyWith(fontSize: 16),
                    ),
                    Text(
                      'Diperbarui Jumat ini',
                      style: AppTheme.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Empty state atau product listing
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada rencana kulaan',
                    style: AppTheme.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rencana kulaan akan muncul setiap Jumat sore setelah ada transaksi minggu ini',
                    style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else ...[
            ...List.generate(limitedItems.length, (index) {
              final item = limitedItems[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Text(
                      '${index + 1}. ',
                      style: AppTheme.body.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Text(
                        item['name'] ?? '',
                        style: AppTheme.body,
                      ),
                    ),
                    Text(
                      '→ ${item['qty']} pcs',
                      style: AppTheme.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onDetailTap,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Lihat Checklist Lengkap',
                      style: AppTheme.body.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward, color: AppTheme.primary, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class RekapHariIniCard extends StatelessWidget {
  final int totalSold;
  final String topProduct;
  final int topProductQty;
  final List<String> criticalStocks;

  const RekapHariIniCard({
    super.key,
    required this.totalSold,
    required this.topProduct,
    required this.topProductQty,
    required this.criticalStocks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_rounded, color: AppTheme.primary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rekap Hari Ini',
                      style: AppTheme.headingMedium.copyWith(fontSize: 16),
                    ),
                    Text(
                      _formatDateToday(),
                      style: AppTheme.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: AppTheme.textSecondary, size: 18),
              const SizedBox(width: 8),
              Text(
                '$totalSold item terjual',
                style: AppTheme.body.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.emoji_events_outlined, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Terlaris: $topProduct ($topProductQty pc)',
                  style: AppTheme.body.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
              ),
            ],
          ),
          if (criticalStocks.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            ...criticalStocks.map((stockInfo) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: AppTheme.statusKritis, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stockInfo,
                        style: AppTheme.body.copyWith(color: AppTheme.statusKritis, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  String _formatDateToday() {
    final date = DateTime.now();
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${days[date.weekday % 7]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
