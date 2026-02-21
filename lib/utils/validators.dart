class Validators {
  static final RegExp _usernamePattern = RegExp(r'^[a-zA-Z0-9._-]{3,30}$');

  static String? requiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!value.contains('@')) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    final input = value.trim();
    if (input.contains('@')) {
      return 'Username cannot contain @';
    }
    if (!_usernamePattern.hasMatch(input)) {
      return 'Use 3-30 chars: letters, numbers, ., _, -';
    }
    return null;
  }

  static String? emailOrUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email or username is required';
    }
    final input = value.trim();
    if (input.contains('@')) return email(input);
    return username(input);
  }
}
