import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveLoginSession(String username) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isLoggedIn', true);
  await prefs.setString('username', username);
}