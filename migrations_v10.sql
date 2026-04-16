-- ============================================================
-- Homey v6.3 – Luo homey_rewards ja homey_reward_claims taulut
-- Aja Supabase SQL editorissa
-- ============================================================

CREATE TABLE IF NOT EXISTS homey_rewards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id uuid NOT NULL REFERENCES homey_families(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  icon text DEFAULT '🎁',
  points_cost integer NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS homey_reward_claims (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reward_id uuid NOT NULL REFERENCES homey_rewards(id) ON DELETE CASCADE,
  child_id uuid NOT NULL REFERENCES homey_children(id) ON DELETE CASCADE,
  family_id uuid NOT NULL REFERENCES homey_families(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending',  -- 'pending' | 'approved' | 'rejected'
  claimed_at timestamptz DEFAULT now(),
  resolved_at timestamptz
);

-- RLS
ALTER TABLE homey_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE homey_reward_claims ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rewards auth" ON homey_rewards
  FOR ALL USING (family_id IN (SELECT id FROM homey_families WHERE auth_user_id = auth.uid()));

CREATE POLICY "reward_claims auth" ON homey_reward_claims
  FOR ALL USING (family_id IN (SELECT id FROM homey_families WHERE auth_user_id = auth.uid()));
