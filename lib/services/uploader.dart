import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/common.dart';
import 'api.dart';

/// Hasil upload foto: nama file di server + byte lokal untuk preview instan
/// (biar foto langsung kelihatan tanpa nunggu ambil ulang dari server).
class UploadResult {
  final String filename;
  final Uint8List bytes;
  const UploadResult(this.filename, this.bytes);
}

/// Batas ukuran file, samakan dengan validasi di server (upload.php).
const int _maxFotoBytes = 3 * 1024 * 1024; // 3 MB

/// Deteksi jenis gambar dari magic bytes (lebih andal daripada ekstensi nama).
String? _imageExt(List<int> b) {
  if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) return 'jpg';
  if (b.length >= 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) return 'png';
  if (b.length >= 12 &&
      b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 &&
      b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50) {
    return 'webp';
  }
  return null;
}

/// Bersihkan nama file agar aman dikirim ke server, pakai ekstensi hasil deteksi.
String _safeName(String original, String ext) {
  final dot = original.lastIndexOf('.');
  final base = dot > 0 ? original.substring(0, dot) : original;
  final safe = base.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
  return '${safe.isEmpty ? 'foto' : safe}.$ext';
}

/// Pilih gambar dari galeri, validasi, lalu upload.
///
/// [onBusy] dipanggil `true` saat proses upload ke server berjalan (untuk
/// menampilkan spinner) dan `false` saat selesai — pemilihan file sendiri tidak
/// memicu spinner karena memakai dialog bawaan sistem/browser.
Future<UploadResult?> pickAndUploadImage(
  BuildContext context, {
  bool camera = false,
  void Function(bool busy)? onBusy,
}) async {
  try {
    final picked = await ImagePicker().pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();

    // Validasi format berdasarkan isi file, bukan cuma ekstensi.
    final ext = _imageExt(bytes);
    if (ext == null) {
      if (context.mounted) showSnack(context, 'Format foto harus JPG, PNG, atau WEBP', error: true);
      return null;
    }
    if (bytes.length > _maxFotoBytes) {
      if (context.mounted) showSnack(context, 'Ukuran foto maksimal 3 MB', error: true);
      return null;
    }

    onBusy?.call(true);
    final res = await Api().uploadBytes(bytes, _safeName(picked.name, ext));
    final filename = (res['filename'] as String?)?.trim();
    if (filename == null || filename.isEmpty) {
      if (context.mounted) showSnack(context, 'Server tidak mengembalikan nama file', error: true);
      return null;
    }
    if (context.mounted) showSnack(context, 'Foto berhasil diunggah');
    return UploadResult(filename, bytes);
  } on ApiException catch (e) {
    if (context.mounted) showSnack(context, e.message, error: true);
    return null;
  } catch (e) {
    if (context.mounted) showSnack(context, 'Gagal mengunggah foto', error: true);
    return null;
  } finally {
    onBusy?.call(false);
  }
}
