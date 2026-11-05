class AppSession {
  AppSession._();

  static String? userId;
  static String? email;
  static bool emailVerified = false;

  static void signIn(String identity) {
    final normalized = identity.trim().toLowerCase();
    email = normalized.contains('@') ? normalized : null;
    userId = 'user:$normalized';
    emailVerified = normalized.endsWith('@student.unand.ac.id');
  }

  static void signOut() {
    userId = null;
    email = null;
    emailVerified = false;
  }
}
