# Melanjutkan pengembangan KerjaKu PTC

Repositori: https://github.com/cahpondokan/kerjaku-ptc. Cabang aktif `main`; tag `v1.10.0` menyimpan sumber versi 1.10.0+21. APK yang telah ditandatangani dan checksum tersedia sebagai aset rilis, terpisah dari sumber Git.

## Mengambil dan menjalankan proyek

```powershell
git clone https://github.com/cahpondokan/kerjaku-ptc.git
cd kerjaku-ptc
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Gunakan `git checkout v1.10.0` untuk mengambil sumber tepat pada rilis tersebut. Untuk melanjutkan pengembangan terbaru, tetap di cabang `main` dan jalankan `git pull --ff-only` sebelum mulai bekerja ketika working tree bersih.

Lingkungan build rilis 1.10.0 yang telah diverifikasi:

- Flutter 3.29.3, Dart 3.7.2; versi dependensi tercatat di `pubspec.lock`.
- Java 17, Android SDK compile/target 35, NDK 27.0.12077973.
- Android minimum 6.0/API 23; Google Play services diperlukan untuk pemindai dokumen ML Kit.
- Package Android tetap `com.niam.ayani.kerjakuptc`, nama package Dart `lembur`.
- Hasil build: `build/app/outputs/flutter-apk/app-release.apk`.

Android Studio dan Flutter membuat konfigurasi SDK lokal sesuai komputer. `android/local.properties`, cache build, berkas hasil ekspor, database, dan kunci signing tidak disimpan dalam repositori publik.

## Data dan pembaruan APK

Data kerja, gaji/kalibrasi, profil, cuti, dan scan berada pada HP, bukan pada repositori. Ekspor melalui **Profil → Data & Keamanan** bila perlu memindahkan data. Backup JSON bersifat pribadi dan disimpan terpisah dari GitHub publik. Memasang APK rilis sebagai pembaruan memakai package dan sertifikat yang sama mempertahankan data aplikasi; jangan uninstall aplikasi sebelumnya.

Rilis lokal saat ini memakai signing debug proyek yang sama dengan versi sebelumnya. **Pembuatan APK pada komputer baru biasanya menghasilkan debug keystore yang berbeda.** Untuk membuat pembaruan yang dapat dipasang di atas instalasi lama, simpan dan gunakan keystore asli secara privat; jangan mengunggahnya ke repositori atau aset rilis publik. Sertifikat rilis yang diharapkan (SHA-256):

```text
610d957cdfb4ccb4b12535c8e8f3349fe57388e7a16c9baaa744cf042ec14ab9
```

APK rilis 1.10.0 yang tersedia di GitHub telah diverifikasi memakai sertifikat tersebut. Perubahan contoh identitas dalam fixture tes untuk publikasi tidak mengubah kode produksi atau APK.

## Struktur yang perlu dilanjutkan

- `lib/features/duty/`: surat dinas, scan per dokumen, PDF, dan berbagi bertahap.
- `android/app/src/main/kotlin/com/niam/ayani/kerjakuptc/DutyScannerBridge.kt`: pemindai Android, koreksi perspektif, dan berbagi WhatsApp tanpa penerima otomatis.
- `lib/core/database/app_database.dart`: database schema 5 dan migrasi tambahan tanpa penghapusan data lama.
- `lib/features/settings/data/backup_restore_service.dart`: cadangan JSON versi 3, kompatibel dengan versi 1/2.
- `test/duty*_test.dart`: validasi surat, SQLite/backup scan, PDF, dan antarmuka.

Satu halaman dari jenis apa pun sudah dapat dibagikan. Urutan PDF tetap SPPD → SPD → Deklarasi → Invoice; kategori kosong dilewati. Formulir tempat/tanggal surat tetap seperti versi 1.9.0. Referensi terperinci: [SURAT_DINAS.md](SURAT_DINAS.md), [SCAN_BERKAS_DINAS.md](SCAN_BERKAS_DINAS.md), dan [BUILD_NOTES.md](BUILD_NOTES.md).

Tes otomatis telah lulus, tetapi kamera/crop native dan pengiriman WhatsApp nyata belum diuji pada HP pengguna dalam pekerjaan ini. Desain raster yang mengandung contoh dokumen pribadi tetap lokal; kode, aset aplikasi, spesifikasi teknis, dan tes yang diperlukan untuk melanjutkan proyek tersedia di repositori.
