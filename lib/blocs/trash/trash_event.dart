import 'package:equatable/equatable.dart';

abstract class TrashEvent extends Equatable {
  const TrashEvent();

  @override
  List<Object?> get props => [];
}

class LoadTrash extends TrashEvent {
  const LoadTrash();
}

class RestoreDocumentFromTrash extends TrashEvent {
  final int documentId;
  const RestoreDocumentFromTrash(this.documentId);

  @override
  List<Object?> get props => [documentId];
}

class PermanentlyDeleteFromTrash extends TrashEvent {
  final int documentId;
  const PermanentlyDeleteFromTrash(this.documentId);

  @override
  List<Object?> get props => [documentId];
}

class EmptyTrash extends TrashEvent {
  const EmptyTrash();
}
