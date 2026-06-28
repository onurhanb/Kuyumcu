import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

type SaveRequest = {
  client_version: string;
  stats: {
    shop_name: string;
    active_shop_key: string | null;
    player_cash: number;
    inventory_usd: number;
    inventory_eur: number;
    inventory_gram: number;
    inventory_quarter: number;
    inventory_half: number;
    inventory_full: number;
    entry_rights_remaining: number;
    spin_rights_remaining: number;
    total_profit: number;
    daily_profit: number;
    weekly_profit: number;
    monthly_revenue: number;
    current_day: number;
    passive_income_balance: number;
    passive_income_updated_at: string;
    total_transactions: number;
    accepted_deals: number;
    rejected_deals: number;
    lifestyle_score: number;
    yesterday_cash: number;
    daily_reward_day: number;
    daily_reward_claimed_at: string | null;
    entry_rights_refreshed_at: string | null;
    profit_day_anchor_at: string | null;
  };
  owned_shops: Array<{
    shop_key: string;
    shop_name: string;
    employee_count: number;
  }>;
  lifestyle_items: Array<{
    item_name: string;
  }>;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ success: false, error: "Method not allowed" }, 405);
  }

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.replace(/^Bearer\s+/i, "").trim();
    if (!token) {
      return json({ success: false, error: "Missing authorization token" }, 401);
    }

    const body = await req.json() as SaveRequest;
    if (!body?.client_version || !body?.stats) {
      return json({ success: false, error: "Invalid save payload" }, 400);
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const { data, error: userError } = await supabase.auth.getUser(token);
    if (userError || !data.user) {
      return json({ success: false, error: "Invalid user token" }, 401);
    }

    const { data: appConfig, error: configError } = await supabase
      .from("app_config")
      .select("minimum_supported_version")
      .eq("id", 1)
      .single();
    if (configError) {
      throw configError;
    }

    const minimumVersion = String(appConfig.minimum_supported_version ?? "").trim();
    if (minimumVersion && isVersionBelow(body.client_version, minimumVersion)) {
      return json({ success: false, error: "Client update required" }, 426);
    }

    const userId = data.user.id;
    const { error: rpcError } = await supabase.rpc("save_game_state_v1", {
      p_user_id: userId,
      p_stats: body.stats,
      p_owned_shops: body.owned_shops,
      p_lifestyle_items: body.lifestyle_items,
    });
    if (rpcError) throw rpcError;

    return json({ success: true });
  } catch (error) {
    console.error("save-game-state error:", error);
    return json({ success: false, error: String(error) }, 500);
  }
});

function isVersionBelow(version: string, minimumVersion: string): boolean {
  const versionParts = version.split(".").map((part) => Number.parseInt(part, 10) || 0);
  const minimumParts = minimumVersion.split(".").map((part) => Number.parseInt(part, 10) || 0);
  const count = Math.max(versionParts.length, minimumParts.length);

  for (let index = 0; index < count; index += 1) {
    const versionValue = versionParts[index] ?? 0;
    const minimumValue = minimumParts[index] ?? 0;
    if (versionValue < minimumValue) return true;
    if (versionValue > minimumValue) return false;
  }

  return false;
}

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
