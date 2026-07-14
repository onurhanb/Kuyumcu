// Supabase Edge Function — fetch-gold-rates
// Scheduled: 0 5 * * * (05:00 UTC = 08:00 TR)
//
// Deploy:  supabase functions deploy fetch-gold-rates
// Schedule in Supabase Dashboard → Edge Functions → fetch-gold-rates → Schedule

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL     = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE  = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const SOURCE_URL        = "https://finans.truncgil.com/today.json";
const SOURCE_TIMEOUT_MS = 12_000;
const SOURCE_RETRY_DELAYS_MS = [1_500, 4_000];

Deno.serve(async (_req) => {
  try {
    console.log("[fetch-gold-rates] scheduled run started");
    const rates = await scrapeRates();
    console.log("[fetch-gold-rates] rates fetched successfully");

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE);
    const fetchedAt = new Date();
    const fetchedAtIso = fetchedAt.toISOString();
    const snapshotDate = new Intl.DateTimeFormat("en-CA", {
      timeZone: "Europe/Istanbul",
    }).format(fetchedAt);

    const { error } = await supabase.from("gold_rates").upsert({
      id:                   1,
      gram_buy:             rates.gramBuy,
      gram_sell:            rates.gramSell,
      gram_change_dir:      rates.gramChangeDir,
      quarter_buy:          rates.quarterBuy,
      quarter_sell:         rates.quarterSell,
      quarter_change_dir:   rates.quarterChangeDir,
      half_buy:             rates.halfBuy,
      half_sell:            rates.halfSell,
      half_change_dir:      rates.halfChangeDir,
      full_buy:             rates.fullBuy,
      full_sell:            rates.fullSell,
      full_change_dir:      rates.fullChangeDir,
      usd_buy:              rates.usdBuy,
      usd_sell:             rates.usdSell,
      usd_change_dir:       rates.usdChangeDir,
      eur_buy:              rates.eurBuy,
      eur_sell:             rates.eurSell,
      eur_change_dir:       rates.eurChangeDir,
      source_name:          "truncgil.com",
      fetched_at:           fetchedAtIso,
    }, { onConflict: "id" });

    if (error) throw error;
    console.log("[fetch-gold-rates] gold_rates updated");

    const { error: historyError } = await supabase.from("gold_rate_history").upsert({
      snapshot_date: snapshotDate,
      gram_buy: rates.gramSell,
      quarter_buy: rates.quarterSell,
      half_buy: rates.halfSell,
      full_buy: rates.fullSell,
      usd_buy: rates.usdSell,
      eur_buy: rates.eurSell,
      source_name: "truncgil.com",
      updated_at: fetchedAtIso,
    }, { onConflict: "snapshot_date" });
    if (historyError) throw historyError;
    console.log("[fetch-gold-rates] gold_rate_history upserted");

    const { error: leaderboardError } = await supabase.rpc("refresh_daily_leaderboard_snapshot_v1", {
      p_snapshot_date: snapshotDate,
      p_updated_at: fetchedAtIso,
      p_gram_buy: rates.gramBuy,
      p_quarter_buy: rates.quarterBuy,
      p_half_buy: rates.halfBuy,
      p_full_buy: rates.fullBuy,
      p_usd_buy: rates.usdBuy,
      p_eur_buy: rates.eurBuy,
    });
    if (leaderboardError) throw leaderboardError;
    console.log("[fetch-gold-rates] leaderboard snapshot refreshed");

    let notification:
      { attempted: number; sent: number; failed: number; skipped?: string }
      | { attempted: number; sent: number; failed: number; error: string };
    try {
      notification = await sendDailyRateNotifications(supabase, rates);
      console.log("[fetch-gold-rates] push notifications completed", notification);
    } catch (notificationError) {
      notification = {
        attempted: 0,
        sent: 0,
        failed: 0,
        error: String(notificationError),
      };
      console.error("[fetch-gold-rates] push notification step failed:", notificationError);
    }

    return new Response(
      JSON.stringify({ success: true, rates, notification }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("fetch-gold-rates error:", err);
    return new Response(
      JSON.stringify({ success: false, error: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});

// ---------------------------------------------------------------------------
// JSON API — finans.truncgil.com/today.json
// ---------------------------------------------------------------------------

interface Rates {
  gramBuy:    number; gramSell:    number; gramChangeDir:    number;
  quarterBuy: number; quarterSell: number; quarterChangeDir: number;
  halfBuy:    number; halfSell:    number; halfChangeDir:    number;
  fullBuy:    number; fullSell:    number; fullChangeDir:    number;
  usdBuy:     number; usdSell:     number; usdChangeDir:     number;
  eurBuy:     number; eurSell:     number; eurChangeDir:     number;
}

// ---------------------------------------------------------------------------
// APNs Push Notification
// ---------------------------------------------------------------------------

interface PushTokenRow {
  token: string;
  environment: "development" | "production";
}

async function sendDailyRateNotifications(
  supabase: ReturnType<typeof createClient>,
  rates: Rates,
): Promise<{ attempted: number; sent: number; failed: number; skipped?: string }> {
  const teamId = Deno.env.get("APNS_TEAM_ID");
  const keyId = Deno.env.get("APNS_KEY_ID");
  const bundleId = Deno.env.get("APNS_BUNDLE_ID");
  const privateKey = Deno.env.get("APNS_PRIVATE_KEY");

  if (!teamId || !keyId || !bundleId || !privateKey) {
    return { attempted: 0, sent: 0, failed: 0, skipped: "APNs secrets missing" };
  }

  const { data, error } = await supabase
    .from("push_tokens")
    .select("token, environment")
    .eq("platform", "ios")
    .eq("is_active", true);

  if (error) throw error;

  const tokens = (data ?? []) as PushTokenRow[];
  if (tokens.length === 0) {
    return { attempted: 0, sent: 0, failed: 0 };
  }

  const jwt = await createAPNsJWT(teamId, keyId, privateKey);
  const body = buildNotificationBody(rates);

  let sent = 0;
  let failed = 0;

  await Promise.all(tokens.map(async (row) => {
    const endpoint = row.environment === "production"
      ? "https://api.push.apple.com"
      : "https://api.sandbox.push.apple.com";

    const res = await fetch(`${endpoint}/3/device/${row.token}`, {
      method: "POST",
      headers: {
        authorization: `bearer ${jwt}`,
        "apns-topic": bundleId,
        "apns-push-type": "alert",
        "apns-priority": "10",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        aps: {
          alert: {
            title: "Günaydın",
            body,
          },
          sound: "default",
        },
      }),
    });

    if (res.ok) {
      sent += 1;
      return;
    }

    failed += 1;
    const responseText = await res.text();
    console.error("APNs send failed:", res.status, responseText);

    if (res.status === 400 || res.status === 410) {
      await supabase
        .from("push_tokens")
        .update({ is_active: false, updated_at: new Date().toISOString() })
        .eq("token", row.token);
    }
  }));

  return { attempted: tokens.length, sent, failed };
}

function buildNotificationBody(rates: Rates): string {
  const date = new Intl.DateTimeFormat("tr-TR", {
    day: "numeric",
    month: "long",
    year: "numeric",
    timeZone: "Europe/Istanbul",
  }).format(new Date());

  return `${date}. Dolar ${formatDecimal(rates.usdSell)}, Euro ${formatDecimal(rates.eurSell)}, Gram ${formatWhole(rates.gramSell)}, Çeyrek ${formatWhole(rates.quarterSell)}`;
}

function formatDecimal(value: number): string {
  return new Intl.NumberFormat("tr-TR", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(value);
}

function formatWhole(value: number): string {
  return new Intl.NumberFormat("tr-TR", {
    maximumFractionDigits: 0,
  }).format(value);
}

async function createAPNsJWT(teamId: string, keyId: string, privateKeyPEM: string): Promise<string> {
  const header = base64UrlEncode(JSON.stringify({ alg: "ES256", kid: keyId }));
  const payload = base64UrlEncode(JSON.stringify({
    iss: teamId,
    iat: Math.floor(Date.now() / 1000),
  }));
  const signingInput = `${header}.${payload}`;

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(privateKeyPEM),
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    new TextEncoder().encode(signingInput),
  );

  return `${signingInput}.${base64UrlEncode(signature)}`;
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const normalized = pem.replace(/\\n/g, "\n");
  const base64 = normalized
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");

  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}

function base64UrlEncode(input: string | ArrayBuffer): string {
  const bytes = typeof input === "string"
    ? new TextEncoder().encode(input)
    : new Uint8Array(input);

  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }

  return btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}

async function scrapeRates(): Promise<Rates> {
  const data = await fetchJSONWithRetry<Record<string, Record<string, string>>>(SOURCE_URL);

  const parsePrice = (raw: string): number =>
    parseFloat(raw.replace(/\./g, "").replace(",", "."));

  // Değişim: "%-0,54" → -1, "%0,00" → 0, "%0,65" → 1
  const parseChangeDir = (raw: string): number => {
    const val = parseFloat(raw.replace("%", "").replace(",", "."));
    if (val > 0) return 1;
    if (val < 0) return -1;
    return 0;
  };

  const get = (key: string, field: "Alış" | "Satış"): number => {
    const entry = data[key];
    if (!entry) return 0;
    return parsePrice(entry[field] ?? "0");
  };

  const getDir = (key: string): number => {
    const entry = data[key];
    if (!entry || !entry["Değişim"]) return 0;
    return parseChangeDir(entry["Değişim"]);
  };

  const gramBuy         = get("gram-altin",   "Alış");
  const gramSell        = get("gram-altin",   "Satış");
  const gramChangeDir   = getDir("gram-altin");
  const quarterBuy      = get("ceyrek-altin", "Alış");
  const quarterSell     = get("ceyrek-altin", "Satış");
  const quarterChangeDir= getDir("ceyrek-altin");
  const halfBuy         = get("yarim-altin",  "Alış");
  const halfSell        = get("yarim-altin",  "Satış");
  const halfChangeDir   = getDir("yarim-altin");
  const fullBuy         = get("tam-altin",    "Alış");
  const fullSell        = get("tam-altin",    "Satış");
  const fullChangeDir   = getDir("tam-altin");
  const usdBuy          = get("USD",          "Alış");
  const usdSell         = get("USD",          "Satış");
  const usdChangeDir    = getDir("USD");
  const eurBuy          = get("EUR",          "Alış");
  const eurSell         = get("EUR",          "Satış");
  const eurChangeDir    = getDir("EUR");

  if (gramBuy === 0) {
    throw new Error(`API'den gram altın alınamadı. Keys: ${Object.keys(data).join(", ")}`);
  }

  return {
    gramBuy,    gramSell,    gramChangeDir,
    quarterBuy, quarterSell, quarterChangeDir,
    halfBuy,    halfSell,    halfChangeDir,
    fullBuy,    fullSell,    fullChangeDir,
    usdBuy,     usdSell,     usdChangeDir,
    eurBuy,     eurSell,     eurChangeDir,
  };
}

async function fetchJSONWithRetry<T>(url: string): Promise<T> {
  let lastError: unknown;

  for (let attempt = 0; attempt <= SOURCE_RETRY_DELAYS_MS.length; attempt += 1) {
    try {
      return await fetchJSONOnce<T>(url, attempt + 1);
    } catch (error) {
      lastError = error;
      const hasMoreAttempts = attempt < SOURCE_RETRY_DELAYS_MS.length;
      console.error(`[fetch-gold-rates] source fetch attempt ${attempt + 1} failed:`, error);
      if (!hasMoreAttempts) break;

      const delayMs = SOURCE_RETRY_DELAYS_MS[attempt];
      await sleep(delayMs);
    }
  }

  throw new Error(`Rates source failed after retries: ${String(lastError)}`);
}

async function fetchJSONOnce<T>(url: string, attempt: number): Promise<T> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort("timeout"), SOURCE_TIMEOUT_MS);

  try {
    const res = await fetch(url, {
      headers: {
        "Accept-Encoding": "identity",
        "Accept": "application/json",
      },
      signal: controller.signal,
    });

    if (!res.ok) {
      throw new Error(`API yanıt vermedi: ${res.status}`);
    }

    const rawText = await res.text();
    if (!rawText.trim()) {
      throw new Error(`Boş yanıt gövdesi alındı (attempt ${attempt})`);
    }

    try {
      return JSON.parse(rawText) as T;
    } catch (parseError) {
      throw new Error(`JSON parse başarısız (attempt ${attempt}): ${String(parseError)}`);
    }
  } catch (error) {
    if (error instanceof Error && error.name === "AbortError") {
      throw new Error(`Rates source timeout after ${SOURCE_TIMEOUT_MS}ms (attempt ${attempt})`);
    }
    throw error;
  } finally {
    clearTimeout(timeoutId);
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
