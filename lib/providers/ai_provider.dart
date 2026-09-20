import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'session_provider.dart';
import '../utils/app_exceptions.dart';

// 1. Store info provider (dari Firestore)
final storeInfoProvider = StreamProvider<Map<String, dynamic>>((ref) async* {
  final session = ref.watch(sessionProvider);
  String? storeId = session;
  if (storeId == null || storeId.isEmpty) {
    final prefs = await SharedPreferences.getInstance();
    storeId = prefs.getString('store_id');
  }
  if (storeId == null || storeId.isEmpty) {
    throw const SessionExpiredException();
  }
  yield* FirebaseFirestore.instance
      .collection('stores')
      .doc(storeId)
      .snapshots()
      .map((doc) => doc.data() ?? <String, dynamic>{});
});

// 2. Inventory provider (real-time)
final inventoryProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final prefs = await SharedPreferences.getInstance();
  final storeId = prefs.getString('store_id');
  if (storeId == null || storeId.isEmpty) {
    // Sebelumnya: yield* Stream.empty() tanpa return, tetap lanjut ke
    // .doc('') di bawah dan crash. Sekarang throw, mengakhiri fungsi.
    throw const SessionExpiredException();
  }

  yield* FirebaseFirestore.instance
      .collection('stores')
      .doc(storeId)
      .collection('inventory')
      .snapshots()
      .map((snapshot) {
        if (snapshot.docs.isEmpty) {
          // Return dummy inventory
          return [];
        }

        final list = snapshot.docs.map((doc) {
          final data = doc.data();
          final name = doc.id;
          final stock = data['stock'] as int? ?? 0;
          final minStock = data['min_stock'] as int? ?? 1;
          final maxStock = data['max_stock'] as int? ?? (stock > 0 ? stock * 2 : 100);

          // Determine status
          String status = 'aman';
          if (stock <= minStock) {
            status = 'kritis';
          } else if (stock <= minStock * 2) {
            status = 'rendah';
          }

          return {
            'name': name,
            'stock': stock,
            'min_stock': minStock,
            'max_stock': maxStock,
            'status': status,
            'last_updated': data['last_updated'] ?? Timestamp.now(),
          };
        }).toList();

        // Sort: kritis -> rendah -> aman
        list.sort((a, b) {
          final order = {'kritis': 0, 'rendah': 1, 'aman': 2};
          return order[a['status']]!.compareTo(order[b['status']]!);
        });

        return list;
      });
});

// 3. Recent transactions provider
final recentTransactionsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final prefs = await SharedPreferences.getInstance();
  final storeId = prefs.getString('store_id');
  if (storeId == null || storeId.isEmpty) {
    throw const SessionExpiredException();
  }

  yield* FirebaseFirestore.instance
      .collection('stores')
      .doc(storeId)
      .collection('transactions')
      .orderBy('timestamp', descending: true)
      .limit(5)
      .snapshots()
      .map((snapshot) {
        if (snapshot.docs.isEmpty) {
          // Return dummy transactions
          return [];
        }

        return snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'item': data['item'] ?? 'Barang',
            'qty': data['qty'] ?? 0,
            'type': data['type'] ?? 'keluar',
            'timestamp': data['timestamp'] ?? Timestamp.now(),
          };
        }).toList();
      });
});

// 4. AI insights provider (computed dari transactions)
final aiInsightsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final storeId = prefs.getString('store_id');
  if (storeId == null || storeId.isEmpty) {
    throw const SessionExpiredException();
  }

  final db = FirebaseFirestore.instance;

  // 1. Ambil data inventory untuk fallback kulaan & critical count
  final inventorySnapshot = await db
      .collection('stores')
      .doc(storeId)
      .collection('inventory')
      .get();

  final inventoryList = inventorySnapshot.docs.map((doc) {
    final data = doc.data();
    final name = doc.id;
    final stock = data['stock'] as int? ?? 0;
    final minStock = data['min_stock'] as int? ?? 1;
    final maxStock = data['max_stock'] as int? ?? (stock > 0 ? stock * 2 : 100);

    String status = 'aman';
    if (stock <= minStock) {
      status = 'kritis';
    } else if (stock <= minStock * 2) {
      status = 'rendah';
    }

    return {
      'name': name,
      'stock': stock,
      'min_stock': minStock,
      'max_stock': maxStock,
      'status': status,
    };
  }).toList();

  // 2. Ambil data transaksi dari Firestore (30 hari terakhir)
  final now = DateTime.now();
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));
  
  final transactionsSnapshot = await db
      .collection('stores')
      .doc(storeId)
      .collection('transactions')
      .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
      .get();

  final transactions = transactionsSnapshot.docs.map((doc) {
    final data = doc.data();
    return {
      'item': data['item'] ?? 'Barang',
      'qty': data['qty'] ?? 0,
      'type': data['type'] ?? 'keluar',
      'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    };
  }).toList();

  // A. INSIGHT MINGGU INI (7 Hari Terakhir)
  // group by item, sum qty where type == "terjual" or "keluar"
  final sevenDaysAgo = now.subtract(const Duration(days: 7));
  final weeklySalesMap = <String, int>{};
  
  for (final tx in transactions) {
    final txDate = tx['timestamp'] as DateTime;
    final type = tx['type'] as String;
    if (txDate.isAfter(sevenDaysAgo) && (type == 'terjual' || type == 'keluar')) {
      final item = tx['item'] as String;
      final qty = tx['qty'] as int;
      weeklySalesMap[item] = (weeklySalesMap[item] ?? 0) + qty;
    }
  }

  final sortedWeekly = weeklySalesMap.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final List<Map<String, dynamic>> topProductsWeekly = [];
  for (int i = 0; i < sortedWeekly.length && i < 3; i++) {
    topProductsWeekly.add({
      'name': sortedWeekly[i].key,
      'qty': sortedWeekly[i].value,
    });
  }

  // Jika data kosong, tampilkan placeholder agar UI tidak kosong/crash
  if (topProductsWeekly.isEmpty) {
    topProductsWeekly.add({'name': 'Belum ada data', 'qty': 0});
  }

  final rangeStr = '${sevenDaysAgo.day} ${_getMonthName(sevenDaysAgo.month)} – ${now.day} ${_getMonthName(now.month)} ${now.year}';
  final criticalCountWeekly = inventoryList.where((item) => item['status'] == 'kritis').length;

  // B. RENCANA KULAAN
  List<Map<String, dynamic>> rencanaKulaan = [];
  
  
  // 1. Ambil dari SharedPreferences key: "kulaan_plan"
  final planStr = prefs.getString('kulaan_plan');
  if (planStr != null && planStr.isNotEmpty) {
    try {
      final List<dynamic> decoded = json.decode(planStr);
      rencanaKulaan = decoded.map((item) {
        return {
          'name': item['name'] as String,
          'qty': item['qty'] as int,
          'checked': false,
        };
      }).toList();
    } catch (e) {
      // Fallback manual parse jika bukan format JSON list tapi string teks
      try {
        final lines = planStr.split('\n');
        for (final line in lines) {
          if (line.contains(':')) {
            final parts = line.split(':');
            rencanaKulaan.add({
              'name': parts[0].trim(),
              'qty': int.tryParse(parts[1].trim()) ?? 10,
              'checked': false,
            });
          }
        }
      } catch (_) {}
    }
  }

  // Jika tidak ada kulaan_plan → biarkan kosong
  // UI akan tampilkan empty state

  // C. REKAP HARI INI
  final startOfToday = DateTime(now.year, now.month, now.day);
  int totalSoldToday = 0;
  final todaySalesMap = <String, int>{};

  for (final tx in transactions) {
    final txDate = tx['timestamp'] as DateTime;
    final type = tx['type'] as String;
    if (txDate.isAfter(startOfToday) && (type == 'terjual' || type == 'keluar')) {
      final item = tx['item'] as String;
      final qty = tx['qty'] as int;
      totalSoldToday += qty;
      todaySalesMap[item] = (todaySalesMap[item] ?? 0) + qty;
    }
  }

  String topSellingToday = 'Tidak ada';
  int topSellingQtyToday = 0;
  if (todaySalesMap.isNotEmpty) {
    final sortedToday = todaySalesMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    topSellingToday = sortedToday.first.key;
    topSellingQtyToday = sortedToday.first.value;
  }

  final List<String> criticalStocksToday = [];
  for (final item in inventoryList) {
    if (item['status'] == 'kritis') {
      criticalStocksToday.add('${item['name']} — sisa ${item['stock']} pcs');
    }
  }

  // D. TREN 30 HARI & RIWAYAT REKAP HARIAN (Aggregate transactions per hari)
  final List<Map<String, dynamic>> dailyHistory = [];
  for (int i = 0; i < 30; i++) {
    final date = now.subtract(Duration(days: i));
    final dateStart = DateTime(date.year, date.month, date.day);
    final dateEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    int soldOnDay = 0;
    final Map<String, int> dayProductSales = {};

    for (final tx in transactions) {
      final txDate = tx['timestamp'] as DateTime;
      final type = tx['type'] as String;
      if (txDate.isAfter(dateStart) && txDate.isBefore(dateEnd) && (type == 'terjual' || type == 'keluar')) {
        final qty = tx['qty'] as int;
        soldOnDay += qty;
        final item = tx['item'] as String;
        dayProductSales[item] = (dayProductSales[item] ?? 0) + qty;
      }
    }

    final dateStr = '${_getDayName(date.weekday)}, ${date.day} ${_getMonthName(date.month)}';

    final details = dayProductSales.entries.map((e) => {
      'name': e.key,
      'qty': e.value,
    }).toList();

    dailyHistory.add({
      'date': date,
      'date_string': dateStr,
      'items_sold': soldOnDay,
      'details': details,
      'critical_items': inventoryList.where((item) => item['status'] == 'kritis').map((item) => item['name'] as String).toList(),
    });
  }

  return {
    'weekly_range': rangeStr,
    'weekly_top_products': topProductsWeekly,
    'weekly_critical_count': criticalCountWeekly,
    'rencana_kulaan': rencanaKulaan,
    'today_sold': totalSoldToday,
    'today_top_product': topSellingToday,
    'today_top_qty': topSellingQtyToday,
    'today_critical_stocks': criticalStocksToday,
    'daily_history': dailyHistory,
  };
});

String _getDayName(int weekday) {
  const names = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  return names[weekday - 1];
}

String _getMonthName(int month) {
  const names = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  // Safety bounds
  int index = month - 1;
  if (index < 0 || index >= names.length) index = 0;
  return names[index];
}

// 5. Transaction count provider (dipakai profil_screen)
// Sebelumnya didefinisikan inline di dalam build() lewat FutureProvider
// anonim, yang bikin provider baru dibuat ulang setiap rebuild (gak pernah
// di-cache Riverpod dengan benar) dan punya fallback 'warung_test_001'
// sendiri. Dipindah ke top-level, pola sama dengan provider lain di atas.
final transactionCountProvider = FutureProvider<int>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final storeId = prefs.getString('store_id');
  if (storeId == null || storeId.isEmpty) {
    throw const SessionExpiredException();
  }

  final snap = await FirebaseFirestore.instance
      .collection('stores')
      .doc(storeId)
      .collection('transactions')
      .get();
  return snap.docs.length;
});

// 6. Kulaan checklist provider (dari SharedPreferences — offline first)
class KulaanItem {
  final String name;
  final int qty;
  final bool checked;

  KulaanItem({required this.name, required this.qty, this.checked = false});

  KulaanItem copyWith({String? name, int? qty, bool? checked}) {
    return KulaanItem(
      name: name ?? this.name,
      qty: qty ?? this.qty,
      checked: checked ?? this.checked,
    );
  }
}

class KulaanChecklistNotifier extends StateNotifier<List<KulaanItem>> {
  KulaanChecklistNotifier() : super([]) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final lastFridayMillis = prefs.getInt('kulaan_last_friday') ?? 0;
    final lastFriday = DateTime.fromMillisecondsSinceEpoch(lastFridayMillis);

    final currentFriday = _getLastFriday(DateTime.now());

    if (currentFriday.isAfter(lastFriday)) {
      await prefs.remove('kulaan_checked_items');
      await prefs.setInt('kulaan_last_friday', currentFriday.millisecondsSinceEpoch);
    }
  }

  DateTime _getLastFriday(DateTime date) {
    int daysToSub = (date.weekday - DateTime.friday) % 7;
    if (daysToSub < 0) daysToSub += 7;
    final lastFri = date.subtract(Duration(days: daysToSub));
    return DateTime(lastFri.year, lastFri.month, lastFri.day);
  }

  Future<void> setItems(List<KulaanItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final checkedList = prefs.getStringList('kulaan_checked_items') ?? [];

    state = items.map((item) {
      final isChecked = checkedList.contains(item.name);
      return item.copyWith(checked: isChecked);
    }).toList();
  }

  Future<void> toggleItem(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final checkedList = prefs.getStringList('kulaan_checked_items') ?? [];

    final newList = List<String>.from(checkedList);
    if (newList.contains(name)) {
      newList.remove(name);
    } else {
      newList.add(name);
    }

    await prefs.setStringList('kulaan_checked_items', newList);

    state = state.map((item) {
      if (item.name == name) {
        return item.copyWith(checked: !item.checked);
      }
      return item;
    }).toList();
  }
}

final kulaanChecklistProvider = StateNotifierProvider<KulaanChecklistNotifier, List<KulaanItem>>((ref) {
  return KulaanChecklistNotifier();
});
