# Surat Permintaan Perjalanan Dinas

Versi aplikasi: 1.9.0+20. Desain disetujui pengguna, dengan koreksi nomor surat pada 11 November 2026. Gambar dan galeri revisi ada di `design/pengajuan-dinas-v2/`.

## Nomor surat

Format: `No. {nomor atau ...} /SPPD/ {bulan Romawi} /{tahun}-S8`.

- Bulan memakai I, II, III, IV, V, VI, VII, VIII, IX, X, XI, XII.
- Bulan/tahun berasal dari **tanggal surat** yang dipilih, default tanggal saat membuat surat baru.
- Tanggal perjalanan tidak mengubah nomor. Membuka surat pada bulan/tahun lain tidak mengubah nomor tersimpan.
- Nomor urut hanya angka, opsional, maksimum 20 digit. Nol di depan dipertahankan. Kosong/whitespace ditampilkan sebagai tiga titik ASCII.
- Tanggal surat 2 November 2026 dan nomor kosong menghasilkan `No. ... /SPPD/ XI /2026-S8`.

## Isian dan alur

1. Identitas: nama, ID Card, penempatan, jenis pekerjaan dari Profil; penerima dan nomor urut.
2. Perjalanan: asal, tujuan, tanggal mulai/kembali, keperluan, kendaraan, penanggung biaya. Durasi ditampilkan sebagai hari kalender inklusif; tidak mengurangi saldo cuti.
3. Tinjau: tempat/tanggal surat, nama/jabatan AFT dari daftar Profil, ringkasan dan konfirmasi pemeriksaan.

Draf boleh belum lengkap. Surat final memerlukan data lengkap, profil siap, penandatangan terkonfirmasi, tanggal valid, dan kotak pemeriksaan dicentang. Penyimpanan dibaca kembali dari repository sebelum pesan berhasil ditampilkan. Perubahan yang belum disimpan memunculkan pilihan simpan draf/buang/kembali ketika keluar.

Data profil disalin ke surat. Mengubah Profil kemudian tidak mengganti surat lama. Pada formulir edit, tombol **Perbarui isian dari Profil** tersedia secara eksplisit. PDF menggunakan data surat tersimpan. Status aplikasi hanya Draf/Tersimpan, tidak menyatakan persetujuan pejabat.

## Dokumen

- Satu halaman A4 tegak, logo Pertamina Patra Niaga hitam di kanan atas, judul dan nomor di tengah, baris data tanpa garis tabel, serta ruang tanda tangan kiri bawah.
- Logo berasal dari aset aplikasi yang sudah ada, diwarnai hitam saat render; aset asli tetap sama.
- Nama/jabatan dicetak, ruang tanda tangan dibiarkan kosong untuk penandatangan.
- Isian panjang dibungkus; keseluruhan isi diskalakan turun jika diperlukan agar tetap pada satu halaman.
- Simpan PDF memakai Android Storage Access Framework melalui channel aplikasi yang sudah ada. Pengguna memilih lokasi penyimpanan. Cetak/bagikan memakai plugin Printing yang sudah tersedia.

## Penyimpanan dan kompatibilitas

Bagian berikut mencatat format awal versi 1.9.0. Versi 1.10.0 menambah schema 5, scan per dokumen, dan cadangan versi 3; lihat [SCAN_BERKAS_DINAS.md](SCAN_BERKAS_DINAS.md).

- SQLite `lembur_ptc.db`, schema 4, tabel tambahan `duty_entries`.
- Upgrade dari schema 3 hanya membuat tabel dinas. Tabel/catatan lembur, cuti, saldo awal, serta pengaturan gaji tetap dipertahankan.
- Backup format 2 memuat tabel dinas, termasuk draf, tanggal surat dan salinan identitas/penandatangan.
- Backup format 1/schema 1–3 tetap diterima. Jika tidak ada tabel dinas, pemulihan tidak menghapus surat dinas di perangkat.
- Backup baru yang rusak, berisi surat final tidak lengkap, status tak dikenal, atau ID surat duplikat ditolak sebelum transaksi pemulihan.
- Data lokal HP tidak diakses dan APK belum dipasang selama pekerjaan ini.

## Verifikasi

Tes otomatis mencakup 12 bulan, pergantian tahun, nomor kosong/nol di depan, pembukaan ulang draf, kegagalan simpan, penggantian draf menjadi surat final, validasi backup, alur edit tanggal surat melalui UI, layar 320 piksel pada skala teks 1,5, serta generator PDF dengan isian normal dan panjang. PDF contoh dirender untuk pemeriksaan visual.
