-- ============================================================
-- Homey v8.0 – Lisää admin_pin -sarake homey_families-tauluun
-- Aja Supabase SQL editorissa
-- ============================================================

ALTER TABLE homey_families ADD COLUMN IF NOT EXISTS admin_pin text DEFAULT null;
