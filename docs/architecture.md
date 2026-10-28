# Architecture

## Components
- **Web/mobile/desktop clients:** UI, local media capture, QR/invite entry and client-side state.
- **Cloudflare Worker:** HTTP API entry point, validates Supabase access tokens, and coordinates room metadata.
- **Supabase Auth:** user identity and access tokens.
- **Supabase Postgres:** room and space metadata with row-level security.
- **Media plane:** not implemented in this starter. Real-time media needs WebRTC signaling and STUN/TURN; multi-party scale commonly requires an SFU.

## Request flow
1. Client authenticates through Supabase Auth.
2. Client calls Worker with `Authorization: Bearer <access_token>`.
3. Worker verifies the token through Supabase Auth's user endpoint.
4. Worker uses the public anon key to call the Supabase REST API with host ownership enforced by RLS.
5. Worker returns room metadata; media joining must be separately implemented.

## Delivery model
Static assets may be delivered through a CDN. API/coordination requests go to the Worker. P2P traffic is only possible where peers can connect; TURN relays or an SFU may incur infrastructure costs. Do not promise a universal $0 P2P path or fixed cost without workload measurements.
