import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/features/home/data/home_layout_store.dart';
import 'package:jeb/features/home/domain/home_section.dart';

/// Holds the home dashboard layout and persists every change immediately.
class HomeLayoutCubit extends Cubit<HomeLayout> {
  HomeLayoutCubit(HomeLayoutStore store)
      : _store = store,
        super(store.read());

  final HomeLayoutStore _store;

  Future<void> toggle(HomeSection section) async {
    final Set<HomeSection> hidden = <HomeSection>{...state.hidden};
    if (!hidden.remove(section)) hidden.add(section);
    await _emitAndSave(state.copyWith(hidden: hidden));
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final List<HomeSection> order = <HomeSection>[...state.order];
    if (newIndex > oldIndex) newIndex -= 1;
    final HomeSection moved = order.removeAt(oldIndex);
    order.insert(newIndex, moved);
    await _emitAndSave(state.copyWith(order: order));
  }

  Future<void> resetToDefault() => _emitAndSave(HomeLayout.defaults);

  Future<void> _emitAndSave(HomeLayout next) async {
    emit(next);
    await _store.write(next);
  }
}
