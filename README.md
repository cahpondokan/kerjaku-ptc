# KerjaKu PTC

Aplikasi Android offline untuk pencatatan lembur pekerja PTC/TAD, perhitungan jam dan estimasi upah lembur, pembuatan PDF SPKL, rekap Excel bulanan, serta surat permohonan cuti dengan saldo tahunan otomatis.

## Identitas Project

- Nama aplikasi: **KerjaKu PTC**
- Project Flutter: `lembur`
- Package Android: `com.niam.ayani.kerjakuptc`
- Platform: Android
- Sistem: offline
- Versi paket: `1.8.3+19`
- Kompatibilitas Dart: `>=3.7.0 <4.0.0`

## Fitur

- Beranda biru dengan ringkasan lembur, layanan, dokumen, dan aktivitas terbaru.
- Pilihan Lembur dan Surat Cuti selalu sejajar dalam satu baris, termasuk pada layar sempit dan ukuran teks besar.
- Gaji pokok, tunjangan tetap, dan tunjangan tidak tetap dapat diisi dari Profil. Dasar upah dan estimasi lembur dihitung otomatis.
- Estimasi bruto setiap catatan dan total bulanan di Beranda, Riwayat, dan Rekap, dengan tombol sembunyikan nominal.
- Dasar upah disimpan per catatan; catatan lama tanpa dasar tersimpan otomatis memakai gaji Profil.
- Navigasi Beranda, Riwayat, Dokumen, dan Profil; tambah/edit lembur diakses dari Beranda dan Riwayat.
- Pengingat profil saat aplikasi dibuka dan saat kembali dari latar belakang. Tombol Nanti hanya menutup pengingat pada sesi tersebut.
- Semua delapan kolom profil wajib lengkap sebelum membuat dokumen.
- Nama dan jabatan penandatangan PTC/AFT wajib diperiksa dan dikonfirmasi. Perubahan daftar membatalkan konfirmasi sebelumnya.
- Minimal satu nama dan satu jabatan AFT; slot tidak terpakai boleh kosong. Nama contoh tidak dapat digunakan untuk ekspor.
- PDF, Excel, dan seluruh jalur berbagi dokumen terkunci sampai profil lengkap dan penandatangan dikonfirmasi.
- Surat cuti PDF A4 mendatar dengan susunan formulir PTC, logo, dan ruang tanda tangan.
- Hak cuti 12 hari per tahun, perhitungan hari kerja dan tanggal masuk kembali otomatis.
- Saldo cuti awal, riwayat, ubah/hapus surat, pratinjau, cetak, dan bagikan PDF.
- Database SQLite offline.
- Ekspor/impor cadangan JSON yang mencakup data lembur, cuti, profil, dan pengaturan.
- Tambah, edit, dan hapus data lembur.
- Perhitungan jam nyata dan jam konversi otomatis.
- Profil dan data pekerjaan tetap.
- Empat slot nama penandatangan AFT yang dapat diubah.
- Dua slot jabatan penandatangan AFT yang dapat diubah.
- Pejabat PTC default `Ricky Roy Sagita`.
- Jabatan PTC default `Manager Manpower Supply - PTC`.
- Nama dan jabatan pejabat PTC dapat diubah dari Pengaturan.
- Nomor WhatsApp admin tersimpan pada Pengaturan.
- PDF SPKL multi-halaman: satu data lembur menjadi satu halaman.
- Logo Pertamina Patra Niaga dan PTC otomatis tampil pada PDF.
- Nomor dokumen mengikuti tahun lembur dan hanya bagian nomor urut yang dibiarkan kosong.
- Rekap bulanan dalam format Excel dengan judul resmi dan kolom Nomor Pekerja.
- Berbagi PDF dan Excel melalui WhatsApp atau panel berbagi Android.
- Ikon launcher Android.
- Unit test perhitungan, WhatsApp, dan format nomor SPKL.

## Pemakaian Upah Lembur

1. Buka **Profil → Gaji & upah lembur → Isi gaji**. Isi komponen bulanan dalam rupiah; tunjangan yang tidak ada diisi `0`.
2. Buka **Lembur → Input**, isi waktu dan pilih jenis hari sesuai jadwal kerja. Periksa **Estimasi upah lembur** sebelum menyimpan.
3. Catatan baru memakai gaji profil saat disimpan. Catatan yang sudah memiliki dasar upah mempertahankan nilai tersebut ketika diedit.
4. Untuk riwayat lama berstatus **Belum dihitung**, buka **Edit → Gunakan gaji profil**, atau **Atur dasar upah catatan** jika gaji pada tanggal itu berbeda. Simpan Lembur untuk menerapkannya.
5. Lihat jumlah bulanan di Beranda/Riwayat/Rekap. Tombol mata menyembunyikan nominal pada ringkasan, daftar riwayat, dan kartu gaji profil; preferensinya tersimpan. Formulir pengeditan tetap memperlihatkan angka yang sedang diubah.

## Memindahkan Data ke Perangkat atau Instalasi Lain

1. Pada KerjaKu PTC yang masih menyimpan data lama, buka **Profil → Data & Keamanan → Ekspor**. Bagikan atau simpan berkas `KerjaKu_PTC_backup_*.json`.
2. Buka KerjaKu PTC pada perangkat/instalasi tujuan, pilih **Impor**, lalu pilih berkas cadangan JSON.
3. Periksa jumlah lembur dan surat cuti pada konfirmasi, lalu pilih **Pulihkan**. Pemulihan mengganti seluruh data serta pengaturan yang ada di instalasi tujuan.

Ekspor dan impor mencakup catatan lembur, surat cuti, saldo awal cuti, profil, gaji, daftar penandatangan, dan pengaturan. Jika aplikasi lama belum memiliki tombol ekspor, perbarui KerjaKu PTC di perangkat lama ke versi yang mendukung cadangan, ekspor dari sana, lalu impor berkasnya di instalasi tujuan. Berkas cadangan memuat data pribadi; simpan dan bagikan hanya melalui tempat tepercaya.

Perhitungan saat ini untuk gaji bulanan dan pola **5 hari kerja / 40 jam per minggu**, mengikuti pola konversi yang sudah digunakan aplikasi. Rumus, contoh, dan batas cakupan ada di [docs/OVERTIME_PAY.md](docs/OVERTIME_PAY.md). Gaji tidak wajib untuk membuat surat cuti atau dokumen SPKL. Estimasi upah ditampilkan di aplikasi; template PDF SPKL dan Excel resmi tetap menggunakan kolom yang ada.

## Pemakaian Surat Cuti

1. Lengkapi Profil dan konfirmasi daftar penandatangan.
2. Buka **Surat Cuti**, pilih tahun, lalu **Isi cuti sebelumnya** jika sudah memakai cuti sebelum aplikasi. Isi jumlah hari yang benar-benar mengurangi jatah. Nilainya tersimpan per tahun dan otomatis tampil pada formulir berikutnya; gunakan **Ubah cuti sebelumnya** untuk koreksi. Jangan mencatat ulang cuti tersebut sebagai surat baru.
3. Pilih **Buat surat cuti**, masukkan tanggal awal dan akhir. Alasan, alamat, serta pilihan penandatangan akan disimpan untuk pengajuan berikutnya.
4. Periksa tanggal surat dan pejabat, lalu **Simpan & lihat PDF**. Gunakan tombol cetak atau bagikan pada pratinjau.

Perhitungan mencakup tanggal awal dan akhir jika hari kerja. Sabtu, Minggu, libur nasional, dan cuti bersama tidak mengurangi jatah. Masuk kembali adalah hari kerja pertama sesudah tanggal akhir yang juga melewati seluruh hari libur tersebut. Pengajuan tanpa hari kerja, bertumpang tindih pada hari kerja, atau melebihi saldo ditolak. Rentang lintas tahun perlu dibuat sebagai dua surat karena setiap tahun mempunyai hak sendiri.

Kalender offline mencakup 2025–2027 sesuai SKB pemerintah, termasuk tambahan cuti bersama 18 Agustus 2025. Tombol **Lihat hari libur** menampilkan tanggal yang dilewati. Tahun di luar cakupan, termasuk tahun tanggal masuk kembali, memerlukan pembaruan kalender aplikasi sebelum surat dibuat. Sumber dan petunjuk pembaruan: [docs/LEAVE_CALENDAR.md](docs/LEAVE_CALENDAR.md).

Setiap 1 Januari, hak tahun baru dimulai dari 12 hari tanpa membawa sisa atau pemakaian tahun lalu. Halaman saldo mengikuti tahun baru saat tetap terbuka maupun ketika kembali dari latar belakang; tahun riwayat yang dipilih secara sengaja tetap dapat dilihat. Cuti awal dan surat tahun lalu tetap tersimpan. Jika sudah ada surat untuk tahun baru, surat itu tetap mengurangi hak tahun baru. Tidak ada penghapusan/reset tabel database.

Surat tersimpan langsung memakai saldo, termasuk cuti yang akan datang. Mengubah surat menghitung ulang selisihnya; menghapus surat mengembalikan jatah. Membuka, mencetak, atau membagikan PDF tidak mengurangi lagi. Aplikasi mencatat permohonan; ruang tanda tangan tetap kosong untuk proses persetujuan.

Kolom **Cuti yang sudah diambil** di PDF mencakup cuti awal dan hari cuti pada surat lain sebelum tanggal mulai surat tersebut. Pengajuan pada surat itu sendiri ditampilkan terpisah pada **Lama Cuti**. **Sisa Cuti = 12 − Cuti yang sudah diambil − Lama Cuti**, sehingga ketiga kolom selalu berjumlah 12. Contoh: lama cuti 3 hari, sudah diambil 3 hari, sisa 6 hari. Surat untuk tanggal sesudahnya tidak dimasukkan ke pemakaian sebelumnya. Saldo utama mencakup semua surat tersimpan di tahun itu, sehingga dapat berbeda jika sudah ada surat untuk tanggal berikutnya. Pembetulan catatan/kuota awal ikut dihitung saat PDF dicetak ulang; PDF yang sudah dibagikan perlu dibuat ulang.

Data cuti, kuota awal per tahun, dan isian surat disimpan di SQLite versi 3. Migrasi versi 3 menambahkan kolom dasar upah yang boleh kosong pada tabel lembur; catatan dan saldo cuti tetap dipertahankan. Nama dan jabatan pada surat tersimpan sebagai snapshot; perubahan profil tidak mengubah surat lama kecuali surat itu diedit dan disimpan lagi.

Contoh keluaran dengan data demonstrasi: `output/pdf/contoh-surat-cuti.pdf`.

## Format Nomor SPKL

```text
No.SPKL -          / PPNLK0101 / 2026-S8
No.          /SPKL/PTC/2026
```

Tahun `2026` pada contoh di atas diambil otomatis dari tanggal lembur setiap halaman.

## Aturan Konversi

### Hari kerja biasa

- Jam pertama: `1,5 ×`.
- Jam kedua dan seterusnya: `2 ×`.

### Hari istirahat mingguan/libur resmi

- Jam ke-1 sampai ke-8: `2 ×`.
- Jam ke-9: `3 ×`.
- Jam ke-10 sampai ke-12: `4 ×` untuk estimasi upah. Durasi hari libur di atas 12 jam tidak diberi estimasi; periksa catatan waktunya. Konversi jam pada dokumen lama tetap dipertahankan.

## Package dan data aplikasi

Package `com.niam.ayani.kerjakuptc` membuat Android memasang KerjaKu PTC sebagai aplikasi terpisah dari package sebelumnya `niam.ayani.kerjakuptc` maupun `com.cahpondokan.lembur`. Data lokal aplikasi lama tidak otomatis berpindah. Perubahan ini tidak menghapus aplikasi atau data lama. Nama package Dart tetap `lembur` untuk mempertahankan struktur import proyek.

Kode sebelum perubahan tersimpan di `../_lembur_backups/before_kerjakuptc_20261022`.

## Instalasi lama (V9)

Installer V9 merupakan alur instalasi versi lama. Untuk versi KerjaKu PTC, gunakan langkah build manual di bawah. Backup versi lama berada di folder saudara project:

```text
D:\Flutter\Project\_lembur_backups
```

## Menjalankan Manual

```powershell
flutter clean
flutter pub get
dart run flutter_launcher_icons
powershell -ExecutionPolicy Bypass -File tools/finalize_launcher_icons.ps1
dart format lib test
flutter analyze
flutter test
flutter build apk --release
flutter run
```

## Referensi Output PDF

Resource ikon dan cara regenerasi: lihat `docs/ICON_RESOURCES.md`. APK terbaru berada di `build/app/outputs/flutter-apk/app-release.apk` setelah build release.

Lihat:

- `docs/PDF_OUTPUT_REFERENCE.pdf`
- `docs/PDF_OUTPUT_REFERENCE.png`
