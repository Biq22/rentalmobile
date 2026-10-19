import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';

class PengaturanScreen extends StatefulWidget {
  const PengaturanScreen({super.key});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _Field {
  final String kunci;
  final String label;
  final int lines;
  final bool numeric;
  const _Field(this.kunci, this.label, {this.lines = 1, this.numeric = false});
}

const _fields = <_Field>[
  _Field('nama_perusahaan', 'Nama Perusahaan'),
  _Field('telepon', 'Telepon'),
  _Field('email', 'Email'),
  _Field('alamat', 'Alamat', lines: 2),
  _Field('jam_operasional', 'Jam Operasional'),
  _Field('visi', 'Visi', lines: 2),
  _Field('tentang', 'Tentang Kami', lines: 4),
  _Field('tarif_denda_per_hari', 'Tarif Denda per Hari (Rp)', numeric: true),
  _Field('rekening', 'Rekening Transfer', lines: 2),
  _Field('qris', 'QRIS / Kode Pembayaran'),
];

class _PengaturanScreenState extends State<PengaturanScreen> {
  final _controllers = <String, TextEditingController>{};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await Api().get('pengaturan.php');
      final p = Pengaturan.fromJson(res['data'] as Map<String, dynamic>);
      for (final f in _fields) {
        _controllers[f.kunci] = TextEditingController(text: p[f.kunci]);
      }
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{};
      for (final f in _fields) {
        body[f.kunci] = _controllers[f.kunci]!.text.trim();
      }
      await Api().put('pengaturan.php', body);
      if (mounted) showSnack(context, 'Pengaturan disimpan');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return AppError(message: _error!, onRetry: _load);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppBody(
          maxWidth: 720,
          child: SectionCard(
            title: 'Informasi Perusahaan',
            icon: Icons.storefront_outlined,
            child: Column(
              children: [
                for (final f in _fields) ...[
                  TextField(
                    controller: _controllers[f.kunci],
                    maxLines: f.lines,
                    keyboardType: f.numeric ? TextInputType.number : TextInputType.text,
                    decoration: InputDecoration(labelText: f.label),
                  ),
                  const SizedBox(height: 14),
                ],
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Menyimpan…' : 'Simpan Pengaturan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
