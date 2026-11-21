import 'package:equatable/equatable.dart';
import 'document_model.dart';

class SearchResult extends Equatable {
  final Document document;
  final String folderName;
  final String snippet;
  final bool isTitleMatch;

  const SearchResult({
    required this.document,
    required this.folderName,
    required this.snippet,
    this.isTitleMatch = false,
  });

  @override
  List<Object?> get props => [document, folderName, snippet, isTitleMatch];
}
