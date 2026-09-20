/// Exception generik untuk kondisi "seharusnya ada sesi aktif tapi kosong".
/// Dipakai provider dan layar yang butuh store_id, supaya kegagalan sesi
/// bisa dibedakan dari error lain (network, Firestore, dsb) di lapisan UI
/// lewat AsyncValue.error atau try/catch biasa.
class SessionExpiredException implements Exception {
  final String message;
  const SessionExpiredException([
    this.message = 'Sesi tidak ditemukan, silakan masuk kembali',
  ]);

  @override
  String toString() => message;
}
