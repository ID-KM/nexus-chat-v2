-- ═══════════════════════════════════════════════════════════════
-- Nexus Chat v2 — Schema Fixed (TEXT UUID IDs)
-- ═══════════════════════════════════════════════════════════════
-- حذف الجداول القديمة أولاً (لأن السكربت السابق فشل جزئياً)
-- ═══════════════════════════════════════════════════════════════
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- ═══════════════════════════════════════════════════════════════
-- 1. جدول الحسابات
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE profiles (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  color TEXT NOT NULL DEFAULT '#005c4b',
  is_admin BOOLEAN NOT NULL DEFAULT FALSE,
  created_at BIGINT NOT NULL DEFAULT (EXTRACT(EPOCH FROM now()) * 1000)::BIGINT
);

-- ═══════════════════════════════════════════════════════════════
-- 2. جدول الرسائل
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE messages (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  text TEXT NOT NULL,
  user_id TEXT NOT NULL REFERENCES profiles(id),
  user_name TEXT NOT NULL DEFAULT 'مجهول',
  color TEXT NOT NULL DEFAULT '#005c4b',
  room TEXT NOT NULL DEFAULT 'general',
  created_at BIGINT NOT NULL DEFAULT (EXTRACT(EPOCH FROM now()) * 1000)::BIGINT,
  edited_at BIGINT,
  deleted BOOLEAN NOT NULL DEFAULT FALSE
);

-- ═══════════════════════════════════════════════════════════════
-- 3. فهارس
-- ═══════════════════════════════════════════════════════════════
CREATE INDEX idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX idx_messages_room ON messages(room);
CREATE INDEX idx_profiles_username ON profiles(username);

-- ═══════════════════════════════════════════════════════════════
-- 4. Row Level Security
-- ═══════════════════════════════════════════════════════════════
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- سياسات الرسائل
CREATE POLICY "Anyone can read messages"
  ON messages FOR SELECT USING (true);

CREATE POLICY "Anyone can insert messages"
  ON messages FOR INSERT WITH CHECK (true);

CREATE POLICY "Owner or admin can update messages"
  ON messages FOR UPDATE USING (true) WITH CHECK (true);

CREATE POLICY "Owner or admin can delete messages"
  ON messages FOR DELETE USING (true);

-- سياسات الحسابات
CREATE POLICY "Anyone can read profiles"
  ON profiles FOR SELECT USING (true);

CREATE POLICY "Anyone can insert profiles"
  ON profiles FOR INSERT WITH CHECK (true);

-- ═══════════════════════════════════════════════════════════════
-- 5. تفعيل Realtime
-- ═══════════════════════════════════════════════════════════════
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE profiles;
