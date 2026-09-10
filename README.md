# Chojay — Journey in Bhutan (Flutter app)

The mobile companion to [journeyinbhutan.com](https://journeyinbhutan.com)
(repo `cjzang03-dev/taledesti-quest`, Next.js/TypeScript/Supabase/Vercel).
The app shares the website's Supabase project — same database, same auth,
same storage buckets — and evolves alongside it rather than replacing it.

## Status

Project setup, shared theme, Supabase bootstrap, the app's Google sign-in
gate, itinerary browsing, and the booking request flow are in place. Chat
is still a "coming soon" placeholder in the bottom-nav tab, in build
order:

1. ~~Website auth rework~~ (out of scope for this repo — see note below)
2. Schema additions for itineraries (website + app)
3. **Flutter: Google sign-in + profile — done**
4. **Flutter: itinerary browsing + detail screens — done**
5. **Flutter: booking flow — done (request-only; see below)**
6. Flutter: chat
7. Flutter: operator/guide dashboards
8. Website: admin itinerary authoring + approval screens
9. Reviews, notifications, polish

Step 4 covers: a published-itinerary catalog (`lib/features/itineraries/`),
a detail screen (hero image, day-by-day plan, indicative price shown
as-is), and the "approved operators" list (`itinerary_operators` joined to
`profiles`, filtered to `status = 'approved'`) that a tourist picks from.

Step 5 (`lib/features/bookings/`) covers: tapping an approved operator
opens a booking *request* screen — travel start date, traveler count, an
optional note, and the itinerary's indicative price shown as-is (never
recalculated per group size, per the known shared-room-pricing issue —
exact pricing is confirmed with the operator once chat exists). Submitting
writes to a **new** `itinerary_bookings` table
(`supabase/migrations/20260910_itinerary_bookings.sql`) — deliberately
separate from the website's existing `bookings` table (legacy
per-operator-package flow, exact shape unverified this session) rather
than repurposing it. **This migration has not been applied** — this
session has no Supabase credentials; review and run it yourself before
the booking flow will work against real data. The Bookings tab lists the
signed-in tourist's own requests with a status chip (requested / confirmed
/ declined / cancelled); nothing yet acts on a request beyond creating it
— operator/admin confirmation is step 7.

> **Note on scope for this session:** this session only has access to the
> `cjzang03-dev/chojay` (this) repo. The website repo
> `cjzang03-dev/taledesti-quest` and the live Supabase schema were **not
> accessible**, so the `profiles.user_type` values and table shapes used
> here (`tourist` / `guide` / `operator`, `itineraries`, `itinerary_operators`)
> are taken directly from the product spec's schema sketch, not verified
> against the actual database. Before wiring up real screens against these
> tables (build order steps 4+), confirm the live schema matches — in
> particular the exact `profiles` columns and the `payments.guide_id`
> naming bug mentioned in the spec, so this app doesn't write data the
> website's existing logic won't expect.

## Product decisions this scaffold builds to

- **Auth:** Google sign-in only, for both app and website, for now.
- **App vs. website sign-in UX differs on purpose:** the website is
  browse-first (sign-in only at booking); the app requires sign-in
  upfront, before the main experience, modeled on the speed/polish of
  Klook/Grab/Lyft's sign-in screens — not their information architecture.
- **No role dropdown for tourists.** Anyone signing in through the main
  app flow is a tourist by default (`profiles.user_type = 'tourist'`).
- **Guides/operators get a separate, secondary entry point**
  ("Partner with us"), reached via a small text link below the main
  sign-in button — never a peer option to it. Inside that flow, role
  choice is a two-card visual picker (Licensed Guide / Tour Operator),
  not a dropdown.
- **Admin is never self-service.** There is no admin option anywhere in
  this app's sign-up UI; admin accounts are provisioned directly in
  Supabase.
- New profiles write `user_type` values (`tourist` / `guide` / `operator`)
  into the same `profiles` column the website already reads — this
  scaffold never introduces a new column or a new naming convention, and
  never overwrites an existing profile's `user_type` on sign-in.

See `lib/features/auth/` for where these decisions live in code.

## Project layout

```
lib/
  core/
    config/    Env (dart-define config) + Supabase client bootstrap
    router/    go_router with an auth-aware redirect
    theme/     "Serene Himalayan Green" shared visual identity
    widgets/   Small shared widgets (e.g. ComingSoon placeholder)
  features/
    auth/        Google sign-in gate + the "Partner with us" card picker
    home/        Bottom-nav shell for the signed-in tourist experience
    itineraries/ Stub — itinerary browsing (build order step 4)
    bookings/    Stub — booking flow (build order step 5)
    chat/        Stub — messaging (build order step 6)
    profile/     Signed-in user's profile + sign out
```

## Setup

1. Install the Flutter SDK (stable channel) — see
   [flutter.dev](https://docs.flutter.dev/get-started/install).
2. Copy `env.example.json` to `env.json` and fill in the **same** Supabase
   project the website uses:
   ```json
   {
     "SUPABASE_URL": "https://your-project.supabase.co",
     "SUPABASE_ANON_KEY": "your-anon-key",
     "GOOGLE_WEB_CLIENT_ID": "your-google-oauth-web-client-id.apps.googleusercontent.com"
   }
   ```
   `GOOGLE_WEB_CLIENT_ID` is the OAuth **web** client ID from Google Cloud
   Console — required by `google_sign_in` on Android/iOS even though the
   app targets Google sign-in only (Supabase verifies the ID token against
   it server-side).
3. `env.json` is git-ignored on purpose — never commit real keys.
4. Run with the config injected at build time:
   ```bash
   flutter pub get
   flutter run --dart-define-from-file=env.json
   ```
   Without `env.json`, the app shows a "Missing Supabase configuration"
   screen instead of crashing — see `lib/main.dart`.

### Google Sign-In platform setup (not done in this scaffold)

Native Google sign-in additionally needs, per platform, once real
credentials exist:

- **Android:** the app's SHA-1 (debug + release) registered against the
  Google Cloud OAuth client, and `google-services.json` if you later add
  Firebase-adjacent tooling (not required for Supabase auth itself).
- **iOS:** the reversed iOS client ID URL scheme added to `Info.plist`.
- **Supabase dashboard:** Google enabled as a provider under
  Authentication → Providers, with the same client ID/secret.

## Validating this scaffold

No Android/iOS emulator was available in the environment this was built
in, so validation here was:

```bash
flutter analyze   # no issues
flutter test      # widget test covers the missing-config fallback
flutter build web --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

The web build was also manually loaded in headless Chromium to confirm
the sign-in screen and the "Partner with us" card picker actually render
as designed (not just that they compile). Real device/emulator testing on
Android/iOS, and testing against the live Supabase project with a real
Google OAuth client, are still outstanding.
