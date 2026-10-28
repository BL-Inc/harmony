#!/bin/bash
# Harmony Hybrid CDN Edition - One-command setup
# Usage: bash setup_harmony.sh inside git repo root

set -e
echo "=== Harmony Hybrid CDN Setup ==="

# 1. Worker - Hybrid CDN Router
mkdir -p worker
cat > worker/worker.js <<'JS'
// Harmony Worker - Hybrid CDN Blazing + Cloudflare + P2P $0
// Routes: STATIC -> Blazing $1/TB, REALTIME -> Cloudflare $5/1000min, P2P -> $0

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;

    // CORS for B2B+B2C one chat
    const cors = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization"
    };
    if (request.method === "OPTIONS") return new Response(null, { headers: cors });

    // HEALTH
    if (path === "/health") {
      return Response.json({ ok: true, cdn: "hybrid", static: "blazing $1/TB", realtime: "cloudflare $5/1000", p2p: "$0" }, { headers: cors });
    }

    // ROOM METADATA API -> Supabase (pointer only, no blob - Privacy: Data Not Collected)
    if (path.startsWith("/api/rooms")) {
      if (!env.SUPABASE_URL || !env.SUPABASE_KEY) {
        return Response.json({ error: "SUPABASE not configured" }, { status: 500, headers: cors });
      }
      const auth = request.headers.get("Authorization");
      if (!auth && request.method !== "GET") return Response.json({ error: "auth required" }, { status: 401, headers: cors });

      // Proxy to Supabase with RLS - host owns rooms
      const supabaseUrl = `${env.SUPABASE_URL}/rest/v1/${path.replace("/api/","")} `;
      const res = await fetch(supabaseUrl + url.search, {
        method: request.method,
        headers: { "apikey": env.SUPABASE_KEY, "Authorization": auth || "", "Content-Type": "application/json" },
        body: request.method !== "GET" ? await request.text() : null
      });
      const data = await res.text();
      return new Response(data, { status: res.status, headers: { ...cors, "Content-Type": "application/json" } });
    }

    // CDN ROUTER
    if (path.startsWith("/cdn/")) {
      const type = url.searchParams.get("type"); // static | realtime | p2p
      const roomId = url.searchParams.get("room");
      
      if (type === "static") {
        // Blazing CDN $1/TB - serve from R2 / Bunny via cache
        return Response.json({ route: "blazing", cost: "$1/TB", cache: "HIT", url: `https://blazing.harmony.cdn${path}` }, { headers: cors });
      }
      if (type === "realtime") {
        // Cloudflare Calls $5/1000 min - SFU
        return Response.json({ route: "cloudflare-calls", cost: "$5/1000 min", roomId, sfu: true }, { headers: cors });
      }
      if (type === "p2p") {
        // WebRTC P2P $0 - local-first, PC super-node
        return Response.json({ route: "p2p", cost: "$0", ice: "stun:stun.cloudflare.com:3478", superNode: "desktop" }, { headers: cors });
      }
      // Auto-select: <3 peers -> P2P $0, 3-20 -> Blazing, >20 -> Cloudflare
      const peers = parseInt(url.searchParams.get("peers") || "0");
      if (peers <= 2) return Response.json({ route: "p2p", reason: "peers<=2 => $0" }, { headers: cors });
      if (peers <= 20) return Response.json({ route: "blazing", reason: "peers<=20 => $1/TB" }, { headers: cors });
      return Response.json({ route: "cloudflare", reason: "peers>20 => SFU" }, { headers: cors });
    }

    return Response.json({ error: "not found" }, { status: 404, headers: cors });
  }
}
JS

cat > worker/wrangler.toml <<'TOML'
name = "harmony-worker"
main = "worker.js"
compatibility_date = "2024-01-01"
compatibility_flags = ["nodejs_compat"]

[vars]
SUPABASE_URL = "https://YOUR_PROJECT.supabase.co"
CF_ACCOUNT_ID = "YOUR_CF_ID"

# Secrets: set via wrangler secret put SUPABASE_KEY
# wrangler secret put SUPABASE_ANON_KEY
# wrangler secret put CF_API_TOKEN

[observability]
enabled = true
TOML

cat > worker/package.json <<'JSON'
{
  "name": "harmony-worker",
  "type": "module",
  "scripts": { "dev": "wrangler dev", "deploy": "wrangler deploy" },
  "devDependencies": { "wrangler": "^3.60.0" }
}
JSON

# 2. Supabase Schema - Privacy Not Collected
mkdir -p supabase
cat > supabase/harmony_rooms.sql <<'SQL'
-- Harmony Rooms - Pointer Only, No Blob Storage
-- Privacy: Data Not Collected - we store only pointers

create table if not exists harmony_spaces (
  space_id text primary key,
  owner_id text not null,
  name text,
  created_at timestamptz default now()
);

create table if not exists harmony_rooms (
  room_id text primary key,
  cf_room_id text,
  space_id text references harmony_spaces(space_id),
  host_user_id text not null,
  type text check (type in ('video','audio','screen')) default 'video',
  duration_secs int default 0,
  cdn_route text check (cdn_route in ('blazing','cloudflare','p2p')) default 'p2p',
  cost_tier text,
  created_at timestamptz default now(),
  ended_at timestamptz
);

create table if not exists harmony_invites (
  inviter_id text not null,
  invitee_hash text not null,
  used bool default false,
  created_at timestamptz default now(),
  primary key (inviter_id, invitee_hash)
);

create index if not exists idx_rooms_host on harmony_rooms (host_user_id, created_at desc);
create index if not exists idx_rooms_space on harmony_rooms (space_id);

alter table harmony_rooms enable row level security;
drop policy if exists "own rooms + space membership" on harmony_rooms;
create policy "own rooms + space membership" on harmony_rooms for all using (auth.uid()::text = host_user_id);

-- Enable realtime for rooms
-- alter publication supabase_realtime add table harmony_rooms;
SQL

# 3. Web Islands - Hybrid CDN logic
mkdir -p web/islands
cat > web/islands/VideoCall.jsx <<'JSX'
import { useEffect, useRef, useState } from 'react';

// Hybrid CDN Selector: P2P $0 -> Blazing $1/TB -> Cloudflare $5/1000
export default function VideoCall({ roomId, initialPeers = 0 }) {
  const videoRef = useRef(null);
  const [cdnRoute, setCdnRoute] = useState('p2p');
  const [peers, setPeers] = useState(initialPeers);

  useEffect(() => {
    async function selectCDN() {
      const res = await fetch(`/cdn/select?peers=${peers}&room=${roomId}&type=auto`);
      const data = await res.json();
      setCdnRoute(data.route);
    }
    selectCDN();
  }, [peers, roomId]);

  useEffect(() => {
    async function startLocal() {
      try {
        const stream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });
        if (videoRef.current) videoRef.current.srcObject = stream;
      } catch (e) { console.error("media error", e); }
    }
    startLocal();
  }, []);

  return (
    <div>
      <div>Room: {roomId} | CDN: {cdnRoute} | Peers: {peers}</div>
      <video ref={videoRef} autoPlay muted playsInline style={{ width: '100%' }} />
      <div>Cost: {cdnRoute==='p2p'?'$0': cdnRoute==='blazing'?'$1/TB':'$5/1000min'}</div>
    </div>
  );
}
JSX

cat > web/islands/QRJoin.jsx <<'JSX'
import { useState } from 'react';
import QRCode from 'qrcode.react';

export default function QRJoin({ roomId }) {
  const joinUrl = `${window.location.origin}/join?room=${roomId}`;
  const [copied, setCopied] = useState(false);
  return (
    <div style={{ textAlign: 'center' }}>
      <QRCode value={joinUrl} size={200} />
      <p>{joinUrl}</p>
      <button onClick={() => { navigator.clipboard.writeText(joinUrl); setCopied(true); }}>
        {copied ? 'Copied!' : 'Copy Link'}
      </button>
      <p>B2B+B2C one chat - local-first, PC super-node fallback</p>
    </div>
  );
}
JSX

# 4. Mobile Services
mkdir -p mobile/src/services mobile/src/db
cat > mobile/src/services/VideoService.ts <<'TS'
export class VideoService {
  // Hybrid CDN logic for mobile
  async getCDNRoute(peers: number, roomId: string) {
    if (peers <= 2) return { route: 'p2p', cost: '$0', transport: 'webrtc' };
    if (peers <= 20) return { route: 'blazing', cost: '$1/TB', transport: 'r2-cache' };
    return { route: 'cloudflare', cost: '$5/1000min', transport: 'sfu' };
  }
  async joinRoom(roomId: string) {
    const route = await this.getCDNRoute(0, roomId);
    console.log(`Joining ${roomId} via ${route.route} (${route.cost})`);
    return route;
  }
}
TS

cat > mobile/src/services/QRService.ts <<'TS'
export class QRService {
  parseQR(data: string): { roomId: string, spaceId?: string } | null {
    try {
      const url = new URL(data);
      const roomId = url.searchParams.get('room') || url.searchParams.get('roomId') || '';
      const spaceId = url.searchParams.get('space') || undefined;
      if (!roomId) return null;
      return { roomId, spaceId };
    } catch { return { roomId: data, spaceId: undefined }; }
  }
}
TS

cat > mobile/src/services/SyncService.ts <<'TS'
export class SyncService {
  // Local-first sync - no blob storage, only pointers
  async syncRooms(userId: string) {
    // Only metadata, cost $0
    const res = await fetch(`/api/rooms?host_user_id=eq.${userId}`);
    return res.json();
  }
}
TS

# 5. Desktop Super-node (Tauri)
mkdir -p desktop/src-tauri/src
cat > desktop/src-tauri/src/main.rs <<'RS'
use tauri::Manager;

// PC Super-node - makes P2P $0 work at scale
// This desktop acts as TURN/STUN fallback when mobile peers >2
#[tauri::command]
fn get_supernode_status() -> String {
    format!("super-node active: p2p=$0, blazing=$1/TB fallback, cloudflare=$5/1000 fallback")
}

#[tauri::command]
fn route_cdn(peers: u32) -> String {
    if peers <= 2 { "p2p:$0".to_string() }
    else if peers <= 20 { "blazing:$1/TB".to_string() }
    else { "cloudflare:$5/1000".to_string() }
}

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![get_supernode_status, route_cdn])
        .run(tauri::generate_context!())
        .expect("error while running tauri");
}
RS

# 6. Docs - Architecture
mkdir -p docs
cat > docs/architecture.md <<'MD'
# Harmony Architecture - Hybrid CDN Edition

## Hybrid CDN: Blazing $1/TB + Cloudflare $5/1000 + P2P $0

Solution Flow:
1. User creates room -> Worker generates cf_room_id + Supabase pointer (no blob)
2. <3 peers: WebRTC P2P direct, cost $0, Desktop super-node as STUN if needed
3. 3-20 peers: Blazing CDN (Bunny/R2) $1/TB static + cached SFU pointers
4. >20 peers: Cloudflare Calls SFU $5/1000 min

Data Flow:
Web/Mobile -> Worker /cdn/select -> Supabase (metadata only) -> P2P/Blazing/CF
No video blobs stored anywhere -> Privacy: Data Not Collected

Security: RLS host owns rooms, invitee_hash, no recording by default
Deployment: Worker -> wrangler deploy, Web -> Vercel, Supabase -> sql file

Cost: $25-85/mo for 1000 MAU (mostly $0 P2P)
MD

cat > docs/implementation-status.md <<'MD'
# Implementation Status

Done:
- Worker router skeleton
- Supabase schema with RLS
- Web local preview
- Mobile services pointers
- Desktop super-node command

Missing for Production:
- Real Cloudflare Calls integration (create room via Calls API)
- TURN server config (cloudflare turn or self-hosted)
- Blazing CDN R2 bucket wiring
- Auth UI (Supabase Auth)
- Rate limiting
- E2E encryption
MD

echo "All files generated. Now run:"
echo "git add . && git commit -m 'feat: Hybrid CDN Blazing+CF+P2P, B2B+B2C, super-node' && git push"
