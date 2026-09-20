import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/app_theme.dart';
import '../providers/ai_provider.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/async_error_view.dart';

class AIScreen extends ConsumerWidget {
  const AIScreen({super.key});

  void _showKulaanBottomSheet(BuildContext context, WidgetRef ref, List<dynamic> calculatedItems) {
    final checklistItems = calculatedItems.map((item) {
      return KulaanItem(
        name: item['name'] as String,
        qty: item['qty'] as int,
      );
    }).toList();

    // Set initial items in provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(kulaanChecklistProvider.notifier).setItems(checklistItems);
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusBottomSheet)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final items = ref.watch(kulaanChecklistProvider);
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Rencana Kulaan Mingguan',
                        style: AppTheme.headingMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Centang barang yang sudah dibeli. List otomatis di-reset setiap hari Jumat baru.',
                        style: AppTheme.caption,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: items.isEmpty
                            ? const Center(child: Text('Tidak ada rencana kulaan.'))
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  return CheckboxListTile(
                                    title: Text(
                                      item.name,
                                      style: AppTheme.body.copyWith(
                                        fontWeight: FontWeight.bold,
                                        decoration: item.checked ? TextDecoration.lineThrough : null,
                                        color: item.checked ? AppTheme.textSecondary : AppTheme.textPrimary,
                                      ),
                                    ),
                                    subtitle: Text('Rekomendasi beli: ${item.qty} pcs', style: AppTheme.caption),
                                    value: item.checked,
                                    activeColor: AppTheme.primary,
                                    onChanged: (val) {
                                      ref.read(kulaanChecklistProvider.notifier).toggleItem(item.name);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showDailyHistoryBottomSheet(BuildContext context, Map<String, dynamic> historyItem) {
    final dateStr = historyItem['date_string'] as String;
    final details = historyItem['details'] as List<dynamic>? ?? [];
    final criticalItems = historyItem['critical_items'] as List<dynamic>? ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusBottomSheet)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Detail Rekap Harian',
                style: AppTheme.headingMedium,
              ),
              Text(
                dateStr,
                style: AppTheme.caption,
              ),
              const SizedBox(height: 16),
              Text('Barang Terjual:', style: AppTheme.body.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (details.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('Tidak ada penjualan tercatat.', style: AppTheme.caption),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: details.length,
                    itemBuilder: (context, index) {
                      final det = details[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(det['name'] ?? det['item'] ?? '', style: AppTheme.body),
                            Text('${det['qty']} pcs', style: AppTheme.body.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text('Stok Kritis Hari Itu:', style: AppTheme.body.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (criticalItems.isEmpty)
                Text(
                  'Stok aman terkendali.',
                  style: AppTheme.body.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold),
                )
              else
                Text(
                  criticalItems.join(', '),
                  style: AppTheme.body.copyWith(color: AppTheme.statusKritis),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> history) {
    final chronoHistory = history.reversed.toList();
    double maxVal = 10;
    for (var h in chronoHistory) {
      final val = (h['items_sold'] as int).toDouble();
      if (val > maxVal) maxVal = val;
    }
    maxVal = (maxVal * 1.2).ceilToDouble();

    final List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < chronoHistory.length; i++) {
      final dayData = chronoHistory[i];
      final itemsSold = dayData['items_sold'] as int? ?? 0;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: itemsSold.toDouble(),
              color: AppTheme.primary.withValues(alpha: 0.8),
              width: 12,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: chronoHistory.length * 28.0 + 40.0,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => AppTheme.primary,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final dayData = chronoHistory[group.x.toInt()];
                    final date = dayData['date'] as DateTime;
                    return BarTooltipItem(
                      '${date.day}/${date.month}\n${rod.toY.toInt()} pcs',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= chronoHistory.length) return const SizedBox();
                      if (index % 5 == 0 || index == chronoHistory.length - 1) {
                        final date = chronoHistory[index]['date'] as DateTime;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            '${date.day}/${date.month}',
                            style: AppTheme.caption.copyWith(fontSize: 9),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                    reservedSize: 24,
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(aiInsightsProvider);
    final storeInfoAsync = ref.watch(storeInfoProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F4), // Slightly bluish-teal background for AI Analysis space
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(aiInsightsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Asisten AI',
                            style: AppTheme.headingBold,
                          ),
                          storeInfoAsync.when(
                            data: (store) => Text(
                              store['nama_warung'] ?? 'Warung Barokah',
                              style: AppTheme.caption,
                            ),
                            loading: () => const SizedBox(),
                            error: (e, s) => AsyncErrorView(error: e, compact: true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                insightsAsync.when(
                  data: (insights) {
                    final weeklyRange = insights['weekly_range'] ?? 'Minggu Ini';
                    final topWeekly = List<Map<String, dynamic>>.from(insights['weekly_top_products'] ?? []);
                    final criticalCount = insights['weekly_critical_count'] as int? ?? 0;
                    final kulaan = List<Map<String, dynamic>>.from(insights['rencana_kulaan'] ?? []);
                    final todaySold = insights['today_sold'] as int? ?? 0;
                    final todayTop = insights['today_top_product'] as String? ?? '';
                    final todayTopQty = insights['today_top_qty'] as int? ?? 0;
                    final todayCritical = List<String>.from(insights['today_critical_stocks'] ?? []);
                    final dailyHistory = List<Map<String, dynamic>>.from(insights['daily_history'] ?? []);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card 1: Insight Minggu Ini
                        WeeklyInsightCard(
                          dateRange: weeklyRange,
                          topProducts: topWeekly,
                          criticalCount: criticalCount,
                        ),
                        const SizedBox(height: 16),

                        // Card 2: Rencana Kulaan
                        RencanaKulaanCard(
                          items: kulaan,
                          onDetailTap: () {
                            _showKulaanBottomSheet(context, ref, kulaan);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Card 3: Rekap Hari Ini
                        RekapHariIniCard(
                          totalSold: todaySold,
                          topProduct: todayTop,
                          topProductQty: todayTopQty,
                          criticalStocks: todayCritical,
                        ),
                        const SizedBox(height: 24),

                        // Section: Sales trend 30 Days
                        Text(
                          'Tren Penjualan 30 Hari',
                          style: AppTheme.headingMedium.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        _buildBarChart(dailyHistory),
                        const SizedBox(height: 24),

                        // Section: Riwayat Rekap Harian
                        Text(
                          'Riwayat Rekap Harian',
                          style: AppTheme.headingMedium.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Container(
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
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: dailyHistory.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                            itemBuilder: (context, index) {
                              final history = dailyHistory[index];
                              return ListTile(
                                leading: const Icon(Icons.calendar_today_rounded, color: AppTheme.primaryLight, size: 20),
                                title: Text(
                                  history['date_string'] ?? '',
                                  style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${history['items_sold']} item',
                                      style: AppTheme.body.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primary),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                                  ],
                                ),
                                onTap: () {
                                  _showDailyHistoryBottomSheet(context, history);
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, s) => Center(
                    child: AsyncErrorView(
                      error: e,
                      onRetry: () => ref.invalidate(aiInsightsProvider),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
