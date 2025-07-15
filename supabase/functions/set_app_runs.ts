import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  let app_runs: boolean | undefined = undefined;
  try {
    const body = await req.json();
    console.log("Received body:", body);
    app_runs = body.app_runs;
    if (typeof app_runs !== 'boolean') throw new Error('Missing or invalid app_runs');
  } catch (e) {
    console.log("Error parsing body:", e);
    return new Response(JSON.stringify({ error: 'Invalid request body' }), { status: 400 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  // Update the row with id = 1 (change as needed)
  const { error } = await supabase
    .from('app_config')
    .update({ app_runs, updated_at: new Date().toISOString() })
    .eq('id', 1);

  if (error) {
    console.log("Supabase error:", error);
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
  return new Response(JSON.stringify({ success: true }), { status: 200 });
}); 