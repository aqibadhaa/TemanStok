import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/ai_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/async_error_view.dart';

class ProfilScreen extends ConsumerWidget {
  const ProfilScreen({super.key});

  String _getInitials(String shopName) {
    if (shopName.trim().isEmpty) return 'PB';
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
    final txCountAsync = ref.watch(transactionCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Light grey background
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Section - Banner (Deep Dark Teal/Green)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF042628), // Deep dark green-teal
              ),
              padding: const EdgeInsets.only(top: 50, bottom: 40, left: 20, right: 20),
              child: storeInfoAsync.when(
                data: (store) {
                  final shopName = store['nama_warung'] ?? 'Warung Barokah';
                  
                  return Column(
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                            onPressed: () {
                              // Standard back behavior
                            },
                          ),
                          Text(
                            'Profil',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Fitur edit segera hadir.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Text(
                              'Edit',
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Avatar with Camera Icon Badge
                      Stack(
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0D7377), // Primary Teal
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _getInitials(shopName),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Color(0xFF0D7377),
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Owner Name & Warung
                      Text(
                        'Pak Budi',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        shopName,
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Active Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981), // Emerald green dot
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Aktif sejak 3 Mei 2026',
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                error: (e, s) => AsyncErrorView(
                  error: e,
                  onRetry: () => ref.invalidate(storeInfoProvider),
                ),
              ),
            ),

            // Floating Stats Card (Overlaps Banner)
            Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        offset: const Offset(0, 8),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn(
                        txCountAsync.maybeWhen(
                              data: (v) => v.toString(),
                              orElse: () => '-',
                            ),
                        'Transaksi',
                      ),
                      _buildDivider(),
                      _buildStatColumn(
                        inventoryAsync.maybeWhen(
                              data: (v) => v.length.toString(),
                              orElse: () => '-',
                            ),
                        'Barang',
                      ),
                      _buildDivider(),
                      _buildStatColumn(
                        '12',
                        'Hari Aktif',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Info Warung Settings Group
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'Info Warung',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                    ),
                    child: storeInfoAsync.when(
                      data: (store) {
                        final shopName = store['nama_warung'] ?? 'Warung Barokah';
                        final phone = store['owner_phone'] ?? '+62 812-3456-7890';
                        return Column(
                          children: [
                            _buildInfoTile(
                              Icons.storefront_rounded,
                              shopName,
                              'Toko Kelontong',
                              iconBgColor: const Color(0xFFE2F3F4),
                              iconColor: const Color(0xFF0D7377),
                            ),
                            const Divider(height: 1, color: Color(0xFFE5E7EB)),
                            _buildInfoTile(
                              Icons.phone_rounded,
                              'Nomor WA',
                              phone,
                              iconBgColor: const Color(0xFFFAEDD4),
                              iconColor: const Color(0xFFBAA070),
                            ),
                            const Divider(height: 1, color: Color(0xFFE5E7EB)),
                            _buildInfoTile(
                              Icons.location_on_rounded,
                              'Alamat',
                              'Jl. Contoh No.1 Jakarta',
                              iconBgColor: const Color(0xFFFAEDD4),
                              iconColor: const Color(0xFFBAA070),
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())),
                      error: (e, s) => AsyncErrorView(
                        error: e,
                        onRetry: () => ref.invalidate(storeInfoProvider),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Lainnya Settings Group
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'Lainnya',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                    ),
                    child: Column(
                      children: [
                        _buildActionTile(
                          Icons.settings_rounded,
                          'Pengaturan',
                          iconBgColor: const Color(0xFFF3F4F6),
                          iconColor: const Color(0xFF6B7280),
                        ),
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                        _buildActionTile(
                          Icons.help_outline_rounded,
                          'Bantuan & FAQ',
                          iconBgColor: const Color(0xFFE2F3F4),
                          iconColor: const Color(0xFF0D7377),
                        ),
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                        _buildActionTile(
                          Icons.star_rounded,
                          'Beri Rating Aplikasi',
                          iconBgColor: const Color(0xFFFAEDD4),
                          iconColor: const Color(0xFFBAA070),
                        ),
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                        // Logout Tile
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: Color(0xFFE53935),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            'Keluar Akun',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFE53935),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Keluar Akun'),
                                content: const Text('Apakah Anda yakin ingin keluar?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Batal'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
                                    child: const Text('Keluar'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await ref.read(sessionProvider.notifier).clearSession();
                              if (context.mounted) {
                                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // Spacing for mic floating button
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0D7377),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 36,
      color: const Color(0xFFE5E7EB),
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String title,
    String subtitle, {
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: const Color(0xFF1A1A1A),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF6B7280),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF9CA3AF),
        size: 20,
      ),
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title, {
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: const Color(0xFF1A1A1A),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF9CA3AF),
        size: 20,
      ),
      onTap: () {},
    );
  }
}
