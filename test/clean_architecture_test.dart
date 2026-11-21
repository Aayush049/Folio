import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:folio/core/service_locator.dart';
import 'package:folio/core/errors/failures.dart';
import 'package:folio/models/folder_model.dart';
import 'package:folio/models/document_model.dart';
import 'package:folio/models/page_model.dart';
import 'package:folio/repositories/document_repository.dart';
import 'package:folio/services/scanner_service.dart';
import 'package:folio/blocs/document_detail/document_detail_bloc.dart';
import 'package:folio/blocs/document_detail/document_detail_event.dart';
import 'package:folio/blocs/document_detail/document_detail_state.dart';

class FakeDocumentRepository implements IDocumentRepository {
  final List<Folder> folders = [];
  final List<Document> documents = [];
  final List<PageModel> pages = [];

  @override
  Future<int> addPage(PageModel page) async {
    pages.add(page);
    return pages.length;
  }

  @override
  Future<int> createDocument(int folderId, String name) async {
    final doc = Document(id: documents.length + 1, folderId: folderId, name: name, createdAt: DateTime.now());
    documents.add(doc);
    return doc.id!;
  }

  @override
  Future<int> createFolder(String name) async {
    final folder = Folder(id: folders.length + 1, name: name, createdAt: DateTime.now());
    folders.add(folder);
    return folder.id!;
  }

  @override
  Future<int> deleteDocument(int id) async {
    documents.removeWhere((d) => d.id == id);
    return 1;
  }

  @override
  Future<int> deleteFolder(int id) async {
    folders.removeWhere((f) => f.id == id);
    return 1;
  }

  @override
  Future<int> deletePage(int id) async {
    pages.removeWhere((p) => p.id == id);
    return 1;
  }

  @override
  Future<List<Document>> getDocumentsInFolder(int folderId) async {
    return documents.where((d) => d.folderId == folderId).toList();
  }

  @override
  Future<List<Folder>> getFolders() async => List.from(folders);

  @override
  Future<List<PageModel>> getPages(int documentId) async {
    return pages.where((p) => p.documentId == documentId).toList();
  }

  @override
  Future<List<Document>> getRecentDocuments() async => List.from(documents);

  @override
  Future<int> updatePage(PageModel page) async {
    final idx = pages.indexWhere((p) => p.id == page.id);
    if (idx != -1) pages[idx] = page;
    return 1;
  }
}

class FakeScannerService extends ScannerService {
  @override
  Future<String> extractTextFromImage(File image) async => 'Sample OCR Text';

  @override
  Future<File> saveImageToPermanentStorage(File image) async => image;
}

void main() {
  group('Service Locator & Clean Architecture DI', () {
    test('resolves registered singletons without error', () async {
      await initServiceLocator();

      expect(sl<IDocumentRepository>(), isNotNull);
      expect(sl<DocumentRepository>(), isNotNull);
      expect(sl<ScannerService>(), isNotNull);
    });

    test('Failures hierarchy holds descriptive messages', () {
      const dbFailure = DatabaseFailure('SQLite disk I/O error');
      const ocrFailure = OcrFailure('ML Kit recognition failed');

      expect(dbFailure.message, contains('disk I/O'));
      expect(ocrFailure.message, contains('ML Kit'));
    });
  });

  group('DocumentDetailBloc State Transitions', () {
    late FakeDocumentRepository fakeRepo;
    late FakeScannerService fakeScanner;
    late DocumentDetailBloc bloc;

    setUp(() {
      fakeRepo = FakeDocumentRepository();
      fakeScanner = FakeScannerService();
      fakeRepo.pages.addAll([
        const PageModel(id: 1, documentId: 10, imagePath: '/path/1.png', pageOrder: 0),
        const PageModel(id: 2, documentId: 10, imagePath: '/path/2.png', pageOrder: 1),
      ]);

      bloc = DocumentDetailBloc(
        repository: fakeRepo,
        scannerService: fakeScanner,
        documentId: 10,
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is DocumentDetailInitial', () {
      expect(bloc.state, equals(DocumentDetailInitial()));
    });

    test('loads document pages successfully', () async {
      bloc.add(const LoadDocumentPages(10));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<DocumentDetailLoading>(),
          isA<DocumentDetailLoaded>().having((s) => s.pages.length, 'pages count', 2),
        ]),
      );
    });

    test('reorders pages and emits updated state', () async {
      bloc.add(const LoadDocumentPages(10));
      await bloc.stream.firstWhere((s) => s is DocumentDetailLoaded);

      bloc.add(const ReorderDocumentPages(0, 2));

      await expectLater(
        bloc.stream,
        emits(
          isA<DocumentDetailLoaded>().having((s) => s.pages.first.id, 'first page id', 2),
        ),
      );
    });

    test('deletes page and updates state', () async {
      bloc.add(const LoadDocumentPages(10));
      await bloc.stream.firstWhere((s) => s is DocumentDetailLoaded);

      bloc.add(const DeleteDocumentPage(1));

      await expectLater(
        bloc.stream,
        emits(
          isA<DocumentDetailLoaded>().having((s) => s.pages.length, 'remaining count', 1),
        ),
      );
    });
  });
}
