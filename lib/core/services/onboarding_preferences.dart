import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPreferences {
  static const _completedKey = 'onboarding_completed';
  static const _homeGuideKey = 'home_guide_completed';

  bool _completed = false;
  bool _homeGuideCompleted = false;
  bool _loaded = false;

  bool get isLoaded => _loaded;
  bool get completed => _completed;
  bool get homeGuideCompleted => _homeGuideCompleted;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _completed = prefs.getBool(_completedKey) ?? false;
    _homeGuideCompleted = prefs.getBool(_homeGuideKey) ?? false;
    _loaded = true;
  }

  Future<void> setCompleted() async {
    _completed = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
  }

  Future<void> setHomeGuideCompleted() async {
    _homeGuideCompleted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_homeGuideKey, true);
  }
}
