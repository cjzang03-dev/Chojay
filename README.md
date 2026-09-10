# Chojay — Journey in Bhutan (Flutter app)

The mobile companion to [journeyinbhutan.com](https://journeyinbhutan.com)
(repo `cjzang03-dev/taledesti-quest`, Next.js/TypeScript/Supabase/Vercel).
The app shares the website's Supabase project — same database, same auth,
same storage buckets — and evolves alongside it rather than replacing it.

## Status

Project setup, shared theme, Supabase bootstrap, the app's Google sign-in
gate, itinerary browsing, the booking request flow, direct-message chat,
and operator/guide dashboards are in place, in build order:

1. ~~Website auth rework~~ (out of scope for this repo — see note below)
2. Schema additions for itineraries (website + app)
3. **Flutter: Google sign-in + profile — done**
4. **Flutter: itinerary browsing + detail screens — done**
5. **Flutter: booking flow — done (request-only; see below)**
6. **Flutter: chat — done (direct messages only; see below)**
7. **Flutter: operator/guide dashboards — done (see below)**
8. Website: admin itinerary authoring + approval screens
9. Reviews, notifications, polish

Step 7 (`lib/features/partner/`) covers: signed-in guides/operators are
routed (by `profiles.user_type`, via `currentProfileProvider` in
`lib/features/auth/data/auth_providers.dart`) into a separate
`PartnerDashboardShell` instead of the tourist `HomeShell`. It reuses the
Chat and Profile tabs as-is — messaging and account info aren't
role-specific — and adds two new tabs:
- **Itineraries**: every published itinerary, with an "Apply" button that
  creates a `pending` `itinerary_operators` row, or a status banner
  (pending/approved/rejected) if already applied. Admin approval (website,
  step 8) is what actually makes an operator appear in the tourist-facing
  picker list — this screen only shows this partner's own standing.
- **Bookings**: incoming `itinerary_bookings` rows where `operator_id` is
  the signed-in user, with a "Message" action into the existing chat
  thread. Read-only beyond that — confirming/declining a request needs an
  `UPDATE` policy on `itinerary_bookings` that isn't in the migration yet
  (deferred; today's flow is "coordinate exact terms in chat," which the
  product decisions already call for).

While building this, two correctness fixes to earlier steps:
- **The base itinerary schema had never actually been written to a
  migration file** — it only existed as inline SQL in the original task
  description. It's now `supabase/migrations/20260910b_itineraries_base_schema.sql`
  (itineraries/itinerary_days/itinerary_media/itinerary_operators + RLS).
  **Not applied** — run both this and `20260910_itinerary_bookings.sql`
  (in that order) before any of steps 4-7 work against real data.
- **`ItinerariesRepository.fetchApprovedOperators` was joining `profiles`
  directly**, which would silently return null for every operator once
  RLS is in place — the website deliberately routes all cross-user
  profile reads through `get_public_profile(s)_by_id(s)` RPCs instead
  (confirmed while building chat). Fixed to use the same batched-RPC
  pattern as `ChatRepository` and the new partner screens.

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

Step 6 (`lib/features/chat/`) reuses the website's existing direct-message
schema exactly as-is (`conversations`: `participant_1`/`participant_2`,
`last_message`, `last_message_at`; `messages`: `conversation_id`,
`sender_id`, `receiver_id`, `content`, `read`), plus its
`get_public_profile(s)_by_id(s)` RPCs for reading another user's public
profile fields under RLS — confirmed by reading
`app/dashboard/page.tsx`'s `MessagingTab` in the website repo, not
guessed. A message sent from the app lands in the same conversation the
operator sees on the website, and vice versa. Chat threads are reached
from a booking's "Message" button, and submitting a booking request
auto-starts (or reuses) the conversation with a summary message — this is
literally where the product decision says exact group/room pricing gets
confirmed. **Deliberately deferred** (the website has these; not silently
dropped, flagging for a decision): message reactions, in-app report/block
inside the app's chat UI, and group chat (the website's `group_messages` /
`group_conversations` tables exist but per the product scope-cut list,
direct messaging alone covers the core trust loop — say if you want group
chat built too).

## Schema verification against the live website repo

This session gained read/write access to `cjzang03-dev/taledesti-quest`
(the website) partway through, and the steps 4-5 (itinerary/booking) work
built before that was re-checked against the real source rather than left
on the original schema sketch. Findings:

- **`profiles.user_type` values are correct as built**: `tourist` /
  `local` / `guide` / `operator` / `local_business`, confirmed in
  `app/setup-profile/page.tsx`'s save logic. No `itineraries` or
  `packages` table exists on the website at all — the itinerary model
  really is new territory, no naming collision.
- **Fixed a real gap**: the website's profile upsert always sets
  `status` (`'active'` for tourists, `'pending'` for guides/operators
  until admin approval) and `verification_status: 'pending'`. This app's
  `AuthRepository.ensureProfile` didn't set either — now fixed to match
  (`lib/features/auth/data/auth_repository.dart`).
- **`itinerary_bookings` staying separate from the legacy `bookings`
  table was the right call, for a slightly different reason than
  guessed**: `bookings.package_id` turns out to be nullable (see
  `app/agency/[slug]/page.tsx`), so inserting with a null package_id
  wouldn't have violated a constraint. But `bookings` carries a lot of
  package-flow-specific fields (`agency_package_rate`,
  `booked_through_agency`, a `payment_status`/`deposit_paid` lifecycle
  tied to `PaymentModal.tsx`, and the known `payments.guide_id` bug —
  confirmed at `PaymentModal.tsx:126`, `guide_id: booking.agency_id`)
  that don't apply to the itinerary model. A dedicated table avoids
  writing rows the website's existing operator dashboard would
  misinterpret.
- **Known gap, not yet built**: a guide/operator who signs up through
  this app's "Partner with us" flow only gets a `profiles` row. The
  website's equivalent signup additionally creates a row in
  `agency_listings` (operators) or `guide_listings` (guides) — that's
  where bio/phone/location/rates live, and it's what makes an operator
  actually appear in the website's "Find an Operator" flow. Until the
  app builds that onboarding (operator/guide dashboards, step 7), an
  app-created operator/guide profile is incomplete on the website side.
- **Naming note**: the website's own code still calls operators
  "agency" in a lot of internal identifiers (`agency_listings`,
  `agency_id`, the `/agency/[slug]` route, `AgencyDashboard.tsx`) even
  though `user_type` and most current UI copy already say "operator" —
  that's pre-existing website naming, left as-is (renaming live
  tables/routes is out of scope for an app-side session), and unrelated
  to anything this app writes.

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
