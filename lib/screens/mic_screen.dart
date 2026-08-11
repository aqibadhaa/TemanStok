import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../providers/voice_provider.dart';

class MicScreen extends ConsumerStatefulWidget {
  const MicScreen({super.key});

  @override
  ConsumerState<MicScreen> createState() => _MicScreenState();
}

class _MicScreenState extends ConsumerState<MicScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final _stockController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Langsung mulai listening begitu halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceProvider.notifier).resetToMic();
      ref.read(voiceProvider.notifier).startListening();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _showInitialStockDialog(String itemName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E2D3E),
          title: Text(
            'Barang Baru Terdeteksi',
            style: AppTheme.headingMedium.copyWith(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Barang "$itemName" belum terdaftar. Masukkan stok awal untuk mendaftarkannya.',
                style: AppTheme.body.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Stok Awal',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryLight),
                  ),
                  border: const OutlineInputBorder(),
                  hintText: 'Contoh: 10',
                  hintStyle: const TextStyle(color: Colors.white30),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                ref.read(voiceProvider.notifier).resetToMic();
                Navigator.of(context).pop();
              },
              child: const Text('Batal', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () {
                final stock = int.tryParse(_stockController.text) ?? 0;
                if (stock <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Stok awal harus lebih dari 0')),
                  );
                  return;
                }
                Navigator.of(context).pop();
                ref.read(voiceProvider.notifier).submitBarangBaru(stock);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceProvider);

    // Pop otomatis setelah proses selesai
    ref.listen<VoiceState>(voiceProvider, (previous, next) {
      if (next.isSuccess && !(previous?.isSuccess ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Stok berhasil disimpan!'), backgroundColor: AppTheme.primary),
        );
        Navigator.of(context).pop();
      }

      if (previous != null && previous.isLoading && !next.isLoading && !next.isBarangBaru) {
        if (next.statusMessage.startsWith('✅')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.statusMessage), backgroundColor: AppTheme.primary),
          );
          Navigator.of(context).pop();
        } else if (next.statusMessage.startsWith('❌')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.statusMessage), backgroundColor: AppTheme.statusKritis),
          );
        }
      }

      if (next.isBarangBaru && !(previous?.isBarangBaru ?? false)) {
        _showInitialStockDialog(next.savedItemName ?? 'Barang');
      }
    });

    // Determine state descriptions
    String titleText = 'Tekan mic untuk mencatat';
    if (voiceState.isLoading) {
      titleText = 'Memproses...';
    } else if (voiceState.isListening) {
      titleText = 'Mendengarkan....';
    }

    final showIdleContent = !voiceState.isListening && !voiceState.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.micScreenBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding, vertical: 16.0),
          child: Column(
            children: [
              // Header Row: Close Button & Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    onPressed: () {
                      ref.read(voiceProvider.notifier).resetToMic();
                      Navigator.of(context).pop();
                    },
                  ),
                  Text(
                    'Catatan Transaksi',
                    style: AppTheme.headingMedium.copyWith(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(width: 48), // Spacer to balance
                ],
              ),
              const Spacer(),

              // Teks State & Transcript
              Text(
                titleText,
                style: AppTheme.headingBold.copyWith(color: Colors.white, fontSize: 26),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (!showIdleContent && voiceState.transcript.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '"${voiceState.transcript}"',
                    style: AppTheme.body.copyWith(
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (showIdleContent)
                Text(
                  'Sebutkan barang & jumlahnya',
                  style: AppTheme.caption.copyWith(color: Colors.white54, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              const Spacer(),

              // Pulsing Mic Button
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  double scale = 1.0;
                  double glow = 0.0;
                  if (voiceState.isListening) {
                    scale = 1.0 + (_pulseController.value * 0.1);
                    glow = _pulseController.value * 8;
                  }
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1A2F45),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(voiceState.isListening ? 0.6 : 0.0),
                            blurRadius: 16,
                            spreadRadius: glow,
                          ),
                          const BoxShadow(
                            color: Colors.black38,
                            blurRadius: 20,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: Center(
                        child: voiceState.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : IconButton(
                                icon: const Icon(Icons.mic_rounded, color: Colors.white, size: 48),
                                onPressed: () {
                                  if (voiceState.isListening) {
                                    ref.read(voiceProvider.notifier).stopAndSend();
                                  } else {
                                    ref.read(voiceProvider.notifier).startListening();
                                  }
                                },
                              ),
                      ),
                    ),
                  );
                },
              ),
              const Spacer(),

              // Status message (if error or info)
              if (voiceState.statusMessage.isNotEmpty && voiceState.statusMessage != 'Tekan mic untuk mulai')
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    voiceState.statusMessage,
                    style: TextStyle(
                      color: voiceState.statusMessage.startsWith('❌') ? AppTheme.statusKritis : Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Examples card
              if (showIdleContent)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONTOH UCAPAN',
                        style: AppTheme.caption.copyWith(color: Colors.white54, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '"Kopi hitam terjual 3"',
                        style: AppTheme.body.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '"Masuk Indomie 24 bungkus"',
                        style: AppTheme.body.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '"Rokok Surya keluar 5"',
                        style: AppTheme.body.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
