-- ============================================================
-- Migration: Fitur tambahan Rental Mobil
-- Jalankan setelah database `rental_mobil` dibuat (lihat schema).
-- Semua penambahan nullable/default supaya data lama tidak rusak.
-- ============================================================

-- 1) Data supir
CREATE TABLE IF NOT EXISTS `supir` (
  `id_supir` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `nama` varchar(100) NOT NULL,
  `no_telpon` varchar(20) NOT NULL,
  `no_sim` varchar(30) NOT NULL,
  `harga_per_hari` decimal(10,2) NOT NULL DEFAULT 0.00,
  `foto` varchar(255) DEFAULT NULL,
  `status` enum('aktif','nonaktif') NOT NULL DEFAULT 'aktif',
  `dibuat_pada` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_supir`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 2) Pengembalian & denda + supir + notifikasi pegawai
ALTER TABLE `pesanan`
  ADD COLUMN `id_supir` int(10) unsigned DEFAULT NULL AFTER `id_pegawai`,
  ADD COLUMN `tanggal_kembali_aktual` date DEFAULT NULL,
  ADD COLUMN `denda` decimal(12,2) NOT NULL DEFAULT 0.00,
  ADD COLUMN `kondisi_kembali` varchar(50) DEFAULT NULL,
  ADD COLUMN `catatan_kembali` text DEFAULT NULL,
  ADD COLUMN `dibaca_pegawai` tinyint(1) NOT NULL DEFAULT 0,
  ADD KEY `fk_pesanan_supir` (`id_supir`),
  ADD CONSTRAINT `fk_pesanan_supir` FOREIGN KEY (`id_supir`) REFERENCES `supir` (`id_supir`);

-- 3) Bukti pembayaran + verifikasi
ALTER TABLE `pembayaran`
  ADD COLUMN `bukti` varchar(255) DEFAULT NULL,
  ADD COLUMN `diverifikasi_oleh` int(10) unsigned DEFAULT NULL,
  ADD COLUMN `catatan` varchar(255) DEFAULT NULL;

-- 4) Pengaturan perusahaan (key-value)
CREATE TABLE IF NOT EXISTS `pengaturan` (
  `kunci` varchar(50) NOT NULL,
  `nilai` text DEFAULT NULL,
  PRIMARY KEY (`kunci`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT INTO `pengaturan` (`kunci`, `nilai`) VALUES
  ('nama_perusahaan', 'Rental Mobil'),
  ('alamat', 'Jl. Raya Rental No. 123, Surabaya'),
  ('telepon', '0812-3456-7890'),
  ('email', 'info@rentalmobil.test'),
  ('jam_operasional', 'Senin - Sabtu, 08.00 - 20.00 WIB'),
  ('visi', 'Menjadi penyedia jasa sewa mobil terbaik dan tepercaya.'),
  ('tentang', 'Layanan sewa mobil yang mudah, cepat, dan terpercaya. Tersedia pilihan lepas kunci maupun dengan supir untuk kebutuhan perjalananmu.'),
  ('tarif_denda_per_hari', '50000'),
  ('rekening', 'BCA 1234567890 a/n Rental Mobil'),
  ('qris', 'RM-RENTALMOBIL')
ON DUPLICATE KEY UPDATE `nilai` = VALUES(`nilai`);

-- 5) Ulasan & rating mobil
CREATE TABLE IF NOT EXISTS `ulasan` (
  `id_ulasan` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `id_pesanan` int(11) NOT NULL,
  `id_mobil` int(10) unsigned NOT NULL,
  `id_pelanggan` int(10) unsigned NOT NULL,
  `rating` tinyint(4) NOT NULL,
  `komentar` text DEFAULT NULL,
  `dibuat_pada` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_ulasan`),
  UNIQUE KEY `uq_ulasan_pesanan` (`id_pesanan`),
  KEY `idx_ulasan_mobil` (`id_mobil`),
  KEY `fk_ulasan_pelanggan` (`id_pelanggan`),
  CONSTRAINT `fk_ulasan_pesanan` FOREIGN KEY (`id_pesanan`) REFERENCES `pesanan` (`id_pesanan`),
  CONSTRAINT `fk_ulasan_mobil` FOREIGN KEY (`id_mobil`) REFERENCES `mobil` (`id_mobil`),
  CONSTRAINT `fk_ulasan_pelanggan` FOREIGN KEY (`id_pelanggan`) REFERENCES `pelanggan` (`id_pelanggan`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 6) Favorit / wishlist
CREATE TABLE IF NOT EXISTS `favorit` (
  `id_favorit` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `id_pelanggan` int(10) unsigned NOT NULL,
  `id_mobil` int(10) unsigned NOT NULL,
  `dibuat_pada` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_favorit`),
  UNIQUE KEY `uq_favorit` (`id_pelanggan`, `id_mobil`),
  KEY `fk_favorit_mobil` (`id_mobil`),
  CONSTRAINT `fk_favorit_pelanggan` FOREIGN KEY (`id_pelanggan`) REFERENCES `pelanggan` (`id_pelanggan`),
  CONSTRAINT `fk_favorit_mobil` FOREIGN KEY (`id_mobil`) REFERENCES `mobil` (`id_mobil`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 7) Galeri multi-foto mobil
CREATE TABLE IF NOT EXISTS `mobil_foto` (
  `id_foto` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `id_mobil` int(10) unsigned NOT NULL,
  `file` varchar(255) NOT NULL,
  `urutan` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id_foto`),
  KEY `idx_mobil_foto` (`id_mobil`),
  CONSTRAINT `fk_mobil_foto_mobil` FOREIGN KEY (`id_mobil`) REFERENCES `mobil` (`id_mobil`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
