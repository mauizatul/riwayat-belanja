# Riwayat Belanjaku

Aplikasi Flutter untuk mencatat & melacak riwayat belanja pribadi — input manual atau scan struk otomatis pakai AI, lengkap dengan insight kenaikan harga barang dari waktu ke waktu.

## ✨ Fitur

- **Catat belanja manual** — input nama merchant (dengan autocomplete dari merchant yang pernah dipakai), tanggal, dan daftar barang (nama, qty, harga)
- **Scan struk otomatis** — foto struk lewat kamera, AI (Gemini) otomatis baca & pecah jadi daftar barang, tinggal dikoreksi sebelum disimpan
- **Riwayat belanja** — dikelompokkan per bulan, lengkap dengan total belanja tiap bulan
- **Detail receipt** — lihat foto struk asli (kalau ada), daftar barang, dan total
- **Cari harga barang** — cari barang yang pernah dibeli, lihat histori harga & merchant-nya
- **Insight kenaikan harga** — deteksi otomatis barang yang harganya naik dibanding pembelian sebelumnya, dibandingkan di merchant yang sama

## 🛠️ Tech Stack

- **Flutter** — UI & state management ([provider](https://pub.dev/packages/provider))
- **Supabase** — database (Postgres), Auth, Storage (foto struk), Edge Functions
- **Google Gemini API** — ekstraksi data struk dari foto (lewat Supabase Edge Function)
- **image_picker** — akses kamera & galeri

## 📁 Struktur Project

```
lib/
├── core/                    # Theme, konstanta, util umum
├── models/                  # Data model (ReceiptModel, ReceiptItem, dll)
├── providers/                # State management (ChangeNotifier)
├── services/                 # Komunikasi ke Supabase (ReceiptService)
└── features/
    ├── home/                  # Home screen, riwayat, search, scan
    └── receipt/               # Form tambah/koreksi receipt

supabase/
├── functions/
│   └── scan-receipt/        # Edge Function: kirim foto struk ke Gemini API
└── sql/                       # Script SQL setup database (jalankan di SQL Editor)
```

## 🚀 Setup

### 1. Prasyarat

- [Flutter SDK](https://docs.flutter.dev/get-started/install) sudah terinstall (`flutter doctor` bersih)
- Akun [Supabase](https://supabase.com) (gratis)
- Akun [Google AI Studio](https://aistudio.google.com/apikey) untuk API key Gemini (gratis)
- [Supabase CLI](https://supabase.com/docs/guides/cli) terinstall (buat deploy Edge Function)

### 2. Clone & install dependencies

```bash
git clone https://github.com/<username>/riwayat_belanjaku.git
cd riwayat_belanjaku
flutter pub get
```

### 3. Setup database

Buka **Supabase Dashboard → SQL Editor**, jalankan script di `supabase/sql/` secara berurutan:

1. Buat tabel `receipts`, `receipt_items`, `merchants` (lihat skema di bawah)
2. `rls_policies.sql` — aktifkan Row Level Security, supaya user cuma bisa akses data miliknya sendiri
3. `storage_setup.sql` — buat bucket `receipt-images` (private) + policy-nya

### 4. Setup konfigurasi Supabase di app

File `lib/core/constants/supabase.dart` **sengaja tidak ikut ter-commit** (ada di `.gitignore`) karena berisi credential project.

```bash
cp lib/core/constants/supabase.dart.example lib/core/constants/supabase.dart
```

Lalu isi `url` dan `anonKey` sesuai project Supabase kamu (**Project Settings → API**).

### 5. Setup & deploy Edge Function

```bash
supabase login
supabase link --project-ref <project-ref-kamu>
supabase secrets set GEMINI_API_KEY="isi-api-key-gemini-kamu"
supabase functions deploy scan-receipt
```

### 6. Jalankan aplikasi

```bash
flutter run
```

## 🗄️ Skema Database

```sql
receipts
├── id                bigint (PK, auto increment)
├── user_id           uuid (FK -> profiles.id)
├── merchant_id        bigint (FK -> merchants.id)
├── receipt_date       date
├── total_amount        numeric(12,2)
├── image_url          text (path di Supabase Storage, bukan URL langsung)
└── created_at          timestamptz

receipt_items
├── id                bigint (PK, auto increment)
├── receipt_id         bigint (FK -> receipts.id)
├── item_name          text
├── qty               numeric(10,2)
├── unit_price          numeric(12,2)
└── total_price         numeric(12,2)

merchants
├── id                bigint (PK, auto increment)
├── name              varchar(100)
└── created_at          timestamp
```

## 🔒 Keamanan

- Semua tabel pakai **Row Level Security** — user cuma bisa akses data miliknya sendiri
- Foto struk disimpan di Storage **bucket private**, diakses lewat signed URL yang expired otomatis (1 jam)
- API key Gemini disimpan sebagai **Supabase secret**, tidak pernah ada di sisi client/app

## 🗺️ Rencana Pengembangan

- [ ] Fuzzy matching nama barang (biar "Indomie Goreng" & "indomie goreng 1pcs" dianggap barang yang sama)
- [ ] Export riwayat ke Excel/PDF
- [ ] Grafik pengeluaran bulanan
- [ ] Kategori belanja (kebutuhan pokok, jajan, dll)
