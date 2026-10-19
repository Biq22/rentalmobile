-- MariaDB dump 10.19  Distrib 10.4.32-MariaDB, for Win64 (AMD64)
--
-- Host: localhost    Database: rental_mobil
-- ------------------------------------------------------
-- Server version	10.4.32-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `rental_mobil`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `rental_mobil` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci */;

USE `rental_mobil`;

--
-- Table structure for table `favorit`
--

DROP TABLE IF EXISTS `favorit`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `favorit` (
  `id_favorit` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `id_pelanggan` int(10) unsigned NOT NULL,
  `id_mobil` int(10) unsigned NOT NULL,
  `dibuat_pada` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_favorit`),
  UNIQUE KEY `uq_favorit` (`id_pelanggan`,`id_mobil`),
  KEY `fk_favorit_mobil` (`id_mobil`),
  CONSTRAINT `fk_favorit_mobil` FOREIGN KEY (`id_mobil`) REFERENCES `mobil` (`id_mobil`),
  CONSTRAINT `fk_favorit_pelanggan` FOREIGN KEY (`id_pelanggan`) REFERENCES `pelanggan` (`id_pelanggan`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `favorit`
--

LOCK TABLES `favorit` WRITE;
/*!40000 ALTER TABLE `favorit` DISABLE KEYS */;
/*!40000 ALTER TABLE `favorit` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `kategori`
--

DROP TABLE IF EXISTS `kategori`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `kategori` (
  `id_kategori` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `nama` varchar(50) NOT NULL,
  `ikon` varchar(255) DEFAULT NULL,
  `deskripsi` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id_kategori`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `kategori`
--

LOCK TABLES `kategori` WRITE;
/*!40000 ALTER TABLE `kategori` DISABLE KEYS */;
INSERT INTO `kategori` VALUES (1,'Toyota',NULL,NULL),(2,'Honda',NULL,NULL);
/*!40000 ALTER TABLE `kategori` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `laporan`
--

DROP TABLE IF EXISTS `laporan`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `laporan` (
  `id_laporan` int(11) NOT NULL AUTO_INCREMENT,
  `id_pegawai` int(11) NOT NULL,
  `tanggal_laporan` date NOT NULL,
  `rata_rata_order` decimal(12,2) NOT NULL,
  `total_order` int(11) NOT NULL,
  `total_pendapatan` decimal(12,2) NOT NULL,
  `keterangan` text NOT NULL,
  PRIMARY KEY (`id_laporan`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `laporan`
--

LOCK TABLES `laporan` WRITE;
/*!40000 ALTER TABLE `laporan` DISABLE KEYS */;
INSERT INTO `laporan` VALUES (1,1,'2026-06-24',758333.33,6,4550000.00,'Semua Status'),(2,1,'2026-06-24',0.00,0,0.00,'pending'),(3,1,'2026-06-24',1050000.00,1,1050000.00,'selesai'),(4,1,'2026-06-24',700000.00,1,700000.00,'batal'),(5,1,'2026-06-24',0.00,0,0.00,'ditolak');
/*!40000 ALTER TABLE `laporan` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mobil`
--

DROP TABLE IF EXISTS `mobil`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mobil` (
  `id_mobil` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `id_kategori` int(10) unsigned DEFAULT NULL,
  `kategori` varchar(50) NOT NULL,
  `tipe` varchar(100) NOT NULL,
  `plat_nomer` varchar(15) NOT NULL,
  `tahun` year(4) NOT NULL,
  `warna` varchar(30) NOT NULL,
  `kondisi` varchar(30) NOT NULL,
  `harga_sewa_per_hari` decimal(10,2) NOT NULL,
  `status` enum('tersedia','disewa') NOT NULL,
  `foto` varchar(255) DEFAULT NULL,
  `kapasitas` int(11) DEFAULT NULL,
  `transmisi` varchar(20) DEFAULT NULL,
  `opsi_supir` enum('tanpa_supir','dengan_supir','keduanya') NOT NULL DEFAULT 'tanpa_supir',
  `harga_supir_per_hari` decimal(10,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`id_mobil`),
  KEY `fk_mobil_kategori` (`id_kategori`),
  CONSTRAINT `fk_mobil_kategori` FOREIGN KEY (`id_kategori`) REFERENCES `kategori` (`id_kategori`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mobil`
--

LOCK TABLES `mobil` WRITE;
/*!40000 ALTER TABLE `mobil` DISABLE KEYS */;
INSERT INTO `mobil` VALUES (1,1,'Toyota','Avanza Matic','B 1726 UEL',2025,'Red','Baik',350000.00,'disewa','mobil_toyota.jpg',4,'Automatic','keduanya',150000.00),(2,1,'Toyota','Rush','B 2922 BGW',2019,'White','Sangat Baik',350000.00,'disewa','mobil_toyota.jpg',5,'Manual','keduanya',150000.00),(3,1,'Toyota ','Camry ','B 1098 UML',2019,'White','Sangat Baik',400000.00,'disewa','mobil_toyota.jpg',NULL,NULL,'keduanya',150000.00),(4,1,'Toyota','Calya','B 4927 UKM',2016,'Gray','Baik',350000.00,'tersedia','1791870329_545d93b9028b976a.jpg',NULL,'Manual','keduanya',150000.00),(5,1,'Toyota','Avanza New','B 4927 UKM',2026,'White','Baik',350000.00,'disewa','mobil_toyota.jpg',NULL,NULL,'keduanya',150000.00),(6,2,'Honda','Brio','B 1087 UHK',2017,'Yellow','Sangat Baik',350000.00,'tersedia','mobil_honda.jpg',NULL,NULL,'keduanya',150000.00),(8,1,'Toyota','Camry Baru','B 7897 OKL',2023,'White','Baik',450000.00,'tersedia','mobil_toyota.jpg',NULL,NULL,'keduanya',150000.00);
/*!40000 ALTER TABLE `mobil` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mobil_foto`
--

DROP TABLE IF EXISTS `mobil_foto`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mobil_foto` (
  `id_foto` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `id_mobil` int(10) unsigned NOT NULL,
  `file` varchar(255) NOT NULL,
  `urutan` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id_foto`),
  KEY `idx_mobil_foto` (`id_mobil`),
  CONSTRAINT `fk_mobil_foto_mobil` FOREIGN KEY (`id_mobil`) REFERENCES `mobil` (`id_mobil`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mobil_foto`
--

LOCK TABLES `mobil_foto` WRITE;
/*!40000 ALTER TABLE `mobil_foto` DISABLE KEYS */;
/*!40000 ALTER TABLE `mobil_foto` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pegawai`
--

DROP TABLE IF EXISTS `pegawai`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pegawai` (
  `id_pegawai` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `nama` varchar(100) NOT NULL,
  `username` varchar(50) DEFAULT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `otp_code` varchar(10) DEFAULT NULL,
  `otp_expired` datetime DEFAULT NULL,
  `no_telepon` varchar(15) NOT NULL,
  `jabatan` varchar(50) NOT NULL,
  `alamat` text NOT NULL,
  `foto` varchar(255) DEFAULT NULL,
  `token` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id_pegawai`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pegawai`
--

LOCK TABLES `pegawai` WRITE;
/*!40000 ALTER TABLE `pegawai` DISABLE KEYS */;
INSERT INTO `pegawai` VALUES (1,'Alen','alen','monamose72@gmail.com','$2y$10$fSulZLdAZ6E0cmQvAM9.jeOAPHGIxR3tf5ZkDwAmRdrbR01RtyS4S','189315','2026-06-25 05:41:20','08123456789','Admin ','Bekasi ',NULL,NULL),(3,'bina',NULL,'bina@gmail.com','280306',NULL,NULL,'082134678888','admin 2','Jl. Kramat raya',NULL,'6876397caca31942c2e3d1bbbd202d5ba7eb92556724935df0c90fa7d3da85d7'),(4,'ismul','ismul ganteng','itsbibin04002@gmail.com','$2y$10$B.Fgid.pee8bNjpH8RANCu5F9f/UWzn5f7ClRgo2EvfxjPT4C.cDO',NULL,NULL,'087765453367','Admin 3','jl cakung',NULL,NULL),(5,'Staff Operasional',NULL,'staff@rentalmobile.test','$2y$10$jYZBAqQhzXLR46MA61Rmr.sYiogC//0VIiILuf9b1orDml/Dv5SXO',NULL,NULL,'0812345678','Staff','Surabaya',NULL,NULL);
/*!40000 ALTER TABLE `pegawai` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pelanggan`
--

DROP TABLE IF EXISTS `pelanggan`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pelanggan` (
  `id_pelanggan` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `nama` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `no_telpon` varchar(15) NOT NULL,
  `no_ktp` varchar(20) NOT NULL,
  `alamat` text NOT NULL,
  `foto` varchar(255) DEFAULT NULL,
  `foto_ktp` varchar(255) DEFAULT NULL,
  `pekerjaan` varchar(100) DEFAULT NULL,
  `password` varchar(255) NOT NULL DEFAULT '',
  `token` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id_pelanggan`)
) ENGINE=InnoDB AUTO_INCREMENT=35 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pelanggan`
--

LOCK TABLES `pelanggan` WRITE;
/*!40000 ALTER TABLE `pelanggan` DISABLE KEYS */;
INSERT INTO `pelanggan` VALUES (1,'Budi Santoso','budi@gmail.com','081234567890','3201010101010001','Jakarta',NULL,NULL,NULL,'',NULL),(2,'Andi Saputra','andi@gmail.com','082345678901','3201010101010002','Bekasi',NULL,NULL,NULL,'',NULL),(3,'Siti Nurhaliza','siti@gmail.com','083456789012','3201010101010003','Bandung',NULL,NULL,NULL,'',NULL),(15,'zalfa','zalpa@gmail.com','0821346780','978868677654545','jl.arah terusan menteng no.29',NULL,NULL,'mahasiswa','',NULL),(16,'gendis','gendis@gmail.com','0897653642','300781937354527','jl sungai x',NULL,NULL,'mahasiswa','',NULL),(19,'azam','azam@gmail.com','08213476644','300781937354986','jl.arah terusan menteng no.330',NULL,NULL,NULL,'',NULL),(20,'mariadi','mariadi14@gmail.com','08976654721','3000178927665339','J. Batu Perak II no.90',NULL,NULL,'karyawan swasta','',NULL),(21,'mariadi','mariadi14@gmail.com','08976654721','3000178927665339','J. Batu Perak II no.90',NULL,NULL,'karyawan swasta','',NULL),(22,'mariadi','mariadi14@gmail.com','08976654721','3000178927665339','J. Batu Perak II no.90',NULL,NULL,'karyawan swasta','',NULL),(23,'ismul','ismul19@gmail.com','08976452711','3000178987244422','jl; kramat II no.09',NULL,NULL,'mahasiswa','',NULL),(24,'ismul','ismul19@gmail.com','08976452711','3000178987244422','.........',NULL,NULL,'mahasiswa','',NULL),(26,'Kevan','kvn@gmail.com','0897654321','1234567890','THB',NULL,NULL,'Pelaut','',NULL),(27,'fikri','fikri1212@gmail.com','09887762311','3000179826622331','jl kramat jati ',NULL,NULL,'karyawan swasta','',NULL),(28,'Tester','tester1@example.com','0811111111','3201010101019999','Jl Test 123',NULL,NULL,NULL,'$2y$10$rOnLLae8y9FP2tn9DX.HBO.ZPqEUOjbGX2V58VBrjNAKEYzaYe6HO',NULL),(29,'Ktp User Updated','ktp@example.com','08999','333','Jl Baru No 1',NULL,NULL,'Mahasiswa','$2y$10$Kzhg.FLoeQlGQOijKQtnle5QhkZJSHP47JKVoX/nBLyK3hIhPBLke','43069ea84ba217407d38ff0127f43511a3293b0b803157f8983bffbe8e7223d0'),(30,'abiq','abiq@gmail.com','081287478','1111111','jalan sini',NULL,NULL,NULL,'$2y$10$iNIVOrbcO8kEqeQuv5tQXORRovkVKvdOtvawrQ4ivOU.rh0t2Jnka',NULL),(32,'abiq','abiq22@gmail.com','081255569','1212115257','jakarta',NULL,'1791569761_ee40736338c5d067.jpg',NULL,'$2y$10$YRBYqRDfuHHH/aQt9Q9yEeuACTHDOOj4qjHrHVzxKIvrauN2iYdV6',NULL);
/*!40000 ALTER TABLE `pelanggan` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pembayaran`
--

DROP TABLE IF EXISTS `pembayaran`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pembayaran` (
  `id_pembayaran` int(11) NOT NULL AUTO_INCREMENT,
  `id_pesanan` int(10) unsigned NOT NULL,
  `tanggal_bayar` date NOT NULL,
  `total_bayar` decimal(12,2) NOT NULL,
  `metode_pembayaran` enum('Cash','Transfer','QRIS') NOT NULL,
  `status_pembayaran` enum('Pending','Lunas','Gagal','Kadaluarsa') NOT NULL DEFAULT 'Pending',
  `nomor_va` varchar(30) DEFAULT NULL,
  `batas_pembayaran` datetime DEFAULT NULL,
  `bukti` varchar(255) DEFAULT NULL,
  `diverifikasi_oleh` int(10) unsigned DEFAULT NULL,
  `catatan` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id_pembayaran`),
  KEY `id_pesanan` (`id_pesanan`)
) ENGINE=InnoDB AUTO_INCREMENT=37 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pembayaran`
--

LOCK TABLES `pembayaran` WRITE;
/*!40000 ALTER TABLE `pembayaran` DISABLE KEYS */;
INSERT INTO `pembayaran` VALUES (1,1,'2026-04-25',1050000.00,'Cash','Lunas',NULL,NULL,NULL,NULL,NULL),(22,16,'2026-06-19',1400000.00,'Transfer','Lunas','880064940191',NULL,NULL,NULL,NULL),(25,19,'2026-06-22',700000.00,'Cash','Kadaluarsa',NULL,'2026-06-23 15:41:37',NULL,NULL,NULL),(26,20,'2026-06-22',700000.00,'Cash','Pending',NULL,NULL,NULL,NULL,NULL),(27,21,'2026-06-22',350000.00,'QRIS','Pending',NULL,NULL,NULL,NULL,NULL),(28,22,'2026-06-22',350000.00,'QRIS','Pending',NULL,NULL,NULL,NULL,NULL),(29,23,'2026-06-25',350000.00,'Cash','Lunas',NULL,'2026-06-26 04:04:25',NULL,NULL,NULL),(30,25,'2026-06-25',400000.00,'QRIS','Pending',NULL,NULL,NULL,NULL,NULL),(31,27,'2026-10-09',1050000.00,'QRIS','Lunas',NULL,NULL,NULL,NULL,NULL),(32,28,'2026-10-09',700000.00,'QRIS','Lunas',NULL,NULL,NULL,NULL,NULL),(36,32,'2026-10-10',700000.00,'','Pending',NULL,NULL,NULL,NULL,NULL);
/*!40000 ALTER TABLE `pembayaran` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pengaturan`
--

DROP TABLE IF EXISTS `pengaturan`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pengaturan` (
  `kunci` varchar(50) NOT NULL,
  `nilai` text DEFAULT NULL,
  PRIMARY KEY (`kunci`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pengaturan`
--

LOCK TABLES `pengaturan` WRITE;
/*!40000 ALTER TABLE `pengaturan` DISABLE KEYS */;
INSERT INTO `pengaturan` VALUES ('alamat','Jl. Raya Rental No. 123, Surabaya'),('email','info@rentalmobil.test'),('jam_operasional','Senin - Sabtu, 08.00 - 20.00 WIB'),('nama_perusahaan','Rental Mobil'),('qris','RM-RENTALMOBIL'),('rekening','BCA 1234567890 a/n Rental Mobil'),('tarif_denda_per_hari','50000'),('telepon','0812-3456-7890'),('tentang','Layanan sewa mobil yang mudah, cepat, dan terpercaya. Tersedia pilihan lepas kunci maupun dengan supir untuk kebutuhan perjalananmu.'),('visi','Menjadi penyedia jasa sewa mobil terbaik dan tepercaya.');
/*!40000 ALTER TABLE `pengaturan` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pesanan`
--

DROP TABLE IF EXISTS `pesanan`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pesanan` (
  `id_pesanan` int(11) NOT NULL AUTO_INCREMENT,
  `id_pelanggan` int(10) unsigned NOT NULL,
  `id_pegawai` int(10) unsigned DEFAULT NULL,
  `id_supir` int(10) unsigned DEFAULT NULL,
  `id_mobil` int(10) unsigned NOT NULL,
  `tanggal_pesanan` date NOT NULL,
  `tanggal_sewa` date NOT NULL,
  `lama_sewa` int(11) NOT NULL,
  `tanggal_selesai` date DEFAULT NULL,
  `total_harga` decimal(12,2) NOT NULL,
  `status_pesanan` enum('pending','diproses','selesai','batal','ditolak') NOT NULL,
  `waktu_pengambilan` datetime DEFAULT NULL,
  `waktu_pengembalian` datetime DEFAULT NULL,
  `dibaca` tinyint(1) NOT NULL DEFAULT 0,
  `pakai_supir` tinyint(1) NOT NULL DEFAULT 0,
  `biaya_supir` decimal(12,2) NOT NULL DEFAULT 0.00,
  `id_promo` int(10) unsigned DEFAULT NULL,
  `diskon` decimal(12,2) NOT NULL DEFAULT 0.00,
  `nama_penyewa` varchar(100) DEFAULT NULL,
  `email_penyewa` varchar(100) DEFAULT NULL,
  `telpon_penyewa` varchar(20) DEFAULT NULL,
  `ktp_penyewa` varchar(20) DEFAULT NULL,
  `alamat_penyewa` text DEFAULT NULL,
  `pekerjaan_penyewa` varchar(100) DEFAULT NULL,
  `foto_ktp_penyewa` varchar(255) DEFAULT NULL,
  `tanggal_kembali_aktual` date DEFAULT NULL,
  `denda` decimal(12,2) NOT NULL DEFAULT 0.00,
  `kondisi_kembali` varchar(50) DEFAULT NULL,
  `catatan_kembali` text DEFAULT NULL,
  `dibaca_pegawai` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id_pesanan`),
  KEY `id_pelanggan` (`id_pelanggan`),
  KEY `id_pegawai` (`id_pegawai`,`id_mobil`),
  KEY `mobil` (`id_mobil`),
  KEY `fk_pesanan_supir` (`id_supir`),
  CONSTRAINT `fk_pesanan_supir` FOREIGN KEY (`id_supir`) REFERENCES `supir` (`id_supir`),
  CONSTRAINT `mobil` FOREIGN KEY (`id_mobil`) REFERENCES `mobil` (`id_mobil`),
  CONSTRAINT `pegawai` FOREIGN KEY (`id_pegawai`) REFERENCES `pegawai` (`id_pegawai`),
  CONSTRAINT `pelanggan` FOREIGN KEY (`id_pelanggan`) REFERENCES `pelanggan` (`id_pelanggan`)
) ENGINE=InnoDB AUTO_INCREMENT=33 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pesanan`
--

LOCK TABLES `pesanan` WRITE;
/*!40000 ALTER TABLE `pesanan` DISABLE KEYS */;
INSERT INTO `pesanan` VALUES (1,1,1,NULL,1,'2026-06-09','2026-04-22',3,NULL,1050000.00,'selesai',NULL,NULL,0,0,0.00,NULL,0.00,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0.00,NULL,NULL,0),(16,15,1,NULL,1,'2026-06-19','2026-06-27',4,NULL,1400000.00,'diproses','2026-06-27 18:00:00','2026-07-01 18:00:00',0,0,0.00,NULL,0.00,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0.00,NULL,NULL,0),(17,16,1,NULL,5,'2026-06-21','2026-06-30',2,NULL,700000.00,'batal','2026-06-30 10:00:00','2026-07-02 10:00:00',0,0,0.00,NULL,0.00,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0.00,NULL,NULL,0),(20,20,1,NULL,5,'2026-06-22','2026-06-24',2,NULL,700000.00,'ditolak','2026-06-24 18:00:00','2026-06-26 18:00:00',0,0,0.00,NULL,0.00,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0.00,NULL,NULL,0),(21,21,1,NULL,2,'2026-06-22','2026-06-27',1,NULL,350000.00,'diproses','2026-06-27 06:00:00','2026-06-28 06:00:00',0,0,0.00,NULL,0.00,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0.00,NULL,NULL,0),(22,22,1,NULL,6,'2026-06-22','2026-06-27',1,NULL,350000.00,'pending','2026-06-27 06:00:00','2026-06-28 06:00:00',0,0,0.00,NULL,0.00,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0.00,NULL,NULL,0),(23,23,1,NULL,5,'2026-06-25','2026-06-29',1,NULL,350000.00,'diproses','2026-06-29 06:00:00','2026-06-30 06:00:00',0,0,0.00,NULL,0.00,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0.00,NULL,NULL,0),(24,24,1,NULL,3,'2026-06-25','2026-06-30',1,NULL,400000.00,'diproses','2026-06-30 06:00:00','2026-07-01 06:00:00',0,0,0.00,NULL,0.00,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0.00,NULL,NULL,0),(26,26,1,NULL,3,'2026-06-25','2026-06-28',1,NULL,400000.00,'diproses','2026-06-28 06:00:00','2026-06-29 06:00:00',0,0,0.00,NULL,0.00,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0.00,NULL,NULL,0),(27,27,1,NULL,1,'2026-06-25','2026-06-27',3,NULL,1050000.00,'selesai','2026-06-27 06:00:00','2026-06-30 06:00:00',0,0,0.00,NULL,0.00,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0.00,NULL,NULL,0),(28,28,NULL,NULL,1,'2026-10-07','2026-10-20',2,NULL,700000.00,'selesai',NULL,NULL,0,0,0.00,NULL,0.00,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0.00,NULL,NULL,0),(32,32,NULL,NULL,2,'2026-10-10','2026-10-10',2,'2026-10-11',700000.00,'pending','2026-10-10 09:00:00',NULL,0,1,0.00,NULL,0.00,'abiq','abiq22@gmail.com','081255569','1212115257','jakarta',NULL,'1791569761_ee40736338c5d067.jpg',NULL,0.00,NULL,NULL,0);
/*!40000 ALTER TABLE `pesanan` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `promo`
--

DROP TABLE IF EXISTS `promo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `promo` (
  `id_promo` int(11) NOT NULL AUTO_INCREMENT,
  `kode` varchar(30) NOT NULL,
  `judul` varchar(120) NOT NULL,
  `deskripsi` text DEFAULT NULL,
  `tipe` enum('persen','nominal') NOT NULL DEFAULT 'persen',
  `nilai` decimal(12,2) NOT NULL DEFAULT 0.00,
  `min_transaksi` decimal(12,2) NOT NULL DEFAULT 0.00,
  `maks_diskon` decimal(12,2) DEFAULT NULL,
  `aktif` tinyint(1) NOT NULL DEFAULT 1,
  `tanggal_mulai` date DEFAULT NULL,
  `tanggal_selesai` date DEFAULT NULL,
  `dibuat_pada` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_promo`),
  UNIQUE KEY `uq_promo_kode` (`kode`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `promo`
--

LOCK TABLES `promo` WRITE;
/*!40000 ALTER TABLE `promo` DISABLE KEYS */;
INSERT INTO `promo` VALUES (1,'GAJIAN10','Diskon Gajian 10%','Potongan 10% untuk semua mobil, maksimal Rp150.000.','persen',10.00,300000.00,150000.00,1,NULL,NULL,'2026-10-09 17:27:20'),(2,'NEWBIE50','Penyewa Baru Hemat Rp50.000','Potongan Rp50.000 untuk transaksi minimal Rp400.000.','nominal',50000.00,400000.00,NULL,1,NULL,NULL,'2026-10-09 17:27:20'),(3,'WEEKEND15','Weekend Seru 15%','Potongan 15% khusus akhir pekan, maksimal Rp200.000.','persen',15.00,250000.00,200000.00,1,NULL,NULL,'2026-10-09 17:27:20');
/*!40000 ALTER TABLE `promo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `supir`
--

DROP TABLE IF EXISTS `supir`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `supir` (
  `id_supir` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `nama` varchar(100) NOT NULL,
  `no_telpon` varchar(20) NOT NULL,
  `no_sim` varchar(30) NOT NULL,
  `harga_per_hari` decimal(10,2) NOT NULL DEFAULT 0.00,
  `foto` varchar(255) DEFAULT NULL,
  `status` enum('aktif','nonaktif') NOT NULL DEFAULT 'aktif',
  `dibuat_pada` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_supir`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `supir`
--

LOCK TABLES `supir` WRITE;
/*!40000 ALTER TABLE `supir` DISABLE KEYS */;
/*!40000 ALTER TABLE `supir` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ulasan`
--

DROP TABLE IF EXISTS `ulasan`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ulasan` (
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
  CONSTRAINT `fk_ulasan_mobil` FOREIGN KEY (`id_mobil`) REFERENCES `mobil` (`id_mobil`),
  CONSTRAINT `fk_ulasan_pelanggan` FOREIGN KEY (`id_pelanggan`) REFERENCES `pelanggan` (`id_pelanggan`),
  CONSTRAINT `fk_ulasan_pesanan` FOREIGN KEY (`id_pesanan`) REFERENCES `pesanan` (`id_pesanan`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ulasan`
--

LOCK TABLES `ulasan` WRITE;
/*!40000 ALTER TABLE `ulasan` DISABLE KEYS */;
/*!40000 ALTER TABLE `ulasan` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-14 19:02:46
