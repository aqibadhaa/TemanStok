import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';

class VoiceState {
  final bool isListening;
  final bool isLoading;
  final String transcript;
  final String statusMessage;
  final String? savedTranscript;
  final String? savedItemName;
  final int? qtyTerjual;
  final int? initialStock;
  final bool isBarangBaru;
  final bool isSuccess;

  const VoiceState({
    this.isListening = false,
    this.isLoading = false,
    this.transcript = '',
    this.statusMessage = 'Tekan mic untuk mulai',
    this.savedTranscript,
    this.savedItemName,
    this.qtyTerjual,
    this.initialStock,
    this.isBarangBaru = false,
    this.isSuccess = false,
  });

  VoiceState copyWith({
    bool? isListening,
    bool? isLoading,
    String? transcript,
    String? statusMessage,
    String? savedTranscript,
    String? savedItemName,
    int? qtyTerjual,
    int? initialStock,
    bool? isBarangBaru,
    bool? isSuccess,
  }) =>
      VoiceState(
        isListening: isListening ?? this.isListening,
        isLoading: isLoading ?? this.isLoading,
        transcript: transcript ?? this.transcript,
        statusMessage: statusMessage ?? this.statusMessage,
        savedTranscript: savedTranscript ?? this.savedTranscript,
        savedItemName: savedItemName ?? this.savedItemName,
        qtyTerjual: qtyTerjual ?? this.qtyTerjual,
        initialStock: initialStock ?? this.initialStock,
        isBarangBaru: isBarangBaru ?? this.isBarangBaru,
        isSuccess: isSuccess ?? this.isSuccess,
      );
}

class VoiceNotifier extends StateNotifier<VoiceState> {
  final SpeechToText _speech = SpeechToText();
  final Dio _dio = Dio(BaseOptions(
    headers: ApiConfig.headers,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  VoiceNotifier() : super(const VoiceState()) {
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onError: (error) => state = state.copyWith(
          statusMessage: 'Error mikrofon: ${error.errorMsg}',
          isListening: false,
        ),
      );

      if (available) {
        try {
          var locales = await _speech.locales();
          print("Supported Locales: ${locales.map((e) => e.localeId).toList()}");
        } catch (e) {
          print("Gagal ambil list bahasa: $e");
        }
      } else {
        state = state.copyWith(statusMessage: 'STT tidak tersedia di sistem ini');
      }
    } catch (e) {
      state = state.copyWith(statusMessage: 'Gagal inisialisasi: $e');
    }
  }

  Future<void> startListening() async {
    state = state.copyWith(
      transcript: '',
      statusMessage: 'Mendengarkan...',
      isListening: true,
    );

    String? localeToUse;
    try {
      var locales = await _speech.locales();
      if (locales.any((l) => l.localeId == 'id_ID')) {
        localeToUse = 'id_ID';
      }
    } catch (e) {
      print("Gagal ambil locales, pake default: $e");
    }

    await _speech.listen(
      localeId: localeToUse,
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
      onResult: (result) {
        state = state.copyWith(transcript: result.recognizedWords);
        if (result.finalResult) stopAndSend();
      },
    );
  }

  Future<void> stopAndSend() async {
    await _speech.stop();
    state = state.copyWith(isListening: false);

    if (state.transcript.trim().isEmpty) {
      state = state.copyWith(statusMessage: 'Tidak ada suara yang terdeteksi');
      return;
    }

    await _kirimKeWebhook(state.transcript.trim());
  }

  Future<void> _kirimKeWebhook(String transcript) async {
    state = state.copyWith(isLoading: true, statusMessage: 'Mengirim...');

    try {
      final storeId = await ApiConfig.getStoreId(); // ← dynamic dari session

      final response = await _dio.post(
        ApiConfig.webhookUrl,
        data: {
          'store_id': storeId,
          'transcript': transcript,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['intent'] == 'barang_baru') {
          state = state.copyWith(
            statusMessage: 'Item belum terdaftar',
            savedTranscript: transcript,
            savedItemName: data['item'],
            isBarangBaru: true,
          );
        } else {
          state = state.copyWith(
            statusMessage: '✅ ${data['item']} terjual ${data['qty']}',
          );
        }
      } else {
        state = state.copyWith(
          statusMessage: '❌ Gagal: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      final msg = e.type == DioExceptionType.connectionTimeout
          ? 'Timeout — cek koneksi atau status ngrok'
          : 'Error: ${e.message}';
      state = state.copyWith(statusMessage: '❌ $msg');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> submitBarangBaru(int initialStock) async {
    state = state.copyWith(isLoading: true, statusMessage: 'Menyimpan stok...');

    try {
      final storeId = await ApiConfig.getStoreId(); // ← dynamic dari session

      final response = await _dio.post(
        ApiConfig.webhookUrl,
        data: {
          'store_id': storeId,
          'transcript': state.savedTranscript,
          'initial_stock': initialStock,
        },
      );

      if (response.data['success'] == true) {
        print('FULL RESPONSE: ${response.data}');
        print('QTY TERJUAL: ${response.data['qty_terjual']}');
        state = state.copyWith(
          initialStock: initialStock,
          qtyTerjual: int.tryParse(
                  response.data['qty_terjual']?.toString() ?? '0') ??
              0,
          isSuccess: true,
        );
      } else {
        state = state.copyWith(statusMessage: '❌ Gagal menyimpan');
      }
    } catch (e) {
      state = state.copyWith(statusMessage: '❌ Terjadi kesalahan: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void resetToMic() {
    state = const VoiceState();
  }

  void clearTriggers() {
    state = state.copyWith(isBarangBaru: false, isSuccess: false);
  }
}

final voiceProvider = StateNotifierProvider<VoiceNotifier, VoiceState>(
  (ref) => VoiceNotifier(),
);