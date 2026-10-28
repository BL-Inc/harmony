# Deployment

## Supabase
1. Create a development project.
2. Apply `supabase/harmony_rooms.sql` in the SQL editor.
3. Configure Auth providers and redirect URLs.
4. Test RLS with owner, unrelated authenticated user, and anonymous sessions.

## Cloudflare Worker
1. Install Node.js and Wrangler.
2. From the repository root, run `npx wrangler deploy --config worker/wrangler.toml`.
3. Set `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `ALLOWED_ORIGINS` to real project values.
4. Restrict `ALLOWED_ORIGINS` to exact trusted origins.
5. Use a deployment secret store/CI variables for sensitive values; never commit private keys.

## Frontend
Install React and TypeScript in your existing app, then import the components under `web/islands/`.
The starter does not include a full frontend bundler setup.

## Validation
- `GET /health` returns a JSON health status.
- Unauthenticated `/api/rooms` returns 401.
- Authenticated user can list/create only their own rooms.
- Invalid room types return 400.
- Browser CORS works only from configured origins.
