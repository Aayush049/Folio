import 'package:flutter_test/flutter_test.dart';
import 'package:folio/blocs/trash/trash_bloc.dart';
import 'package:folio/blocs/trash/trash_event.dart';
import 'package:folio/blocs/trash/trash_state.dart';
import 'package:folio/models/document_model.dart';
import 'package:folio/models/folder_model.dart';
import 'package:folio/models/page_model.dart';
import 'package:folio/models/search_result_model.dart';
import 'package:folio/repositories/document_repository.dart';

class _FakeTrashRepo implements IDocumentRepository {
  final List<Document> trashList = [
    Document(
      id: 10,
      folderId: 1,
      name: 'Deleted Draft',
      createdAt: DateTime(2026, 11, 1),
      isDeleted: true,
      deletedAt: DateTime(2026, 11, 20),
    ),
  ];

  @override
  Future<List<Document>> getTrashDocuments() async => List.from(trashList);

  @override
  Future<int> restoreDocument(int id) async {
    trashList.removeWhere((d) => d.id == id);
    return 1;
  }

  @override
  Future<int> permanentDeleteDocument(int id) async {
    trashList.removeWhere((d) => d.id == id);
    return 1;
  }

  @override
  Future<int> emptyTrash() async {
    final count = trashList.length;
    trashList.clear();
    return count;
  }

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
  Future<void> indexDocumentText(int documentId, String docName, String ocrContent) async {}
  @override
  Future<int> insertOrUpdateDocument(Document doc) async => 1;
  @override
  Future<int> insertOrUpdateFolder(Folder folder) async => 1;
  @override
  Future<int> insertOrUpdatePage(PageModel page) async => 1;
  @override
  Future<List<SearchResult>> searchDocuments(String query) async => [];
  @override
  Future<int> softDeleteDocument(int id) async => 1;
  @override
  Future<int> updatePage(PageModel page) async => 1;
}

void main() {
  group('TrashBloc Tests', () {
    late _FakeTrashRepo repo;
    late TrashBloc bloc;

    setUp(() {
      repo = _FakeTrashRepo();
      bloc = TrashBloc(repository: repo);
    });

    tearDown(() {
      bloc.close();
    });

    test('loads trash documents correctly', () async {
      bloc.add(const LoadTrash());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<TrashLoading>(),
          isA<TrashLoaded>().having((s) => s.documents.length, 'docs count', 1),
        ]),
      );
    });

    test('restores document and emits updated state with message', () async {
      bloc.add(const RestoreDocumentFromTrash(10));

      await expectLater(
        bloc.stream,
        emits(
          isA<TrashLoaded>()
              .having((s) => s.documents, 'documents', isEmpty)
              .having((s) => s.message, 'message', contains('restored')),
        ),
      );
    });

    test('permanently deletes document and updates state', () async {
      bloc.add(const PermanentlyDeleteFromTrash(10));

      await expectLater(
        bloc.stream,
        emits(
          isA<TrashLoaded>()
              .having((s) => s.documents, 'documents', isEmpty)
              .having((s) => s.message, 'message', contains('permanently deleted')),
        ),
      );
    });

    test('empties trash and clears list', () async {
      bloc.add(const EmptyTrash());

      await expectLater(
        bloc.stream,
        emits(
          isA<TrashLoaded>()
              .having((s) => s.documents, 'documents', isEmpty)
              .having((s) => s.message, 'message', contains('Purged')),
        ),
      );
    });
  });
}
