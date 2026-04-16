// Supabase Edge Function: migrate-families
// Siirtää olemassa olevat perheet (auth_user_id IS NULL) Supabase Authiin.
//
// Aja: supabase functions invoke migrate-families --no-verify-jwt
// tai HTTP POST https://<project>.supabase.co/functions/v1/migrate-families
//   Authorization: Bearer <service_role_key>
//
// Tarvittavat env-muuttujat (asetetaan automaattisesti Supabase-projektissa):
//   SUPABASE_URL
//   SUPABASE_SERVICE_ROLE_KEY

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  // Require service role key — tämä funktio EI saa olla julkisesti ajettavissa
  const authHeader = req.headers.get('Authorization') ?? '';
  const token = authHeader.replace('Bearer ', '');
  if (token !== Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { autoRefreshToken: false, persistSession: false } }
  );

  // 1. Hae kaikki perheet joilla ei ole auth_user_id
  const { data: families, error: fetchErr } = await supabaseAdmin
    .from('homey_families')
    .select('id, name, email')
    .is('auth_user_id', null);

  if (fetchErr) {
    return new Response(JSON.stringify({ error: fetchErr.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  if (!families || families.length === 0) {
    return new Response(
      JSON.stringify({ message: 'Kaikki perheet on jo siirretty Authiin.', migrated: 0, failed: 0 }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  // 2. Luo Auth-käyttäjä jokaiselle perheelle
  const results: { email: string; status: string; error?: string }[] = [];
  let migrated = 0;
  let failed = 0;

  for (const family of families) {
    try {
      // Luo Auth-käyttäjä — satunnainen väliaikainen salasana (käyttäjä voi resetoida)
      const tempPassword = crypto.randomUUID().replace(/-/g, '').slice(0, 16) + 'Aa1!';

      const { data: authUser, error: createErr } = await supabaseAdmin.auth.admin.createUser({
        email: family.email,
        password: tempPassword,
        email_confirm: true, // merkitään suoraan vahvistetuksi
        user_metadata: { family_name: family.name },
      });

      if (createErr) {
        // Jos käyttäjä on jo olemassa Authissa, yritä löytää heidät
        if (
          createErr.message?.toLowerCase().includes('already exists') ||
          createErr.message?.toLowerCase().includes('already registered')
        ) {
          const { data: userList } = await supabaseAdmin.auth.admin.listUsers();
          const existing = userList?.users?.find((u) => u.email === family.email);
          if (existing) {
            await supabaseAdmin
              .from('homey_families')
              .update({ auth_user_id: existing.id })
              .eq('id', family.id);
            results.push({ email: family.email, status: 'linked_existing' });
            migrated++;
            continue;
          }
        }
        results.push({ email: family.email, status: 'failed', error: createErr.message });
        failed++;
        continue;
      }

      // 3. Päivitä homey_families.auth_user_id
      const { error: updateErr } = await supabaseAdmin
        .from('homey_families')
        .update({ auth_user_id: authUser.user.id })
        .eq('id', family.id);

      if (updateErr) {
        results.push({ email: family.email, status: 'auth_created_but_link_failed', error: updateErr.message });
        failed++;
        continue;
      }

      // 4. Lähetä salasanan palautuslinkki (käyttäjä asettaa oman salasanan)
      await supabaseAdmin.auth.admin.generateLink({
        type: 'recovery',
        email: family.email,
      });

      results.push({ email: family.email, status: 'migrated' });
      migrated++;
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      results.push({ email: family.email, status: 'exception', error: msg });
      failed++;
    }
  }

  return new Response(
    JSON.stringify({
      message: `Siirretty: ${migrated}, epäonnistui: ${failed}`,
      migrated,
      failed,
      results,
    }),
    { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  );
});
