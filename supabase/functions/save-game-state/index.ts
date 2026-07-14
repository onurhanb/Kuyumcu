import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// Hile koruması sınırları (v1.6). Amaç: meşru oynanışı ASLA engellememek,
// yalnızca imkânsız/manipüle edilmiş değerleri yakalamak. Eşikler bilerek geniştir.
const LIMITS = {
  maxPlayerCash: 1e13,          // 10 trilyon TL — akıl sağlığı tavanı
  maxInventoryUnit: 1e9,        // tek envanter kalemi üst sınırı
  maxSpinRights: 50,            // çark hakkı üst sınırı
  maxProfitPerSecond: 5_000_000, // saniyede kazanılabilecek maks. kâr (çok cömert)
  profitBurstBuffer: 100_000_000, // tek kayıt döngüsündeki ani kâr payı (çark/ödül/işlem)
};

const SHOP_RULES = {
  neighborhood_shop: { name: "Mahalle Kuyumcusu", employeeCapacity: 2 },
  bazaar_shop: { name: "Çarşı Kuyumcusu", employeeCapacity: 4 },
  district_bazaar_shop: { name: "İlçe Kuyumcusu", employeeCapacity: 6 },
  city_center_shop: { name: "Şehir Merkezi Kuyumcusu", employeeCapacity: 8 },
  mall_shop: { name: "AVM Kuyumcusu", employeeCapacity: 10 },
  grand_bazaar_shop: { name: "Kapalıçarşı Kuyumcusu", employeeCapacity: 12 },
} as const;

const LIFESTYLE_ITEM_NAMES = new Set([
  "Espresso Makinesi",
  "Kulaklık",
  "PS6",
  "Drone",
  "Akıllı Telefon",
  "Fotoğraf Makinesi",
  "Akıllı TV (85\")",
  "Laptop",
  "Akıllı Ev Sistemi",
  "Kol Saati",
  "Bisiklet",
  "Motosiklet",
  "Bütçe Araç",
  "Orta Sınıf Araç",
  "SUV",
  "Tekne",
  "Lüks Sedan",
  "Spor Araba",
  "Yat",
  "Helikopter",
  "Stüdyo Daire",
  "1+1 Daire",
  "2+1 Apartman Dairesi",
  "3+1 Geniş Daire",
  "Lüks Site Dairesi",
  "Villa",
  "Tripleks",
  "Villa Sitesi",
  "Köşk",
  "Malikane",
  "Tasarım Güneş Gözlüğü",
  "Özel Takım Elbise",
  "Lüks El Çantası",
  "Kürk Kaban",
  "Pırlanta Kolye",
  "Özel Şarap Koleksiyonu",
  "VIP Kulüp Üyeliği",
  "İsviçre Saati",
  "Sanat Eseri",
  "Private Jet Payı",
  "Yurt İçi Tatil",
  "Dalış Kursu",
  "Michelin Yıldızlı Akşam",
  "Özel Konser Koltuğu",
  "Avrupa Turu",
  "Dubai Tatili",
  "F1 Yarışı",
  "Maldivler",
  "Dünya Turu",
  "Uzay Yolculuğu",
]);

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
    tax_debt?: number;
    last_tax_charged_day?: number;
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
    profit_day_anchor_at?: string | null;
    save_revision?: number;
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

    const rawBody = await req.json() as SaveRequest;
    const body = normalizeSaveRequest(rawBody);
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
    const existingStats = await fetchExistingStats(supabase, userId);
    const validationError = validateSaveRequest(body, existingStats);
    if (validationError) {
      return json({ success: false, error: validationError }, 400);
    }

    // Bayat kayıt önce conflict olarak dönmeli. Aksi halde eski cihazdan gelen
    // kayıt anti-cheat'e takılıp client'ın otomatik bulut yükleme akışını bozabilir.
    if (existingStats &&
        Number(body.stats.save_revision ?? 0) < Number(existingStats.save_revision ?? 0)) {
      return json({ success: false, error: "revision_conflict" });
    }

    // Delta-bazlı plausibility: bir önceki kayıttan bu yana total_profit ne kadar
    // arttı? Sunucu saatiyle geçen süreye göre imkânsız sıçramaları reddet.
    const plausibilityError = validateProfitDelta(existingStats, body.stats);
    if (plausibilityError) {
      return json({ success: false, error: plausibilityError }, 400);
    }

    const { data: saveResult, error: rpcError } = await supabase.rpc("save_game_state_v1", {
      p_user_id: userId,
      p_stats: body.stats,
      p_owned_shops: body.owned_shops,
      p_lifestyle_items: body.lifestyle_items,
    });
    if (rpcError) throw rpcError;

    // Gelen kayıt bayat (save_revision buluttakinden küçük) → client güncel veriyi çekmeli.
    if (saveResult === "conflict") {
      return json({ success: false, error: "revision_conflict" });
    }

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

function normalizeSaveRequest(body: SaveRequest): SaveRequest {
  return {
    ...body,
    stats: {
      ...body.stats,
      shop_name: String(body.stats?.shop_name ?? "").trim(),
      tax_debt: Number.isFinite(body.stats?.tax_debt) ? body.stats.tax_debt : 0,
      last_tax_charged_day: Number.isInteger(body.stats?.last_tax_charged_day) ? body.stats.last_tax_charged_day : 0,
      profit_day_anchor_at: body.stats?.profit_day_anchor_at ?? null,
      save_revision: Number.isFinite(body.stats?.save_revision) ? body.stats.save_revision : 0,
    },
  };
}

function validateSaveRequest(body: SaveRequest, existingStats: ExistingStats | null): string | null {
  const stats = body.stats;
  if (!stats.shop_name) {
    return "Invalid shop_name";
  }
  if (stats.shop_name.toLocaleLowerCase("tr-TR") === "misafir") {
    // Geçiş dönemi: eski Misafir hesaplar v1.7 forced-rename'e kadar save alabilsin,
    // fakat yeni Misafir oluşumu ve normal isimden Misafir'e dönüş engellensin.
    if (!existingStats) {
      return "Reserved shop_name";
    }
    if (String(existingStats.shop_name ?? "").toLocaleLowerCase("tr-TR") !== "misafir") {
      return "Reserved shop_name";
    }
  }

  const nonNegativeNumericFields: Array<[string, number]> = [
    ["player_cash", stats.player_cash],
    ["inventory_usd", stats.inventory_usd],
    ["inventory_eur", stats.inventory_eur],
    ["inventory_gram", stats.inventory_gram],
    ["inventory_quarter", stats.inventory_quarter],
    ["inventory_half", stats.inventory_half],
    ["inventory_full", stats.inventory_full],
    ["entry_rights_remaining", stats.entry_rights_remaining],
    ["spin_rights_remaining", stats.spin_rights_remaining],
    ["tax_debt", stats.tax_debt],
    ["last_tax_charged_day", stats.last_tax_charged_day],
    ["current_day", stats.current_day],
    ["passive_income_balance", stats.passive_income_balance],
    ["total_transactions", stats.total_transactions],
    ["accepted_deals", stats.accepted_deals],
    ["rejected_deals", stats.rejected_deals],
    ["lifestyle_score", stats.lifestyle_score],
    ["yesterday_cash", stats.yesterday_cash],
    ["daily_reward_day", stats.daily_reward_day],
    ["save_revision", stats.save_revision],
  ];

  for (const [field, value] of nonNegativeNumericFields) {
    if (!Number.isFinite(value) || value < 0) {
      return `Invalid numeric field: ${field}`;
    }
  }

  const signedNumericFields: Array<[string, number]> = [
    ["total_profit", stats.total_profit],
    ["daily_profit", stats.daily_profit],
    ["weekly_profit", stats.weekly_profit],
    ["monthly_revenue", stats.monthly_revenue],
  ];

  for (const [field, value] of signedNumericFields) {
    if (!Number.isFinite(value)) {
      return `Invalid numeric field: ${field}`;
    }
  }

  if (!Number.isInteger(stats.current_day) || stats.current_day < 1) {
    return "Invalid current_day";
  }
  if (!Number.isInteger(stats.last_tax_charged_day) || stats.last_tax_charged_day < 0) {
    return "Invalid last_tax_charged_day";
  }
  if (!Number.isInteger(stats.daily_reward_day) || stats.daily_reward_day > 7) {
    return "Invalid daily_reward_day";
  }
  if (!Number.isInteger(stats.entry_rights_remaining) || stats.entry_rights_remaining > 3) {
    return "Invalid entry_rights_remaining";
  }
  if (!Number.isInteger(stats.total_transactions) ||
      !Number.isInteger(stats.accepted_deals) ||
      !Number.isInteger(stats.rejected_deals) ||
      stats.accepted_deals + stats.rejected_deals > stats.total_transactions) {
    return "Invalid transaction counters";
  }
  if (!Number.isInteger(stats.save_revision)) {
    return "Invalid save_revision";
  }

  // Mutlak akıl sağlığı tavanları — meşru oynanışta asla tetiklenmez.
  if (stats.player_cash > LIMITS.maxPlayerCash) {
    return "Implausible player_cash";
  }
  if (stats.spin_rights_remaining > LIMITS.maxSpinRights) {
    return "Invalid spin_rights_remaining";
  }
  const inventoryFields: Array<[string, number]> = [
    ["inventory_usd", stats.inventory_usd],
    ["inventory_eur", stats.inventory_eur],
    ["inventory_gram", stats.inventory_gram],
    ["inventory_quarter", stats.inventory_quarter],
    ["inventory_half", stats.inventory_half],
    ["inventory_full", stats.inventory_full],
  ];
  for (const [field, value] of inventoryFields) {
    if (value > LIMITS.maxInventoryUnit) {
      return `Implausible ${field}`;
    }
  }

  const ownedShopKeys = new Set<string>();
  for (const shop of body.owned_shops) {
    const rule = SHOP_RULES[shop.shop_key as keyof typeof SHOP_RULES];
    if (!rule) {
      return `Invalid shop_key: ${shop.shop_key}`;
    }
    if (shop.shop_name !== rule.name) {
      return `Shop name mismatch for key: ${shop.shop_key}`;
    }
    if (!Number.isInteger(shop.employee_count) || shop.employee_count < 0 || shop.employee_count > rule.employeeCapacity) {
      return `Invalid employee_count for shop: ${shop.shop_key}`;
    }
    if (ownedShopKeys.has(shop.shop_key)) {
      return `Duplicate owned shop: ${shop.shop_key}`;
    }
    ownedShopKeys.add(shop.shop_key);
  }

  if (stats.active_shop_key && !ownedShopKeys.has(stats.active_shop_key)) {
    return "active_shop_key must belong to owned_shops";
  }

  const lifestyleNames = new Set<string>();
  for (const item of body.lifestyle_items) {
    if (!LIFESTYLE_ITEM_NAMES.has(item.item_name)) {
      return `Invalid lifestyle item: ${item.item_name}`;
    }
    if (lifestyleNames.has(item.item_name)) {
      return `Duplicate lifestyle item: ${item.item_name}`;
    }
    lifestyleNames.add(item.item_name);
  }

  return null;
}

type ExistingStats = {
  shop_name: string | null;
  total_profit: number | null;
  updated_at: string | null;
  save_revision: number | null;
};

// deno-lint-ignore no-explicit-any
async function fetchExistingStats(
  supabase: any,
  userId: string,
): Promise<ExistingStats | null> {
  const { data, error } = await supabase
    .from("player_stats")
    .select("shop_name, total_profit, updated_at, save_revision")
    .eq("user_id", userId)
    .maybeSingle();

  // Yeni oyuncu (kayıt yok) veya okuma hatası → kontrolleri atla (bloke etme).
  if (error || !data) {
    return null;
  }

  return data as ExistingStats;
}

function validateProfitDelta(
  prev: ExistingStats | null,
  stats: SaveRequest["stats"],
): string | null {
  if (!prev) {
    return null;
  }

  const prevProfit = Number(prev.total_profit ?? 0);
  const prevTime = prev.updated_at ? new Date(prev.updated_at).getTime() : Date.now();
  const elapsedSec = Math.max(0, (Date.now() - prevTime) / 1000);
  const maxGain = elapsedSec * LIMITS.maxProfitPerSecond + LIMITS.profitBurstBuffer;

  // Not: total_profit reset (resetGame) ile düşebilir; azalışlar reddedilmez.
  if (stats.total_profit - prevProfit > maxGain) {
    return "Implausible profit increase";
  }

  return null;
}

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
