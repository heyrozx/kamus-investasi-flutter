## 1.1.0 (12)

* Upgrade ke Flutter 3.47 / Dart 3.13 dan semua dependency ke versi terbaru (`google_mobile_ads` 9,
  `upgrader` 13, `google_fonts` 9, `share_plus` 13, `fluttertoast` 10)
* Migrasi import `package:flutter/material.dart` ke paket `material_ui`
* Upgrade toolchain Android: Gradle 9.3.1, Android Gradle Plugin 9.1.0, Kotlin 2.4.0
* Menghapus platform iOS, project sekarang khusus Android
* Menghapus package yang tidak dipakai: `infinite_scroll_pagination`, `cupertino_icons`,
  `change_app_package_name`
* Logo baru: background transparan dan huruf V bergradien biru
* Padding logo dan launcher icon disamakan dengan logo sebelumnya
* Launcher icon baru memakai logo terbaru, termasuk adaptive icon dan themed (monochrome) icon
* Menambahkan ikon Play Store 512x512 di `store/icon_512.png`
* Mengganti `getCurrentOrientationAnchoredAdaptiveBannerAdSize` (deprecated) dengan
  `getLargeAnchoredAdaptiveBannerAdSize`
* Data kamus sekarang dikirim sebagai database SQLite siap pakai (`assets/db/dictionary.db`),
  sehingga pembukaan pertama aplikasi tidak lagi mem-parsing JSON dan meng-insert 593 baris
* Data kamus dan data pengguna (bookmark, riwayat) dipisah ke file database berbeda; update data
  kamus tidak lagi menyentuh bookmark dan riwayat
* Migrasi database pengguna ke versi 2: tabel kamus lama dihapus, bookmark dan riwayat tetap utuh
* Menambahkan generator `tool/dictionary_db` dan VS Code task "Generate dictionary.db" untuk
  membuat ulang database dari `assets/datasets/dictionaries.json`
* Menambahkan index pada kolom `alphabet` dan `category`
* Menambah 425 istilah baru, total kamus sekarang 1.018 istilah
* Memperbaiki query SQL yang memakai kutip ganda untuk teks (`alphabet="A"`) menjadi parameter
  `?`; sebelumnya pencarian bisa error jika kata kunci mengandung tanda kutip, dan query gagal
  di versi SQLite yang tidak lagi menerima kutip ganda sebagai teks
* Menambahkan aset Play Console di folder `store/`: ikon 512, feature graphic 1024x500, dan
  7 screenshot ponsel dengan mockup realistis, termasuk highlight "1.000+" dan fitur offline

## 1.0.9 (11)

* Menaikkan target Android ke API level 36 (Android 16) sesuai persyaratan Google Play
* Upgrade toolchain Android: Gradle 8.14.3, Android Gradle Plugin 8.13.0, Kotlin 2.2.20
* Menghapus package `clipboard` (tidak terawat, masih compileSdk 33 sehingga build gagal) dan
  menggantinya dengan `Clipboard` bawaan Flutter
* Memperbaiki constraint Dart SDK di `pubspec.yaml` agar cocok dengan Flutter/Dart terpasang

## 1.0.8 (10)

* Memperbaiki issue admob: Modified ad code: Resizing Ad Frames

## 1.0.7 (9)

* Memperbaiki issue admob: Modified ad code: Resizing Ad Frames

## 1.0.6 (7)

* Menghapus interstitial ad di halaman detail dictionary

## 1.0.5 (6)

* Menghapus halaman feedback
* Upgrade dependency/package
* Improve banner placement