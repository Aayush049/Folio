import 'package:equatable/equatable.dart';
import '../../models/page_model.dart';

abstract class DocumentDetailState extends Equatable {
  const DocumentDetailState();

  @override
  List<Object?> get props => [];
}

class DocumentDetailInitial extends DocumentDetailState {}

class DocumentDetailLoading extends DocumentDetailState {}

class DocumentDetailLoaded extends DocumentDetailState {
  final List<PageModel> pages;
  final bool isExtractingOcr;
  final String? extractedOcrText;

  const DocumentDetailLoaded({
    required this.pages,
    this.isExtractingOcr = false,
    this.extractedOcrText,
  });

  DocumentDetailLoaded copyWith({
    List<PageModel>? pages,
    bool? isExtractingOcr,
    String? extractedOcrText,
  }) {
    return DocumentDetailLoaded(
      pages: pages ?? this.pages,
      isExtractingOcr: isExtractingOcr ?? this.isExtractingOcr,
      extractedOcrText: extractedOcrText ?? this.extractedOcrText,
    );
  }

  @override
  List<Object?> get props => [pages, isExtractingOcr, extractedOcrText];
}

class DocumentDetailError extends DocumentDetailState {
  final String message;
  const DocumentDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
