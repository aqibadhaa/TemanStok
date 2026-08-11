import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingItem {
  final String name;
  final int stock;

  OnboardingItem({required this.name, required this.stock});

  OnboardingItem copyWith({String? name, int? stock}) {
    return OnboardingItem(
      name: name ?? this.name,
      stock: stock ?? this.stock,
    );
  }
}

class OnboardingState {
  final String phoneNumber;
  final String shopName;
  final List<OnboardingItem> items;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  OnboardingState({
    this.phoneNumber = '',
    this.shopName = '',
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  OnboardingState copyWith({
    String? phoneNumber,
    String? shopName,
    List<OnboardingItem>? items,
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return OnboardingState(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      shopName: shopName ?? this.shopName,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier()
      : super(OnboardingState(
          items: List.generate(5, (_) => OnboardingItem(name: '', stock: 0)),
        ));

  String _sanitizePhone(String phone) {
    phone = phone.trim()
        .replaceAll('+', '')
        .replaceAll('-', '')
        .replaceAll(' ', '');
    if (phone.startsWith('0')) {
      phone = '62${phone.substring(1)}';
    } else if (!phone.startsWith('62')) {
      phone = '62$phone';
    }
    return phone;
  }

  void updatePhoneNumber(String phone) {
    state = state.copyWith(phoneNumber: phone);
  }

  void updateShopName(String name) {
    state = state.copyWith(shopName: name);
  }

  void updateItem(int index, {String? name, int? stock}) {
    final newItems = [...state.items];
    if (index >= 0 && index < newItems.length) {
      newItems[index] = newItems[index].copyWith(name: name, stock: stock);
      state = state.copyWith(items: newItems);
    }
  }

  void addItem() {
    if (state.items.length < 10) {
      state = state.copyWith(
        items: [...state.items, OnboardingItem(name: '', stock: 0)],
      );
    }
  }

  void removeItem(int index) {
    if (state.items.length > 5) {
      final newItems = [...state.items];
      newItems.removeAt(index);
      state = state.copyWith(items: newItems);
    }
  }

  Future<void> submit() async {
  state = state.copyWith(isLoading: true, errorMessage: null);

  final storeId = _sanitizePhone(state.phoneNumber);
  final db = FirebaseFirestore.instance;

  try {
    // 1. Simpan profil warung
    await db.collection('stores').doc(storeId).set({
      'store_id': storeId,
      'nama_warung': state.shopName,
      'owner_phone': storeId,
    });

    // 2. Simpan tiap barang ke inventory
    for (final item in state.items) {
      final initialStock = item.stock;
      final minStock = (initialStock * 0.2).round().clamp(1, 999);
      final maxStock = initialStock * 2;

      await db
          .collection('stores')
          .doc(storeId)
          .collection('inventory')
          .doc(item.name.trim())
          .set({
        'stock': initialStock,
        'min_stock': minStock,
        'max_stock': maxStock,
      });
    }

    // 3. Simpan session ke local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('store_id', storeId);

    state = state.copyWith(isLoading: false, isSuccess: true);
  } catch (e) {
    state = state.copyWith(isLoading: false, errorMessage: e.toString());
  }
}
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});