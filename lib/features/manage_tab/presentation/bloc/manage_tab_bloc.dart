import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'manage_tab_event.dart';
part 'manage_tab_state.dart';

class ManageTabBloc extends Bloc<ManageTabEvent, ManageTabState> {
  ManageTabBloc() : super(ManageTabInitial()) {
    on<ManageTabEvent>((event, emit) {
    });
  }
}
