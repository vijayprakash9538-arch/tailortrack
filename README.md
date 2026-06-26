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

## Known gaps / next steps

- Phone-OTP login screen isn't wired into the router yet (it goes straight to Home) — `AuthService` exists and is ready to back a login flow.
- Photo upload in the New Order "Notes / Photo" section is a placeholder tappable box; wire `image_picker` + `StorageService.uploadOrderPhoto`.
- Dark mode follows system theme; not manually toggleable yet.
- No automated tests yet.
