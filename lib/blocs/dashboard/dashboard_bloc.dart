import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/document_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final IDocumentRepository repository;

  DashboardBloc({required this.repository}) : super(DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<AddFolder>(_onAddFolder);
    on<DeleteDocument>(_onDeleteDocument);
    on<DeleteFolder>(_onDeleteFolder);

    add(const LoadDashboard());
  }

  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final folders = await repository.getFolders();
      final recentDocs = await repository.getRecentDocuments();
      emit(DashboardLoaded(folders: folders, recentDocuments: recentDocs));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> _onAddFolder(
    AddFolder event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      await repository.createFolder(event.name);
      add(const LoadDashboard());
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> _onDeleteDocument(
    DeleteDocument event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      await repository.softDeleteDocument(event.id);
      add(const LoadDashboard());
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> _onDeleteFolder(
    DeleteFolder event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      await repository.deleteFolder(event.id);
      add(const LoadDashboard());
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
