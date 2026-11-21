import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/document_repository.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final IDocumentRepository _repository;
  Timer? _debounceTimer;

  SearchBloc({required IDocumentRepository repository})
    : _repository = repository,
      super(const SearchState()) {
    on<SearchQueryChanged>(_onQueryChanged);
    on<ClearSearch>(_onClearSearch);
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query;
    if (query.trim().isEmpty) {
      _debounceTimer?.cancel();
      emit(
        state.copyWith(
          query: '',
          results: const [],
          isLoading: false,
          clearError: true,
        ),
      );
      return;
    }

    emit(state.copyWith(query: query, isLoading: true, clearError: true));

    final completer = Completer<void>();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () async {
      try {
        final results = await _repository.searchDocuments(query);
        if (!isClosed) {
          emit(state.copyWith(results: results, isLoading: false));
        }
      } catch (e) {
        if (!isClosed) {
          emit(
            state.copyWith(isLoading: false, errorMessage: 'Search failed: $e'),
          );
        }
      } finally {
        completer.complete();
      }
    });

    await completer.future;
  }

  void _onClearSearch(ClearSearch event, Emitter<SearchState> emit) {
    _debounceTimer?.cancel();
    emit(const SearchState());
  }
}
