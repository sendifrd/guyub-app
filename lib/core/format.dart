import 'package:intl/intl.dart';

final _rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

/// 15000 -> "Rp15.000"
String rupiah(num value) => _rupiah.format(value);

/// DateTime -> "Kam, 15 Okt" (zona waktu mengikuti HP; server menyimpan WIB/timestamptz)
String tanggalPendek(DateTime d) => DateFormat('EEE, d MMM', 'id_ID').format(d.toLocal());

/// DateTime -> "13.00"
String jam(DateTime d) => DateFormat('HH.mm', 'id_ID').format(d.toLocal());

/// DateTime -> "Kamis, 22 Oktober"
String tanggalPanjang(DateTime d) => DateFormat('EEEE, d MMMM', 'id_ID').format(d.toLocal());

/// "Kam" / "22" / "Okt" untuk kotak tanggal
String hariSingkat(DateTime d) => DateFormat('EEE', 'id_ID').format(d.toLocal());
String bulanSingkat(DateTime d) => DateFormat('MMM', 'id_ID').format(d.toLocal());

/// Waktu relatif untuk notifikasi: "baru saja", "5 menit lalu", "3 jam lalu", "Kemarin", "12 Okt"
String waktuRelatif(DateTime d) {
  final selisih = DateTime.now().difference(d.toLocal());
  if (selisih.inMinutes < 1) return 'baru saja';
  if (selisih.inMinutes < 60) return '${selisih.inMinutes} menit lalu';
  if (selisih.inHours < 24) return '${selisih.inHours} jam lalu';
  if (selisih.inDays == 1) return 'Kemarin';
  if (selisih.inDays < 7) return '${selisih.inDays} hari lalu';
  return DateFormat('d MMM', 'id_ID').format(d.toLocal());
}

/// Huruf depan nama untuk avatar: "Rina Aulia" -> "RA"
String inisial(String nama) {
  final kata = nama.trim().split(RegExp(r'\s+')).where((k) => k.isNotEmpty && RegExp(r'[A-Za-z]').hasMatch(k[0])).toList();
  if (kata.isEmpty) return '?';
  return (kata.first[0] + (kata.length > 1 ? kata[1][0] : '')).toUpperCase();
}
