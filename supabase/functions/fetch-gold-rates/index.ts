// Supabase Edge Function — fetch-gold-rates
// Scheduled: 0 5 * * * (05:00 UTC = 08:00 TR)
//
// Deploy:  supabase functions deploy fetch-gold-rates
// Schedule in Supabase Dashboard → Edge Functions → fetch-gold-rates → Schedule

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL     = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE  = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const SOURCE_URL        = "https://finans.truncgil.com/today.json";

Deno.serve(async (_req) => {
  try {
    const rates = await scrapeRates();

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE);
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
      fetched_at:           new Date().toISOString(),
    }, { onConflict: "id" });

    if (error) throw error;

    return new Response(
      JSON.stringify({ success: true, rates }),
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

async function scrapeRates(): Promise<Rates> {
  const res  = await fetch(SOURCE_URL, {
    headers: { "Accept-Encoding": "identity", "Accept": "application/json" },
  });
  if (!res.ok) throw new Error(`API yanıt vermedi: ${res.status}`);
  const data = await res.json();

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
