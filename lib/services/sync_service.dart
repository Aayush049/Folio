import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../core/errors/failures.dart';
import '../models/document_model.dart';
import '../models/folder_model.dart';
import '../models/page_model.dart';
import '../repositories/document_repository.dart';

class SyncResult {
  final bool success;
  final int foldersCount;
  final int documentsCount;
  final int pagesCount;
  final String message;
  final DateTime timestamp;

  SyncResult({
    required this.success,
    this.foldersCount = 0,
    this.documentsCount = 0,
    this.pagesCount = 0,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class SyncService {
  final FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customFirestore;
  final FirebaseStorage? _customStorage;
  final IDocumentRepository _repository;

  SyncService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    required IDocumentRepository repository,
  })  : _customAuth = auth,
        _customFirestore = firestore,
        _customStorage = storage,
        _repository = repository;

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;
  FirebaseStorage get _storage => _customStorage ?? FirebaseStorage.instance;

  /// Retrieves the last recorded backup timestamp from Firestore
  Future<DateTime?> getLastSyncTime() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final snapshot = await _firestore.collection('users').doc(user.uid).get();
      if (snapshot.exists && snapshot.data() != null) {
        final dynamic raw = snapshot.data()!['lastBackupAt'];
        if (raw is Timestamp) {
          return raw.toDate();
        }
      }
    } catch (e) {
      debugPrint('Warning: unable to fetch last sync timestamp: $e');
    }
    return null;
  }

  /// Backs up all local Folders, Documents, and Pages to Firebase
  Future<SyncResult> backupAllToCloud() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const SyncFailure('You must be signed in to back up data.');
    }

    try {
      final folders = await _repository.getFolders();
      final documents = await _repository.getAllDocuments();
      final pages = await _repository.getAllPages();

      // 1. Upload page image files to Storage and prepare page metadata
      final List<Map<String, dynamic>> uploadedPages = [];

      for (final page in pages) {
        String? storagePath;
        String? downloadUrl;

        try {
          if (kIsWeb) {
            if (page.imagePath.startsWith('data:image')) {
              final base64Content = page.imagePath.split(',').last;
              final bytes = base64Decode(base64Content);
              final targetRef = _storage.ref().child(
                    'users/${user.uid}/pages/${page.id ?? 'p'}_${DateTime.now().millisecondsSinceEpoch}.png',
                  );
              await targetRef.putData(
                bytes,
                SettableMetadata(contentType: 'image/png'),
              );
              storagePath = targetRef.fullPath;
              downloadUrl = await targetRef.getDownloadURL();
            }
          } else {
            final localFile = File(page.imagePath);
            if (await localFile.exists()) {
              final fileName = p.basename(localFile.path);
              final targetRef = _storage.ref().child(
                    'users/${user.uid}/pages/${page.id ?? 'p'}_$fileName',
                  );
              await targetRef.putFile(
                localFile,
                SettableMetadata(contentType: 'image/png'),
              );
              storagePath = targetRef.fullPath;
              downloadUrl = await targetRef.getDownloadURL();
            }
          }
        } catch (e) {
          debugPrint('Warning: failed to upload page image ${page.id}: $e');
        }

        uploadedPages.add({
          'id': page.id,
          'documentId': page.documentId,
          'pageOrder': page.pageOrder,
          'metadata': page.metadata,
          'storagePath': storagePath,
          'downloadUrl': downloadUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 2. Batch commit to Firestore
      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(user.uid);

      for (final folder in folders) {
        final folderRef = userRef.collection('folders').doc(folder.id.toString());
        batch.set(folderRef, {
          'id': folder.id,
          'name': folder.name,
          'createdAt': folder.createdAt.toIso8601String(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      for (final doc in documents) {
        final docRef = userRef.collection('documents').doc(doc.id.toString());
        batch.set(docRef, {
          'id': doc.id,
          'folderId': doc.folderId,
          'name': doc.name,
          'createdAt': doc.createdAt.toIso8601String(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      for (final pageData in uploadedPages) {
        final pageRef = userRef.collection('pages').doc(pageData['id'].toString());
        batch.set(pageRef, pageData);
      }

      // Update sync status on root user document
      batch.set(
        userRef,
        {
          'email': user.email,
          'displayName': user.displayName,
          'lastBackupAt': FieldValue.serverTimestamp(),
          'totalFolders': folders.length,
          'totalDocuments': documents.length,
          'totalPages': pages.length,
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      return SyncResult(
        success: true,
        foldersCount: folders.length,
        documentsCount: documents.length,
        pagesCount: pages.length,
        message: 'Successfully backed up ${documents.length} document(s) & ${pages.length} page(s) to cloud.',
      );
    } on FirebaseException catch (e) {
      throw SyncFailure(e.message ?? 'Cloud backup failed due to a network or Firebase error.');
    } catch (e) {
      throw SyncFailure('Failed to backup: $e');
    }
  }

  /// Restores Folders, Documents, and Pages from Firebase to local SQLite & disk
  Future<SyncResult> restoreAllFromCloud() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const SyncFailure('You must be signed in to restore cloud data.');
    }

    try {
      final userRef = _firestore.collection('users').doc(user.uid);

      final foldersSnap = await userRef.collection('folders').get();
      final docsSnap = await userRef.collection('documents').get();
      final pagesSnap = await userRef.collection('pages').get();

      if (foldersSnap.docs.isEmpty && docsSnap.docs.isEmpty) {
        return SyncResult(
          success: true,
          foldersCount: 0,
          documentsCount: 0,
          pagesCount: 0,
          message: 'No cloud backups found for your account.',
        );
      }

      // 1. Restore Folders
      for (final fDoc in foldersSnap.docs) {
        final data = fDoc.data();
        final folder = Folder(
          id: data['id'] as int?,
          name: data['name'] as String? ?? 'Untitled Folder',
          createdAt: data['createdAt'] != null
              ? DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now()
              : DateTime.now(),
        );
        await _repository.insertOrUpdateFolder(folder);
      }

      // 2. Restore Documents
      for (final dDoc in docsSnap.docs) {
        final data = dDoc.data();
        final document = Document(
          id: data['id'] as int?,
          folderId: data['folderId'] as int? ?? 1,
          name: data['name'] as String? ?? 'Untitled Document',
          createdAt: data['createdAt'] != null
              ? DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now()
              : DateTime.now(),
        );
        await _repository.insertOrUpdateDocument(document);
      }

      // 3. Restore Pages & download image assets
      for (final pDoc in pagesSnap.docs) {
        final data = pDoc.data();
        final pageId = data['id'] as int?;
        final docId = data['documentId'] as int? ?? 0;
        final pageOrder = data['pageOrder'] as int? ?? 0;
        final metadata = data['metadata'] as String?;
        final storagePath = data['storagePath'] as String?;
        final downloadUrl = data['downloadUrl'] as String?;

        String localImagePath = '';

        if (storagePath != null && storagePath.isNotEmpty) {
          try {
            if (kIsWeb) {
              final bytes = await _storage.ref(storagePath).getData();
              if (bytes != null) {
                localImagePath = 'data:image/png;base64,${base64Encode(bytes)}';
              }
            } else {
              final appDir = await getApplicationDocumentsDirectory();
              final scansDir = Directory(p.join(appDir.path, 'scans'));
              if (!await scansDir.exists()) {
                await scansDir.create(recursive: true);
              }
              final localFile = File(p.join(
                scansDir.path,
                'restored_${pageId ?? 'p'}_${DateTime.now().millisecondsSinceEpoch}.png',
              ));
              await _storage.ref(storagePath).writeToFile(localFile);
              localImagePath = localFile.path;
            }
          } catch (e) {
            debugPrint('Warning: unable to download restored page image: $e');
            localImagePath = downloadUrl ?? '';
          }
        } else if (downloadUrl != null) {
          localImagePath = downloadUrl;
        }

        final page = PageModel(
          id: pageId,
          documentId: docId,
          imagePath: localImagePath,
          pageOrder: pageOrder,
          metadata: metadata,
        );
        await _repository.insertOrUpdatePage(page);
      }

      return SyncResult(
        success: true,
        foldersCount: foldersSnap.docs.length,
        documentsCount: docsSnap.docs.length,
        pagesCount: pagesSnap.docs.length,
        message: 'Successfully restored ${docsSnap.docs.length} document(s) & ${pagesSnap.docs.length} page(s) from cloud.',
      );
    } on FirebaseException catch (e) {
      throw SyncFailure(e.message ?? 'Cloud restore failed due to a network or Firebase error.');
    } catch (e) {
      throw SyncFailure('Failed to restore from cloud: $e');
    }
  }
}
