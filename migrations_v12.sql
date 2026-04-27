-- ============================================================
-- Homey v7.0.9 – Lunastuksen pisteiden ylikirjoitus hyväksynnässä
-- 1. Lisää approved_cost-sarake homey_reward_claims-tauluun
-- 2. Päivitä approve_reward_claim RPC tukemaan p_override_cost
-- Aja Supabase SQL editorissa
-- ============================================================

ALTER TABLE homey_reward_claims
  ADD COLUMN IF NOT EXISTS approved_cost integer DEFAULT null;

-- ============================================================
-- RPC: approve_reward_claim (päivitetty)
-- p_override_cost: jos annettu, käytetään tätä pistekustannusta
--   alkuperäisen reward.points_cost sijaan
-- ============================================================
CREATE OR REPLACE FUNCTION approve_reward_claim(
  p_claim_id uuid,
  p_parent_comment text DEFAULT null,
  p_override_cost integer DEFAULT null
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_claim homey_reward_claims%ROWTYPE;
  v_reward homey_rewards%ROWTYPE;
  v_current_pts integer;
  v_cost integer;
BEGIN
  SELECT * INTO v_claim FROM homey_reward_claims WHERE id = p_claim_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Claim not found';
  END IF;

  SELECT * INTO v_reward FROM homey_rewards WHERE id = v_claim.reward_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Reward not found';
  END IF;

  v_cost := COALESCE(p_override_cost, v_reward.points_cost);

  SELECT points_balance INTO v_current_pts FROM homey_children WHERE id = v_claim.child_id;
  IF v_current_pts IS NULL THEN v_current_pts := 0; END IF;

  IF v_current_pts < v_cost THEN
    RAISE EXCEPTION 'Insufficient points balance';
  END IF;

  UPDATE homey_children
    SET points_balance = points_balance - v_cost
    WHERE id = v_claim.child_id;

  UPDATE homey_reward_claims
    SET status = 'approved',
        parent_comment = p_parent_comment,
        approved_cost = v_cost,
        resolved_at = now()
    WHERE id = p_claim_id;
END;
$$;
