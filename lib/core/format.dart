import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config.dart';

final _rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

String rupiah(num v) => _rupiah.format(v);
String rupiahShort(num v) {
  if (v >= 1000000000) return 'Rp ${(v / 1000000000).toStringAsFixed(1)} M';
  if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(1)} jt';
  if (v >= 1000) return 'Rp ${(v / 1000).toStringAsFixed(0)} rb';
  return rupiah(v);
}

DateTime? parseDate(String? s) {
  if (s == null || s.isEmpty) return null;
  return DateTime.tryParse(s);
}

String tanggal(String? s, {String fallback = '-'}) {
  final d = parseDate(s);
  if (d == null) return fallback;
  return DateFormat('d MMM yyyy', 'id_ID').format(d);
}

String tanggalWaktu(String? s, {String fallback = '-'}) {
  final d = parseDate(s);
  if (d == null) return fallback;
  return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(d);
}

String inputDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

String statusPesananLabel(String s) => switch (s) {
      'pending' => 'Menunggu',
      'diproses' => 'Diproses',
      'selesai' => 'Selesai',
      'batal' => 'Dibatalkan',
      'ditolak' => 'Ditolak',
      _ => s,
    };

Color statusPesananColor(String s) {
  switch (s) {
    case 'pending':
      return AppColors.warning;
    case 'diproses':
      return AppColors.info;
    case 'selesai':
      return AppColors.success;
    case 'batal':
    case 'ditolak':
      return AppColors.danger;
    default:
      return AppColors.muted;
  }
}

String statusBayarLabel(String? s) {
  if (s == null || s.isEmpty) return 'Belum Bayar';
  return s;
}

Color statusPembayaranColor(String? s) {
  switch ((s ?? '').toLowerCase()) {
    case 'lunas':
      return AppColors.success;
    case 'pending':
    case 'menunggu konfirmasi':
      return AppColors.info;
    case 'gagal':
    case 'ditolak':
    case 'batal':
      return AppColors.danger;
    case 'kadaluarsa':
      return AppColors.muted;
    default:
      return AppColors.warning;
  }
}

String supirLabel(String opsi) {
  switch (opsi) {
    case 'dengan_supir':
      return 'Wajib dengan supir';
    case 'keduanya':
      return 'Bisa dengan / tanpa supir';
    default:
      return 'Tanpa supir';
  }
}
