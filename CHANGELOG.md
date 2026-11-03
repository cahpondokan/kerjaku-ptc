# Changelog

## 1.8.3+19 — Riwayat cuti lebih jelas

- Surat cuti dibaca kembali dari database setelah disimpan untuk memastikan masuk ke riwayat.
- Saldo membedakan cuti dari surat yang tersimpan dan cuti yang digunakan sebelum aplikasi dipakai.

## 1.8.2+18 — Otomatis menghitung lembur lama

- Catatan lama tanpa dasar upah tersimpan otomatis memakai dasar upah dari Profil.
- Impor cadangan mempertahankan pengaturan KerjaKu PTC yang tidak tersedia di cadangan lama, seperti profil dan gaji.

## 1.8.1+17 — Ekspor langsung ke berkas

- Ekspor cadangan membuka pemilih lokasi Android dan menyimpan JSON langsung ke lokasi pilihan.

## 1.8.0+16 — Cadangan data

- Menambahkan ekspor dan impor cadangan JSON untuk catatan lembur, surat cuti, saldo, profil, gaji, dan pengaturan.
- Pemulihan memvalidasi format cadangan dan meminta konfirmasi sebelum mengganti data di perangkat.
- Mempertahankan package `com.niam.ayani.kerjakuptc` dan database lokal agar pembaruan tidak menghapus data yang sudah tersimpan.

## 1.5.1+12 — Ikon KerjaKu PTC

- Memasang ikon dokumen, centang, dan jam sesuai desain yang disetujui.
- Menyiapkan PNG utama, lapisan foreground transparan, ikon launcher lima kepadatan, ikon bulat, dan adaptive icon dengan latar gradasi biru.
- Menampilkan ikon baru pada beranda.
- Mempertahankan package `com.niam.ayani.kerjakuptc` agar APK dapat memperbarui instalasi dengan package yang sama.

## 1.5.0+11 — Surat cuti otomatis

- Memperbarui application ID, namespace, lokasi MainActivity, dan channel WhatsApp menjadi `com.niam.ayani.kerjakuptc`.

- Mengaktifkan Surat Cuti dari Beranda dan Dokumen dengan riwayat per tahun.
- Menghitung hak 12 hari, lama cuti Senin–Jumat, tanggal masuk kembali, serta saldo otomatis.
- Menyimpan pemakaian sebelum aplikasi, alasan/alamat terakhir, pilihan penandatangan, dan surat dalam SQLite.
- Menolak benturan tanggal, jatah berlebih, cuti akhir pekan saja, serta rentang lintas tahun.
- Menambahkan ubah/hapus surat; cetak ulang dan berbagi tidak mengurangi saldo lagi.
- Menghasilkan PDF A4 mendatar mengikuti susunan formulir contoh dengan logo PTC dan ruang tanda tangan kosong.
- Menjaga pemeriksaan profil/konfirmasi penandatangan sebelum menyimpan dan mencetak surat, serta seluruh fitur lembur.

## 1.4.0+10 — KerjaKu PTC

- Mengubah nama aplikasi menjadi KerjaKu PTC dan application ID menjadi `niam.ayani.kerjakuptc`.
- Menerapkan beranda baru, navigasi Beranda/Riwayat/Dokumen/Profil, dan menu informasi Surat Cuti.
- Menambahkan pemeriksaan seluruh data profil dan konfirmasi daftar nama/jabatan penandatangan.
- Mengingatkan pada pembukaan aplikasi dan kembali dari latar belakang, sampai data wajib lengkap.
- Memblokir seluruh ekspor dan berbagi rekap sebelum data wajib siap, termasuk catatan lama dengan nama contoh.
- Mempertahankan pencatatan, pengeditan, penghapusan, perhitungan, dan output lembur.

## 1.3.0+9 - V9 Output Final & Responsive Form

- Mengubah kode surat permintaan menjadi `PPNLK0101`.
- Mempertahankan nomor urut kosong dan tahun otomatis mengikuti tanggal lembur.
- Mengubah judul Excel menjadi `JUSTIFIKASI KELEBIHAN JAM KERJA LEMBUR TAD AFT AHMAD YANI`.
- Menambahkan baris `PERIODE BULAN ...` sesuai periode rekap.
- Menambahkan kolom `NOMOR PEKERJA` pada setiap baris Excel.
- Menyesuaikan urutan kolom, total, lebar kolom, dan blok tanda tangan Excel.
- Tanggal tanda tangan rekap otomatis menjadi tanggal 1 bulan berikutnya.
- Memperbaiki overflow pada dropdown Jenis Hari di layar Android yang sempit.
- Menambahkan ellipsis aman pada seluruh pilihan dropdown.
- Menambah ruang bawah form agar tombol Simpan tidak tertutup bottom navigation.

## 1.2.0+8 - V8 Logo & SPKL Layout

- Menambahkan logo Pertamina Patra Niaga pada bagian Surat Permintaan Kerja Lembur.
- Menambahkan logo PTC pada bagian Surat Perintah Kerja Lembur.
- Memperbaiki susunan PDF agar lebih menyerupai contoh SPKL resmi.
- Satu data lembur tetap menghasilkan satu halaman PDF.
- Nomor permintaan menjadi `No.SPKL -          / PPNLK0101 / TAHUN-S0`.
- Nomor perintah menjadi `No.          /SPKL/PTC/TAHUN`.
- Hanya bagian nomor urut yang dibiarkan kosong; tahun mengikuti tanggal lembur tiap halaman.
- Jam pada PDF dan Excel ditampilkan dengan tanda titik, misalnya `08.00`.
- Jam masuk dan jam pulang Security/HSE otomatis mengikuti waktu lembur.
- Pejabat PTC default: Ricky Roy Sagita.
- Jabatan PTC default: Manager Manpower Supply - PTC.
- Nama dan jabatan pejabat PTC dapat diubah dari halaman Pengaturan.
- Menambahkan unit test format nomor SPKL.
- Menambahkan dokumen referensi tampilan PDF.

## 1.1.1+7 - V7 Analyze Fix

- Memindahkan backup installer keluar root project agar tidak dianalisis Flutter.
- Menghapus import yang tidak diperlukan.
- Mempertahankan fitur PDF, Excel, WhatsApp, SQLite, dan tema neumorphism.
