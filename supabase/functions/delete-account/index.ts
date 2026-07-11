// Supabase Edge Function — delete-account
//
// Deploy: supabase functions deploy delete-account
//
// Kullanıcı JWT'sini doğrular, oyun kayıtlarını siler ve ardından Auth kullanıcısını kaldırır.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const jsonHeaders = {
  "Content-Type": "application/json",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: jsonHeaders });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ success: false, error: "Method not allowed" }),
      { status: 405, headers: jsonHeaders },
    );
  }

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.replace(/^Bearer\s+/i, "").trim();
    if (!token) {
      return new Response(
        JSON.stringify({ success: false, error: "Authorization token missing" }),
        { status: 401, headers: jsonHeaders },
      );
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const { data, error: userError } = await supabase.auth.getUser(token);
    if (userError || !data.user) {
      return new Response(
        JSON.stringify({ success: false, error: "Invalid user token" }),
        { status: 401, headers: jsonHeaders },
      );
    }

    const userId = data.user.id;

    // Tüm oyun verisini tek transaction'da sil (ya hepsi, ya hiçbiri).
    const { error: deleteError } = await supabase.rpc("delete_user_data", {
      p_user_id: userId,
    });
    if (deleteError) throw deleteError;

    const { error: authDeleteError } = await supabase.auth.admin.deleteUser(userId);
    if (authDeleteError) throw authDeleteError;

    return new Response(
      JSON.stringify({ success: true }),
      { headers: jsonHeaders },
    );
  } catch (err) {
    console.error("delete-account error:", err);
    return new Response(
      JSON.stringify({ success: false, error: String(err) }),
      { status: 500, headers: jsonHeaders },
    );
  }
});
