-- ============================================================
-- Homey v7.0 – Ota RLS käyttöön migraation jälkeen
--
-- AJA TÄMÄ VASTA kun migrate-families Edge Function on ajettu
-- ja kaikilla homey_families-riveillä on auth_user_id täytettynä.
--
-- Tarkista ennen ajoa:
--   SELECT id, email, auth_user_id FROM homey_families WHERE auth_user_id IS NULL;
-- → Tuloksen pitää olla tyhjä (0 riviä) ennen kuin jatkat.
-- ============================================================

-- Varmistus: tarkista ettei auth_user_id puutu keneltäkään
-- (Kommentoi pois jos haluat ajaa ilman tarkistusta)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM homey_families WHERE auth_user_id IS NULL) THEN
    RAISE EXCEPTION 'Virhe: joillakin perheillä ei ole auth_user_id. Aja ensin migrate-families Edge Function.';
  END IF;
END $$;

-- ============================================================
-- Poista vanhat RLS-politiikat (migrations_v6.sql:sta)
-- ============================================================
drop policy if exists "familia auth"    on homey_families;
drop policy if exists "children auth"   on homey_children;
drop policy if exists "tasks auth"      on homey_tasks;
drop policy if exists "completions auth" on homey_completions;
drop policy if exists "payments auth"   on homey_payments;
drop policy if exists "bonuses auth"    on homey_bonuses;
drop policy if exists "challenges auth" on homey_challenges;
drop policy if exists "comments auth"   on homey_comments;
drop policy if exists "templates auth"  on homey_task_templates;
drop policy if exists "parents auth"    on homey_parents;

-- ============================================================
-- Ota RLS käyttöön kaikilla tauluilla
-- ============================================================
alter table homey_families        enable row level security;
alter table homey_children        enable row level security;
alter table homey_tasks           enable row level security;
alter table homey_completions     enable row level security;
alter table homey_payments        enable row level security;
alter table homey_bonuses         enable row level security;
alter table homey_challenges      enable row level security;
alter table homey_comments        enable row level security;
alter table homey_task_templates  enable row level security;
alter table homey_parents         enable row level security;

-- ============================================================
-- Luo RLS-politiikat
-- ============================================================

-- homey_families: omistaja näkee vain oman perheen
create policy "familia auth" on homey_families
  for all using (auth_user_id = auth.uid());

-- homey_children: sallitaan jos family_id kuuluu kirjautuneelle käyttäjälle
create policy "children auth" on homey_children
  for all using (
    family_id in (
      select id from homey_families where auth_user_id = auth.uid()
    )
  );

-- homey_tasks
create policy "tasks auth" on homey_tasks
  for all using (
    family_id in (
      select id from homey_families where auth_user_id = auth.uid()
    )
  );

-- homey_completions
create policy "completions auth" on homey_completions
  for all using (
    child_id in (
      select id from homey_children where family_id in (
        select id from homey_families where auth_user_id = auth.uid()
      )
    )
  );

-- homey_payments
create policy "payments auth" on homey_payments
  for all using (
    child_id in (
      select id from homey_children where family_id in (
        select id from homey_families where auth_user_id = auth.uid()
      )
    )
  );

-- homey_bonuses
create policy "bonuses auth" on homey_bonuses
  for all using (
    family_id in (
      select id from homey_families where auth_user_id = auth.uid()
    )
  );

-- homey_challenges
create policy "challenges auth" on homey_challenges
  for all using (
    family_id in (
      select id from homey_families where auth_user_id = auth.uid()
    )
  );

-- homey_comments
create policy "comments auth" on homey_comments
  for all using (
    family_id in (
      select id from homey_families where auth_user_id = auth.uid()
    )
  );

-- homey_task_templates
create policy "templates auth" on homey_task_templates
  for all using (
    family_id in (
      select id from homey_families where auth_user_id = auth.uid()
    )
  );

-- homey_parents
create policy "parents auth" on homey_parents
  for all using (
    family_id in (
      select id from homey_families where auth_user_id = auth.uid()
    )
  );

-- ============================================================
-- Valmis! Testaa kirjautuminen uudelleen sovelluksessa.
-- ============================================================
