# Panduan Instalasi Lembur PTC V9

## Cara termudah

1. Hentikan `flutter run` dengan menekan `q`.
2. Ekstrak ZIP ini.
3. Jalankan `INSTALL_NOW.bat`.
4. Target default adalah `D:\Flutter\Project\lembur`.
5. Installer membuat backup di `D:\Flutter\Project\_lembur_backups`.
6. Installer menjalankan clean, pub get, launcher icon, format, analyze, test, dan build APK debug.

## Menentukan target lain

```powershell
install_to_project.bat "D:\Folder\Project\lembur"
```

## Sesudah instalasi

```powershell
cd D:\Flutter\Project\lembur
flutter run
```

## Pengaturan baru

Buka `Pengaturan > Pejabat PTC` untuk mengubah:

- Nama pejabat PTC, default `Ricky Roy Sagita`.
- Jabatan pejabat PTC, default `Manager Manpower Supply - PTC`.

## Output PDF

- Logo Pertamina Patra Niaga tampil pada surat bagian atas.
- Logo PTC tampil pada surat bagian bawah.
- Satu baris lembur menjadi satu halaman PDF.
- Tahun nomor dokumen mengikuti tahun tanggal lembur.
- Nomor urut tetap kosong untuk diisi admin.

## Perubahan V9

- Memperbaiki overflow 21 piksel pada dropdown Jenis Hari.
- Menambahkan kolom Nomor Pekerja pada Excel.
- Memperbaiki judul dan periode rekap Excel.
- Mengubah kode dokumen menjadi `PPNLK0101`.
- Membiarkan bagian nomor urut kosong untuk diisi admin.
