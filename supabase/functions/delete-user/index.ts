// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts"

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

console.log("Hello from Functions!")

serve(async (req) => {
  // Only allow POST
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  // Authorization header validation
  const expectedAuth = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"); // or use a custom secret
  const authHeader = req.headers.get("authorization");
  if (!authHeader || authHeader !== `Bearer ${expectedAuth}`) {
    return new Response("Unauthorized", { status: 401 });
  }

  // Parse the body for user_id
  let user_id = "";
  try {
    const body = await req.json();
    user_id = body.user_id;
    if (!user_id) throw new Error("Missing user_id");
  } catch {
    return new Response("Invalid request body", { status: 400 });
  }

  // Use the service role key from environment
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const projectUrl = Deno.env.get("SUPABASE_URL");

  // Call the Supabase Admin API to delete the user
  const res = await fetch(`${projectUrl}/auth/v1/admin/users/${user_id}`, {
    method: "DELETE",
    headers: {
      "apikey": serviceRoleKey!,
      "Authorization": `Bearer ${serviceRoleKey}`,
      "Content-Type": "application/json",
    },
  });

  if (res.ok) {
    return new Response(JSON.stringify({ success: true }), { status: 200 });
  } else {
    const error = await res.text();
    return new Response(error, { status: res.status });
  }
});

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/delete-user' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
