# Harmony — Hybrid Room Collaboration Starter

This bundle contains the source files for a starter web application, a Cloudflare Worker room-metadata API, a Supabase schema, mobile service helpers, and a Tauri desktop shell.

## Run the web demo
Requires Node.js 20+.
```bash
npm install
cp .env.example .env
npm run dev
```
The UI can create a local demo room ID, render a QR code, accept a room ID, and request a local camera/microphone preview. It does **not** connect remote participants.

## Run the Worker
```bash
cd worker
npm install
cp .dev.vars.example .dev.vars
npm run dev
```
Set real Supabase project values in local `.dev.vars` and production Worker configuration. Do not commit secrets.

## Included
- Vite + React + TypeScript frontend and QR rendering
- VideoCall local media preview and QR join form
- Worker health and authenticated room list/create endpoints
- Supabase schema and host-owned room RLS policies
- Mobile API, QR parsing, and retry helpers
- Initial Tauri Rust shell
- Tests and architecture/deployment/security documentation

## Production limitations
This is not a production-ready conferencing system. Remote WebRTC signaling, TURN/SFU media transport, secure invite flows, full auth UI, mobile native projects, desktop Tauri configuration, rate limiting, monitoring, and comprehensive tests remain to be implemented. See `docs/implementation-status.md` and `docs/missing-work.md`.
