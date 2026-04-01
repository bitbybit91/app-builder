import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/admin_stats.dart';
import '../../domain/usecases/get_admin_stats_usecase.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();
  @override
  List<Object?> get props => [];
}

class LoadAdminDashboard extends AdminEvent {}

abstract class AdminState extends Equatable {
  const AdminState();
  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {}
class AdminLoading extends AdminState {}

class AdminLoaded extends AdminState {
  final AdminStats stats;
  const AdminLoaded(this.stats);
  @override
  List<Object?> get props => [stats];
}

class AdminError extends AdminState {
  final String message;
  const AdminError(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final GetAdminStatsUseCase getAdminStatsUseCase;

  AdminBloc({required this.getAdminStatsUseCase}) : super(AdminInitial()) {
    on<LoadAdminDashboard>(_onLoadDashboard);
  }

  Future<void> _onLoadDashboard(LoadAdminDashboard event, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    try {
      final stats = await getAdminStatsUseCase();
      emit(AdminLoaded(stats));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }
}
