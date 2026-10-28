# Implementation status

| Area | Status | Notes |
|---|---|---|
| Vite/React app shell | Starter implemented | Local UI, QR rendering |
| Worker health endpoint | Starter implemented | `/health` |
| Room metadata list/create | Starter implemented | Verifies Supabase access token; host ownership via RLS |
| Supabase schema/RLS | Starter implemented | Host-only room policies; shared-space auth needs work |
| Web camera preview | Starter implemented | Local preview only; no remote media |
| QR join and QR parsing | Starter implemented | Parses IDs/URLs; does not authorize room access |
| Mobile API/QR/retry helpers | Starter implemented | Integration helpers, not a native app |
| Tauri shell | Scaffold only | Needs Tauri config/dependencies |
| WebRTC signaling | Not implemented | Required for peer connections |
| TURN/SFU/media plane | Not implemented | Required for reliable production calls |
| Invite issuance/consumption | Not implemented | Needs secure server-side flow |
| Production CI/observability | Not implemented | Add before release |
