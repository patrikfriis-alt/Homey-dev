-- ============================================================
-- Homey v6.5 – Lunastusten hyväksyntä
-- 1. Lisää parent_comment-sarake homey_reward_claims-tauluun
-- 2. Luo approve_reward_claim RPC -funktio
-- Aja Supabase SQL editorissa
-- ============================================================

-- Lisää sarakkeet jos puuttuvat
ALTER TABLE homey_reward_claims
  ADD COLUMN IF NOT EXISTS parent_comment text DEFAULT null,
  ADD COLUMN IF NOT EXISTS resolved_at timestamptz DEFAULT null;

-- ============================================================
-- RPC: approve_reward_claim
-- Atomisesti: tarkistaa pistesaldon, vähentää pisteet,
-- merkitsee claiMin approved
-- ============================================================
CREATE OR REPLACE FUNCTION approve_reward_claim(
  p_claim_id uuid,
  p_parent_comment text DEFAULT null
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_claim homey_reward_claims%ROWTYPE;
  v_reward homey_rewards%ROWTYPE;
  v_current_pts integer;
BEGIN
  -- Hae claim
  SELECT * INTO v_claim FROM homey_reward_claims WHERE id = p_claim_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Claim not found';
  END IF;

  -- Hae reward
  SELECT * INTO v_reward FROM homey_rewards WHERE id = v_claim.reward_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Reward not found';
  END IF;

  -- Tarkista pistesaldo
  SELECT points_balance INTO v_current_pts FROM homey_children WHERE id = v_claim.child_id;
  IF v_current_pts IS NULL THEN v_current_pts := 0; END IF;

  IF v_current_pts < v_reward.points_cost THEN
    RAISE EXCEPTION 'Insufficient points balance';
  END IF;

  -- Vähennä pisteet
  UPDATE homey_children
    SET points_balance = points_balance - v_reward.points_cost
    WHERE id = v_claim.child_id;

  -- Merkitse approved
  UPDATE homey_reward_claims
    SET status = 'approved',
        parent_comment = p_parent_comment,
        resolved_at = now()
    WHERE id = p_claim_id;
END;
$$;
