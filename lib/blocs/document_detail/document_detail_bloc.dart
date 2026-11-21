import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/document_repository.dart';
import '../../services/scanner_service.dart';
import '../../models/page_model.dart';
import 'document_detail_event.dart';
import 'document_detail_state.dart';

class DocumentDetailBloc extends Bloc<DocumentDetailEvent, DocumentDetailState> {
  final IDocumentRepository repository;
  final ScannerService scannerService;
  final int documentId;

  DocumentDetailBloc({
    required this.repository,
    required this.scannerService,
    required this.documentId,
  }) : super(DocumentDetailInitial()) {
    on<LoadDocumentPages>(_onLoadDocumentPages);
    on<ReorderDocumentPages>(_onReorderDocumentPages);
    on<DeleteDocumentPage>(_onDeleteDocumentPage);
    on<UpdateDocumentPage>(_onUpdateDocumentPage);
    on<AddDocumentPages>(_onAddDocumentPages);
    on<ExtractDocumentOcrText>(_onExtractDocumentOcrText);
  }

  Future<void> _onLoadDocumentPages(
    LoadDocumentPages event,
    Emitter<DocumentDetailState> emit,
  ) async {
    emit(DocumentDetailLoading());
    try {
      final pages = await repository.getPages(event.documentId);
      emit(DocumentDetailLoaded(pages: pages));
    } catch (e) {
      emit(DocumentDetailError('Failed to load document pages: $e'));
    }
  }

  Future<void> _onReorderDocumentPages(
    ReorderDocumentPages event,
    Emitter<DocumentDetailState> emit,
  ) async {
    if (state is DocumentDetailLoaded) {
      final currentState = state as DocumentDetailLoaded;
      final reordered = List<PageModel>.from(currentState.pages);

      int newIndex = event.newIndex;
      if (event.oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = reordered.removeAt(event.oldIndex);
      reordered.insert(newIndex, item);

      // Optimistically emit reordered list
      emit(currentState.copyWith(pages: reordered));

      try {
        for (int i = 0; i < reordered.length; i++) {
          await repository.updatePage(reordered[i].copyWith(pageOrder: i));
        }
      } catch (e) {
        emit(DocumentDetailError('Failed to persist page order: $e'));
      }
    }
  }

  Future<void> _onDeleteDocumentPage(
    DeleteDocumentPage event,
    Emitter<DocumentDetailState> emit,
  ) async {
    if (state is DocumentDetailLoaded) {
      final currentState = state as DocumentDetailLoaded;
      try {
        await repository.deletePage(event.pageId);
        final pages = await repository.getPages(documentId);
        emit(currentState.copyWith(pages: pages));
      } catch (e) {
        emit(DocumentDetailError('Failed to delete page: $e'));
      }
    }
  }

  Future<void> _onUpdateDocumentPage(
    UpdateDocumentPage event,
    Emitter<DocumentDetailState> emit,
  ) async {
    if (state is DocumentDetailLoaded) {
      final currentState = state as DocumentDetailLoaded;
      try {
        await repository.updatePage(event.page);
        final pages = await repository.getPages(documentId);
        emit(currentState.copyWith(pages: pages));
      } catch (e) {
        emit(DocumentDetailError('Failed to update page: $e'));
      }
    }
  }

  Future<void> _onAddDocumentPages(
    AddDocumentPages event,
    Emitter<DocumentDetailState> emit,
  ) async {
    if (state is DocumentDetailLoaded) {
      final currentState = state as DocumentDetailLoaded;
      emit(DocumentDetailLoading());
      try {
        final startOrder = currentState.pages.length;
        for (int i = 0; i < event.images.length; i++) {
          final permanentFile =
              await scannerService.saveImageToPermanentStorage(event.images[i]);
          await repository.addPage(PageModel(
            documentId: documentId,
            imagePath: permanentFile.path,
            pageOrder: startOrder + i,
          ));
        }
        final pages = await repository.getPages(documentId);
        emit(DocumentDetailLoaded(pages: pages));
      } catch (e) {
        emit(DocumentDetailError('Failed to add pages: $e'));
      }
    }
  }

  Future<void> _onExtractDocumentOcrText(
    ExtractDocumentOcrText event,
    Emitter<DocumentDetailState> emit,
  ) async {
    if (state is DocumentDetailLoaded) {
      final currentState = state as DocumentDetailLoaded;
      if (currentState.pages.isEmpty) return;

      emit(currentState.copyWith(isExtractingOcr: true));

      try {
        final buffer = StringBuffer();
        for (int i = 0; i < currentState.pages.length; i++) {
          final text = await scannerService.extractTextFromImage(
            File(currentState.pages[i].imagePath),
          );
          if (text.isNotEmpty) {
            buffer.writeln('─── Page ${i + 1} ───');
            buffer.writeln(text);
            buffer.writeln();
          }
        }
        final result = buffer.toString().trim();
        emit(currentState.copyWith(
          isExtractingOcr: false,
          extractedOcrText: result.isEmpty ? 'No text found in this document.' : result,
        ));
      } catch (e) {
        emit(currentState.copyWith(isExtractingOcr: false));
        emit(DocumentDetailError('OCR Extraction failed: $e'));
      }
    }
  }
}
