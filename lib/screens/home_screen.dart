import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../providers/ai_provider.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaksi_item.dart';
import '../widgets/async_error_view.dart';

// Shared tab index provider for global tab navigation control
final tabIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 19) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  String _getInitials(String shopName) {
    if (shopName.trim().isEmpty) return 'TS';
    final parts = shopName.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeInfoAsync = ref.watch(storeInfoProvider);
    final inventoryAsync = ref.watch(inventoryProvider);
    final transactionsAsync = ref.watch(recentTransactionsProvider);
    final aiInsightsAsync = ref.watch(aiInsightsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(storeInfoProvider);
            ref.invalidate(inventoryProvider);
            ref.invalidate(recentTransactionsProvider);
            ref.invalidate(aiInsightsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Greeting, Shop Name, Bell & Avatar
                storeInfoAsync.when(
                  data: (store) {
                    final shopName = store['nama_warung'] ?? 'Warung Barokah';
                    final ownerName = ''; // Fallback if no owner name
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_getGreeting()}, $ownerName',
                                style: AppTheme.caption.copyWith(fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                shopName,
                                style: AppTheme.headingBold.copyWith(fontSize: 22),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.textPrimary),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Belum ada notifikasi baru.')),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            // Avatar
                            Container(
                              width: 42,
                              height: 42,
                              decoration: const BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _getInitials(shopName),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => AsyncErrorView(
                    error: e,
                    onRetry: () => ref.invalidate(storeInfoProvider),
                  ),
                ),
                const SizedBox(height: 24),

                // Grid of 4 summary cards
                inventoryAsync.when(
                  data: (inventory) {
                    final totalJenis = inventory.length;
                    final criticalCount = inventory.where((item) => item['status'] == 'kritis').length;
                    
                    final recentCount = transactionsAsync.maybeWhen(
                      data: (d) => d.length,
                      orElse: () => null,
                    );
                    final aiSaranCount = aiInsightsAsync.maybeWhen(
                      data: (d) => (d['rencana_kulaan'] as List?)?.length,
                      orElse: () => null,
                    );

                    return Column(
                      children: [
                        Row(
                          children: [
                            SummaryCard(
                              label: 'Total Jenis',
                              value: totalJenis.toString(),
                              valueColor: AppTheme.textPrimary,
                            ),
                            const SizedBox(width: 12),
                            SummaryCard(
                              label: 'Stok Kritis',
                              value: criticalCount.toString(),
                              valueColor: criticalCount > 0 ? AppTheme.statusKritis : AppTheme.textPrimary,
                              onTap: () {
                                // Go to inventory filter
                                ref.read(tabIndexProvider.notifier).state = 1;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            SummaryCard(
                              label: 'Transaksi',
                              value: recentCount?.toString() ?? '-',
                              valueColor: AppTheme.textPrimary,
                            ),
                            const SizedBox(width: 12),
                            SummaryCard(
                              label: 'Saran AI',
                              value: aiSaranCount?.toString() ?? '-',
                              valueColor: AppTheme.primary,
                              onTap: () {
                                // Go to AI tab
                                ref.read(tabIndexProvider.notifier).state = 2;
                              },
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => AsyncErrorView(
                    error: e,
                    onRetry: () => ref.invalidate(inventoryProvider),
                  ),
                ),
                const SizedBox(height: 24),

                // Transaksi Terakhir Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transaksi Terakhir',
                      style: AppTheme.headingMedium.copyWith(fontSize: 16),
                    ),
                    TextButton(
                      onPressed: () {
                        // Switch to Stok tab
                        ref.read(tabIndexProvider.notifier).state = 1;
                      },
                      child: Row(
                        children: [
                          Text(
                            'Lihat Semua',
                            style: AppTheme.body.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, color: AppTheme.primary, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Last 5 Transactions List
                transactionsAsync.when(
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: Text(
                            'Belum ada transaksi.',
                            style: AppTheme.caption,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        return TransaksiItem(
                          item: tx['item'] ?? '',
                          qty: tx['qty'] as int? ?? 0,
                          type: tx['type'] ?? 'keluar',
                          timestamp: tx['timestamp'],
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => AsyncErrorView(
                    error: e,
                    onRetry: () => ref.invalidate(recentTransactionsProvider),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
