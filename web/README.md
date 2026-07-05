# Tumble — Waitlist site

Pre-launch landing page for Tumble. Single Next.js page (App Router + TypeScript
+ Tailwind v4) that captures waitlist emails into Firestore. Deploys to Vercel at
**gettumbleapp.com**.

## Local development

```bash
cd web
npm install
cp .env.example .env.local   # then fill in real Firebase creds (see below)
npm run dev                  # http://localhost:3000
```

The page renders fully without Firebase config; only the actual email write needs
it. Without config, submitting shows a graceful "something went wrong" message.

## Firebase setup (required for waitlist writes)

1. Create a Firebase project (or reuse one) at <https://console.firebase.google.com>.
2. Build → **Firestore Database** → Create database (production mode is fine — we
   write through the site API, and Firestore rules restrict what can be created).
3. Project Settings → **General** → your web app → copy the `apiKey`.
4. Copy these fields into `.env.local`:
   - Firebase project ID → `FIREBASE_PROJECT_ID`
   - Web app `apiKey` → `FIREBASE_WEB_API_KEY`
5. In Firestore → **Rules**, publish rules that only allow creating waitlist docs.

Emails land in the `waitlist` collection, one document per email (keyed by the
normalized email, so repeat signups are idempotent).

## Deploy to Vercel

1. Push this repo to GitHub (the site lives in the `web/` subdirectory).
2. In Vercel → New Project → import the repo.
3. **Set Root Directory to `web`** (Settings → General → Root Directory).
4. Add the two `FIREBASE_*` environment variables (Settings → Environment
   Variables) for Production (and Preview if you want).
5. Deploy.
6. Add the custom domain **gettumbleapp.com** (Settings → Domains) and follow
   Vercel's DNS instructions at your registrar.

## What's a placeholder (swap before/at launch)

- App Store badge + QR are greyed "coming soon" — no live listing yet.
- `/privacy` and `/terms` are short placeholders.
- Support email `aftaab@aftab.dev` — change it in `src/components/Footer.tsx`
  and the legal pages if a dedicated inbox is added later.
- Device-support line ("supported devices confirmed at launch") — finalize once
  the iOS minimum is known.
```
