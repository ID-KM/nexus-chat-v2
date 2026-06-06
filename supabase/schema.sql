-- ═══════════════════════════════════════════════════════════════
-- Nexus Chat v2 — Supabase Schema
-- ═══════════════════════════════════════════════════════════════
-- 1. اذهب إلى Supabase Dashboard → SQL Editor
-- 2. الصق هذا الكود وشغّله
-- 3. بعدها اذهب إلى Replication → Enable Realtime على جدول messages
-- ═══════════════════════════════════════════════════════════════

-- إنشاء جدول الرسائل
CREATE TABLE IF NOT EXISTS messages (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  text TEXT NOT NULL,
  user_id TEXT NOT NULL,
  user_name TEXT NOT NULL DEFAULT 'مجهول',
  color TEXT NOT NULL DEFAULT '#005c4b',
  created_at BIGINT NOT NULL DEFAULT (EXTRACT(EPOCH FROM now()) * 1000)::BIGINT,
  deleted BOOLEAN NOT NULL DEFAULT FALSE
);

-- فهرس لترتيب الرسائل
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);

-- ═══════════════════════════════════════════════════════════════
-- Row Level Security (RLS)
-- ═══════════════════════════════════════════════════════════════

-- تشغيل RLS
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- السماح للجميع بقراءة الرسائل غير المحذوفة
CREATE POLICY "Anyone can read non-deleted messages"
  ON messages
  FOR SELECT
  USING (deleted = FALSE);

-- السماح للجميع بإضافة رسائل جديدة
CREATE POLICY "Anyone can insert messages"
  ON messages
  FOR INSERT
  WITH CHECK (true);

-- السماح فقط لصاحب الرسالة بحذفها (تحديث deleted = true)
CREATE POLICY "Owner can soft-delete their message"
  ON messages
  FOR UPDATE
  USING (user_id = current_setting('app.user_id', TRUE) OR user_id IS NOT NULL)
  WITH CHECK (deleted = TRUE AND user_id = current_setting('app.user_id', TRUE));

-- ═══════════════════════════════════════════════════════════════
-- ملاحظة: RLS أعلاه خاص بالنسخة المتقدمة.
-- للنسخة البسيطة (chat مفتوح بدون أمان)، استخدم هذه القاعدة بدلاً من ذلك:
-- ═══════════════════════════════════════════════════════════════

-- DROP POLICY IF EXISTS "Anyone can insert messages" ON messages;
-- DROP POLICY IF EXISTS "Owner can soft-delete their message" ON messages;
-- DROP POLICY IF EXISTS "Anyone can read non-deleted messages" ON messages;
-- DROP POLICY IF EXISTS "Anyone can soft-delete" ON messages;

-- CREATE POLICY "Anyone can do anything"
--   ON messages
--   FOR ALL
--   USING (true)
--   WITH CHECK (true);

-- ═══════════════════════════════════════════════════════════════
-- Enable Realtime (أيضاً من Dashboard)
-- ═══════════════════════════════════════════════════════════════
-- يجب تفعيل Realtime على جدول messages:
-- Supabase Dashboard → Database → Replication
-- → Source: "Realtime" → Enable
-- → اختر جدول "messages"
-- أو استخدم الأمر:
-- ALTER PUBLICATION supabase_realtime ADD TABLE messages;
