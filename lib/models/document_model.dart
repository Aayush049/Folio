import 'package:equatable/equatable.dart';

class Document extends Equatable {
  final int? id;
  final int folderId;
  final String name;
  final DateTime createdAt;
  final bool isDeleted;
  final DateTime? deletedAt;

  const Document({
    this.id,
    required this.folderId,
    required this.name,
    required this.createdAt,
    this.isDeleted = false,
    this.deletedAt,
  });

  Document copyWith({
    int? id,
    int? folderId,
    String? name,
    DateTime? createdAt,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return Document(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'folderId': folderId,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'isDeleted': isDeleted ? 1 : 0,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'] as int?,
      folderId: map['folderId'] as int,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isDeleted: (map['isDeleted'] as int? ?? 0) == 1,
      deletedAt: map['deletedAt'] != null
          ? DateTime.tryParse(map['deletedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        folderId,
        name,
        createdAt,
        isDeleted,
        deletedAt,
      ];
}
