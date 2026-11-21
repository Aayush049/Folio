import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/folder_model.dart';
import '../models/document_model.dart';
import '../models/page_model.dart';
import '../models/search_result_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('folio.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      return await openDatabase(
        filePath,
        version: 2,
        onConfigure: _onConfigureDB,
        onCreate: _createDB,
        onUpgrade: _onUpgradeDB,
      );
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onConfigure: _onConfigureDB,
      onCreate: _createDB,
      onUpgrade: _onUpgradeDB,
    );
  }

  Future _onConfigureDB(Database db) async {
    // Explicitly enforce SQLite foreign keys for cascade deletions
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Version 2 Migration: Add soft delete & FTS5 search index
      try {
        await db.execute(
          'ALTER TABLE documents ADD COLUMN isDeleted INTEGER NOT NULL DEFAULT 0',
        );
        await db.execute('ALTER TABLE documents ADD COLUMN deletedAt TEXT');
      } catch (e) {
        debugPrint('DB migration column notice: $e');
      }

      await _createFtsTable(db);
      await _populateFtsFromExisting(db);
    }
  }

  Future<void> _createFtsTable(Database db) async {
    try {
      await db.execute('''
        CREATE VIRTUAL TABLE IF NOT EXISTS document_fts USING fts5(
          documentId UNINDEXED,
          docName,
          ocrContent
        )
      ''');
    } catch (_) {
      // Fallback for platforms without native FTS5 binary compilation
      await db.execute('''
        CREATE TABLE IF NOT EXISTS document_fts (
          documentId INTEGER PRIMARY KEY,
          docName TEXT,
          ocrContent TEXT
        )
      ''');
    }
  }

  Future<void> _populateFtsFromExisting(Database db) async {
    try {
      final docs = await db.query('documents');
      for (final doc in docs) {
        final id = doc['id'] as int;
        final name = doc['name'] as String;
        final pages = await db.query(
          'pages',
          where: 'documentId = ?',
          whereArgs: [id],
        );
        final ocrText = pages
            .map((p) => p['metadata'] as String? ?? '')
            .where((text) => text.isNotEmpty)
            .join(' ');

        await db.insert('document_fts', {
          'documentId': id,
          'docName': name,
          'ocrContent': ocrText,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e) {
      debugPrint('FTS population notice: $e');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folderId INTEGER NOT NULL,
        name TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isDeleted INTEGER NOT NULL DEFAULT 0,
        deletedAt TEXT,
        FOREIGN KEY (folderId) REFERENCES folders (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE pages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        documentId INTEGER NOT NULL,
        imagePath TEXT NOT NULL,
        pageOrder INTEGER NOT NULL,
        metadata TEXT,
        FOREIGN KEY (documentId) REFERENCES documents (id) ON DELETE CASCADE
      )
    ''');

    await _createFtsTable(db);

    // Insert a default "Uncategorized" folder
    await db.insert('folders', {
      'name': 'Uncategorized',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // ─── Folder CRUD ────────────────────────────────────────────────────────────

  Future<int> insertFolder(Folder folder) async {
    final db = await instance.database;
    return await db.insert('folders', folder.toMap());
  }

  Future<int> insertOrUpdateFolder(Folder folder) async {
    final db = await instance.database;
    return await db.insert(
      'folders',
      folder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Folder>> getAllFolders() async {
    final db = await instance.database;
    final result = await db.query('folders', orderBy: 'createdAt DESC');
    return result.map((json) => Folder.fromMap(json)).toList();
  }

  Future<int> deleteFolder(int id) async {
    final db = await instance.database;
    return await db.delete('folders', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Document CRUD ──────────────────────────────────────────────────────────

  Future<int> insertDocument(Document doc) async {
    final db = await instance.database;
    final docId = await db.insert('documents', doc.toMap());
    // Create initial FTS entry
    await indexDocumentText(docId, doc.name, '');
    return docId;
  }

  Future<int> insertOrUpdateDocument(Document doc) async {
    final db = await instance.database;
    final docId = await db.insert(
      'documents',
      doc.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await indexDocumentText(doc.id ?? docId, doc.name, '');
    return docId;
  }

  Future<List<Document>> getAllDocuments() async {
    final db = await instance.database;
    final result = await db.query(
      'documents',
      where: 'isDeleted = 0',
      orderBy: 'createdAt DESC',
    );
    return result.map((json) => Document.fromMap(json)).toList();
  }

  Future<List<Document>> getDocumentsByFolder(int folderId) async {
    final db = await instance.database;
    final result = await db.query(
      'documents',
      where: 'folderId = ? AND isDeleted = 0',
      whereArgs: [folderId],
      orderBy: 'createdAt DESC',
    );
    return result.map((json) => Document.fromMap(json)).toList();
  }

  Future<List<Document>> getRecentDocuments({int limit = 5}) async {
    final db = await instance.database;
    final result = await db.query(
      'documents',
      where: 'isDeleted = 0',
      orderBy: 'createdAt DESC',
      limit: limit,
    );
    return result.map((json) => Document.fromMap(json)).toList();
  }

  // ─── Soft Delete & Trash CRUD ───────────────────────────────────────────────

  Future<int> softDeleteDocument(int id) async {
    final db = await instance.database;
    return await db.update(
      'documents',
      {'isDeleted': 1, 'deletedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> restoreDocument(int id) async {
    final db = await instance.database;
    return await db.update(
      'documents',
      {'isDeleted': 0, 'deletedAt': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Document>> getTrashDocuments() async {
    final db = await instance.database;
    final result = await db.query(
      'documents',
      where: 'isDeleted = 1',
      orderBy: 'deletedAt DESC',
    );
    return result.map((json) => Document.fromMap(json)).toList();
  }

  Future<int> permanentDeleteDocument(int id) async {
    final db = await instance.database;
    try {
      await db.delete('document_fts', where: 'documentId = ?', whereArgs: [id]);
    } catch (_) {}
    return await db.delete('documents', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> emptyTrash() async {
    final trashDocs = await getTrashDocuments();
    for (final doc in trashDocs) {
      if (doc.id != null) {
        await permanentDeleteDocument(doc.id!);
      }
    }
    return trashDocs.length;
  }

  // Legacy hard delete (kept for backwards compatibility)
  Future<int> deleteDocument(int id) => softDeleteDocument(id);

  // ─── Page CRUD & Search Indexing ────────────────────────────────────────────

  Future<int> insertPage(PageModel page) async {
    final db = await instance.database;
    final pageId = await db.insert('pages', page.toMap());
    await _refreshDocumentIndex(page.documentId);
    return pageId;
  }

  Future<int> insertOrUpdatePage(PageModel page) async {
    final db = await instance.database;
    final pageId = await db.insert(
      'pages',
      page.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _refreshDocumentIndex(page.documentId);
    return pageId;
  }

  Future<List<PageModel>> getAllPages() async {
    final db = await instance.database;
    final result = await db.query('pages', orderBy: 'pageOrder ASC');
    return result.map((json) => PageModel.fromMap(json)).toList();
  }

  Future<List<PageModel>> getPagesByDocument(int documentId) async {
    final db = await instance.database;
    final result = await db.query(
      'pages',
      where: 'documentId = ?',
      whereArgs: [documentId],
      orderBy: 'pageOrder ASC',
    );
    return result.map((json) => PageModel.fromMap(json)).toList();
  }

  Future<int> updatePage(PageModel page) async {
    final db = await instance.database;
    final count = await db.update(
      'pages',
      page.toMap(),
      where: 'id = ?',
      whereArgs: [page.id],
    );
    await _refreshDocumentIndex(page.documentId);
    return count;
  }

  Future<int> deletePage(int id) async {
    final db = await instance.database;
    final pageQuery = await db.query('pages', where: 'id = ?', whereArgs: [id]);
    final documentId = pageQuery.isNotEmpty
        ? pageQuery.first['documentId'] as int?
        : null;

    final count = await db.delete('pages', where: 'id = ?', whereArgs: [id]);

    if (documentId != null) {
      await _refreshDocumentIndex(documentId);
    }
    return count;
  }

  Future<void> indexDocumentText(
    int documentId,
    String docName,
    String ocrContent,
  ) async {
    final db = await instance.database;
    try {
      await db.delete(
        'document_fts',
        where: 'documentId = ?',
        whereArgs: [documentId],
      );
      await db.insert('document_fts', {
        'documentId': documentId,
        'docName': docName,
        'ocrContent': ocrContent,
      });
    } catch (e) {
      debugPrint('indexDocumentText error: $e');
    }
  }

  Future<void> _refreshDocumentIndex(int documentId) async {
    final db = await instance.database;
    try {
      final docRes = await db.query(
        'documents',
        where: 'id = ?',
        whereArgs: [documentId],
      );
      if (docRes.isEmpty) return;
      final docName = docRes.first['name'] as String;

      final pagesRes = await db.query(
        'pages',
        where: 'documentId = ?',
        whereArgs: [documentId],
      );
      final ocrText = pagesRes
          .map((p) => p['metadata'] as String? ?? '')
          .where((text) => text.isNotEmpty)
          .join(' ');

      await indexDocumentText(documentId, docName, ocrText);
    } catch (e) {
      debugPrint('Error refreshing document index: $e');
    }
  }

  // ─── Full-Text OCR Search ───────────────────────────────────────────────────

  Future<List<SearchResult>> searchDocuments(String query) async {
    if (query.trim().isEmpty) return [];
    final db = await instance.database;
    final q = query.trim();

    List<Map<String, dynamic>> results = [];
    try {
      results = await db.rawQuery(
        '''
        SELECT f.documentId, f.docName, f.ocrContent, d.folderId, d.createdAt, fol.name as folderName
        FROM document_fts f
        INNER JOIN documents d ON d.id = f.documentId
        LEFT JOIN folders fol ON fol.id = d.folderId
        WHERE d.isDeleted = 0 AND (f.docName LIKE ? OR f.ocrContent LIKE ?)
        ORDER BY d.createdAt DESC
      ''',
        ['%$q%', '%$q%'],
      );
    } catch (e) {
      debugPrint('Search query error: $e');
    }

    return results.map((row) {
      final docId = row['documentId'] as int;
      final docName = row['docName'] as String? ?? 'Untitled';
      final ocrContent = row['ocrContent'] as String? ?? '';
      final folderId = row['folderId'] as int? ?? 1;
      final folderName = row['folderName'] as String? ?? 'Uncategorized';
      final createdAt = row['createdAt'] != null
          ? DateTime.tryParse(row['createdAt'] as String) ?? DateTime.now()
          : DateTime.now();

      String snippet = '';
      final lowerContent = ocrContent.toLowerCase();
      final lowerQ = q.toLowerCase();
      final matchIdx = lowerContent.indexOf(lowerQ);

      if (matchIdx != -1) {
        final start = (matchIdx - 30).clamp(0, ocrContent.length);
        final end = (matchIdx + lowerQ.length + 50).clamp(0, ocrContent.length);
        snippet =
            '...${ocrContent.substring(start, end).replaceAll('\n', ' ')}...';
      } else if (ocrContent.isNotEmpty) {
        final end = 70.clamp(0, ocrContent.length);
        snippet = '${ocrContent.substring(0, end).replaceAll('\n', ' ')}...';
      } else {
        snippet = 'Matched document title';
      }

      final isTitleMatch = docName.toLowerCase().contains(lowerQ);

      return SearchResult(
        document: Document(
          id: docId,
          folderId: folderId,
          name: docName,
          createdAt: createdAt,
        ),
        folderName: folderName,
        snippet: snippet,
        isTitleMatch: isTitleMatch,
      );
    }).toList();
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
    }
    _database = null;
  }
}
