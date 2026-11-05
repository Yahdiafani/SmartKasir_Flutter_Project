# SmartKasir — Flutter

Aplikasi kasir sederhana untuk praktikum Mobile Programming Minggu 10.

## Fitur
- Splash screen dengan durasi 3 detik.
- Dashboard ringkasan penjualan.
- Katalog 6 produk contoh.
- Filter kategori: Semua, Makanan, Minuman, Snack.
- Indikator stok: habis (0), menipis (1–5), aman (>5).
- Keranjang dan simulasi transaksi.
- Riwayat transaksi selama aplikasi berjalan.
- Profil toko yang dapat diedit.
- Penyimpanan data produk dan profil menggunakan Shared Preferences.
- Format harga Rupiah menggunakan `intl`.

## Persyaratan
- Flutter SDK terpasang dan terdeteksi melalui `flutter doctor`.
- VS Code dengan extension Flutter dan Dart, atau Android Studio.

## Menjalankan di Chrome
Buka folder `smartkasir_app` di VS Code, kemudian buka Terminal dan jalankan:

```bash
flutter pub get
flutter run -d chrome
```

Jangan membuka `http://localhost:8080` secara manual. Gunakan `flutter run -d chrome` agar Flutter membuat server lokal dan membuka browser secara otomatis.

## Menjalankan di Android
Pastikan Android SDK dan emulator/perangkat sudah tersedia:

```bash
flutter devices
flutter run
```

## Build Web untuk publikasi/hosting
```bash
flutter build web --release
```
Hasil build berada di `build/web`. Folder tersebut dapat diunggah ke layanan hosting statis seperti GitHub Pages, Netlify, atau Firebase Hosting.

## GitHub
1. Buat repository baru bernama `smartkasir_app` di GitHub.
2. Jangan sertakan folder `build/` atau `.dart_tool/`.
3. Dari terminal pada folder proyek:
```bash
git init
git add .
git commit -m "feat: build SmartKasir Flutter app"
git branch -M main
git remote add origin https://github.com/USERNAME/smartkasir_app.git
git push -u origin main
```
Ganti `USERNAME` dengan username GitHub milikmu.

## Catatan praktikum
Dependensi `sqflite` dan `path` disertakan sesuai kebutuhan praktikum. Versi demo ini memakai `shared_preferences` agar data contoh dapat disimpan dan aplikasi dapat langsung dijalankan di Chrome. Integrasi SQLite native dapat dikembangkan pada tahap praktikum database berikutnya. Data produk awal adalah data contoh dan dapat diedit melalui kode di `lib/main.dart`.
