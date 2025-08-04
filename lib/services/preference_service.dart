import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static const String _preferredRoleKey = 'preferred_role';
  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';
  
  // Get user's preferred role (user/admin)
  static Future<String?> getPreferredRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_preferredRoleKey);
  }
  
  // Set user's preferred role
  static Future<void> setPreferredRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferredRoleKey, role);
  }
  
  // Clear preferred role
  static Future<void> clearPreferredRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_preferredRoleKey);
  }
  
  // Check if user has seen onboarding
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenOnboardingKey) ?? false;
  }
  
  // Mark onboarding as seen
  static Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingKey, true);
  }
  
  // Reset onboarding status (for testing)
  static Future<void> resetOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasSeenOnboardingKey);
  }
  
  // Get appropriate auth route based on preferred role
  static Future<String> getAuthRouteForRole() async {
    final preferredRole = await getPreferredRole();
    switch (preferredRole) {
      case 'admin':
        return '/auth/admin-login';
      case 'user':
      default:
        return '/auth/login';
    }
  }
  
  // Clear all preferences
  static Future<void> clearAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
