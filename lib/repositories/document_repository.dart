import '../core/database_helper.dart';
import '../models/folder_model.dart';
import '../models/document_model.dart';
import '../models/page_model.dart';

/// Abstract contract for Document & Folder data access.
/// Decouples UI & BLoC layers from the SQLite DatabaseHelper for testing and mocking.
abstract class IDocumentRepository {
  Future<List<Folder>> getFolders();
  Future<int> createFolder(String name);
  Future<List<Document>> getRecentDocuments();
  Future<List<Document>> getDocumentsInFolder(int folderId);
  Future<int> createDocument(int folderId, String name);
  Future<int> addPage(PageModel page);
  Future<List<PageModel>> getPages(int documentId);
  Future<int> deleteDocument(int id);
  Future<int> deleteFolder(int id);
  Future<int> updatePage(PageModel page);
  Future<int> deletePage(int id);
}

/// Concrete implementation of [IDocumentRepository] using SQLite via [DatabaseHelper].
class DocumentRepository implements IDocumentRepository {
  final DatabaseHelper _dbHelper;

  DocumentRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<List<Folder>> getFolders() => _dbHelper.getAllFolders();

  @override
  Future<int> createFolder(String name) {
    final folder = Folder(name: name, createdAt: DateTime.now());
    return _dbHelper.insertFolder(folder);
  }

  @override
  Future<List<Document>> getRecentDocuments() => _dbHelper.getRecentDocuments();

  @override
  Future<List<Document>> getDocumentsInFolder(int folderId) =>
      _dbHelper.getDocumentsByFolder(folderId);

  @override
  Future<int> createDocument(int folderId, String name) {
    final doc = Document(
      folderId: folderId,
      name: name,
      createdAt: DateTime.now(),
    );
    return _dbHelper.insertDocument(doc);
  }

  @override
  Future<int> addPage(PageModel page) => _dbHelper.insertPage(page);

  @override
  Future<List<PageModel>> getPages(int documentId) =>
      _dbHelper.getPagesByDocument(documentId);

  @override
  Future<int> deleteDocument(int id) => _dbHelper.deleteDocument(id);

  @override
  Future<int> deleteFolder(int id) => _dbHelper.deleteFolder(id);

  @override
  Future<int> updatePage(PageModel page) => _dbHelper.updatePage(page);

  @override
  Future<int> deletePage(int id) => _dbHelper.deletePage(id);
}
