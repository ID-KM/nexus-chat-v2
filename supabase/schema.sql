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

-- السماح للجميع بقراءة كل الرسائل
CREATE POLICY "Anyone can read messages"
  ON messages
  FOR SELECT
  USING (true);

-- السماح للجميع بإضافة رسائل جديدة
CREATE POLICY "Anyone can insert messages"
  ON messages
  FOR INSERT
  WITH CHECK (true);

-- السماح بحذف الرسالة — العميل يتحقق من user_id في الاستعلام نفسه
CREATE POLICY "Anyone can delete their own messages"
  ON messages
  FOR DELETE
  USING (true);

-- ═══════════════════════════════════════════════════════════════
-- ملاحظة: هذا البوليسي يسمح لأي شخص بحذف أي رسالة.
-- الأمان يجي من العميل (Client) اللي يرسل user_id في طلب الحذف.
-- للنسخة المحمية، استخدم Supabase Auth + جلسات المستخدمين.
-- ═══════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════
-- Enable Realtime (أيضاً من Dashboard)
-- ═══════════════════════════════════════════════════════════════
-- يجب تفعيل Realtime على جدول messages:
-- Supabase Dashboard → Database → Replication
-- → Source: "Realtime" → Enable
-- → اختر جدول "messages"
-- أو استخدم الأمر:
-- ALTER PUBLICATION supabase_realtime ADD TABLE messages;
