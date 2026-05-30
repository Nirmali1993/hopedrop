import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LanguageService extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;

  Future<void> loadLanguage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final lang = doc.data()?['language'] ?? 'en';
        _currentLocale = Locale(lang);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Language load error: $e');
    }
  }

  Future<void> changeLanguage(String langCode) async {
    try {
      _currentLocale = Locale(langCode);
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'language': langCode});
      }
    } catch (e) {
      debugPrint('Language save error: $e');
    }
  }

  String getLanguageName(String code) {
    switch (code) {
      case 'si':
        return 'සිංහල';
      case 'ta':
        return 'தமிழ்';
      default:
        return 'English';
    }
  }

  String getFlagEmoji(String code) {
    switch (code) {
      case 'si':
        return '🇱🇰';
      case 'ta':
        return '🇱🇰';
      default:
        return '🇬🇧';
    }
  }
}
