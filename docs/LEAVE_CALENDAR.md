# Kalender cuti KerjaKu PTC

Versi 1.6.1+14. Data kalender diperiksa 22 Oktober 2026. Sesuai pilihan pengguna, Sabtu, Minggu, libur nasional **dan cuti bersama** semuanya dilewati. Ini adalah kebijakan perhitungan aplikasi yang diminta pengguna.

## Sumber resmi

| Tahun | Libur nasional | Cuti bersama | Sumber |
| --- | --- | --- | --- |
| 2025 | 17 | 11 setelah perubahan | [Pengumuman Kemenko PMK 2025](https://www2.kemenkopmk.go.id/pemerintah-tetapkan-hari-libur-nasional-dan-cuti-bersama-tahun-2025), [tambahan 18 Agustus 2025](https://www.kemenkopmk.go.id/pemerintah-tetapkan-cuti-bersama-18-agustus-2025-untuk-peringatan-hut-ke-80-ri) |
| 2026 | 17 | 8 | [Pengumuman Kemenko PMK 2026](https://kemenkopmk.go.id/pemerintah-tetapkan-17-hari-libur-nasional-dan-8-hari-cuti-bersama-tahun-2026) |
| 2027 | 18 | 8 | [Pengumuman Kemenko PMK 2027](https://www2.kemenkopmk.go.id/pemerintah-tetapkan-18-hari-libur-nasional-dan-8-cuti-bersama-tahun-2027) |

Tahun 2027 memiliki dua tanggal Isra Mikraj (5 Januari dan 26 Desember). Hari raya yang jatuh pada akhir pekan tidak dikurangi dua kali. Libur lokal/perusahaan di luar daftar SKB belum tercakup.

## Perilaku aplikasi

- Data disertakan di `lib/features/leave/domain/leave_holidays.dart` agar dapat bekerja tanpa internet.
- `LeaveCalculator` dipakai bersama oleh formulir, saldo/riwayat, benturan tanggal, dan PDF. Tanggal masuk kembali juga melewati hari libur.
- Contoh: 23–28 Desember 2026 = 2 hari cuti (23 dan 28), masuk kembali 29 Desember. Dengan cuti sebelumnya 4 hari, kolom PDF menjadi Lama Cuti 2, Cuti yang sudah diambil 4, Sisa Cuti 6. Ketiganya berjumlah 12.
- Contoh pergantian tahun: selesai 31 Desember 2026, masuk 4 Januari 2027. Hak tahun 2027 sendiri 12 hari, dikurangi hanya catatan tahun 2027.
- Cuti sebelum aplikasi disimpan sebagai jumlah hari bersih per tahun di `leave_year_balances`. Nilai 0 juga dianggap sudah diisi dan akan tampil lagi. Mengubah jumlah menggantikan nilai lama, bukan menambahkannya.
- Surat lama tetap tersimpan; hitungan dan cetak ulang menggunakan kalender yang diperbarui. Tidak ada perubahan tabel atau migrasi baru dari database versi 2.
- Tahun di luar cakupan tidak boleh menghasilkan surat/PDF dengan hitungan seolah-olah hanya akhir pekan yang libur. UI menampilkan permintaan pembaruan kalender. Ini juga berlaku jika tanggal masuk kembali mencapai tahun yang belum tersedia.

## Pemeliharaan kalender

Saat SKB tahun berikutnya atau perubahan SKB diterbitkan, verifikasi sumber resmi, tambahkan/ubah tanggal serta labelnya, lalu sesuaikan `firstYear`/`lastYear` hanya setelah data lengkap. Perbarui label cakupan UI, tabel sumber ini, dan tes total kalender. Jalankan tes rentang libur, tanggal masuk, saldo, formulir, PDF, dan rollover tahun sebelum merilis APK. Aplikasi offline tidak mengunduh perubahan kalender secara otomatis.

## Verifikasi

Tes mencakup libur panjang Nyepi/Idul Fitri 2025–2027, tambahan Agustus 2025, Natal/cuti bersama, akhir pekan yang berimpit hari raya, tahun tanpa kalender, cetak ulang, penyimpanan cuti awal termasuk nol, serta 1 Januari saat halaman aktif dan sesudah kembali dari latar belakang. Pemesanan cuti tahun berikutnya tetap dipertahankan saat rollover.
