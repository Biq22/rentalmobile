double _d(dynamic v) => v == null ? 0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);
int _i(dynamic v) => v == null ? 0 : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);

class Kategori {
  final int idKategori;
  final String nama;
  final String? ikon;
  final String? deskripsi;
  final int jumlahMobil;

  Kategori({
    required this.idKategori,
    required this.nama,
    this.ikon,
    this.deskripsi,
    this.jumlahMobil = 0,
  });

  factory Kategori.fromJson(Map<String, dynamic> j) => Kategori(
        idKategori: _i(j['id_kategori']),
        nama: '${j['nama'] ?? ''}',
        ikon: j['ikon'] as String?,
        deskripsi: j['deskripsi'] as String?,
        jumlahMobil: _i(j['jumlah_mobil']),
      );
}

class Promo {
  final int idPromo;
  final String kode;
  final String judul;
  final String? deskripsi;
  final String tipe;
  final double nilai;
  final double minTransaksi;
  final double? maksDiskon;
  final bool aktif;
  final String? tanggalMulai;
  final String? tanggalSelesai;

  Promo({
    required this.idPromo,
    required this.kode,
    required this.judul,
    this.deskripsi,
    this.tipe = 'persen',
    this.nilai = 0,
    this.minTransaksi = 0,
    this.maksDiskon,
    this.aktif = true,
    this.tanggalMulai,
    this.tanggalSelesai,
  });

  bool get persen => tipe == 'persen';

  factory Promo.fromJson(Map<String, dynamic> j) => Promo(
        idPromo: _i(j['id_promo']),
        kode: '${j['kode'] ?? ''}',
        judul: '${j['judul'] ?? ''}',
        deskripsi: j['deskripsi'] as String?,
        tipe: '${j['tipe'] ?? 'persen'}',
        nilai: _d(j['nilai']),
        minTransaksi: _d(j['min_transaksi']),
        maksDiskon: j['maks_diskon'] == null ? null : _d(j['maks_diskon']),
        aktif: _i(j['aktif']) == 1,
        tanggalMulai: j['tanggal_mulai'] as String?,
        tanggalSelesai: j['tanggal_selesai'] as String?,
      );
}

class Mobil {
  final int idMobil;
  final int? idKategori;
  final String kategori;
  final String? namaKategori;
  final String tipe;
  final String platNomer;
  final String tahun;
  final String warna;
  final String kondisi;
  final double harga;
  final String status;
  final String? foto;
  final int? kapasitas;
  final String? transmisi;
  final String opsiSupir;
  final double hargaSupir;
  final double rating;
  final int jumlahUlasan;
  final List<String> galeri;

  Mobil({
    required this.idMobil,
    this.idKategori,
    required this.kategori,
    this.namaKategori,
    required this.tipe,
    required this.platNomer,
    required this.tahun,
    required this.warna,
    required this.kondisi,
    required this.harga,
    required this.status,
    this.foto,
    this.kapasitas,
    this.transmisi,
    this.opsiSupir = 'tanpa_supir',
    this.hargaSupir = 0,
    this.rating = 0,
    this.jumlahUlasan = 0,
    this.galeri = const [],
  });

  bool get bisaTanpaSupir => opsiSupir == 'tanpa_supir' || opsiSupir == 'keduanya';
  bool get bisaDenganSupir => opsiSupir == 'dengan_supir' || opsiSupir == 'keduanya';
  bool get tersedia => status == 'tersedia';

  List<String> get semuaFoto => [
        if (foto != null && foto!.isNotEmpty) foto!,
        ...galeri.where((g) => g != foto),
      ];

  factory Mobil.fromJson(Map<String, dynamic> j) => Mobil(
        idMobil: _i(j['id_mobil']),
        idKategori: j['id_kategori'] == null ? null : _i(j['id_kategori']),
        kategori: '${j['kategori'] ?? ''}'.trim(),
        namaKategori: j['nama_kategori'] as String?,
        tipe: '${j['tipe'] ?? ''}'.trim(),
        platNomer: '${j['plat_nomer'] ?? ''}',
        tahun: '${j['tahun'] ?? ''}',
        warna: '${j['warna'] ?? ''}',
        kondisi: '${j['kondisi'] ?? ''}',
        harga: _d(j['harga_sewa_per_hari']),
        status: '${j['status'] ?? 'tersedia'}',
        foto: j['foto'] as String?,
        kapasitas: j['kapasitas'] == null ? null : _i(j['kapasitas']),
        transmisi: j['transmisi'] as String?,
        opsiSupir: '${j['opsi_supir'] ?? 'tanpa_supir'}',
        hargaSupir: _d(j['harga_supir_per_hari']),
        rating: _d(j['rating']),
        jumlahUlasan: _i(j['jumlah_ulasan']),
        galeri: j['galeri'] is List ? (j['galeri'] as List).map((e) => '$e').toList() : const [],
      );
}

class Pesanan {
  final int idPesanan;
  final int idPelanggan;
  final int? idPegawai;
  final int? idSupir;
  final int idMobil;
  final String? tanggalPesanan;
  final String tanggalSewa;
  final String? tanggalSelesai;
  final int lamaSewa;
  final double totalHarga;
  final String statusPesanan;
  final bool pakaiSupir;
  final double biayaSupir;
  final int? idPromo;
  final double diskon;
  final String? kodePromo;
  final String? judulPromo;
  final String? namaPenyewa;
  final String? emailPenyewa;
  final String? telponPenyewa;
  final String? ktpPenyewa;
  final String? alamatPenyewa;
  final String? pekerjaanPenyewa;
  final String? fotoKtpPenyewa;
  final String? waktuPengambilan;
  final String? waktuPengembalian;
  final int? idPembayaran;
  final String? nomorVa;
  final String? kategori;
  final String? tipe;
  final String? platNomer;
  final String? foto;
  final String? namaKategori;
  final String? namaPelanggan;
  final String? noTelpon;
  final String? statusPembayaran;
  final String? metodePembayaran;
  final double? totalBayar;
  final String? namaSupir;
  final String? supirTelpon;
  final String? supirFoto;
  final double denda;
  final String? tanggalKembaliAktual;
  final String? kondisiKembali;
  final String? catatanKembali;
  final bool dibacaPegawai;
  final String? bukti;
  final String? buktiUrl;
  final String? catatanPembayaran;

  Pesanan({
    required this.idPesanan,
    required this.idPelanggan,
    this.idPegawai,
    this.idSupir,
    required this.idMobil,
    this.tanggalPesanan,
    required this.tanggalSewa,
    this.tanggalSelesai,
    required this.lamaSewa,
    required this.totalHarga,
    required this.statusPesanan,
    this.pakaiSupir = false,
    this.biayaSupir = 0,
    this.idPromo,
    this.diskon = 0,
    this.kodePromo,
    this.judulPromo,
    this.namaPenyewa,
    this.emailPenyewa,
    this.telponPenyewa,
    this.ktpPenyewa,
    this.alamatPenyewa,
    this.pekerjaanPenyewa,
    this.fotoKtpPenyewa,
    this.waktuPengambilan,
    this.waktuPengembalian,
    this.idPembayaran,
    this.nomorVa,
    this.kategori,
    this.tipe,
    this.platNomer,
    this.foto,
    this.namaKategori,
    this.namaPelanggan,
    this.noTelpon,
    this.statusPembayaran,
    this.metodePembayaran,
    this.totalBayar,
    this.namaSupir,
    this.supirTelpon,
    this.supirFoto,
    this.denda = 0,
    this.tanggalKembaliAktual,
    this.kondisiKembali,
    this.catatanKembali,
    this.dibacaPegawai = false,
    this.bukti,
    this.buktiUrl,
    this.catatanPembayaran,
  });

  factory Pesanan.fromJson(Map<String, dynamic> j) => Pesanan(
        idPesanan: _i(j['id_pesanan']),
        idPelanggan: _i(j['id_pelanggan']),
        idPegawai: j['id_pegawai'] == null ? null : _i(j['id_pegawai']),
        idSupir: j['id_supir'] == null ? null : _i(j['id_supir']),
        idMobil: _i(j['id_mobil']),
        tanggalPesanan: j['tanggal_pesanan'] as String?,
        tanggalSewa: '${j['tanggal_sewa'] ?? ''}',
        tanggalSelesai: j['tanggal_selesai'] as String?,
        lamaSewa: _i(j['lama_sewa']),
        totalHarga: _d(j['total_harga']),
        statusPesanan: '${j['status_pesanan'] ?? 'pending'}',
        pakaiSupir: _i(j['pakai_supir']) == 1,
        biayaSupir: _d(j['biaya_supir']),
        idPromo: j['id_promo'] == null ? null : _i(j['id_promo']),
        diskon: _d(j['diskon']),
        kodePromo: j['kode_promo'] as String?,
        judulPromo: j['judul_promo'] as String?,
        namaPenyewa: j['nama_penyewa'] as String?,
        emailPenyewa: j['email_penyewa'] as String?,
        telponPenyewa: j['telpon_penyewa'] as String?,
        ktpPenyewa: j['ktp_penyewa'] as String?,
        alamatPenyewa: j['alamat_penyewa'] as String?,
        pekerjaanPenyewa: j['pekerjaan_penyewa'] as String?,
        fotoKtpPenyewa: j['foto_ktp_penyewa'] as String?,
        waktuPengambilan: j['waktu_pengambilan'] as String?,
        waktuPengembalian: j['waktu_pengembalian'] as String?,
        idPembayaran: j['id_pembayaran'] == null ? null : _i(j['id_pembayaran']),
        nomorVa: j['nomor_va'] as String?,
        kategori: j['kategori'] as String?,
        tipe: j['tipe'] as String?,
        platNomer: j['plat_nomer'] as String?,
        foto: j['foto'] as String?,
        namaKategori: j['nama_kategori'] as String?,
        namaPelanggan: j['nama_pelanggan'] as String?,
        noTelpon: j['no_telpon'] as String?,
        statusPembayaran: j['status_pembayaran'] as String?,
        metodePembayaran: j['metode_pembayaran'] as String?,
        totalBayar: j['total_bayar'] == null ? null : _d(j['total_bayar']),
        namaSupir: j['nama_supir'] as String?,
        supirTelpon: j['supir_telpon'] as String?,
        supirFoto: j['supir_foto'] as String?,
        denda: _d(j['denda']),
        tanggalKembaliAktual: j['tanggal_kembali_aktual'] as String?,
        kondisiKembali: j['kondisi_kembali'] as String?,
        catatanKembali: j['catatan_kembali'] as String?,
        dibacaPegawai: _i(j['dibaca_pegawai']) == 1,
        bukti: j['bukti'] as String?,
        buktiUrl: j['bukti_url'] as String?,
        catatanPembayaran: j['catatan'] as String?,
      );
}

class Pelanggan {
  final int idPelanggan;
  final String nama;
  final String email;
  final String noTelpon;
  final String noKtp;
  final String alamat;
  final String? pekerjaan;
  final String? foto;
  final String? fotoKtp;
  final int jumlahPesanan;

  Pelanggan({
    required this.idPelanggan,
    required this.nama,
    required this.email,
    required this.noTelpon,
    required this.noKtp,
    required this.alamat,
    this.pekerjaan,
    this.foto,
    this.fotoKtp,
    this.jumlahPesanan = 0,
  });

  factory Pelanggan.fromJson(Map<String, dynamic> j) => Pelanggan(
        idPelanggan: _i(j['id_pelanggan']),
        nama: '${j['nama'] ?? ''}',
        email: '${j['email'] ?? ''}',
        noTelpon: '${j['no_telpon'] ?? ''}',
        noKtp: '${j['no_ktp'] ?? ''}',
        alamat: '${j['alamat'] ?? ''}',
        pekerjaan: j['pekerjaan'] as String?,
        foto: j['foto'] as String?,
        fotoKtp: j['foto_ktp'] as String?,
        jumlahPesanan: _i(j['jumlah_pesanan']),
      );
}

class Pegawai {
  final int id;
  final String nama;
  final String? username;
  final String email;
  final String noTelepon;
  final String jabatan;
  final String alamat;
  final String? foto;

  Pegawai({
    required this.id,
    required this.nama,
    this.username,
    required this.email,
    required this.noTelepon,
    required this.jabatan,
    required this.alamat,
    this.foto,
  });

  bool get isAdmin => jabatan.toLowerCase().contains('admin');

  factory Pegawai.fromJson(Map<String, dynamic> j) => Pegawai(
        id: _i(j['id'] ?? j['id_pegawai']),
        nama: '${j['nama'] ?? ''}',
        username: j['username'] as String?,
        email: '${j['email'] ?? ''}',
        noTelepon: '${j['no_telepon'] ?? ''}',
        jabatan: '${j['jabatan'] ?? ''}',
        alamat: '${j['alamat'] ?? ''}',
        foto: j['foto'] as String?,
      );
}

class Pembayaran {
  final int idPembayaran;
  final int idPesanan;
  final int? idPelanggan;
  final String tanggalBayar;
  final double totalBayar;
  final String metode;
  final String status;
  final String? nomorVa;
  final String? batasPembayaran;
  final String? namaPelanggan;
  final double? totalHarga;
  final String? statusPesanan;
  final String? bukti;
  final String? catatan;
  final int? diverifikasiOleh;

  Pembayaran({
    required this.idPembayaran,
    required this.idPesanan,
    this.idPelanggan,
    required this.tanggalBayar,
    required this.totalBayar,
    required this.metode,
    required this.status,
    this.nomorVa,
    this.batasPembayaran,
    this.namaPelanggan,
    this.totalHarga,
    this.statusPesanan,
    this.bukti,
    this.catatan,
    this.diverifikasiOleh,
  });

  factory Pembayaran.fromJson(Map<String, dynamic> j) => Pembayaran(
        idPembayaran: _i(j['id_pembayaran']),
        idPesanan: _i(j['id_pesanan']),
        idPelanggan: j['id_pelanggan'] == null ? null : _i(j['id_pelanggan']),
        tanggalBayar: '${j['tanggal_bayar'] ?? ''}',
        totalBayar: _d(j['total_bayar']),
        metode: '${j['metode_pembayaran'] ?? ''}',
        status: '${j['status_pembayaran'] ?? 'Pending'}',
        nomorVa: j['nomor_va'] as String?,
        batasPembayaran: j['batas_pembayaran'] as String?,
        namaPelanggan: j['nama_pelanggan'] as String?,
        totalHarga: j['total_harga'] == null ? null : _d(j['total_harga']),
        statusPesanan: j['status_pesanan'] as String?,
        bukti: j['bukti'] as String?,
        catatan: j['catatan'] as String?,
        diverifikasiOleh: j['diverifikasi_oleh'] == null ? null : _i(j['diverifikasi_oleh']),
      );
}

class Supir {
  final int idSupir;
  final String nama;
  final String noTelpon;
  final String noSim;
  final double hargaPerHari;
  final String? foto;
  final String status;

  Supir({
    required this.idSupir,
    required this.nama,
    required this.noTelpon,
    required this.noSim,
    this.hargaPerHari = 0,
    this.foto,
    this.status = 'aktif',
  });

  bool get aktif => status == 'aktif';

  factory Supir.fromJson(Map<String, dynamic> j) => Supir(
        idSupir: _i(j['id_supir']),
        nama: '${j['nama'] ?? ''}',
        noTelpon: '${j['no_telpon'] ?? ''}',
        noSim: '${j['no_sim'] ?? ''}',
        hargaPerHari: _d(j['harga_per_hari']),
        foto: j['foto'] as String?,
        status: '${j['status'] ?? 'aktif'}',
      );
}

class Ulasan {
  final int idUlasan;
  final int idPesanan;
  final int idMobil;
  final int idPelanggan;
  final int rating;
  final String? komentar;
  final String? namaPelanggan;
  final String? dibuatPada;

  Ulasan({
    required this.idUlasan,
    required this.idPesanan,
    required this.idMobil,
    required this.idPelanggan,
    required this.rating,
    this.komentar,
    this.namaPelanggan,
    this.dibuatPada,
  });

  factory Ulasan.fromJson(Map<String, dynamic> j) => Ulasan(
        idUlasan: _i(j['id_ulasan']),
        idPesanan: _i(j['id_pesanan']),
        idMobil: _i(j['id_mobil']),
        idPelanggan: _i(j['id_pelanggan']),
        rating: _i(j['rating']),
        komentar: j['komentar'] as String?,
        namaPelanggan: j['nama_pelanggan'] as String?,
        dibuatPada: j['dibuat_pada'] as String?,
      );
}

class NotifikasiRow {
  final int idPesanan;
  final int? idMobil;
  final String? tanggalSewa;
  final int? lamaSewa;
  final double totalHarga;
  final String statusPesanan;
  final String pesan;
  final String? kategori;
  final String? tipe;
  final String? platNomer;
  final String? namaPelanggan;
  final int idPegawai;

  NotifikasiRow({
    required this.idPesanan,
    this.idMobil,
    this.tanggalSewa,
    this.lamaSewa,
    this.totalHarga = 0,
    this.statusPesanan = '',
    this.pesan = '',
    this.kategori,
    this.tipe,
    this.platNomer,
    this.namaPelanggan,
    this.idPegawai = 0,
  });

  factory NotifikasiRow.fromJson(Map<String, dynamic> j) => NotifikasiRow(
        idPesanan: _i(j['id_pesanan']),
        idMobil: j['id_mobil'] == null ? null : _i(j['id_mobil']),
        tanggalSewa: j['tanggal_sewa'] as String?,
        lamaSewa: j['lama_sewa'] == null ? null : _i(j['lama_sewa']),
        totalHarga: _d(j['total_harga']),
        statusPesanan: '${j['status_pesanan'] ?? ''}',
        pesan: '${j['pesan'] ?? ''}',
        kategori: j['kategori'] as String?,
        tipe: j['tipe'] as String?,
        platNomer: j['plat_nomer'] as String?,
        namaPelanggan: j['nama_pelanggan'] as String?,
        idPegawai: _i(j['id_pegawai']),
      );
}

class Pengaturan {
  final Map<String, String> nilai;

  Pengaturan(this.nilai);

  factory Pengaturan.fromJson(Map<String, dynamic> j) {
    final m = <String, String>{};
    j.forEach((k, v) => m[k] = v == null ? '' : '$v');
    return Pengaturan(m);
  }

  String get namaPerusahaan => nilai['nama_perusahaan'] ?? 'Rental Mobil';
  String get alamat => nilai['alamat'] ?? '';
  String get telepon => nilai['telepon'] ?? '';
  String get email => nilai['email'] ?? '';
  String get jamOperasional => nilai['jam_operasional'] ?? '';
  String get visi => nilai['visi'] ?? '';
  String get tentang => nilai['tentang'] ?? '';
  double get tarifDenda => double.tryParse(nilai['tarif_denda_per_hari'] ?? '') ?? 0;
  String get rekening => nilai['rekening'] ?? '';
  String get qris => nilai['qris'] ?? '';

  String operator [](String k) => nilai[k] ?? '';
}

class DailySales {
  final String tanggal;
  final String label;
  final int jumlah;
  final double pendapatan;

  DailySales({
    required this.tanggal,
    required this.label,
    required this.jumlah,
    required this.pendapatan,
  });

  factory DailySales.fromJson(Map<String, dynamic> j) => DailySales(
        tanggal: '${j['tanggal'] ?? ''}',
        label: '${j['label'] ?? ''}',
        jumlah: _i(j['jumlah']),
        pendapatan: _d(j['pendapatan']),
      );
}

class LaporanRow {
  final int idLaporan;
  final int idPegawai;
  final String? namaPegawai;
  final String tanggalLaporan;
  final double rataRataOrder;
  final int totalOrder;
  final double totalPendapatan;
  final String keterangan;

  LaporanRow({
    required this.idLaporan,
    required this.idPegawai,
    this.namaPegawai,
    required this.tanggalLaporan,
    required this.rataRataOrder,
    required this.totalOrder,
    required this.totalPendapatan,
    required this.keterangan,
  });

  factory LaporanRow.fromJson(Map<String, dynamic> j) => LaporanRow(
        idLaporan: _i(j['id_laporan']),
        idPegawai: _i(j['id_pegawai']),
        namaPegawai: j['nama_pegawai'] as String?,
        tanggalLaporan: '${j['tanggal_laporan'] ?? ''}',
        rataRataOrder: _d(j['rata_rata_order']),
        totalOrder: _i(j['total_order']),
        totalPendapatan: _d(j['total_pendapatan']),
        keterangan: '${j['keterangan'] ?? ''}',
      );
}
