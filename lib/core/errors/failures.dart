import 'package:equatable/equatable.dart';

/// Base Failure class for typed error handling
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class OcrFailure extends Failure {
  const OcrFailure(super.message);
}

class FileSystemFailure extends Failure {
  const FileSystemFailure(super.message);
}

class DocumentNotFoundFailure extends Failure {
  const DocumentNotFoundFailure([super.message = 'Document not found']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class SyncFailure extends Failure {
  const SyncFailure(super.message);
}
