import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/blocs/auth_sync/auth_sync_bloc.dart';
import 'package:folio/blocs/auth_sync/auth_sync_event.dart';
import 'package:folio/blocs/auth_sync/auth_sync_state.dart';
import 'package:folio/models/document_model.dart';
import 'package:folio/models/folder_model.dart';
import 'package:folio/models/page_model.dart';
import 'package:folio/repositories/document_repository.dart';
import 'package:folio/services/auth_service.dart';
import 'package:folio/services/sync_service.dart';

class _FakeRepo implements IDocumentRepository {
  @override
  Future<int> addPage(PageModel page) async => 1;
  @override
  Future<int> createDocument(int folderId, String name) async => 1;
  @override
  Future<int> createFolder(String name) async => 1;
  @override
  Future<int> deleteDocument(int id) async => 1;
  @override
  Future<int> deleteFolder(int id) async => 1;
  @override
  Future<int> deletePage(int id) async => 1;
  @override
  Future<List<Document>> getAllDocuments() async => [];
  @override
  Future<List<PageModel>> getAllPages() async => [];
  @override
  Future<List<Document>> getDocumentsInFolder(int folderId) async => [];
  @override
  Future<List<Folder>> getFolders() async => [];
  @override
  Future<List<PageModel>> getPages(int documentId) async => [];
  @override
  Future<List<Document>> getRecentDocuments() async => [];
  @override
  Future<int> insertOrUpdateDocument(Document doc) async => 1;
  @override
  Future<int> insertOrUpdateFolder(Folder folder) async => 1;
  @override
  Future<int> insertOrUpdatePage(PageModel page) async => 1;
  @override
  Future<int> updatePage(PageModel page) async => 1;
}

class FakeAuthService extends AuthService {
  final StreamController<User?> _controller = StreamController<User?>.broadcast();
  User? _mockUser;

  FakeAuthService() : super(auth: null);

  void setMockUser(User? user) {
    _mockUser = user;
    _controller.add(user);
  }

  @override
  User? get currentUser => _mockUser;

  @override
  Stream<User?> get authStateChanges => _controller.stream;

  @override
  Future<User?> signInWithGoogle() async => _mockUser;

  @override
  Future<void> signOut() async {
    _mockUser = null;
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}

class FakeSyncService extends SyncService {
  DateTime? lastSync;
  bool shouldFail = false;

  FakeSyncService() : super(repository: _FakeRepo());

  @override
  Future<DateTime?> getLastSyncTime() async => lastSync;

  @override
  Future<SyncResult> backupAllToCloud() async {
    if (shouldFail) {
      throw Exception('Network disconnected');
    }
    lastSync = DateTime(2026, 11, 21, 12, 0);
    return SyncResult(
      success: true,
      foldersCount: 2,
      documentsCount: 4,
      pagesCount: 8,
      message: 'Backup completed',
      timestamp: lastSync,
    );
  }

  @override
  Future<SyncResult> restoreAllFromCloud() async {
    if (shouldFail) {
      throw Exception('Network disconnected');
    }
    lastSync = DateTime(2026, 11, 21, 12, 30);
    return SyncResult(
      success: true,
      foldersCount: 2,
      documentsCount: 4,
      pagesCount: 8,
      message: 'Restore completed',
      timestamp: lastSync,
    );
  }
}

void main() {
  group('AuthSyncBloc Tests', () {
    late FakeAuthService fakeAuthService;
    late FakeSyncService fakeSyncService;
    late AuthSyncBloc bloc;

    setUp(() {
      fakeAuthService = FakeAuthService();
      fakeSyncService = FakeSyncService();
      bloc = AuthSyncBloc(
        authService: fakeAuthService,
        syncService: fakeSyncService,
      );
    });

    tearDown(() {
      bloc.close();
      fakeAuthService.dispose();
    });

    test('initial state has null user when not authenticated', () {
      expect(bloc.state.user, isNull);
      expect(bloc.state.isAuthenticated, isFalse);
      expect(bloc.state.isBusy, isFalse);
    });

    test('blocks backup when user is not signed in', () async {
      bloc.add(const BackupToCloudRequested());

      await expectLater(
        bloc.stream,
        emits(
          isA<AuthSyncState>().having(
            (s) => s.errorMessage,
            'errorMessage',
            contains('Please sign in'),
          ),
        ),
      );
    });

    test('blocks restore when user is not signed in', () async {
      bloc.add(const RestoreFromCloudRequested());

      await expectLater(
        bloc.stream,
        emits(
          isA<AuthSyncState>().having(
            (s) => s.errorMessage,
            'errorMessage',
            contains('Please sign in'),
          ),
        ),
      );
    });

    test('signs out successfully and clears user state', () async {
      bloc.add(const SignOutRequested());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthSyncState>().having((s) => s.isAuthenticating, 'isAuthenticating', isTrue),
          isA<AuthSyncState>().having((s) => s.user, 'user', isNull),
        ]),
      );
    });
  });
}
