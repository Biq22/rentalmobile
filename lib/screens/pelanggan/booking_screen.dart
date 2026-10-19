import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../config.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../services/uploader.dart';
import '../../widgets/common.dart';
import 'payment_screen.dart';

class BookingScreen extends StatefulWidget {
  final Mobil mobil;
  const BookingScreen({super.key, required this.mobil});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _mulai;
  DateTime? _selesai;
  bool _pakaiSupir = false;
  TimeOfDay? _jam;
  bool _loading = false;
  bool _loadingInit = true;
  String? _initError;

  final _email = TextEditingController();
  final _nama = TextEditingController();
  final _telpon = TextEditingController();
  final _ktp = TextEditingController();
  final _alamat = TextEditingController();
  final _pekerjaan = TextEditingController();
  final _kodePromo = TextEditingController();

  String? _fotoKtp;
  Uint8List? _ktpBytes;
  bool _uploadingKtp = false;

  List<Promo> _promos = [];
  Promo? _promo;
  bool _setuju = false;

  double get _lama {
    if (_mulai == null || _selesai == null) return 0;
    final d = _selesai!.difference(_mulai!).inDays + 1;
    return d < 1 ? 1 : d.toDouble();
  }

  double get _biayaSupir => _pakaiSupir ? widget.mobil.hargaSupir * _lama : 0;

  double get _sewa => widget.mobil.harga * _lama;

  double get _subtotal => _sewa + _biayaSupir;

  double get _diskon {
    final p = _promo;
    if (p == null) return 0;
    final s = _subtotal;
    if (s < p.minTransaksi) return 0;
    var d = p.persen ? s * p.nilai / 100 : p.nilai;
    if (p.maksDiskon != null && d > p.maksDiskon!) d = p.maksDiskon!;
    if (d > s) d = s;
    return d;
  }

  double get _total => _subtotal - _diskon;

  String get _labelWaktu => _pakaiSupir ? 'Waktu Diantarkan' : 'Waktu Ambil';

  @override
  void initState() {
    super.initState();
    _pakaiSupir = widget.mobil.opsiSupir == 'dengan_supir';
    _mulai = DateTime.now();
    _selesai = DateTime.now().add(const Duration(days: 1));
    _loadInit();
  }

  @override
  void dispose() {
    _email.dispose();
    _nama.dispose();
    _telpon.dispose();
    _ktp.dispose();
    _alamat.dispose();
    _pekerjaan.dispose();
    _kodePromo.dispose();
    super.dispose();
  }

  Future<void> _loadInit() async {
    setState(() {
      _loadingInit = true;
      _initError = null;
    });
    try {
      final results = await Future.wait([
        Api().get('profil.php'),
        Api().get('promo.php'),
      ]);
      final u = results[0]['data'] as Map;
      _nama.text = (u['nama'] ?? '').toString();
      _email.text = (u['email'] ?? '').toString();
      _telpon.text = (u['no_telpon'] ?? '').toString();
      _ktp.text = (u['no_ktp'] ?? '').toString();
      _alamat.text = (u['alamat'] ?? '').toString();
      _pekerjaan.text = (u['pekerjaan'] ?? '').toString();
      final fk = u['foto_ktp'];
      if (fk != null && fk.toString().isNotEmpty) _fotoKtp = fk.toString();
      _promos = (results[1]['data'] as List).map((e) => Promo.fromJson(e)).toList();
    } on ApiException catch (e) {
      _initError = e.message;
    } finally {
      if (mounted) setState(() => _loadingInit = false);
    }
  }

  Future<void> _pickTanggal({required bool isMulai}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isMulai ? _mulai : _selesai,
      firstDate: isMulai ? now : (_mulai ?? now),
      lastDate: now.add(const Duration(days: 365)),
      helpText: isMulai ? 'Tanggal mulai sewa' : 'Tanggal selesai sewa',
    );
    if (picked == null) return;
    setState(() {
      if (isMulai) {
        _mulai = picked;
        if (_selesai == null || _selesai!.isBefore(_mulai!)) {
          _selesai = _mulai!.add(const Duration(days: 1));
        }
      } else {
        _selesai = picked;
      }
    });
  }

  Future<void> _pickJam() async {
    final picked = await showTimePicker(context: context, initialTime: _jam ?? const TimeOfDay(hour: 9, minute: 0));
    if (picked != null) setState(() => _jam = picked);
  }

  Future<void> _uploadKtp() async {
    final res = await pickAndUploadImage(context, onBusy: (busy) {
      if (mounted) setState(() => _uploadingKtp = busy);
    });
    if (!mounted || res == null) return;
    setState(() {
      _fotoKtp = res.filename;
      _ktpBytes = res.bytes;
    });
  }

  void _pakaiKode(String kode) {
    final k = kode.trim().toUpperCase();
    setState(() {
      if (k.isEmpty) {
        _promo = null;
        _kodePromo.clear();
        return;
      }
      final found = _promos.where((p) => p.kode.toUpperCase() == k).toList();
      if (found.isEmpty) {
        _promo = null;
      } else {
        _promo = found.first;
        _kodePromo.text = found.first.kode;
      }
    });
  }

  Future<void> _submit() async {
    if (_mulai == null || _selesai == null) {
      showSnack(context, 'Lengkapi tanggal sewa dulu');
      return;
    }
    if (_jam == null) {
      showSnack(context, 'Pilih $_labelWaktu dulu');
      return;
    }
    if (!_setuju) {
      showSnack(context, 'Kamu harus menyetujui Syarat & Ketentuan');
      return;
    }
    if (_nama.text.trim().isEmpty || _email.text.trim().isEmpty || _telpon.text.trim().isEmpty || _ktp.text.trim().isEmpty || _alamat.text.trim().isEmpty) {
      showSnack(context, 'Lengkapi data penyewa (nama, email, telepon, NIK, alamat)');
      return;
    }
    if (_fotoKtp == null) {
      showSnack(context, 'Unggah foto KTP dulu');
      return;
    }
    setState(() => _loading = true);
    try {
      final body = {
        'id_mobil': widget.mobil.idMobil,
        'tanggal_sewa': inputDate(_mulai!),
        'tanggal_selesai': inputDate(_selesai!),
        'pakai_supir': _pakaiSupir,
        'waktu_ambil': '${_jam!.hour.toString().padLeft(2, '0')}:${_jam!.minute.toString().padLeft(2, '0')}',
        'kode_promo': _promo?.kode ?? '',
        'setuju_snk': true,
        'nama_penyewa': _nama.text.trim(),
        'email_penyewa': _email.text.trim(),
        'telpon_penyewa': _telpon.text.trim(),
        'ktp_penyewa': _ktp.text.trim(),
        'alamat_penyewa': _alamat.text.trim(),
        'pekerjaan_penyewa': _pekerjaan.text.trim(),
        'foto_ktp_penyewa': _fotoKtp,
      };
      final res = await Api().post('booking.php', body);
      if (!mounted) return;
      final id = res['id_pesanan'] ?? res['data']?['id_pesanan'];
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => PaymentScreen(idPesanan: (id as num).toInt())));
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 980;
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Pesanan')),
      body: _loadingInit
          ? const Center(child: CircularProgressIndicator())
          : _initError != null
              ? AppError(message: _initError!, onRetry: _loadInit)
              : AppBody(maxWidth: wide ? 1180 : 900, child: wide ? _desktop() : _mobile()),
      bottomNavigationBar: (!wide && !_loadingInit && _initError == null) ? _bottomBar() : null,
    );
  }

  Widget _desktop() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(right: 4, bottom: 40),
              children: _sections(wide: true),
            ),
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: 380,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 40),
              shrinkWrap: true,
              children: [_summaryCard(showButton: true)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobile() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        ..._sections(wide: false),
        const SizedBox(height: 16),
        _summaryCard(showButton: false),
      ],
    );
  }

  List<Widget> _sections({required bool wide}) => [
        _carCard(),
        const SizedBox(height: 16),
        SectionCard(title: 'Detail Sewa', icon: Icons.event_available_outlined, child: _sewaBody(wide)),
        const SizedBox(height: 16),
        SectionCard(title: 'Promo', icon: Icons.local_offer_outlined, child: _promoBody()),
        const SizedBox(height: 16),
        SectionCard(title: 'Data Penyewa', icon: Icons.person_outline, child: _penyewaBody(wide)),
        const SizedBox(height: 16),
        SectionCard(title: 'Syarat & Ketentuan', icon: Icons.gavel_outlined, child: _snkBody()),
      ];

  Widget _carCard() {
    final m = widget.mobil;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
      child: Row(children: [
        CarImage(foto: m.foto, height: 72, width: 96),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${m.kategori} ${m.tipe}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
            Text('${m.platNomer} · ${m.tahun}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 6),
            Text('${rupiah(m.harga)} /hari', style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w700)),
          ]),
        ),
      ]),
    );
  }

  Widget _sewaBody(bool wide) {
    final mulai = _dateBox('Tanggal Mulai', _mulai, () => _pickTanggal(isMulai: true));
    final selesai = _dateBox('Tanggal Selesai', _selesai, () => _pickTanggal(isMulai: false));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (wide)
          Row(children: [Expanded(child: mulai), const SizedBox(width: 12), Expanded(child: selesai)])
        else
          Column(children: [mulai, const SizedBox(height: 12), selesai]),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.timelapse_outlined, size: 16, color: AppColors.brand),
          const SizedBox(width: 6),
          Text('Lama sewa: ${_lama.toInt()} hari', style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 14),
        if (widget.mobil.bisaDenganSupir)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: AppColors.brandLight, borderRadius: BorderRadius.circular(14)),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _pakaiSupir,
              onChanged: (v) => setState(() => _pakaiSupir = v),
              title: const Text('Gunakan supir', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                _pakaiSupir ? '${rupiah(widget.mobil.hargaSupir)} /hari · $_labelWaktu' : supirLabel(widget.mobil.opsiSupir),
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              activeThumbColor: AppColors.brand,
            ),
          ),
        const SizedBox(height: 14),
        _waktuTile(),
      ],
    );
  }

  Widget _dateBox(String label, DateTime? value, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.calendar_month_outlined, color: AppColors.brand, size: 18),
              const SizedBox(width: 8),
              Text(inputDate(value ?? DateTime.now()), style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
          ]),
        ),
      );

  Widget _waktuTile() => InkWell(
        onTap: _pickJam,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
          child: Row(children: [
            const Icon(Icons.schedule_outlined, color: AppColors.brand, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _jam == null ? 'Pilih $_labelWaktu' : '$_labelWaktu: ${_jam!.hour.toString().padLeft(2, '0')}:${_jam!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(color: _jam == null ? AppColors.muted : AppColors.ink, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ]),
        ),
      );

  Widget _promoBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: _kodePromo,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(hintText: 'Kode promo', prefixIcon: Icon(Icons.confirmation_number_outlined)),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(onPressed: () => _pakaiKode(_kodePromo.text), child: const Text('Pakai')),
        ]),
        if (_promos.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _promos.map((p) {
              final selected = _promo?.idPromo == p.idPromo;
              return ChoiceChip(
                label: Text('${p.kode} · ${p.persen ? '${p.nilai.toInt()}%' : rupiah(p.nilai)}'),
                selected: selected,
                showCheckmark: false,
                selectedColor: AppColors.brand,
                labelStyle: TextStyle(color: selected ? Colors.white : AppColors.ink, fontWeight: FontWeight.w600),
                onSelected: (_) => _pakaiKode(p.kode),
              );
            }).toList(),
          ),
        ],
        if (_promo != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
            decoration: BoxDecoration(color: AppColors.brandLight, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.check_circle, color: AppColors.brand, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('${_promo!.kode} aktif · hemat ${rupiah(_diskon)}', style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w700, fontSize: 13))),
              IconButton(onPressed: () => _pakaiKode(''), icon: const Icon(Icons.close, size: 18, color: AppColors.brand), visualDensity: VisualDensity.compact),
            ]),
          ),
        ],
      ],
    );
  }

  Widget _penyewaBody(bool wide) {
    final nama = _field(_nama, 'Nama lengkap (sesuai KTP)');
    final email = _field(_email, 'Email aktif', kb: TextInputType.emailAddress);
    final telpon = _field(_telpon, 'No. telepon/WA', kb: TextInputType.phone);
    final ktp = _field(_ktp, 'NIK (No. KTP)', kb: TextInputType.number);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (wide)
          Row(children: [Expanded(child: nama), const SizedBox(width: 12), Expanded(child: email)])
        else ...[nama, const SizedBox(height: 12), email],
        const SizedBox(height: 12),
        if (wide)
          Row(children: [Expanded(child: telpon), const SizedBox(width: 12), Expanded(child: ktp)])
        else ...[telpon, const SizedBox(height: 12), ktp],
        const SizedBox(height: 12),
        _field(_alamat, 'Alamat lengkap', lines: 2),
        const SizedBox(height: 12),
        _field(_pekerjaan, 'Pekerjaan (opsional)'),
        const SizedBox(height: 14),
        _ktpTile(),
      ],
    );
  }

  Widget _field(TextEditingController c, String label, {TextInputType? kb, int lines = 1}) => TextField(
        controller: c,
        keyboardType: kb,
        maxLines: lines,
        decoration: InputDecoration(labelText: label),
      );

  Widget _ktpTile() {
    final url = _fotoKtp == null ? null : Api().fotoUrl(_fotoKtp!);
    final preview = _ktpBytes != null
        ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_ktpBytes!, width: 62, height: 62, fit: BoxFit.cover))
        : url == null
            ? const Icon(Icons.badge_outlined, color: AppColors.brand)
            : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.badge_outlined, color: AppColors.brand)));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
      child: Row(children: [
        Container(
          width: 62, height: 62,
          decoration: BoxDecoration(color: AppColors.brandLight, borderRadius: BorderRadius.circular(12)),
          child: Center(child: preview),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Foto KTP', style: TextStyle(fontWeight: FontWeight.w700)),
            Text(_fotoKtp == null ? 'Wajib diunggah untuk verifikasi' : 'Foto KTP sudah diunggah', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ]),
        ),
        if (_fotoKtp != null && !_uploadingKtp)
          IconButton(
            tooltip: 'Hapus foto KTP',
            onPressed: () => setState(() {
              _fotoKtp = null;
              _ktpBytes = null;
            }),
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          ),
        OutlinedButton.icon(
          onPressed: _uploadingKtp ? null : _uploadKtp,
          icon: _uploadingKtp ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.upload_outlined, size: 18),
          label: Text(_fotoKtp == null ? 'Unggah' : 'Ganti'),
        ),
      ]),
    );
  }

  Widget _snkBody() {
    const points = <String>[
      'Kendaraan dipakai untuk keperluan pribadi dan tidak disewakan ulang.',
      'Penyewa wajib menunjukkan KTP asli saat pengambilan.',
      'Bahan bakar ditanggung penyewa.',
      'Keterlambatan pengembalian dikenakan biaya tambahan.',
      'Kerusakan/kehilangan selama masa sewa menjadi tanggung jawab penyewa.',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final t in points)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.check, size: 16, color: AppColors.brand),
              const SizedBox(width: 8),
              Expanded(child: Text(t, style: const TextStyle(color: AppColors.muted, fontSize: 13))),
            ]),
          ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => setState(() => _setuju = !_setuju),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Checkbox(value: _setuju, onChanged: (v) => setState(() => _setuju = v ?? false), activeColor: AppColors.brand),
              const Expanded(child: Text('Saya menyetujui Syarat & Ketentuan di atas', style: TextStyle(fontWeight: FontWeight.w600))),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({required bool showButton}) {
    final m = widget.mobil;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ringkasan Pesanan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 14),
          Row(children: [
            CarImage(foto: m.foto, height: 48, width: 64, radius: BorderRadius.circular(12)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${m.kategori} ${m.tipe}', style: const TextStyle(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${m.platNomer} · ${_lama.toInt()} hari', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ]),
            ),
          ]),
          const Divider(height: 28, color: AppColors.line),
          _sumRow('Sewa', rupiah(_sewa)),
          if (_biayaSupir > 0) _sumRow('Supir', rupiah(_biayaSupir)),
          if (_diskon > 0) _sumRow('Diskon (${_promo!.kode})', '- ${rupiah(_diskon)}', valueColor: AppColors.success),
          const Divider(height: 28, color: AppColors.line),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.w800)),
              Text(rupiah(_total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.brand)),
            ],
          ),
          if (showButton) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle_outline),
                label: const Text('Konfirmasi Pesanan'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sumRow(String l, String v, {Color? valueColor}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l, style: const TextStyle(color: AppColors.muted)),
            Text(v, style: TextStyle(fontWeight: FontWeight.w700, color: valueColor)),
          ],
        ),
      );

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.line))),
      child: AppBody(
        maxWidth: 900,
        child: Row(
          children: [
            OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Konfirmasi · ${rupiah(_total)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
