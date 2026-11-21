import 'package:equatable/equatable.dart';
import '../../models/document_model.dart';

abstract class TrashState extends Equatable {
  const TrashState();

  @override
  List<Object?> get props => [];
}

class TrashInitial extends TrashState {}

class TrashLoading extends TrashState {}

class TrashLoaded extends TrashState {
  final List<Document> documents;
  final String? message;

  const TrashLoaded({required this.documents, this.message});

  @override
  List<Object?> get props => [documents, message];
}

class TrashError extends TrashState {
  final String message;
  const TrashError(this.message);

  @override
  List<Object?> get props => [message];
}
