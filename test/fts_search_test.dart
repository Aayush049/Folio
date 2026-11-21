import 'package:flutter_test/flutter_test.dart';
import 'package:folio/blocs/search/search_bloc.dart';
import 'package:folio/blocs/search/search_event.dart';
import 'package:folio/blocs/search/search_state.dart';
import 'package:folio/models/document_model.dart';
import 'package:folio/models/folder_model.dart';
import 'package:folio/models/page_model.dart';
import 'package:folio/models/search_result_model.dart';
import 'package:folio/repositories/document_repository.dart';

class _FakeSearchRepo implements IDocumentRepository {
  final List<Document> docs = [
    Document(
      id: 1,
      folderId: 1,
      name: 'Invoice Nov 2026',
      createdAt: DateTime(2026, 11, 1),
    ),
    Document(
      id: 2,
      folderId: 1,
      name: 'Passport Scan',
      createdAt: DateTime(2026, 11, 5),
    ),
  ];

  @override
  Future<List<SearchResult>> searchDocuments(String query) async {
    final q = query.toLowerCase();
    return docs
        .where((d) => d.name.toLowerCase().contains(q))
        .map(
          (d) => SearchResult(
            document: d,
            folderName: 'Personal',
            snippet: 'Matched name in search',
            isTitleMatch: true,
          ),
        )
        .toList();
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
  Future<int> emptyTrash() async => 0;
  @override
  Future<List<Document>> getAllDocuments() async => docs;
  @override
  Future<List<PageModel>> getAllPages() async => [];
  @override
  Future<List<Document>> getDocumentsInFolder(int folderId) async => [];
  @override
  Future<List<Folder>> getFolders() async => [];
  @override
  Future<List<PageModel>> getPages(int documentId) async => [];
  @override
  Future<List<Document>> getRecentDocuments() async => docs;
  @override
  Future<List<Document>> getTrashDocuments() async => [];
  @override
  Future<void> indexDocumentText(
    int documentId,
    String docName,
    String ocrContent,
  ) async {}
  @override
  Future<int> insertOrUpdateDocument(Document doc) async => 1;
  @override
  Future<int> insertOrUpdateFolder(Folder folder) async => 1;
  @override
  Future<int> insertOrUpdatePage(PageModel page) async => 1;
  @override
  Future<int> permanentDeleteDocument(int id) async => 1;
  @override
  Future<int> restoreDocument(int id) async => 1;
  @override
  Future<int> softDeleteDocument(int id) async => 1;
  @override
  Future<int> updatePage(PageModel page) async => 1;
}

void main() {
  group('SearchBloc Tests', () {
    late _FakeSearchRepo repo;
    late SearchBloc bloc;

    setUp(() {
      repo = _FakeSearchRepo();
      bloc = SearchBloc(repository: repo);
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state has empty query and results', () {
      expect(bloc.state.query, isEmpty);
      expect(bloc.state.results, isEmpty);
      expect(bloc.state.isLoading, isFalse);
    });

    test('querying updates state with debounced results', () async {
      bloc.add(const SearchQueryChanged('Passport'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SearchState>().having((s) => s.isLoading, 'isLoading', isTrue),
          isA<SearchState>()
              .having((s) => s.isLoading, 'isLoading', isFalse)
              .having((s) => s.results.length, 'results count', 1)
              .having(
                (s) => s.results.first.document.name,
                'doc name',
                'Passport Scan',
              ),
        ]),
      );
    });

    test('clearing search emits empty initial-like state', () async {
      bloc.add(const SearchQueryChanged('Invoice'));
      await bloc.stream.firstWhere((s) => s.results.isNotEmpty);

      bloc.add(const ClearSearch());

      await expectLater(bloc.stream, emits(const SearchState()));
    });
  });
}
