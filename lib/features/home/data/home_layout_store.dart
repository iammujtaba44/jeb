import 'package:jeb/features/home/domain/home_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the home dashboard layout locally (per device — it's a UI choice,
/// not synced data).
class HomeLayoutStore {
  const HomeLayoutStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _key = 'home_layout_v1';

  HomeLayout read() => HomeLayout.parse(_prefs.getString(_key));

  Future<void> write(HomeLayout layout) =>
      _prefs.setString(_key, layout.serialize());
}
