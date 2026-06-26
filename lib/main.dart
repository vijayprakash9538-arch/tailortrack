import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'common/widgets/mobile_frame.dart';
import 'core/offline/offline_store.dart';
import 'core/offline/sync.dart';
import 'core/router/app_router.dart';
import 'core/supabase/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/customers/data/customers_repository.dart';
import 'features/orders/data/orders_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Local cache/outbox for offline support (must be ready before the app runs).
  await OfflineStore.instance();
  // Initializes the Supabase client and restores any persisted session,
  // giving us "stay logged in across launches and devices" for free.
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(const ProviderScope(child: TailorTrackApp()));
}

class TailorTrackApp extends ConsumerStatefulWidget {
  const TailorTrackApp({super.key});

  @override
  ConsumerState<TailorTrackApp> createState() => _TailorTrackAppState();
}

class _TailorTrackAppState extends ConsumerState<TailorTrackApp> {
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  @override
  void initState() {
    super.initState();
    // When connectivity returns, push anything queued offline and re-sync.
    _connSub = Connectivity().onConnectivityChanged.listen((results) async {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (!online) return;
      await flushOutbox(Supabase.instance.client);
      ref.invalidate(ordersProvider);
      ref.invalidate(customersProvider);
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TailorTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.light(),
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
      builder: (context, child) => MobileFrame(child: child!),
    );
  }
}
