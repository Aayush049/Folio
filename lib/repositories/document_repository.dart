import '../core/database_helper.dart';
import '../models/folder_model.dart';
import '../models/document_model.dart';
import '../models/page_model.dart';
import '../models/search_result_model.dart';

/// Abstract contract for Document & Folder data access.
/// Decouples UI & BLoC layers from the SQLite DatabaseHelper for testing and mocking.
abstract class IDocumentRepository {
  Future<List<Folder>> getFolders();
  Future<int> createFolder(String name);
  Future<int> insertOrUpdateFolder(Folder folder);

  Future<List<Document>> getAllDocuments();
  Future<List<Document>> getRecentDocuments();
  Future<List<Document>> getDocumentsInFolder(int folderId);
  Future<int> createDocument(int folderId, String name);
  Future<int> insertOrUpdateDocument(Document doc);
  Future<int> deleteDocument(int id);
  Future<int> deleteFolder(int id);

  // Soft delete & Trash
  Future<int> softDeleteDocument(int id);
  Future<int> restoreDocument(int id);
  Future<List<Document>> getTrashDocuments();
  Future<int> permanentDeleteDocument(int id);
  Future<int> emptyTrash();

  // Full-Text OCR Search
  Future<List<SearchResult>> searchDocuments(String query);
  Future<void> indexDocumentText(int documentId, String docName, String ocrContent);

  Future<List<PageModel>> getAllPages();
  Future<List<PageModel>> getPages(int documentId);
  Future<int> addPage(PageModel page);
  Future<int> insertOrUpdatePage(PageModel page);
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
  Future<int> insertOrUpdateFolder(Folder folder) =>
      _dbHelper.insertOrUpdateFolder(folder);

  @override
  Future<List<Document>> getAllDocuments() => _dbHelper.getAllDocuments();

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
  Future<int> insertOrUpdateDocument(Document doc) =>
      _dbHelper.insertOrUpdateDocument(doc);

  @override
  Future<int> deleteDocument(int id) => _dbHelper.deleteDocument(id);

  @override
  Future<int> deleteFolder(int id) => _dbHelper.deleteFolder(id);

  // Soft delete & Trash
  @override
  Future<int> softDeleteDocument(int id) => _dbHelper.softDeleteDocument(id);

  @override
  Future<int> restoreDocument(int id) => _dbHelper.restoreDocument(id);

  @override
  Future<List<Document>> getTrashDocuments() => _dbHelper.getTrashDocuments();

  @override
  Future<int> permanentDeleteDocument(int id) =>
      _dbHelper.permanentDeleteDocument(id);

  @override
  Future<int> emptyTrash() => _dbHelper.emptyTrash();

  // Full-Text OCR Search
  @override
  Future<List<SearchResult>> searchDocuments(String query) =>
      _dbHelper.searchDocuments(query);

  @override
  Future<void> indexDocumentText(
    int documentId,
    String docName,
    String ocrContent,
  ) =>
      _dbHelper.indexDocumentText(documentId, docName, ocrContent);

  @override
  Future<List<PageModel>> getAllPages() => _dbHelper.getAllPages();

  @override
  Future<List<PageModel>> getPages(int documentId) =>
      _dbHelper.getPagesByDocument(documentId);

  @override
  Future<int> addPage(PageModel page) => _dbHelper.insertPage(page);

  @override
  Future<int> insertOrUpdatePage(PageModel page) =>
      _dbHelper.insertOrUpdatePage(page);

  @override
  Future<int> updatePage(PageModel page) => _dbHelper.updatePage(page);

  @override
  Future<int> deletePage(int id) => _dbHelper.deletePage(id);
}
