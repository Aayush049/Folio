import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'blocs/dashboard/dashboard_bloc.dart';
import 'blocs/scanner/scanner_bloc.dart';
import 'repositories/document_repository.dart';
import 'services/scanner_service.dart';
import 'ui/screens/splash_screen.dart';
import 'core/folio_theme.dart';
import 'core/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  await initServiceLocator();
  runApp(const FolioApp());
}

class FolioApp extends StatelessWidget {
  const FolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FolioThemeNotifier>.value(
          value: sl<FolioThemeNotifier>(),
        ),
        Provider<ScannerService>.value(
          value: sl<ScannerService>(),
        ),
        Provider<IDocumentRepository>.value(
          value: sl<IDocumentRepository>(),
        ),
        Provider<DocumentRepository>.value(
          value: sl<DocumentRepository>(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<DashboardBloc>(
            create: (_) => DashboardBloc(
              repository: sl<IDocumentRepository>(),
            ),
          ),
          BlocProvider<ScannerBloc>(
            create: (_) => ScannerBloc(
              scannerService: sl<ScannerService>(),
              repository: sl<IDocumentRepository>(),
            ),
          ),
        ],
        child: Consumer<FolioThemeNotifier>(
          builder: (context, theme, _) => MaterialApp(
            title: 'Folio',
            debugShowCheckedModeBanner: false,
            theme: theme.themeData, // auto-switches day ↔ night
            home: const SplashScreen(),
          ),
        ),
      ),
    );
  }
}
