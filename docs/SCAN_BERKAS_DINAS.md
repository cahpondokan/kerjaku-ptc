# Scan dan bagikan berkas dinas

Fitur KerjaKu PTC 1.10.0+21. Masuk melalui **Surat Dinas → pilih surat tersimpan → Kelola berkas dinas**. Formulir tempat/tanggal surat dan penandatangan tetap mengikuti versi 1.9.0.

## Pemakaian

1. Pilih **SPPD**, **SPD**, **Deklarasi**, atau **Invoice** sebelum membuka pemindai. Untuk SPPD, gunakan hasil scan cetakan yang telah ditandatangani.
2. Tekan **Scan**. Pemindai mendeteksi tepi dan meluruskan perspektif. Kamera atau galeri dapat digunakan, hingga 10 halaman dalam satu sesi penambahan. Sesi berikutnya dapat menambahkan halaman lagi.
3. Periksa setiap halaman dengan menggeser pratinjau. Gunakan **Ubah potongan**, **Scan ulang**, atau perbesar gambar untuk memeriksa keterbacaan. Simpan ke jenis dokumen yang dipilih.
4. Pada daftar halaman, **Potong**, **Ganti**, dan **Hapus** berlaku hanya untuk halaman tersebut. Geser pegangan untuk mengurutkan halaman dalam jenis yang sama. Penggantian baru disimpan setelah tombol simpan ditekan; pembatalan mempertahankan halaman sebelumnya.
5. Tekan **Bagikan via WhatsApp**. Minimal **satu halaman dari jenis mana pun** sudah cukup. SPPD dan SPD saja juga dapat dikirim; Deklarasi/Invoice dapat ditambahkan kemudian.
6. Aplikasi membangun PDF baru dari halaman tersimpan terbaru dengan urutan **SPPD → SPD → Deklarasi → Invoice**. Jenis kosong dilewati tanpa halaman kosong. Pilih sendiri kontak atau grup di WhatsApp, lalu tekan kirim di sana.

Nomor admin dari Profil tidak digunakan untuk paket dinas. Membuka WhatsApp tidak diberi status “terkirim”. Berbagi tidak menghapus atau menggabungkan permanen scan sumber; paket dapat diperbaiki dan dibagikan ulang.

## Pemindai dan PDF

- Kamera, deteksi tepi, potong otomatis, dan koreksi awal menggunakan UI pemindai Android Google ML Kit. Tampilan kamera mengikuti komponen tersebut; gambar desain adalah acuan alur.
- Dependensi stabil `play-services-mlkit-document-scanner:16.0.0` memerlukan `minSdk 23` menurut manifest AAR yang digunakan pada build. APK mendukung Android 6.0 atau lebih baru, dengan Google Play services dan persyaratan perangkat ML Kit.
- Pemakaian pertama membutuhkan internet untuk menyiapkan komponen pemindai. Setelah komponen tersedia, pemindaian dan penyimpanan dilakukan di perangkat. Pengiriman melalui WhatsApp menggunakan koneksi internet.
- Mode BASE mempertahankan isi dokumen tanpa fitur penghapusan noda/objek. Potong ulang memakai empat sudut dan koreksi perspektif, dengan putaran kelipatan 90°. Sumber sebelum potong manual tetap disimpan. Sumber ini adalah JPEG hasil pemindai, bukan foto kamera sebelum pemotongan otomatis pertama.
- Setiap gambar menghasilkan satu halaman PDF, mempertahankan rasio dan orientasi. Dokumen biasa memakai ukuran dasar A4; struk panjang mendapat tinggi halaman tambahan agar seluruh isi tetap terbaca dan tidak dipotong.
- Maksimal 20 MiB per gambar. PDF sementara dibuat pada folder unik setiap kali dibagikan, agar kiriman sebelumnya tidak tertimpa.

Rujukan pemindai: [dokumentasi resmi ML Kit](https://developers.google.com/ml-kit/vision/doc-scanner/android).

## Penyimpanan dan pembaruan

- Identitas paket Android tetap `com.niam.ayani.kerjakuptc`, database tetap `lembur_ptc.db`. Pembaruan menambahkan tabel `duty_scan_pages` (skema 5); tabel lembur, cuti, saldo, dan nilai upah tidak dihapus atau dihitung ulang.
- Halaman disimpan sebagai gambar terpisah dalam transaksi SQLite, dengan ID, jenis, urutan, dan waktu perubahan. Pembacaan BLOB memakai potongan 256 KiB agar gambar besar tidak melampaui kapasitas baris CursorWindow Android.
- Mengedit surat menggunakan UPDATE, sehingga tidak menghapus scan melalui relasi parent. Menghapus surat meminta konfirmasi dan menghapus scan milik surat tersebut.
- Ekspor JSON versi 3 mencakup seluruh gambar dan sumber potongan dalam base64. Impor cadangan lama versi 1/2 tetap diterima. Scan yang tidak tercakup oleh format lama, beserta surat induknya yang diperlukan, tetap dipertahankan.
- Pasang APK sebagai **pembaruan** di atas versi lama, tanpa uninstall. Tidak ada pemasangan atau perubahan data HP oleh proses pengembangan fitur ini.

## Verifikasi

Tes SQLite nyata mencakup paket parsial, urutan, penggantian satu halaman, pembatalan, kegagalan penyimpanan, edit surat tanpa kehilangan scan, pengurutan, backup/pemulihan, cadangan lama, gambar lebih dari 3 MiB, dan invoice panjang. Tes widget memeriksa layar 320 dp dengan teks diperbesar, penyimpanan/pembatalan, dialog bagikan, serta argumen WhatsApp tanpa penerima otomatis.

Pemindaian kamera, potongan native pada perangkat, dan pengiriman WhatsApp nyata masih perlu diuji pengguna di HP. Tes tidak memasang APK atau mengakses data perangkat pengguna.
