# Estimasi upah lembur — 1.7.0

Fitur memakai gaji bulanan dengan pola lima hari kerja dan 40 jam seminggu. Nilai adalah estimasi bruto sebelum pajak/potongan. Perhitungan perusahaan yang berbeda atau lebih baik perlu dicocokkan dengan ketentuan perusahaan.

Dasar hukum diperiksa 29 Oktober 2026: [PP 35 Tahun 2021, Pasal 31–34](https://www.peraturan.go.id/files/pp35-2021bt.pdf), terutama Pasal 31 ayat (1)/(3) dan Pasal 32.

## Dasar upah

- Gaji pokok + tunjangan tetap menjadi dasar bulanan.
- Jika jumlah itu lebih kecil dari 75% total gaji pokok + tunjangan tetap + tunjangan tidak tetap, gunakan 75% total tersebut.
- Upah per jam = dasar bulanan / 173.
- Hari biasa: satu jam pertama × 1,5; berikutnya × 2.
- Hari istirahat/libur resmi untuk pola lima hari: jam 1–8 × 2, jam 9 × 3, jam 10–12 × 4.
- Jenis hari dipilih pengguna sesuai jadwal; kalender cuti tidak otomatis menentukan jenis hari lembur. Enam hari kerja, kerja bergilir dengan pola lain, serta gaji harian/satuan hasil belum dicakup fitur ini.

Contoh dasar Rp5.190.000 menghasilkan upah per jam Rp30.000. Tiga jam lembur biasa memiliki 5,5 jam konversi dan estimasi Rp165.000; delapan jam pada hari libur menghasilkan Rp480.000.

Waktu dihitung dengan presisi menit, termasuk pecahan jam. Dasar hasil 75% disimpan dalam sen agar pecahan rupiah tidak hilang. Upah per jam tidak dibulatkan untuk perhitungan; hanya hasil akhir setiap catatan dibulatkan ke rupiah terdekat (setengah ke atas). Total bulanan menjumlahkan hasil akhir setiap catatan.

Setiap catatan dihitung sebagai satu sesi lembur sesuai jam konversinya. Beberapa sesi terpisah pada hari yang sama belum digabung otomatis untuk menghitung tingkat pengali harian. Waktu istirahat berbayar/tidak berbayar dan potongan pajak tidak diperkirakan aplikasi. Formulir mengingatkan jika hari biasa lebih dari empat jam; nominal tetap dihitung dari waktu yang dimasukkan. Hari libur di atas 12 jam ditandai belum dihitung agar tidak mengekstrapolasi tarif upah.

## Penyimpanan dan riwayat

- Tiga komponen gaji disimpan dalam satu nilai JSON SharedPreferences `overtime_salary_v1`. Preferensi mata disimpan dalam `hide_overtime_pay`.
- SQLite v3 menambahkan `monthly_wage_basis_cents INTEGER NULL` pada `overtime_entries`. Data lama tetap NULL, sehingga tidak menggunakan gaji baru secara diam-diam.
- Catatan baru mengambil dasar gaji profil saat disimpan. Mengubah gaji profil tidak menghitung ulang catatan lama.
- Edit catatan lama mempertahankan dasarnya. Tombol **Gunakan gaji profil** atau **Atur dasar upah catatan** mengubahnya hanya setelah **Simpan Lembur**.
- Jika sebagian catatan belum dapat dihitung, ringkasan bernama **Subtotal upah lembur** dan mencantumkan jumlah yang belum dihitung. Jika semuanya belum dihitung, nominal menjadi **Belum dihitung**. Kegagalan pemuatan tidak ditampilkan sebagai saldo nol.
- Gaji dan estimasi tersimpan lokal. Format dokumen resmi PDF/Excel dan aturan kesiapan profil/penandatangan tetap berlaku.

## Verifikasi

`test/overtime_pay_test.dart` menguji dasar 75%, tarif, pecahan menit, pembulatan akhir, validasi input, serialisasi, riwayat, dan persistensi preferensi. `test/overtime_pay_widget_test.dart` menguji alur isi gaji, penyimpanan lembur baru/lama, koreksi dasar, subtotal, privasi, navigasi, dan geometri dua kartu pada beragam lebar/skala teks.

`python tools/verify_overtime_migration.py` menjalankan SQL produksi pada SQLite sementara untuk versi 1 → 3, 2 → 3, dan pembuatan baru. Pemeriksaan memastikan data lembur/cuti/saldo lama tetap utuh, kolom lama bernilai NULL, dan dasar upah baru tetap ada setelah buka ulang database.
