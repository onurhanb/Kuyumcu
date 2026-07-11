// Supabase Edge Function — generate-social-feed
// Scheduled independently from fetch-gold-rates.
// Suggested schedule: 50 4 * * * (04:50 UTC = 07:50 TR)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const TIME_ZONE = "Europe/Istanbul";

type PlayerStats = {
  user_id: string;
  shop_name: string;
  total_profit: number;
  daily_profit: number;
  total_transactions: number;
  rejected_deals: number;
};

type DailyWinners = {
  profit: DailyMetric | null;
  trades: DailyMetric | null;
  rejected: DailyMetric | null;
  hasBaseline: boolean;
};

type DailyMetric = {
  shop_name: string;
  value: number;
};

Deno.serve(async (_req) => {
  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const now = new Date();
    const feedDate = dateInTimeZone(now, TIME_ZONE);
    const previousSnapshotDate = await fetchPreviousSnapshotDate(supabase, feedDate);
    const currentStats = await fetchCurrentStats(supabase);

    await upsertMetricSnapshot(supabase, feedDate, currentStats);

    const { data: existingPost, error: existingError } = await supabase
      .from("social_feed_posts")
      .select("id")
      .eq("post_type", "daily_recap")
      .eq("metadata->>feed_date", feedDate)
      .maybeSingle();
    if (existingError) throw existingError;

    await cleanupOldAutomaticPosts(supabase, now);

    if (existingPost) {
      return json({ success: true, skipped: "daily_recap_exists", feed_date: feedDate });
    }

    const winners = await calculateDailyWinners(supabase, currentStats, previousSnapshotDate);
    const body = buildDailyRecapBody(feedDate, winners);

    const { error: insertError } = await supabase
      .from("social_feed_posts")
      .insert({
        post_type: "daily_recap",
        author_name: "Kuyumcu Güncel",
        author_handle: "@kuyumcugnc",
        author_avatar_key: "kuyumcu_guncel",
        body,
        metadata: {
          feed_date: feedDate,
          profit_winner: winners.profit?.shop_name ?? null,
          trade_winner: winners.trades?.shop_name ?? null,
          rejected_winner: winners.rejected?.shop_name ?? null,
          has_baseline: winners.hasBaseline,
          previous_snapshot_date: previousSnapshotDate,
        },
        published_at: now.toISOString(),
        expires_at: addDays(now, 7).toISOString(),
      });
    if (insertError) throw insertError;

    return json({ success: true, feed_date: feedDate });
  } catch (error) {
    console.error("generate-social-feed error:", error);
    return json({ success: false, error: String(error) }, 500);
  }
});

// deno-lint-ignore no-explicit-any
async function fetchCurrentStats(supabase: any): Promise<PlayerStats[]> {
  const { data, error } = await supabase
    .from("player_stats")
    .select("user_id, shop_name, total_profit, daily_profit, total_transactions, rejected_deals");
  if (error) throw error;
  return (data ?? []) as PlayerStats[];
}

// deno-lint-ignore no-explicit-any
async function fetchPreviousSnapshotDate(supabase: any, feedDate: string): Promise<string | null> {
  const { data, error } = await supabase
    .from("social_feed_player_snapshots")
    .select("snapshot_date")
    .lt("snapshot_date", feedDate)
    .order("snapshot_date", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (error) throw error;
  return data?.snapshot_date ?? null;
}

// deno-lint-ignore no-explicit-any
async function upsertMetricSnapshot(
  supabase: any,
  feedDate: string,
  stats: PlayerStats[],
): Promise<void> {
  const rows = stats.map((stat) => ({
    snapshot_date: feedDate,
    user_id: stat.user_id,
    shop_name: stat.shop_name,
    total_profit: Number(stat.total_profit ?? 0),
    daily_profit: Number(stat.daily_profit ?? 0),
    total_transactions: Number(stat.total_transactions ?? 0),
    rejected_deals: Number(stat.rejected_deals ?? 0),
  }));

  if (rows.length === 0) return;

  const { error } = await supabase
    .from("social_feed_player_snapshots")
    .upsert(rows, { onConflict: "snapshot_date,user_id", ignoreDuplicates: true });
  if (error) throw error;
}

// deno-lint-ignore no-explicit-any
async function calculateDailyWinners(
  supabase: any,
  currentStats: PlayerStats[],
  previousSnapshotDate: string | null,
): Promise<DailyWinners> {
  if (!previousSnapshotDate) {
    return {
      profit: null,
      trades: null,
      rejected: null,
      hasBaseline: false,
    };
  }

  const { data, error } = await supabase
    .from("social_feed_player_snapshots")
    .select("user_id, total_profit, total_transactions, rejected_deals")
    .eq("snapshot_date", previousSnapshotDate);
  if (error) throw error;

  const previousByUser = new Map<string, { total_profit: number; total_transactions: number; rejected_deals: number }>();
  for (const row of data ?? []) {
    previousByUser.set(row.user_id, {
      total_profit: Number(row.total_profit ?? 0),
      total_transactions: Number(row.total_transactions ?? 0),
      rejected_deals: Number(row.rejected_deals ?? 0),
    });
  }

  const tradeMetrics: DailyMetric[] = [];
  const rejectedMetrics: DailyMetric[] = [];
  const profitMetrics: DailyMetric[] = [];

  for (const stat of currentStats) {
    const previous = previousByUser.get(stat.user_id);
    const totalProfit = Number(stat.total_profit ?? 0);
    const totalTransactions = Number(stat.total_transactions ?? 0);
    const rejectedDeals = Number(stat.rejected_deals ?? 0);
    const profitDelta = Math.max(0, totalProfit - Number(previous?.total_profit ?? 0));
    const transactionDelta = Math.max(0, totalTransactions - Number(previous?.total_transactions ?? 0));
    const rejectedDelta = Math.max(0, rejectedDeals - Number(previous?.rejected_deals ?? 0));

    tradeMetrics.push({ shop_name: stat.shop_name, value: transactionDelta });
    rejectedMetrics.push({ shop_name: stat.shop_name, value: rejectedDelta });
    profitMetrics.push({ shop_name: stat.shop_name, value: profitDelta });
  }

  return {
    profit: topMetric(profitMetrics),
    trades: topMetric(tradeMetrics),
    rejected: topMetric(rejectedMetrics),
    hasBaseline: true,
  };
}

function topMetric(metrics: DailyMetric[]): DailyMetric | null {
  const positiveMetrics = metrics.filter((metric) => metric.value > 0);
  if (positiveMetrics.length === 0) return null;
  return positiveMetrics.sort((lhs, rhs) => rhs.value - lhs.value)[0];
}

function buildDailyRecapBody(feedDate: string, winners: DailyWinners): string {
  const dateText = formatFeedDate(feedDate);
  if (!winners.hasBaseline) {
    return [
      `${dateText} Kuyumcular Bülteni`,
      "",
      "📊 Bugün ilk ölçüm alındı.",
      "Yarınki bültende gerçek günlük liderler paylaşılacak.",
    ].join("\n");
  }

  return [
    `${dateText} Kuyumcular Bülteni`,
    "",
    "🏆 En çok kâr eden",
    metricLine(winners.profit, "₺"),
    "",
    "🤝 En çok al sat yapan",
    metricLine(winners.trades, "işlem"),
    "",
    "🚫 En çok teklifi reddedilen",
    metricLine(winners.rejected, "red"),
  ].join("\n");
}

function metricLine(metric: DailyMetric | null, suffix: "₺" | "işlem" | "red"): string {
  if (!metric) return "Henüz veri yok";
  if (suffix === "₺") {
    return `${metric.shop_name} - ${formatTRY(metric.value)}`;
  }
  return `${metric.shop_name} - ${Math.round(metric.value)} ${suffix}`;
}

function formatTRY(value: number): string {
  return new Intl.NumberFormat("tr-TR", {
    style: "currency",
    currency: "TRY",
    maximumFractionDigits: 0,
  }).format(value);
}

function formatFeedDate(feedDate: string): string {
  const [year, month, day] = feedDate.split("-").map((part) => Number.parseInt(part, 10));
  const date = new Date(Date.UTC(year, month - 1, day, 12));
  return new Intl.DateTimeFormat("tr-TR", {
    timeZone: TIME_ZONE,
    day: "numeric",
    month: "long",
  }).format(date);
}

// deno-lint-ignore no-explicit-any
async function cleanupOldAutomaticPosts(supabase: any, now: Date): Promise<void> {
  const cutoff = addDays(now, -7).toISOString();
  const { error } = await supabase
    .from("social_feed_posts")
    .delete()
    .eq("post_type", "daily_recap")
    .lt("published_at", cutoff);
  if (error) throw error;
}

function dateInTimeZone(date: Date, timeZone: string): string {
  return new Intl.DateTimeFormat("en-CA", { timeZone }).format(date);
}

function addDays(date: Date, days: number): Date {
  const next = new Date(date);
  next.setUTCDate(next.getUTCDate() + days);
  return next;
}

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
