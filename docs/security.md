# Security checklist

- Validate identity server-side for every protected endpoint.
- Keep service-role keys and Cloudflare API tokens out of client code and Git.
- Keep CORS allowlists exact; do not combine wildcard origins with credentials.
- Add rate limiting, abuse monitoring, quotas, and idempotency before launch.
- Add authorization rules for shared spaces and invitations before enabling them.
- Room IDs are identifiers, not authorization tokens.
- Implement short-lived, scoped media tokens and review signaling security.
- Define metadata and logs retention/deletion; avoid unsupported claims such as “no data collected.”
- Test RLS for owner, member, unrelated user, and anonymous access.
- Review dependency vulnerabilities, privacy disclosures, and penetration test results before production.
