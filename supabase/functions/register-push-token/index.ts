import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ success: false, error: "Method not allowed" }, 405);
  }

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.replace("Bearer ", "");
    if (!token) return json({ success: false, error: "Missing authorization token" }, 401);

    const body = await req.json();
    const deviceToken = String(body.token ?? "").trim();
    const environment = String(body.environment ?? "").trim();
    const platform = String(body.platform ?? "ios").trim();
    const isActive = body.is_active === undefined ? true : Boolean(body.is_active);

    if (!/^[a-f0-9]{64,}$/i.test(deviceToken)) {
      return json({ success: false, error: "Invalid APNs token" }, 400);
    }
    if (!["development", "production"].includes(environment)) {
      return json({ success: false, error: "Invalid APNs environment" }, 400);
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE);
    const { data, error: userError } = await supabase.auth.getUser(token);
    if (userError || !data.user) {
      return json({ success: false, error: "Invalid user token" }, 401);
    }

    const { error } = await supabase.from("push_tokens").upsert({
      user_id: data.user.id,
      token: deviceToken,
      platform,
      environment,
      is_active: isActive,
      last_seen_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    }, { onConflict: "token" });

    if (error) throw error;

    return json({ success: true });
  } catch (err) {
    console.error("register-push-token error:", err);
    return json({ success: false, error: String(err) }, 500);
  }
});

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
