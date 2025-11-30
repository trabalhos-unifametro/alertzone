import 'package:shared_preferences/shared_preferences.dart';

const String termsAcceptedKey = 'terms_accepted';

Future<bool> checkTermsAccepted() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(termsAcceptedKey) ?? false;
  } catch (e) {
    return false;
  }
}