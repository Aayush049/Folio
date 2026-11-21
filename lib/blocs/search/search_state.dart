import 'package:equatable/equatable.dart';
import '../../models/search_result_model.dart';

class SearchState extends Equatable {
  final String query;
  final List<SearchResult> results;
  final bool isLoading;
  final String? errorMessage;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isEmptyQuery => query.trim().isEmpty;
  bool get hasResults => results.isNotEmpty;

  SearchState copyWith({
    String? query,
    List<SearchResult>? results,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [query, results, isLoading, errorMessage];
}
