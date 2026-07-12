---
name: verify
description: How to run and drive this Rails app locally to verify changes end-to-end (server, auth, admin, email evidence).
---

# Verifying changes in this app

Rails 8 + Postgres + esbuild/Tailwind. No Docker needed locally.

## Build & run

```bash
npm run build && npm run build:css        # assets (server doesn't watch)
bin/rails server -p 3457 -P /tmp/smoke.pid  # pick a free port; /up returns 200 when booted
```

## Sign in headlessly (curl)

OmniAuth `:developer` is enabled in development. Request phase requires POST + CSRF:

```bash
TOKEN=$(curl -s -c jar http://localhost:3457/ | grep -o 'name="csrf-token" content="[^"]*"' | sed 's/.*content="//;s/"//')
curl -s -b jar -c jar -X POST http://localhost:3457/auth/developer --data-urlencode "authenticity_token=$TOKEN" -o /dev/null
curl -s -b jar -c jar -X POST http://localhost:3457/auth/developer/callback -d "name=smoketest" -d "email=smoke@example.com"
```

**Gotcha:** developer login uses the email as `uid`; logging in with an *existing* user's email renames that user via `release_stale_claims!`. Always use a throwaway email, then grant admin:

```bash
bin/rails runner 'User.find_by(email: "smoke@example.com").update!(site_admin: true)'
```

Stafftools (`/stafftools/...`) 404s for non-admins — a 404 there usually means the grant didn't run.

## Form submissions via curl

Rails forms: POST with `_method=patch` + `authenticity_token` scraped from the page you're on. Don't use `curl -L -X POST` to follow redirects (it re-POSTs the redirect target); follow with a separate GET.

## Email evidence

Development uses the inline async ActiveJob adapter (Solid Queue is production-only), so `deliver_later` mail renders **in the server process log** — grep the server output for `MeetupsMailer#<method>`, `Subject:`, `To:`. Don't look in `solid_queue_jobs`.

## Seed / cleanup

The dev DB holds the user's playground data — create clearly-named throwaway records (e.g. "SMOKE ..." titles) via `bin/rails runner` and destroy them after. Meetups need: active event, its scheduling_day + location + ≥1 tag, `starts_at` in `day.valid_start_times`, future date, free `(location, starts_at)` slot. A merged source references its target via `merged_into_id` — destroy the source before the target.

## Gotchas

- `bin/rails` only works from the repo root — don't `cd` into the scratchpad.
- Pre-existing failing test on main: `meetups_mailer_test.rb` expects "Starting soon" in the reminder subject; the mailer says "OffKai Expo meetup reminder".
