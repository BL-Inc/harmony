# Remaining production work

1. **Authentication UX:** add sign-in/sign-out and session refresh using Supabase Auth.
2. **Room authorization:** validate space membership for any `space_id`; the current host-only room policy does not implement shared room membership.
3. **Invite service:** create one-time hashed invite tokens with expiry, abuse limits, and atomic consumption.
4. **Media signaling:** implement authenticated WebSocket signaling and room presence.
5. **WebRTC:** add ICE negotiation and STUN/TURN configuration; use an SFU for reliable multi-party calls.
6. **Mobile app:** add real native Android/iOS projects, permission flows, secure storage, and background handling.
7. **Desktop:** configure Tauri v2, capabilities, CSP, signed updates, and opt-in relay controls.
8. **Data lifecycle:** add retention, account deletion, export, audit, and privacy disclosures.
9. **Reliability:** add integration tests, rate limiting, structured logs, metrics, alerting, and load tests.
10. **Cost model:** benchmark CDN egress, Worker requests, database usage, TURN/SFU traffic, and storage. Do not promise fixed costs without measured workloads.
