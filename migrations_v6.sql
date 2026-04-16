-- ============================================================
-- Homey v6.0 – RLS-politiikat kaikille tauluille (Supabase Auth)
-- Aja nämä Supabase SQL editorissa
-- ============================================================

-- Poista vanhat RLS-politiikat (jos olemassa)
drop policy if exists "perhe näkee omat lapset" on homey_children;
drop policy if exists "perhe näkee omat tehtävät" on homey_tasks;
drop policy if exists "perhe näkee omat suoritukset" on homey_completions;
drop policy if exists "perhe näkee omat maksut" on homey_payments;

-- Ota RLS käyttöön kaikilla tauluilla
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

-- homey_families
create policy "familia auth" on homey_families
  for all using (auth_user_id = auth.uid());

-- homey_children
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
-- HUOM: homey_achievements- ja homey_goals-taulujen politiikat
-- lisätään vain jos nämä taulut on luotu kannassasi:
-- ============================================================
-- alter table homey_achievements enable row level security;
-- create policy "achievements auth" on homey_achievements
--   for all using (
--     family_id in (
--       select id from homey_families where auth_user_id = auth.uid()
--     )
--   );
--
-- alter table homey_goals enable row level security;
-- create policy "goals auth" on homey_goals
--   for all using (
--     family_id in (
--       select id from homey_families where auth_user_id = auth.uid()
--     )
--   );

-- ============================================================
-- Varmista lisäksi että Supabase Auth "Confirm email" on
-- poistettu käytöstä (Settings → Auth → Confirm email: off)
-- jotta rekisteröityminen toimii ilman sähköpostivahvistusta.
-- ============================================================
