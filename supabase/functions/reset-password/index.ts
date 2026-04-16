// Supabase Edge Function: reset-password
// Lähettää Supabase Auth password reset -sähköpostin perheen sähköpostiosoitteeseen.
//
// HTTP POST https://<project>.supabase.co/functions/v1/reset-password
// Body: { "email": "perhe@esimerkki.fi" }
// (Ei vaadi autentikointia — tarkoituksella julkinen)

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  let email: string;
  try {
    const body = await req.json();
    email = (body.email ?? '').trim().toLowerCase();
    if (!email) throw new Error('missing email');
  } catch {
    return new Response(JSON.stringify({ error: 'Pyyntö vaatii kentän: email' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // Käytä anon clientiä — resetointi ei vaadi admin-oikeuksia
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!
  );

  const { error } = await supabase.auth.resetPasswordForEmail(email, {
    // redirectTo: 'https://patrikfriis-alt.github.io/Homey/', // valinnainen
  });

  if (error) {
    // Älä paljasta onko sähköposti rekisteröity — palauta aina 200
    console.error('reset-password error:', error.message);
  }

  // Palauta aina sama viesti tietoturvan vuoksi
  return new Response(
    JSON.stringify({
      message: 'Jos sähköposti on rekisteröity, salasanan palautuslinkki on lähetetty.',
    }),
    { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  );
});
