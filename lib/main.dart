import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'blocs/dashboard/dashboard_bloc.dart';
import 'blocs/scanner/scanner_bloc.dart';
import 'blocs/auth_sync/auth_sync_bloc.dart';
import 'blocs/auth_sync/auth_sync_event.dart';
import 'blocs/search/search_bloc.dart';
import 'blocs/trash/trash_bloc.dart';
import 'blocs/trash/trash_event.dart';
import 'blocs/security/security_bloc.dart';
import 'blocs/security/security_event.dart';
import 'repositories/document_repository.dart';
import 'services/scanner_service.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'services/security_service.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/widgets/vault_lock_overlay.dart';
import 'core/folio_theme.dart';
import 'core/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  // Graceful offline-first Firebase initialization
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice (running offline): $e');
  }

  await initServiceLocator();
  runApp(const FolioApp());
}

class FolioApp extends StatefulWidget {
  const FolioApp({super.key});

  @override
  State<FolioApp> createState() => _FolioAppState();
}

class _FolioAppState extends State<FolioApp> with WidgetsBindingObserver {
  late final SecurityBloc _securityBloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _securityBloc = SecurityBloc(securityService: sl<SecurityService>())
      ..add(const CheckSecurityStatus());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _securityBloc.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _securityBloc.add(AppLifecycleChanged(state));
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FolioThemeNotifier>.value(
          value: sl<FolioThemeNotifier>(),
        ),
        Provider<ScannerService>.value(value: sl<ScannerService>()),
        Provider<IDocumentRepository>.value(value: sl<IDocumentRepository>()),
        Provider<DocumentRepository>.value(value: sl<DocumentRepository>()),
        Provider<AuthService>.value(value: sl<AuthService>()),
        Provider<SyncService>.value(value: sl<SyncService>()),
        Provider<SecurityService>.value(value: sl<SecurityService>()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<DashboardBloc>(
            create: (_) => DashboardBloc(repository: sl<IDocumentRepository>()),
          ),
          BlocProvider<ScannerBloc>(
            create: (_) => ScannerBloc(
              scannerService: sl<ScannerService>(),
              repository: sl<IDocumentRepository>(),
            ),
          ),
          BlocProvider<AuthSyncBloc>(
            create: (_) => AuthSyncBloc(
              authService: sl<AuthService>(),
              syncService: sl<SyncService>(),
            )..add(const CheckAuthSyncStatus()),
          ),
          BlocProvider<SearchBloc>(
            create: (_) => SearchBloc(repository: sl<IDocumentRepository>()),
          ),
          BlocProvider<TrashBloc>(
            create: (_) =>
                TrashBloc(repository: sl<IDocumentRepository>())
                  ..add(const LoadTrash()),
          ),
          BlocProvider<SecurityBloc>.value(value: _securityBloc),
        ],
        child: Consumer<FolioThemeNotifier>(
          builder: (context, theme, _) => MaterialApp(
            title: 'Folio',
            debugShowCheckedModeBanner: false,
            theme: theme.themeData,
            home: const SplashScreen(),
            builder: (context, child) {
              return VaultLockOverlay(child: child ?? const SizedBox.shrink());
            },
          ),
        ),
      ),
    );
  }
}
