import 'package:get_it/get_it.dart';
import 'database_helper.dart';
import 'folio_theme.dart';
import '../repositories/document_repository.dart';
import '../services/scanner_service.dart';
import '../services/pdf_service.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/security_service.dart';

final sl = GetIt.instance;

/// Initializes all singleton services, repositories, and helpers via GetIt.
Future<void> initServiceLocator() async {
  // Database Helper
  if (!sl.isRegistered<DatabaseHelper>()) {
    sl.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper.instance);
  }

  // Services
  if (!sl.isRegistered<ScannerService>()) {
    sl.registerLazySingleton<ScannerService>(() => ScannerService());
  }

  if (!sl.isRegistered<PdfService>()) {
    sl.registerLazySingleton<PdfService>(() => PdfService());
  }

  // Repositories
  if (!sl.isRegistered<IDocumentRepository>()) {
    sl.registerLazySingleton<IDocumentRepository>(
      () => DocumentRepository(dbHelper: sl<DatabaseHelper>()),
    );
  }

  if (!sl.isRegistered<DocumentRepository>()) {
    sl.registerLazySingleton<DocumentRepository>(
      () => sl<IDocumentRepository>() as DocumentRepository,
    );
  }

  // Cloud & Auth Services
  if (!sl.isRegistered<AuthService>()) {
    sl.registerLazySingleton<AuthService>(() => AuthService());
  }

  if (!sl.isRegistered<SyncService>()) {
    sl.registerLazySingleton<SyncService>(
      () => SyncService(repository: sl<IDocumentRepository>()),
    );
  }

  // Security & Biometric Vault Service
  if (!sl.isRegistered<SecurityService>()) {
    sl.registerLazySingleton<SecurityService>(() => SecurityService());
  }

  // Theme Notifier
  if (!sl.isRegistered<FolioThemeNotifier>()) {
    sl.registerLazySingleton<FolioThemeNotifier>(() => FolioThemeNotifier());
  }
}
