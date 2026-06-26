# TailorTrack

Premium order management app for women's tailoring shops. Built with Flutter 3, Material 3, and Riverpod.

## Status

This is a **fully-built UI + state layer running on in-memory mock data** — every screen in the spec (Home, New Order, Orders, Order Details, Customers, Customer Profile, Insights) is implemented and wired together with real business logic (balance calculation, today's orders, pending payments, top customers, dress-type analytics, delivery scheduling). Firebase is **not yet connected** — see "Wiring up Firebase" below.

## Getting started

1. Install Flutter 3.22+ (`brew install --cask flutter` on macOS, or see flutter.dev).
2. From this folder:
   ```
   flutter pub get
   flutter run
   ```
3. No `build_runner` step is required — models use plain Dart classes with hand-written `copyWith`, not Freezed codegen, so the app runs immediately without a generation step. (`freezed`/`json_serializable` are still in `pubspec.yaml` for when the data layer moves to Firestore and typed JSON (de)serialization is worth the codegen.)

## Architecture

Feature-first, as specified:

```
lib/
  core/
    theme/       — AppColors, AppRadius, AppTheme (light + dark)
    router/      — GoRouter config, ShellRoute for the 4-tab bottom nav
    services/    — AuthService / StorageService interfaces + Mock impls
  common/widgets/ — OrderCard, CustomerCard, StatusBadge, AccordionSection, etc.
  features/
    splash/
    home/
    orders/      — domain (Order, OrderStatus, DeliveryTime), data (mock + Riverpod notifier), presentation (Orders list, Order details, New Order form)
    customers/   — domain (Customer, Measurement), data, presentation
    insights/    — derived providers (BusinessHealth, DressTypeShare, DeliverySchedule) + screen
```

All business numbers (today's orders, pending payments, balance, top customers, monthly income) are **derived Riverpod providers** computed from the single `ordersProvider`/`customersProvider` source of truth — there is no separately-stored "stats" model that could drift out of sync.

## Wiring up Firebase

The app is structured so Firebase can be dropped in without touching UI code:

1. Run `flutterfire configure` to generate `firebase_options.dart`.
2. Uncomment the Firebase packages in `pubspec.yaml` and run `flutter pub get`.
3. Replace `MockAuthService`/`MockStorageService` in `lib/core/services/service_providers.dart` with Firebase-backed implementations of the same `AuthService`/`StorageService` interfaces.
4. Replace the bodies of `OrdersNotifier`/`CustomersNotifier` (in `lib/features/orders/data/orders_repository.dart` and `lib/features/customers/data/customers_repository.dart`) with Firestore reads/writes — the public API (`addOrder`, `updateStatus`, etc.) and every downstream provider stays the same.

## Orders tab (redesigned)

The Orders screen is built around a tailor's daily workflow:

- **Upcoming view** (default) — non-delivered orders grouped into **Overdue / Today / Tomorrow / This Week / Later** buckets, so the week's workload is visible at a glance.
- **All view** — flat list with status filter chips (All / Pending / Stitching / Ready / Overdue).
- **Done view** — delivered orders.
- **Inline progress update** — tap the status badge on any card to open a quick picker and advance an order (Pending → Stitching → Ready → Delivered) without opening it.
- **Date-range filter** — calendar icon in the app bar filters by delivery date.
- Every card shows the **order-placed date** ("Ordered 25 Jun") for tracking.

New Order / Edit Order:
- **Edit** an existing order from the Order Details screen (pencil icon) — reuses the same form.
- **Order Date** field defaults to today and is editable (can backdate if entered late).
- **Delivery Date** allows past dates (in case an order was missed).
- Dropdowns are height-capped so they no longer cover the screen.

## Payments & Insights accounting

The Insights numbers reconcile by construction — **Collected + Pending = Order Value**, always:
- **Order Value** = sum of every order's total (business booked)
- **Collected** = sum of advances actually received (income in hand)
- **Pending** = sum of outstanding balances

Marking an order **Delivered** with an outstanding balance pops a **Collect Payment** dialog: record the amount received now ("Fully Paid" settles the whole balance, or enter a partial amount and leave the rest pending). Settling sets the order's advance up so it counts as collected.

The **month filter** (top-right of Insights) scopes the Business Health card, Earnings Overview and Dress Type mix to a chosen month (by order-placed date) or All Time. The **Monthly Collected** bar chart is real data computed from advances received per month. Pending Payments, Top Customers and Today's Schedule stay current regardless of the filter.

## Measurements (Top / Bottom split)

Measurements are captured and displayed in two clearly-separated groups for readability:
- **Top / Blouse** — chest, waist, shoulder, sleeve, length, neck
- **Bottom / Pant** — waist, hip, length, thigh, knee, bottom

The same `MeasurementForm` widget is reused in New Order and Customer Edit.

## Editable customers

Customer profiles have an **Edit** button (name, phone, full measurements). Saved measurements become the customer's default and auto-fill repeat orders.

## Supabase backend

TailorTrack is backed by a dedicated Supabase project (`tailortrack`, region ap-south-1).

**Config** — `lib/core/supabase/supabase_config.dart` reads the project URL and the **publishable** key (public by design, protected by RLS). The secret/service-role key is never referenced in the app. Override at build time without editing source:

```
flutter build web --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

**Schema** (`tt_` prefix): `tt_shops`, `tt_customers`, `tt_orders`. One shop per authenticated owner; every customer/order carries `shop_id`. A signup trigger (`tt_on_auth_user_created`) auto-creates the shop from the shop/owner name passed as signup metadata.

**Security** — Row Level Security on every table scopes rows to the owner's shop via `tt_current_shop_id()`. Storage buckets `photos` and `voice-notes` are **private**, with policies that only allow access under `{shop_id}/…`.

**Auth** — email/password (`features/authentication/`): Login, Sign Up, Forgot Password, Reset Password. Session persists across launches/devices (handled by `supabase_flutter`). The router (`app_router.dart`) gates the app: signed-out users land on `/login`; signed-in users go to the tabs. Sign out from the Home header.

**Realtime multi-device sync** — `OrdersNotifier`/`CustomersNotifier` subscribe to Postgres changes filtered by `shop_id`, so edits on one device appear on others automatically. Public provider APIs are unchanged, so the UI/workflows are untouched.

**Offline support** — reads are cached locally (`shared_preferences`); the app opens instantly and works with no network. Writes apply optimistically and queue in an outbox (`core/offline/`) that flushes when connectivity returns.

**Media compression** (`core/storage/media_service.dart`) — photos are resized to ~1280px / JPEG q70 before upload; voice notes record as AAC `.m4a`. Both upload to the shop's private storage folder; display/playback use short-lived signed URLs.

## Settings & Backup

A **Settings** screen (gear icon in the Home header → `/settings`) adds, without changing any existing screen:
- **Account** — shop name, logged-in email, owner, and **Log out**.
- **Automatic Cloud Backup** — note explaining data already syncs to Supabase and restores on any device you sign into (no manual action).
- **Manual backup** — **Export JSON / Export ZIP** and **Import Backup**. Exports include customers, orders, measurements and payments; **photos and voice notes are excluded**. Import validates the file, previews the counts, and lets you **Merge** (add/update) or **Replace** (clear first).

## Media retention

`core/maintenance/retention_service.dart` runs a once-per-day sweep (throttled via SharedPreferences, kicked off from Home once the shop is known):
- **Photos deleted after 60 days**, **voice notes after 30 days** — only the storage files are removed; the order/customer records (and all measurements/payments) are kept forever, with the media reference cleared.

### Backend notes for going live
- **Email confirmation**: Supabase's default "Confirm email" setting means a new signup must click a confirmation email before signing in. For instant testing you can turn it off in the Supabase dashboard → Authentication → Providers → Email.
- **Password reset emails** use Supabase's built-in SMTP (rate-limited); add a custom SMTP provider for production volume.

## Known gaps / next steps

- Phone-OTP login screen isn't wired into the router yet (it goes straight to Home) — `AuthService` exists and is ready to back a login flow.
- Photo upload in the New Order "Notes / Photo" section is a placeholder tappable box; wire `image_picker` + `StorageService.uploadOrderPhoto`.
- Dark mode follows system theme; not manually toggleable yet.
- No automated tests yet.
