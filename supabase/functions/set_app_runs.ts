import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  // Authorization header validation
  const expectedAuth = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const authHeader = req.headers.get("authorization");
  if (!authHeader || authHeader !== `Bearer ${expectedAuth}`) {
    return new Response("Unauthorized", { status: 401 });
  }

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
  let updateFields: Record<string, any> = { app_runs, updated_at: new Date().toISOString() };
  if (app_runs === false) {
    // Set estimated_time to 1 minute from now
    const now = new Date();
    const estimatedTime = new Date(now.getTime() + 2 * 60 * 1000).toISOString();
    updateFields.estimated_time = estimatedTime;
  } else {
    updateFields.estimated_time = null;
  }

  const { error } = await supabase
    .from('app_config')
    .update(updateFields)
    .eq('id', 1);

  if (error) {
    console.log("Supabase error:", error);
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
  return new Response(JSON.stringify({ success: true }), { status: 200 });
}); 