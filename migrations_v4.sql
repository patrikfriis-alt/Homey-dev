-- ============================================================
-- Homey v4.0 – DB migrations
-- Aja nämä Supabase SQL editorissa
-- ============================================================

-- Feature 1: Toistuvat tehtävät
ALTER TABLE homey_tasks ADD COLUMN IF NOT EXISTS recurrence text DEFAULT null;
-- Arvot: null = ei toistu, 'daily' = päivittäin, 'weekly' = viikoittain, 'monthly' = kuukausittain

-- Feature 2: Hylkäyskommentti
ALTER TABLE homey_completions ADD COLUMN IF NOT EXISTS rejection_reason text DEFAULT null;

-- Feature 3: Säästötavoite (tallennetaan lapsen riviin)
ALTER TABLE homey_children ADD COLUMN IF NOT EXISTS goal_name text DEFAULT null;
ALTER TABLE homey_children ADD COLUMN IF NOT EXISTS goal_amount numeric DEFAULT null;

-- Feature 5: Bonusmaksut (uusi taulu)
CREATE TABLE IF NOT EXISTS homey_bonuses (
  id          uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  family_id   uuid REFERENCES homey_families(id) ON DELETE CASCADE,
  child_id    uuid REFERENCES homey_children(id) ON DELETE CASCADE,
  amount      numeric NOT NULL,
  note        text,
  created_at  timestamptz DEFAULT now()
);

-- RLS homey_bonuses
-- Kopioi alla oleva query Supabase SQL editorissa ja tarkista mikä sarake homey_families-taulussa
-- viittaa auth.uid():iin (esim. user_id, owner_id, tms.) ja vaihda se oikeaan.
--
-- Vaihtoehto 1: Jos muissakin tauluissa ei ole RLS käytössä, jätä pois:
-- (ei tarvita, Supabase anon key + family_id riittää)
--
-- Vaihtoehto 2: Jos RLS on käytössä muissa tauluissa, aja:
-- ALTER TABLE homey_bonuses ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY "family_can_manage_bonuses" ON homey_bonuses
--   FOR ALL
--   USING (family_id IN (
--     SELECT id FROM homey_families WHERE <auth_sarake> = auth.uid()
--   ));
