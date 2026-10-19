import 'package:flutter/material.dart';

import '../../config.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';

class PesananScreen extends StatefulWidget {
  const PesananScreen({super.key});

  @override
  State<PesananScreen> createState() => _PesananScreenState();
}

class _PesananScreenState extends State<PesananScreen> {
  List<Pesanan> _items = [];
  bool _loading = true;
  String? _error;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      _error = null;
    }
    try {
      final q = _filter.isEmpty ? null : {'status': _filter};
      final res = await Api().get('booking.php', query: q);
      _items = (res['data'] as List).map((e) => Pesanan.fromJson(e)).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _ubahStatus(Pesanan p, String status, String label) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$label pesanan #${p.idPesanan}?'),
        content: Text('${p.namaPelanggan ?? ''} · ${p.kategori ?? ''} ${p.tipe ?? ''}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(label)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api().put('booking.php', {'id_pesanan': p.idPesanan, 'status_pesanan': status});
      if (mounted) showSnack(context, 'Status pesanan diperbarui');
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _assignSupir(Pesanan p) async {
    List<Supir> daftar;
    try {
      final res = await Api().get('supir.php', query: {'status': 'aktif'});
      daftar = (res['data'] as List).map((e) => Supir.fromJson(e)).toList();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
      return;
    }
    if (!mounted) return;
    final pilih = await showDialog<Object?>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text('Pilih Supir — Pesanan #${p.idPesanan}'),
        children: [
          if (daftar.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('Belum ada supir aktif.'))
          else
            for (final s in daftar)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, s.idSupir),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.brandLight,
                    backgroundImage: (s.foto != null && s.foto!.isNotEmpty) ? NetworkImage(Api().fotoUrl(s.foto)) : null,
                    child: (s.foto == null || s.foto!.isEmpty) ? const Icon(Icons.person, color: AppColors.brand) : null,
                  ),
                  title: Text(s.nama),
                  subtitle: Text('${rupiah(s.hargaPerHari)} /hari · ${s.noTelpon}'),
                ),
              ),
          if (p.idSupir != null)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 0),
              child: const Row(children: [
                Icon(Icons.person_off_outlined, color: AppColors.danger),
                SizedBox(width: 8),
                Text('Lepas supir', style: TextStyle(color: AppColors.danger)),
              ]),
            ),
        ],
      ),
    );
    if (pilih == null) return;
    try {
      await Api().put('booking.php', {'action': 'assign_supir', 'id_pesanan': p.idPesanan, 'id_supir': pilih});
      if (mounted) showSnack(context, 'Supir diperbarui');
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _kembalikan(Pesanan p) async {
    DateTime tgl = DateTime.now();
    String kondisi = 'Baik';
    final catatan = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text('Pengembalian #${p.idPesanan}'),
          content: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tanggal kembali aktual'),
                subtitle: Text(tanggal(inputDate(tgl))),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () async {
                  final picked = await showDatePicker(context: ctx, initialDate: tgl, firstDate: DateTime(2020), lastDate: DateTime(2100));
                  if (picked != null) setD(() => tgl = picked);
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: kondisi,
                decoration: const InputDecoration(labelText: 'Kondisi mobil'),
                items: const [
                  DropdownMenuItem(value: 'Baik', child: Text('Baik')),
                  DropdownMenuItem(value: 'Ada kerusakan', child: Text('Ada kerusakan')),
                  DropdownMenuItem(value: 'Perlu servis', child: Text('Perlu servis')),
                ],
                onChanged: (v) => setD(() => kondisi = v ?? 'Baik'),
              ),
              const SizedBox(height: 12),
              TextField(controller: catatan, maxLines: 2, decoration: const InputDecoration(labelText: 'Catatan (opsional)')),
              const SizedBox(height: 8),
              const Text('Denda keterlambatan dihitung otomatis sesuai tarif di Pengaturan.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Proses')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      final res = await Api().put('booking.php', {
        'action': 'kembalikan',
        'id_pesanan': p.idPesanan,
        'tanggal_kembali_aktual': inputDate(tgl),
        'kondisi_kembali': kondisi,
        'catatan_kembali': catatan.text.trim(),
      });
      if (mounted) showSnack(context, '${res['message'] ?? 'Pengembalian diproses'}');
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  String? _buktiUrl(Pesanan p) {
    if (p.buktiUrl != null && p.buktiUrl!.isNotEmpty) return p.buktiUrl;
    if (p.bukti != null && p.bukti!.isNotEmpty) return Api().fotoUrl(p.bukti);
    return null;
  }

  Future<void> _ubahStatusBayar(Pesanan p, String status, {String? catatan}) async {
    if (p.idPembayaran == null) {
      showSnack(context, 'Data pembayaran pesanan ini tidak ditemukan', error: true);
      return;
    }
    try {
      await Api().put('pembayaran.php', {
        'id_pembayaran': p.idPembayaran,
        'status_pembayaran': status,
        if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
      });
      if (mounted) showSnack(context, 'Status pembayaran: $status');
      await _load(showLoading: false);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _verifikasiPembayaran(Pesanan p) async {
    final catatan = TextEditingController(text: p.catatanPembayaran ?? '');
    final metode = (p.metodePembayaran ?? '').trim();
    final bukti = _buktiUrl(p);
    final aksi = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Verifikasi Pembayaran #${p.idPesanan}'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              _line('Nama', p.namaPelanggan ?? '-'),
              _line('Total tagihan', rupiah(p.totalHarga)),
              _line('Metode bayar', metode.isEmpty ? 'Belum dipilih' : metode),
              const SizedBox(height: 12),
              if (bukti != null) ...[
                const Text('Bukti pembayaran', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _buktiFull(bukti),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(bukti, height: 200, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Text('Gagal memuat bukti')),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _buktiFull(bukti),
                    icon: const Icon(Icons.zoom_out_map, size: 16),
                    label: const Text('Perbesar'),
                  ),
                ),
              ] else if (metode == 'QRIS' || metode == 'Transfer')
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('Pelanggan belum mengunggah bukti pembayaran.', style: TextStyle(color: AppColors.muted)),
                ),
              TextField(controller: catatan, maxLines: 2, decoration: const InputDecoration(labelText: 'Catatan verifikasi (opsional)')),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 'Gagal'), child: const Text('Tolak Pembayaran', style: TextStyle(color: AppColors.danger))),
          FilledButton(onPressed: () => Navigator.pop(ctx, 'Lunas'), child: const Text('Setujui Lunas')),
        ],
      ),
    );
    if (aksi == null) return;
    await _ubahStatusBayar(p, aksi, catatan: catatan.text.trim());
  }

  void _lihatBukti(Pesanan p) {
    final url = _buktiUrl(p);
    if (url == null) return;
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Bukti Pembayaran', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 10),
              Flexible(
                child: GestureDetector(
                  onTap: () => _buktiFull(url),
                  child: Image.network(url, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Text('Gagal memuat bukti')),
                ),
              ),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                OutlinedButton.icon(
                  onPressed: () => _buktiFull(url),
                  icon: const Icon(Icons.zoom_out_map, size: 16),
                  label: const Text('Perbesar'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                ),
                const SizedBox(width: 8),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  void _buktiFull(String url) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('Bukti Pembayaran', style: TextStyle(color: Colors.white)),
        ),
        body: InteractiveViewer(
          maxScale: 8,
          child: Center(
            child: Image.network(url, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text('Gagal memuat bukti', style: TextStyle(color: Colors.white70))),
          ),
        ),
      ),
    ));
  }

  Widget _metodeBadge(String metode) {
    final (icon, label, color) = switch (metode) {
      'QRIS' => (Icons.qr_code_2, 'QRIS', AppColors.info),
      'Transfer' => (Icons.account_balance_outlined, 'Transfer', AppColors.brand),
      'Cash' => (Icons.payments_outlined, 'Cash', AppColors.success),
      _ => (Icons.help_outline, 'Belum dipilih', AppColors.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      ]),
    );
  }

  Widget _bayarRow(Pesanan p) {
    final metode = (p.metodePembayaran ?? '').trim();
    final status = (p.statusPembayaran ?? '').trim();
    final color = statusPembayaranColor(status.isEmpty ? 'Pending' : status);
    final pending = status.toLowerCase() == 'pending';
    final bukti = _buktiUrl(p);
    final perluBukti = metode == 'QRIS' || metode == 'Transfer';

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _metodeBadge(metode),
        if (pending)
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => _verifikasiPembayaran(p),
            child: Tooltip(
              message: 'Klik untuk verifikasi pembayaran',
              child: StatusChip(label: 'Pending', color: color),
            ),
          )
        else
          StatusChip(label: status.isEmpty ? 'Belum Bayar' : status, color: color),
        if (perluBukti)
          bukti != null
              ? TextButton.icon(
                  onPressed: () => _lihatBukti(p),
                  icon: const Icon(Icons.photo_library_outlined, size: 16),
                  label: const Text('Lihat Bukti Pembayaran'),
                  style: TextButton.styleFrom(minimumSize: const Size(0, 36), visualDensity: VisualDensity.compact),
                )
              : const Text('Bukti belum diunggah', style: TextStyle(color: AppColors.muted, fontSize: 12))
        else if (metode == 'Cash')
          const Text('Bayar di Tempat / Cash', style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 54,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            children: [
              for (final f in const [('', 'Semua'), ('pending', 'Pending'), ('diproses', 'Diproses'), ('selesai', 'Selesai'), ('batal', 'Batal'), ('ditolak', 'Ditolak')])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.$2),
                    selected: _filter == f.$1,
                    onSelected: (_) {
                      setState(() => _filter = f.$1);
                      _load();
                    },
                    labelStyle: TextStyle(color: _filter == f.$1 ? Colors.white : AppColors.ink, fontWeight: FontWeight.w600),
                    selectedColor: AppColors.brand,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.line),
                    showCheckmark: false,
                  ),
                ),
            ],
          ),
        ),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return AppError(message: _error!, onRetry: _load);
    if (_items.isEmpty) return const AppEmpty(title: 'Belum ada pesanan', message: 'Pesanan pelanggan akan muncul di sini.');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (_, i) => _card(_items[i]),
      ),
    );
  }

  Widget _card(Pesanan p) {
    final statusColor = switch (p.statusPesanan) {
      'diproses' => AppColors.info,
      'selesai' => AppColors.success,
      'batal' || 'ditolak' => AppColors.danger,
      _ => AppColors.warning,
    };
    return AppBody(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
        child: Column(
          children: [
            Row(children: [
              CarImage(foto: p.foto, height: 66, width: 88),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text('#${p.idPesanan} · ${p.kategori ?? ''} ${p.tipe ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800))),
                    StatusChip(label: p.statusPesanan, color: statusColor),
                  ]),
                  const SizedBox(height: 4),
                  Text('${p.platNomer ?? ''}${p.pakaiSupir ? ' · dengan supir' : ''}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('${p.namaPelanggan ?? ''} · ${p.noTelpon ?? ''}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ]),
              ),
            ]),
            const Divider(height: 22),
            Row(children: [
              _info('Tanggal', tanggal(p.tanggalSewa)),
              _info('Lama', '${p.lamaSewa} hari'),
              _info('Total', rupiah(p.totalHarga)),
            ]),
            const SizedBox(height: 8),
            _bayarRow(p),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _line('Masa sewa', '${tanggal(p.tanggalSewa)} → ${(p.tanggalSelesai != null && p.tanggalSelesai!.isNotEmpty) ? tanggal(p.tanggalSelesai!) : '-'}'),
                _line(p.pakaiSupir ? 'Waktu diantar' : 'Waktu ambil', _jam(p.waktuPengambilan)),
                if (p.namaSupir != null && p.namaSupir!.isNotEmpty) _line('Supir', '${p.namaSupir} · ${p.supirTelpon ?? ''}'),
                if (p.diskon > 0) _line('Promo', '${p.kodePromo ?? ''} · -${rupiah(p.diskon)}'),
                if (p.tanggalKembaliAktual != null && p.tanggalKembaliAktual!.isNotEmpty)
                  _line('Kembali', '${tanggal(p.tanggalKembaliAktual)} · ${p.kondisiKembali ?? ''}'),
                if (p.denda > 0) _line('Denda', rupiah(p.denda)),
              ]),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _detailPenyewa(p),
                icon: const Icon(Icons.person_search_outlined, size: 18),
                label: const Text('Detail Penyewa & KTP'),
              ),
            ),
            if (p.statusPesanan == 'pending' || p.statusPesanan == 'diproses') ...[
              const SizedBox(height: 10),
              Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: [
                OutlinedButton.icon(
                  onPressed: () => _assignSupir(p),
                  icon: const Icon(Icons.person_add_alt, size: 18),
                  label: const Text('Atur Supir'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42)),
                ),
                if (p.statusPesanan == 'pending') ...[
                  OutlinedButton(onPressed: () => _ubahStatus(p, 'ditolak', 'Tolak'), style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, minimumSize: const Size(0, 42)), child: const Text('Tolak')),
                  FilledButton(onPressed: () => _ubahStatus(p, 'diproses', 'Setujui'), style: FilledButton.styleFrom(minimumSize: const Size(0, 42)), child: const Text('Setujui')),
                ],
                if (p.statusPesanan == 'diproses') ...[
                  OutlinedButton(onPressed: () => _ubahStatus(p, 'batal', 'Batalkan'), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42)), child: const Text('Batalkan')),
                  FilledButton.icon(
                    onPressed: () => _kembalikan(p),
                    icon: const Icon(Icons.keyboard_return, size: 18),
                    label: const Text('Kembalikan'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.success, minimumSize: const Size(0, 42)),
                  ),
                ],
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _info(String l, String v) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      );

  Widget _line(String l, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(children: [
          SizedBox(width: 96, child: Text(l, style: const TextStyle(color: AppColors.muted, fontSize: 12))),
          Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
        ]),
      );

  String _jam(String? dt) {
    if (dt == null || dt.isEmpty) return '-';
    final parts = dt.split(' ');
    if (parts.length < 2) return dt;
    final t = parts[1].split(':');
    return '${t[0]}:${t.length > 1 ? t[1] : '00'}';
  }

  void _detailPenyewa(Pesanan p) {
    final fk = p.fotoKtpPenyewa;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Data Penyewa #${p.idPesanan}'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              _line('Nama (KTP)', p.namaPenyewa ?? p.namaPelanggan ?? '-'),
              _line('Email', p.emailPenyewa ?? '-'),
              _line('Telpon/WA', p.telponPenyewa ?? p.noTelpon ?? '-'),
              _line('NIK', p.ktpPenyewa ?? '-'),
              _line('Pekerjaan', p.pekerjaanPenyewa ?? '-'),
              _line('Alamat', p.alamatPenyewa ?? '-'),
              const SizedBox(height: 12),
              const Text('Foto KTP', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              if (fk != null && fk.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(Api().fotoUrl(fk), fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Text('Gagal memuat foto KTP')),
                )
              else
                const Text('Foto KTP tidak tersedia', style: TextStyle(color: AppColors.muted)),
            ]),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
      ),
    );
  }
}
