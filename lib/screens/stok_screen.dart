import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_theme.dart';
import '../providers/ai_provider.dart';
import '../providers/session_provider.dart';
import '../utils/app_exceptions.dart';
import '../widgets/async_error_view.dart';
import '../widgets/stok_item_card.dart';

class StokScreen extends ConsumerStatefulWidget {
  const StokScreen({super.key});

  @override
  ConsumerState<StokScreen> createState() => _StokScreenState();
}

class _StokScreenState extends ConsumerState<StokScreen> {
  String _searchQuery = '';
  String _activeFilter = 'Semua'; // 'Semua', 'kritis', 'rendah', 'aman'
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusCard)),
          title: Text('Tambah Barang Baru', style: AppTheme.headingMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Barang',
                  border: OutlineInputBorder(),
                  hintText: 'Contoh: Indomie Soto',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stok Awal',
                  border: OutlineInputBorder(),
                  hintText: 'Contoh: 20',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final stock = int.tryParse(stockController.text) ?? 0;
                if (name.isEmpty || stock <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nama dan stok awal harus valid')),
                  );
                  return;
                }

                Navigator.pop(context);
                final messenger = ScaffoldMessenger.of(context);

                try {
                  final storeId = ref.read(sessionProvider);
                  if (storeId == null || storeId.isEmpty) {
                    throw const SessionExpiredException();
                  }
                  await FirebaseFirestore.instance
                      .collection('stores')
                      .doc(storeId)
                      .collection('inventory')
                      .doc(name)
                      .set({
                        'stock': stock,
                        'min_stock': (stock * 0.2).round().clamp(1, 999),
                        'max_stock': stock * 2,
                        'last_updated': Timestamp.now(),
                      });
                  messenger.showSnackBar(
                    const SnackBar(content: Text('✅ Barang berhasil ditambahkan!'), backgroundColor: AppTheme.primary),
                  );
                } on SessionExpiredException {
                  // Sebelumnya diam-diam fallback ke 'warung_test_001' kalau
                  // sesi kosong — sekarang tolak dan paksa masuk ulang,
                  // supaya data barang gak nyasar ke dokumen bareng.
                  if (mounted) {
                    Navigator.of(this.context)
                        .pushNamedAndRemoveUntil('/phone_login', (route) => false);
                  }
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('❌ Gagal menambahkan: $e'), backgroundColor: AppTheme.statusKritis),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  void _showEditStockDialog(String name, int currentStock, int maxStock) {
    final stockController = TextEditingController(text: currentStock.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusCard)),
          title: Text('Update Stok - $name', style: AppTheme.headingMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Stok',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final stock = int.tryParse(stockController.text) ?? 0;
                if (stock < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Stok tidak boleh negatif')),
                  );
                  return;
                }

                Navigator.pop(context);
                final messenger = ScaffoldMessenger.of(context);

                try {
                  final storeId = ref.read(sessionProvider);
                  if (storeId == null || storeId.isEmpty) {
                    throw const SessionExpiredException();
                  }
                  await FirebaseFirestore.instance
                      .collection('stores')
                      .doc(storeId)
                      .collection('inventory')
                      .doc(name)
                      .update({
                        'stock': stock,
                        'last_updated': Timestamp.now(),
                      });
                  messenger.showSnackBar(
                    const SnackBar(content: Text('✅ Stok berhasil diupdate!'), backgroundColor: AppTheme.primary),
                  );
                } on SessionExpiredException {
                  if (mounted) {
                    Navigator.of(this.context)
                        .pushNamedAndRemoveUntil('/phone_login', (route) => false);
                  }
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('❌ Gagal update: $e'), backgroundColor: AppTheme.statusKritis),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value, Color? dotColor) {
    final isActive = _activeFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTheme.body.copyWith(
                color: isActive ? Colors.white : AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        selected: isActive,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _activeFilter = value;
            });
          }
        },
        selectedColor: AppTheme.primary,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
          side: BorderSide(color: isActive ? Colors.transparent : Colors.grey[300]!),
        ),
        showCheckmark: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Title & Add Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Stok Barang',
                    style: AppTheme.headingBold,
                  ),
                  OutlinedButton.icon(
                    onPressed: _showAddProductDialog,
                    icon: const Icon(Icons.add, color: AppTheme.primary, size: 18),
                    label: Text(
                      'Tambah',
                      style: AppTheme.body.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.toLowerCase();
                          });
                        },
                        style: AppTheme.body,
                        decoration: const InputDecoration(
                          hintText: 'Cari barang...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: AppTheme.textSecondary),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textSecondary, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Semua', 'Semua', null),
                    _buildFilterChip('Kritis', 'kritis', AppTheme.statusKritis),
                    _buildFilterChip('Rendah', 'rendah', AppTheme.statusRendah),
                    _buildFilterChip('Aman', 'aman', AppTheme.statusAman),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Product List
              Expanded(
                child: inventoryAsync.when(
                  data: (inventory) {
                    // Filter items
                    final filteredItems = inventory.where((item) {
                      final matchesSearch = (item['name'] as String).toLowerCase().contains(_searchQuery);
                      final matchesFilter = _activeFilter == 'Semua' || item['status'] == _activeFilter;
                      return matchesSearch && matchesFilter;
                    }).toList();

                    if (filteredItems.isEmpty) {
                      return Center(
                        child: Text(
                          'Tidak ada barang ditemukan.',
                          style: AppTheme.caption,
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return StokItemCard(
                          name: item['name'] ?? '',
                          stock: item['stock'] as int? ?? 0,
                          maxStock: item['max_stock'] as int? ?? 100,
                          status: item['status'] ?? 'aman',
                          lastUpdated: item['last_updated'],
                          onTap: () {
                            _showEditStockDialog(
                              item['name'],
                              item['stock'] as int,
                              item['max_stock'] as int,
                            );
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(
                    child: AsyncErrorView(
                      error: e,
                      onRetry: () => ref.invalidate(inventoryProvider),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
