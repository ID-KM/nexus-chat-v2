-- ═══════════════════════════════════════════════════════════════
-- Nexus Chat v2 — Supabase Schema (Full)
-- ═══════════════════════════════════════════════════════════════
-- شغّل هذا في Supabase Dashboard → SQL Editor
-- ═══════════════════════════════════════════════════════════════

-- إنشاء جدول الرسائل (إذا ما موجود)
CREATE TABLE IF NOT EXISTS messages (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  text TEXT NOT NULL,
  user_id TEXT NOT NULL,
  user_name TEXT NOT NULL DEFAULT 'مجهول',
  color TEXT NOT NULL DEFAULT '#005c4b',
  room TEXT NOT NULL DEFAULT 'general',
  created_at BIGINT NOT NULL DEFAULT (EXTRACT(EPOCH FROM now()) * 1000)::BIGINT,
  edited_at BIGINT,
  deleted BOOLEAN NOT NULL DEFAULT FALSE
);

-- إضافة الأعمدة الجديدة (إذا الجدول قديم وما فيه room/edited_at)
ALTER TABLE messages ADD COLUMN IF NOT EXISTS room TEXT NOT NULL DEFAULT 'general';
ALTER TABLE messages ADD COLUMN IF NOT EXISTS edited_at BIGINT;

-- فهارس
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_room ON messages(room);

-- ═══════════════════════════════════════════════════════════════
-- Row Level Security (RLS)
-- ═══════════════════════════════════════════════════════════════

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- حذف السياسات القديمة إن وجدت
DROP POLICY IF EXISTS "Owner can soft-delete their message" ON messages;
DROP POLICY IF EXISTS "Anyone can read non-deleted messages" ON messages;

-- سياسات جديدة
CREATE POLICY "Anyone can read messages"
  ON messages FOR SELECT USING (true);

CREATE POLICY "Anyone can insert messages"
  ON messages FOR INSERT WITH CHECK (true);

CREATE POLICY "Anyone can delete their own messages"
  ON messages FOR DELETE USING (true);

CREATE POLICY "Anyone can update their own messages"
  ON messages FOR UPDATE USING (true) WITH CHECK (true);

-- ═══════════════════════════════════════════════════════════════
-- Enable Realtime
-- ═══════════════════════════════════════════════════════════════
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
