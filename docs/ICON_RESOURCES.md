# Resource ikon KerjaKu PTC 1.5.1

Ikon mengikuti rekomendasi yang disetujui: dokumen putih, centang biru, dan jam, dengan latar gradasi biru. Nama aplikasi ditampilkan oleh launcher, bukan ditulis di dalam gambar ikon.

## Berkas

- `assets/icons/app_icon.png`: PNG utama 1254 × 1254 dengan alpha, dipakai untuk launcher lama dan logo beranda.
- `assets/icons/app_icon_foreground.png`: PNG foreground 1254 × 1254 dengan alpha, untuk adaptive icon.
- `android/app/src/main/res/mipmap-*/ic_launcher.png`: ukuran 48, 72, 96, 144, dan 192 piksel.
- `android/app/src/main/res/mipmap-*/ic_launcher_round.png`: ikon bulat pada lima kepadatan yang sama.
- `android/app/src/main/res/drawable-*/ic_launcher_foreground.png`: foreground 108, 162, 216, 324, dan 432 piksel.
- `android/app/src/main/res/drawable/ic_launcher_gradient.xml`: gradasi biru native Android.
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` dan `ic_launcher_round.xml`: adaptive icon dengan inset 20%.
- `docs/icon-design/approved-design.png`: referensi desain yang disetujui.
- `output/icons/preview-adaptive-round.png` dan `preview-adaptive-rounded.png`: pratinjau masker Android, diperiksa secara visual.

## Regenerasi

Jalankan dari folder project:

```powershell
dart run flutter_launcher_icons
powershell -ExecutionPolicy Bypass -File tools/finalize_launcher_icons.ps1
```

Langkah kedua menerapkan gradasi native, memperbarui ikon bulat lama, dan menyamakan XML normal/bulat. Jangan hanya menjalankan generator pertama karena generator tersebut tidak memperbarui PNG bulat dan akan mengembalikan background adaptive menjadi warna polos.

Package tetap `com.niam.ayani.kerjakuptc`; versi dinaikkan menjadi `1.5.1+12`. Backup ikon lama berada di `../_lembur_backups/before_icon_151_20261022`.

## Mode dan prompt sumber

Mode: built-in `image_gen` dengan gambar yang disetujui sebagai edit target; bukan CLI/API fallback. PNG hasilnya disalin ke project. `flutter_launcher_icons` menghasilkan ukuran Android; script PowerShell hanya mengemas lapisan dan masker launcher.

### PNG utama

Use case: background-extraction. Input image 1 is the approved KerjaKu PTC icon design and is the edit target. Extract only the blue rounded-square app-icon tile from the upper part of this image as a standalone production launcher icon. Remove ALL surrounding pale presentation background and ALL text below the icon. Use a genuinely transparent alpha background outside the blue tile. Preserve the exact approved design within the tile: vivid royal-blue gradient, white folded document, blue checkmark, two pale-blue text bars, overlapping blue-rim clock with white face and navy hands pointing to 12 and 4, the same soft dimensional shading and relative positions. Do not redesign, add new elements, change the clock, or change proportions. Center the tile on a square 1024x1024 canvas, nearly filling the canvas with only a minimal 3% transparent margin, no extra drop shadow outside the tile. Crisp clean edges. No lettering anywhere, no checkerboard baked into pixels, no mockup.

### Foreground transparan

Use case: background-extraction. Input image 1 is the approved KerjaKu PTC icon and is the edit target. Produce only its FOREGROUND emblem as a transparent PNG for an Android adaptive launcher icon. Extract the entire white folded-corner document with blue checkmark and the two pale-blue bars, together with the overlapping blue-rimmed white-face clock and navy clock hands. Keep these elements together as ONE exact emblem. Preserve their shapes, proportions, colors, clean edges, and subtle original shading. Clock hands must point to 12 and 4, as in the original. Remove the blue rounded-square tile completely, remove all pale surrounding presentation background and all lettering. The outside of the document and clock must be truly transparent alpha; no colored tile, no background square, no cast shadow extending outside the emblem, no blue color remnants, no detached specks. Center the emblem on a square canvas, with the emblem filling about 80% of width and height and clear transparent padding on all sides. Do not redesign the approved icon, do not add text or objects. Clean production-ready alpha edges, no white or checkerboard background baked into the image.

