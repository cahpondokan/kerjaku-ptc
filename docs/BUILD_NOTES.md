# Catatan Build KerjaKu PTC 1.8.0+16

- Fitur ekspor/impor cadangan JSON mencakup lembur, cuti, saldo awal cuti, profil, gaji, dan pengaturan.
- Build release berhasil: `output/apk/KerjaKu-PTC-1.8.0.apk` (29.219.978 byte).
- Metadata APK: label `KerjaKu PTC`, package `com.niam.ayani.kerjakuptc`, versi `1.8.0`, kode `16`.
- Sertifikat APK cocok dengan KerjaKu PTC `1.7.0`: SHA-256 `610d957cdfb4ccb4b12535c8e8f3349fe57388e7a16c9baaa744cf042ec14ab9`.
- SHA-256 APK: `D4B4A35C61CB0B8CE3C2371A47905628E050E08E3455B85387FB594309D5F687`.
- Instal sebagai pembaruan langsung tanpa menghapus aplikasi. Database tetap memakai `lembur_ptc.db`; jangan pilih **Uninstall** jika installer menyatakan aplikasi tidak kompatibel atau tanda tangan berbeda.

# Catatan Verifikasi KerjaKu PTC 1.7.0+15

- Gaji bulanan ditambahkan pada Profil dalam tiga komponen: pokok, tunjangan tetap, dan tidak tetap. Dasar upah otomatis memakai gaji pokok + tunjangan tetap atau ketentuan 75% jika berlaku.
- Estimasi bruto pada formulir/riwayat lembur serta jumlah bulanan di Beranda/Riwayat/Rekap. Dasar upah disimpan per catatan; perubahan gaji profil tidak mengubah riwayat. Catatan lama belum dihitung hingga dasar upahnya dilengkapi lewat Edit.
- Tombol mata menyembunyikan nominal di ringkasan/riwayat/kartu Profil, dengan preferensi yang tersimpan. Nominal masih terlihat ketika sengaja membuka formulir pengeditan.
- Dua pilihan layanan tetap dalam satu baris. Tes geometri dan navigasi mencakup lebar 320–390 dp, skala teks 0,85–2, termasuk konfigurasi HP terhubung (720 px, density 320 dpi = 360 dp, font 0,85).
- `flutter analyze --no-pub`: tidak ada masalah. `flutter test --no-pub --reporter expanded`: seluruh **80 tes lulus**, termasuk 21 tes baru dan seluruh regresi profil, dokumen, serta cuti.
- `tools/verify_overtime_migration.py`: SQL produksi diuji pada SQLite nyata untuk v1 → v3, v2 → v3, dan pembuatan v3 baru. Data lembur/cuti/saldo terpelihara; kolom `monthly_wage_basis_cents` pada data lama NULL; nilai baru tetap tersimpan setelah database dibuka ulang.
- Paket tetap `com.niam.ayani.kerjakuptc`; ikon, template SPKL/Excel/surat cuti, serta aturan pengingat profil/penandatangan tetap digunakan. Estimasi upah hanya ditambahkan ke tampilan aplikasi.
- Aturan, contoh, pembulatan, cakupan lima hari kerja, dan referensi resmi PP 35/2021: [OVERTIME_PAY.md](OVERTIME_PAY.md).
- Backup kode dan APK sebelumnya: `../_lembur_backups/before_overtime_pay_20261029`.
- `flutter build apk --release --no-pub`: berhasil (Gradle 271,3 detik). APK 29.185.955 byte, label KerjaKu PTC, package `com.niam.ayani.kerjakuptc`, versi 1.7.0/kode 15. Sertifikat sama dengan APK 1.6.1.
- APK arsip: `output/apk/KerjaKu-PTC-1.7.0.apk`. SHA-256: `4f7b5a0dcc6e1d2ba283e2d77604a0e7d082532fcffef2b588b7d7d3e8694434`. Log pemeriksaan akhir: `output/verification/1.7.0/verification-*.log`.
- Dipasang ke HP model `25028RN03A` melalui `adb install -r`: **Success**. Android mengonfirmasi versi 1.7.0/kode 15; waktu pemasangan pertama tetap 22 Oktober 2026 15:53:01. Aplikasi berhasil dibuka (`Status: ok`, cold launch 1.065 ms) dan proses tetap aktif. Tidak dilakukan uninstall atau penghapusan data.

## Arsip verifikasi 1.6.1+14

- Kolom PDF **Cuti yang sudah diambil** kini hanya memuat cuti awal dan pemakaian pada surat lain sebelum tanggal mulai surat ini. Pengajuan saat ini tidak dihitung lagi pada kolom tersebut.
- Rumus PDF: **Lama Cuti + Cuti yang sudah diambil + Sisa Cuti = 12**. Contoh pengguna diverifikasi dari PDF produksi: **3 + 3 + 6 = 12**. Contoh libur panjang juga diverifikasi: **2 + 4 + 6 = 12**.
- Perhitungan mencakup surat terdahulu menurut tanggal cuti, termasuk rentang yang berbagi hari libur/akhir pekan. Pengajuan masa depan dan surat yang sedang diedit dikecualikan dari pemakaian sebelumnya.
- `flutter analyze --no-pub`: tidak ada masalah. `flutter test --no-pub --dart-define=GENERATE_LEAVE_SAMPLE=true`: seluruh 59 tes lulus, termasuk pemakaian nol, kuota tepat habis, koreksi/hapus surat, buka ulang, pergantian tahun, libur, dan fitur lembur.
- Ketiga PDF contoh diperiksa melalui ekstraksi teks: satu halaman A4 mendatar, tiga angka berjumlah 12. Contoh 3/3/6 dirender dengan Poppler dan diperiksa secara visual: `output/pdf/contoh-surat-cuti-saldo-benar.pdf`.
- Data dan schema database tetap sama. PDF yang telah dibagikan sebelumnya perlu dibuat ulang dari surat tersimpan.
- Backup kode dan APK sebelumnya: `../_lembur_backups/before_pdf_balance_fix_20261023`.
- `flutter build apk --release --no-pub`: berhasil. APK 29.082.779 byte, package `com.niam.ayani.kerjakuptc`, versi `1.6.1`, kode `14`; sertifikat penandatanganan sama dengan versi 1.6.0.
- Dipasang sebagai pembaruan melalui `adb install -r` ke HP yang terhubung (model `25028RN03A`): `Success`. Versi pada perangkat terverifikasi `1.6.1` / kode `14`; aplikasi berhasil diluncurkan (`Status: ok`, cold launch 1152 ms) dan prosesnya aktif. Tidak dilakukan uninstall atau penghapusan data.

## Arsip verifikasi 1.6.0+13

- Perhitungan hari cuti dan tanggal masuk kembali melewati Sabtu, Minggu, libur nasional, serta cuti bersama. Kalender offline 2025–2027 beserta sumber dicatat di `LEAVE_CALENDAR.md`.
- Cuti sebelum aplikasi dapat diisi dari halaman saldo atau formulir surat. Angka tersimpan per tahun, termasuk angka nol, dan langsung tampil kembali; koreksi mengganti angka sebelumnya.
- Halaman saldo mengikuti pergantian tahun saat tetap terbuka atau kembali dari latar belakang. Hak tahun baru 12 hari, riwayat lama dipertahankan, dan surat yang sudah dipesan untuk tahun baru tetap diperhitungkan.
- `flutter analyze --no-pub`: tidak ada masalah. Folder `output/` dikecualikan dari analisis karena memuat paket resource hasil ekspor dengan salinan pubspec, bukan kode aplikasi.
- `flutter test --no-pub`: seluruh 56 tes lulus. Tes mencakup libur panjang, cuti bersama, rollover aktif/resume, isian otomatis setelah buka ulang, saldo, PDF, layar sempit, serta regresi lembur/profil.
- PDF produksi diperiksa melalui ekstraksi teks dan render Poppler: satu halaman A4 mendatar; cuti 23–28 Desember 2026 = 2 hari, masuk 29 Desember, pemakaian kumulatif 6 dan sisa 6 dengan cuti sebelumnya 4 hari. Contoh: `output/pdf/contoh-surat-cuti-libur.pdf`.
- Database tetap versi 2. Tidak ada perubahan schema atau penghapusan data. Ikon dan package tetap sama.
- Backup kode dan APK sebelumnya: `../_lembur_backups/before_holiday_20261022`.
- Build release berhasil: `build/app/outputs/flutter-apk/app-release.apk`, 29.081.296 byte. Metadata APK: label `KerjaKu PTC`, package `com.niam.ayani.kerjakuptc`, versi `1.6.0`, kode `13`. Sertifikat penandatanganan identik dengan versi 1.5.1.
- Pembaruan dipasang melalui `adb install -r` pada HP model `25028RN03A`: `Success`. Perangkat mengonfirmasi versi `1.6.0` / kode `13`; waktu pemasangan pertama tetap sama. Peluncuran `MainActivity` berhasil (`Status: ok`, cold launch 614 ms) dan proses aplikasi aktif. Tidak dilakukan uninstall atau penghapusan data.

## Arsip verifikasi 1.5.1+12

- Ikon baru diterapkan pada launcher normal, launcher bulat, adaptive icon, dan beranda.
- `flutter analyze --no-pub`: tidak ada masalah.
- `flutter test --no-pub`: seluruh 45 tes lulus setelah perubahan ikon.
- `flutter build apk --release --no-pub`: berhasil. APK terbaru: `build/app/outputs/flutter-apk/app-release.apk` (29.047.468 byte, sekitar 27,7 MiB).
- Metadata APK: package `com.niam.ayani.kerjakuptc`, versi `1.5.1`, kode `12`, label `KerjaKu PTC`.
- Sertifikat penandatanganan sama dengan APK sebelumnya. Konfigurasi release proyek saat ini memakai signing debug yang sama untuk pemasangan lokal.
- Kedua aset PNG utama di APK identik dengan sumber. Kelima belas PNG native (normal, bulat, dan foreground pada lima kepadatan) cocok pikselnya dengan resource proyek. Referensi adaptive XML normal/bulat dan background gradasi ikut diverifikasi melalui resource table APK yang telah dioptimalkan.
- Tampilan ikon dari APK dan pratinjau masker bulat/persegi membulat diperiksa secara visual. Belum diuji pada launcher perangkat Android fisik.
- Resource lengkap: `output/icons/KerjaKu-PTC-Icon-Resources-1.5.1.zip`. Instruksi regenerasi dan prompt gambar tersedia di `docs/ICON_RESOURCES.md`.

## Arsip verifikasi 1.5.0+11

- Nama aplikasi: `KerjaKu PTC`.
- Application ID dan namespace: `com.niam.ayani.kerjakuptc`.
- Flutter 3.29.3 / Dart 3.7.2.
- `flutter analyze --no-pub`: tidak ada masalah.
- `flutter test --no-pub --dart-define=GENERATE_LEAVE_SAMPLE=true`: 45 tes lulus, termasuk perhitungan hari kerja, kuota tahunan, benturan tanggal, ubah/hapus, kegagalan penyimpanan, isian otomatis, perubahan tanggal lewat UI, cetak ulang tanpa pemotongan tambahan, penguncian surat, dan seluruh tes lembur/profil sebelumnya.
- `flutter build apk --debug --no-pub`: berhasil. APK uji tersedia di `build/app/outputs/flutter-apk/app-debug.apk`.
- PDF dari generator produksi diperiksa melalui ekstraksi teks dan render Poppler: satu halaman A4 mendatar, cuti 23–26 Oktober 2026 = 2 hari, masuk 27 Oktober, pemakaian kumulatif 6 hari dan sisa 6 hari dengan cuti awal 4 hari. Contoh: `output/pdf/contoh-surat-cuti.pdf`.
- SQL migrasi SQLite versi 1 ke 2 diverifikasi menggunakan database sementara: data lembur utuh, tabel cuti/default/kuota dapat diisi, dan batas kuota awal diterapkan.
- `aapt dump badging` mengonfirmasi `com.niam.ayani.kerjakuptc`, versi `1.5.0`, kode `11`, label `KerjaKu PTC`, serta launcher `com.niam.ayani.kerjakuptc.MainActivity`. Manifest APK menggunakan authority `com.niam.ayani.kerjakuptc.fileprovider`. Logo surat cuti disertakan dalam APK.
- Setelah perubahan package, `flutter analyze --no-pub` dan build APK debug diulang dan berhasil. Nama channel WhatsApp Dart/Kotlin diperbarui bersama.
- Pemeriksaan tampilan meliputi widget pada lebar 320 dengan skala teks 1,5. Belum dilakukan pemasangan atau uji cetak pada perangkat Android fisik.
- Package baru terpasang terpisah dari `niam.ayani.kerjakuptc` dan aplikasi Lembur lama; data lokal lama tidak otomatis bermigrasi.

Kode sebelum fitur cuti disimpan di `../_lembur_backups/before_cuti_20261022`.

## Arsip catatan versi V9

Paket disiapkan untuk:

- Package: `com.cahpondokan.lembur`
- Dart SDK: `3.7.2` atau `>=3.7.0 <4.0.0`
- Android NDK: `27.0.12077973`

## Pemeriksaan Struktur Paket

- Aset logo Pertamina dan PTC tersedia serta tercantum di `pubspec.yaml`.
- Format nomor SPKL dipisahkan dalam utilitas yang memiliki unit test.
- Nama dan jabatan pejabat PTC disimpan dengan `SharedPreferences`.
- Controller dialog pejabat PTC dimiliki oleh `StatefulWidget` dan di-dispose dengan aman.
- Tidak ada folder backup di dalam root source paket.
- Installer memformat hanya folder `lib` dan `test`.
- Package dan application ID tetap `com.cahpondokan.lembur`.

## Verifikasi di Komputer Pengguna

Installer otomatis menjalankan:

```powershell
flutter clean
flutter pub get
dart run flutter_launcher_icons
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```
