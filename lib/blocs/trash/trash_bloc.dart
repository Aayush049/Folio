import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/document_repository.dart';
import 'trash_event.dart';
import 'trash_state.dart';

class TrashBloc extends Bloc<TrashEvent, TrashState> {
  final IDocumentRepository _repository;

  TrashBloc({required IDocumentRepository repository})
    : _repository = repository,
      super(TrashInitial()) {
    on<LoadTrash>(_onLoadTrash);
    on<RestoreDocumentFromTrash>(_onRestoreDocument);
    on<PermanentlyDeleteFromTrash>(_onPermanentDelete);
    on<EmptyTrash>(_onEmptyTrash);
  }

  Future<void> _onLoadTrash(LoadTrash event, Emitter<TrashState> emit) async {
    emit(TrashLoading());
    try {
      final docs = await _repository.getTrashDocuments();
      emit(TrashLoaded(documents: docs));
    } catch (e) {
      emit(TrashError('Failed to load trash: $e'));
    }
  }

  Future<void> _onRestoreDocument(
    RestoreDocumentFromTrash event,
    Emitter<TrashState> emit,
  ) async {
    try {
      await _repository.restoreDocument(event.documentId);
      final docs = await _repository.getTrashDocuments();
      emit(
        TrashLoaded(documents: docs, message: 'Document restored to library.'),
      );
    } catch (e) {
      emit(TrashError('Failed to restore document: $e'));
    }
  }

  Future<void> _onPermanentDelete(
    PermanentlyDeleteFromTrash event,
    Emitter<TrashState> emit,
  ) async {
    try {
      await _repository.permanentDeleteDocument(event.documentId);
      final docs = await _repository.getTrashDocuments();
      emit(
        TrashLoaded(documents: docs, message: 'Document permanently deleted.'),
      );
    } catch (e) {
      emit(TrashError('Failed to delete document: $e'));
    }
  }

  Future<void> _onEmptyTrash(EmptyTrash event, Emitter<TrashState> emit) async {
    try {
      final count = await _repository.emptyTrash();
      emit(
        TrashLoaded(
          documents: const [],
          message: 'Purged $count document(s) from trash.',
        ),
      );
    } catch (e) {
      emit(TrashError('Failed to empty trash: $e'));
    }
  }
}
