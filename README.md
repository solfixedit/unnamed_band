# Unnamed Band — Rehearsal HQ

A one-page site for the band: a short intro, a shared availability calendar, a rehearsal
planner with Google Maps links, and a members-only board for links and notes. Login and
data storage run on Supabase (Auth + Postgres + Realtime). There's no build step — it's a
single static HTML file.

## Files

| File | Purpose |
| --- | --- |
| `index.html` | The whole site (markup, styles, and logic in one file). |
| `supabase-schema.sql` | Creates the database tables and security rules. Run this once in Supabase. |

## 1. Set up Supabase (one-time)

1. Open your project at [supabase.com](https://supabase.com/dashboard) → **SQL Editor** → **New query**.
2. Paste the contents of `supabase-schema.sql` and click **Run**. This creates four tables
   (`profiles`, `availability`, `rehearsals`, `board_posts`) with row-level security so only
   signed-in band members can read or write data, and each member can only edit their own
   availability and their own board posts.
3. *(Optional)* **Authentication → Sign In / Providers → Email** — toggle **Confirm email**
   off if you want members to be signed in immediately after they create an account, or on
   if you want them to confirm by email first. The site handles either setting.

The Supabase project URL and public (`sb_publishable_...`) API key are already in
`index.html`. That key is meant to be public — it's safe to ship in client-side code. Access
control is enforced by the database policies from step 2, not by hiding the key.

## 2. Preview locally (optional)

Any static file server works, for example:

```bash
npx serve .
# or
python3 -m http.server 8000
```

Then open the printed URL in your browser.

## 3. Deploy to Vercel

No framework, no build command — this deploys as a static site.

### Option A: Vercel CLI (fastest)

```bash
npm install -g vercel   # skip if you already have it
cd path/to/this/folder
vercel
```

Follow the prompts (link or create a project, keep the defaults — Framework Preset:
**Other**, Build Command: none, Output Directory: `.`). Vercel prints a live URL when it's
done. Run `vercel --prod` to promote it to your production domain.

### Option B: GitHub + Vercel dashboard

1. Push this folder to a new GitHub repository.
2. In the [Vercel dashboard](https://vercel.com/new), **Import** that repository.
3. When asked for a framework, choose **Other** — leave Build Command and Output Directory
   blank/default. Click **Deploy**.
4. Every push to the repo's default branch redeploys automatically.

### After deploying

Open the Vercel URL and confirm:

- The **Home** tab loads with the band intro.
- The **Schedule** and **Board** tabs show a sign-in / sign-up screen.
- Signing up as one of the four members works, and the name you picked is no longer
  offered to the next person who signs up.
- Checking an AM/PM box on the calendar shows your name; opening the same URL in another
  browser (or getting a bandmate to sign in) shows the change without a manual refresh —
  that's Supabase Realtime.

## Updating the site later

Since it's a single file, ask for changes (wording, colors, features) and swap the updated
`index.html` into the repo — push to GitHub (auto-redeploys) or run `vercel --prod` again
if you're using the CLI.

## Troubleshooting

- **Blank page / "Couldn't load the Supabase library"** — the CDN script
  (`cdn.jsdelivr.net`) didn't load. Check your internet connection or whether something
  (an ad blocker, a restrictive network) is blocking `jsdelivr.net`.
- **"Invalid login credentials"** — wrong email/password, or the account hasn't confirmed
  its email yet (see step 1.3 above).
- **A member's name isn't offered during sign-up** — someone already claimed it. They
  should sign in instead of signing up again.
- **Changes don't appear for other members** — confirm `supabase-schema.sql` ran fully,
  including the last `alter publication supabase_realtime add table ...` line, which turns
  on live updates.
