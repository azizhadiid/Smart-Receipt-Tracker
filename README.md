# 🧾 Smart Receipt App

**Smart Receipt** is a modern, responsive, and intelligent Flutter application designed to automate personal expense tracking. Utilizing **Google ML Kit** for local OCR (Optical Character Recognition) and **Supabase** as a Backend-as-a-Service (BaaS), this app seamlessly extracts text and transaction nominals from receipt images, PDFs, and Excel files, providing an intuitive dashboard for budget management.

---

## 🌟 Key Features
- **Intelligent Scanning**: Extracts text and amounts automatically from images, PDFs, and Excel files utilizing Google ML Kit and regex heuristics.
- **Budget Dashboard**: Visualizes your monthly spending, remaining budget limits, and recent transaction history.
- **Automated Workflows**: Fast upload to cloud storage and direct insertion into the database upon document capture.
- **Secure Backend Integration**: Powered by Supabase Auth, PostgreSQL with Row Level Security (RLS), and Database Triggers.
- **Responsive UI/UX**: Crafted with beautiful gradients, robust error handling, and scalable layouts tailored for all screen sizes.

---

## 🛠 Tech Stack
- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **Backend & Database**: [Supabase](https://supabase.com/) (PostgreSQL)
- **OCR Engine**: [Google ML Kit](https://developers.google.com/ml-kit)
- **Storage**: Supabase Storage Buckets

---

## 🚀 Getting Started

Follow these instructions to set up the project locally on your machine.

### 1. Prerequisites
Ensure you have the following installed:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.10+)
- [Dart SDK](https://dart.dev/get-dart)
- An active [Supabase](https://supabase.com/) account and project.

### 2. Clone the Repository
```bash
git clone https://github.com/azizhadiid/Smart-Receipt-Tracker.git
cd smart_receipt
```

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Configure Supabase Environment
Ensure your Supabase URL and Anon Key are correctly initialized in your `main.dart` or via a `.env` configuration file:
```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_PROJECT_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

### 5. Run the Application
Start an emulator or connect a physical device, then run:
```bash
flutter run
```

---

## 🗄️ Supabase Database Setup

This application relies on Supabase for data persistence, user profiles, and storage. You **must** run the following SQL queries in your Supabase SQL Editor to initialize the required schemas, tables, Storage Buckets, and Row Level Security (RLS) policies.

### SQL Schema Initialization

Copy and paste the following snippet into the **SQL Editor** in your Supabase Dashboard:

```sql
-- ==========================================
-- 1. PROFILES TABLE SETUP
-- ==========================================
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  full_name TEXT,
  budget_limit NUMERIC DEFAULT 1000000, -- Default batas pengeluaran
  institution TEXT DEFAULT 'Belum diatur',
  role TEXT DEFAULT 'Pengguna',
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::TEXT, NOW())
);

-- Mengaktifkan Row Level Security (RLS) agar data aman
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Membuat aturan: Pengguna hanya bisa melihat dan mengedit profilnya sendiri
CREATE POLICY "Pengguna bisa melihat profil sendiri" 
ON public.profiles FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Pengguna bisa mengupdate profil sendiri" 
ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- ==========================================
-- 2. TRANSACTIONS TABLE SETUP
-- ==========================================
CREATE TABLE public.transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL, -- Contoh: "Belanja Gelas Plastik & Susu Kental Manis"
  amount NUMERIC NOT NULL, -- Total harga hasil scan ML Kit
  transaction_date DATE NOT NULL,
  receipt_image_url TEXT, -- Link gambar dari Supabase Storage
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::TEXT, NOW())
);

-- Mengaktifkan Row Level Security (RLS)
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- Membuat aturan: Pengguna HANYA bisa mengelola transaksi miliknya sendiri
CREATE POLICY "Pengguna mengelola transaksinya sendiri" 
ON public.transactions FOR ALL USING (auth.uid() = user_id);

-- ==========================================
-- 3. AUTOMATED USER TRIGGER
-- ==========================================
-- Membuat fungsi untuk menyalin data otomatis saat user baru mendaftar
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name)
  VALUES (new.id, new.raw_user_meta_data->>'full_name');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Membuat trigger yang berjalan setiap kali ada user baru mendaftar
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ==========================================
-- 4. STORAGE BUCKETS & SECURITY (RLS)
-- ==========================================
-- Membuat Storage Bucket publik bernama 'avatars' dan 'receipts'
INSERT INTO storage.buckets (id, name, public) 
VALUES 
  ('avatars', 'avatars', true),
  ('receipts', 'receipts', true);

-- Mengatur Keamanan (RLS) untuk Storage 'avatars'
CREATE POLICY "Foto profil bisa dilihat semua orang" 
ON storage.objects FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "Pengguna bisa mengunggah foto sendiri" 
ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid() = owner);

CREATE POLICY "Pengguna bisa mengupdate foto sendiri"
ON storage.objects FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid() = owner);

-- Mengatur Keamanan (RLS) untuk Storage 'receipts'
CREATE POLICY "Pengguna bisa mengunggah dokumen" 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'receipts' AND auth.uid() = owner);
```

---

## 🛡️ License
Distributed under the MIT License. See `LICENSE` for more information.
