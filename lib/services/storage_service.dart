import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const String propertiesBox = 'propertiesBox';
  static const String favoritesBox = 'favoritesBox';
  static const String bookingsBox = 'bookingsBox';
  static const String paymentsBox = 'paymentsBox';

  static const String loginStateKey = 'isLoggedIn';
  static const String currentUserKey = 'currentUserId';
  static const String roleKey = 'currentRole';
  static const String onboardingKey = 'onboardingSeen';

  late SharedPreferences _prefs;

  Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(propertiesBox);
    await Hive.openBox<List>(favoritesBox);
    await Hive.openBox<Map>(bookingsBox);
    await Hive.openBox<Map>(paymentsBox);
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs => _prefs;

  Box<Map> get propertyStore => Hive.box<Map>(propertiesBox);
  Box<List> get favoriteStore => Hive.box<List>(favoritesBox);
  Box<Map> get bookingStore => Hive.box<Map>(bookingsBox);
  Box<Map> get paymentStore => Hive.box<Map>(paymentsBox);
}
