import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage_service.dart';

enum UserRole { renter, owner, superadmin }

class AuthProvider extends ChangeNotifier {
  bool _isInitializing = true;
  bool _hasSeenOnboarding = false;
  bool _isLoggedIn = false;
  String? _currentUserId;
  UserRole? _role;

  bool get isInitializing => _isInitializing;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  bool get isLoggedIn => _isLoggedIn;
  String? get currentUserId => _currentUserId;
  UserRole? get role => _role;
  String get currentRoleLabel {
    if (_role == UserRole.superadmin) return 'Super Admin';
    if (_role == UserRole.owner) return 'Property Owner';
    if (_role == UserRole.renter) return 'Renter';
    return 'Unknown';
  }

  String get currentFullName {
    final userId = _currentUserId;
    if (userId == null) return 'Unknown';
    final name = StorageService.instance.prefs.getString(_nameKeyFor(userId));
    if (name == null || name.trim().isEmpty) return 'Unknown';
    return name.trim();
  }

  String get currentUsername {
    final userId = _currentUserId;
    if (userId == null) return 'unknown';
    final username = StorageService.instance.prefs.getString(
      _usernameKeyFor(userId),
    );
    if (username == null || username.trim().isEmpty) return userId;
    return username.trim();
  }

  Future<void> initialize() async {
    final prefs = StorageService.instance.prefs;
    await _ensureDefaultSuperAdmin(prefs);
    _hasSeenOnboarding = prefs.getBool(StorageService.onboardingKey) ?? false;
    _isLoggedIn = prefs.getBool(StorageService.loginStateKey) ?? false;
    _currentUserId = prefs.getString(StorageService.currentUserKey);
    if (_isLoggedIn && _currentUserId != null) {
      final roleRaw = prefs.getString(_roleKeyFor(_currentUserId!));
      if (roleRaw != null) {
        _role = _roleFromRaw(roleRaw);
        await prefs.setString(StorageService.roleKey, roleRaw);
      } else {
        // Incomplete/legacy session: force login.
        _isLoggedIn = false;
        _role = null;
        await prefs.setBool(StorageService.loginStateKey, false);
        await prefs.remove(StorageService.currentUserKey);
        await prefs.remove(StorageService.roleKey);
      }
    } else {
      _role = null;
    }

    await Future<void>.delayed(const Duration(milliseconds: 900));
    _isInitializing = false;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasSeenOnboarding = true;
    await StorageService.instance.prefs.setBool(
      StorageService.onboardingKey,
      true,
    );
    notifyListeners();
  }

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    final identity = _normalizeIdentity(identifier);
    if (identity.isEmpty) return;

    final prefs = StorageService.instance.prefs;
    final mappedUserId = prefs.getString(_identityKeyFor(identity));
    if (mappedUserId != null) {
      _currentUserId = mappedUserId;
    } else if (identity.contains('@')) {
      // Backward compatibility for older email-only accounts.
      _currentUserId = identity;
      await prefs.setString(_identityKeyFor(identity), identity);
    } else {
      throw Exception('Username not found. Please register first.');
    }
    final userPassword = prefs.getString(_passwordKeyFor(_currentUserId!));
    if (userPassword != null && userPassword != password) {
      throw Exception('Invalid credentials');
    }

    final roleRaw = prefs.getString(_roleKeyFor(_currentUserId!));
    if (roleRaw == null) {
      throw Exception('Account setup incomplete. Please register again.');
    }

    _isLoggedIn = true;
    _role = _roleFromRaw(roleRaw);
    await prefs.setString(StorageService.roleKey, roleRaw);
    await prefs.setBool(StorageService.loginStateKey, true);
    await prefs.setString(StorageService.currentUserKey, _currentUserId!);

    notifyListeners();
  }

  Future<String> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizeIdentity(email);
    final normalizedUsername = _normalizeIdentity(username);
    if (normalizedEmail.isEmpty || normalizedUsername.isEmpty) {
      throw Exception('Email and username are required');
    }

    final prefs = StorageService.instance.prefs;
    final emailOwner = prefs.getString(_identityKeyFor(normalizedEmail));
    final usernameOwner = prefs.getString(_identityKeyFor(normalizedUsername));
    if ((emailOwner != null && emailOwner != normalizedEmail) ||
        (usernameOwner != null && usernameOwner != normalizedEmail)) {
      throw Exception('Email or username already in use');
    }

    await prefs.setString(_identityKeyFor(normalizedEmail), normalizedEmail);
    await prefs.setString(_identityKeyFor(normalizedUsername), normalizedEmail);
    await prefs.setString(_usernameKeyFor(normalizedEmail), normalizedUsername);
    await prefs.setString(_nameKeyFor(normalizedEmail), name.trim());
    await prefs.setString(_passwordKeyFor(normalizedEmail), password);
    await prefs.setBool(StorageService.loginStateKey, false);
    await prefs.remove(StorageService.currentUserKey);
    await prefs.remove(StorageService.roleKey);

    notifyListeners();
    return normalizedEmail;
  }

  Future<void> setRoleForUser({
    required String userId,
    required UserRole role,
  }) async {
    if (userId.trim().isEmpty) return;
    final value = _roleToRaw(role);
    await StorageService.instance.prefs.setString(_roleKeyFor(userId), value);
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _currentUserId = null;
    _role = null;

    await StorageService.instance.prefs.setBool(
      StorageService.loginStateKey,
      false,
    );
    await StorageService.instance.prefs.remove(StorageService.currentUserKey);
    await StorageService.instance.prefs.remove(StorageService.roleKey);

    notifyListeners();
  }

  String _normalizeIdentity(String value) => value.trim().toLowerCase();

  String _roleKeyFor(String userId) =>
      'user_role_${_normalizeIdentity(userId)}';

  String _identityKeyFor(String identity) =>
      'user_identity_${_normalizeIdentity(identity)}';

  String _usernameKeyFor(String userId) =>
      'user_username_${_normalizeIdentity(userId)}';

  String _nameKeyFor(String userId) =>
      'user_name_${_normalizeIdentity(userId)}';

  String _passwordKeyFor(String userId) =>
      'user_password_${_normalizeIdentity(userId)}';

  UserRole _roleFromRaw(String raw) {
    if (raw == 'owner') return UserRole.owner;
    if (raw == 'superadmin') return UserRole.superadmin;
    return UserRole.renter;
  }

  String _roleToRaw(UserRole role) {
    if (role == UserRole.owner) return 'owner';
    if (role == UserRole.superadmin) return 'superadmin';
    return 'renter';
  }

  Future<void> _ensureDefaultSuperAdmin(SharedPreferences prefs) async {
    const userId = 'jester@fake.com';
    const username = 'jester';
    const fullName = 'R_My_Jester';
    const password = 'Jester';
    const role = 'superadmin';

    final existingRole = prefs.getString(_roleKeyFor(userId));
    final existingPassword = prefs.getString(_passwordKeyFor(userId));
    if (existingRole == role && existingPassword == password) return;

    await prefs.setString(_identityKeyFor(userId), userId);
    await prefs.setString(_identityKeyFor(username), userId);
    await prefs.setString(_usernameKeyFor(userId), username);
    await prefs.setString(_nameKeyFor(userId), fullName);
    await prefs.setString(_passwordKeyFor(userId), password);
    await prefs.setString(_roleKeyFor(userId), role);
  }
}
