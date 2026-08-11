//Voice Input Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/voice_provider.dart';

class VoiceInputScreen extends ConsumerWidget {
  const VoiceInputScreen({super.key});

  String _capitalize(String? text) {
    if (text == null || text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInputStokBottomSheet(
    BuildContext context,
    WidgetRef ref,
    String itemName,
  ) {
    final controller = TextEditingController();
    bool isValid = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🆕 Wah, "${_capitalize(itemName)}" belum ada di daftar produk nih!',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Yuk isi stok terkini dulu\n(sebelum terjual tadi)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Stok saat ini',
                  hintText: 'contoh: 30',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.inventory),
                ),
                onChanged: (val) {
                  setState(() {
                    final n = int.tryParse(val);
                    isValid = n != null && n > 0;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Masukkan jumlah stok SEBELUM terjual tadi',
                      style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isValid
                      ? () {
                          final stock = int.parse(controller.text);
                          Navigator.pop(context);
                          ref.read(voiceProvider.notifier).submitBarangBaru(stock);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Submit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showKonfirmasiDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String itemName,
    required int initialStock,
    required int qtyTerjual,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Berhasil input stok awal'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_capitalize(itemName)} ($initialStock pcs).'),
            const SizedBox(height: 16),
            const Text('Dan saat ini'),
            Text(
              '${_capitalize(itemName)} terjual $qtyTerjual?',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(voiceProvider.notifier).resetToMic();
            },
            child: Text('✏️ Edit', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessSnackbar(context, '✅ ${_capitalize(itemName)} terjual $qtyTerjual');
              ref.read(voiceProvider.notifier).resetToMic();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('✅ Benar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(voiceProvider);
    final notifier = ref.read(voiceProvider.notifier);

    ref.listen(voiceProvider, (previous, next) {
      if (next.isBarangBaru && !(previous?.isBarangBaru ?? false)) {
        notifier.clearTriggers();
        _showInputStokBottomSheet(context, ref, next.savedItemName ?? '');
      }
      if (next.isSuccess && !(previous?.isSuccess ?? false)) {
        notifier.clearTriggers();
        _showKonfirmasiDialog(
          context: context,
          ref: ref,
          itemName: next.savedItemName ?? '',
          initialStock: next.initialStock ?? 0,
          qtyTerjual: next.qtyTerjual ?? 0,
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('WarungAI'),
        actions: [
          IconButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('store_id');
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                state.transcript.isEmpty
                    ? 'Transcript muncul di sini...'
                    : state.transcript,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            Text(state.statusMessage, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: state.isLoading
                  ? null
                  : (state.isListening
                      ? notifier.stopAndSend
                      : notifier.startListening),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state.isListening ? Colors.red : Colors.blue,
                  boxShadow: state.isListening
                      ? [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 8,
                          )
                        ]
                      : [],
                ),
                child: state.isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Icon(
                        state.isListening ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 36,
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              state.isListening ? 'Tap untuk stop' : 'Tap untuk bicara',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}