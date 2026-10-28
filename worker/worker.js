/**
 * Harmony Worker API starter.
 *
 * Supports health checks and a room metadata API backed by Supabase.
 * Requires Supabase JWTs in Authorization: Bearer <access_token>.
 * This is room coordination only; it does not implement WebRTC media/SFU.
 */
const JSON_HEADERS = {
  "content-type": "application/json; charset=utf-8",
  "cache-control": "no-store",
  "x-content-type-options": "nosniff",
};

function response(data, status = 200, extraHeaders = {}) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...JSON_HEADERS, ...extraHeaders },
  });
}

function corsHeaders(request, env) {
  const origin = request.headers.get("Origin");
  const allowed = (env.ALLOWED_ORIGINS || "").split(",").map((v) => v.trim()).filter(Boolean);
  // No wildcard credentials. Requests without Origin are allowed for server-to-server calls.
  const headers = { "vary": "Origin" };
  if (origin && allowed.includes(origin)) {
    headers["access-control-allow-origin"] = origin;
    headers["access-control-allow-methods"] = "GET,POST,OPTIONS";
    headers["access-control-allow-headers"] = "authorization,content-type";
    headers["access-control-max-age"] = "86400";
  }
  return headers;
}

async function getUser(request, env) {
  const auth = request.headers.get("Authorization") || "";
  const token = auth.startsWith("Bearer ") ? auth.slice(7) : "";
  if (!token || !env.SUPABASE_URL || !env.SUPABASE_ANON_KEY) return null;

  const res = await fetch(`${env.SUPABASE_URL}/auth/v1/user`, {
    headers: {
      "authorization": `Bearer ${token}`,
      "apikey": env.SUPABASE_ANON_KEY,
    },
  });
  if (!res.ok) return null;
  const user = await res.json();
  return user && user.id ? user : null;
}

async function supabaseRequest(env, path, init = {}) {
  const headers = new Headers(init.headers || {});
  headers.set("apikey", env.SUPABASE_ANON_KEY);
  headers.set("authorization", `Bearer ${env.SUPABASE_ANON_KEY}`);
  headers.set("content-type", "application/json");
  return fetch(`${env.SUPABASE_URL}/rest/v1/${path}`, { ...init, headers });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const cors = corsHeaders(request, env);

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: cors });
    }
    if (url.pathname === "/health" && request.method === "GET") {
      return response({ ok: true, service: "harmony-worker" }, 200, cors);
    }
    if (!url.pathname.startsWith("/api/")) {
      return response({ error: "not_found" }, 404, cors);
    }

    const user = await getUser(request, env);
    if (!user) return response({ error: "unauthorized" }, 401, cors);

    if (url.pathname === "/api/rooms" && request.method === "GET") {
      const query = new URLSearchParams({
        select: "room_id,space_id,host_user_id,room_type,created_at,ended_at",
        host_user_id: `eq.${user.id}`,
        order: "created_at.desc",
        limit: "100",
      });
      const res = await supabaseRequest(env, `harmony_rooms?${query.toString()}`);
      if (!res.ok) return response({ error: "room_list_failed" }, 502, cors);
      return new Response(await res.text(), { status: 200, headers: { ...JSON_HEADERS, ...cors } });
    }

    if (url.pathname === "/api/rooms" && request.method === "POST") {
      let body;
      try { body = await request.json(); } catch { return response({ error: "invalid_json" }, 400, cors); }
      const roomType = body?.room_type;
      if (!["video", "audio", "screen"].includes(roomType)) {
        return response({ error: "invalid_room_type" }, 400, cors);
      }
      const payload = {
        host_user_id: user.id,
        room_type: roomType,
        ...(typeof body.space_id === "string" ? { space_id: body.space_id } : {}),
      };
      const res = await supabaseRequest(env, "harmony_rooms", {
        method: "POST",
        headers: { "prefer": "return=representation" },
        body: JSON.stringify(payload),
      });
      if (!res.ok) return response({ error: "room_create_failed" }, 502, cors);
      const rows = await res.json();
      return response(rows?.[0] || null, 201, cors);
    }

    return response({ error: "not_found" }, 404, cors);
  },
};
