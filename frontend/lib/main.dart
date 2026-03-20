import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/env.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'shared/providers/theme_locale_provider.dart';
import 'shared/services/offline_sync.dart';
import 'generated/l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for offline storage
  await Hive.initFlutter();

  // Initialize Supabase with PKCE flow (required for OAuth on mobile)
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: kIsWeb ? AuthFlowType.implicit : AuthFlowType.pkce,
    ),
  );

  runApp(
    const ProviderScope(
      child: ConceptraApp(),
    ),
  );
}

/// Root widget that wires up theme, locale, router, and localizations.
class ConceptraApp extends ConsumerStatefulWidget {
  const ConceptraApp({super.key});

  @override
  ConsumerState<ConceptraApp> createState() => _ConceptraAppState();
}

class _ConceptraAppState extends ConsumerState<ConceptraApp> {
  @override
  void initState() {
    super.initState();
    // Initialize offline sync service (opens Hive box, starts listening)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(offlineSyncProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    // Ensures UserProfile is created in backend on every login
    ref.watch(profileSyncProvider);

    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Conceptra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('te'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
