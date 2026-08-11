//input_barang_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/onboarding_provider.dart';

class InputBarangScreen extends ConsumerStatefulWidget {
  const InputBarangScreen({super.key});

  @override
  ConsumerState<InputBarangScreen> createState() => _InputBarangScreenState();
}

class _InputBarangScreenState extends ConsumerState<InputBarangScreen> {
  final _formKey = GlobalKey<FormState>();

  Future<void> _onFinish() async {
    if (_formKey.currentState!.validate()) {
      final state = ref.read(onboardingProvider);
      if (state.items.length < 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Minimal daftarkan 5 barang')),
        );
        return;
      }

      await ref.read(onboardingProvider.notifier).submit();

      final newState = ref.read(onboardingProvider);
      if (newState.isSuccess) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      } else if (newState.errorMessage != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal: ${newState.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);
    final items = onboardingState.items;
    final isLoading = onboardingState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Barang Awal'),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Daftarkan 5–10 Barang Terlaris',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Ini akan membantu kami mengatur stok awal warungmu.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              initialValue: items[index].name,
                              decoration: InputDecoration(
                                labelText: 'Nama Barang ${index + 1}',
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onChanged: (val) {
                                ref.read(onboardingProvider.notifier).updateItem(index, name: val);
                              },
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Wajib isi';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: items[index].stock > 0 ? items[index].stock.toString() : '',
                              decoration: const InputDecoration(
                                labelText: 'Stok',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                final stock = int.tryParse(val) ?? 0;
                                ref.read(onboardingProvider.notifier).updateItem(index, stock: stock);
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Wajib isi';
                                }
                                final stock = int.tryParse(value);
                                if (stock == null || stock <= 0) {
                                  return '> 0';
                                }
                                return null;
                              },
                            ),
                          ),
                          if (items.length > 5)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () {
                                ref.read(onboardingProvider.notifier).removeItem(index);
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (items.length < 10)
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(onboardingProvider.notifier).addItem();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Barang'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: isLoading ? null : _onFinish,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Selesai & Masuk Dashboard',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}