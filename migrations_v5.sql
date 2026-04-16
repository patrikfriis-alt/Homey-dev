-- ============================================================
-- Homey v5.0 – DB migrations
-- Aja nämä Supabase SQL editorissa
-- ============================================================

-- Feature H: Supabase Auth migration
-- Linkittää homey_families-rivin Supabase Auth -käyttäjään
ALTER TABLE homey_families ADD COLUMN IF NOT EXISTS auth_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL;

-- Indeksi nopeuttaa haku-operaatiota auth_user_id:llä
CREATE INDEX IF NOT EXISTS idx_families_auth_user_id ON homey_families(auth_user_id);

-- RLS-politiikat (valinnainen, suositeltava):
-- Ota käyttöön vain jos muissakin tauluissa on RLS käytössä

-- ALTER TABLE homey_families ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY "owner_can_manage_family" ON homey_families
--   FOR ALL
--   USING (auth_user_id = auth.uid() OR auth_user_id IS NULL);

-- Olemassa olevien perheiden siirto (valinnainen):
-- Jos haluat siirtää vanhat perheet Supabase Auth -käyttäjiksi automaattisesti,
-- luo ensin Auth-käyttäjät manuaalisesti Supabase Dashboardissa ja päivitä:
-- UPDATE homey_families SET auth_user_id = '<auth-user-uuid>' WHERE email = '<email>';

-- ============================================================
-- Feature 1 (v4): Tehtävien aikarajat
-- (jo ajettu migrations_v4.sql:ssa, tässä varmuuden vuoksi)
-- ============================================================
ALTER TABLE homey_tasks ADD COLUMN IF NOT EXISTS deadline date DEFAULT null;

-- ============================================================
-- Feature 3 (v4): Haasteet
-- ============================================================
CREATE TABLE IF NOT EXISTS homey_challenges (
  id          uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  family_id   uuid REFERENCES homey_families(id) ON DELETE CASCADE,
  child_id    uuid REFERENCES homey_children(id) ON DELETE CASCADE,
  title       text NOT NULL,
  goal_amount numeric NOT NULL,
  bonus_amount numeric DEFAULT 0,
  week_start  date NOT NULL,
  created_at  timestamptz DEFAULT now()
);

-- ============================================================
-- Feature 2 (v4): Kommentit
-- ============================================================
CREATE TABLE IF NOT EXISTS homey_comments (
  id           uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  family_id    uuid REFERENCES homey_families(id) ON DELETE CASCADE,
  completion_id uuid REFERENCES homey_completions(id) ON DELETE CASCADE,
  child_comment text,
  parent_reply  text,
  created_at   timestamptz DEFAULT now()
);

-- ============================================================
-- Feature 5 (v4): Lisävanhempi
-- ============================================================
CREATE TABLE IF NOT EXISTS homey_parents (
  id          uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  family_id   uuid REFERENCES homey_families(id) ON DELETE CASCADE,
  name        text NOT NULL,
  email       text NOT NULL,
  password_hash text,
  role        text DEFAULT 'parent',
  created_at  timestamptz DEFAULT now(),
  UNIQUE(family_id, email)
);

-- ============================================================
-- Feature 6 (v4): Tehtävämallit
-- ============================================================
CREATE TABLE IF NOT EXISTS homey_task_templates (
  id          uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  family_id   uuid REFERENCES homey_families(id) ON DELETE CASCADE,
  name        text NOT NULL,
  tasks_json  jsonb NOT NULL,
  created_at  timestamptz DEFAULT now(),
  UNIQUE(family_id, name)
);
