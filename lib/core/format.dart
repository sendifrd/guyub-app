import 'package:intl/intl.dart';

final _rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

/// 15000 -> "Rp15.000"
String rupiah(num value) => _rupiah.format(value);

/// DateTime -> "Kam, 15 Okt" (zona waktu mengikuti HP; server menyimpan WIB/timestamptz)
String tanggalPendek(DateTime d) => DateFormat('EEE, d MMM', 'id_ID').format(d.toLocal());

/// DateTime -> "13.00"
String jam(DateTime d) => DateFormat('HH.mm', 'id_ID').format(d.toLocal());
