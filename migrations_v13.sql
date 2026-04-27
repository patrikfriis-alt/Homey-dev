-- ============================================================
-- Homey v7.0.10 – Perhekohtainen tehtäväkirjasto
-- Luo homey_task_library-taulu ja RLS-politiikka
-- Aja Supabase SQL editorissa
-- ============================================================

CREATE TABLE IF NOT EXISTS homey_task_library (
  id         uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  family_id  uuid REFERENCES homey_families(id) ON DELETE CASCADE,
  title      text NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE homey_task_library ENABLE ROW LEVEL SECURITY;

CREATE POLICY "task_library auth" ON homey_task_library
  FOR ALL USING (
    family_id IN (
      SELECT id FROM homey_families WHERE auth_user_id = auth.uid()
    )
  );
