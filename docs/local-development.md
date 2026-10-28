# Local development

## Web app
1. Install Node.js 20 or newer.
2. From repository root run `npm install`.
3. Copy `.env.example` to `.env` and fill in your public Supabase URL/anon key and Worker URL.
4. Run `npm run dev`; open the URL Vite prints.

The current web demo can generate a local demo room ID and request a local camera preview. It does not establish a remote call.

## Worker
1. `cd worker`
2. `npm install`
3. Copy `.dev.vars.example` to `.dev.vars` and configure the values.
4. `npm run dev`

Do not use production credentials for local development.

## Tests
From the repository root, run `npm test` and `npm run typecheck`.
