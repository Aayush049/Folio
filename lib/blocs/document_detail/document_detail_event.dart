import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../models/page_model.dart';

abstract class DocumentDetailEvent extends Equatable {
  const DocumentDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadDocumentPages extends DocumentDetailEvent {
  final int documentId;
  const LoadDocumentPages(this.documentId);

  @override
  List<Object?> get props => [documentId];
}

class ReorderDocumentPages extends DocumentDetailEvent {
  final int oldIndex;
  final int newIndex;
  const ReorderDocumentPages(this.oldIndex, this.newIndex);

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

class DeleteDocumentPage extends DocumentDetailEvent {
  final int pageId;
  const DeleteDocumentPage(this.pageId);

  @override
  List<Object?> get props => [pageId];
}

class UpdateDocumentPage extends DocumentDetailEvent {
  final PageModel page;
  const UpdateDocumentPage(this.page);

  @override
  List<Object?> get props => [page];
}

class AddDocumentPages extends DocumentDetailEvent {
  final List<File> images;
  const AddDocumentPages(this.images);

  @override
  List<Object?> get props => [images];
}

class ExtractDocumentOcrText extends DocumentDetailEvent {
  const ExtractDocumentOcrText();
}
