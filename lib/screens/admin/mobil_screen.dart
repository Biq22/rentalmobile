import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../config.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../services/uploader.dart';
import '../../widgets/common.dart';

class MobilScreen extends StatefulWidget {
  const MobilScreen({super.key});

  @override
  State<MobilScreen> createState() => _MobilScreenState();
}

class _MobilScreenState extends State<MobilScreen> {
  List<Mobil> _items = [];
  List<Kategori> _kategori = [];
  bool _loading = true;
  String? _error;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final q = <String, String>{};
      if (_search.text.trim().isNotEmpty) q['q'] = _search.text.trim();
      final results = await Future.wait([
        Api().get('mobil.php', query: q),
        Api().get('kategori.php'),
      ]);
      _items = (results[0]['data'] as List).map((e) => Mobil.fromJson(e)).toList();
      _kategori = (results[1]['data'] as List).map((e) => Kategori.fromJson(e)).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([Mobil? mobil]) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _MobilForm(mobil: mobil, kategori: _kategori),
    );
    if (changed == true) _load();
  }

  Future<void> _hapus(Mobil m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus mobil?'),
        content: Text('${m.kategori} ${m.tipe} (${m.platNomer}) akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api().delete('mobil.php', query: {'id': '${m.idMobil}'});
      if (mounted) showSnack(context, 'Mobil dihapus');
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBody(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  onSubmitted: (_) => _load(),
                  decoration: InputDecoration(
                    hintText: 'Cari mobil / plat…',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.line)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(onPressed: () => _openForm(), icon: const Icon(Icons.add), label: const Text('Tambah')),
            ]),
          ),
        ),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return AppError(message: _error!, onRetry: _load);
    if (_items.isEmpty) return const AppEmpty(title: 'Belum ada mobil', message: 'Tambahkan mobil pertama kamu.');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final m = _items[i];
          return AppBody(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
              child: Row(children: [
                CarImage(foto: m.foto, height: 70, width: 94),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text('${m.kategori} ${m.tipe}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                      StatusChip(label: m.status, color: m.tersedia ? AppColors.success : AppColors.warning),
                    ]),
                    const SizedBox(height: 4),
                    Text('${m.platNomer} · ${m.tahun} · ${m.transmisi ?? '-'}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 14, children: [
                      Text(rupiah(m.harga), style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w700)),
                      if (m.bisaDenganSupir) Text('Supir ${rupiahShort(m.hargaSupir)}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    ]),
                  ]),
                ),
                IconButton(onPressed: () => _openForm(m), icon: const Icon(Icons.edit_outlined, color: AppColors.brand)),
                IconButton(onPressed: () => _hapus(m), icon: const Icon(Icons.delete_outline, color: AppColors.danger)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _MobilForm extends StatefulWidget {
  final Mobil? mobil;
  final List<Kategori> kategori;
  const _MobilForm({this.mobil, required this.kategori});

  @override
  State<_MobilForm> createState() => _MobilFormState();
}

class _MobilFormState extends State<_MobilForm> {
  final _tipe = TextEditingController();
  final _plat = TextEditingController();
  final _tahun = TextEditingController();
  final _warna = TextEditingController();
  final _kondisi = TextEditingController(text: 'Baik');
  final _harga = TextEditingController();
  final _kapasitas = TextEditingController();
  final _hargaSupir = TextEditingController();
  int? _idKategori;
  String _transmisi = 'Manual';
  String _opsiSupir = 'keduanya';
  String _status = 'tersedia';
  String? _foto;
  Uint8List? _localBytes;
  List<String> _galeri = [];
  bool _uploading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.mobil;
    if (m != null) {
      _tipe.text = m.tipe;
      _plat.text = m.platNomer;
      _tahun.text = m.tahun;
      _warna.text = m.warna;
      _kondisi.text = m.kondisi;
      _harga.text = m.harga.toStringAsFixed(0);
      _kapasitas.text = m.kapasitas?.toString() ?? '';
      _hargaSupir.text = m.hargaSupir.toStringAsFixed(0);
      _idKategori = m.idKategori;
      _transmisi = m.transmisi ?? 'Manual';
      _opsiSupir = m.opsiSupir;
      _status = m.status;
      _foto = m.foto;
      _galeri = List<String>.from(m.galeri);
    } else if (widget.kategori.isNotEmpty) {
      _idKategori = widget.kategori.first.idKategori;
    }
  }

  @override
  void dispose() {
    for (final c in [_tipe, _plat, _tahun, _warna, _kondisi, _harga, _kapasitas, _hargaSupir]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    final res = await pickAndUploadImage(context, onBusy: (busy) {
      if (mounted) setState(() => _uploading = busy);
    });
    if (!mounted || res == null) return;
    setState(() {
      _foto = res.filename;
      _localBytes = res.bytes;
    });
  }

  Future<void> _pickGaleri() async {
    final res = await pickAndUploadImage(context, onBusy: (busy) {
      if (mounted) setState(() => _uploading = busy);
    });
    if (!mounted || res == null) return;
    setState(() => _galeri = [..._galeri, res.filename]);
  }

  Widget _galeriSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('Galeri tambahan', style: TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          TextButton.icon(
            onPressed: _uploading ? null : _pickGaleri,
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
            label: const Text('Tambah foto'),
          ),
        ]),
        if (_galeri.isEmpty)
          const Text('Belum ada foto tambahan.', style: TextStyle(color: AppColors.muted, fontSize: 12))
        else
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _galeri.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => Stack(
                children: [
                  CarImage(foto: _galeri[i], height: 80, width: 110),
                  Positioned(
                    top: 0, right: 0,
                    child: GestureDetector(
                      onTap: () => setState(() => _galeri = [..._galeri]..removeAt(i)),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Preview foto: pakai byte lokal kalau baru diunggah (langsung tampil),
  /// kalau tidak ambil dari server lewat [CarImage].
  Widget _fotoPreview() {
    final b = _localBytes;
    if (b != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(b, height: 80, width: 110, fit: BoxFit.cover),
      );
    }
    return CarImage(foto: _foto, height: 80, width: 110);
  }

  Future<void> _save() async {
    if (_idKategori == null || _tipe.text.trim().isEmpty || _plat.text.trim().isEmpty || _tahun.text.trim().isEmpty || _harga.text.trim().isEmpty) {
      showSnack(context, 'Lengkapi field wajib (kategori, tipe, plat, tahun, harga)', error: true);
      return;
    }
    setState(() => _saving = true);
    final kategoriNama = widget.kategori.firstWhere((k) => k.idKategori == _idKategori).nama;
    final body = {
      'id_kategori': _idKategori,
      'kategori': kategoriNama,
      'tipe': _tipe.text.trim(),
      'plat_nomer': _plat.text.trim(),
      'tahun': _tahun.text.trim(),
      'warna': _warna.text.trim(),
      'kondisi': _kondisi.text.trim(),
      'harga_sewa_per_hari': double.tryParse(_harga.text.trim()) ?? 0,
      'status': _status,
      'foto': _foto,
      'kapasitas': _kapasitas.text.trim().isEmpty ? null : int.tryParse(_kapasitas.text.trim()),
      'transmisi': _transmisi,
      'opsi_supir': _opsiSupir,
      'harga_supir_per_hari': double.tryParse(_hargaSupir.text.trim()) ?? 0,
      'galeri': _galeri,
    };
    try {
      if (widget.mobil == null) {
        await Api().post('mobil.php', body);
      } else {
        await Api().put('mobil.php', body, query: {'id': '${widget.mobil!.idMobil}'});
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.mobil == null ? 'Tambah Mobil' : 'Edit Mobil'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                _fotoPreview(),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  OutlinedButton.icon(
                    onPressed: _uploading ? null : _pick,
                    icon: _uploading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.upload),
                    label: Text(_uploading ? 'Mengunggah…' : 'Upload Foto'),
                  ),
                  if (_foto != null || _localBytes != null)
                    TextButton.icon(
                      onPressed: _uploading ? null : () => setState(() {
                        _foto = null;
                        _localBytes = null;
                      }),
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                      label: const Text('Hapus foto', style: TextStyle(color: AppColors.danger)),
                    ),
                ]),
              ]),
              const SizedBox(height: 8),
              _galeriSection(),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _idKategori,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: widget.kategori.map((k) => DropdownMenuItem(value: k.idKategori, child: Text(k.nama))).toList(),
                onChanged: (v) => setState(() => _idKategori = v),
              ),
              const SizedBox(height: 12),
              _t(_tipe, 'Tipe (mis. Avanza)'),
              _t(_plat, 'Plat nomer'),
              _t(_tahun, 'Tahun', type: TextInputType.number),
              _t(_warna, 'Warna'),
              _t(_kondisi, 'Kondisi'),
              _t(_harga, 'Harga sewa / hari', type: TextInputType.number),
              _t(_kapasitas, 'Kapasitas kursi', type: TextInputType.number),
              DropdownButtonFormField<String>(
                initialValue: _transmisi,
                decoration: const InputDecoration(labelText: 'Transmisi'),
                items: const [DropdownMenuItem(value: 'Manual', child: Text('Manual')), DropdownMenuItem(value: 'Automatic', child: Text('Automatic'))],
                onChanged: (v) => setState(() => _transmisi = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _opsiSupir,
                decoration: const InputDecoration(labelText: 'Opsi Supir'),
                items: const [
                  DropdownMenuItem(value: 'tanpa_supir', child: Text('Tanpa supir')),
                  DropdownMenuItem(value: 'dengan_supir', child: Text('Dengan supir')),
                  DropdownMenuItem(value: 'keduanya', child: Text('Keduanya')),
                ],
                onChanged: (v) => setState(() => _opsiSupir = v!),
              ),
              const SizedBox(height: 12),
              _t(_hargaSupir, 'Harga supir / hari', type: TextInputType.number),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [DropdownMenuItem(value: 'tersedia', child: Text('Tersedia')), DropdownMenuItem(value: 'disewa', child: Text('Disewa'))],
                onChanged: (v) => setState(() => _status = v!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Batal')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Simpan'),
        ),
      ],
    );
  }

  Widget _t(TextEditingController c, String label, {TextInputType? type}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(controller: c, keyboardType: type, decoration: InputDecoration(labelText: label)),
      );
}

