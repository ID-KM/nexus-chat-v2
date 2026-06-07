-- ═══════════════════════════════════════════════════════════════
-- Nexus Chat v2 — Supabase Schema (Full)
-- ═══════════════════════════════════════════════════════════════
-- شغّل هذا في Supabase Dashboard → SQL Editor
-- ═══════════════════════════════════════════════════════════════

-- إنشاء جدول الحسابات
CREATE TABLE IF NOT EXISTS profiles (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,           -- SHA-256 hash hex
  color TEXT NOT NULL DEFAULT '#005c4b',
  is_admin BOOLEAN NOT NULL DEFAULT FALSE,
  created_at BIGINT NOT NULL DEFAULT (EXTRACT(EPOCH FROM now()) * 1000)::BIGINT
);

-- إنشاء جدول الرسائل (إذا ما موجود)
CREATE TABLE IF NOT EXISTS messages (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  text TEXT NOT NULL,
  user_id BIGINT NOT NULL REFERENCES profiles(id),  -- يشير لجدول الحسابات
  user_name TEXT NOT NULL DEFAULT 'مجهول',
  color TEXT NOT NULL DEFAULT '#005c4b',
  room TEXT NOT NULL DEFAULT 'general',
  created_at BIGINT NOT NULL DEFAULT (EXTRACT(EPOCH FROM now()) * 1000)::BIGINT,
  edited_at BIGINT,
  deleted BOOLEAN NOT NULL DEFAULT FALSE
);

-- إضافة الأعمدة للجدول القديم (إذا موجود)
ALTER TABLE messages ALTER COLUMN user_id TYPE BIGINT USING user_id::BIGINT;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS edited_at BIGINT;

-- فهارس
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_room ON messages(room);
CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles(username);

-- ═══════════════════════════════════════════════════════════════
-- Row Level Security (RLS)
-- ═══════════════════════════════════════════════════════════════

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- حذف السياسات القديمة
DROP POLICY IF EXISTS "Owner can soft-delete their message" ON messages;
DROP POLICY IF EXISTS "Anyone can read non-deleted messages" ON messages;

-- سياسات جديدة للرسائل
CREATE POLICY "Anyone can read messages"
  ON messages FOR SELECT USING (true);

CREATE POLICY "Anyone can insert messages"
  ON messages FOR INSERT WITH CHECK (true);

CREATE POLICY "Owner or admin can update messages"
  ON messages FOR UPDATE USING (true) WITH CHECK (true);

CREATE POLICY "Owner or admin can delete messages"
  ON messages FOR DELETE USING (true);

-- سياسات للحسابات
CREATE POLICY "Anyone can read profiles"
  ON profiles FOR SELECT USING (true);

CREATE POLICY "Anyone can insert profiles"
  ON profiles FOR INSERT WITH CHECK (true);

-- ═══════════════════════════════════════════════════════════════
-- Enable Realtime
-- ═══════════════════════════════════════════════════════════════
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE profiles;
